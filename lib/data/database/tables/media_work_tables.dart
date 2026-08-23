/// SQL statements for MediaWork content foundation tables.
///
/// These are created via customStatement (no Drift codegen).
/// Part of Etapa 1 — Fundação de Conteúdo.
abstract final class MediaWorkSql {
  /// MediaWork — the canonical representation of a piece of content.
  static const createMediaWork = '''
    CREATE TABLE IF NOT EXISTS media_works (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      type TEXT NOT NULL DEFAULT 'movie',
      canonical_title TEXT NOT NULL,
      original_title TEXT,
      normalized_title TEXT NOT NULL,
      year INTEGER,
      overview_cache TEXT,
      poster_url_cache TEXT,
      banner_url_cache TEXT,
      genre_cache TEXT,
      cast_cache TEXT,
      external_id INTEGER,
      metadata_source TEXT NOT NULL DEFAULT 'none',
      metadata_updated_at TEXT,
      created_at TEXT NOT NULL DEFAULT (datetime('now')),
      updated_at TEXT NOT NULL DEFAULT (datetime('now'))
    )
  ''';

  /// ContentAlias — maps various names to a single MediaWork.
  static const createContentAlias = '''
    CREATE TABLE IF NOT EXISTS content_aliases (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      media_work_id INTEGER NOT NULL REFERENCES media_works(id) ON DELETE CASCADE,
      alias_text TEXT NOT NULL,
      normalized_text TEXT NOT NULL,
      source TEXT NOT NULL DEFAULT 'auto',
      created_at TEXT NOT NULL DEFAULT (datetime('now'))
    )
  ''';

  /// MediaWorkMergeLog — audit trail for merge/unmerge operations.
  static const createMergeLog = '''
    CREATE TABLE IF NOT EXISTS media_work_merge_log (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      target_id INTEGER NOT NULL,
      target_type TEXT NOT NULL DEFAULT 'media_work',
      action TEXT NOT NULL,
      performed_by TEXT NOT NULL DEFAULT 'auto',
      details TEXT,
      created_at TEXT NOT NULL DEFAULT (datetime('now'))
    )
  ''';

  /// PendingMatch — queue of matches needing user review (score 0.60-0.84).
  static const createPendingMatch = '''
    CREATE TABLE IF NOT EXISTS pending_matches (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      input_name TEXT NOT NULL,
      normalized_input TEXT NOT NULL,
      suggested_media_work_id INTEGER REFERENCES media_works(id) ON DELETE SET NULL,
      confidence REAL NOT NULL,
      type TEXT NOT NULL DEFAULT 'movie',
      status TEXT NOT NULL DEFAULT 'pending',
      resolved_at TEXT,
      created_at TEXT NOT NULL DEFAULT (datetime('now'))
    )
  ''';

  /// Indexes for performance.
  static const createIndexes = [
    'CREATE INDEX IF NOT EXISTS idx_media_works_type ON media_works(type)',
    'CREATE INDEX IF NOT EXISTS idx_media_works_normalized_title ON media_works(normalized_title)',
    'CREATE INDEX IF NOT EXISTS idx_media_works_external_id ON media_works(external_id)',
    'CREATE INDEX IF NOT EXISTS idx_media_works_metadata_source ON media_works(metadata_source)',
    'CREATE INDEX IF NOT EXISTS idx_content_aliases_media_work_id ON content_aliases(media_work_id)',
    'CREATE INDEX IF NOT EXISTS idx_content_aliases_normalized_text ON content_aliases(normalized_text)',
    'CREATE INDEX IF NOT EXISTS idx_pending_matches_status ON pending_matches(status)',
    'CREATE INDEX IF NOT EXISTS idx_merge_log_target ON media_work_merge_log(target_id, target_type)',
  ];

  /// Migration: link VOD items to MediaWork.
  static const addMediaWorkIdToVod =
      'ALTER TABLE vod_items ADD COLUMN media_work_id INTEGER REFERENCES media_works(id)';

  /// Migration: link Series items to MediaWork.
  static const addMediaWorkIdToSeries =
      'ALTER TABLE series_items ADD COLUMN media_work_id INTEGER REFERENCES media_works(id)';
}
