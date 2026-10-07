import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/core/errors/app_failure.dart';
import 'package:nebula_iptv/data/database/daos/tmdb_cache_dao.dart';
import 'package:nebula_iptv/data/database/tables/channels_table.dart';
import 'package:nebula_iptv/domain/providers/content_providers.dart';
import 'package:nebula_iptv/features/channels/providers/channels_provider.dart';

/// Model for a VOD (movie) item with optional metadata enrichment.
class VodItem {
  final int id;
  final int playlistId;
  final String name;
  final String streamUrl;
  final String? logoUrl;
  final String? categoryName;
  final String? plot;
  final String? cast;
  final String? director;
  final String? rating;
  final String? duration;
  final String? containerExtension;
  final DateTime? addedAt;

  // Enriched fields (from TMDB/TVMaze via MediaWork)
  final String? tmdbPosterUrl;
  final String? tmdbBackdropUrl;
  final String? tmdbOverview;
  final String? tmdbGenres;
  final String? tmdbCast;
  final String? tmdbDirector;
  final double? tmdbRating;
  final String? tmdbReleaseDate;
  final int? tmdbRuntime;
  final int? tmdbId;
  final int? mediaWorkId;
  final bool isEnriched;

  const VodItem({
    required this.id,
    required this.playlistId,
    required this.name,
    required this.streamUrl,
    this.logoUrl,
    this.categoryName,
    this.plot,
    this.cast,
    this.director,
    this.rating,
    this.duration,
    this.containerExtension,
    this.addedAt,
    this.tmdbPosterUrl,
    this.tmdbBackdropUrl,
    this.tmdbOverview,
    this.tmdbGenres,
    this.tmdbCast,
    this.tmdbDirector,
    this.tmdbRating,
    this.tmdbReleaseDate,
    this.tmdbRuntime,
    this.tmdbId,
    this.mediaWorkId,
    this.isEnriched = false,
  });

  /// Returns the best available poster URL.
  String? get displayPosterUrl => tmdbPosterUrl ?? logoUrl;

  /// Returns the best available overview.
  String? get displayOverview => tmdbOverview ?? plot;

  /// Returns the best available rating.
  String? get displayRating =>
      tmdbRating != null ? tmdbRating!.toStringAsFixed(1) : rating;

  /// Extracts the short category name (after "Filmes | " prefix).
  String get shortCategory {
    if (categoryName == null) return 'Outros';
    final parts = categoryName!.split('|');
    return parts.length > 1 ? parts.last.trim() : categoryName!.trim();
  }

  VodItem copyWithEnrichment({
    String? tmdbPosterUrl,
    String? tmdbBackdropUrl,
    String? tmdbOverview,
    String? tmdbGenres,
    String? tmdbCast,
    String? tmdbDirector,
    double? tmdbRating,
    String? tmdbReleaseDate,
    int? tmdbRuntime,
    int? tmdbId,
    int? mediaWorkId,
  }) {
    return VodItem(
      id: id,
      playlistId: playlistId,
      name: name,
      streamUrl: streamUrl,
      logoUrl: logoUrl,
      categoryName: categoryName,
      plot: plot,
      cast: cast,
      director: director,
      rating: rating,
      duration: duration,
      containerExtension: containerExtension,
      addedAt: addedAt,
      tmdbPosterUrl: tmdbPosterUrl ?? this.tmdbPosterUrl,
      tmdbBackdropUrl: tmdbBackdropUrl ?? this.tmdbBackdropUrl,
      tmdbOverview: tmdbOverview ?? this.tmdbOverview,
      tmdbGenres: tmdbGenres ?? this.tmdbGenres,
      tmdbCast: tmdbCast ?? this.tmdbCast,
      tmdbDirector: tmdbDirector ?? this.tmdbDirector,
      tmdbRating: tmdbRating ?? this.tmdbRating,
      tmdbReleaseDate: tmdbReleaseDate ?? this.tmdbReleaseDate,
      tmdbRuntime: tmdbRuntime ?? this.tmdbRuntime,
      tmdbId: tmdbId ?? this.tmdbId,
      mediaWorkId: mediaWorkId ?? this.mediaWorkId,
      isEnriched: true,
    );
  }

