import 'package:drift/drift.dart';
import 'package:nebula_iptv/core/logging/app_logger.dart';
import 'package:nebula_iptv/core/utils/string_similarity.dart';
import 'package:nebula_iptv/data/database/app_database.dart';
import 'package:nebula_iptv/domain/services/channel_dedup_service.dart';
import 'package:nebula_iptv/domain/services/content_matching_service.dart';

/// A group of duplicate content items.
class ContentDuplicateGroup {
  final String normalizedName;
  final List<DuplicateItem> items;
  final double confidence;

  const ContentDuplicateGroup({
    required this.normalizedName,
    required this.items,
    this.confidence = 1.0,
  });

  @override
  String toString() =>
      'DuplicateGroup("$normalizedName", ${items.length} items, '
      'confidence: ${confidence.toStringAsFixed(2)})';
}

/// A single item within a duplicate group.
class DuplicateItem {
  final int id;
  final String originalName;
  final String? qualityTag;
  final bool isPrimary;

  const DuplicateItem({
    required this.id,
    required this.originalName,
    this.qualityTag,
    this.isPrimary = false,
  });
}

/// Result of a content deduplication scan.
class ContentDeduplicationResult {
  final int totalItems;
  final int duplicateGroups;
  final int duplicateItems;
  final Duration elapsed;

  const ContentDeduplicationResult({
    this.totalItems = 0,
    this.duplicateGroups = 0,
    this.duplicateItems = 0,
    this.elapsed = Duration.zero,
  });

  @override
  String toString() =>
      'ContentDeduplicationResult(items: $totalItems, groups: $duplicateGroups, '
      'duplicates: $duplicateItems, elapsed: ${elapsed.inMilliseconds}ms)';
}

/// Service for detecting duplicate movies and series in the VOD library.
///
/// Uses the ContentMatchingService normalize() for initial grouping,
/// then Jaro-Winkler similarity for close-but-not-identical names.
class ContentDeduplicationService {
  final AppDatabase _db;
  final ContentMatchingService _matchingService;

  ContentDeduplicationService({
    required AppDatabase db,
    required ContentMatchingService matchingService,
  })  : _db = db,
        _matchingService = matchingService;

  /// Detects duplicate movies in the VOD library.
  ///
  /// Groups items with same normalized name (e.g. "#SalveRosa" variants)
  /// and items that match with high Jaro-Winkler score (>= 0.90).
  Future<List<ContentDuplicateGroup>> detectDuplicateMovies({
    int? playlistId,
  }) async {
    return _detectDuplicates(
      tableName: 'channels',
      sourceTypeFilter: 'vod',
      playlistId: playlistId,
    );
  }

  /// Detects duplicate series.
  Future<List<ContentDuplicateGroup>> detectDuplicateSeries({
    int? playlistId,
  }) async {
    return _detectDuplicates(
      tableName: 'channels',
      sourceTypeFilter: 'series',
      playlistId: playlistId,
    );
  }

  /// Full scan returning both result stats and groups.
  Future<(ContentDeduplicationResult, List<ContentDuplicateGroup>)>
      fullScan({int? playlistId, String sourceType = 'vod'}) async {
    final stopwatch = Stopwatch()..start();

    final groups = await _detectDuplicates(
      tableName: 'channels',
      sourceTypeFilter: sourceType,
      playlistId: playlistId,
    );

    stopwatch.stop();
    final totalDuplicateItems =
        groups.fold<int>(0, (sum, g) => sum + g.items.length);

    final result = ContentDeduplicationResult(
      duplicateGroups: groups.length,
      duplicateItems: totalDuplicateItems,
      elapsed: stopwatch.elapsed,
    );

    return (result, groups);
  }

