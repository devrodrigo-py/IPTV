import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nebula_iptv/data/database/app_database.dart';
import 'package:nebula_iptv/data/database/tables/channels_table.dart';
import 'package:nebula_iptv/data/database/tables/playlists_table.dart';
import 'package:nebula_iptv/features/channels/providers/channels_provider.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());

    // Setup test data first, before creating container
    final playlistId = await db.playlistsDao.insertPlaylist(
      PlaylistsCompanion.insert(
        name: 'Test Playlist',
        type: PlaylistType.m3u,
      ),
    );

    await db.channelsDao.insertChannels([
      ChannelsCompanion.insert(
        playlistId: playlistId,
        name: 'ESPN Sports',
        streamUrl: 'http://s/espn',
        sourceType: ChannelSourceType.m3u,
        groupName: const Value('Sports'),
      ),
      ChannelsCompanion.insert(
        playlistId: playlistId,
        name: 'CNN News',
        streamUrl: 'http://s/cnn',
        sourceType: ChannelSourceType.m3u,
        groupName: const Value('News'),
      ),
      ChannelsCompanion.insert(
        playlistId: playlistId,
        name: 'HBO Movies',
        streamUrl: 'http://s/hbo',
        sourceType: ChannelSourceType.m3u,
        groupName: const Value('Movies'),
      ),
      ChannelsCompanion.insert(
        playlistId: playlistId,
        name: 'Fox Sports',
        streamUrl: 'http://s/fox',
        sourceType: ChannelSourceType.m3u,
        groupName: const Value('Sports'),
      ),
    ]);

    // Create container after data is ready
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

  group('ChannelsScreenNotifier', () {
    test('should load all channels on init', () async {
      // Read the provider to trigger initialization
      container.read(channelsScreenProvider);
      // Wait for async load
      await Future.delayed(const Duration(milliseconds: 200));

      final state = container.read(channelsScreenProvider);
      expect(state.isLoading, isFalse);
      expect(state.allChannels, hasLength(4));
      expect(state.filteredChannels, hasLength(4));
      expect(state.groups, hasLength(3));
      expect(state.failure, isNull);
    });

    test('should filter by search query', () async {
      container.read(channelsScreenProvider);
      await Future.delayed(const Duration(milliseconds: 200));

      container.read(channelsScreenProvider.notifier).search('ESPN');
      // Wait for debounce (300ms) + processing
      await Future.delayed(const Duration(milliseconds: 500));

      final state = container.read(channelsScreenProvider);
      expect(state.filteredChannels, hasLength(1));
      expect(state.filteredChannels.first.name, 'ESPN Sports');
    });

    test('should filter by group', () async {
      container.read(channelsScreenProvider);
      await Future.delayed(const Duration(milliseconds: 200));

      container.read(channelsScreenProvider.notifier).filterByGroup('News');
      await Future.delayed(const Duration(milliseconds: 50));

      final state = container.read(channelsScreenProvider);
      expect(state.filteredChannels, hasLength(1));
      expect(state.filteredChannels.first.name, 'CNN News');
      expect(state.selectedGroup, 'News');
    });

    test('should clear group filter on re-select', () async {
      container.read(channelsScreenProvider);
      await Future.delayed(const Duration(milliseconds: 200));

      final notifier = container.read(channelsScreenProvider.notifier);
      notifier.filterByGroup('News');
      await Future.delayed(const Duration(milliseconds: 50));
      notifier.filterByGroup('News'); // toggle off
      await Future.delayed(const Duration(milliseconds: 50));

      final state = container.read(channelsScreenProvider);
      expect(state.filteredChannels, hasLength(4));
      expect(state.selectedGroup, isNull);
    });

    test('should toggle favorite', () async {
      container.read(channelsScreenProvider);
      await Future.delayed(const Duration(milliseconds: 200));

      final state = container.read(channelsScreenProvider);
      final channelId = state.allChannels.first.id;

      await container
          .read(channelsScreenProvider.notifier)
          .toggleFavorite(channelId);
      await Future.delayed(const Duration(milliseconds: 50));

      final updated = container.read(channelsScreenProvider);
      expect(updated.favoriteIds.contains(channelId), isTrue);

      // Toggle off
      await container
          .read(channelsScreenProvider.notifier)
          .toggleFavorite(channelId);
      await Future.delayed(const Duration(milliseconds: 50));

      final after = container.read(channelsScreenProvider);
      expect(after.favoriteIds.contains(channelId), isFalse);
    });

    test('should combine search and group filter', () async {
      container.read(channelsScreenProvider);
      await Future.delayed(const Duration(milliseconds: 200));

      final notifier = container.read(channelsScreenProvider.notifier);
      notifier.filterByGroup('Sports');
      notifier.search('ESPN');
      await Future.delayed(const Duration(milliseconds: 500));

      final state = container.read(channelsScreenProvider);
      expect(state.filteredChannels, hasLength(1));
      expect(state.filteredChannels.first.name, 'ESPN Sports');
    });
  });
}
