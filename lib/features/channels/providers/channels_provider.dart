import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/core/errors/app_failure.dart';
import 'package:nebula_iptv/core/logging/app_logger.dart';
import 'package:nebula_iptv/data/database/app_database.dart';
import 'package:nebula_iptv/data/database/tables/channels_table.dart';

/// State for the channels screen.
class ChannelsScreenState {
  final List<Channel> allChannels;
  final List<Channel> filteredChannels;
  final List<String> groups;
  final String? selectedGroup;
  final String searchQuery;
  final Set<int> favoriteIds;
  final bool isLoading;
  final AppFailure? failure;

  const ChannelsScreenState({
    this.allChannels = const [],
    this.filteredChannels = const [],
    this.groups = const [],
    this.selectedGroup,
    this.searchQuery = '',
    this.favoriteIds = const {},
    this.isLoading = true,
    this.failure,
  });

  ChannelsScreenState copyWith({
    List<Channel>? allChannels,
    List<Channel>? filteredChannels,
    List<String>? groups,
    String? selectedGroup,
    bool clearSelectedGroup = false,
    String? searchQuery,
    Set<int>? favoriteIds,
    bool? isLoading,
    AppFailure? failure,
    bool clearFailure = false,
  }) {
    return ChannelsScreenState(
      allChannels: allChannels ?? this.allChannels,
      filteredChannels: filteredChannels ?? this.filteredChannels,
      groups: groups ?? this.groups,
      selectedGroup:
          clearSelectedGroup ? null : (selectedGroup ?? this.selectedGroup),
      searchQuery: searchQuery ?? this.searchQuery,
      favoriteIds: favoriteIds ?? this.favoriteIds,
      isLoading: isLoading ?? this.isLoading,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}

/// Provider for the Channels Screen state.
final channelsScreenProvider =
    StateNotifierProvider<ChannelsScreenNotifier, ChannelsScreenState>(
  (ref) => ChannelsScreenNotifier(ref),
);

/// Provider for the database instance.
/// Must be overridden in the app bootstrap with the real database.
final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('databaseProvider must be overridden');
});

/// Notifier that manages channel browsing state.
class ChannelsScreenNotifier extends StateNotifier<ChannelsScreenState> {
  final Ref _ref;
  Timer? _debounce;

  ChannelsScreenNotifier(this._ref) : super(const ChannelsScreenState()) {
    _loadChannels();
  }

  /// Loads all active channels and groups, filtering duplicates.
  Future<void> _loadChannels() async {
    try {
      final db = _ref.read(databaseProvider);
      final allChannels = await db.channelsDao.getAllActiveChannels();
      // Only show live channels (xtream/m3u) — VOD and Series have their own screens
      final channels = allChannels
          .where((c) =>
              c.sourceType == ChannelSourceType.xtream ||
              c.sourceType == ChannelSourceType.m3u)
          .toList();
      // Groups must come from the live-only collection. Using every row in
      // `channels` leaked movie and series categories into the Ao Vivo filter.
      final groups = channels
          .map((channel) => channel.groupName)
          .whereType<String>()
          .where((group) => group.trim().isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      final favoriteIds = await db.favoritesDao.getFavoriteChannelIds();

      // Apply deduplication: keep only primary channel per group
      final dedupChannels = await _filterDuplicates(db, channels);

      state = state.copyWith(
        allChannels: dedupChannels,
        filteredChannels: dedupChannels,
        groups: groups,
        favoriteIds: favoriteIds,
        isLoading: false,
        clearFailure: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        failure: DatabaseFailure(
          message: 'Erro ao carregar canais.',
          originalError: e,
        ),
      );
    }
  }

  /// Filters out duplicate channels using channel_groups.
  /// Keeps only the primary_channel_id from each group.
  Future<List<Channel>> _filterDuplicates(
      AppDatabase db, List<Channel> channels) async {
    try {
      // Get primary channel IDs and all grouped channel IDs
      final groupRows = await db
          .customSelect(
            'SELECT g.primary_channel_id, m.channel_id '
            'FROM channel_groups g '
            'INNER JOIN channel_group_members m ON m.group_id = g.id '
            'WHERE g.primary_channel_id IS NOT NULL',
          )
          .get();

      appLogger.d('[Dedup UI] Found ${groupRows.length} group member rows');

      if (groupRows.isEmpty) return channels;

      // Build sets
      final primaryIds = <int>{};
      final allGroupedIds = <int>{};
      for (final row in groupRows) {
        final primaryId = row.read<int>('primary_channel_id');
        final memberId = row.read<int>('channel_id');
        primaryIds.add(primaryId);
        allGroupedIds.add(memberId);
      }

      appLogger.d(
        '[Dedup UI] ${primaryIds.length} primary, ${allGroupedIds.length} grouped total, '
        '${channels.length} channels before filter',
      );

      // Keep channels that are: not in any group, OR are the primary of their group
      final filtered = channels.where((c) {
        if (!allGroupedIds.contains(c.id)) return true; // not grouped
        return primaryIds.contains(c.id); // is primary
      }).toList();

      appLogger.d('[Dedup UI] ${filtered.length} channels after filter');
      return filtered;
    } catch (e) {
      appLogger.w('[Dedup UI] Filter failed: $e');
      // If dedup query fails, return all channels
      return channels;
    }
  }

  /// Searches channels with debounce (spec §16).
  void search(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      state = state.copyWith(searchQuery: query);
      _applyFilters();
    });
  }

  /// Filters by group. Pass null to clear filter.
  void filterByGroup(String? group) {
    if (group == state.selectedGroup) {
      state = state.copyWith(clearSelectedGroup: true);
    } else {
      state = state.copyWith(selectedGroup: group);
    }
    _applyFilters();
  }

  /// Toggles a channel's favorite status.
  Future<void> toggleFavorite(int channelId) async {
    try {
      final db = _ref.read(databaseProvider);
      await db.favoritesDao.toggleFavorite(channelId);
      final favoriteIds = await db.favoritesDao.getFavoriteChannelIds();
      state = state.copyWith(favoriteIds: favoriteIds);
    } catch (e) {
      // Don't break UI for favorite toggle — the optimistic list stays
      // correct, but the persistence failure must be observable.
      appLogger
          .w('[Channels] Falha ao alternar favorito (canal $channelId): $e');
    }
  }

  /// Refreshes channels from the database.
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearFailure: true);
    await _loadChannels();
  }

  /// Applies search and group filters to the channel list.
  void _applyFilters() {
    var filtered = state.allChannels;

    // Apply group filter
    if (state.selectedGroup != null) {
      filtered =
          filtered.where((c) => c.groupName == state.selectedGroup).toList();
    }

    // Apply search filter
    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      filtered = filtered.where((c) {
        return c.name.toLowerCase().contains(query) ||
            (c.groupName?.toLowerCase().contains(query) ?? false) ||
            (c.tvgId?.toLowerCase().contains(query) ?? false) ||
            (c.tvgName?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    state = state.copyWith(filteredChannels: filtered);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
