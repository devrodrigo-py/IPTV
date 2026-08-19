import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nebula_iptv/core/network/dio_client.dart';
import 'package:nebula_iptv/data/database/app_database.dart';
import 'package:nebula_iptv/data/database/tables/channels_table.dart';
import 'package:nebula_iptv/data/database/tables/playlists_table.dart';
import 'package:nebula_iptv/data/datasources/credentials/memory_credential_store.dart';
import 'package:nebula_iptv/data/datasources/xtream/xtream_datasource.dart';
import 'package:nebula_iptv/data/datasources/xtream/xtream_models.dart';

void main() {
  group('XtreamModels', () {
    test('XtreamUserInfo should parse auth response', () {
      final json = {
        'username': 'testuser',
        'status': 'Active',
        'auth': 1,
        'exp_date': '1893456000', // far future
        'max_connections': '2',
        'active_cons': '0',
      };

      final info = XtreamUserInfo.fromJson(json);
      expect(info.isAuthenticated, isTrue);
      expect(info.isExpired, isFalse);
      expect(info.isConnectionLimitReached, isFalse);
    });

    test('XtreamUserInfo should detect expired account', () {
      final json = {
        'username': 'expired',
        'status': 'Expired',
        'auth': 1,
        'exp_date': '1000000000', // 2001 - expired
        'max_connections': '1',
        'active_cons': '0',
      };

      final info = XtreamUserInfo.fromJson(json);
      expect(info.isExpired, isTrue);
    });

    test('XtreamUserInfo should detect connection limit', () {
      final json = {
        'username': 'limited',
        'status': 'Active',
        'auth': 1,
        'exp_date': '1893456000',
        'max_connections': '1',
        'active_cons': '1',
      };

      final info = XtreamUserInfo.fromJson(json);
      expect(info.isConnectionLimitReached, isTrue);
    });

    test('XtreamUserInfo should detect failed auth', () {
      final json = {
        'username': 'bad',
        'status': 'Disabled',
        'auth': 0,
      };

      final info = XtreamUserInfo.fromJson(json);
      expect(info.isAuthenticated, isFalse);
    });

    test('XtreamServerInfo should build base URL', () {
      final json = {
        'url': 'server.example.com',
        'port': '8080',
        'https_port': '8443',
        'server_protocol': 'http',
      };

      final info = XtreamServerInfo.fromJson(json);
      expect(info.baseUrl, 'http://server.example.com:8080');
    });

    test('XtreamServerInfo should use https port when protocol is https', () {
      final json = {
        'url': 'server.example.com',
        'port': '8080',
        'https_port': '443',
        'server_protocol': 'https',
      };

      final info = XtreamServerInfo.fromJson(json);
      expect(info.baseUrl, 'https://server.example.com:443');
    });

    test('XtreamCategory should parse JSON', () {
      final json = {
        'category_id': '1',
        'category_name': 'Sports',
      };

      final cat = XtreamCategory.fromJson(json);
      expect(cat.categoryId, '1');
      expect(cat.categoryName, 'Sports');
    });

    test('XtreamLiveStream should parse JSON', () {
      final json = {
        'stream_id': 12345,
        'name': 'ESPN HD',
        'stream_icon': 'http://logo.com/espn.png',
        'epg_channel_id': 'espn.us',
        'category_id': '1',
        'container_extension': 'ts',
      };

      final stream = XtreamLiveStream.fromJson(json);
      expect(stream.streamId, 12345);
      expect(stream.name, 'ESPN HD');
      expect(stream.streamIcon, 'http://logo.com/espn.png');
      expect(stream.epgChannelId, 'espn.us');
      expect(stream.containerExtension, 'ts');
    });

    test('XtreamLiveStream should handle string stream_id', () {
      final json = {
        'stream_id': '999',
        'name': 'Test',
      };

      final stream = XtreamLiveStream.fromJson(json);
      expect(stream.streamId, 999);
    });
  });

  group('XtreamDataSource', () {
    late XtreamDataSource dataSource;

    setUp(() {
      dataSource = XtreamDataSource(client: DioClient());
    });

    test('buildStreamUrl should construct correct URL', () {
      final url = dataSource.buildStreamUrl(
        serverUrl: 'http://server.example.com:8080',
        username: 'user',
        password: 'pass',
        streamId: 12345,
        extension: 'ts',
      );

      expect(url, 'http://server.example.com:8080/live/user/pass/12345.ts');
    });

    test('buildStreamUrl should handle port override', () {
      final url = dataSource.buildStreamUrl(
        serverUrl: 'http://server.example.com:8080',
        username: 'user',
        password: 'pass',
        streamId: 100,
        portOverride: 9090,
        extension: 'm3u8',
      );

      expect(url, 'http://server.example.com:9090/live/user/pass/100.m3u8');
    });

    test('buildStreamUrl should handle trailing slash', () {
      final url = dataSource.buildStreamUrl(
        serverUrl: 'http://server.example.com:8080/',
        username: 'user',
        password: 'pass',
        streamId: 1,
      );

      expect(url, 'http://server.example.com:8080/live/user/pass/1.ts');
    });
  });

  group('MemoryCredentialStore', () {
    late MemoryCredentialStore store;

    setUp(() {
      store = MemoryCredentialStore();
    });

    test('should save and read credential', () async {
      await store.save(key: 'test-key', value: 'secret');
      final result = await store.read(key: 'test-key');
      expect(result.isSuccess, isTrue);
      result.when(
        success: (val) => expect(val, 'secret'),
        failure: (_) => fail('Should succeed'),
      );
    });

    test('should return null for non-existent key', () async {
      final result = await store.read(key: 'missing');
      result.when(
        success: (val) => expect(val, isNull),
        failure: (_) => fail('Should succeed with null'),
      );
    });

    test('should delete credential', () async {
      await store.save(key: 'k', value: 'v');
      await store.delete(key: 'k');
      final result = await store.read(key: 'k');
      result.when(
        success: (val) => expect(val, isNull),
        failure: (_) => fail('Should succeed'),
      );
    });

    test('should check existence', () async {
      await store.save(key: 'exists', value: 'yes');
      final r1 = await store.exists(key: 'exists');
      final r2 = await store.exists(key: 'nope');
      r1.when(
        success: (val) => expect(val, isTrue),
        failure: (_) => fail('Should succeed'),
      );
      r2.when(
        success: (val) => expect(val, isFalse),
        failure: (_) => fail('Should succeed'),
      );
    });
  });

  group('XtreamImportRepository - reconciliation', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('should match Xtream channels by sourceId (stream_id)', () async {
      final playlistId = await db.playlistsDao.insertPlaylist(
        PlaylistsCompanion.insert(
          name: 'Xtream Test',
          type: PlaylistType.xtream,
          url: const Value('http://server.test:8080'),
        ),
      );

      await db.channelsDao.insertChannel(
        ChannelsCompanion.insert(
          playlistId: playlistId,
          name: 'Old Channel Name',
          streamUrl: 'http://server.test:8080/live/u/p/123.ts',
          sourceType: ChannelSourceType.xtream,
          sourceId: const Value('123'),
        ),
      );

      final found = await db.channelsDao.getChannelBySourceId(
        playlistId,
        '123',
      );
      expect(found, isNotNull);
      expect(found!.sourceId, '123');
    });

    test('should preserve favorites when Xtream channel removed', () async {
      final playlistId = await db.playlistsDao.insertPlaylist(
        PlaylistsCompanion.insert(
          name: 'Xtream Fav',
          type: PlaylistType.xtream,
          url: const Value('http://srv:8080'),
        ),
      );

      final chId = await db.channelsDao.insertChannel(
        ChannelsCompanion.insert(
          playlistId: playlistId,
          name: 'Fav Stream',
          streamUrl: 'http://srv:8080/live/u/p/456.ts',
          sourceType: ChannelSourceType.xtream,
          sourceId: const Value('456'),
        ),
      );

      await db.favoritesDao.addFavorite(chId);
      await db.channelsDao.deactivateChannelsForPlaylist(playlistId);

      expect(await db.favoritesDao.isFavorite(chId), isTrue);
    });
  });
}
