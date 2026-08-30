import 'dart:async';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/core/result/result.dart';
import 'package:nebula_iptv/data/datasources/tmdb/tmdb_models.dart';
import 'package:nebula_iptv/domain/providers/content_providers.dart';
import 'package:nebula_iptv/domain/services/batch_enrichment_service.dart';
import 'package:nebula_iptv/features/channels/providers/channels_provider.dart';

/// Search result item — unified across channels, VOD, and series.
class SearchResultItem {
  final int id;
  final int playlistId;
  final String name;
  final String? logoUrl;
  final String? streamUrl;
  final String? groupName;
  final String? sourceId;
  final String sourceType; // 'xtream', 'm3u', 'vod', 'series'

  const SearchResultItem({
    required this.id,
    required this.playlistId,
    required this.name,
    this.logoUrl,
    this.streamUrl,
    this.groupName,
    this.sourceId,
    required this.sourceType,
  });

  bool get isLive => sourceType == 'xtream' || sourceType == 'm3u';
  bool get isVod => sourceType == 'vod';
  bool get isSeries => sourceType == 'series';
}

/// Grouped search results.
class SearchResults {
  final List<SearchResultItem> channels;
  final List<SearchResultItem> vod;
  final List<SearchResultItem> series;
  final String query;

  const SearchResults({
    this.channels = const [],
    this.vod = const [],
    this.series = const [],
    this.query = '',
  });

  bool get isEmpty => channels.isEmpty && vod.isEmpty && series.isEmpty;
  int get totalCount => channels.length + vod.length + series.length;
}

/// State for the search feature.
class SearchState {
  final String query;
  final SearchResults? results;
  final bool isSearching;

  const SearchState({
    this.query = '',
    this.results,
    this.isSearching = false,
  });

  SearchState copyWith({
    String? query,
    SearchResults? results,
    bool? isSearching,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isSearching: isSearching ?? this.isSearching,
    );
  }
}

/// Provider for the search notifier.
final searchProvider =
    StateNotifierProvider.autoDispose<SearchNotifier, SearchState>(
  (ref) => SearchNotifier(ref),
);

/// Notifier for global search with debounce.
class SearchNotifier extends StateNotifier<SearchState> {
  final Ref _ref;
  Timer? _debounceTimer;

  SearchNotifier(this._ref) : super(const SearchState());

  /// Updates query with debounce (300ms).
  void updateQuery(String query) {
    state = state.copyWith(query: query);

    _debounceTimer?.cancel();

    if (query.trim().isEmpty) {
      state = state.copyWith(
        results: const SearchResults(),
        isSearching: false,
      );
      return;
    }

    state = state.copyWith(isSearching: true);

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query.trim());
    });
  }

  /// Performs the actual search.
  Future<void> _performSearch(String query) async {
    if (!mounted) return;

    try {
      final db = _ref.read(databaseProvider);
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

      if (!mounted) return;

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

      // If STILL few local results, search TMDB live as last resort
      final totalLocal = channels.length + vod.length + series.length;
      if (totalLocal < 5 && query.length >= 3) {
        final tmdbResults = await _searchViaTmdb(db, query);
        if (tmdbResults != null) {
          final existingVodIds = vod.map((r) => r.id).toSet();
          final existingSeriesIds = series.map((r) => r.id).toSet();
          for (final item in tmdbResults.vod) {
            if (!existingVodIds.contains(item.id)) vod.add(item);
          }
          for (final item in tmdbResults.series) {
            if (!existingSeriesIds.contains(item.id)) series.add(item);
          }
        }
      }

      final results = SearchResults(
        channels: channels,
        vod: vod,
        series: series,
        query: query,
      );

      state = state.copyWith(results: results, isSearching: false);
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isSearching: false);
      }
    }
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
  Future<SearchResults?> _searchViaTmdb(dynamic db, String query) async {
    try {
      final tmdbDs = _ref.read(tmdbDataSourceProvider);

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

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

/// Provider for "Surpreenda-me" (random content).
final surpriseMeProvider = FutureProvider.autoDispose
    .family<SearchResultItem?, String>((ref, contentType) async {
  final db = ref.read(databaseProvider);

  final String whereClause;
  if (contentType == 'vod') {
    whereClause = "source_type = 'vod'";
  } else if (contentType == 'series') {
    whereClause = "source_type = 'series'";
  } else if (contentType == 'live') {
    whereClause = "source_type IN ('xtream', 'm3u')";
  } else {
    whereClause = "source_type IN ('vod', 'series')";
  }

  final rows = await db.customSelect(
    '''
    SELECT id, playlist_id, name, logo_url, stream_url, group_name, source_id, source_type
    FROM channels
    WHERE $whereClause
      AND is_active = 1
      AND id NOT IN (SELECT channel_id FROM watch_history_entries WHERE progress_percent > 0.9)
    ORDER BY RANDOM()
    LIMIT 1
    ''',
  ).get();

  if (rows.isEmpty) return null;

  final row = rows.first;
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
});

/// Provider for discovery recommendations.
final discoveryProvider =
    FutureProvider.autoDispose<List<SearchResultItem>>((ref) async {
  final db = ref.read(databaseProvider);

  // Get categories from most watched content
  final categoryRows = await db.customSelect(
    '''
    SELECT DISTINCT c.group_name
    FROM watch_history_entries h
    INNER JOIN channels c ON c.id = h.channel_id
    WHERE c.group_name IS NOT NULL
      AND c.source_type IN ('vod', 'series')
    ORDER BY h.last_watched_at DESC
    LIMIT 5
    ''',
  ).get();

  if (categoryRows.isEmpty) return [];

  final categories =
      categoryRows.map((r) => r.read<String>('group_name')).toList();

  // Find unwatched content in those categories
  final placeholders = List.filled(categories.length, '?').join(', ');
  final variables = categories.map((c) => Variable.withString(c)).toList();

  final rows = await db.customSelect(
    '''
    SELECT id, playlist_id, name, logo_url, stream_url, group_name, source_id, source_type
    FROM channels
    WHERE group_name IN ($placeholders)
      AND source_type IN ('vod', 'series')
      AND is_active = 1
      AND id NOT IN (SELECT channel_id FROM watch_history_entries)
    ORDER BY RANDOM()
    LIMIT 15
    ''',
    variables: variables,
  ).get();

  return rows.map((row) {
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
  }).toList();
});

/// Provider for the BatchEnrichmentService.
final batchEnrichmentProvider = Provider<BatchEnrichmentService>((ref) {
  final db = ref.read(databaseProvider);
  final tmdbDs = ref.read(tmdbDataSourceProvider);
  return BatchEnrichmentService(
    db: db,
    tmdbDs: tmdbDs,
    aliasesDao: db.searchAliasesDao,
  );
});

/// Enrichment is triggered explicitly: after Xtream imports
/// (playlist_management_provider) or from Configurações > Manutenção.
