import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nebula_iptv/data/database/app_database.dart';
import 'package:nebula_iptv/data/database/tables/channels_table.dart';
import 'package:nebula_iptv/data/database/tables/playlists_table.dart';
import 'package:nebula_iptv/data/repositories/user_data_repository.dart';

void main() {
  late AppDatabase db;
  late UserDataRepository repo;
  late Directory tempDir;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = UserDataRepository(db: db);
    tempDir = await Directory.systemTemp.createTemp('nebula_test_');
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('UserDataRepository', () {
    group('export', () {
      test('should export empty data', () async {
        final path = '${tempDir.path}/export.json';
        final result = await repo.exportData(path);

        expect(result.isSuccess, isTrue);
        result.when(
          success: (data) {
            expect(data.playlistCount, 0);
            expect(data.favoriteCount, 0);
            expect(File(path).existsSync(), isTrue);
          },
          failure: (_) => fail('Should succeed'),
        );
      });

      test('should export playlists and favorites', () async {
        // Setup data
        final playlistId = await db.playlistsDao.insertPlaylist(
          PlaylistsCompanion.insert(
            name: 'My Playlist',
            type: PlaylistType.m3u,
            url: const Value('http://example.com/list.m3u'),
          ),
        );

        final channelId = await db.channelsDao.insertChannel(
          ChannelsCompanion.insert(
            playlistId: playlistId,
            name: 'ESPN',
            streamUrl: 'http://stream/espn',
            sourceType: ChannelSourceType.m3u,
          ),
        );

        await db.favoritesDao.addFavorite(channelId);

        final path = '${tempDir.path}/export.json';
        final result = await repo.exportData(path);

        expect(result.isSuccess, isTrue);
        result.when(
          success: (data) {
            expect(data.playlistCount, 1);
            expect(data.favoriteCount, 1);
          },
          failure: (_) => fail('Should succeed'),
        );

        // Verify JSON structure
        final json = jsonDecode(File(path).readAsStringSync());
        expect(json['version'], 1);
        expect(json['playlists'], hasLength(1));
        expect(json['playlists'][0]['name'], 'My Playlist');
        expect(json['playlists'][0]['type'], 'm3u');
        expect(json['favoriteChannelIds'], hasLength(1));
      });

      test('should not export Xtream credentials', () async {
        await db.playlistsDao.insertPlaylist(
          PlaylistsCompanion.insert(
            name: 'Xtream Source',
            type: PlaylistType.xtream,
            url: const Value('http://xtream.server:8080'),
            username: const Value('myuser'),
            credentialKey: const Value('key_123'),
          ),
        );

        final path = '${tempDir.path}/export.json';
        await repo.exportData(path);

        final json = jsonDecode(File(path).readAsStringSync());
        final playlist = json['playlists'][0];
        expect(playlist['requiresAuthentication'], isTrue);
        // Should NOT contain credentialKey or actual password
        expect(playlist.containsKey('credentialKey'), isFalse);
      });
    });

    group('import', () {
      test('should return Failure for non-existent file', () async {
        final result = await repo.importData('/nonexistent/path.json');
        expect(result.isFailure, isTrue);
      });

      test('should return Failure for invalid JSON', () async {
        final path = '${tempDir.path}/invalid.json';
        File(path).writeAsStringSync('not valid json');

        final result = await repo.importData(path);
        expect(result.isFailure, isTrue);
      });

      test('should return Failure for unsupported version', () async {
        final path = '${tempDir.path}/future.json';
        File(path).writeAsStringSync(
          jsonEncode({
            'version': 99,
            'playlists': [],
          }),
        );

        final result = await repo.importData(path);
        expect(result.isFailure, isTrue);
      });

      test('should import valid data', () async {
        final path = '${tempDir.path}/valid.json';
        File(path).writeAsStringSync(
          jsonEncode({
            'version': 1,
            'playlists': [
              {
                'name': 'Imported',
                'type': 'm3u',
                'url': 'http://example.com/imported.m3u',
                'requiresAuthentication': false,
              },
            ],
            'favoriteChannelIds': [],
          }),
        );

        final result = await repo.importData(path);
        expect(result.isSuccess, isTrue);
      });

      test('should skip Xtream playlists requiring auth', () async {
        final path = '${tempDir.path}/xtream.json';
        File(path).writeAsStringSync(
          jsonEncode({
            'version': 1,
            'playlists': [
              {
                'name': 'Xtream',
                'type': 'xtream',
                'url': 'http://server:8080',
                'requiresAuthentication': true,
              },
              {
                'name': 'M3U',
                'type': 'm3u',
                'url': 'http://example.com/list.m3u',
                'requiresAuthentication': false,
              },
            ],
          }),
        );

        final result = await repo.importData(path);
        result.when(
          success: (count) => expect(count, 1), // Only M3U imported
          failure: (_) => fail('Should succeed'),
        );
      });
    });
  });
}
