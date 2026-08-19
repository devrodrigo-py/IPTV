import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/core/errors/app_failure.dart';
import 'package:nebula_iptv/data/database/app_database.dart';

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

  /// Loads all active channels and groups.
  Future<void> _loadChannels() async {
    try {
      final db = _ref.read(databaseProvider);
      final channels = await db.channelsDao.getAllActiveChannels();
      final groups = await db.channelsDao.getDistinctGroups();
      final favoriteIds = await db.favoritesDao.getFavoriteChannelIds();

      state = state.copyWith(
        allChannels: channels,
        filteredChannels: channels,
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
    } catch (_) {
      // Silently fail — don't break UI for favorite toggle
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
