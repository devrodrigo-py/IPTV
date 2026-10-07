import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/data/database/app_database.dart';
import 'package:nebula_iptv/features/channels/providers/channels_provider.dart';
import 'package:nebula_iptv/features/profiles/providers/profile_provider.dart';

/// All stats data bundled together.
class StatsData {
  final int totalWatchMs;
  final int totalSessions;
  final int streak;
  final int ratedCount;
  final List<Map<String, dynamic>> dailyWatch; // last 7 days
  final List<Map<String, dynamic>> topLive;
  final List<Map<String, dynamic>> topVod;
  final List<Map<String, dynamic>> topSeries;
  final List<Map<String, dynamic>> categoryDistribution;
  final Map<String, int> contentTypeSplit; // live/vod/series → ms
  final List<Map<String, dynamic>> topRated;

  const StatsData({
    this.totalWatchMs = 0,
    this.totalSessions = 0,
    this.streak = 0,
    this.ratedCount = 0,
    this.dailyWatch = const [],
    this.topLive = const [],
    this.topVod = const [],
    this.topSeries = const [],
    this.categoryDistribution = const [],
    this.contentTypeSplit = const {},
    this.topRated = const [],
  });

  String get totalWatchFormatted {
    final hours = totalWatchMs ~/ 3600000;
    final minutes = (totalWatchMs % 3600000) ~/ 60000;
    if (hours > 0) return '${hours}h ${minutes}min';
    return '${minutes}min';
  }
}

/// Main stats provider that fetches all statistics data.
final statsProvider = FutureProvider.autoDispose<StatsData>((ref) async {
  final profileId = ref.watch(activeProfileProvider);
  final db = ref.read(databaseProvider);

  // Total watch time
  final totalRows = await db
      .customSelect(
        'SELECT COALESCE(SUM(total_watch_ms), 0) as total FROM watch_stats_daily',
      )
      .get();
  final totalWatchMs = (totalRows.first.data['total'] as int?) ?? 0;

  // Total sessions
  final sessionsRows = await db
      .customSelect(
        'SELECT COALESCE(SUM(session_count), 0) as total FROM watch_stats_daily',
      )
      .get();
  final totalSessions = (sessionsRows.first.data['total'] as int?) ?? 0;

  // Daily watch (last 7 days)
  final dailyWatch = await db.watchStatsDao.getDailyWatchTime(days: 7);

  // Streak
  final streak = await _calculateStreak(db);

  // Rating count
  final ratedCount = await db.ratingsDao.getRatingCount(profileId);

  // Top by content type
  final topLive = await _getTopByType(db, 'live');
  final topVod = await _getTopByType(db, 'vod');
  final topSeries = await _getTopByType(db, 'series');

  // Category distribution
  final categoryDist = await _getCategoryDistribution(db);

  // Content type split
  final splitRows = await db.customSelect(
    '''
    SELECT content_type, COALESCE(SUM(total_watch_ms), 0) as total
    FROM watch_stats_daily
    GROUP BY content_type
    ''',
  ).get();
  final contentTypeSplit = <String, int>{};
  for (final row in splitRows) {
    final type = row.data['content_type'] as String? ?? 'live';
    final total = (row.data['total'] as int?) ?? 0;
    contentTypeSplit[type] = total;
  }

  // Top rated
  final topRated = await db.ratingsDao.getTopRated(profileId, limit: 20);

  return StatsData(
    totalWatchMs: totalWatchMs,
    totalSessions: totalSessions,
    streak: streak,
    ratedCount: ratedCount,
    dailyWatch: dailyWatch,
    topLive: topLive,
    topVod: topVod,
    topSeries: topSeries,
    categoryDistribution: categoryDist,
    contentTypeSplit: contentTypeSplit,
    topRated: topRated,
  );
});

Future<int> _calculateStreak(AppDatabase db) async {
  final rows = await db.customSelect(
    '''
    SELECT DISTINCT date FROM watch_stats_daily
    ORDER BY date DESC
    LIMIT 365
    ''',
  ).get();

  if (rows.isEmpty) return 0;

  final dates = rows
      .map((r) => r.data['date'] as String)
      .map((d) => DateTime.tryParse(d))
      .where((d) => d != null)
      .cast<DateTime>()
      .toList();

  if (dates.isEmpty) return 0;

  int streak = 1;
  final today = DateTime.now();

  // If today or yesterday isn't in the list, streak is 0
  final firstDate = dates.first;
  final diff = today.difference(firstDate).inDays;
  if (diff > 1) return 0;

  for (int i = 1; i < dates.length; i++) {
    final dayDiff = dates[i - 1].difference(dates[i]).inDays;
    if (dayDiff == 1) {
      streak++;
    } else {
      break;
    }
  }

  return streak;
}

Future<List<Map<String, dynamic>>> _getTopByType(
    AppDatabase db, String contentType) async {
  final rows = await db.customSelect(
    '''
    SELECT
      s.channel_id,
      SUM(s.total_watch_ms) as total_ms,
      SUM(s.session_count) as sessions,
      c.name,
      c.logo_url,
      c.stream_url,
      c.source_type,
      c.group_name
    FROM watch_stats_daily s
    INNER JOIN channels c ON c.id = s.channel_id
    WHERE s.content_type = ?
    GROUP BY s.channel_id
    ORDER BY total_ms DESC
    LIMIT 10
    ''',
    variables: [Variable.withString(contentType)],
  ).get();
  return rows.map((r) => r.data).toList();
}

Future<List<Map<String, dynamic>>> _getCategoryDistribution(
    AppDatabase db) async {
  final rows = await db.customSelect(
    '''
    SELECT
      c.group_name as category,
      SUM(s.total_watch_ms) as total_ms
    FROM watch_stats_daily s
    INNER JOIN channels c ON c.id = s.channel_id
    WHERE c.group_name IS NOT NULL AND c.group_name != ''
    GROUP BY c.group_name
    ORDER BY total_ms DESC
    LIMIT 10
    ''',
  ).get();
  return rows.map((r) => r.data).toList();
}
