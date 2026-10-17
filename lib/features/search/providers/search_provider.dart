import 'dart:async';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/data/database/database_provider.dart';
import 'package:nebula_iptv/data/repositories/search_repository.dart';
import 'package:nebula_iptv/domain/models/search_result.dart';
import 'package:nebula_iptv/domain/providers/content_providers.dart';
import 'package:nebula_iptv/domain/services/batch_enrichment_service.dart';

export 'package:nebula_iptv/domain/models/search_result.dart';

/// State for the search feature.
class SearchState {
  final String query;
  final SearchResults? results;
  final bool isSearching;
  final String? errorMessage;

  const SearchState({
    this.errorMessage,
    this.query = '',
    this.results,
    this.isSearching = false,
  });

  SearchState copyWith({
    String? query,
    SearchResults? results,
    bool? isSearching,
    String? errorMessage,
  }) {
    return SearchState(
      errorMessage: errorMessage,
      query: query ?? this.query,
      results: results ?? this.results,
      isSearching: isSearching ?? this.isSearching,
    );
  }
}

final searchRepositoryProvider = Provider<SearchRepository>((ref) =>
    SearchRepository(
        ref.watch(databaseProvider), ref.watch(tmdbDataSourceProvider)));
final searchProvider =
    StateNotifierProvider.autoDispose<SearchNotifier, SearchState>(
        (ref) => SearchNotifier(ref.read(searchRepositoryProvider)));

/// Generation tokens reject late responses, including after clearing the query.
class SearchNotifier extends StateNotifier<SearchState> {
  final SearchRepository _repository;
  Timer? _debounce;
  int _generation = 0;
  SearchNotifier(this._repository) : super(const SearchState());
  void updateQuery(String query) {
    final generation = ++_generation;
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      state = const SearchState(results: SearchResults());
      return;
    }
    state = SearchState(query: query, isSearching: true);
    _debounce = Timer(const Duration(milliseconds: 220),
        () => _search(query.trim(), generation));
  }

  bool _current(int generation) => mounted && generation == _generation;
  Future<void> _search(String query, int generation) async {
    try {
      final local = await _repository.searchLocal(query);
      if (!_current(generation)) return;
      state = SearchState(query: query, results: local);
      if (local.totalCount >= 5 || query.length < 3) return;
      final remote = await _repository.searchRemote(query);
      if (!_current(generation) || remote == null) return;
      List<SearchResultItem> merge(
              List<SearchResultItem> a, List<SearchResultItem> b) =>
          {
            ...{for (final item in a) item.id: item},
            ...{for (final item in b) item.id: item}
          }.values.toList();
      state = SearchState(
          query: query,
          results: SearchResults(
              query: query,
              channels: local.channels,
              vod: merge(local.vod, remote.vod),
              series: merge(local.series, remote.series)));
    } catch (_) {
      if (_current(generation)) {
        state = SearchState(
            query: query,
            errorMessage: 'Não foi possível pesquisar. Tente novamente.');
      }
    }
  }

  @override
  void dispose() {
    _generation++;
    _debounce?.cancel();
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
