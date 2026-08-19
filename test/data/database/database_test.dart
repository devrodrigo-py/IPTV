import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nebula_iptv/data/database/app_database.dart';
import 'package:nebula_iptv/data/database/tables/channels_table.dart';
import 'package:nebula_iptv/data/database/tables/playlists_table.dart';

/// Creates an in-memory database for testing.
AppDatabase createTestDatabase() {
  return AppDatabase(NativeDatabase.memory());
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  group('PlaylistsDao', () {
    test('should insert and retrieve a playlist', () async {
      final id = await db.playlistsDao.insertPlaylist(
        PlaylistsCompanion.insert(
          name: 'Test Playlist',
          type: PlaylistType.m3u,
          url: const Value('http://example.com/playlist.m3u'),
        ),
      );

      expect(id, greaterThan(0));

      final playlist = await db.playlistsDao.getPlaylistById(id);
      expect(playlist, isNotNull);
      expect(playlist!.name, 'Test Playlist');
      expect(playlist.type, PlaylistType.m3u);
      expect(playlist.isActive, isTrue);
      expect(playlist.syncStatus, PlaylistSyncStatus.idle);
    });

    test('should update sync status', () async {
      final id = await db.playlistsDao.insertPlaylist(
        PlaylistsCompanion.insert(
          name: 'Sync Test',
          type: PlaylistType.xtream,
        ),
      );

      await db.playlistsDao.updateSyncStatus(
        id,
        status: PlaylistSyncStatus.syncing,
      );

      final playlist = await db.playlistsDao.getPlaylistById(id);
      expect(playlist!.syncStatus, PlaylistSyncStatus.syncing);
    });

    test('should deactivate playlist', () async {
      final id = await db.playlistsDao.insertPlaylist(
        PlaylistsCompanion.insert(
          name: 'Deactivate Test',
          type: PlaylistType.m3u,
        ),
      );

      await db.playlistsDao.deactivatePlaylist(id);

      final playlist = await db.playlistsDao.getPlaylistById(id);
      expect(playlist!.isActive, isFalse);
    });
  });

  group('ChannelsDao', () {
    late int playlistId;

    setUp(() async {
      playlistId = await db.playlistsDao.insertPlaylist(
        PlaylistsCompanion.insert(
          name: 'Channel Test Playlist',
          type: PlaylistType.m3u,
        ),
      );
    });

    test('should insert and retrieve channels', () async {
      await db.channelsDao.insertChannel(
        ChannelsCompanion.insert(
          playlistId: playlistId,
          name: 'ESPN',
          streamUrl: 'http://stream.test/espn',
          sourceType: ChannelSourceType.m3u,
          groupName: const Value('Sports'),
          sourceId: const Value('espn-1'),
        ),
      );

      final channels = await db.channelsDao.getChannelsByPlaylist(playlistId);
      expect(channels, hasLength(1));
      expect(channels.first.name, 'ESPN');
      expect(channels.first.groupName, 'Sports');
    });

    test('should search channels by name', () async {
      await db.channelsDao.insertChannels([
        ChannelsCompanion.insert(
          playlistId: playlistId,
          name: 'ESPN Sports',
          streamUrl: 'http://stream.test/espn',
          sourceType: ChannelSourceType.m3u,
        ),
        ChannelsCompanion.insert(
          playlistId: playlistId,
          name: 'HBO Max',
          streamUrl: 'http://stream.test/hbo',
          sourceType: ChannelSourceType.m3u,
        ),
        ChannelsCompanion.insert(
          playlistId: playlistId,
          name: 'ESPN 2',
          streamUrl: 'http://stream.test/espn2',
          sourceType: ChannelSourceType.m3u,
        ),
      ]);

      final results = await db.channelsDao.searchChannels('ESPN');
      expect(results, hasLength(2));
    });

    test('should find channel by sourceId', () async {
      await db.channelsDao.insertChannel(
        ChannelsCompanion.insert(
          playlistId: playlistId,
          name: 'Discovery',
          streamUrl: 'http://stream.test/discovery',
          sourceType: ChannelSourceType.m3u,
          sourceId: const Value('disc-001'),
        ),
      );

      final channel = await db.channelsDao.getChannelBySourceId(
        playlistId,
        'disc-001',
      );
      expect(channel, isNotNull);
      expect(channel!.name, 'Discovery');
    });

    test('should get distinct groups', () async {
      await db.channelsDao.insertChannels([
        ChannelsCompanion.insert(
          playlistId: playlistId,
          name: 'CH 1',
          streamUrl: 'http://s/1',
          sourceType: ChannelSourceType.m3u,
          groupName: const Value('Sports'),
        ),
        ChannelsCompanion.insert(
          playlistId: playlistId,
          name: 'CH 2',
          streamUrl: 'http://s/2',
          sourceType: ChannelSourceType.m3u,
          groupName: const Value('News'),
        ),
        ChannelsCompanion.insert(
          playlistId: playlistId,
          name: 'CH 3',
          streamUrl: 'http://s/3',
          sourceType: ChannelSourceType.m3u,
          groupName: const Value('Sports'),
        ),
      ]);

      final groups = await db.channelsDao.getDistinctGroups();
      expect(groups, hasLength(2));
      expect(groups, containsAll(['News', 'Sports']));
    });
  });

  group('FavoritesDao', () {
    late int channelId;

    setUp(() async {
      final playlistId = await db.playlistsDao.insertPlaylist(
        PlaylistsCompanion.insert(
          name: 'Fav Test Playlist',
          type: PlaylistType.m3u,
        ),
      );
      channelId = await db.channelsDao.insertChannel(
        ChannelsCompanion.insert(
          playlistId: playlistId,
          name: 'Fav Channel',
          streamUrl: 'http://stream.test/fav',
          sourceType: ChannelSourceType.m3u,
        ),
      );
    });

    test('should add and check favorite', () async {
      await db.favoritesDao.addFavorite(channelId);

      final isFav = await db.favoritesDao.isFavorite(channelId);
      expect(isFav, isTrue);
    });

    test('should remove favorite', () async {
      await db.favoritesDao.addFavorite(channelId);
      await db.favoritesDao.removeFavorite(channelId);

      final isFav = await db.favoritesDao.isFavorite(channelId);
      expect(isFav, isFalse);
    });

    test('should toggle favorite', () async {
      final result1 = await db.favoritesDao.toggleFavorite(channelId);
      expect(result1, isTrue);

      final result2 = await db.favoritesDao.toggleFavorite(channelId);
      expect(result2, isFalse);
    });

    test('should not duplicate favorites', () async {
      await db.favoritesDao.addFavorite(channelId);
      await db.favoritesDao.addFavorite(channelId); // duplicate

      final ids = await db.favoritesDao.getFavoriteChannelIds();
      expect(ids, hasLength(1));
    });
  });

  group('WatchHistoryDao', () {
    late int channelId;

    setUp(() async {
      final playlistId = await db.playlistsDao.insertPlaylist(
        PlaylistsCompanion.insert(
          name: 'History Test',
          type: PlaylistType.m3u,
        ),
      );
      channelId = await db.channelsDao.insertChannel(
        ChannelsCompanion.insert(
          playlistId: playlistId,
          name: 'History Channel',
          streamUrl: 'http://stream.test/hist',
          sourceType: ChannelSourceType.m3u,
        ),
      );
    });

    test('should create history entry', () async {
      await db.watchHistoryDao.upsertEntry(
        channelId: channelId,
        watchedDurationMs: 60000,
      );

      final history = await db.watchHistoryDao.getRecentHistory();
      expect(history, hasLength(1));
      expect(history.first.watchedDurationMs, 60000);
    });

    test('should accumulate duration on upsert', () async {
      await db.watchHistoryDao.upsertEntry(
        channelId: channelId,
        watchedDurationMs: 30000,
      );
      await db.watchHistoryDao.upsertEntry(
        channelId: channelId,
        watchedDurationMs: 45000,
      );

      final entry = await db.watchHistoryDao.getEntryForChannel(channelId);
      expect(entry!.watchedDurationMs, 75000);
    });

    test('should clear all history', () async {
      await db.watchHistoryDao.upsertEntry(
        channelId: channelId,
        watchedDurationMs: 1000,
      );
      await db.watchHistoryDao.clearAll();

      final history = await db.watchHistoryDao.getRecentHistory();
      expect(history, isEmpty);
    });
  });

  group('EpgDao', () {
    late int channelId;

    setUp(() async {
      final playlistId = await db.playlistsDao.insertPlaylist(
        PlaylistsCompanion.insert(
          name: 'EPG Test',
          type: PlaylistType.m3u,
        ),
      );
      channelId = await db.channelsDao.insertChannel(
        ChannelsCompanion.insert(
          playlistId: playlistId,
          name: 'EPG Channel',
          streamUrl: 'http://stream.test/epg',
          sourceType: ChannelSourceType.m3u,
        ),
      );
    });

    test('should insert and retrieve programs', () async {
      final now = DateTime.now().toUtc();
      await db.epgDao.insertPrograms([
        EpgProgramsCompanion.insert(
          channelId: channelId,
          title: 'Morning News',
          startTimeUtc: now.subtract(const Duration(hours: 1)),
          endTimeUtc: now.add(const Duration(hours: 1)),
        ),
        EpgProgramsCompanion.insert(
          channelId: channelId,
          title: 'Afternoon Show',
          startTimeUtc: now.add(const Duration(hours: 1)),
          endTimeUtc: now.add(const Duration(hours: 3)),
        ),
      ]);

      final programs = await db.epgDao.getProgramsForChannel(channelId);
      expect(programs, hasLength(2));
    });

    test('should get current program', () async {
      final now = DateTime.now().toUtc();
      await db.epgDao.insertPrograms([
        EpgProgramsCompanion.insert(
          channelId: channelId,
          title: 'Current Show',
          startTimeUtc: now.subtract(const Duration(minutes: 30)),
          endTimeUtc: now.add(const Duration(minutes: 30)),
        ),
      ]);

      final current = await db.epgDao.getCurrentProgram(channelId);
      expect(current, isNotNull);
      expect(current!.title, 'Current Show');
    });

    test('should delete expired programs', () async {
      final now = DateTime.now().toUtc();
      await db.epgDao.insertPrograms([
        EpgProgramsCompanion.insert(
          channelId: channelId,
          title: 'Expired',
          startTimeUtc: now.subtract(const Duration(hours: 5)),
          endTimeUtc: now.subtract(const Duration(hours: 3)),
        ),
        EpgProgramsCompanion.insert(
          channelId: channelId,
          title: 'Future',
          startTimeUtc: now.add(const Duration(hours: 1)),
          endTimeUtc: now.add(const Duration(hours: 3)),
        ),
      ]);

      await db.epgDao.deleteExpiredPrograms();

      final all = await db.epgDao.getProgramsForChannel(channelId);
      expect(all, hasLength(1));
      expect(all.first.title, 'Future');
    });
  });
}
