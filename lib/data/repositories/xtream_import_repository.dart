import 'package:drift/drift.dart';
import 'package:nebula_iptv/core/credentials/credential_store.dart';
import 'package:nebula_iptv/core/errors/app_failure.dart';
import 'package:nebula_iptv/core/logging/app_logger.dart';
import 'package:nebula_iptv/core/result/result.dart';
import 'package:nebula_iptv/data/database/app_database.dart';
import 'package:nebula_iptv/data/database/tables/channels_table.dart';
import 'package:nebula_iptv/data/database/tables/playlists_table.dart';
import 'package:nebula_iptv/data/datasources/xtream/xtream_datasource.dart';
import 'package:nebula_iptv/data/datasources/xtream/xtream_models.dart';
import 'package:nebula_iptv/data/repositories/playlist_import_repository.dart';
import 'package:nebula_iptv/data/repositories/series_import_repository.dart';
import 'package:nebula_iptv/data/repositories/vod_import_repository.dart';

/// Repository for importing and syncing Xtream Codes playlists.
///
/// Single source of truth for Xtream imports (live + VOD + series).
/// The presentation layer consumes the [Result] returned by
/// [importXtream]/[refreshXtream]; it must not re-implement the flow.
class XtreamImportRepository {
  final AppDatabase _db;
  final XtreamDataSource _xtreamDataSource;
  final CredentialStore _credentialStore;
  late final VodImportRepository _vodImportRepository;
  late final SeriesImportRepository _seriesImportRepository;

  XtreamImportRepository({
    required AppDatabase db,
    required XtreamDataSource xtreamDataSource,
    required CredentialStore credentialStore,
  })  : _db = db,
        _xtreamDataSource = xtreamDataSource,
        _credentialStore = credentialStore {
    _vodImportRepository = VodImportRepository(
      db: db,
      xtreamDataSource: xtreamDataSource,
      credentialStore: credentialStore,
    );
    _seriesImportRepository = SeriesImportRepository(
      db: db,
      xtreamDataSource: xtreamDataSource,
      credentialStore: credentialStore,
    );
  }

  /// Imports a new Xtream source: live channels, VOD and series.
  ///
  /// Live streams are mandatory — a failure aborts the import before any
  /// row is written. VOD/series failures are logged and non-blocking.
  Future<Result<PlaylistImportResult>> importXtream({
    required String name,
    required String serverUrl,
    required String username,
    required String userPass,
    int? portOverride,
    String? epgUrl,
    bool allowInsecureTls = false,
  }) async {
    final authResult = await _xtreamDataSource.authenticate(
      serverUrl: serverUrl,
      username: username,
      password: userPass,
      portOverride: portOverride,
      allowInsecureCertificates: allowInsecureTls,
    );

    return await authResult.when(
      success: (auth) => _persistXtreamImport(
        name: name,
        serverUrl: serverUrl,
        username: username,
        userPass: userPass,
        portOverride: portOverride,
        epgUrl: epgUrl,
        allowInsecureTls: allowInsecureTls,
        accountStatus: auth.userInfo.status,
      ),
      failure: (f) => Failure(f),
    );
  }

