import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/core/logging/app_logger.dart';
import 'package:nebula_iptv/core/network/dio_client.dart';
import 'package:nebula_iptv/data/database/app_database.dart';
import 'package:nebula_iptv/data/database/database_provider.dart';
import 'package:nebula_iptv/data/database/tables/playlists_table.dart';
import 'package:nebula_iptv/data/datasources/m3u/m3u_datasource.dart';
import 'package:nebula_iptv/data/datasources/xtream/xtream_datasource.dart';
import 'package:nebula_iptv/data/repositories/epg_repository.dart';
import 'package:nebula_iptv/data/repositories/playlist_import_repository.dart';
import 'package:nebula_iptv/data/repositories/xtream_import_repository.dart';
import 'package:nebula_iptv/domain/providers/dedup_providers.dart';
import 'package:nebula_iptv/domain/providers/epg_providers.dart';
import 'package:nebula_iptv/domain/providers/health_check_providers.dart';
import 'package:nebula_iptv/domain/services/channel_dedup_service.dart';
import 'package:nebula_iptv/domain/services/video_player_service.dart';
import 'package:nebula_iptv/features/channels/providers/channels_provider.dart';
import 'package:nebula_iptv/features/player/providers/player_provider.dart';
import 'package:nebula_iptv/features/playlists/widgets/playlist_file_picker.dart';
import 'package:nebula_iptv/features/search/providers/search_provider.dart';
import 'package:nebula_iptv/features/series/providers/series_provider.dart';
import 'package:nebula_iptv/features/vod/providers/vod_provider.dart';

/// State for playlist management screen.
class PlaylistManagementState {
  final List<Playlist> playlists;
  final bool isLoading;
  final String? statusMessage;
  final bool isError;

  const PlaylistManagementState({
    this.playlists = const [],
    this.isLoading = false,
    this.statusMessage,
    this.isError = false,
  });

  PlaylistManagementState copyWith({
    List<Playlist>? playlists,
    bool? isLoading,
    String? statusMessage,
    bool clearStatus = false,
    bool? isError,
  }) {
    return PlaylistManagementState(
      playlists: playlists ?? this.playlists,
      isLoading: isLoading ?? this.isLoading,
      statusMessage: clearStatus ? null : (statusMessage ?? this.statusMessage),
      isError: isError ?? this.isError,
    );
  }
}

/// Provider for playlist management.
final playlistManagementProvider =
    StateNotifierProvider<PlaylistManagementNotifier, PlaylistManagementState>(
  (ref) => PlaylistManagementNotifier(ref),
);

