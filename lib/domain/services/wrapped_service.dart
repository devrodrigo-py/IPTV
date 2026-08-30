import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/core/logging/app_logger.dart';
import 'package:nebula_iptv/data/database/app_database.dart';
import 'package:nebula_iptv/features/channels/providers/channels_provider.dart';
import 'package:nebula_iptv/features/profiles/providers/profile_provider.dart';

/// Data model for Nebula Wrapped stats.
class WrappedData {
  final int totalHoursWatched;
  final int totalMinutesRemainder;
  final int totalMoviesWatched;
  final int totalSeriesEpisodes;
  final String favoriteGenre;
  final String favoriteTimeOfDay;
  final String? topChannelName;
  final String? topMovieName;
  final String? topSeriesName;
  final int totalDaysActive;
  final int longestSessionMinutes;
  final int totalSessions;

  const WrappedData({
    this.totalHoursWatched = 0,
    this.totalMinutesRemainder = 0,
    this.totalMoviesWatched = 0,
    this.totalSeriesEpisodes = 0,
    this.favoriteGenre = 'Não definido',
    this.favoriteTimeOfDay = 'Noite',
    this.topChannelName,
    this.topMovieName,
    this.topSeriesName,
    this.totalDaysActive = 0,
    this.longestSessionMinutes = 0,
    this.totalSessions = 0,
  });
}

/// Service that gathers all data for Nebula Wrapped.
class WrappedService {
  final AppDatabase _db;
  final int _profileId;

  WrappedService(this._db, this._profileId);

  Future<WrappedData> generateWrapped() async {
    final totalMs = await _getTotalWatchMs();
    final totalHours = totalMs ~/ 3600000;
    final totalMinutes = (totalMs % 3600000) ~/ 60000;

    final moviesWatched = await _getMoviesWatched();
    final seriesEpisodes = await _getSeriesEpisodes();
    final genre = await _getFavoriteGenre();
    final timeOfDay = await _getFavoriteTimeOfDay();
    final topChannel = await _getTopByType('xtream');
    final topMovie = await _getTopByType('vod');
    final topSeries = await _getTopByType('series');
    final daysActive = await _getDaysActive();
    final longestSession = await _getLongestSession();
    final totalSessions = await _getTotalSessions();

    return WrappedData(
      totalHoursWatched: totalHours,
      totalMinutesRemainder: totalMinutes,
      totalMoviesWatched: moviesWatched,
      totalSeriesEpisodes: seriesEpisodes,
      favoriteGenre: genre,
      favoriteTimeOfDay: timeOfDay,
      topChannelName: topChannel,
      topMovieName: topMovie,
      topSeriesName: topSeries,
      totalDaysActive: daysActive,
      longestSessionMinutes: longestSession,
      totalSessions: totalSessions,
    );
  }

  Future<int> _getTotalWatchMs() async {
    final rows = await _db.customSelect(
      'SELECT COALESCE(SUM(total_watch_ms), 0) as total FROM watch_stats_daily WHERE profile_id = ?',
      variables: [Variable.withInt(_profileId)],
    ).get();
    return rows.first.data['total'] as int? ?? 0;
  }

  Future<int> _getMoviesWatched() async {
    final rows = await _db.customSelect(
      '''SELECT COUNT(DISTINCT channel_id) as cnt FROM watch_history_entries
         WHERE profile_id = ? AND content_type = 'vod' AND progress_percent > 0.8''',
      variables: [Variable.withInt(_profileId)],
    ).get();
    return rows.first.data['cnt'] as int? ?? 0;
  }

  Future<int> _getSeriesEpisodes() async {
    final rows = await _db.customSelect(
      '''SELECT COUNT(*) as cnt FROM watch_history_entries
         WHERE profile_id = ? AND content_type = 'series' AND watched_duration_ms > 60000''',
      variables: [Variable.withInt(_profileId)],
    ).get();
    return rows.first.data['cnt'] as int? ?? 0;
  }