  Future<Result<PlaylistImportResult>> _persistXtreamImport({
    required String name,
    required String serverUrl,
    required String username,
    required String userPass,
    required int? portOverride,
    required String? epgUrl,
    required bool allowInsecureTls,
    required String accountStatus,
  }) async {
    final credentialKey = 'xtream_${username}_${serverUrl.hashCode}';
    final saveResult = await _credentialStore.save(
      key: credentialKey,
      value: userPass,
    );

    if (saveResult.isFailure) {
      return const Failure(
        CredentialFailure(
          message: 'Não foi possível salvar as credenciais.',
        ),
      );
    }

    try {
      // Fetch everything BEFORE creating the playlist row: a live failure
      // aborts here and no half-imported source is left behind.
      final categoryMaps = await Future.wait([
        _fetchCategoryMap(
          serverUrl: serverUrl,
          username: username,
          password: userPass,
          portOverride: portOverride,
          action: 'live',
          allowInsecureCertificates: allowInsecureTls,
        ),
        _fetchCategoryMap(
          serverUrl: serverUrl,
          username: username,
          password: userPass,
          portOverride: portOverride,
          action: 'vod',
          allowInsecureCertificates: allowInsecureTls,
        ),
        _fetchCategoryMap(
          serverUrl: serverUrl,
          username: username,
          password: userPass,
          portOverride: portOverride,
          action: 'series',
          allowInsecureCertificates: allowInsecureTls,
        ),
      ]);
      final liveCatMap = categoryMaps[0];
      final vodCatMap = categoryMaps[1];
      final seriesCatMap = categoryMaps[2];

      final liveResult = await _xtreamDataSource.getLiveStreams(
        serverUrl: serverUrl,
        username: username,
        password: userPass,
        portOverride: portOverride,
        allowInsecureCertificates: allowInsecureTls,
      );
      if (liveResult case Failure(:final failure)) {
        return Failure(failure);
      }
      final liveStreams = liveResult.when(
          success: (s) => s, failure: (_) => <XtreamLiveStream>[]);

      final vodStreams = await _fetchStreamsOrEmpty(
        fetch: () => _xtreamDataSource.getVodStreams(
          serverUrl: serverUrl,
          username: username,
          password: userPass,
          portOverride: portOverride,
          allowInsecureCertificates: allowInsecureTls,
        ),
        context: 'VOD',
      );

      final seriesList = await _fetchStreamsOrEmpty(
        fetch: () => _xtreamDataSource.getSeries(
          serverUrl: serverUrl,
          username: username,
          password: userPass,
          portOverride: portOverride,
          allowInsecureCertificates: allowInsecureTls,
        ),
        context: 'séries',
      );

      // Build all rows in memory (pure), then write in one transaction.
      final liveCompanions = _liveToCompanions(
        streams: liveStreams,
        playlistId: 0,
        serverUrl: serverUrl,
        username: username,
        userPass: userPass,
        portOverride: portOverride,
        categoryMap: liveCatMap,
      );
      final vodContent = _vodToCompanions(
        movies: vodStreams,
        playlistId: 0,
        serverUrl: serverUrl,
        username: username,
        userPass: userPass,
        portOverride: portOverride,
        categoryMap: vodCatMap,
      );
      final seriesContent = _seriesToCompanions(
        seriesList: seriesList,
        playlistId: 0,
        categoryMap: seriesCatMap,
      );

      final playlistId = await _db.playlistsDao.insertPlaylist(
        PlaylistsCompanion.insert(
          name: name,
          type: PlaylistType.xtream,
          url: Value(serverUrl),
          epgUrl: Value(epgUrl),
          username: Value(username),
          credentialKey: Value(credentialKey),
          xtreamPortOverride: Value(portOverride),
          allowInsecureTls: Value(allowInsecureTls),
          lastSyncAt: Value(DateTime.now()),
          syncStatus: const Value(PlaylistSyncStatus.idle),
        ),
      );

      final allChannels = [
        ..._rebind(liveCompanions, playlistId),
        ..._rebind(vodContent.channels, playlistId),
        ..._rebind(seriesContent.channels, playlistId),
      ];

      await _db.transaction(() async {
        await _db.channelsDao.insertChannels(allChannels);
        if (vodContent.items.isNotEmpty) {
          await _db.vodDao.insertVodBatch(
            _rebindVodItems(vodContent.items, playlistId),
          );
        }
        if (seriesContent.items.isNotEmpty) {
          await _db.seriesDao.insertSeriesBatch(
            _rebindSeriesItems(seriesContent.items, playlistId),
          );
        }

        await _cacheCategories(
          playlistId: playlistId,
          liveCatMap: liveCatMap,
          vodCatMap: vodCatMap,
          seriesCatMap: seriesCatMap,
        );

        await _db.playlistsDao.updateSyncStatus(
          playlistId,
          status: PlaylistSyncStatus.idle,
          syncedAt: DateTime.now(),
        );
      });

      appLogger.i(
        'Imported Xtream "$name" (account: $accountStatus): '
        '${liveStreams.length} live, ${vodStreams.length} vod, '
        '${seriesList.length} series',
      );

      return Success(
        PlaylistImportResult(
          playlistId: playlistId,
          channelsAdded: allChannels.length,
          channelsUpdated: 0,
          channelsDeactivated: 0,
          parseErrors: 0,
          vodItemsImported: vodContent.items.length,
          seriesImported: seriesContent.items.length,
        ),
      );
    } catch (e) {
      return Failure(
        DatabaseFailure(
          message: 'Erro ao salvar a fonte Xtream.',
          originalError: e,
        ),
      );
    }
  }

