import 'package:drift/drift.dart';
import 'package:nebula_iptv/core/credentials/credential_store.dart';
import 'package:nebula_iptv/core/errors/app_failure.dart';
import 'package:nebula_iptv/core/logging/app_logger.dart';
import 'package:nebula_iptv/core/result/result.dart';
import 'package:nebula_iptv/data/database/app_database.dart';
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
      failure: (_) => null,
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
      failure: (_) => null,
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
          failure: (_) {},
        );
      } catch (_) {}

      final existing = await _db.seriesDao.getSeriesByPlaylist(playlistId);
      final existingBySourceId = <String, SeriesItem>{};
      for (final s in existing) {
        existingBySourceId[s.sourceId] = s;
      }

      final matchedIds = <int>{};
      var added = 0;
      var updated = 0;

      for (final series in seriesList) {
        final sourceId = series.seriesId.toString();
        final existingSeries = existingBySourceId[sourceId];

        if (existingSeries != null) {
          matchedIds.add(existingSeries.id);
          // Update if changed
          if (existingSeries.name != series.name ||
              existingSeries.coverUrl != series.cover ||
              existingSeries.rating != series.rating) {
            await (_db.update(_db.seriesItems)
                  ..where((s) => s.id.equals(existingSeries.id)))
                .write(
              SeriesItemsCompanion(
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
              ),
            );
            updated++;
          } else if (!existingSeries.isActive) {
            await (_db.update(_db.seriesItems)
                  ..where((s) => s.id.equals(existingSeries.id)))
                .write(
              SeriesItemsCompanion(
                isActive: const Value(true),
                updatedAt: Value(DateTime.now()),
              ),
            );
            updated++;
          }
        } else {
          await _db.seriesDao.insertSeries(
            SeriesItemsCompanion.insert(
              playlistId: playlistId,
              sourceId: sourceId,
              name: series.name,
              coverUrl: Value(series.cover),
              categoryName: Value(categoryMap[series.categoryId] ?? series.categoryId),
              plot: Value(series.plot),
              cast: Value(series.cast),
              director: Value(series.director),
              genre: Value(series.genre),
              rating: Value(series.rating),
              year: Value(series.year),
              backdropUrl: Value(series.backdropPath),
            ),
          );
          added++;
        }
      }

      // Deactivate series no longer in the source
      var deactivated = 0;
      for (final s in existing) {
        if (!matchedIds.contains(s.id)) {
          await (_db.update(_db.seriesItems)
                ..where((si) => si.id.equals(s.id)))
              .write(
            SeriesItemsCompanion(
              isActive: const Value(false),
              updatedAt: Value(DateTime.now()),
            ),
          );
          deactivated++;
        }
      }

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
              containerExtension:
                  Value(episode.containerExtension ?? 'mp4'),
              plot: Value(episode.plot),
              duration: Value(episode.durationSecs),
              coverUrl: Value(episode.coverBig),
              rating: Value(episode.rating),
              releaseDate: Value(episode.releaseDate),
            ),
          );
        }
      }

      final totalEpisodes = info.episodes.values
          .fold<int>(0, (sum, list) => sum + list.length);

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
