import 'package:drift/drift.dart';
import 'package:nebula_iptv/data/database/app_database.dart';

/// DAO for watch statistics and enhanced history queries.
///
/// No codegen — uses customSelect/customStatement directly.
class WatchStatsDao extends DatabaseAccessor<AppDatabase> {
  WatchStatsDao(super.db);

  /// Upserts a daily watch stat for a channel.
  Future<void> upsertDailyStat({
    required String date,
    required int channelId,
    required String contentType,
    required int watchMs,
  }) async {
    await customStatement(
      '''
      INSERT INTO watch_stats_daily (date, channel_id, content_type, total_watch_ms, session_count)
      VALUES (?, ?, ?, ?, 1)
      ON CONFLICT(date, channel_id)
      DO UPDATE SET
        total_watch_ms = total_watch_ms + excluded.total_watch_ms,
        session_count = session_count + 1
      ''',
      [date, channelId, contentType, watchMs],
    );
  }

  /// Gets top watched channels in the last N days.
  Future<List<Map<String, dynamic>>> getTopChannels({
    int days = 7,
    int limit = 20,
  }) async {
    final since = DateTime.now().subtract(Duration(days: days));
    final dateStr = since.toIso8601String().substring(0, 10);

    final rows = await customSelect(
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
      WHERE s.date >= ?
      GROUP BY s.channel_id
      ORDER BY total_ms DESC
      LIMIT ?
      ''',
      variables: [Variable.withString(dateStr), Variable.withInt(limit)],
    ).get();

    return rows.map((r) => r.data).toList();
  }

  /// Gets channels watched more than N times (for smart favorites suggestions).
  Future<List<Map<String, dynamic>>> getFrequentChannels({
    int days = 30,
    int minSessions = 3,
    int limit = 10,
  }) async {
    final since = DateTime.now().subtract(Duration(days: days));
    final dateStr = since.toIso8601String().substring(0, 10);

    final rows = await customSelect(
      '''
      SELECT
        s.channel_id,
        SUM(s.session_count) as sessions,
        SUM(s.total_watch_ms) as total_ms,
        c.name,
        c.logo_url,
        c.stream_url,
        c.source_type,
        c.group_name
      FROM watch_stats_daily s
      INNER JOIN channels c ON c.id = s.channel_id
      WHERE s.date >= ?
      GROUP BY s.channel_id
      HAVING sessions >= ?
      ORDER BY sessions DESC
      LIMIT ?
      ''',
      variables: [
        Variable.withString(dateStr),
        Variable.withInt(minSessions),
        Variable.withInt(limit),
      ],
    ).get();

    return rows.map((r) => r.data).toList();
  }

  /// Gets daily watch time aggregated (for stats display).
  Future<List<Map<String, dynamic>>> getDailyWatchTime({int days = 7}) async {
    final since = DateTime.now().subtract(Duration(days: days));
    final dateStr = since.toIso8601String().substring(0, 10);

    final rows = await customSelect(
      '''
      SELECT date, SUM(total_watch_ms) as total_ms, SUM(session_count) as sessions
      FROM watch_stats_daily
      WHERE date >= ?
      GROUP BY date
      ORDER BY date ASC
      ''',
      variables: [Variable.withString(dateStr)],
    ).get();

    return rows.map((r) => r.data).toList();
  }

  // --- Enhanced Watch History methods ---

  /// Gets items to "Continue Watching" (progress between 5% and 95%).
  Future<List<Map<String, dynamic>>> getContinueWatching({
    int limit = 20,
  }) async {
    final rows = await customSelect(
      '''
      SELECT
        h.*,
        c.name as channel_name,
        c.logo_url,
        c.stream_url,
        c.source_type,
        c.group_name
      FROM watch_history_entries h
      INNER JOIN channels c ON c.id = h.channel_id
      WHERE h.watched_duration_ms > 5000
        AND (h.progress_percent < 0.95 OR h.progress_percent = 0)
        AND h.content_type IN ('vod', 'series')
      ORDER BY h.last_watched_at DESC
      LIMIT ?
      ''',
      variables: [Variable.withInt(limit)],
    ).get();

    return rows.map((r) => r.data).toList();
  }

  /// Gets recent history by content type.
  Future<List<Map<String, dynamic>>> getRecentByType({
    String? contentType,
    int limit = 50,
  }) async {
    final String where;
    final List<Variable> variables;

    if (contentType != null && contentType != 'all') {
      where = 'WHERE h.content_type = ?';
      variables = [Variable.withString(contentType), Variable.withInt(limit)];
    } else {
      where = '';
      variables = [Variable.withInt(limit)];
    }

    final rows = await customSelect(
      '''
      SELECT
        h.*,
        c.name as channel_name,
        c.logo_url,
        c.stream_url,
        c.source_type,
        c.group_name
      FROM watch_history_entries h
      INNER JOIN channels c ON c.id = h.channel_id
      $where
      ORDER BY h.last_watched_at DESC
      LIMIT ?
      ''',
      variables: variables,
    ).get();

    return rows.map((r) => r.data).toList();
  }

  /// Upserts an enhanced watch history entry.
  Future<void> upsertWatchEntry({
    required int channelId,
    required int watchedDurationMs,
    required double progressPercent,
    required int totalDurationMs,
    required String contentType,
    String? contentName,
    int? seriesId,
    int? seasonNumber,
    int? episodeNumber,
    String? episodeTitle,
    String? thumbnailUrl,
  }) async {
    // Check if entry exists
    final existing = await customSelect(
      'SELECT id, watched_duration_ms FROM watch_history_entries WHERE channel_id = ?',
      variables: [Variable.withInt(channelId)],
    ).get();

    if (existing.isNotEmpty) {
      final existingId = existing.first.read<int>('id');
      final existingDuration = existing.first.read<int>('watched_duration_ms');
      // Use the greater value: either the new position or the previously stored one
      final effectiveDuration = watchedDurationMs > existingDuration
          ? watchedDurationMs
          : existingDuration;
      await customStatement(
        '''
        UPDATE watch_history_entries SET
          last_watched_at = datetime('now'),
          watched_duration_ms = ?,
          progress_percent = ?,
          total_duration_ms = ?,
          content_type = ?,
          content_name = ?,
          series_id = ?,
          season_number = ?,
          episode_number = ?,
          episode_title = ?,
          thumbnail_url = ?
        WHERE id = ?
        ''',
        [
          effectiveDuration,
          progressPercent,
          totalDurationMs,
          contentType,
          contentName,
          seriesId,
          seasonNumber,
          episodeNumber,
          episodeTitle,
          thumbnailUrl,
          existingId,
        ],
      );
    } else {
      await customStatement(
        '''
        INSERT INTO watch_history_entries
          (channel_id, started_at, last_watched_at, watched_duration_ms,
           progress_percent, total_duration_ms, content_type, content_name,
           series_id, season_number, episode_number, episode_title, thumbnail_url)
        VALUES (?, datetime('now'), datetime('now'), ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          channelId,
          watchedDurationMs,
          progressPercent,
          totalDurationMs,
          contentType,
          contentName,
          seriesId,
          seasonNumber,
          episodeNumber,
          episodeTitle,
          thumbnailUrl,
        ],
      );
    }
  }
}
