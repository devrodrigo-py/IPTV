import 'package:drift/drift.dart';
import 'package:nebula_iptv/core/credentials/credential_store.dart';
import 'package:nebula_iptv/core/errors/app_failure.dart';
import 'package:nebula_iptv/core/logging/app_logger.dart';
import 'package:nebula_iptv/core/result/result.dart';
import 'package:nebula_iptv/data/database/app_database.dart';
import 'package:nebula_iptv/data/datasources/xtream/xtream_datasource.dart';
import 'package:nebula_iptv/data/datasources/xtream/xtream_models.dart';

/// Result of importing VOD content.
class VodImportResult {
  final int playlistId;
  final int moviesAdded;
  final int moviesUpdated;
  final int moviesDeactivated;

  const VodImportResult({
    required this.playlistId,
    required this.moviesAdded,
    required this.moviesUpdated,
    required this.moviesDeactivated,
  });

  int get totalMovies => moviesAdded + moviesUpdated;
}

/// Repository for importing and syncing VOD (movies) from Xtream Codes.
class VodImportRepository {
  final AppDatabase _db;
  final XtreamDataSource _xtreamDataSource;
  final CredentialStore _credentialStore;

  VodImportRepository({
    required AppDatabase db,
    required XtreamDataSource xtreamDataSource,
    required CredentialStore credentialStore,
  })  : _db = db,
        _xtreamDataSource = xtreamDataSource,
        _credentialStore = credentialStore;

  /// Imports VOD content for an existing Xtream playlist.
  Future<Result<VodImportResult>> importVod({
    required int playlistId,
    required String serverUrl,
    required String username,
    required String password,
    int? portOverride,
  }) async {
    final streamsResult = await _xtreamDataSource.getVodStreams(
      serverUrl: serverUrl,
      username: username,
      password: password,
      portOverride: portOverride,
    );

    return await streamsResult.when(
      success: (streams) => _persistVod(
        playlistId: playlistId,
        serverUrl: serverUrl,
        username: username,
        password: password,
        portOverride: portOverride,
        streams: streams,
      ),
      failure: (f) => Failure(f),
    );
  }

  /// Refreshes VOD content for an existing playlist.
  Future<Result<VodImportResult>> refreshVod(int playlistId) async {
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

    return importVod(
      playlistId: playlistId,
      serverUrl: playlist.url,
      username: playlist.username ?? '',
      password: userPass,
      portOverride: playlist.xtreamPortOverride,
    );
  }

  Future<Result<VodImportResult>> _persistVod({
    required int playlistId,
    required String serverUrl,
    required String username,
    required String password,
    required List<XtreamVodStream> streams,
    int? portOverride,
  }) async {
    try {
      // Fetch VOD category names to resolve numeric IDs
      final categoryMap = <String, String>{};
      try {
        final catResult = await _xtreamDataSource.getVodCategories(
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

      // Get existing VOD items for reconciliation
      final existing = await _db.vodDao.getVodByPlaylist(playlistId);
      final existingBySourceId = <String, VodItem>{};
      for (final vod in existing) {
        existingBySourceId[vod.sourceId] = vod;
      }

      final matchedIds = <int>{};
      var added = 0;
      var updated = 0;

      for (final stream in streams) {
        final sourceId = stream.streamId.toString();
        final streamUrl = _xtreamDataSource.buildVodStreamUrl(
          serverUrl: serverUrl,
          username: username,
          password: password,
          streamId: stream.streamId,
          portOverride: portOverride,
          extension: stream.containerExtension ?? 'mp4',
        );

        final existingVod = existingBySourceId[sourceId];

        if (existingVod != null) {
          matchedIds.add(existingVod.id);
          // Update if changed
          if (existingVod.name != stream.name ||
              existingVod.streamUrl != streamUrl ||
              existingVod.logoUrl != stream.streamIcon) {
            await (_db.update(_db.vodItems)
                  ..where((v) => v.id.equals(existingVod.id)))
                .write(
              VodItemsCompanion(
                name: Value(stream.name),
                streamUrl: Value(streamUrl),
                logoUrl: Value(stream.streamIcon),
                plot: Value(stream.plot),
                cast: Value(stream.cast),
                director: Value(stream.director),
                genre: Value(stream.genre),
                rating: Value(stream.rating),
                year: Value(stream.year),
                isActive: const Value(true),
                updatedAt: Value(DateTime.now()),
              ),
            );
            updated++;
          } else if (!existingVod.isActive) {
            await (_db.update(_db.vodItems)
                  ..where((v) => v.id.equals(existingVod.id)))
                .write(
              VodItemsCompanion(
                isActive: const Value(true),
                updatedAt: Value(DateTime.now()),
              ),
            );
            updated++;
          }
        } else {
          await _db.vodDao.insertVod(
            VodItemsCompanion.insert(
              playlistId: playlistId,
              sourceId: sourceId,
              name: stream.name,
              streamUrl: streamUrl,
              logoUrl: Value(stream.streamIcon),
              categoryName: Value(categoryMap[stream.categoryId] ?? stream.categoryId),
              plot: Value(stream.plot),
              cast: Value(stream.cast),
              director: Value(stream.director),
              genre: Value(stream.genre),
              rating: Value(stream.rating),
              year: Value(stream.year),
              containerExtension:
                  Value(stream.containerExtension ?? 'mp4'),
            ),
          );
          added++;
        }
      }

      // Deactivate items no longer in the source
      var deactivated = 0;
      for (final vod in existing) {
        if (!matchedIds.contains(vod.id)) {
          await (_db.update(_db.vodItems)
                ..where((v) => v.id.equals(vod.id)))
              .write(
            VodItemsCompanion(
              isActive: const Value(false),
              updatedAt: Value(DateTime.now()),
            ),
          );
          deactivated++;
        }
      }

      appLogger.i(
        'VOD import for playlist $playlistId: '
        '+$added, ~$updated, -$deactivated',
      );

      return Success(
        VodImportResult(
          playlistId: playlistId,
          moviesAdded: added,
          moviesUpdated: updated,
          moviesDeactivated: deactivated,
        ),
      );
    } catch (e) {
      return Failure(
        DatabaseFailure(
          message: 'Erro ao importar filmes.',
          originalError: e,
        ),
      );
    }
  }
}