  /// Internal method to detect duplicates in any source type.
  Future<List<ContentDuplicateGroup>> _detectDuplicates({
    required String tableName,
    required String sourceTypeFilter,
    int? playlistId,
  }) async {
    final items = await _loadItems(
      tableName: tableName,
      sourceTypeFilter: sourceTypeFilter,
      playlistId: playlistId,
    );

    if (items.isEmpty) return [];

    appLogger.d(
      '[ContentDedup] Scanning ${items.length} $sourceTypeFilter items...',
    );

    // Phase 1: Group by normalized name (exact match after normalization)
    final groups = <String, List<_ContentItem>>{};
    for (final item in items) {
      final normalized = _matchingService.normalize(item.name);
      if (normalized.isEmpty) continue;
      groups.putIfAbsent(normalized, () => []).add(item);
    }

    // Phase 2: Merge groups with very similar normalized names (>= 0.92)
    final mergedGroups = _mergeSimilarGroups(groups);

    // Phase 3: Convert to result format (only groups with 2+ items)
    final duplicateGroups = <ContentDuplicateGroup>[];
    for (final entry in mergedGroups.entries) {
      if (entry.value.length < 2) continue;

      final items = entry.value.map((item) {
        final tag = ChannelDeduplicationService.extractQualityTag(item.name);
        return DuplicateItem(
          id: item.id,
          originalName: item.name,
          qualityTag: tag,
          isPrimary: false,
        );
      }).toList();

      // Mark the highest quality as primary
      final bestIdx = _findBestQualityIndex(items);
      final updatedItems = [
        for (var i = 0; i < items.length; i++)
          if (i == bestIdx)
            DuplicateItem(
              id: items[i].id,
              originalName: items[i].originalName,
              qualityTag: items[i].qualityTag,
              isPrimary: true,
            )
          else
            items[i],
      ];

      duplicateGroups.add(ContentDuplicateGroup(
        normalizedName: entry.key,
        items: updatedItems,
        confidence: 1.0,
      ));
    }

    appLogger.i(
      '[ContentDedup] Found ${duplicateGroups.length} duplicate groups '
      'in $sourceTypeFilter',
    );

    return duplicateGroups;
  }

  /// Merges groups with very similar normalized names.
  ///
  /// E.g. "salverosa" and "salve rosa" should be the same group.
  Map<String, List<_ContentItem>> _mergeSimilarGroups(
    Map<String, List<_ContentItem>> groups,
  ) {
    final keys = groups.keys.toList();
    final merged = <String, List<_ContentItem>>{};
    final consumed = <int>{};

    for (var i = 0; i < keys.length; i++) {
      if (consumed.contains(i)) continue;

      final key = keys[i];
      final items = List<_ContentItem>.from(groups[key]!);

      // Try to merge with subsequent groups
      for (var j = i + 1; j < keys.length; j++) {
        if (consumed.contains(j)) continue;

        final otherKey = keys[j];
        final similarity = StringSimilarity.jaroWinkler(key, otherKey);

        if (similarity >= 0.92) {
          items.addAll(groups[otherKey]!);
          consumed.add(j);
        }
      }

      merged[key] = items;
    }

    return merged;
  }

  /// Finds the index of the best quality item.
  int _findBestQualityIndex(List<DuplicateItem> items) {
    var bestIdx = 0;
    var bestPriority = -1;

    for (var i = 0; i < items.length; i++) {
      final priority =
          ChannelDeduplicationService.qualityPriority(items[i].qualityTag);
      if (priority > bestPriority) {
        bestPriority = priority;
        bestIdx = i;
      }
    }

    return bestIdx;
  }

  /// Loads items from the database.
  Future<List<_ContentItem>> _loadItems({
    required String tableName,
    required String sourceTypeFilter,
    int? playlistId,
  }) async {
    var query =
        'SELECT id, name FROM $tableName WHERE is_active = 1 AND source_type = ?';
    final variables = <Variable>[Variable.withString(sourceTypeFilter)];

    if (playlistId != null) {
      query += ' AND playlist_id = ?';
      variables.add(Variable.withInt(playlistId));
    }

    final results =
        await _db.customSelect(query, variables: variables).get();
    return results
        .map((row) => _ContentItem(
              id: row.read<int>('id'),
              name: row.read<String>('name'),
            ))
        .toList();
  }
}

/// Internal model.
class _ContentItem {
  final int id;
  final String name;

  const _ContentItem({required this.id, required this.name});
}