  /// Refreshes an existing Xtream playlist.
  ///
  /// Reconciles live channels by `sourceId` (spec §19) using a diff and a
  /// single batch — removed channels are deactivated, never deleted, so
  /// favorites and history are preserved. VOD/series are reconciled in the
  /// background via their own repositories.
  Future<Result<PlaylistImportResult>> refreshXtream(int playlistId) async {
    final playlist = await _db.playlistsDao.getPlaylistById(playlistId);
    if (playlist == null) {
      return const Failure(
        DatabaseFailure(message: 'Fonte não encontrada.'),
      );
    }

    final credResult = await _credentialStore.read(
      key: playlist.credentialKey ?? '',
    );
    final userPass = credResult.when(
      success: (val) => val,
      failure: (f) {
        appLogger.w(
          'Xtream import (playlist $playlistId): falha ao ler credenciais: '
          '${f.message}',
        );
        return null;
      },
    );

    if (userPass == null || userPass.isEmpty) {
      return const Failure(
        CredentialFailure(
          message: 'Credenciais não encontradas. Recadastre a fonte.',
        ),
      );
    }

    await _db.playlistsDao.updateSyncStatus(
      playlistId,
      status: PlaylistSyncStatus.syncing,
    );

    try {
      final authResult = await _xtreamDataSource.authenticate(
        serverUrl: playlist.url,
        username: playlist.username ?? '',
        password: userPass,
        portOverride: playlist.xtreamPortOverride,
        allowInsecureCertificates: playlist.allowInsecureTls,
      );
      if (authResult case Failure(:final failure)) {
        await _db.playlistsDao.updateSyncStatus(
          playlistId,
          status: PlaylistSyncStatus.error,
        );
        return Failure(failure);
      }

      final streamsResult = await _xtreamDataSource.getLiveStreams(
        serverUrl: playlist.url,
        username: playlist.username ?? '',
        password: userPass,
        portOverride: playlist.xtreamPortOverride,
        allowInsecureCertificates: playlist.allowInsecureTls,
      );
      if (streamsResult case Failure(:final failure)) {
        await _db.playlistsDao.updateSyncStatus(
          playlistId,
          status: PlaylistSyncStatus.error,
        );
        return Failure(failure);
      }
      final streams = streamsResult.when(
        success: (s) => s,
        failure: (_) => <XtreamLiveStream>[],
      );

      final result = await _reconcileXtreamPlaylist(
        playlistId: playlistId,
        serverUrl: playlist.url,
        username: playlist.username ?? '',
        userPass: userPass,
        portOverride: playlist.xtreamPortOverride,
        allowInsecureTls: playlist.allowInsecureTls,
        streams: streams,
      );

      // VOD/series refresh in the background — failures logged, non-blocking.
      _refreshVodAndSeriesInBackground(playlistId);

      return result;
    } catch (e) {
      await _db.playlistsDao.updateSyncStatus(
        playlistId,
        status: PlaylistSyncStatus.error,
      );
      return Failure(
        UnknownFailure(
          message: 'Erro ao atualizar a fonte.',
          originalError: e,
        ),
      );
    }
  }

