import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/core/errors/app_failure.dart';
import 'package:nebula_iptv/data/database/daos/tmdb_cache_dao.dart';
import 'package:nebula_iptv/data/database/tables/channels_table.dart';
import 'package:nebula_iptv/data/datasources/tmdb/tmdb_datasource.dart';
import 'package:nebula_iptv/core/network/dio_client.dart';
import 'package:nebula_iptv/data/datasources/xtream/xtream_datasource.dart';
import 'package:nebula_iptv/domain/providers/content_providers.dart';
import 'package:nebula_iptv/features/channels/providers/channels_provider.dart';

/// Model for a Series item with optional metadata enrichment.
class SeriesItem {
  final int id;
  final int playlistId;
  final String name;
  final String? coverUrl;
  final String? categoryName;
  final String? plot;
  final String? cast;
  final String? director;
  final String? genre;
  final String? rating;
  final String? sourceId;

  // Enriched fields (from TMDB/TVMaze via MediaWork)
  final String? tmdbPosterUrl;
  final String? tmdbBackdropUrl;
  final String? tmdbOverview;
  final String? tmdbGenres;
  final String? tmdbCast;
  final double? tmdbRating;
  final String? tmdbReleaseDate;
  final int? tmdbId;
  final int? tmdbNumberOfSeasons;
  final String? tmdbSeasonsJson;
  final int? mediaWorkId;
  final bool isEnriched;

  const SeriesItem({
    required this.id,
    required this.playlistId,
    required this.name,
    this.coverUrl,
    this.categoryName,
    this.plot,
    this.cast,
    this.director,
    this.genre,
    this.rating,
    this.sourceId,
    this.tmdbPosterUrl,
    this.tmdbBackdropUrl,
    this.tmdbOverview,
    this.tmdbGenres,
    this.tmdbCast,
    this.tmdbRating,
    this.tmdbReleaseDate,
    this.tmdbId,
    this.tmdbNumberOfSeasons,
    this.tmdbSeasonsJson,
    this.mediaWorkId,
    this.isEnriched = false,
  });

  /// Returns the best available poster URL.
  String? get displayPosterUrl => tmdbPosterUrl ?? coverUrl;

  /// Returns the best available overview.
  String? get displayOverview => tmdbOverview ?? plot;

  /// Extracts the short category name (after "Series | " prefix).
  String get shortCategory {
    if (categoryName == null) return 'Outros';
    final parts = categoryName!.split('|');
    return parts.length > 1 ? parts.last.trim() : categoryName!.trim();
  }

  SeriesItem copyWithTmdb({
    String? tmdbPosterUrl,
    String? tmdbBackdropUrl,
    String? tmdbOverview,
    String? tmdbGenres,
    String? tmdbCast,
    double? tmdbRating,
    String? tmdbReleaseDate,
    int? tmdbId,
    int? tmdbNumberOfSeasons,
    String? tmdbSeasonsJson,
    int? mediaWorkId,
  }) {
    return SeriesItem(
      id: id,
      playlistId: playlistId,
      name: name,
      coverUrl: coverUrl,
      categoryName: categoryName,
      plot: plot,
      cast: cast,
      director: director,
      genre: genre,
      rating: rating,
      sourceId: sourceId,
      tmdbPosterUrl: tmdbPosterUrl ?? this.tmdbPosterUrl,
      tmdbBackdropUrl: tmdbBackdropUrl ?? this.tmdbBackdropUrl,
      tmdbOverview: tmdbOverview ?? this.tmdbOverview,
      tmdbGenres: tmdbGenres ?? this.tmdbGenres,
      tmdbCast: tmdbCast ?? this.tmdbCast,
      tmdbRating: tmdbRating ?? this.tmdbRating,
      tmdbReleaseDate: tmdbReleaseDate ?? this.tmdbReleaseDate,
      tmdbId: tmdbId ?? this.tmdbId,
      tmdbNumberOfSeasons: tmdbNumberOfSeasons ?? this.tmdbNumberOfSeasons,
      tmdbSeasonsJson: tmdbSeasonsJson ?? this.tmdbSeasonsJson,
      mediaWorkId: mediaWorkId ?? this.mediaWorkId,
      isEnriched: true,
    );
  }
}

