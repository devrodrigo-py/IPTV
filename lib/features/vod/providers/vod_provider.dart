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

  const VodScreenState({
    this.allMovies = const [],
    this.filteredMovies = const [],
    this.categories = const [],
    this.selectedCategory,
    this.searchQuery = '',
    this.isLoading = true,
    this.failure,
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
    );
  }
}

/// Provider for the VOD screen state.
final vodScreenProvider =
    StateNotifierProvider<VodScreenNotifier, VodScreenState>(
  (ref) => VodScreenNotifier(ref),
);

/// Notifier that manages VOD browsing state with metadata enrichment.
///
/// Uses MetadataEnrichmentService (TMDB + TVMaze → MediaWork) for
/// on-demand enrichment and falls back to the legacy tmdb_cache for
/// items enriched before the MediaWork migration.
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

      // Query channels with sourceType vod
      final channels = await db.channelsDao.getAllActiveChannels();
      final vodChannels = channels
          .where((c) => c.sourceType == ChannelSourceType.vod)
          .map((c) {
        final cached = _legacyCache?[c.id.toString()];
        var item = VodItem(
          id: c.id,
          playlistId: c.playlistId,
          name: c.name,
          streamUrl: c.streamUrl,
          logoUrl: c.logoUrl,
          categoryName: c.groupName,
        );

        // Apply cached TMDB data if available (legacy cache)
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
        return item;
      }).toList();

      final categories = vodChannels
          .map((v) => v.categoryName)
          .where((c) => c != null && c.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList()
        ..sort();

      state = state.copyWith(
        allMovies: vodChannels,
        filteredMovies: vodChannels,
        categories: categories,
        isLoading: false,
        clearFailure: true,
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

  /// Enriches a single movie with metadata (called on-demand).
  ///
  /// Uses the new MetadataEnrichmentService which:
  /// 1. Normalizes the movie name
  /// 2. Checks for existing MediaWork match
  /// 3. Queries TMDB (primary) or TVMaze (fallback)
  /// 4. Persists result in MediaWork table + ContentAlias
  Future<VodItem?> enrichMovie(VodItem movie) async {
    if (movie.isEnriched) return movie;

    try {
      final enrichmentService = _ref.read(metadataEnrichmentServiceProvider);
      final mediaWork = await enrichmentService.enrichMovie(movie.name);
      if (mediaWork == null) return null;

      // Build enriched item from MediaWork data
      // (MediaWorkEntry in ContentMatchingService is lightweight;
      //  we need to read the full row for metadata fields)
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
      // Enrichment failure should never block the UI
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
