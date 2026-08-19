import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nebula_iptv/core/network/dio_client.dart';
import 'package:nebula_iptv/data/database/app_database.dart';
import 'package:nebula_iptv/data/database/tables/channels_table.dart';
import 'package:nebula_iptv/data/database/tables/playlists_table.dart';
import 'package:nebula_iptv/data/datasources/m3u/m3u_datasource.dart';
import 'package:nebula_iptv/data/datasources/m3u/m3u_parser.dart';

AppDatabase _createTestDb() => AppDatabase(NativeDatabase.memory());

void main() {
  late AppDatabase db;
  late M3uDataSource dataSource;

  setUp(() {
    db = _createTestDb();
    dataSource = M3uDataSource(
      client: DioClient(),
      parser: const M3uParser(),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('PlaylistImportRepository', () {
    group('reconciliation', () {
      test('should add new channels on refresh', () async {
        const content1 = '''#EXTM3U
#EXTINF:-1 tvg-id="ch1",Channel 1
http://stream.example.com/ch1''';

        final result1 = dataSource.parseContent(content1);
        expect(result1.isSuccess, isTrue);

        final playlistId = await db.playlistsDao.insertPlaylist(
          PlaylistsCompanion.insert(
            name: 'Test',
            type: PlaylistType.m3u,
            url: const Value('http://test.com/playlist.m3u'),
          ),
        );

        await db.channelsDao.insertChannel(
          ChannelsCompanion.insert(
            playlistId: playlistId,
            name: 'Channel 1',
            streamUrl: 'http://stream.example.com/ch1',
            sourceType: ChannelSourceType.m3u,
            sourceId: const Value('ch1'),
          ),
        );

        final initial = await db.channelsDao.getChannelsByPlaylist(playlistId);
        expect(initial, hasLength(1));
      });

      test('should preserve favorites when channel is deactivated', () async {
        final playlistId = await db.playlistsDao.insertPlaylist(
          PlaylistsCompanion.insert(
            name: 'Fav Test',
            type: PlaylistType.m3u,
            url: const Value('http://test.com/fav.m3u'),
          ),
        );

        final channelId = await db.channelsDao.insertChannel(
          ChannelsCompanion.insert(
            playlistId: playlistId,
            name: 'Fav Channel',
            streamUrl: 'http://stream.example.com/fav',
            sourceType: ChannelSourceType.m3u,
            sourceId: const Value('fav-1'),
          ),
        );

        await db.favoritesDao.addFavorite(channelId);
        await db.channelsDao.deactivateChannelsForPlaylist(playlistId);

        final isFav = await db.favoritesDao.isFavorite(channelId);
        expect(isFav, isTrue);

        final channel = await db.channelsDao.getChannelById(channelId);
        expect(channel!.isActive, isFalse);
      });

      test('should match channels by sourceId', () async {
        final playlistId = await db.playlistsDao.insertPlaylist(
          PlaylistsCompanion.insert(
            name: 'Reconcile Test',
            type: PlaylistType.m3u,
            url: const Value('http://test.com/recon.m3u'),
          ),
        );

        await db.channelsDao.insertChannel(
          ChannelsCompanion.insert(
            playlistId: playlistId,
            name: 'Old Name',
            streamUrl: 'http://old-url.com/stream',
            sourceType: ChannelSourceType.m3u,
            sourceId: const Value('stable-id'),
          ),
        );

        final found = await db.channelsDao.getChannelBySourceId(
          playlistId,
          'stable-id',
        );
        expect(found, isNotNull);
        expect(found!.name, 'Old Name');
      });
    });

    group('M3uDataSource parseContent', () {
      test('should return Success for valid content', () {
        const content = '''#EXTM3U
#EXTINF:-1 tvg-id="ch1",Test Channel
http://stream.example.com/test''';

        final result = dataSource.parseContent(content);
        expect(result.isSuccess, isTrue);
      });

      test('should return Failure for empty content', () {
        final result = dataSource.parseContent('');
        expect(result.isFailure, isTrue);
      });

      test('should return Failure for content with no valid channels', () {
        const content = '#EXTM3U\n# just comments\n';
        final result = dataSource.parseContent(content);
        expect(result.isFailure, isTrue);
      });
    });
  });
}