/// Manages playlist CRUD operations.
///
/// All import/refresh flows are delegated to the repositories, which own
/// the business logic and return [Result] — the notifier only maps the
/// outcome to screen state.
class PlaylistManagementNotifier
    extends StateNotifier<PlaylistManagementState> {
  final Ref _ref;
  late final PlaylistImportRepository _importRepo;
  late final XtreamImportRepository _xtreamRepo;
  late final EpgRepository _epgRepo;
  late final PlaylistFilePicker _filePicker;

  PlaylistManagementNotifier(this._ref)
      : super(const PlaylistManagementState()) {
    final db = _ref.read(databaseProvider);
    final client = DioClient();
    final xtreamDataSource = XtreamDataSource(client: client);
    _importRepo = PlaylistImportRepository(
      db: db,
      m3uDataSource: M3uDataSource(client: client),
    );
    _xtreamRepo = XtreamImportRepository(
      db: db,
      xtreamDataSource: xtreamDataSource,
      credentialStore: _ref.read(credentialStoreProvider),
    );
    _epgRepo = _ref.read(epgRepositoryProvider);
    _filePicker = PlaylistFilePicker();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    final db = _ref.read(databaseProvider);
    final playlists = await db.playlistsDao.getAllPlaylists();
    state = state.copyWith(playlists: playlists);
  }

  /// Reativa o health check pós-import, exceto se houver playback ativo
  /// (o player é quem controla a pausa nesse caso).
  void _resumeHealthCheckUnlessPlaying() {
    final status = _ref.read(playerProvider).playbackState.status;
    final playing =
        status == PlaybackStatus.playing || status == PlaybackStatus.buffering;
    if (!playing) {
      _ref.read(healthCheckServiceProvider).resume();
    }
  }

  /// Imports a playlist from URL.
  Future<void> importFromUrl({
    required String name,
    required String url,
    String? epgUrl,
    bool allowInsecureTls = false,
  }) async {
    state = state.copyWith(isLoading: true, clearStatus: true);
    // Importo disputa conexões com o painel: health check pausado durante.
    _ref.read(healthCheckServiceProvider).pause();

    final result = await _importRepo.importFromUrl(
      name: name,
      url: url,
      epgUrl: epgUrl,
      allowInsecureTls: allowInsecureTls,
    );
    _resumeHealthCheckUnlessPlaying();

    result.when(
      success: (data) {
        state = state.copyWith(
          isLoading: false,
          statusMessage: '✓ Importado: ${data.channelsAdded} canais de "$name"',
          isError: false,
        );
        _loadPlaylists();
        // Refresh channels screen
        _ref.read(channelsScreenProvider.notifier).refresh();
        // Keep M3U imports consistent with Xtream imports. This is deliberately
        // fire-and-forget so a health/duplicate scan never delays importing.
        _syncEpgInBackground(data.playlistId);
        _runDeduplicationInBackground();
      },
      failure: (f) {
        state = state.copyWith(
          isLoading: false,
          statusMessage: f.message,
          isError: true,
        );
      },
    );
  }

  /// Imports a playlist from a file (uses file picker).
  Future<void> importFromFile() async {
    final pickResult = await _filePicker.pickPlaylistFile();

    await pickResult.when(
      success: (file) async {
        state = state.copyWith(isLoading: true, clearStatus: true);

        final result = await _importRepo.importFromFile(
          name: file.fileName.replaceAll(RegExp(r'\.\w+$'), ''),
          content: file.content,
        );
        _resumeHealthCheckUnlessPlaying();

        result.when(
          success: (data) {
            state = state.copyWith(
              isLoading: false,
              statusMessage:
                  '✓ Importado: ${data.channelsAdded} canais de "${file.fileName}"',
              isError: false,
            );
            _loadPlaylists();
            _ref.read(channelsScreenProvider.notifier).refresh();
            _runDeduplicationInBackground();
          },
          failure: (f) {
            state = state.copyWith(
              isLoading: false,
              statusMessage: f.message,
              isError: true,
            );
          },
        );
      },
      failure: (f) {
        if (f.message != 'Nenhum arquivo selecionado.') {
          state = state.copyWith(
            statusMessage: f.message,
            isError: true,
          );
        }
      },
    );
  }

  /// Refreshes a playlist (re-fetches from source and reconciles).
  Future<void> refreshPlaylist(int playlistId) async {
    state = state.copyWith(isLoading: true, clearStatus: true);

    final db = _ref.read(databaseProvider);
    final playlist = await db.playlistsDao.getPlaylistById(playlistId);
    if (playlist == null) {
      state = state.copyWith(
        isLoading: false,
        statusMessage: 'Fonte não encontrada.',
        isError: true,
      );
      return;
    }
    _ref.read(healthCheckServiceProvider).pause();

    final result = playlist.type == PlaylistType.xtream
        ? await _xtreamRepo.refreshXtream(playlistId)
        : await _importRepo.refreshPlaylist(playlistId);
    _resumeHealthCheckUnlessPlaying();

    result.when(
      success: (data) {
        state = state.copyWith(
          isLoading: false,
          statusMessage: '✓ Atualizado: +${data.channelsAdded} novos, '
              '${data.channelsDeactivated} removidos',
          isError: false,
        );
        _loadPlaylists();
        _ref.read(channelsScreenProvider.notifier).refresh();
        _ref.read(seriesScreenProvider.notifier).refresh();
        _ref.read(vodScreenProvider.notifier).refresh();
        _syncEpgInBackground(playlistId);
        _runDeduplicationInBackground();
      },
      failure: (f) {
        state = state.copyWith(
          isLoading: false,
          statusMessage: f.message,
          isError: true,
        );
      },
    );
  }

  /// Deletes a playlist.
  Future<void> deletePlaylist(int playlistId) async {
    final db = _ref.read(databaseProvider);
    // Delete all channels/series/vod associated with this playlist
    await db.customStatement(
      'DELETE FROM channels WHERE playlist_id = ?',
      [playlistId],
    );
    await db.customStatement(
      'DELETE FROM vod_items WHERE playlist_id = ?',
      [playlistId],
    );
    await db.customStatement(
      'DELETE FROM series_items WHERE playlist_id = ?',
      [playlistId],
    );
    await db.customStatement('DELETE FROM channel_groups');
    await db.customStatement('DELETE FROM channel_group_members');

    await db.playlistsDao.deletePlaylist(playlistId);
    await _loadPlaylists();
    _ref.read(channelsScreenProvider.notifier).refresh();
    _ref.read(seriesScreenProvider.notifier).refresh();
    _ref.read(vodScreenProvider.notifier).refresh();
    state = state.copyWith(
      statusMessage: 'Fonte removida',
      isError: false,
    );
  }

  /// Imports a source via Xtream Codes API (live + VOD + series).
  ///
  /// Delegates entirely to [XtreamImportRepository] — credentials are stored
  /// in the platform secure store and content is reconciled by stable id.
  Future<void> importFromXtream({
    required String name,
    required String serverUrl,
    required String username,
    required String password,
    String? epgUrl,
    bool allowInsecureTls = false,
  }) async {
    state = state.copyWith(isLoading: true, clearStatus: true);
    _ref.read(healthCheckServiceProvider).pause();

    final result = await _xtreamRepo.importXtream(
      name: name,
      serverUrl: serverUrl,
      username: username,
      userPass: password,
      epgUrl: epgUrl,
      allowInsecureTls: allowInsecureTls,
    );
    _resumeHealthCheckUnlessPlaying();

    result.when(
      success: (data) {
        state = state.copyWith(
          isLoading: false,
          statusMessage: '✓ Importado: ${data.channelsAdded} itens '
              '(${data.vodItemsImported} filmes, ${data.seriesImported} séries)',
          isError: false,
        );
        _loadPlaylists();
        _ref.read(channelsScreenProvider.notifier).refresh();
        _ref.read(seriesScreenProvider.notifier).refresh();
        _ref.read(vodScreenProvider.notifier).refresh();

        // Run channel deduplication in background (non-blocking)
        _syncEpgInBackground(data.playlistId);
        _runDeduplicationInBackground();
        _runContentDedupInBackground(data.playlistId);
        _runEnrichmentInBackground();
      },
      failure: (f) {
        state = state.copyWith(
          isLoading: false,
          statusMessage: f.message,
          isError: true,
        );
      },
    );
  }

  /// Downloads and parses the XMLTV EPG for a playlist in the background
  /// (parse runs in an isolate). Failures are logged — never block the
  /// import result.
  Future<void> _syncEpgInBackground(int playlistId) async {
    try {
      final db = _ref.read(databaseProvider);
      final playlist = await db.playlistsDao.getPlaylistById(playlistId);
      final epgUrl = playlist?.epgUrl;
      if (epgUrl == null || epgUrl.isEmpty) return;

      final result = await _epgRepo.syncEpg(epgUrl);
      result.when(
        success: (r) => appLogger.i(
          '[EPG] Synced playlist $playlistId: ${r.programsImported} programs, '
          '${r.channelsMatched} channels matched',
        ),
        failure: (f) =>
            appLogger.w('[EPG] Sync failed for playlist $playlistId: '
                '${f.message}'),
      );
    } catch (e) {
      appLogger.w('[EPG] Sync crashed for playlist $playlistId: $e');
    }
  }

  /// Runs channel deduplication in background after import.
  /// Non-blocking — errors are logged but don't affect the user.
  Future<void> _runDeduplicationInBackground() async {
    try {
      final db = _ref.read(databaseProvider);
      await db.channelGroupDao.ensureTables();
      final dedupService = ChannelDeduplicationService(
        db: db,
        groupDao: db.channelGroupDao,
      );
      final result = await dedupService.detectDuplicateChannels();
      appLogger.i(
        '[Dedup] Detected ${result.groupsCreated} channel groups '
        '(${result.channelsGrouped} channels grouped)',
      );
      // Refresh channel list to apply deduplication filter
      _ref.read(channelsScreenProvider.notifier).refresh();
    } catch (e) {
      appLogger.w('[Dedup] Channel deduplication failed: $e');
    }
  }

  /// Runs the VOD/series duplicate scan in the background after an Xtream
  /// import. Results are logged (read-only scan — no data is merged).
  Future<void> _runContentDedupInBackground(int playlistId) async {
    try {
      final service = _ref.read(contentDeduplicationServiceProvider);
      for (final sourceType in ['vod', 'series']) {
        final (result, groups) = await service.fullScan(
          playlistId: playlistId,
          sourceType: sourceType,
        );
        appLogger.i(
          '[ContentDedup] $sourceType: ${result.duplicateGroups} duplicate '
          'groups, ${result.totalItems} items scanned',
        );
        for (final group in groups.take(10)) {
          appLogger.d('[ContentDedup] candidate: $group');
        }
      }
    } catch (e) {
      appLogger.w('[ContentDedup] Scan failed: $e');
    }
  }

  /// Runs batch TMDB enrichment in background for cross-language search.
  void _runEnrichmentInBackground() {
    Future(() async {
      try {
        final service = _ref.read(batchEnrichmentProvider);
        await service.runEnrichment(batchSize: 50);
      } catch (e) {
        appLogger.w('[Enrichment Batch] Failed: $e');
      }
    });
  }
}
