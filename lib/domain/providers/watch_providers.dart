import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/data/database/daos/watch_stats_dao.dart';
import 'package:nebula_iptv/domain/services/smart_favorites_service.dart';
import 'package:nebula_iptv/domain/services/watch_tracking_service.dart';
import 'package:nebula_iptv/features/channels/providers/channels_provider.dart';

/// Provider for the WatchStatsDao.
final watchStatsDaoProvider = Provider<WatchStatsDao>((ref) {
  final db = ref.read(databaseProvider);
  return WatchStatsDao(db);
});

/// Provider for the WatchTrackingService (singleton during app lifecycle).
final watchTrackingServiceProvider = Provider<WatchTrackingService>((ref) {
  final db = ref.read(databaseProvider);
  final statsDao = ref.read(watchStatsDaoProvider);
  final service = WatchTrackingService(db: db, statsDao: statsDao);
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for the SmartFavoritesService.
final smartFavoritesServiceProvider = Provider<SmartFavoritesService>((ref) {
  final db = ref.read(databaseProvider);
  final statsDao = ref.read(watchStatsDaoProvider);
  return SmartFavoritesService(db: db, statsDao: statsDao);
});

/// Provider for "Continue Watching" items.
final continueWatchingProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final statsDao = ref.read(watchStatsDaoProvider);
  return statsDao.getContinueWatching(limit: 20);
});

/// Provider for recent watch history (filtered by type).
final watchHistoryProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String?>(
  (ref, contentType) async {
    final statsDao = ref.read(watchStatsDaoProvider);
    return statsDao.getRecentByType(contentType: contentType, limit: 50);
  },
);

/// Provider for smart favorite suggestions.
final smartFavoriteSuggestionsProvider =
    FutureProvider<List<FavoriteSuggestion>>((ref) async {
  final service = ref.read(smartFavoritesServiceProvider);
  return service.getSuggestions();
});

/// Provider for most watched channels.
final mostWatchedProvider =
    FutureProvider.autoDispose<List<FavoriteSuggestion>>((ref) async {
  final service = ref.read(smartFavoritesServiceProvider);
  return service.getMostWatched(days: 7);
});
