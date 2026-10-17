import 'package:drift/drift.dart';
import 'package:nebula_iptv/core/result/result.dart';
import 'package:nebula_iptv/data/database/app_database.dart';
import 'package:nebula_iptv/data/datasources/tmdb/tmdb_datasource.dart';
import 'package:nebula_iptv/data/datasources/tmdb/tmdb_models.dart';
import 'package:nebula_iptv/domain/models/search_result.dart';

class SearchRepository {
  final AppDatabase db;
  final TmdbDataSource tmdbDs;
  SearchRepository(this.db, this.tmdbDs);
  Future<SearchResults> searchLocal(String query) async {
    // Smart search: prioritize word-boundary matches over substring matches
    // Use multiple terms for multi-word queries (AND logic)
    final words = query.toLowerCase().split(RegExp(r'\s+'));

    // Build WHERE clause: each word must appear in the name
    final conditions =
        words.map((_) => 'name LIKE ? COLLATE NOCASE').join(' AND ');
    final variables = words.map((w) => Variable.withString('%$w%')).toList();

    // Search channels (live)
    final channelRows = await db.customSelect(
      '''
        SELECT id, playlist_id, name, logo_url, stream_url, group_name, source_id, source_type
        FROM channels
        WHERE $conditions
          AND source_type IN ('xtream', 'm3u')
          AND is_active = 1
        ORDER BY
          CASE
            WHEN name LIKE ? COLLATE NOCASE THEN 0
            WHEN name LIKE ? COLLATE NOCASE THEN 1
            ELSE 2
          END,
          name ASC
        LIMIT 50
        ''',
      variables: [
        ...variables,
        Variable.withString('$query%'),
        Variable.withString('%$query%')
      ],
    ).get();

    // Search VOD
    final vodRows = await db.customSelect(
      '''
        SELECT id, playlist_id, name, logo_url, stream_url, group_name, source_id, source_type
        FROM channels
        WHERE $conditions
          AND source_type = 'vod'
          AND is_active = 1
        ORDER BY
          CASE
            WHEN name LIKE ? COLLATE NOCASE THEN 0
            WHEN name LIKE ? COLLATE NOCASE THEN 1
            ELSE 2
          END,
          name ASC
        LIMIT 50
        ''',
      variables: [
        ...variables,
        Variable.withString('$query%'),
        Variable.withString('%$query%')
      ],
    ).get();

    // Search Series
    final seriesRows = await db.customSelect(
      '''
        SELECT id, playlist_id, name, logo_url, stream_url, group_name, source_id, source_type
        FROM channels
        WHERE $conditions
          AND source_type = 'series'
          AND is_active = 1
        ORDER BY
          CASE
            WHEN name LIKE ? COLLATE NOCASE THEN 0
            WHEN name LIKE ? COLLATE NOCASE THEN 1
            ELSE 2
          END,
          name ASC
        LIMIT 50
        ''',
      variables: [
        ...variables,
        Variable.withString('$query%'),
        Variable.withString('%$query%')
      ],
    ).get();

    final channels = channelRows.map(_rowToResult).toList();
    final vod = vodRows.map(_rowToResult).toList();
    final series = seriesRows.map(_rowToResult).toList();

    // Search via aliases (covers alternative titles from TMDB enrichment)
    final aliasesDao = db.searchAliasesDao;
    final aliasVodIds =
        await aliasesDao.searchByAlias(term: query, sourceType: 'vod');
    final aliasSeriesIds =
        await aliasesDao.searchByAlias(term: query, sourceType: 'series');

    if (aliasVodIds.isNotEmpty) {
      final existingIds = vod.map((r) => r.id).toSet();
      final newIds = aliasVodIds
          .where((id) => !existingIds.contains(id))
          .take(20)
          .toList();
      if (newIds.isNotEmpty) {
        final placeholders = newIds.map((_) => '?').join(',');
        final aliasRows = await db
            .customSelect(
              'SELECT id, playlist_id, name, logo_url, stream_url, group_name, source_id, source_type '
              'FROM channels WHERE id IN ($placeholders) AND is_active = 1',
              variables: newIds.map((id) => Variable.withInt(id)).toList(),
            )
            .get();
        vod.addAll(aliasRows.map(_rowToResult));
      }
    }

    if (aliasSeriesIds.isNotEmpty) {
      final existingIds = series.map((r) => r.id).toSet();
      final newIds = aliasSeriesIds
          .where((id) => !existingIds.contains(id))
          .take(20)
          .toList();
      if (newIds.isNotEmpty) {
        final placeholders = newIds.map((_) => '?').join(',');
        final aliasRows = await db
            .customSelect(
              'SELECT id, playlist_id, name, logo_url, stream_url, group_name, source_id, source_type '
              'FROM channels WHERE id IN ($placeholders) AND is_active = 1',
              variables: newIds.map((id) => Variable.withInt(id)).toList(),
            )
            .get();
        series.addAll(aliasRows.map(_rowToResult));
      }
    }

    return SearchResults(
        channels: channels, vod: vod, series: series, query: query);
  }

