import 'package:drift/drift.dart';
import 'package:nebula_iptv/core/credentials/credential_store.dart';
import 'package:nebula_iptv/core/errors/app_failure.dart';
import 'package:nebula_iptv/core/logging/app_logger.dart';
import 'package:nebula_iptv/core/result/result.dart';
import 'package:nebula_iptv/data/database/app_database.dart';
import 'package:nebula_iptv/data/database/tables/channels_table.dart';
import 'package:nebula_iptv/data/datasources/xtream/xtream_datasource.dart';
import 'package:nebula_iptv/data/datasources/xtream/xtream_models.dart';

/// Result of importing series content.
class SeriesImportResult {
  final int playlistId;
  final int seriesAdded;
  final int seriesUpdated;
  final int seriesDeactivated;

  const SeriesImportResult({
    required this.playlistId,
    required this.seriesAdded,
    required this.seriesUpdated,
    required this.seriesDeactivated,
  });

  int get totalSeries => seriesAdded + seriesUpdated;
}

/// Repository for importing and syncing series from Xtream Codes.
class SeriesImportRepository {
  final AppDatabase _db;
  final XtreamDataSource _xtreamDataSource;
  final CredentialStore _credentialStore;

  SeriesImportRepository({
    required AppDatabase db,
    required XtreamDataSource xtreamDataSource,
    required CredentialStore credentialStore,
  })  : _db = db,
        _xtreamDataSource = xtreamDataSource,
        _credentialStore = credentialStore;

  /// Imports series list for an existing Xtream playlist.
  Future<Result<SeriesImportResult>> importSeries({
    required int playlistId,
    required String serverUrl,
    required String username,
    required String password,
    int? portOverride,
  }) async {
    final seriesResult = await _xtreamDataSource.getSeries(
      serverUrl: serverUrl,
      username: username,
      password: password,
      portOverride: portOverride,
    );

    return await seriesResult.when(
      success: (seriesList) => _persistSeries(
        playlistId: playlistId,
        serverUrl: serverUrl,
        username: username,
        password: password,
        portOverride: portOverride,
        seriesList: seriesList,
      ),
      failure: (f) => Failure(f),
    );
  }

  /// Refreshes series for an existing playlist.
  Future<Result<SeriesImportResult>> refreshSeries(int playlistId) async {
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
          'Series import (playlist $playlistId): falha ao ler credenciais: '
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

    return importSeries(
      playlistId: playlistId,
      serverUrl: playlist.url,
      username: playlist.username ?? '',
      password: userPass,
      portOverride: playlist.xtreamPortOverride,
    );
  }

  /// Fetches and persists detailed series info (seasons + episodes).
  Future<Result<void>> importSeriesDetails({
    required int seriesDbId,
    required int xtreamSeriesId,
    required String serverUrl,
    required String username,
    required String password,
    int? portOverride,
  }) async {
    final infoResult = await _xtreamDataSource.getSeriesInfo(
      serverUrl: serverUrl,
      username: username,
      password: password,
      seriesId: xtreamSeriesId,
      portOverride: portOverride,
    );

    return await infoResult.when(
      success: (info) => _persistSeriesDetails(
        seriesDbId: seriesDbId,
        serverUrl: serverUrl,
        username: username,
        password: password,
        portOverride: portOverride,
        info: info,
      ),
      failure: (f) => Failure(f),
    );
  }

