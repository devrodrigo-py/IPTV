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

/// Repository for importing and syncing Xtream Codes playlists.
class XtreamImportRepository {
  final AppDatabase _db;
  final XtreamDataSource _xtreamDataSource;
  final CredentialStore _credentialStore;

  XtreamImportRepository({
    required AppDatabase db,
    required XtreamDataSource xtreamDataSource,
    required CredentialStore credentialStore,
  })  : _db = db,
        _xtreamDataSource = xtreamDataSource,
        _credentialStore = credentialStore;

  /// Imports a new Xtream source.
  Future<Result<PlaylistImportResult>> importXtream({
    required String name,
    required String serverUrl,
    required String username,
    required String userPass,
    int? portOverride,
    String? epgUrl,
  }) async {
    final authResult = await _xtreamDataSource.authenticate(
      serverUrl: serverUrl,
      username: username,
      password: userPass,
      portOverride: portOverride,
    );

    return await authResult.when(
      success: (auth) async {
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

        final streamsResult = await _xtreamDataSource.getLiveStreams(
          serverUrl: serverUrl,
          username: username,
          password: userPass,
          portOverride: portOverride,
        );

        return await streamsResult.when(
          success: (streams) => _persistXtreamPlaylist(
            name: name,
            serverUrl: serverUrl,
            username: username,
            credentialKey: credentialKey,
            portOverride: portOverride,
            epgUrl: epgUrl,
            streams: streams,
            userPass: userPass,
          ),
          failure: (f) => Failure(f),
        );
      },
      failure: (f) => Failure(f),
    );
  }

  /// Refreshes an existing Xtream playlist.
  Future<Result<PlaylistImportResult>> refreshXtream(
    int playlistId,
  ) async {
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

    await _db.playlistsDao.updateSyncStatus(
      playlistId,
      status: PlaylistSyncStatus.syncing,
    );

    final authResult = await _xtreamDataSource.authenticate(
      serverUrl: playlist.url,
      username: playlist.username ?? '',
      password: userPass,
      portOverride: playlist.xtreamPortOverride,
    );

    return await authResult.when(
      success: (auth) async {
        final streamsResult = await _xtreamDataSource.getLiveStreams(
          serverUrl: playlist.url,
          username: playlist.username ?? '',
          password: userPass,
          portOverride: playlist.xtreamPortOverride,
        );

        return await streamsResult.when(
          success: (streams) => _reconcileXtreamPlaylist(
            playlistId: playlistId,
            serverUrl: playlist.url,
            username: playlist.username ?? '',
            userPass: userPass,
            portOverride: playlist.xtreamPortOverride,
            streams: streams,
          ),
          failure: (f) async {
            await _db.playlistsDao.updateSyncStatus(
              playlistId,
              status: PlaylistSyncStatus.error,
            );
            return Failure(f);
          },
        );
      },
      failure: (f) async {
        await _db.playlistsDao.updateSyncStatus(
          playlistId,
          status: PlaylistSyncStatus.error,
        );
        return Failure(f);
      },
    );
  }

  Future<Result<PlaylistImportResult>> _persistXtreamPlaylist({
    required String name,
    required String serverUrl,
    required String username,
    required String credentialKey,
    required String userPass,
    required List<XtreamLiveStream> streams,
    int? portOverride,
    String? epgUrl,
  }) async {
    try {
      final playlistId = await _db.playlistsDao.insertPlaylist(
        PlaylistsCompanion.insert(
          name: name,
          type: PlaylistType.xtream,
          url: Value(serverUrl),
          epgUrl: Value(epgUrl),
          username: Value(username),
          credentialKey: Value(credentialKey),
          xtreamPortOverride: Value(portOverride),
          lastSyncAt: Value(DateTime.now()),
          syncStatus: const Value(PlaylistSyncStatus.idle),
        ),
      );

      final companions = _streamsToCompanions(
        streams: streams,
        playlistId: playlistId,
        serverUrl: serverUrl,
        username: username,
        userPass: userPass,
        portOverride: portOverride,
      );

      await _db.channelsDao.insertChannels(companions);

      appLogger.i(
        'Imported Xtream "$name": ${companions.length} channels',
      );

      return Success(
        PlaylistImportResult(
          playlistId: playlistId,
          channelsAdded: companions.length,
          channelsUpdated: 0,
          channelsDeactivated: 0,
          parseErrors: 0,
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

  Future<Result<PlaylistImportResult>> _reconcileXtreamPlaylist({
    required int playlistId,
    required String serverUrl,
    required String username,
    required String userPass,
    required List<XtreamLiveStream> streams,
    int? portOverride,
  }) async {
    try {
      final existing = await _db.channelsDao.getChannelsByPlaylist(playlistId);

      final existingBySourceId = <String, Channel>{};
      for (final ch in existing) {
        if (ch.sourceId != null) {
          existingBySourceId[ch.sourceId!] = ch;
        }
      }

      final matchedIds = <int>{};
      var added = 0;
      var updated = 0;

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
            await ((_db.update(_db.channels))
                  ..where((c) => c.id.equals(existingCh.id)))
                .write(
              ChannelsCompanion(
                name: Value(stream.name),
                streamUrl: Value(streamUrl),
                logoUrl: Value(stream.streamIcon),
                isActive: const Value(true),
                updatedAt: Value(DateTime.now()),
              ),
            );
            updated++;
          } else if (!existingCh.isActive) {
            await _db.channelsDao.activateChannel(existingCh.id);
            updated++;
          }
        } else {
          await _db.channelsDao.insertChannel(
            ChannelsCompanion.insert(
              playlistId: playlistId,
              name: stream.name,
              streamUrl: streamUrl,
              sourceType: ChannelSourceType.xtream,
              sourceId: Value(sourceId),
              logoUrl: Value(stream.streamIcon),
              groupName: Value(stream.categoryId),
              tvgId: Value(stream.epgChannelId),
            ),
          );
          added++;
        }
      }

      var deactivated = 0;
      for (final ch in existing) {
        if (!matchedIds.contains(ch.id)) {
          await ((_db.update(_db.channels))..where((c) => c.id.equals(ch.id)))
              .write(
            ChannelsCompanion(
              isActive: const Value(false),
              updatedAt: Value(DateTime.now()),
            ),
          );
          deactivated++;
        }
      }

      await _db.playlistsDao.updateSyncStatus(
        playlistId,
        status: PlaylistSyncStatus.idle,
        syncedAt: DateTime.now(),
      );

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

  List<ChannelsCompanion> _streamsToCompanions({
    required List<XtreamLiveStream> streams,
    required int playlistId,
    required String serverUrl,
    required String username,
    required String userPass,
    int? portOverride,
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
        groupName: Value(stream.categoryId),
        tvgId: Value(stream.epgChannelId),
      );
    }).toList();
  }
}