/// Model for a Season.
class SeasonItem {
  final int id;
  final int seriesId;
  final int seasonNumber;
  final String? name;
  final String? coverUrl;
  final int episodeCount;
  final List<EpisodeItem> episodes;

  const SeasonItem({
    required this.id,
    required this.seriesId,
    required this.seasonNumber,
    this.name,
    this.coverUrl,
    this.episodeCount = 0,
    this.episodes = const [],
  });
}

/// Model for an Episode.
class EpisodeItem {
  final int id;
  final int seasonId;
  final int seriesId;
  final int episodeNumber;
  final String title;
  final String streamUrl;
  final String? containerExtension;
  final String? plot;
  final String? duration;
  final String? coverUrl;
  final double watchProgress; // 0.0 to 1.0
  final int watchedDurationMs; // position in ms for seek
  final int totalDurationMs; // total duration in ms

  const EpisodeItem({
    required this.id,
    required this.seasonId,
    required this.seriesId,
    required this.episodeNumber,
    required this.title,
    required this.streamUrl,
    this.containerExtension,
    this.plot,
    this.duration,
    this.coverUrl,
    this.watchProgress = 0.0,
    this.watchedDurationMs = 0,
    this.totalDurationMs = 0,
  });

  EpisodeItem copyWith({double? watchProgress, int? watchedDurationMs, int? totalDurationMs}) {
    return EpisodeItem(
      id: id,
      seasonId: seasonId,
      seriesId: seriesId,
      episodeNumber: episodeNumber,
      title: title,
      streamUrl: streamUrl,
      containerExtension: containerExtension,
      plot: plot,
      duration: duration,
      coverUrl: coverUrl,
      watchProgress: watchProgress ?? this.watchProgress,
      watchedDurationMs: watchedDurationMs ?? this.watchedDurationMs,
      totalDurationMs: totalDurationMs ?? this.totalDurationMs,
    );
  }
}

/// State for the Series list screen.
class SeriesScreenState {
  final List<SeriesItem> allSeries;
  final List<SeriesItem> filteredSeries;
  final List<String> categories;
  final String? selectedCategory;
  final String searchQuery;
  final bool isLoading;
  final AppFailure? failure;

  /// Categorized series for Netflix-style rows.
  final Map<String, List<SeriesItem>> categorizedSeries;

  /// Hero banner items (series with posters).
  final List<SeriesItem> heroItems;

  const SeriesScreenState({
    this.allSeries = const [],
    this.filteredSeries = const [],
    this.categories = const [],
    this.selectedCategory,
    this.searchQuery = '',
    this.isLoading = true,
    this.failure,
    this.categorizedSeries = const {},
    this.heroItems = const [],
  });

  SeriesScreenState copyWith({
    List<SeriesItem>? allSeries,
    List<SeriesItem>? filteredSeries,
    List<String>? categories,
    String? selectedCategory,
    bool clearSelectedCategory = false,
    String? searchQuery,
    bool? isLoading,
    AppFailure? failure,
    bool clearFailure = false,
    Map<String, List<SeriesItem>>? categorizedSeries,
    List<SeriesItem>? heroItems,
  }) {
    return SeriesScreenState(
      allSeries: allSeries ?? this.allSeries,
      filteredSeries: filteredSeries ?? this.filteredSeries,
      categories: categories ?? this.categories,
      selectedCategory: clearSelectedCategory
          ? null
          : (selectedCategory ?? this.selectedCategory),
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      failure: clearFailure ? null : (failure ?? this.failure),
      categorizedSeries: categorizedSeries ?? this.categorizedSeries,
      heroItems: heroItems ?? this.heroItems,
    );
  }
}

/// State for the Series detail screen.
class SeriesDetailState {
  final SeriesItem? series;
  final List<SeasonItem> seasons;
  final int selectedSeasonIndex;
  final bool isLoading;
  final bool isLoadingEpisodes;
  final AppFailure? failure;