  /// Fetches series details using stored credentials.
  Future<Result<void>> importSeriesDetailsFromPlaylist({
    required int seriesDbId,
    required int xtreamSeriesId,
    required int playlistId,
  }) async {
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
          'Series details (playlist $playlistId): falha ao ler credenciais: '
          '${f.message}',
        );
        return null;
      },
    );

    if (userPass == null || userPass.isEmpty) {
      return const Failure(
        CredentialFailure(
          message: 'Credenciais não encontradas.',
        ),
      );
    }

    return importSeriesDetails(
      seriesDbId: seriesDbId,
      xtreamSeriesId: xtreamSeriesId,
      serverUrl: playlist.url,
      username: playlist.username ?? '',
      password: userPass,
      portOverride: playlist.xtreamPortOverride,
    );
  }

  Future<Result<SeriesImportResult>> _persistSeries({
    required int playlistId,
    required String serverUrl,
    required String username,
    required String password,
    required List<XtreamSeries> seriesList,
    int? portOverride,
  }) async {
    try {
      // Fetch series category names to resolve numeric IDs
      final categoryMap = <String, String>{};
      try {
        final catResult = await _xtreamDataSource.getSeriesCategories(
          serverUrl: serverUrl,
          username: username,
          password: password,
          portOverride: portOverride,
        );
        catResult.when(
          success: (categories) {
            for (final cat in categories) {
              categoryMap[cat.categoryId] = cat.categoryName;
            }
          },
          failure: (f) => appLogger.w(
            'Series import (playlist $playlistId): falha ao buscar categorias: '
            '${f.message}',
          ),
        );
      } catch (e) {
        appLogger.w(
          'Series import (playlist $playlistId): erro ao buscar categorias: $e',
        );
      }

      // Reconcile against the full set including deactivated rows, so a
      // series that left the source and came back reactivates (never
      // duplicates).
      final existing = await _db.seriesDao.getAllSeriesByPlaylist(playlistId);
      final existingBySourceId = <String, SeriesItem>{};
      for (final s in existing) {
        existingBySourceId[s.sourceId] = s;
      }

      final toInsert = <SeriesItemsCompanion>[];
      final toUpdate = <int, SeriesItemsCompanion>{};
      final toActivate = <int>[];
      final matchedIds = <int>{};

      for (final series in seriesList) {
        final sourceId = series.seriesId.toString();
        final existingSeries = existingBySourceId[sourceId];

        if (existingSeries != null) {
          matchedIds.add(existingSeries.id);
          if (existingSeries.name != series.name ||
              existingSeries.coverUrl != series.cover ||
              existingSeries.rating != series.rating) {
            toUpdate[existingSeries.id] = SeriesItemsCompanion(
              name: Value(series.name),
              coverUrl: Value(series.cover),
              plot: Value(series.plot),
              cast: Value(series.cast),
              director: Value(series.director),
              genre: Value(series.genre),
              rating: Value(series.rating),
              year: Value(series.year),
              backdropUrl: Value(series.backdropPath),
              isActive: const Value(true),
              updatedAt: Value(DateTime.now()),
            );
          } else if (!existingSeries.isActive) {
            toActivate.add(existingSeries.id);
          }
        } else {
          toInsert.add(
            SeriesItemsCompanion.insert(
              playlistId: playlistId,
              sourceId: sourceId,
              name: series.name,
              coverUrl: Value(series.cover),
              categoryName:
                  Value(categoryMap[series.categoryId] ?? series.categoryId),
              plot: Value(series.plot),
              cast: Value(series.cast),
              director: Value(series.director),
              genre: Value(series.genre),
              rating: Value(series.rating),
              year: Value(series.year),
              backdropUrl: Value(series.backdropPath),
            ),
          );
        }
      }

      final toDeactivate = existing
          .where((s) => s.isActive && !matchedIds.contains(s.id))
          .map((s) => s.id)
          .toList();

      final added = toInsert.length;
      final updated = toUpdate.length + toActivate.length;
      final deactivated = toDeactivate.length;

      // Single atomic pass: series_items + the channels-table mirror rows,
      // both reconciled as batch operations inside one transaction.
      await _db.transaction(() async {
        await _db.batch((b) {
          if (toInsert.isNotEmpty) {
            b.insertAll(_db.seriesItems, toInsert);
          }
          toUpdate.forEach((id, companion) {
            b.update(_db.seriesItems, companion, where: (s) => s.id.equals(id));
          });
          if (toActivate.isNotEmpty) {
            b.update(
              _db.seriesItems,
              SeriesItemsCompanion(
                isActive: const Value(true),
                updatedAt: Value(DateTime.now()),
              ),
              where: (s) => s.id.isIn(toActivate),
            );
          }
          if (toDeactivate.isNotEmpty) {
            b.update(
              _db.seriesItems,
              SeriesItemsCompanion(
                isActive: const Value(false),
                updatedAt: Value(DateTime.now()),
              ),
              where: (s) => s.id.isIn(toDeactivate),
            );
          }
        });

        await _reconcileChannelRows(
          playlistId: playlistId,
          categoryMap: categoryMap,
          seriesList: seriesList,
        );
      });

      appLogger.i(
        'Series import for playlist $playlistId: '
        '+$added, ~$updated, -$deactivated',
      );

      return Success(
        SeriesImportResult(
          playlistId: playlistId,
          seriesAdded: added,
          seriesUpdated: updated,
          seriesDeactivated: deactivated,
        ),
      );
    } catch (e) {
      return Failure(
        DatabaseFailure(
          message: 'Erro ao importar séries.',
          originalError: e,
        ),
      );
    }
  }

  /// Reconciles the `channels` rows backed by series (search/home read from
  /// the channels table). Diff by sourceId, single batch.
  Future<void> _reconcileChannelRows({
    required int playlistId,
    required Map<String, String> categoryMap,
    required List<XtreamSeries> seriesList,
  }) async {
    final existingRows = await _db.channelsDao.getAllChannelsByPlaylistAndType(
      playlistId,
      ChannelSourceType.series,
    );

    final bySourceId = <String, Channel>{};
    for (final row in existingRows) {
      if (row.sourceId != null) {
        bySourceId[row.sourceId!] = row;
      }
    }

    final toInsert = <ChannelsCompanion>[];
    final toUpdate = <int, ChannelsCompanion>{};
    final toActivate = <int>[];
    final matchedIds = <int>{};

    for (final series in seriesList) {
      final sourceId = series.seriesId.toString();
      final row = bySourceId[sourceId];

      if (row != null) {
        matchedIds.add(row.id);
        if (row.name != series.name || row.logoUrl != series.cover) {
          toUpdate[row.id] = ChannelsCompanion(
            name: Value(series.name),
            logoUrl: Value(series.cover),
            groupName: Value(
              categoryMap[series.categoryId] ?? series.categoryId,
            ),
            isActive: const Value(true),
            updatedAt: Value(DateTime.now()),
          );
        } else if (!row.isActive) {
          toActivate.add(row.id);
        }
      } else {
        toInsert.add(
          ChannelsCompanion.insert(
            playlistId: playlistId,
            name: series.name,
            streamUrl: '',
            sourceType: ChannelSourceType.series,
            sourceId: Value(sourceId),
            logoUrl: Value(series.cover),
            groupName: Value(
              categoryMap[series.categoryId] ?? series.categoryId,
            ),
          ),
        );
      }
    }

    final toDeactivate = existingRows
        .where((row) => !matchedIds.contains(row.id))
        .map((row) => row.id)
        .toList();

    await _db.batch((b) {
      if (toInsert.isNotEmpty) {
        b.insertAll(_db.channels, toInsert);
      }
      toUpdate.forEach((id, companion) {
        b.update(_db.channels, companion, where: (c) => c.id.equals(id));
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
  }

  Future<Result<void>> _persistSeriesDetails({
    required int seriesDbId,
    required String serverUrl,
    required String username,
    required String password,
    required XtreamSeriesInfo info,
    int? portOverride,
  }) async {
    try {
      // Clear existing seasons and episodes for this series
      await _db.seriesDao.deleteEpisodesForSeries(seriesDbId);
      await _db.seriesDao.deleteSeasonsForSeries(seriesDbId);

      // Update series info if available
      if (info.info != null) {
        await (_db.update(_db.seriesItems)
              ..where((s) => s.id.equals(seriesDbId)))
            .write(
          SeriesItemsCompanion(
            plot: Value(info.info!.plot),
            cast: Value(info.info!.cast),
            director: Value(info.info!.director),
            genre: Value(info.info!.genre),
            rating: Value(info.info!.rating),
            coverUrl: Value(info.info!.cover),
            backdropUrl: Value(info.info!.backdropPath),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }

      // Insert seasons
      final seasonIdMap = <int, int>{}; // seasonNumber → db ID

      for (final season in info.seasons) {
        final seasonId = await _db.seriesDao.insertSeason(
          SeasonsCompanion.insert(
            seriesId: seriesDbId,
            seasonNumber: season.seasonNumber,
            name: Value(season.name ?? 'Temporada ${season.seasonNumber}'),
            coverUrl: Value(season.coverBig ?? season.cover),
            episodeCount: Value(season.episodeCount),
            airDate: Value(season.airDate),
          ),
        );
        seasonIdMap[season.seasonNumber] = seasonId;
      }

      // Insert episodes
      for (final entry in info.episodes.entries) {
        final seasonNumber = entry.key;
        final episodeList = entry.value;

        // Find or create season ID
        var seasonId = seasonIdMap[seasonNumber];
        if (seasonId == null) {
          // Season not in the seasons list, create it
          seasonId = await _db.seriesDao.insertSeason(
            SeasonsCompanion.insert(
              seriesId: seriesDbId,
              seasonNumber: seasonNumber,
              name: Value('Temporada $seasonNumber'),
            ),
          );
          seasonIdMap[seasonNumber] = seasonId;
        }

        for (final episode in episodeList) {
          final streamUrl = _xtreamDataSource.buildSeriesStreamUrl(
            serverUrl: serverUrl,
            username: username,
            password: password,
            episodeId: episode.id,
            portOverride: portOverride,
            extension: episode.containerExtension ?? 'mp4',
          );

          await _db.seriesDao.insertEpisode(
            EpisodesCompanion.insert(
              seriesId: seriesDbId,
              seasonId: seasonId,
              sourceId: episode.id,
              episodeNumber: episode.episodeNum,
              title: episode.title,
              streamUrl: streamUrl,
              containerExtension: Value(episode.containerExtension ?? 'mp4'),
              plot: Value(episode.plot),
              duration: Value(episode.durationSecs),
              coverUrl: Value(episode.coverBig),
              rating: Value(episode.rating),
              releaseDate: Value(episode.releaseDate),
            ),
          );
        }
      }

      final totalEpisodes =
          info.episodes.values.fold<int>(0, (sum, list) => sum + list.length);

      appLogger.i(
        'Series details for $seriesDbId: '
        '${info.seasons.length} seasons, $totalEpisodes episodes',
      );

      return const Success(null);
    } catch (e) {
      return Failure(
        DatabaseFailure(
          message: 'Erro ao importar detalhes da série.',
          originalError: e,
        ),
      );
    }
  }
}