  SearchResultItem _rowToResult(QueryRow row) {
    return SearchResultItem(
      id: row.read<int>('id'),
      playlistId: row.read<int>('playlist_id'),
      name: row.read<String>('name'),
      logoUrl: row.readNullable<String>('logo_url'),
      streamUrl: row.readNullable<String>('stream_url'),
      groupName: row.readNullable<String>('group_name'),
      sourceId: row.readNullable<String>('source_id'),
      sourceType: row.read<String>('source_type'),
    );
  }

  /// Searches TMDB for the query, then cross-references results with local catalog.
  /// Handles cases where local names differ from search terms (e.g., "parks" → "Confusões de Leslie").
  Future<SearchResults?> searchRemote(String query) async {
    try {
      // Search TMDB in pt-BR and en-US to get both localized and original titles
      final movieResult = await tmdbDs.searchMovie(query, language: 'pt-BR');
      final tvResult = await tmdbDs.searchTv(query, language: 'pt-BR');
      final movieResultEn = await tmdbDs.searchMovie(query, language: 'en-US');
      final tvResultEn = await tmdbDs.searchTv(query, language: 'en-US');

      final List<SearchResultItem> foundVod = [];
      final List<SearchResultItem> foundSeries = [];
      final Set<int> seenIds = {};

      // Collect all title variants from both languages
      final movieTitles = <String>{};
      if (movieResult.isSuccess) {
        for (final m
            in (movieResult as Success<List<TmdbSearchResult>>).data.take(5)) {
          movieTitles.add(m.title);
        }
      }
      if (movieResultEn.isSuccess) {
        for (final m in (movieResultEn as Success<List<TmdbSearchResult>>)
            .data
            .take(5)) {
          movieTitles.add(m.title);
        }
      }

      final seriesTitles = <String>{};
      if (tvResult.isSuccess) {
        for (final s
            in (tvResult as Success<List<TmdbSearchResult>>).data.take(5)) {
          seriesTitles.add(s.title);
        }
      }
      if (tvResultEn.isSuccess) {
        for (final s
            in (tvResultEn as Success<List<TmdbSearchResult>>).data.take(5)) {
          seriesTitles.add(s.title);
        }
      }

      // Cross-reference movie titles with local VOD catalog
      for (final title in movieTitles) {
        if (title.isEmpty) continue;
        final searchName = title.length > 20 ? title.substring(0, 20) : title;
        final localRows = await db.customSelect(
          'SELECT id, playlist_id, name, logo_url, stream_url, group_name, source_id, source_type '
          "FROM channels WHERE name LIKE ? COLLATE NOCASE AND source_type = 'vod' AND is_active = 1 LIMIT 3",
          variables: [Variable.withString('%$searchName%')],
        ).get();
        for (final row in localRows) {
          final item = _rowToResult(row);
          if (!seenIds.contains(item.id)) {
            seenIds.add(item.id);
            foundVod.add(item);
          }
        }
      }

      // Cross-reference TV titles with local series catalog
      for (final title in seriesTitles) {
        if (title.isEmpty) continue;
        final searchName = title.length > 20 ? title.substring(0, 20) : title;
        final localRows = await db.customSelect(
          'SELECT id, playlist_id, name, logo_url, stream_url, group_name, source_id, source_type '
          "FROM channels WHERE name LIKE ? COLLATE NOCASE AND source_type = 'series' AND is_active = 1 LIMIT 3",
          variables: [Variable.withString('%$searchName%')],
        ).get();
        for (final row in localRows) {
          final item = _rowToResult(row);
          if (!seenIds.contains(item.id)) {
            seenIds.add(item.id);
            foundSeries.add(item);
          }
        }
      }

      if (foundVod.isEmpty && foundSeries.isEmpty) return null;

      return SearchResults(
        channels: [],
        vod: foundVod,
        series: foundSeries,
        query: query,
      );
    } catch (e) {
      return null;
    }
  }
}