  const SeriesDetailState({
    this.series,
    this.seasons = const [],
    this.selectedSeasonIndex = 0,
    this.isLoading = true,
    this.isLoadingEpisodes = false,
    this.failure,
  });

  SeriesDetailState copyWith({
    SeriesItem? series,
    List<SeasonItem>? seasons,
    int? selectedSeasonIndex,
    bool? isLoading,
    bool? isLoadingEpisodes,
    AppFailure? failure,
    bool clearFailure = false,
  }) {
    return SeriesDetailState(
      series: series ?? this.series,
      seasons: seasons ?? this.seasons,
      selectedSeasonIndex: selectedSeasonIndex ?? this.selectedSeasonIndex,
      isLoading: isLoading ?? this.isLoading,
      isLoadingEpisodes: isLoadingEpisodes ?? this.isLoadingEpisodes,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  /// Gets currently selected season.
  SeasonItem? get currentSeason =>
      seasons.isNotEmpty && selectedSeasonIndex < seasons.length
          ? seasons[selectedSeasonIndex]
          : null;
}

/// Provider for the Series list screen.
final seriesScreenProvider =
    StateNotifierProvider<SeriesScreenNotifier, SeriesScreenState>(
  (ref) => SeriesScreenNotifier(ref),
);

/// Provider for the Series detail screen.
final seriesDetailProvider = StateNotifierProvider.autoDispose
    .family<SeriesDetailNotifier, SeriesDetailState, int>(
  (ref, seriesId) => SeriesDetailNotifier(ref, seriesId),
);

/// Notifier for series list browsing with metadata enrichment.
///
/// Uses MetadataEnrichmentService (TMDB + TVMaze → MediaWork) for
/// on-demand enrichment and falls back to the legacy tmdb_cache.
class SeriesScreenNotifier extends StateNotifier<SeriesScreenState> {
  final Ref _ref;
  Timer? _debounce;
  Map<String, TmdbCacheEntry>? _legacyCache;

  SeriesScreenNotifier(this._ref) : super(const SeriesScreenState()) {
    _loadSeries();
  }

  /// Loads all series from database with cached metadata.
  Future<void> _loadSeries() async {
    try {
      final db = _ref.read(databaseProvider);

      // Ensure tables exist
      await db.tmdbCacheDao.ensureTable();
      await db.mediaWorkDao.ensureTables();

      // Load legacy TMDB cache for backwards compatibility
      _legacyCache = await db.tmdbCacheDao.getAllCachedByType('tv');

      // Query channels with sourceType series
      final channels = await db.channelsDao.getAllActiveChannels();
      final seriesChannels = channels
          .where((c) => c.sourceType == ChannelSourceType.series)
          .map((c) {
        final cached = _legacyCache?[c.id.toString()];
        var item = SeriesItem(
          id: c.id,
          playlistId: c.playlistId,
          name: c.name,
          coverUrl: c.logoUrl,
          categoryName: c.groupName,
          sourceId: c.sourceId,
        );

        if (cached != null) {
          item = item.copyWithTmdb(
            tmdbPosterUrl: cached.posterUrl,
            tmdbBackdropUrl: cached.backdropUrl,
            tmdbOverview: cached.overview,
            tmdbGenres: cached.genres,
            tmdbCast: cached.castNames,
            tmdbRating: cached.voteAverage,
            tmdbReleaseDate: cached.releaseDate,
            tmdbId: cached.tmdbId,
            tmdbSeasonsJson: cached.seasonsJson,
          );
        }
        return item;
      }).toList();

      final categories = seriesChannels
          .map((s) => s.categoryName)
          .where((c) => c != null && c.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList()
        ..sort();

      // Build categorized map for Netflix rows
      final categorizedSeries = <String, List<SeriesItem>>{};
      for (final series in seriesChannels) {
        final cat = series.shortCategory;
        categorizedSeries.putIfAbsent(cat, () => []).add(series);
      }

      // Pick hero items: series with poster images
      final seriesWithPoster = seriesChannels
          .where((s) => s.displayPosterUrl != null && s.displayPosterUrl!.isNotEmpty)
          .toList();
      List<SeriesItem> heroItems;
      if (seriesWithPoster.length >= 5) {
        seriesWithPoster.shuffle();
        heroItems = seriesWithPoster.take(5).toList();
      } else if (seriesWithPoster.isNotEmpty) {
        heroItems = seriesWithPoster.take(5).toList();
      } else {
        heroItems = seriesChannels.take(5).toList();
      }

      state = state.copyWith(
        allSeries: seriesChannels,
        filteredSeries: seriesChannels,
        categories: categories,
        isLoading: false,
        clearFailure: true,
        categorizedSeries: categorizedSeries,
        heroItems: heroItems,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        failure: DatabaseFailure(
          message: 'Erro ao carregar séries.',
          originalError: e,
        ),
      );
    }
  }

  /// Enriches a single series with metadata (called on-demand).
  ///
  /// Uses MetadataEnrichmentService which tries TMDB first, then TVMaze.
  Future<SeriesItem?> enrichSeries(SeriesItem series) async {
    if (series.isEnriched) return series;

    try {
      final enrichmentService = _ref.read(metadataEnrichmentServiceProvider);
      final mediaWork = await enrichmentService.enrichSeries(series.name);
      if (mediaWork == null) return null;

      // Read full metadata from media_works table
      final fullRow = await _getMediaWorkMetadata(mediaWork.id);

      final enriched = series.copyWithTmdb(
        tmdbPosterUrl: fullRow?['poster_url_cache'] as String?,
        tmdbBackdropUrl: fullRow?['banner_url_cache'] as String?,
        tmdbOverview: fullRow?['overview_cache'] as String?,
        tmdbGenres: fullRow?['genre_cache'] as String?,
        tmdbCast: fullRow?['cast_cache'] as String?,
        tmdbRating: (fullRow?['vote_average'] as num?)?.toDouble(),
        tmdbId: fullRow?['external_id'] as int?,
        mediaWorkId: mediaWork.id,
      );

      // Update in state
      if (mounted) {
        final updatedAll = state.allSeries.map((s) {
          return s.id == series.id ? enriched : s;
        }).toList();
        final updatedFiltered = state.filteredSeries.map((s) {
          return s.id == series.id ? enriched : s;
        }).toList();
        state = state.copyWith(
          allSeries: updatedAll,
          filteredSeries: updatedFiltered,
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

  /// Searches series with debounce.
  void search(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      state = state.copyWith(searchQuery: query);
      _applyFilters();
    });
  }

  /// Filters by category.
  void filterByCategory(String? category) {
    if (category == state.selectedCategory) {
      state = state.copyWith(clearSelectedCategory: true);
    } else {
      state = state.copyWith(selectedCategory: category);
    }
    _applyFilters();
  }

  /// Refreshes series.
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearFailure: true);
    await _loadSeries();
  }

  /// Applies search and category filters.
  void _applyFilters() {
    var filtered = state.allSeries;

    if (state.selectedCategory != null) {
      filtered = filtered
          .where((s) => s.categoryName == state.selectedCategory)
          .toList();
    }

    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      filtered = filtered.where((s) {
        return s.name.toLowerCase().contains(query) ||
            (s.categoryName?.toLowerCase().contains(query) ?? false) ||
            (s.tmdbGenres?.toLowerCase().contains(query) ?? false) ||
            (s.tmdbCast?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    state = state.copyWith(filteredSeries: filtered);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

/// Notifier for series detail screen with TMDB/TVMaze seasons and episodes.
class SeriesDetailNotifier extends StateNotifier<SeriesDetailState> {
  final Ref _ref;
  final int _seriesId;

  SeriesDetailNotifier(this._ref, this._seriesId)
      : super(const SeriesDetailState()) {
    _loadSeriesDetail();
  }

  /// Loads series detail with seasons from metadata.
  Future<void> _loadSeriesDetail() async {
    try {
      // Find the series in the list state first
      final seriesState = _ref.read(seriesScreenProvider);
      SeriesItem? series;
      for (final s in seriesState.allSeries) {
        if (s.id == _seriesId) {
          series = s;
          break;
        }
      }

      // If not found in state, load from database directly
      if (series == null || series.name.isEmpty) {
        final db = _ref.read(databaseProvider);
        final rows = await db.customSelect(
          'SELECT * FROM channels WHERE id = ? AND is_active = 1',
          variables: [Variable.withInt(_seriesId)],
        ).get();
        if (rows.isNotEmpty) {
          final row = rows.first;
          series = SeriesItem(
            id: row.read<int>('id'),
            playlistId: row.read<int>('playlist_id'),
            name: row.read<String>('name'),
            coverUrl: row.readNullable<String>('logo_url'),
            categoryName: row.readNullable<String>('group_name'),
            sourceId: row.readNullable<String>('source_id'),
          );
        } else {
          state = state.copyWith(isLoading: false);
          return;
        }
      }

      state = state.copyWith(series: series);

      // If already enriched with seasons data, parse it
      if (series.tmdbSeasonsJson != null && series.tmdbId != null) {
        final seasons = _parseSeasonsJson(series.tmdbSeasonsJson!);
        state = state.copyWith(seasons: seasons, isLoading: false);
      } else {
        // Try enriching from MetadataEnrichmentService
        final enrichmentService = _ref.read(metadataEnrichmentServiceProvider);
        final mediaWork = await enrichmentService.enrichSeries(series.name);

        if (mediaWork != null) {
          // Read full metadata
          final db = _ref.read(databaseProvider);
          final results = await db.customSelect(
            'SELECT * FROM media_works WHERE id = ?',
            variables: [Variable.withInt(mediaWork.id)],
          ).get();

          if (results.isNotEmpty) {
            final row = results.first.data;
            series = series.copyWithTmdb(
              tmdbId: row['external_id'] as int?,
              tmdbOverview: row['overview_cache'] as String?,
              tmdbPosterUrl: row['poster_url_cache'] as String?,
              tmdbBackdropUrl: row['banner_url_cache'] as String?,
              tmdbGenres: row['genre_cache'] as String?,
              tmdbCast: row['cast_cache'] as String?,
              mediaWorkId: mediaWork.id,
            );
          }

          // Try to get TMDB seasons if we have a tmdbId
          final tmdbId = series.tmdbId;
          if (tmdbId != null) {
            final tmdbDs = _ref.read(tmdbDataSourceProvider);
            final tvResult = await tmdbDs.getTvDetails(tmdbId);
            final seasons = tvResult.when(
              success: (details) => details.seasons.map((s) {
                return SeasonItem(
                  id: s.seasonNumber,
                  seriesId: _seriesId,
                  seasonNumber: s.seasonNumber,
                  name: s.name,
                  episodeCount: s.episodeCount,
                  coverUrl: TmdbDataSource.getImageUrl(s.posterPath),
                );
              }).toList(),
              failure: (_) => <SeasonItem>[],
            );

            state = state.copyWith(
              series: series,
              seasons: seasons,
              isLoading: false,
              isLoadingEpisodes: true,
            );
            // Auto-load episodes for the first season
            if (seasons.isNotEmpty) {
              loadSeasonEpisodes(seasons.first.seasonNumber);
            }
          } else {
            state = state.copyWith(series: series, isLoading: false);
          }
        } else {
          // Load seasons from local database as fallback
          await _loadLocalSeasons();
        }
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        failure: DatabaseFailure(
          message: 'Erro ao carregar detalhes da série.',
          originalError: e,
        ),
      );
    }
  }

  /// Loads episodes for a specific season — fetches from Xtream API for real
  /// stream URLs, then enriches with TMDB metadata (plot, cover, etc.).
  Future<void> loadSeasonEpisodes(int seasonNumber) async {
    final series = state.series;
    if (series == null) return;

    // 1. Fetch episode stream URLs from Xtream API
    final xtreamEpisodes = await _fetchXtreamEpisodes(seasonNumber);

    // 2. If we have TMDB data, enrich with metadata
    List<EpisodeItem> finalEpisodes;
    if (series.tmdbId != null) {
      final tmdbDs = _ref.read(tmdbDataSourceProvider);
      final result =
          await tmdbDs.getTvSeasonDetails(series.tmdbId!, seasonNumber);

      finalEpisodes = result.when(
        success: (tmdbEpisodes) {
          // Merge TMDB metadata with Xtream stream URLs by episode number
          return tmdbEpisodes.map((e) {
            // Find matching Xtream episode
            final xtreamEp = xtreamEpisodes.firstWhere(
              (x) => x.episodeNumber == e.episodeNumber,
              orElse: () => EpisodeItem(
                id: e.episodeNumber,
                seasonId: seasonNumber,
                seriesId: _seriesId,
                episodeNumber: e.episodeNumber,
                title: e.name,
                streamUrl: '',
              ),
            );
            return EpisodeItem(
              id: xtreamEp.id,
              seasonId: seasonNumber,
              seriesId: _seriesId,
              episodeNumber: e.episodeNumber,
              title: e.name.isNotEmpty ? e.name : xtreamEp.title,
              streamUrl: xtreamEp.streamUrl, // Real Xtream URL
              plot: e.overview,
              duration: e.runtime?.toString(),
              coverUrl: e.stillPath != null && e.stillPath!.isNotEmpty
                ? TmdbDataSource.getImageUrl(e.stillPath)
                : xtreamEp.coverUrl,
            );
          }).toList();
        },
        failure: (_) => xtreamEpisodes, // Fall back to Xtream-only episodes
      );
    } else {
      // No TMDB — use Xtream episodes directly
      finalEpisodes = xtreamEpisodes;
    }

    // Enrich episodes with watch progress from DB
    final enrichedEpisodes = await _enrichWithProgress(finalEpisodes, seasonNumber);

    final updatedSeasons = state.seasons.map((s) {
      if (s.seasonNumber == seasonNumber) {
        return SeasonItem(
          id: s.id,
          seriesId: s.seriesId,
          seasonNumber: s.seasonNumber,
          name: s.name,
          coverUrl: s.coverUrl,
          episodeCount: enrichedEpisodes.isNotEmpty ? enrichedEpisodes.length : s.episodeCount,
          episodes: enrichedEpisodes,
        );
      }
      return s;
    }).toList();

    state = state.copyWith(seasons: updatedSeasons, isLoadingEpisodes: false);
  }

  
  /// Enriches episodes with watch progress from the database.
  Future<List<EpisodeItem>> _enrichWithProgress(List<EpisodeItem> episodes, int seasonNumber) async {
    if (episodes.isEmpty) return episodes;
    final series = state.series;
    if (series == null) return episodes;

    try {
      final db = _ref.read(databaseProvider);
      // Query watch history for this series + season
      final rows = await db.customSelect(
        'SELECT episode_number, progress_percent, watched_duration_ms, total_duration_ms '
        'FROM watch_history_entries '
        'WHERE series_id = ? AND season_number = ? AND content_type = \'series\'',
        variables: [Variable.withInt(series.id), Variable.withInt(seasonNumber)],
      ).get();

      if (rows.isEmpty) return episodes;

      // Build a map: episodeNumber → progress
      final progressMap = <int, double>{};
      for (final row in rows) {
        final epNum = row.read<int>('episode_number');
        final progress = (row.read<double>('progress_percent')).clamp(0.0, 1.0);
        final watchedMs = row.read<int>('watched_duration_ms');
        final totalMs = row.read<int>('total_duration_ms');
        // Use progress_percent if available, otherwise estimate from duration
        if (progress > 0) {
          progressMap[epNum] = progress;
        } else if (totalMs > 0) {
          progressMap[epNum] = (watchedMs / totalMs).clamp(0.0, 1.0);
        } else if (watchedMs > 5000) {
          progressMap[epNum] = 0.05; // Watched but unknown total
        }
      }

      // Build duration maps too
      final watchedMsMap = <int, int>{};
      final totalMsMap = <int, int>{};
      for (final row in rows) {
        final epNum = row.read<int>('episode_number');
        watchedMsMap[epNum] = row.read<int>('watched_duration_ms');
        totalMsMap[epNum] = row.read<int>('total_duration_ms');
      }

      return episodes.map((ep) {
        final progress = progressMap[ep.episodeNumber];
        if (progress != null && progress > 0) {
          return ep.copyWith(
            watchProgress: progress,
            watchedDurationMs: watchedMsMap[ep.episodeNumber] ?? 0,
            totalDurationMs: totalMsMap[ep.episodeNumber] ?? 0,
          );
        }
        return ep;
      }).toList();
    } catch (e) {
      return episodes; // Fail silently
    }
  }

/// Fetches episodes for a season from the Xtream API.
  Future<List<EpisodeItem>> _fetchXtreamEpisodes(int seasonNumber) async {
    final series = state.series;
    if (series == null || series.sourceId == null) return [];

    try {
      final db = _ref.read(databaseProvider);

      // Get playlist credentials
      final playlistRows = await db.customSelect(
        'SELECT p.url, p.username, p.credential_key FROM playlists p '
        'INNER JOIN channels c ON c.playlist_id = p.id '
        'WHERE c.id = ? LIMIT 1',
        variables: [Variable.withInt(_seriesId)],
      ).get();

      if (playlistRows.isEmpty) return [];

      final serverUrl = playlistRows.first.read<String>('url');
      final username = playlistRows.first.readNullable<String>('username') ?? '';
      final password = playlistRows.first.readNullable<String>('credential_key') ?? '';

      if (username.isEmpty || password.isEmpty) return [];

      final seriesIdInt = int.tryParse(series.sourceId!);
      if (seriesIdInt == null) return [];

      final xtream = XtreamDataSource(client: DioClient());
      final result = await xtream.getSeriesInfo(
        serverUrl: serverUrl,
        username: username,
        password: password,
        seriesId: seriesIdInt,
      );

      return result.when(
        success: (info) {
          final seasonEpisodes = info.episodes[seasonNumber] ?? [];
          return seasonEpisodes.map((ep) {
            final streamUrl = xtream.buildSeriesStreamUrl(
              serverUrl: serverUrl,
              username: username,
              password: password,
              episodeId: ep.id,
              extension: ep.containerExtension ?? 'mp4',
            );
            return EpisodeItem(
              id: int.tryParse(ep.id) ?? 0,
              seasonId: seasonNumber,
              seriesId: _seriesId,
              episodeNumber: ep.episodeNum,
              title: ep.title,
              streamUrl: streamUrl,
              containerExtension: ep.containerExtension,
              plot: ep.plot,
              coverUrl: ep.coverBig,
            );
          }).toList();
        },
        failure: (_) => <EpisodeItem>[],
      );
    } catch (e) {
      return [];
    }
  }

  /// Selects a season by index.
  void selectSeason(int index) {
    state = state.copyWith(selectedSeasonIndex: index);
    final season = state.currentSeason;
    if (season != null && season.episodes.isEmpty) {
      state = state.copyWith(isLoadingEpisodes: true);
      loadSeasonEpisodes(season.seasonNumber);
    }
  }

  /// Parses seasons JSON from cache.
  List<SeasonItem> _parseSeasonsJson(String json) {
    try {
      final data = jsonDecode(json) as List<dynamic>;
      return data.map((s) {
        final map = s as Map<String, dynamic>;
        return SeasonItem(
          id: map['season_number'] as int? ?? 0,
          seriesId: _seriesId,
          seasonNumber: map['season_number'] as int? ?? 0,
          name: map['name'] as String?,
          episodeCount: map['episode_count'] as int? ?? 0,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Loads seasons/episodes from local database (Xtream data).
  Future<void> _loadLocalSeasons() async {
    try {
      final db = _ref.read(databaseProvider);
      final seasonRows = await db.customSelect(
        'SELECT * FROM seasons WHERE series_id = ? ORDER BY season_number',
        variables: [Variable.withInt(_seriesId)],
      ).get();

      if (seasonRows.isNotEmpty) {
        // Use local data
        final seasons = <SeasonItem>[];
        for (final row in seasonRows) {
          final seasonId = row.read<int>('id');
          final episodeRows = await db.customSelect(
            'SELECT * FROM episodes WHERE season_id = ? ORDER BY episode_number',
            variables: [Variable.withInt(seasonId)],
          ).get();

          seasons.add(SeasonItem(
            id: seasonId,
            seriesId: _seriesId,
            seasonNumber: row.read<int>('season_number'),
            name: row.readNullable<String>('name'),
            coverUrl: row.readNullable<String>('cover_url'),
            episodeCount: episodeRows.length,
            episodes: episodeRows.map((e) {
              return EpisodeItem(
                id: e.read<int>('id'),
                seasonId: seasonId,
                seriesId: _seriesId,
                episodeNumber: e.read<int>('episode_number'),
                title: e.read<String>('title'),
                streamUrl: e.read<String>('stream_url'),
                containerExtension: e.readNullable<String>('container_extension'),
                plot: e.readNullable<String>('plot'),
                coverUrl: e.readNullable<String>('cover_url'),
              );
            }).toList(),
          ));
        }
        state = state.copyWith(seasons: seasons, isLoading: false);
      } else {
        // No local data — fetch from Xtream API
        await _loadSeasonsFromXtream();
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Fetches seasons/episodes directly from Xtream API using series sourceId.
  Future<void> _loadSeasonsFromXtream() async {
    final series = state.series;
    if (series == null || series.sourceId == null) {
      state = state.copyWith(isLoading: false);
      return;
    }

    try {
      final db = _ref.read(databaseProvider);

      // Get playlist credentials (url, username, password stored in credential_key)
      final playlistRows = await db.customSelect(
        'SELECT p.url, p.username, p.credential_key FROM playlists p '
        'INNER JOIN channels c ON c.playlist_id = p.id '
        'WHERE c.id = ? LIMIT 1',
        variables: [Variable.withInt(_seriesId)],
      ).get();

      if (playlistRows.isEmpty) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final serverUrl = playlistRows.first.read<String>('url');
      final username = playlistRows.first.readNullable<String>('username') ?? '';
      final password = playlistRows.first.readNullable<String>('credential_key') ?? '';

      if (username.isEmpty || password.isEmpty) {
        state = state.copyWith(isLoading: false);
        return;
      }

      // Fetch series info from Xtream API
      final xtream = XtreamDataSource(client: DioClient());
      final seriesIdInt = int.tryParse(series.sourceId!);
      if (seriesIdInt == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final result = await xtream.getSeriesInfo(
        serverUrl: serverUrl,
        username: username,
        password: password,
        seriesId: seriesIdInt,
      );

      result.when(
        success: (info) {
          final seasons = info.seasons.map((season) {
            final seasonEpisodes = info.episodes[season.seasonNumber] ?? [];
            return SeasonItem(
              id: season.seasonNumber,
              seriesId: _seriesId,
              seasonNumber: season.seasonNumber,
              name: season.name,
              coverUrl: season.cover,
              episodeCount: seasonEpisodes.length,
              episodes: seasonEpisodes.map((ep) {
                final streamUrl = xtream.buildSeriesStreamUrl(
                  serverUrl: serverUrl,
                  username: username,
                  password: password,
                  episodeId: ep.id,
                  extension: ep.containerExtension ?? 'mp4',
                );
                return EpisodeItem(
                  id: int.tryParse(ep.id) ?? 0,
                  seasonId: season.seasonNumber,
                  seriesId: _seriesId,
                  episodeNumber: ep.episodeNum,
                  title: ep.title,
                  streamUrl: streamUrl,
                  containerExtension: ep.containerExtension,
                  plot: ep.plot,
                  coverUrl: ep.coverBig,
                );
              }).toList(),
            );
          }).toList();

          state = state.copyWith(seasons: seasons, isLoading: false);
        },
        failure: (_) {
          state = state.copyWith(isLoading: false);
        },
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }
}
