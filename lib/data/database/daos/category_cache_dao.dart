import 'package:drift/drift.dart';
import 'package:nebula_iptv/data/database/app_database.dart';

/// DAO for the category_cache table.
///
/// Caches Xtream category names (id → name mappings) to resolve
/// numeric category IDs to friendly display names.
class CategoryCacheDao extends DatabaseAccessor<AppDatabase> {
  CategoryCacheDao(super.db);

  /// Creates the category_cache table if it doesn't exist.
  Future<void> ensureTable() async {
    await customStatement('''
      CREATE TABLE IF NOT EXISTS category_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        playlist_id INTEGER NOT NULL,
        category_id TEXT NOT NULL,
        category_name TEXT NOT NULL,
        source_type TEXT NOT NULL DEFAULT 'live',
        updated_at TEXT NOT NULL DEFAULT (datetime('now')),
        UNIQUE(playlist_id, category_id, source_type)
      )
    ''');
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_category_cache_lookup
      ON category_cache(playlist_id, source_type)
    ''');
  }

  /// Inserts or updates a category mapping.
  Future<void> upsertCategory({
    required int playlistId,
    required String categoryId,
    required String categoryName,
    required String sourceType,
  }) async {
    await customInsert(
      '''
      INSERT OR REPLACE INTO category_cache 
        (playlist_id, category_id, category_name, source_type, updated_at)
      VALUES (?, ?, ?, ?, datetime('now'))
      ''',
      variables: [
        Variable.withInt(playlistId),
        Variable.withString(categoryId),
        Variable.withString(categoryName),
        Variable.withString(sourceType),
      ],
    );
  }

  /// Batch inserts category mappings from a map.
  Future<void> upsertCategories({
    required int playlistId,
    required Map<String, String> categoryMap,
    required String sourceType,
  }) async {
    for (final entry in categoryMap.entries) {
      await upsertCategory(
        playlistId: playlistId,
        categoryId: entry.key,
        categoryName: entry.value,
        sourceType: sourceType,
      );
    }
  }

  /// Gets a single category name.
  Future<String?> getCategoryName({
    required int playlistId,
    required String categoryId,
    required String sourceType,
  }) async {
    final results = await customSelect(
      '''SELECT category_name FROM category_cache 
         WHERE playlist_id = ? AND category_id = ? AND source_type = ?''',
      variables: [
        Variable.withInt(playlistId),
        Variable.withString(categoryId),
        Variable.withString(sourceType),
      ],
    ).get();

    if (results.isEmpty) return null;
    return results.first.read<String>('category_name');
  }

  /// Gets all category mappings for a playlist and source type.
  Future<Map<String, String>> getAllCategories({
    required int playlistId,
    required String sourceType,
  }) async {
    final results = await customSelect(
      '''SELECT category_id, category_name FROM category_cache 
         WHERE playlist_id = ? AND source_type = ?''',
      variables: [
        Variable.withInt(playlistId),
        Variable.withString(sourceType),
      ],
    ).get();

    final map = <String, String>{};
    for (final row in results) {
      map[row.read<String>('category_id')] =
          row.read<String>('category_name');
    }
    return map;
  }

  /// Resolves numeric groupName values in existing channels for a playlist.
  /// Updates channels whose groupName matches a cached category_id.
  Future<int> resolveExistingChannels(int playlistId) async {
    final categories = await getAllCategories(
      playlistId: playlistId,
      sourceType: 'live',
    );

    var resolved = 0;
    for (final entry in categories.entries) {
      final updated = await customUpdate(
        '''UPDATE channels SET group_name = ? 
           WHERE playlist_id = ? AND group_name = ?''',
        variables: [
          Variable.withString(entry.value),
          Variable.withInt(playlistId),
          Variable.withString(entry.key),
        ],
        updates: {},
      );
      resolved += updated;
    }
    return resolved;
  }

  /// Resolves numeric categoryName values in existing VOD items.
  Future<int> resolveExistingVodItems(int playlistId) async {
    final categories = await getAllCategories(
      playlistId: playlistId,
      sourceType: 'vod',
    );

    var resolved = 0;
    for (final entry in categories.entries) {
      final updated = await customUpdate(
        '''UPDATE vod_items SET category_name = ? 
           WHERE playlist_id = ? AND category_name = ?''',
        variables: [
          Variable.withString(entry.value),
          Variable.withInt(playlistId),
          Variable.withString(entry.key),
        ],
        updates: {},
      );
      resolved += updated;
    }
    return resolved;
  }

  /// Resolves numeric categoryName values in existing series items.
  Future<int> resolveExistingSeries(int playlistId) async {
    final categories = await getAllCategories(
      playlistId: playlistId,
      sourceType: 'series',
    );

    var resolved = 0;
    for (final entry in categories.entries) {
      final updated = await customUpdate(
        '''UPDATE series_items SET category_name = ? 
           WHERE playlist_id = ? AND category_name = ?''',
        variables: [
          Variable.withString(entry.value),
          Variable.withInt(playlistId),
          Variable.withString(entry.key),
        ],
        updates: {},
      );
      resolved += updated;
    }
    return resolved;
  }
}
