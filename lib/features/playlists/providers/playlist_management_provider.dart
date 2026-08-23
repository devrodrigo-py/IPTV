import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/core/logging/app_logger.dart';
import 'package:nebula_iptv/core/network/dio_client.dart';
import 'package:nebula_iptv/core/errors/app_failure.dart';
import 'package:nebula_iptv/core/result/result.dart';
import 'package:nebula_iptv/data/database/app_database.dart';
import 'package:nebula_iptv/data/database/tables/channels_table.dart';
import 'package:nebula_iptv/data/database/tables/playlists_table.dart';
import 'package:nebula_iptv/data/datasources/xtream/xtream_datasource.dart';
import 'package:nebula_iptv/domain/services/channel_dedup_service.dart';
import 'package:nebula_iptv/data/datasources/m3u/m3u_datasource.dart';
import 'package:nebula_iptv/data/repositories/playlist_import_repository.dart';
import 'package:nebula_iptv/features/channels/providers/channels_provider.dart';
import 'package:nebula_iptv/features/search/providers/search_provider.dart';
import 'package:nebula_iptv/features/playlists/widgets/playlist_file_picker.dart';

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
final playlistManagementProvider = StateNotifierProvider<
    PlaylistManagementNotifier, PlaylistManagementState>(
  (ref) => PlaylistManagementNotifier(ref),
);

