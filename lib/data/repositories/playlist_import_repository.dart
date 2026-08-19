import 'package:drift/drift.dart';
import 'package:nebula_iptv/core/errors/app_failure.dart';
import 'package:nebula_iptv/core/logging/app_logger.dart';
import 'package:nebula_iptv/core/result/result.dart';
import 'package:nebula_iptv/data/database/app_database.dart';
import 'package:nebula_iptv/data/database/tables/channels_table.dart';
import 'package:nebula_iptv/data/database/tables/playlists_table.dart';
import 'package:nebula_iptv/data/datasources/m3u/m3u_datasource.dart';
import 'package:nebula_iptv/data/datasources/m3u/m3u_entry.dart';
import 'package:nebula_iptv/data/datasources/m3u/m3u_parser.dart';

/// Result of importing a playlist.
class PlaylistImportResult {
  final int playlistId;
  final int channelsAdded;
  final int channelsUpdated;
  final int channelsDeactivated;
  final int parseErrors;

  const PlaylistImportResult({
    required this.playlistId,
    required this.channelsAdded,
    required this.channelsUpdated,
    required this.channelsDeactivated,
    required this.parseErrors,
  });

  int get totalChannels => channelsAdded + channelsUpdated;
}

/// Repository responsible for importing and syncing M3U playlists.
class PlaylistImportRepository {
  final AppDatabase _db;
  final M3uDataSource _m3uDataSource;

  PlaylistImportRepository({
    required AppDatabase db,
    required M3uDataSource m3uDataSource,
  })  : _db = db,
        _m3uDataSource = m3uDataSource;

  /// Imports a new M3U playlist from URL.
  Future<Result<PlaylistImportResult>> importFromUrl({
    required String name,
    required String url,
    String? epgUrl,
  }) async {
    final parseResult = await _m3uDataSource.fetchFromUrl(url);
    return parseResult.when(
      success: (result) => _persistPlaylist(
        name: name,
        url: url,
        epgUrl: epgUrl,
        parseResult: result,
      ),
      failure: (f) => Failure(f),
    );
  }

  /// Imports a new M3U playlist from local file.
  Future<Result<PlaylistImportResult>> importFromFile({
    required String name,
    required String filePath,
    String? epgUrl,
  }) async {
    final parseResult = await _m3uDataSource.readFromFile(filePath);
    return parseResult.when(
      success: (result) => _persistPlaylist(
        name: name,
        url: filePath,
        epgUrl: epgUrl,
        parseResult: result,
      ),
      failure: (f) => Failure(f),
    );
  }

  /// Refreshes an existing playlist (re-fetches and reconciles).
  Future<Result<PlaylistImportResult>> refreshPlaylist(
    int playlistId,
  ) async {
    final playlist = await _db.playlistsDao.getPlaylistById(playlistId);
    if (playlist == null) {
      return const Failure(
        DatabaseFailure(message: 'Playlist não encontrada.'),
      );
    }

    await _db.playlistsDao.updateSyncStatus(
      playlistId,
      status: PlaylistSyncStatus.syncing,
    );

    try {
      final parseResult = await _m3uDataSource.fetchFromUrl(playlist.url);
      return await parseResult.when(
        success: (result) => _reconcilePlaylist(
          playlistId: playlistId,
          parseResult: result,
        ),
        failure: (f) async {
          await _db.playlistsDao.updateSyncStatus(
            playlistId,
            status: PlaylistSyncStatus.error,
          );
          return Failure(f);
        },
      );
    } catch (e) {
      await _db.playlistsDao.updateSyncStatus(
        playlistId,
        status: PlaylistSyncStatus.error,
      );
      return Failure(
        UnknownFailure(
          message: 'Erro ao atualizar a playlist.',
          originalError: e,
        ),
      );
    }
  }