  Future<Result<PlaylistImportResult>> _reconcileXtreamPlaylist({
    required int playlistId,
    required String serverUrl,
    required String username,
    required String userPass,
    required int? portOverride,
    required bool allowInsecureTls,
    required List<XtreamLiveStream> streams,
  }) async {
    try {
      final liveCatMap = await _fetchCategoryMap(
        serverUrl: serverUrl,
        username: username,
        password: userPass,
        portOverride: portOverride,
        action: 'live',
        allowInsecureCertificates: allowInsecureTls,
      );

      // Only live rows take part in the live reconciliation — VOD/series
      // rows have their own sourceId space and are reconciled separately.
      final existing = await _db.channelsDao.getAllChannelsByPlaylistAndType(
        playlistId,
        ChannelSourceType.xtream,
      );

      final existingBySourceId = <String, Channel>{};
      for (final ch in existing) {
        if (ch.sourceId != null) {
          existingBySourceId[ch.sourceId!] = ch;
        }
      }

      // Diff phase.
      final toInsert = <ChannelsCompanion>[];
      final toUpdate = <int, ChannelsCompanion>{};
      final toActivate = <int>[];
      final matchedIds = <int>{};

      for (final stream in streams) {
        final sourceId = stream.streamId.toString();
        final streamUrl = _xtreamDataSource.buildStreamUrl(
          serverUrl: serverUrl,
          username: username,
          password: userPass,
          streamId: stream.streamId,
          portOverride: portOverride,
          extension: stream.containerExtension ?? 'ts',
        );

        final existingCh = existingBySourceId[sourceId];

        if (existingCh != null) {
          matchedIds.add(existingCh.id);
          if (existingCh.name != stream.name ||
              existingCh.streamUrl != streamUrl ||
              existingCh.logoUrl != stream.streamIcon) {
            toUpdate[existingCh.id] = ChannelsCompanion(
              name: Value(stream.name),
              streamUrl: Value(streamUrl),
              logoUrl: Value(stream.streamIcon),
              isActive: const Value(true),
              updatedAt: Value(DateTime.now()),
            );
          } else if (!existingCh.isActive) {
            toActivate.add(existingCh.id);
          }
        } else {
          toInsert.add(
            ChannelsCompanion.insert(
              playlistId: playlistId,
              name: stream.name,
              streamUrl: streamUrl,
              sourceType: ChannelSourceType.xtream,
              sourceId: Value(sourceId),
              logoUrl: Value(stream.streamIcon),
              groupName: Value(
                liveCatMap[stream.categoryId] ?? stream.categoryId,
              ),
              tvgId: Value(stream.epgChannelId),
            ),
          );
        }
      }

      final toDeactivate = existing
          .where((ch) => !matchedIds.contains(ch.id))
          .map((ch) => ch.id)
          .toList();

      final added = toInsert.length;
      final updated = toUpdate.length + toActivate.length;
      final deactivated = toDeactivate.length;

      // Write phase: one transactional batch.
      await _db.transaction(() async {
        await _db.batch((b) {
          if (toInsert.isNotEmpty) {
            b.insertAll(_db.channels, toInsert);
          }
          toUpdate.forEach((id, companion) {
            b.update(
              _db.channels,
              companion,
              where: (c) => c.id.equals(id),
            );
          });
          if (toActivate.isNotEmpty) {
            b.update(
              _db.channels,
              ChannelsCompanion(
                isActive: const Value(true),
                updatedAt: Value(DateTime.now()),
              ),
              where: (c) => c.id.isIn(toActivate),
            );
          }
          if (toDeactivate.isNotEmpty) {
            b.update(
              _db.channels,
              ChannelsCompanion(
                isActive: const Value(false),
                updatedAt: Value(DateTime.now()),
              ),
              where: (c) => c.id.isIn(toDeactivate),
            );
          }
        });

        if (liveCatMap.isNotEmpty) {
          await _db.categoryCacheDao.ensureTable();
          await _db.categoryCacheDao.upsertCategories(
            playlistId: playlistId,
            categoryMap: liveCatMap,
            sourceType: 'live',
          );
        }

        await _db.playlistsDao.updateSyncStatus(
          playlistId,
          status: PlaylistSyncStatus.idle,
          syncedAt: DateTime.now(),
        );
      });

      appLogger.i(
        'Refreshed Xtream $playlistId: +$added, ~$updated, -$deactivated',
      );

      return Success(
        PlaylistImportResult(
          playlistId: playlistId,
          channelsAdded: added,
          channelsUpdated: updated,
          channelsDeactivated: deactivated,
          parseErrors: 0,
        ),
      );
    } catch (e) {
      await _db.playlistsDao.updateSyncStatus(
        playlistId,
        status: PlaylistSyncStatus.error,
      );
      return Failure(
        DatabaseFailure(
          message: 'Erro na reconciliação Xtream.',
          originalError: e,
        ),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Row builders (pure)
  // ─────────────────────────────────────────────────────────────────────────

  List<ChannelsCompanion> _liveToCompanions({
    required List<XtreamLiveStream> streams,
    required int playlistId,
    required String serverUrl,
    required String username,
    required String userPass,
    required int? portOverride,
    required Map<String, String> categoryMap,
  }) {
    return streams.map((stream) {
      final streamUrl = _xtreamDataSource.buildStreamUrl(
        serverUrl: serverUrl,
        username: username,
        password: userPass,
        streamId: stream.streamId,
        portOverride: portOverride,
        extension: stream.containerExtension ?? 'ts',
      );

      return ChannelsCompanion.insert(
        playlistId: playlistId,
        name: stream.name,
        streamUrl: streamUrl,
        sourceType: ChannelSourceType.xtream,
        sourceId: Value(stream.streamId.toString()),
        logoUrl: Value(stream.streamIcon),
        groupName: Value(categoryMap[stream.categoryId] ?? stream.categoryId),
        tvgId: Value(stream.epgChannelId),
      );
    }).toList();
  }

  ({List<ChannelsCompanion> channels, List<VodItemsCompanion> items})
      _vodToCompanions({
    required List<XtreamVodStream> movies,
    required int playlistId,
    required String serverUrl,
    required String username,
    required String userPass,
    required int? portOverride,
    required Map<String, String> categoryMap,
  }) {
    final channels = <ChannelsCompanion>[];
    final items = <VodItemsCompanion>[];

    for (final movie in movies) {
      final streamUrl = _xtreamDataSource.buildVodStreamUrl(
        serverUrl: serverUrl,
        username: username,
        password: userPass,
        streamId: movie.streamId,
        portOverride: portOverride,
        extension: movie.containerExtension ?? 'mp4',
      );
      final cat = categoryMap[movie.categoryId] ?? movie.categoryId;

      channels.add(
        ChannelsCompanion.insert(
          playlistId: playlistId,
          name: movie.name,
          streamUrl: streamUrl,
          sourceType: ChannelSourceType.vod,
          sourceId: Value(movie.streamId.toString()),
          logoUrl: Value(movie.streamIcon),
          groupName: Value(cat),
        ),
      );
      items.add(
        VodItemsCompanion.insert(
          playlistId: playlistId,
          sourceId: movie.streamId.toString(),
          name: movie.name,
          streamUrl: streamUrl,
          logoUrl: Value(movie.streamIcon),
          categoryName: Value(cat),
          containerExtension: Value(movie.containerExtension ?? 'mp4'),
        ),
      );
    }

    return (channels: channels, items: items);
  }

  ({List<ChannelsCompanion> channels, List<SeriesItemsCompanion> items})
      _seriesToCompanions({
    required List<XtreamSeries> seriesList,
    required int playlistId,
    required Map<String, String> categoryMap,
  }) {
    final channels = <ChannelsCompanion>[];
    final items = <SeriesItemsCompanion>[];

    for (final s in seriesList) {
      final cat = categoryMap[s.categoryId] ?? s.categoryId;
      final sourceIdStr = s.seriesId.toString();

      channels.add(
        ChannelsCompanion.insert(
          playlistId: playlistId,
          name: s.name,
          streamUrl: '',
          sourceType: ChannelSourceType.series,
          sourceId: Value(sourceIdStr),
          logoUrl: Value(s.cover),
          groupName: Value(cat),
        ),
      );
      items.add(
        SeriesItemsCompanion.insert(
          playlistId: playlistId,
          sourceId: sourceIdStr,
          name: s.name,
          coverUrl: Value(s.cover),
          categoryName: Value(cat),
          plot: Value(s.plot),
          cast: Value(s.cast),
          director: Value(s.director),
          genre: Value(s.genre),
          rating: Value(s.rating),
          year: Value(s.year),
          backdropUrl: Value(s.backdropPath),
        ),
      );
    }

    return (channels: channels, items: items);
  }

  /// Rebinds companions built against a placeholder playlistId (0) to the
  /// real one, so row building stays decoupled from row insertion.
  List<ChannelsCompanion> _rebind(
    List<ChannelsCompanion> companions,
    int playlistId,
  ) {
    return companions
        .map(
          (c) => c.copyWith(playlistId: Value(playlistId)),
        )
        .toList();
  }

  List<VodItemsCompanion> _rebindVodItems(
    List<VodItemsCompanion> items,
    int playlistId,
  ) {
    return items.map((i) => i.copyWith(playlistId: Value(playlistId))).toList();
  }

  List<SeriesItemsCompanion> _rebindSeriesItems(
    List<SeriesItemsCompanion> items,
    int playlistId,
  ) {
    return items.map((i) => i.copyWith(playlistId: Value(playlistId))).toList();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Background helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Refreshes VOD and series content in the background.
  /// Failures are logged but don't affect the main refresh result.
  void _refreshVodAndSeriesInBackground(int playlistId) {
    _vodImportRepository.refreshVod(playlistId).then(
          (result) => result.when(
            success: (r) =>
                appLogger.i('VOD refresh: +${r.moviesAdded} movies'),
            failure: (f) => appLogger.w('VOD refresh failed: ${f.message}'),
          ),
          onError: (e) => appLogger.w('VOD refresh crashed: $e'),
        );

    _seriesImportRepository.refreshSeries(playlistId).then(
          (result) => result.when(
            success: (r) =>
                appLogger.i('Series refresh: +${r.seriesAdded} series'),
            failure: (f) => appLogger.w('Series refresh failed: ${f.message}'),
          ),
          onError: (e) => appLogger.w('Series refresh crashed: $e'),
        );
  }

  /// Fetches content-type streams; failures are logged and return an empty
  /// list (VOD/series must not block the import of live channels).
  Future<List<T>> _fetchStreamsOrEmpty<T>({
    required Future<Result<List<T>>> Function() fetch,
    required String context,
  }) async {
    try {
      final result = await fetch();
      return await result.when(
        success: (items) => items,
        failure: (f) {
          appLogger.w('Xtream import: $context fetch failed: ${f.message}');
          return const [];
        },
      );
    } catch (e) {
      appLogger.w('Xtream import: $context fetch crashed: $e');
      return const [];
    }
  }

  /// Fetches a category name map (id → name). Returns an empty map on
  /// failure (non-blocking) — group names fall back to the raw id.
  Future<Map<String, String>> _fetchCategoryMap({
    required String serverUrl,
    required String username,
    required String password,
    required String action,
    int? portOverride,
    bool allowInsecureCertificates = false,
  }) async {
    final map = <String, String>{};
    try {
      final result = switch (action) {
        'live' => await _xtreamDataSource.getLiveCategories(
            serverUrl: serverUrl,
            username: username,
            password: password,
            portOverride: portOverride,
            allowInsecureCertificates: allowInsecureCertificates,
          ),
        'vod' => await _xtreamDataSource.getVodCategories(
            serverUrl: serverUrl,
            username: username,
            password: password,
            portOverride: portOverride,
            allowInsecureCertificates: allowInsecureCertificates,
          ),
        'series' => await _xtreamDataSource.getSeriesCategories(
            serverUrl: serverUrl,
            username: username,
            password: password,
            portOverride: portOverride,
            allowInsecureCertificates: allowInsecureCertificates,
          ),
        _ => await _xtreamDataSource.getLiveCategories(
            serverUrl: serverUrl,
            username: username,
            password: password,
            portOverride: portOverride,
            allowInsecureCertificates: allowInsecureCertificates,
          ),
      };
      result.when(
        success: (categories) {
          for (final cat in categories) {
            map[cat.categoryId] = cat.categoryName;
          }
        },
        failure: (f) =>
            appLogger.w('Xtream import: category fetch failed: ${f.message}'),
      );
    } catch (e) {
      appLogger.w('Xtream import: category fetch crashed: $e');
    }
    return map;
  }

  /// Caches live/VOD/series category names for future id → name resolution.
  Future<void> _cacheCategories({
    required int playlistId,
    required Map<String, String> liveCatMap,
    required Map<String, String> vodCatMap,
    required Map<String, String> seriesCatMap,
  }) async {
    await _db.categoryCacheDao.ensureTable();
    for (final entry in {
      'live': liveCatMap,
      'vod': vodCatMap,
      'series': seriesCatMap,
    }.entries) {
      if (entry.value.isNotEmpty) {
        await _db.categoryCacheDao.upsertCategories(
          playlistId: playlistId,
          categoryMap: entry.value,
          sourceType: entry.key,
        );
      }
    }
  }
}
