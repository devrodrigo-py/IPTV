import 'dart:convert';

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

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = UserDataRepository(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  group('UserDataRepository', () {
    group('export', () {
      test('should export empty data', () async {
        final result = await repo.exportData();

        expect(result.isSuccess, isTrue);
        result.when(
          success: (data) {
            expect(data.playlistCount, 0);
            expect(data.favoriteCount, 0);
            expect(data.jsonContent, isNotEmpty);
          },
          failure: (_) => fail('Should succeed'),
        );
      });

      test('should export playlists and favorites', () async {
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

        final result = await repo.exportData();

        expect(result.isSuccess, isTrue);
        result.when(
          success: (data) {
            expect(data.playlistCount, 1);
            expect(data.favoriteCount, 1);

            final json = jsonDecode(data.jsonContent);
            expect(json['version'], 1);
            expect(json['playlists'], hasLength(1));
            expect(json['playlists'][0]['name'], 'My Playlist');
            expect(json['favoriteChannelIds'], hasLength(1));
          },
          failure: (_) => fail('Should succeed'),
        );
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

        final result = await repo.exportData();

        result.when(
          success: (data) {
            final json = jsonDecode(data.jsonContent);
            final playlist = json['playlists'][0];
            expect(playlist['requiresAuthentication'], isTrue);
            expect(playlist.containsKey('credentialKey'), isFalse);
          },
          failure: (_) => fail('Should succeed'),
        );
      });
    });

    group('import', () {
      test('should return Failure for empty content', () async {
        final result = await repo.importData('');
        expect(result.isFailure, isTrue);
      });

      test('should return Failure for invalid JSON', () async {
        final result = await repo.importData('not valid json');
        expect(result.isFailure, isTrue);
      });

      test('should return Failure for unsupported version', () async {
        final result = await repo.importData(jsonEncode({
          'version': 99,
          'playlists': [],
        }));
        expect(result.isFailure, isTrue);
      });

      test('should import valid data', () async {
        final result = await repo.importData(jsonEncode({
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
        }));
        expect(result.isSuccess, isTrue);
      });

      test('should skip Xtream playlists requiring auth', () async {
        final result = await repo.importData(jsonEncode({
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
        }));
        result.when(
          success: (count) => expect(count, 1),
          failure: (_) => fail('Should succeed'),
        );
      });
    });
  });
}