  /// Backwards-compatible alias for copyWithEnrichment.
  VodItem copyWithTmdb({
    String? tmdbPosterUrl,
    String? tmdbBackdropUrl,
    String? tmdbOverview,
    String? tmdbGenres,
    String? tmdbCast,
    String? tmdbDirector,
    double? tmdbRating,
    String? tmdbReleaseDate,
    int? tmdbRuntime,
    int? tmdbId,
  }) {
    return copyWithEnrichment(
      tmdbPosterUrl: tmdbPosterUrl,
      tmdbBackdropUrl: tmdbBackdropUrl,
      tmdbOverview: tmdbOverview,
      tmdbGenres: tmdbGenres,
      tmdbCast: tmdbCast,
      tmdbDirector: tmdbDirector,
      tmdbRating: tmdbRating,
      tmdbReleaseDate: tmdbReleaseDate,
      tmdbRuntime: tmdbRuntime,
      tmdbId: tmdbId,
    );
  }
}

/// State for the VOD screen.
class VodScreenState {
  final List<VodItem> allMovies;
  final List<VodItem> filteredMovies;
  final List<String> categories;
  final String? selectedCategory;
  final String searchQuery;
  final bool isLoading;
  final AppFailure? failure;

  /// Categorized movies for Netflix-style rows.
  final Map<String, List<VodItem>> categorizedMovies;

  /// Hero banner items (movies with posters).
  final List<VodItem> heroItems;

  const VodScreenState({
    this.allMovies = const [],
    this.filteredMovies = const [],
    this.categories = const [],
    this.selectedCategory,
    this.searchQuery = '',
    this.isLoading = true,
    this.failure,
    this.categorizedMovies = const {},
    this.heroItems = const [],
  });

  VodScreenState copyWith({
    List<VodItem>? allMovies,
    List<VodItem>? filteredMovies,
    List<String>? categories,
    String? selectedCategory,
    bool clearSelectedCategory = false,
    String? searchQuery,
    bool? isLoading,
    AppFailure? failure,
    bool clearFailure = false,
    Map<String, List<VodItem>>? categorizedMovies,
    List<VodItem>? heroItems,
  }) {
    return VodScreenState(
      allMovies: allMovies ?? this.allMovies,
      filteredMovies: filteredMovies ?? this.filteredMovies,
      categories: categories ?? this.categories,
      selectedCategory: clearSelectedCategory
          ? null
          : (selectedCategory ?? this.selectedCategory),
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      failure: clearFailure ? null : (failure ?? this.failure),
      categorizedMovies: categorizedMovies ?? this.categorizedMovies,
      heroItems: heroItems ?? this.heroItems,
    );
  }
}

/// Provider for the VOD screen state.
final vodScreenProvider =
    StateNotifierProvider<VodScreenNotifier, VodScreenState>(
  (ref) => VodScreenNotifier(ref),
);

/// Notifier that manages VOD browsing state with metadata enrichment.
class VodScreenNotifier extends StateNotifier<VodScreenState> {
  final Ref _ref;
  Timer? _debounce;
  Map<String, TmdbCacheEntry>? _legacyCache;

  VodScreenNotifier(this._ref) : super(const VodScreenState()) {
    _loadMovies();
  }

