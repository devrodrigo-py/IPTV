/// SQL statements for ChannelGroup tables.
///
/// These are created via customStatement (no Drift codegen).
/// Part of Etapa 2 — Organização Inteligente.
abstract final class ChannelGroupSql {
  /// ChannelGroup — groups quality variants of the same channel.
  static const createChannelGroups = '''
    CREATE TABLE IF NOT EXISTS channel_groups (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      display_name TEXT NOT NULL,
      normalized_name TEXT NOT NULL,
      primary_channel_id INTEGER,
      confidence_score REAL NOT NULL DEFAULT 1.0,
      source TEXT NOT NULL DEFAULT 'auto',
      created_at TEXT NOT NULL DEFAULT (datetime('now'))
    )
  ''';

  /// ChannelGroupMembers — links channels to their group.
  static const createChannelGroupMembers = '''
    CREATE TABLE IF NOT EXISTS channel_group_members (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      group_id INTEGER NOT NULL REFERENCES channel_groups(id) ON DELETE CASCADE,
      channel_id INTEGER NOT NULL,
      quality_tag TEXT,
      priority INTEGER NOT NULL DEFAULT 0,
      UNIQUE(group_id, channel_id)
    )
  ''';

  /// Indexes for performance.
  static const createIndexes = [
    'CREATE INDEX IF NOT EXISTS idx_channel_groups_normalized ON channel_groups(normalized_name)',
    'CREATE INDEX IF NOT EXISTS idx_group_members_group ON channel_group_members(group_id)',
    'CREATE INDEX IF NOT EXISTS idx_group_members_channel ON channel_group_members(channel_id)',
  ];
}
