import 'dart:math';
import 'package:drift/drift.dart';
import 'package:nebula_iptv/data/database/app_database.dart';

/// Item in the Sua TV queue.
class SuaTvItem {
  final int channelId;
  final String name;
  final String streamUrl;
  final String? thumbnailUrl;
  final String contentType;
  final String? categoryName;

  const SuaTvItem({
    required this.channelId,
    required this.name,
    required this.streamUrl,
    this.thumbnailUrl,
    required this.contentType,
    this.categoryName,
  });
}

/// Service that generates a personalized "Sua TV" queue.
///
/// Algorithm:
/// - 40% from favorites
/// - 30% from top categories (most watched)
/// - 30% random from same categories
/// Shuffled for variety.
class SuaTvService {
  final AppDatabase _db;
  final int _profileId;
  final _random = Random();

  SuaTvService(this._db, this._profileId);

  Future<List<SuaTvItem>> generateQueue({int size = 25}) async {
    final queue = <SuaTvItem>[];

    // 1. Get favorites
    final favorites = await _getFavorites();
    final favCount = (size * 0.4).round().clamp(0, favorites.length);
    queue.addAll(favorites.take(favCount));

    // 2. Get top categories
    final topCategories = await _getTopCategories();

    // 3. Items from top categories (partially watched or unwatched)
    final categoryItems = await _getFromCategories(topCategories, (size * 0.3).round());
    queue.addAll(categoryItems);

    // 4. Random items from same categories
    final randomItems = await _getRandomFromCategories(topCategories, (size * 0.3).round());
    queue.addAll(randomItems);

    // Deduplicate by channelId
    final seen = <int>{};
    final deduped = <SuaTvItem>[];
    for (final item in queue) {
      if (seen.add(item.channelId)) {
        deduped.add(item);
      }
    }

    // Shuffle for variety
    deduped.shuffle(_random);

    return deduped.take(size).toList();
  }

  Future<List<SuaTvItem>> _getFavorites() async {
    final rows = await _db.customSelect(
      '''SELECT c.id, c.name, c.stream_url, c.logo_url, c.source_type, c.group_name
         FROM favorites f
         JOIN channels c ON f.channel_id = c.id
         WHERE c.is_active = 1 AND c.stream_url IS NOT NULL AND c.stream_url != ''
         ORDER BY RANDOM()
         LIMIT 15''',
    ).get();

    return rows.map((r) => SuaTvItem(
      channelId: r.data['id'] as int,
      name: r.data['name'] as String? ?? '',
      streamUrl: r.data['stream_url'] as String? ?? '',
      thumbnailUrl: r.data['logo_url'] as String?,
      contentType: r.data['source_type'] as String? ?? 'xtream',
      categoryName: r.data['group_name'] as String?,
    )).where((item) => item.streamUrl.isNotEmpty).toList();
  }

  Future<List<String>> _getTopCategories() async {
    final rows = await _db.customSelect(
      '''SELECT c.group_name, SUM(w.total_watch_ms) as total
         FROM watch_stats_daily w
         JOIN channels c ON w.channel_id = c.id
         WHERE w.profile_id = ? AND c.group_name IS NOT NULL AND c.group_name != ''
         GROUP BY c.group_name
         ORDER BY total DESC
         LIMIT 5''',
      variables: [Variable.withInt(_profileId)],
    ).get();

    return rows.map((r) => r.data['group_name'] as String).toList();
  }

  Future<List<SuaTvItem>> _getFromCategories(List<String> categories, int limit) async {
    if (categories.isEmpty) return [];

    final placeholders = categories.map((_) => '?').join(',');
    final vars = [
      ...categories.map((c) => Variable.withString(c)),
    ];

    final rows = await _db.customSelect(
      '''SELECT c.id, c.name, c.stream_url, c.logo_url, c.source_type, c.group_name
         FROM channels c
         WHERE c.group_name IN ($placeholders)
           AND c.is_active = 1
           AND c.stream_url IS NOT NULL AND c.stream_url != ''
         ORDER BY RANDOM()
         LIMIT ?''',
      variables: [...vars, Variable.withInt(limit)],
    ).get();

    return rows.map((r) => SuaTvItem(
      channelId: r.data['id'] as int,
      name: r.data['name'] as String? ?? '',
      streamUrl: r.data['stream_url'] as String? ?? '',
      thumbnailUrl: r.data['logo_url'] as String?,
      contentType: r.data['source_type'] as String? ?? 'xtream',
      categoryName: r.data['group_name'] as String?,
    )).where((item) => item.streamUrl.isNotEmpty).toList();
  }

  Future<List<SuaTvItem>> _getRandomFromCategories(List<String> categories, int limit) async {
    if (categories.isEmpty) {
      // Fallback: random from any active channel with stream
      final rows = await _db.customSelect(
        '''SELECT c.id, c.name, c.stream_url, c.logo_url, c.source_type, c.group_name
           FROM channels c
           WHERE c.is_active = 1
             AND c.stream_url IS NOT NULL AND c.stream_url != ''
             AND c.source_type IN ('vod', 'xtream')
           ORDER BY RANDOM()
           LIMIT ?''',
        variables: [Variable.withInt(limit)],
      ).get();

      return rows.map((r) => SuaTvItem(
        channelId: r.data['id'] as int,
        name: r.data['name'] as String? ?? '',
        streamUrl: r.data['stream_url'] as String? ?? '',
        thumbnailUrl: r.data['logo_url'] as String?,
        contentType: r.data['source_type'] as String? ?? 'xtream',
        categoryName: r.data['group_name'] as String?,
      )).where((item) => item.streamUrl.isNotEmpty).toList();
    }

    return _getFromCategories(categories, limit);
  }
}