  Future<String> _getFavoriteGenre() async {
    final rows = await _db.customSelect(
      '''SELECT c.group_name, SUM(w.total_watch_ms) as total
         FROM watch_stats_daily w
         JOIN channels c ON w.channel_id = c.id
         WHERE w.profile_id = ? AND c.group_name IS NOT NULL AND c.group_name != ''
         GROUP BY c.group_name
         ORDER BY total DESC
         LIMIT 1''',
      variables: [Variable.withInt(_profileId)],
    ).get();
    if (rows.isEmpty) return 'Não definido';
    final groupName = rows.first.data['group_name'] as String? ?? '';
    // Extract category after "| " if present
    final parts = groupName.split('|');
    return parts.length > 1 ? parts.last.trim() : groupName.trim();
  }

  Future<String> _getFavoriteTimeOfDay() async {
    final rows = await _db.customSelect(
      '''SELECT last_watched_at FROM watch_history_entries
         WHERE profile_id = ? AND last_watched_at IS NOT NULL''',
      variables: [Variable.withInt(_profileId)],
    ).get();

    if (rows.isEmpty) return 'Noite';

    int morning = 0, afternoon = 0, evening = 0, night = 0;
    for (final row in rows) {
      final ts = row.data['last_watched_at'];
      if (ts == null) continue;
      try {
        final dt = DateTime.parse(ts.toString());
        final hour = dt.hour;
        if (hour >= 6 && hour < 12) {
          morning++;
        } else if (hour >= 12 && hour < 18) {
          afternoon++;
        } else if (hour >= 18 && hour < 24) {
          evening++;
        } else {
          night++;
        }
      } catch (e) {
        // Linha individual com timestamp inválido: ignora, mas registra.
        appLogger.d('[Wrapped] Timestamp inválido no histórico: $e');
      }
    }

    final max =
        [morning, afternoon, evening, night].reduce((a, b) => a > b ? a : b);
    if (max == morning) return 'Manhã ☀️';
    if (max == afternoon) return 'Tarde 🌤️';
    if (max == evening) return 'Noite 🌙';
    return 'Madrugada 🌃';
  }

  Future<String?> _getTopByType(String contentType) async {
    final rows = await _db.customSelect(
      '''SELECT c.name, SUM(w.total_watch_ms) as total
         FROM watch_stats_daily w
         JOIN channels c ON w.channel_id = c.id
         WHERE w.profile_id = ? AND w.content_type = ?
         GROUP BY w.channel_id
         ORDER BY total DESC
         LIMIT 1''',
      variables: [
        Variable.withInt(_profileId),
        Variable.withString(contentType)
      ],
    ).get();
    if (rows.isEmpty) return null;
    return rows.first.data['name'] as String?;
  }

  Future<int> _getDaysActive() async {
    final rows = await _db.customSelect(
      'SELECT COUNT(DISTINCT date) as cnt FROM watch_stats_daily WHERE profile_id = ?',
      variables: [Variable.withInt(_profileId)],
    ).get();
    return rows.first.data['cnt'] as int? ?? 0;
  }

  Future<int> _getLongestSession() async {
    final rows = await _db.customSelect(
      '''SELECT MAX(watched_duration_ms) as longest FROM watch_history_entries
         WHERE profile_id = ?''',
      variables: [Variable.withInt(_profileId)],
    ).get();
    final ms = rows.first.data['longest'] as int? ?? 0;
    return ms ~/ 60000;
  }

  Future<int> _getTotalSessions() async {
    final rows = await _db.customSelect(
      'SELECT COALESCE(SUM(session_count), 0) as total FROM watch_stats_daily WHERE profile_id = ?',
      variables: [Variable.withInt(_profileId)],
    ).get();
    return rows.first.data['total'] as int? ?? 0;
  }
}

/// Provider for Wrapped data.
final wrappedProvider = FutureProvider.autoDispose<WrappedData>((ref) async {
  final db = ref.read(databaseProvider);
  final profileId = ref.read(activeProfileProvider);
  final service = WrappedService(db, profileId);
  return service.generateWrapped();
});
