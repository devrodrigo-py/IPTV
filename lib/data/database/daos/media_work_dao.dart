import 'package:drift/drift.dart';
import 'package:nebula_iptv/data/database/app_database.dart';
import 'package:nebula_iptv/domain/services/content_matching_service.dart';

/// DAO for the media_works, content_aliases, and pending_matches tables.
///
/// Provides data access for the content matching pipeline (spec 3.1)
/// and the metadata enrichment service.
/// These tables are created via customStatement (no Drift codegen).
class MediaWorkDao extends DatabaseAccessor<AppDatabase> {
  MediaWorkDao(super.db);

  /// Creates the media_works and content_aliases tables if they don't exist.
  Future<void> ensureTables() async {
    await customStatement('''
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
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS content_aliases (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        media_work_id INTEGER NOT NULL,
        alias_text TEXT NOT NULL,
        normalized_text TEXT NOT NULL,
        source TEXT NOT NULL DEFAULT 'auto',
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (media_work_id) REFERENCES media_works(id) ON DELETE CASCADE
      )
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS pending_matches (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        input_name TEXT NOT NULL,
        normalized_input TEXT NOT NULL,
        suggested_media_work_id INTEGER,
        confidence REAL NOT NULL,
        type TEXT NOT NULL DEFAULT 'movie',
        status TEXT NOT NULL DEFAULT 'pending',
        resolved_at TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (suggested_media_work_id) REFERENCES media_works(id) ON DELETE SET NULL
      )
    ''');

    await customStatement('''
      CREATE TABLE IF NOT EXISTS media_work_merge_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        target_id INTEGER NOT NULL,
        target_type TEXT NOT NULL DEFAULT 'media_work',
        action TEXT NOT NULL,
        performed_by TEXT NOT NULL DEFAULT 'auto',
        details TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    // Indexes for efficient lookups.
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_content_aliases_normalized ON content_aliases(normalized_text)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_media_works_type ON media_works(type)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_media_works_normalized_title ON media_works(normalized_title)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_media_works_external_id ON media_works(external_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_pending_matches_status ON pending_matches(status)',
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MediaWork CRUD
  // ═══════════════════════════════════════════════════════════════════════════

  /// Inserts a new media work and returns its ID.
  Future<int> insertMediaWork({
    required String type,
    required String canonicalTitle,
    String? originalTitle,
    String? normalizedTitle,
    int? year,
    String? overviewCache,
    String? posterUrlCache,
    String? bannerUrlCache,
    String? genreCache,
    String? castCache,
    int? externalId,
    String metadataSource = 'none',
  }) async {
    final normalized = normalizedTitle ?? canonicalTitle.toLowerCase();
    return customInsert(
      '''
      INSERT INTO media_works 
        (type, canonical_title, original_title, normalized_title, year,
         overview_cache, poster_url_cache, banner_url_cache, genre_cache,
         cast_cache, external_id, metadata_source, metadata_updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, datetime('now'))
      ''',
      variables: [
        Variable.withString(type),
        Variable.withString(canonicalTitle),
        Variable.withString(originalTitle ?? canonicalTitle),
        Variable.withString(normalized),
        if (year != null) Variable.withInt(year) else const Variable(null),
        if (overviewCache != null)
          Variable.withString(overviewCache)
        else
          const Variable(null),
        if (posterUrlCache != null)
          Variable.withString(posterUrlCache)
        else
          const Variable(null),
        if (bannerUrlCache != null)
          Variable.withString(bannerUrlCache)
        else
          const Variable(null),
        if (genreCache != null)
          Variable.withString(genreCache)
        else
          const Variable(null),
        if (castCache != null)
          Variable.withString(castCache)
        else
          const Variable(null),
        if (externalId != null)
          Variable.withInt(externalId)
        else
          const Variable(null),
        Variable.withString(metadataSource),
      ],
    );
  }

  /// Updates metadata for an existing MediaWork entry.
  Future<void> updateMetadata({
    required int id,
    String? canonicalTitle,
    String? originalTitle,
    int? year,
    String? overviewCache,
    String? posterUrlCache,
    String? bannerUrlCache,
    String? genreCache,
    String? castCache,
    int? externalId,
    String? metadataSource,
  }) async {
    final sets = <String>[];
    final vars = <Variable>[];

    if (canonicalTitle != null) {
      sets.add('canonical_title = ?');
      vars.add(Variable.withString(canonicalTitle));
      sets.add('normalized_title = ?');
      vars.add(Variable.withString(canonicalTitle.toLowerCase()));
    }
    if (originalTitle != null) {
      sets.add('original_title = ?');
      vars.add(Variable.withString(originalTitle));
    }
    if (year != null) {
      sets.add('year = ?');
      vars.add(Variable.withInt(year));
    }
    if (overviewCache != null) {
      sets.add('overview_cache = ?');
      vars.add(Variable.withString(overviewCache));
    }
    if (posterUrlCache != null) {
      sets.add('poster_url_cache = ?');
      vars.add(Variable.withString(posterUrlCache));
    }
    if (bannerUrlCache != null) {
      sets.add('banner_url_cache = ?');
      vars.add(Variable.withString(bannerUrlCache));
    }
    if (genreCache != null) {
      sets.add('genre_cache = ?');
      vars.add(Variable.withString(genreCache));
    }
    if (castCache != null) {
      sets.add('cast_cache = ?');
      vars.add(Variable.withString(castCache));
    }
    if (externalId != null) {
      sets.add('external_id = ?');
      vars.add(Variable.withInt(externalId));
    }
    if (metadataSource != null) {
      sets.add('metadata_source = ?');
      vars.add(Variable.withString(metadataSource));
    }

    // Always update timestamps
    sets.add("metadata_updated_at = datetime('now')");
    sets.add("updated_at = datetime('now')");

    if (sets.isEmpty) return;

    vars.add(Variable.withInt(id));

    await customUpdate(
      'UPDATE media_works SET ${sets.join(', ')} WHERE id = ?',
      variables: vars,
      updates: {},
    );
  }

  /// Gets a MediaWork by its ID.
  Future<MediaWorkEntry?> getById(int id) async {
    final results = await customSelect(
      'SELECT id, canonical_title, normalized_title, type FROM media_works WHERE id = ?',
      variables: [Variable.withInt(id)],
    ).get();

    if (results.isEmpty) return null;

    final row = results.first;
    final aliases = await _getAliasesForWork(id);

    return MediaWorkEntry(
      id: row.read<int>('id'),
      canonicalTitle: row.read<String>('canonical_title'),
      normalizedTitle: row.read<String>('normalized_title'),
      type: row.read<String>('type'),
      aliases: aliases,
    );
  }

  /// Gets a MediaWork by its external ID and source.
  Future<MediaWorkEntry?> getByExternalId(int externalId, String source) async {
    final results = await customSelect(
      '''SELECT id, canonical_title, normalized_title, type FROM media_works 
         WHERE external_id = ? AND metadata_source = ?''',
      variables: [
        Variable.withInt(externalId),
        Variable.withString(source),
      ],
    ).get();

    if (results.isEmpty) return null;

    final row = results.first;
    final workId = row.read<int>('id');
    final aliases = await _getAliasesForWork(workId);

    return MediaWorkEntry(
      id: workId,
      canonicalTitle: row.read<String>('canonical_title'),
      normalizedTitle: row.read<String>('normalized_title'),
      type: row.read<String>('type'),
      aliases: aliases,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Alias operations
  // ═══════════════════════════════════════════════════════════════════════════

  /// Adds an alias for a media work.
  Future<void> insertAlias({
    required int mediaWorkId,
    required String aliasText,
    required String normalizedText,
    String source = 'auto',
  }) async {
    await customInsert(
      '''
      INSERT OR IGNORE INTO content_aliases (media_work_id, alias_text, normalized_text, source)
      VALUES (?, ?, ?, ?)
      ''',
      variables: [
        Variable.withInt(mediaWorkId),
        Variable.withString(aliasText),
        Variable.withString(normalizedText),
        Variable.withString(source),
      ],
    );
  }

  /// Alias for insertAlias (backwards compatibility with ContentMatchingService).
  Future<void> addAlias({
    required int mediaWorkId,
    required String normalizedText,
    String source = 'auto',
  }) async {
    await insertAlias(
      mediaWorkId: mediaWorkId,
      aliasText: normalizedText,
      normalizedText: normalizedText,
      source: source,
    );
  }

  /// Finds a MediaWork by exact alias match (no type filter).
  ///
  /// Used by MetadataEnrichmentService for quick lookups.
  Future<MediaWorkEntry?> findByAlias(String normalizedText) async {
    final results = await customSelect(
      '''
      SELECT mw.id, mw.canonical_title, mw.normalized_title, mw.type
      FROM content_aliases ca
      INNER JOIN media_works mw ON mw.id = ca.media_work_id
      WHERE ca.normalized_text = ?
      LIMIT 1
      ''',
      variables: [Variable.withString(normalizedText)],
    ).get();

    if (results.isEmpty) return null;

    final row = results.first;
    final workId = row.read<int>('id');
    final aliases = await _getAliasesForWork(workId);

    return MediaWorkEntry(
      id: workId,
      canonicalTitle: row.read<String>('canonical_title'),
      normalizedTitle: row.read<String>('normalized_title'),
      type: row.read<String>('type'),
      aliases: aliases,
    );
  }

  /// Finds an exact alias match for a normalized text (with type filter).
  ///
  /// Used by ContentMatchingService for typed lookups.
  Future<MediaWorkEntry?> findExactAlias(
    String normalizedText, {
    String type = 'movie',
  }) async {
    final results = await customSelect(
      '''
      SELECT mw.id, mw.canonical_title, mw.normalized_title, mw.type
      FROM content_aliases ca
      INNER JOIN media_works mw ON mw.id = ca.media_work_id
      WHERE ca.normalized_text = ? AND mw.type = ?
      LIMIT 1
      ''',
      variables: [
        Variable.withString(normalizedText),
        Variable.withString(type),
      ],
    ).get();

    if (results.isEmpty) return null;

    final row = results.first;
    final workId = row.read<int>('id');
    final aliases = await _getAliasesForWork(workId);

    return MediaWorkEntry(
      id: workId,
      canonicalTitle: row.read<String>('canonical_title'),
      normalizedTitle: row.read<String>('normalized_title'),
      type: row.read<String>('type'),
      aliases: aliases,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Batch operations (for ContentMatchingService)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Gets all media works of a given type with their aliases.
  /// Used for batch fuzzy matching.
  Future<List<MediaWorkEntry>> getAllMediaWorks({String type = 'movie'}) async {
    final works = await customSelect(
      'SELECT id, canonical_title, normalized_title, type FROM media_works WHERE type = ?',
      variables: [Variable.withString(type)],
    ).get();

    final entries = <MediaWorkEntry>[];
    for (final row in works) {
      final workId = row.read<int>('id');
      final aliases = await _getAliasesForWork(workId);

      entries.add(
        MediaWorkEntry(
          id: workId,
          canonicalTitle: row.read<String>('canonical_title'),
          normalizedTitle: row.read<String>('normalized_title'),
          type: row.read<String>('type'),
          aliases: aliases,
        ),
      );
    }

    return entries;
  }

  /// Gets all content aliases for a given type.
  /// Used for batch exact matching.
  Future<List<ContentAliasEntry>> getAllAliases({String type = 'movie'}) async {
    final results = await customSelect(
      '''
      SELECT ca.id, ca.media_work_id, ca.normalized_text
      FROM content_aliases ca
      INNER JOIN media_works mw ON mw.id = ca.media_work_id
      WHERE mw.type = ?
      ''',
      variables: [Variable.withString(type)],
    ).get();

    return results
        .map(
          (row) => ContentAliasEntry(
            id: row.read<int>('id'),
            mediaWorkId: row.read<int>('media_work_id'),
            normalizedText: row.read<String>('normalized_text'),
          ),
        )
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Normalization repair (old normalizer stripped trailing numbers)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Returns every stored alias with its original text for re-normalization.
  Future<List<({int id, String aliasText, String normalizedText})>>
      getAllAliasRowsForRepair() async {
    final rows = await customSelect(
      'SELECT id, alias_text, normalized_text FROM content_aliases',
    ).get();
    return rows
        .map(
          (r) => (
            id: r.read<int>('id'),
            aliasText: r.read<String>('alias_text'),
            normalizedText: r.read<String>('normalized_text'),
          ),
        )
        .toList();
  }

  /// Deletes an alias row (used when its normalized form was produced by
  /// the old normalizer — the mapping itself may point at the wrong work).
  Future<void> deleteAliasRow(int id) async {
    await customStatement('DELETE FROM content_aliases WHERE id = ?', [id]);
  }

  /// Returns every work's canonical vs stored normalized title.
  Future<List<({int id, String canonicalTitle, String normalizedTitle})>>
      getWorkTitleRowsForRepair() async {
    final rows = await customSelect(
      'SELECT id, canonical_title, normalized_title FROM media_works',
    ).get();
    return rows
        .map(
          (r) => (
            id: r.read<int>('id'),
            canonicalTitle: r.read<String>('canonical_title'),
            normalizedTitle: r.read<String>('normalized_title'),
          ),
        )
        .toList();
  }

  /// Fixes a work's stored normalized title.
  Future<void> updateNormalizedTitle(int id, String normalizedTitle) async {
    await customStatement(
      'UPDATE media_works SET normalized_title = ? WHERE id = ?',
      [normalizedTitle, id],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Pending matches
  // ═══════════════════════════════════════════════════════════════════════════

  /// Inserts a pending match for manual review.
  Future<void> insertPendingMatch({
    required String inputName,
    required String normalizedInput,
    int? suggestedMediaWorkId,
    required double confidence,
    String type = 'movie',
  }) async {
    await customInsert(
      '''
      INSERT INTO pending_matches 
        (input_name, normalized_input, suggested_media_work_id, confidence, type)
      VALUES (?, ?, ?, ?, ?)
      ''',
      variables: [
        Variable.withString(inputName),
        Variable.withString(normalizedInput),
        if (suggestedMediaWorkId != null)
          Variable.withInt(suggestedMediaWorkId)
        else
          const Variable(null),
        Variable.withReal(confidence),
        Variable.withString(type),
      ],
    );
  }

  /// Gets all pending matches awaiting review.
  Future<List<Map<String, dynamic>>> getPendingMatches({
    int limit = 50,
    int offset = 0,
  }) async {
    final results = await customSelect(
      '''
      SELECT pm.*, mw.canonical_title as suggested_title
      FROM pending_matches pm
      LEFT JOIN media_works mw ON mw.id = pm.suggested_media_work_id
      WHERE pm.status = 'pending'
      ORDER BY pm.confidence DESC
      LIMIT ? OFFSET ?
      ''',
      variables: [Variable.withInt(limit), Variable.withInt(offset)],
    ).get();

    return results.map((row) => row.data).toList();
  }

  /// Resolves a pending match (approve or reject).
  Future<void> resolvePendingMatch({
    required int pendingMatchId,
    required String status, // 'approved', 'rejected', 'new_work'
  }) async {
    await customUpdate(
      '''
      UPDATE pending_matches 
      SET status = ?, resolved_at = datetime('now')
      WHERE id = ?
      ''',
      variables: [
        Variable.withString(status),
        Variable.withInt(pendingMatchId),
      ],
      updates: {},
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Merge log
  // ═══════════════════════════════════════════════════════════════════════════

  /// Logs a merge or unmerge action.
  Future<void> logMerge({
    required int targetId,
    String targetType = 'media_work',
    required String action, // 'merge', 'unmerge'
    String performedBy = 'auto',
    String? details,
  }) async {
    await customInsert(
      '''
      INSERT INTO media_work_merge_log (target_id, target_type, action, performed_by, details)
      VALUES (?, ?, ?, ?, ?)
      ''',
      variables: [
        Variable.withInt(targetId),
        Variable.withString(targetType),
        Variable.withString(action),
        Variable.withString(performedBy),
        if (details != null)
          Variable.withString(details)
        else
          const Variable(null),
      ],
    );
  }

  /// Gets merge history for a target.
  Future<List<Map<String, dynamic>>> getMergeHistory(int targetId) async {
    final results = await customSelect(
      'SELECT * FROM media_work_merge_log WHERE target_id = ? ORDER BY created_at DESC',
      variables: [Variable.withInt(targetId)],
    ).get();

    return results.map((row) => row.data).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Statistics
  // ═══════════════════════════════════════════════════════════════════════════

  /// Gets count of media works by type.
  Future<Map<String, int>> getCountsByType() async {
    final results = await customSelect(
      'SELECT type, COUNT(*) as count FROM media_works GROUP BY type',
    ).get();

    final map = <String, int>{};
    for (final row in results) {
      map[row.read<String>('type')] = row.read<int>('count');
    }
    return map;
  }

  /// Gets count of pending matches.
  Future<int> getPendingMatchCount() async {
    final results = await customSelect(
      "SELECT COUNT(*) as count FROM pending_matches WHERE status = 'pending'",
    ).get();

    return results.first.read<int>('count');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Private helpers
  // ═══════════════════════════════════════════════════════════════════════════

  /// Gets the list of normalized alias texts for a specific media work.
  Future<List<String>> _getAliasesForWork(int workId) async {
    final aliasRows = await customSelect(
      'SELECT normalized_text FROM content_aliases WHERE media_work_id = ?',
      variables: [Variable.withInt(workId)],
    ).get();

    return aliasRows.map((r) => r.read<String>('normalized_text')).toList();
  }
}