/// Manages playlist CRUD operations.
class PlaylistManagementNotifier
    extends StateNotifier<PlaylistManagementState> {
  final Ref _ref;
  late final PlaylistImportRepository _importRepo;
  late final PlaylistFilePicker _filePicker;
  late final XtreamDataSource _xtreamDataSource;

  PlaylistManagementNotifier(this._ref)
      : super(const PlaylistManagementState()) {
    final db = _ref.read(databaseProvider);
    _importRepo = PlaylistImportRepository(
      db: db,
      m3uDataSource: M3uDataSource(client: DioClient()),
    );
    _filePicker = PlaylistFilePicker();
    _xtreamDataSource = XtreamDataSource(client: DioClient());
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    final db = _ref.read(databaseProvider);
    final playlists = await db.playlistsDao.getAllPlaylists();
    state = state.copyWith(playlists: playlists);
  }

  /// Imports a playlist from URL.
  Future<void> importFromUrl({
    required String name,
    required String url,
  }) async {
    state = state.copyWith(isLoading: true, clearStatus: true);

    final result = await _importRepo.importFromUrl(
      name: name,
      url: url,
    );

    result.when(
      success: (data) {
        state = state.copyWith(
          isLoading: false,
          statusMessage:
              '✓ Importado: ${data.channelsAdded} canais de "$name"',
          isError: false,
        );
        _loadPlaylists();
        // Refresh channels screen
        _ref.read(channelsScreenProvider.notifier).refresh();
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
          filePath: file.content, // readFromContent expects content string
        );

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

  /// Refreshes a playlist (re-fetches from source).
  Future<void> refreshPlaylist(int playlistId) async {
    state = state.copyWith(isLoading: true, clearStatus: true);

    final result = await _importRepo.refreshPlaylist(playlistId);

    result.when(
      success: (data) {
        state = state.copyWith(
          isLoading: false,
          statusMessage:
              '✓ Atualizado: +${data.channelsAdded} novos, '
              '${data.channelsDeactivated} removidos',
          isError: false,
        );
        _loadPlaylists();
        _ref.read(channelsScreenProvider.notifier).refresh();
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
    await db.customStatement('DELETE FROM channel_groups');
    await db.customStatement('DELETE FROM channel_group_members');

    await db.playlistsDao.deletePlaylist(playlistId);
    await _loadPlaylists();
    _ref.read(channelsScreenProvider.notifier).refresh();
    state = state.copyWith(
      statusMessage: 'Fonte removida',
      isError: false,
    );
  }

  /// Imports a source via Xtream Codes API (live + VOD + series).
  Future<void> importFromXtream({
    required String name,
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearStatus: true);

    // 1. Authenticate
    final authResult = await _xtreamDataSource.authenticate(
      serverUrl: serverUrl,
      username: username,
      password: password,
    );

    if (authResult.isFailure) {
      final failure = (authResult as Failure).failure;
      state = state.copyWith(
        isLoading: false,
        statusMessage: failure.message,
        isError: true,
      );
      return;
    }

    final db = _ref.read(databaseProvider);

    // Create playlist entry first
    final playlistId = await db.playlistsDao.insertPlaylist(
      PlaylistsCompanion.insert(
        name: name,
        type: PlaylistType.xtream,
        url: Value(serverUrl),
        username: Value(username),
        credentialKey: Value(password),
      ),
    );

    var liveCount = 0;
    var vodCount = 0;
    var seriesCount = 0;

    // 2. Fetch category maps for name resolution
    final liveCatMap = await _fetchCategoryMap(
      serverUrl: serverUrl, username: username, password: password,
      action: 'live',
    );
    final vodCatMap = await _fetchCategoryMap(
      serverUrl: serverUrl, username: username, password: password,
      action: 'vod',
    );
    final seriesCatMap = await _fetchCategoryMap(
      serverUrl: serverUrl, username: username, password: password,
      action: 'series',
    );

    // 3. Import live streams
    final liveResult = await _xtreamDataSource.getLiveStreams(
      serverUrl: serverUrl,
      username: username,
      password: password,
    );
    if (liveResult case Success(data: final streams)) {
      for (final stream in streams) {
        final streamUrl = _xtreamDataSource.buildStreamUrl(
          serverUrl: serverUrl,
          username: username,
          password: password,
          streamId: stream.streamId,
          extension: stream.containerExtension ?? 'ts',
        );
        await db.channelsDao.insertChannel(ChannelsCompanion.insert(
          playlistId: playlistId,
          name: stream.name,
          streamUrl: streamUrl,
          sourceType: ChannelSourceType.xtream,
          sourceId: Value(stream.streamId.toString()),
          logoUrl: Value(stream.streamIcon),
          groupName: Value(liveCatMap[stream.categoryId] ?? stream.categoryId),
        ));
      }
      liveCount = streams.length;
    }

    // 4. Import VOD (movies)
    final vodResult = await _xtreamDataSource.getVodStreams(
      serverUrl: serverUrl,
      username: username,
      password: password,
    );
    if (vodResult case Success(data: final movies)) {
      for (final movie in movies) {
        final streamUrl = _xtreamDataSource.buildVodStreamUrl(
          serverUrl: serverUrl,
          username: username,
          password: password,
          streamId: movie.streamId,
          extension: movie.containerExtension ?? 'mp4',
        );
        await db.channelsDao.insertChannel(ChannelsCompanion.insert(
          playlistId: playlistId,
          name: movie.name,
          streamUrl: streamUrl,
          sourceType: ChannelSourceType.vod,
          sourceId: Value(movie.streamId.toString()),
          logoUrl: Value(movie.streamIcon),
          groupName: Value(vodCatMap[movie.categoryId] ?? movie.categoryId),
        ));
      }
      vodCount = movies.length;
    }

    // 5. Import Series (metadata only)
    final seriesResult = await _xtreamDataSource.getSeries(
      serverUrl: serverUrl,
      username: username,
      password: password,
    );
    if (seriesResult case Success(data: final seriesList)) {
      for (final s in seriesList) {
        await db.channelsDao.insertChannel(ChannelsCompanion.insert(
          playlistId: playlistId,
          name: s.name,
          streamUrl: '', // Series don't have a direct stream URL
          sourceType: ChannelSourceType.series,
          sourceId: Value(s.seriesId.toString()),
          logoUrl: Value(s.cover),
          groupName: Value(seriesCatMap[s.categoryId] ?? s.categoryId),
        ));
      }
      seriesCount = seriesList.length;
    }

    state = state.copyWith(
      isLoading: false,
      statusMessage:
          '\u2713 Importado: $liveCount canais, $vodCount filmes, $seriesCount s\u00e9ries',
      isError: false,
    );
    _loadPlaylists();
    _ref.read(channelsScreenProvider.notifier).refresh();

    // Run channel deduplication in background (non-blocking)
    _runDeduplicationInBackground();
    _runEnrichmentInBackground();
  }

  /// Fetches category name map (id → name) from Xtream API.
  Future<Map<String, String>> _fetchCategoryMap({
    required String serverUrl,
    required String username,
    required String password,
    required String action, // 'live', 'vod', 'series'
  }) async {
    final map = <String, String>{};
    try {
      final result = switch (action) {
        'live' => await _xtreamDataSource.getLiveCategories(
            serverUrl: serverUrl, username: username, password: password),
        'vod' => await _xtreamDataSource.getVodCategories(
            serverUrl: serverUrl, username: username, password: password),
        'series' => await _xtreamDataSource.getSeriesCategories(
            serverUrl: serverUrl, username: username, password: password),
        _ => await _xtreamDataSource.getLiveCategories(
            serverUrl: serverUrl, username: username, password: password),
      };
      result.when(
        success: (categories) {
          for (final cat in categories) {
            map[cat.categoryId] = cat.categoryName;
          }
        },
        failure: (_) {},
      );
    } catch (_) {}
    return map;
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
