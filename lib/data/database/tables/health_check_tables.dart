/// SQL statements for channel health check tables.
///
/// These are created via customStatement (no Drift codegen).
/// Part of Etapa 2 — Organização Inteligente.
abstract final class HealthCheckSql {
  /// Table to track channel availability and latency.
  static const createHealthChecks = '''
    CREATE TABLE IF NOT EXISTS channel_health_checks (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      channel_id INTEGER NOT NULL,
      status TEXT NOT NULL DEFAULT 'unknown',
      latency_ms INTEGER,
      consecutive_failures INTEGER NOT NULL DEFAULT 0,
      last_checked_at TEXT,
      next_check_at TEXT,
      created_at TEXT NOT NULL DEFAULT (datetime('now')),
      UNIQUE(channel_id)
    )
  ''';

  /// Indexes for performance.
  static const createIndexes = [
    'CREATE INDEX IF NOT EXISTS idx_health_channel ON channel_health_checks(channel_id)',
    'CREATE INDEX IF NOT EXISTS idx_health_status ON channel_health_checks(status)',
    'CREATE INDEX IF NOT EXISTS idx_health_next_check ON channel_health_checks(next_check_at)',
  ];
}
