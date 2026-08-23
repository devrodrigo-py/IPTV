/// SQL constants for user ratings table (Etapa 7).
abstract final class RatingsSql {
  static const createUserRatings = '''
    CREATE TABLE IF NOT EXISTS user_ratings (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      profile_id INTEGER NOT NULL DEFAULT 1,
      channel_id INTEGER NOT NULL,
      rating REAL NOT NULL,
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      UNIQUE(profile_id, channel_id)
    )
  ''';

  static const createIndexes = [
    'CREATE INDEX IF NOT EXISTS idx_ratings_profile ON user_ratings(profile_id)',
    'CREATE INDEX IF NOT EXISTS idx_ratings_channel ON user_ratings(channel_id)',
    'CREATE INDEX IF NOT EXISTS idx_ratings_rating ON user_ratings(rating DESC)',
  ];
}