  Future<Result<PlaylistImportResult>> _persistPlaylist({
    required String name,
    required String url,
    String? epgUrl,
    required M3uParseResult parseResult,
  }) async {
    try {
      final playlistId = await _db.playlistsDao.insertPlaylist(
        PlaylistsCompanion.insert(
          name: name,
          type: PlaylistType.m3u,
          url: Value(url),
          epgUrl: Value(epgUrl),
          lastSyncAt: Value(DateTime.now()),
          syncStatus: const Value(PlaylistSyncStatus.idle),
        ),
      );

      final channels = _entriesToCompanions(parseResult.entries, playlistId);
      await _db.channelsDao.insertChannels(channels);

      appLogger.i(
        'Imported playlist "$name": '
        '${channels.length} channels, '
        '${parseResult.errorCount} errors',
      );

      return Success(
        PlaylistImportResult(
          playlistId: playlistId,
          channelsAdded: channels.length,
          channelsUpdated: 0,
          channelsDeactivated: 0,
          parseErrors: parseResult.errorCount,
        ),
      );
    } catch (e) {
      return Failure(
        DatabaseFailure(
          message: 'Erro ao salvar a playlist.',
          originalError: e,
        ),
      );
    }
  }

  Future<Result<PlaylistImportResult>> _reconcilePlaylist({
    required int playlistId,
    required M3uParseResult parseResult,
  }) async {
    try {
      final existingChannels =
          await _db.channelsDao.getChannelsByPlaylist(playlistId);

      final existingBySourceId = <String, Channel>{};
      final existingByUrl = <String, Channel>{};
      for (final ch in existingChannels) {
        if (ch.sourceId != null && ch.sourceId!.isNotEmpty) {
          existingBySourceId[ch.sourceId!] = ch;
        }
        existingByUrl[ch.streamUrl] = ch;
      }

      final matchedIds = <int>{};
      var added = 0;
      var updated = 0;

      for (final entry in parseResult.entries) {
        if (!entry.hasValidUrl) continue;

        Channel? existing;
        if (entry.sourceId != null) {
          existing = existingBySourceId[entry.sourceId];
        }
        existing ??= existingByUrl[entry.streamUrl];

        if (existing != null) {
          matchedIds.add(existing.id);
          if (_hasChanges(existing, entry)) {
            await ((_db.update(_db.channels))
                  ..where((c) => c.id.equals(existing!.id)))
                .write(
              ChannelsCompanion(
                name: Value(entry.name),
                streamUrl: Value(entry.streamUrl),
                logoUrl: Value(entry.logoUrl),
                groupName: Value(entry.groupTitle),
                tvgId: Value(entry.tvgId),
                tvgName: Value(entry.tvgName),
                sourceId: Value(entry.sourceId),
                isActive: const Value(true),
                updatedAt: Value(DateTime.now()),
              ),
            );
            updated++;
          } else if (!existing.isActive) {
            await _db.channelsDao.activateChannel(existing.id);
            updated++;
          }
        } else {
          await _db.channelsDao.insertChannel(
            _entryToCompanion(entry, playlistId),
          );
          added++;
        }
      }

      var deactivated = 0;
      for (final ch in existingChannels) {
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
        'Refreshed playlist $playlistId: '
        '+$added, ~$updated, -$deactivated',
      );

      return Success(
        PlaylistImportResult(
          playlistId: playlistId,
          channelsAdded: added,
          channelsUpdated: updated,
          channelsDeactivated: deactivated,
          parseErrors: parseResult.errorCount,
        ),
      );
    } catch (e) {
      await _db.playlistsDao.updateSyncStatus(
        playlistId,
        status: PlaylistSyncStatus.error,
      );
      return Failure(
        DatabaseFailure(
          message: 'Erro na reconciliação da playlist.',
          originalError: e,
        ),
      );
    }
  }

  bool _hasChanges(Channel existing, M3uEntry entry) {
    return existing.name != entry.name ||
        existing.streamUrl != entry.streamUrl ||
        existing.logoUrl != entry.logoUrl ||
        existing.groupName != entry.groupTitle ||
        existing.tvgId != entry.tvgId ||
        existing.tvgName != entry.tvgName;
  }

  List<ChannelsCompanion> _entriesToCompanions(
    List<M3uEntry> entries,
    int playlistId,
  ) {
    return entries
        .where((e) => e.hasValidUrl)
        .map((e) => _entryToCompanion(e, playlistId))
        .toList();
  }

  ChannelsCompanion _entryToCompanion(M3uEntry entry, int playlistId) {
    return ChannelsCompanion.insert(
      playlistId: playlistId,
      name: entry.name,
      streamUrl: entry.streamUrl,
      sourceType: ChannelSourceType.m3u,
      sourceId: Value(entry.sourceId),
      logoUrl: Value(entry.logoUrl),
      groupName: Value(entry.groupTitle),
      tvgId: Value(entry.tvgId),
      tvgName: Value(entry.tvgName),
    );
  }
}
