import 'package:drift/drift.dart';
import 'package:nebula_iptv/data/database/app_database.dart';
import 'package:nebula_iptv/domain/models/catalog_item.dart';

/// Bounded SQL queries keep large provider catalogues out of the UI isolate.
class CatalogRepository {
  final AppDatabase db;
  CatalogRepository(this.db);
  static const _fields = """
    c.*, COALESCE(NULLIF(t.poster_url, ''), c.logo_url) AS poster,
    t.backdrop_url AS backdrop, t.overview AS overview,
    substr(t.release_date, 1, 4) AS release_year
  """;
  static const _metadata = """
    LEFT JOIN tmdb_cache t ON t.source_id = CAST(c.id AS TEXT)
      AND t.media_type = CASE WHEN c.source_type = 'series' THEN 'tv' ELSE 'movie' END
  """;

  Stream<HomeCatalog> watchHome() => db.customSelect("""
    WITH ranked AS (
      SELECT id, ROW_NUMBER() OVER (
        PARTITION BY COALESCE(group_name, 'Para descobrir')
        ORDER BY updated_at DESC, id DESC) AS rank_in_category
      FROM channels WHERE is_active = 1 AND source_type IN ('vod', 'series')
    )
    SELECT $_fields FROM channels c
    INNER JOIN ranked r ON r.id = c.id
    $_metadata
    WHERE r.rank_in_category <= 16
    ORDER BY c.updated_at DESC, c.id DESC LIMIT 128
  """, readsFrom: {db.channels}).watch().map((rows) {
        final items = rows.map(_item).toList();
        final groups = <String, List<CatalogItem>>{};
        for (final item in items) {
          final name = item.category?.split('|').last.trim();
          groups
              .putIfAbsent(
                  name == null || name.isEmpty ? 'Para descobrir' : name,
                  () => [])
              .add(item);
        }
        final featured = [...items]..sort((a, b) =>
            (b.backdropUrl?.isNotEmpty == true ? 1 : 0)
                .compareTo(a.backdropUrl?.isNotEmpty == true ? 1 : 0));
        return HomeCatalog(
            featured: List.unmodifiable(featured.take(4)),
            shelves: List.unmodifiable([
              CatalogShelf('Adicionados recentemente', items.take(20).toList()),
              ...groups.entries
                  .take(6)
                  .map((e) => CatalogShelf(e.key, e.value)),
            ]));
      });

  Stream<List<CatalogItem>> watchMyList() => db
      .customSelect('''
    SELECT $_fields FROM channels c
    INNER JOIN favorites f ON f.channel_id = c.id $_metadata
    WHERE c.is_active = 1 ORDER BY f.id DESC LIMIT 60
  ''', readsFrom: {db.channels, db.favorites})
      .watch()
      .map((rows) => rows.map(_item).toList());

  Stream<List<CatalogItem>> watchContinueWatching() => db
      .customSelect("""
    SELECT $_fields, h.progress_percent, h.watched_duration_ms, h.total_duration_ms
    FROM channels c INNER JOIN watch_history_entries h ON h.channel_id = c.id
    $_metadata
    WHERE c.is_active = 1 AND c.source_type IN ('vod', 'series')
      AND h.watched_duration_ms > 5000 AND h.progress_percent < 0.95
    ORDER BY h.last_watched_at DESC LIMIT 20
  """, readsFrom: {db.channels, db.watchHistoryEntries})
      .watch()
      .map((rows) => rows.map((row) {
            final progress = (row.readNullable<double>('progress_percent') ?? 0)
                .clamp(0.0, 1.0);
            final total = row.readNullable<int>('total_duration_ms') ?? 0;
            return _item(row,
                progress: progress,
                resumeMs: total > 0
                    ? (total * progress).round()
                    : row.read<int>('watched_duration_ms'));
          }).toList());

  Future<List<CatalogItem>> related(CatalogItem item) async {
    final rows = await db.customSelect("""
      SELECT $_fields FROM channels c $_metadata
      WHERE c.is_active = 1 AND c.id != ? AND c.group_name = ?
        AND c.source_type IN ('vod', 'series')
      ORDER BY c.updated_at DESC, c.id DESC LIMIT 16
    """, variables: [
      Variable.withInt(item.id),
      Variable.withString(item.category ?? '')
    ]).get();
    return rows.map(_item).toList();
  }

  CatalogItem _item(QueryRow row, {double? progress, int resumeMs = 0}) =>
      CatalogItem(
          id: row.read<int>('id'),
          playlistId: row.read<int>('playlist_id'),
          title: row.read<String>('name'),
          streamUrl: row.read<String>('stream_url'),
          kind: switch (row.read<String>('source_type')) {
            'vod' => CatalogKind.movie,
            'series' => CatalogKind.series,
            _ => CatalogKind.live,
          },
          sourceId: row.readNullable<String>('source_id'),
          posterUrl: row.readNullable<String>('poster'),
          backdropUrl: row.readNullable<String>('backdrop'),
          overview: row.readNullable<String>('overview'),
          category: row.readNullable<String>('group_name'),
          year: row.readNullable<String>('release_year'),
          progress: progress,
          resumeMs: resumeMs);
}
