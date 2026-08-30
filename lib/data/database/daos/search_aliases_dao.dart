import 'package:drift/drift.dart';
import 'package:nebula_iptv/data/database/app_database.dart';

/// DAO for search_aliases — direct channel_id → alternative title mapping.
///
/// No codegen. Used by the batch enrichment service and fuzzy search.
class SearchAliasesDao extends DatabaseAccessor<AppDatabase> {
  SearchAliasesDao(super.db);

  /// Inserts an alias for a channel. Ignores duplicates (UNIQUE constraint).
  Future<void> insertAlias({
    required int channelId,
    required String alias,
    required String normalizedAlias,
    String source = 'tmdb',
  }) async {
    await customStatement(
      'INSERT OR IGNORE INTO search_aliases (channel_id, alias, normalized_alias, source) VALUES (?, ?, ?, ?)',
      [channelId, alias, normalizedAlias, source],
    );
  }

  /// Inserts multiple aliases for a channel in a batch.
  Future<void> insertAliases({
    required int channelId,
    required List<String> aliases,
    String source = 'tmdb',
  }) async {
    for (final alias in aliases) {
      final normalized = _normalize(alias);
      if (normalized.length < 2) continue;
      await customStatement(
        'INSERT OR IGNORE INTO search_aliases (channel_id, alias, normalized_alias, source) VALUES (?, ?, ?, ?)',
        [channelId, alias, normalized, source],
      );
    }
  }

  /// Searches aliases by term. Returns matching channel IDs for a given source_type.
  Future<List<int>> searchByAlias({
    required String term,
    required String sourceType,
  }) async {
    final normalized = '%${_normalize(term)}%';
    final rows = await customSelect(
      '''
      SELECT DISTINCT sa.channel_id
      FROM search_aliases sa
      INNER JOIN channels c ON c.id = sa.channel_id
      WHERE sa.normalized_alias LIKE ? COLLATE NOCASE
        AND c.source_type = ?
        AND c.is_active = 1
      LIMIT 50
      ''',
      variables: [
        Variable.withString(normalized),
        Variable.withString(sourceType)
      ],
    ).get();
    return rows.map((r) => r.read<int>('channel_id')).toList();
  }

  /// Returns the set of channel IDs that already have aliases (already enriched).
  Future<Set<int>> getEnrichedChannelIds() async {
    final rows = await customSelect(
      'SELECT DISTINCT channel_id FROM search_aliases',
    ).get();
    return rows.map((r) => r.read<int>('channel_id')).toSet();
  }

  /// Gets count of enriched channels.
  Future<int> getEnrichedCount() async {
    final rows = await customSelect(
      'SELECT COUNT(DISTINCT channel_id) as cnt FROM search_aliases',
    ).get();
    return rows.first.read<int>('cnt');
  }

  /// Deletes all aliases for a channel.
  Future<void> deleteForChannel(int channelId) async {
    await customStatement(
      'DELETE FROM search_aliases WHERE channel_id = ?',
      [channelId],
    );
  }

  /// Normalizes a string for alias matching: lowercase, remove accents, trim.
  static String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[àáâãäå]'), 'a')
        .replaceAll(RegExp(r'[èéêë]'), 'e')
        .replaceAll(RegExp(r'[ìíîï]'), 'i')
        .replaceAll(RegExp(r'[òóôõö]'), 'o')
        .replaceAll(RegExp(r'[ùúûü]'), 'u')
        .replaceAll(RegExp(r'[ýÿ]'), 'y')
        .replaceAll(RegExp(r'[ñ]'), 'n')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Public normalize for external use.
  static String normalize(String input) => _normalize(input);
}
