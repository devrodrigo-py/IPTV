/// SQL constants for profile tables (Etapa 6).
///
/// Profiles allow multiple users on the same device (Netflix-style).
abstract final class ProfileSql {
  static const createProfiles = '''
    CREATE TABLE IF NOT EXISTS profiles (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      avatar_icon TEXT NOT NULL DEFAULT 'person',
      avatar_color TEXT NOT NULL DEFAULT '#7B2FF7',
      is_default INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
  ''';

  static const createUserShortcuts = '''
    CREATE TABLE IF NOT EXISTS user_shortcuts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      profile_id INTEGER NOT NULL DEFAULT 1,
      channel_id INTEGER NOT NULL,
      position INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (profile_id) REFERENCES profiles(id) ON DELETE CASCADE
    )
  ''';

  /// Add profile_id to existing tables.
  static const alterStatements = [
    'ALTER TABLE watch_history_entries ADD COLUMN profile_id INTEGER NOT NULL DEFAULT 1',
    'ALTER TABLE favorites ADD COLUMN profile_id INTEGER NOT NULL DEFAULT 1',
    'ALTER TABLE watch_stats_daily ADD COLUMN profile_id INTEGER NOT NULL DEFAULT 1',
  ];

  static const createIndexes = [
    'CREATE INDEX IF NOT EXISTS idx_profiles_default ON profiles(is_default)',
    'CREATE INDEX IF NOT EXISTS idx_shortcuts_profile ON user_shortcuts(profile_id)',
    'CREATE INDEX IF NOT EXISTS idx_shortcuts_channel ON user_shortcuts(channel_id)',
  ];

  /// Insert default profile on first creation.
  static const insertDefaultProfile = '''
    INSERT OR IGNORE INTO profiles (id, name, avatar_icon, avatar_color, is_default)
    VALUES (1, 'Principal', 'person', '#7B2FF7', 1)
  ''';
}
