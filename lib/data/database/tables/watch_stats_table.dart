/// SQL statements for WatchStatsDaily table.
///
/// Created via customStatement (no Drift codegen).
/// Part of Etapa 3 — Histórico e Favoritos Inteligentes.
abstract final class WatchStatsSql {
  /// Daily watch statistics per channel.
  static const createWatchStatsDaily = '''
    CREATE TABLE IF NOT EXISTS watch_stats_daily (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      date TEXT NOT NULL,
      channel_id INTEGER NOT NULL,
      content_type TEXT NOT NULL DEFAULT 'live',
      total_watch_ms INTEGER NOT NULL DEFAULT 0,
      session_count INTEGER NOT NULL DEFAULT 0,
      UNIQUE(date, channel_id)
    )
  ''';

  /// Migration: add new columns to watch_history_entries.
  static const alterWatchHistoryColumns = [
    "ALTER TABLE watch_history_entries ADD COLUMN progress_percent REAL NOT NULL DEFAULT 0",
    "ALTER TABLE watch_history_entries ADD COLUMN total_duration_ms INTEGER NOT NULL DEFAULT 0",
    "ALTER TABLE watch_history_entries ADD COLUMN content_type TEXT NOT NULL DEFAULT 'live'",
    "ALTER TABLE watch_history_entries ADD COLUMN series_id INTEGER",
    "ALTER TABLE watch_history_entries ADD COLUMN season_number INTEGER",
    "ALTER TABLE watch_history_entries ADD COLUMN episode_number INTEGER",
    "ALTER TABLE watch_history_entries ADD COLUMN episode_title TEXT",
    "ALTER TABLE watch_history_entries ADD COLUMN thumbnail_url TEXT",
    "ALTER TABLE watch_history_entries ADD COLUMN content_name TEXT",
  ];

  /// Indexes for performance.
  static const createIndexes = [
    'CREATE INDEX IF NOT EXISTS idx_watch_stats_date ON watch_stats_daily(date)',
    'CREATE INDEX IF NOT EXISTS idx_watch_stats_channel ON watch_stats_daily(channel_id)',
    'CREATE INDEX IF NOT EXISTS idx_watch_stats_date_channel ON watch_stats_daily(date, channel_id)',
    'CREATE INDEX IF NOT EXISTS idx_watch_history_content_type ON watch_history_entries(content_type)',
    'CREATE INDEX IF NOT EXISTS idx_watch_history_progress ON watch_history_entries(progress_percent)',
    'CREATE INDEX IF NOT EXISTS idx_watch_history_last_watched ON watch_history_entries(last_watched_at)',
  ];
}
