import 'package:drift/drift.dart';
import 'package:nebula_iptv/data/database/app_database.dart';
import 'package:nebula_iptv/data/database/tables/health_check_tables.dart';

/// Health check entry for a channel.
class HealthCheckEntry {
  final int id;
  final int channelId;
  final String status; // 'online', 'offline', 'unknown'
  final int? latencyMs;
  final int consecutiveFailures;
  final DateTime? lastCheckedAt;
  final DateTime? nextCheckAt;
  final DateTime createdAt;

  const HealthCheckEntry({
    required this.id,
    required this.channelId,
    required this.status,
    this.latencyMs,
    this.consecutiveFailures = 0,
    this.lastCheckedAt,
    this.nextCheckAt,
    required this.createdAt,
  });
}

/// Health statistics summary.
class HealthStats {
  final int total;
  final int online;
  final int offline;
  final int unknown;
  final double averageLatencyMs;

  const HealthStats({
    required this.total,
    required this.online,
    required this.offline,
    required this.unknown,
    this.averageLatencyMs = 0,
  });
}

/// Manual DAO for the channel_health_checks table (no code generation).
class HealthCheckDao extends DatabaseAccessor<AppDatabase> {
  HealthCheckDao(super.db);

  /// Creates the health checks table if it doesn't exist.
  Future<void> ensureTable() async {
    await customStatement(HealthCheckSql.createHealthChecks);
    for (final indexSql in HealthCheckSql.createIndexes) {
      await customStatement(indexSql);
    }
  }

  /// Upserts a health check result for a channel.
  Future<void> upsertCheck({
    required int channelId,
    required String status,
    int? latencyMs,
    required int consecutiveFailures,
    required DateTime nextCheckAt,
  }) async {
    await customInsert(
      '''
      INSERT INTO channel_health_checks 
        (channel_id, status, latency_ms, consecutive_failures, last_checked_at, next_check_at)
      VALUES (?, ?, ?, ?, datetime('now'), ?)
      ON CONFLICT(channel_id) DO UPDATE SET
        status = excluded.status,
        latency_ms = excluded.latency_ms,
        consecutive_failures = excluded.consecutive_failures,
        last_checked_at = datetime('now'),
        next_check_at = excluded.next_check_at
      ''',
      variables: [
        Variable.withInt(channelId),
        Variable.withString(status),
        if (latencyMs != null)
          Variable.withInt(latencyMs)
        else
          const Variable(null),
        Variable.withInt(consecutiveFailures),
        Variable.withString(nextCheckAt.toIso8601String()),
      ],
    );
  }

  /// Gets the health check entry for a specific channel.
  Future<HealthCheckEntry?> getCheckForChannel(int channelId) async {
    final results = await customSelect(
      'SELECT * FROM channel_health_checks WHERE channel_id = ?',
      variables: [Variable.withInt(channelId)],
    ).get();

    if (results.isEmpty) return null;
    return _rowToEntry(results.first);
  }

  /// Gets channel IDs that are due for a health check.
  ///
  /// Returns channels where next_check_at <= now OR that have never been checked.
  Future<List<int>> getChannelsDueForCheck(int limit) async {
    final results = await customSelect(
      '''
      SELECT c.id as channel_id
      FROM channels c
      LEFT JOIN channel_health_checks hc ON hc.channel_id = c.id
      WHERE c.is_active = 1
        AND (hc.next_check_at IS NULL OR hc.next_check_at <= datetime('now'))
      ORDER BY hc.next_check_at ASC NULLS FIRST
      LIMIT ?
      ''',
      variables: [Variable.withInt(limit)],
    ).get();

    return results.map((r) => r.read<int>('channel_id')).toList();
  }

  /// Gets overall health statistics.
  Future<HealthStats> getHealthStats() async {
    final results = await customSelect('''
      SELECT
        COUNT(*) as total,
        SUM(CASE WHEN status = 'online' THEN 1 ELSE 0 END) as online_count,
        SUM(CASE WHEN status = 'offline' THEN 1 ELSE 0 END) as offline_count,
        SUM(CASE WHEN status = 'unknown' THEN 1 ELSE 0 END) as unknown_count,
        AVG(CASE WHEN status = 'online' THEN latency_ms ELSE NULL END) as avg_latency
      FROM channel_health_checks
    ''').get();

    if (results.isEmpty) {
      return const HealthStats(total: 0, online: 0, offline: 0, unknown: 0);
    }

    final row = results.first;
    return HealthStats(
      total: row.read<int>('total'),
      online: row.read<int>('online_count'),
      offline: row.read<int>('offline_count'),
      unknown: row.read<int>('unknown_count'),
      averageLatencyMs: row.readNullable<double>('avg_latency') ?? 0,
    );
  }

  /// Updates the next check time for a channel.
  Future<void> setNextCheckTime(int channelId, DateTime nextCheckAt) async {
    await customUpdate(
      'UPDATE channel_health_checks SET next_check_at = ? WHERE channel_id = ?',
      variables: [
        Variable.withString(nextCheckAt.toIso8601String()),
        Variable.withInt(channelId),
      ],
      updates: {},
    );
  }

  /// Gets offline channels with pagination.
  Future<List<HealthCheckEntry>> getOfflineChannels({
    int limit = 50,
    int offset = 0,
  }) async {
    final results = await customSelect(
      '''
      SELECT * FROM channel_health_checks 
      WHERE status = 'offline' 
      ORDER BY consecutive_failures DESC
      LIMIT ? OFFSET ?
      ''',
      variables: [Variable.withInt(limit), Variable.withInt(offset)],
    ).get();

    return results.map(_rowToEntry).toList();
  }

  /// Gets the consecutive failure count for a channel.
  Future<int> getConsecutiveFailures(int channelId) async {
    final results = await customSelect(
      'SELECT consecutive_failures FROM channel_health_checks WHERE channel_id = ?',
      variables: [Variable.withInt(channelId)],
    ).get();

    if (results.isEmpty) return 0;
    return results.first.read<int>('consecutive_failures');
  }

  /// Resets health check data for all channels (e.g., after reimport).
  Future<void> clearAll() async {
    await customStatement('DELETE FROM channel_health_checks');
  }

  HealthCheckEntry _rowToEntry(QueryRow row) {
    return HealthCheckEntry(
      id: row.read<int>('id'),
      channelId: row.read<int>('channel_id'),
      status: row.read<String>('status'),
      latencyMs: row.readNullable<int>('latency_ms'),
      consecutiveFailures: row.read<int>('consecutive_failures'),
      lastCheckedAt: row.readNullable<String>('last_checked_at') != null
          ? DateTime.tryParse(row.read<String>('last_checked_at'))
          : null,
      nextCheckAt: row.readNullable<String>('next_check_at') != null
          ? DateTime.tryParse(row.read<String>('next_check_at'))
          : null,
      createdAt: DateTime.tryParse(
            row.readNullable<String>('created_at') ?? '',
          ) ??
          DateTime.now(),
    );
  }
}