  /// Loads all VOD movies from database and applies cached metadata.
  Future<void> _loadMovies() async {
    try {
      final db = _ref.read(databaseProvider);

      // Ensure tables exist
      await db.tmdbCacheDao.ensureTable();
      await db.mediaWorkDao.ensureTables();

      // Load legacy TMDB cache for backwards compatibility
      _legacyCache = await db.tmdbCacheDao.getAllCachedByType('movie');

      final allMoviesList = <VodItem>[];

      // 1. Load from vodItems table (Xtream VOD import)
      final dbVod = await db.vodDao.getAllActiveVod();
      for (final v in dbVod) {
        final cached = _legacyCache?[v.id.toString()];
        var item = VodItem(
          id: v.id,
          playlistId: v.playlistId,
          name: v.name,
          streamUrl: v.streamUrl,
          logoUrl: v.logoUrl,
          categoryName: v.categoryName,
          plot: v.plot,
          cast: v.cast,
          director: v.director,
          rating: v.rating?.toString(),
          duration: v.duration?.toString(),
          containerExtension: v.containerExtension,
        );

        if (cached != null) {
          item = item.copyWithEnrichment(
            tmdbPosterUrl: cached.posterUrl,
            tmdbBackdropUrl: cached.backdropUrl,
            tmdbOverview: cached.overview,
            tmdbGenres: cached.genres,
            tmdbCast: cached.castNames,
            tmdbDirector: cached.director,
            tmdbRating: cached.voteAverage,
            tmdbReleaseDate: cached.releaseDate,
            tmdbRuntime: cached.runtime,
            tmdbId: cached.tmdbId,
          );
        }
        allMoviesList.add(item);
      }

      // 2. Also load from channels table (M3U imports with sourceType vod)
      final channels = await db.channelsDao.getAllActiveChannels();
      final vodChannels =
          channels.where((c) => c.sourceType == ChannelSourceType.vod).toList();

      final existingSourceIds =
          allMoviesList.map((v) => v.id.toString()).toSet();

      for (final c in vodChannels) {
        if (c.sourceId != null && existingSourceIds.contains(c.sourceId)) {
          continue;
        }
        final cached = _legacyCache?[c.id.toString()];
        var item = VodItem(
          id: c.id,
          playlistId: c.playlistId,
          name: c.name,
          streamUrl: c.streamUrl,
          logoUrl: c.logoUrl,
          categoryName: c.groupName,
        );

        if (cached != null) {
          item = item.copyWithEnrichment(
            tmdbPosterUrl: cached.posterUrl,
            tmdbBackdropUrl: cached.backdropUrl,
            tmdbOverview: cached.overview,
            tmdbGenres: cached.genres,
            tmdbCast: cached.castNames,
            tmdbDirector: cached.director,
            tmdbRating: cached.voteAverage,
            tmdbReleaseDate: cached.releaseDate,
            tmdbRuntime: cached.runtime,
            tmdbId: cached.tmdbId,
          );
        }
        allMoviesList.add(item);
      }

      // Build categories
      final categories = allMoviesList
          .map((v) => v.categoryName)
          .where((c) => c != null && c.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList()
        ..sort();

      // Build categorized map for Netflix rows
      final categorizedMovies = <String, List<VodItem>>{};
      for (final movie in allMoviesList) {
        final cat = movie.shortCategory;
        categorizedMovies.putIfAbsent(cat, () => []).add(movie);
      }
      for (final movies in categorizedMovies.values) {
        _sortForDiscovery(movies);
      }
      _sortForDiscovery(allMoviesList);

      // Pick hero items: movies with poster images, prefer enriched ones
      final moviesWithPoster = allMoviesList
          .where((m) =>
              m.displayPosterUrl != null && m.displayPosterUrl!.isNotEmpty)
          .toList();
      List<VodItem> heroItems;
      if (moviesWithPoster.length >= 5) {
        moviesWithPoster.shuffle();
        heroItems = moviesWithPoster.take(5).toList();
      } else if (moviesWithPoster.isNotEmpty) {
        heroItems = moviesWithPoster.take(5).toList();
      } else {
        // Fallback: pick first 5 movies
        heroItems = allMoviesList.take(5).toList();
      }

      state = state.copyWith(
        allMovies: allMoviesList,
        filteredMovies: allMoviesList,
        categories: categories,
        isLoading: false,
        clearFailure: true,
        categorizedMovies: categorizedMovies,
        heroItems: heroItems,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        failure: DatabaseFailure(
          message: 'Erro ao carregar filmes.',
          originalError: e,
        ),
      );
    }
  }

  /// Prefer catalog quality and freshness over the alphabetical import order.
  void _sortForDiscovery(List<VodItem> movies) {
    double score(VodItem movie) =>
        movie.tmdbRating ?? double.tryParse(movie.rating ?? '') ?? 0;
    movies.sort((a, b) {
      final scoreOrder = score(b).compareTo(score(a));
      if (scoreOrder != 0) return scoreOrder;
      final enrichedOrder =
          (b.isEnriched ? 1 : 0).compareTo(a.isEnriched ? 1 : 0);
      if (enrichedOrder != 0) return enrichedOrder;
      final recentOrder = (b.addedAt?.millisecondsSinceEpoch ?? b.id)
          .compareTo(a.addedAt?.millisecondsSinceEpoch ?? a.id);
      if (recentOrder != 0) return recentOrder;
      return a.name.compareTo(b.name);
    });
  }

  /// Enriches a single movie with metadata (called on-demand).
  Future<VodItem?> enrichMovie(VodItem movie) async {
    if (movie.isEnriched) return movie;

    try {
      final enrichmentService = _ref.read(metadataEnrichmentServiceProvider);
      final mediaWork = await enrichmentService.enrichMovie(movie.name);
      if (mediaWork == null) return null;

      final fullRow = await _getMediaWorkMetadata(mediaWork.id);

      final enriched = movie.copyWithEnrichment(
        tmdbPosterUrl: fullRow?['poster_url_cache'] as String?,
        tmdbBackdropUrl: fullRow?['banner_url_cache'] as String?,
        tmdbOverview: fullRow?['overview_cache'] as String?,
        tmdbGenres: fullRow?['genre_cache'] as String?,
        tmdbCast: fullRow?['cast_cache'] as String?,
        tmdbRating: fullRow?['vote_average'] as double?,
        tmdbId: fullRow?['external_id'] as int?,
        mediaWorkId: mediaWork.id,
      );

      // Update in state
      if (mounted) {
        final updatedAll = state.allMovies.map((m) {
          return m.id == movie.id ? enriched : m;
        }).toList();
        final updatedFiltered = state.filteredMovies.map((m) {
          return m.id == movie.id ? enriched : m;
        }).toList();
        state = state.copyWith(
          allMovies: updatedAll,
          filteredMovies: updatedFiltered,
        );
      }

      return enriched;
    } catch (e) {
      return null;
    }
  }

  /// Reads full metadata from media_works table.
  Future<Map<String, dynamic>?> _getMediaWorkMetadata(int id) async {
    final db = _ref.read(databaseProvider);
    final results = await db.customSelect(
      'SELECT * FROM media_works WHERE id = ?',
      variables: [Variable.withInt(id)],
    ).get();

    if (results.isEmpty) return null;
    return results.first.data;
  }

  /// Searches movies with debounce.
  void search(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      state = state.copyWith(searchQuery: query);
      _applyFilters();
    });
  }

  /// Filters by category. Pass null to clear filter.
  void filterByCategory(String? category) {
    if (category == state.selectedCategory) {
      state = state.copyWith(clearSelectedCategory: true);
    } else {
      state = state.copyWith(selectedCategory: category);
    }
    _applyFilters();
  }

  /// Refreshes movies from the database.
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearFailure: true);
    await _loadMovies();
  }

  /// Applies search and category filters.
  void _applyFilters() {
    var filtered = state.allMovies;

    if (state.selectedCategory != null) {
      filtered = filtered
          .where((m) => m.categoryName == state.selectedCategory)
          .toList();
    }

    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      filtered = filtered.where((m) {
        return m.name.toLowerCase().contains(query) ||
            (m.categoryName?.toLowerCase().contains(query) ?? false) ||
            (m.tmdbDirector?.toLowerCase().contains(query) ?? false) ||
            (m.tmdbCast?.toLowerCase().contains(query) ?? false) ||
            (m.tmdbGenres?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    state = state.copyWith(filteredMovies: filtered);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
