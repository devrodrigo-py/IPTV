import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nebula_iptv/data/database/app_database.dart';
import 'package:nebula_iptv/data/database/tables/channels_table.dart';
import 'package:nebula_iptv/data/database/tables/playlists_table.dart';
import 'package:nebula_iptv/features/channels/providers/channels_provider.dart';
import 'package:nebula_iptv/features/history/providers/history_provider.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late int channelId1;
  late int channelId2;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());

    final playlistId = await db.playlistsDao.insertPlaylist(
      PlaylistsCompanion.insert(
        name: 'Test',
        type: PlaylistType.m3u,
      ),
    );

    channelId1 = await db.channelsDao.insertChannel(
      ChannelsCompanion.insert(
        playlistId: playlistId,
        name: 'Channel 1',
        streamUrl: 'http://s/1',
        sourceType: ChannelSourceType.m3u,
      ),
    );

    channelId2 = await db.channelsDao.insertChannel(
      ChannelsCompanion.insert(
        playlistId: playlistId,
        name: 'Channel 2',
        streamUrl: 'http://s/2',
        sourceType: ChannelSourceType.m3u,
      ),
    );

    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('HistoryScreenNotifier', () {
    test('should start with empty history', () async {
      container.read(historyScreenProvider);
      await Future.delayed(const Duration(milliseconds: 200));

      final state = container.read(historyScreenProvider);
      expect(state.isLoading, isFalse);
      expect(state.entries, isEmpty);
      expect(state.failure, isNull);
    });

    test('should record watch and load history', () async {
      container.read(historyScreenProvider);
      await Future.delayed(const Duration(milliseconds: 200));

      await container
          .read(historyScreenProvider.notifier)
          .recordWatch(channelId: channelId1, durationMs: 60000);

      final state = container.read(historyScreenProvider);
      expect(state.entries, hasLength(1));
      expect(state.entries.first.channelId, channelId1);
      expect(state.entries.first.watchedDurationMs, 60000);
    });

    test('should accumulate duration on repeated watch', () async {
      container.read(historyScreenProvider);
      await Future.delayed(const Duration(milliseconds: 200));

      await container
          .read(historyScreenProvider.notifier)
          .recordWatch(channelId: channelId1, durationMs: 30000);
      await container
          .read(historyScreenProvider.notifier)
          .recordWatch(channelId: channelId1, durationMs: 45000);

      final state = container.read(historyScreenProvider);
      expect(state.entries, hasLength(1));
      expect(state.entries.first.watchedDurationMs, 75000);
    });

    test('should delete single entry', () async {
      container.read(historyScreenProvider);
      await Future.delayed(const Duration(milliseconds: 200));

      await container
          .read(historyScreenProvider.notifier)
          .recordWatch(channelId: channelId1, durationMs: 1000);
      await container
          .read(historyScreenProvider.notifier)
          .recordWatch(channelId: channelId2, durationMs: 2000);

      var state = container.read(historyScreenProvider);
      expect(state.entries, hasLength(2));

      await container
          .read(historyScreenProvider.notifier)
          .deleteEntry(state.entries.first.id);

      state = container.read(historyScreenProvider);
      expect(state.entries, hasLength(1));
    });

    test('should clear all history', () async {
      container.read(historyScreenProvider);
      await Future.delayed(const Duration(milliseconds: 200));

      await container
          .read(historyScreenProvider.notifier)
          .recordWatch(channelId: channelId1, durationMs: 1000);
      await container
          .read(historyScreenProvider.notifier)
          .recordWatch(channelId: channelId2, durationMs: 2000);

      await container.read(historyScreenProvider.notifier).clearAll();

      final state = container.read(historyScreenProvider);
      expect(state.entries, isEmpty);
    });

    test('should respect configurable limit', () async {
      container.read(historyScreenProvider);
      await Future.delayed(const Duration(milliseconds: 200));

      // Set limit to 1
      container.read(historyScreenProvider.notifier).setLimit(1);

      // Add 2 entries
      await container
          .read(historyScreenProvider.notifier)
          .recordWatch(channelId: channelId1, durationMs: 1000);
      await container
          .read(historyScreenProvider.notifier)
          .recordWatch(channelId: channelId2, durationMs: 2000);

      final state = container.read(historyScreenProvider);
      // Should be trimmed to 1
      expect(state.entries.length, lessThanOrEqualTo(1));
    });
  });
}
