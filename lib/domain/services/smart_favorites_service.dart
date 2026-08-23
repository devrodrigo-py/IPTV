import 'package:nebula_iptv/data/database/app_database.dart';
import 'package:nebula_iptv/data/database/daos/watch_stats_dao.dart';

/// A suggested favorite based on watch history.
class FavoriteSuggestion {
  final int channelId;
  final String name;
  final String? logoUrl;
  final String? streamUrl;
  final String? sourceType;
  final String? groupName;
  final int sessions;
  final int totalWatchMs;

  const FavoriteSuggestion({
    required this.channelId,
    required this.name,
    this.logoUrl,
    this.streamUrl,
    this.sourceType,
    this.groupName,
    required this.sessions,
    required this.totalWatchMs,
  });

  /// Formatted watch time (e.g., "2h 30min", "45min").
  String get formattedWatchTime {
    final hours = totalWatchMs ~/ 3600000;
    final minutes = (totalWatchMs % 3600000) ~/ 60000;
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    }
    return '${minutes}min';
  }
}

/// Service that generates smart favorite suggestions based on watch patterns.
///
/// Analyzes watch_stats_daily to find channels the user watches frequently
/// but hasn't explicitly favorited yet.
class SmartFavoritesService {
  final AppDatabase _db;
  final WatchStatsDao _statsDao;

  SmartFavoritesService({
    required AppDatabase db,
    required WatchStatsDao statsDao,
  })  : _db = db,
        _statsDao = statsDao;

  /// Gets suggested favorites — channels watched ≥3 times in last 30 days
  /// that aren't already in the user's favorites.
  Future<List<FavoriteSuggestion>> getSuggestions({
    int days = 30,
    int minSessions = 3,
    int limit = 10,
  }) async {
    // Get existing favorite IDs to exclude
    final favoriteIds = await _db.favoritesDao.getFavoriteChannelIds();

    // Get frequently watched channels
    final frequent = await _statsDao.getFrequentChannels(
      days: days,
      minSessions: minSessions,
      limit: limit + favoriteIds.length, // fetch extra to compensate filtering
    );

    // Filter out already favorited channels
    final suggestions = <FavoriteSuggestion>[];
    for (final row in frequent) {
      final channelId = row['channel_id'] as int;
      if (favoriteIds.contains(channelId)) continue;

      suggestions.add(FavoriteSuggestion(
        channelId: channelId,
        name: row['name'] as String? ?? 'Canal $channelId',
        logoUrl: row['logo_url'] as String?,
        streamUrl: row['stream_url'] as String?,
        sourceType: row['source_type'] as String?,
        groupName: row['group_name'] as String?,
        sessions: row['sessions'] as int? ?? 0,
        totalWatchMs: row['total_ms'] as int? ?? 0,
      ));

      if (suggestions.length >= limit) break;
    }

    return suggestions;
  }

  /// Gets the user's "Most Watched" channels in last N days (for display).
  Future<List<FavoriteSuggestion>> getMostWatched({
    int days = 7,
    int limit = 10,
  }) async {
    final results = await _statsDao.getTopChannels(days: days, limit: limit);

    return results.map((row) {
      return FavoriteSuggestion(
        channelId: row['channel_id'] as int,
        name: row['name'] as String? ?? '',
        logoUrl: row['logo_url'] as String?,
        streamUrl: row['stream_url'] as String?,
        sourceType: row['source_type'] as String?,
        groupName: row['group_name'] as String?,
        sessions: row['sessions'] as int? ?? 0,
        totalWatchMs: row['total_ms'] as int? ?? 0,
      );
    }).toList();
  }
}
