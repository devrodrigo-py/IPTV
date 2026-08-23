/// DDL for the search_aliases table — maps channel IDs to alternative title strings
/// for cross-language search (e.g., "parks" → finds "Confusões de Leslie").
class SearchAliasesTable {
  static const String createTable = '''
    CREATE TABLE IF NOT EXISTS search_aliases (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      channel_id INTEGER NOT NULL,
      alias TEXT NOT NULL,
      normalized_alias TEXT NOT NULL,
      source TEXT NOT NULL DEFAULT 'tmdb',
      UNIQUE(channel_id, normalized_alias)
    )
  ''';

  static const String createIndex = '''
    CREATE INDEX IF NOT EXISTS idx_search_aliases_normalized 
    ON search_aliases(normalized_alias)
  ''';

  static const String createChannelIndex = '''
    CREATE INDEX IF NOT EXISTS idx_search_aliases_channel 
    ON search_aliases(channel_id)
  ''';
}
