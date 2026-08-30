import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/core/errors/app_failure.dart';
import 'package:nebula_iptv/core/logging/app_logger.dart';
import 'package:nebula_iptv/core/network/dio_client.dart';
import 'package:nebula_iptv/data/database/daos/tmdb_cache_dao.dart';
import 'package:nebula_iptv/data/database/database_provider.dart';
import 'package:nebula_iptv/data/database/tables/channels_table.dart';
import 'package:nebula_iptv/data/datasources/tmdb/tmdb_datasource.dart';
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

  EpisodeItem copyWith(
      {double? watchProgress, int? watchedDurationMs, int? totalDurationMs}) {
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

      final allSeriesItems = <SeriesItem>[];

      // 1. Load from seriesItems table (Xtream series import)
      final dbSeries = await db.seriesDao.getAllActiveSeries();
      for (final s in dbSeries) {
        final cached = _legacyCache?[s.id.toString()];
        var item = SeriesItem(
          id: s.id,
          playlistId: s.playlistId,
          name: s.name,
          coverUrl: s.coverUrl,
          categoryName: s.categoryName,
          sourceId: s.sourceId,
          plot: s.plot,
          cast: s.cast,
          director: s.director,
          genre: s.genre,
          rating: s.rating?.toString(),
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
        allSeriesItems.add(item);
      }

      // 2. Also load from channels table (M3U imports with sourceType series)
      final channels = await db.channelsDao.getAllActiveChannels();
      final seriesFromChannels = channels
          .where((c) => c.sourceType == ChannelSourceType.series)
          .toList();

      // Avoid duplicates by checking sourceId
      final existingSourceIds =
          allSeriesItems.map((s) => s.sourceId).whereType<String>().toSet();

      for (final c in seriesFromChannels) {
        if (c.sourceId != null && existingSourceIds.contains(c.sourceId)) {
          continue; // Already loaded from seriesItems
        }
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
        allSeriesItems.add(item);
      }

      final categories = allSeriesItems
          .map((s) => s.categoryName)
          .where((c) => c != null && c.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList()
        ..sort();

      // Build categorized map for Netflix rows
      final categorizedSeries = <String, List<SeriesItem>>{};
      for (final series in allSeriesItems) {
        final cat = series.shortCategory;
        categorizedSeries.putIfAbsent(cat, () => []).add(series);
      }
      for (final series in categorizedSeries.values) {
        _sortForDiscovery(series);
      }
      _sortForDiscovery(allSeriesItems);

      // Pick hero items: series with poster images
      final seriesWithPoster = allSeriesItems
          .where((s) =>
              s.displayPosterUrl != null && s.displayPosterUrl!.isNotEmpty)
          .toList();
      List<SeriesItem> heroItems;
      if (seriesWithPoster.length >= 5) {
        seriesWithPoster.shuffle();
        heroItems = seriesWithPoster.take(5).toList();
      } else if (seriesWithPoster.isNotEmpty) {
        heroItems = seriesWithPoster.take(5).toList();
      } else {
        heroItems = allSeriesItems.take(5).toList();
      }

      state = state.copyWith(
        allSeries: allSeriesItems,
        filteredSeries: allSeriesItems,
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

  /// Prevent rows from mirroring the alphabetical order of the IPTV source.
  void _sortForDiscovery(List<SeriesItem> series) {
    double score(SeriesItem item) =>
        item.tmdbRating ?? double.tryParse(item.rating ?? '') ?? 0;
    series.sort((a, b) {
      final scoreOrder = score(b).compareTo(score(a));
      if (scoreOrder != 0) return scoreOrder;
      final enrichedOrder =
          (b.isEnriched ? 1 : 0).compareTo(a.isEnriched ? 1 : 0);
      if (enrichedOrder != 0) return enrichedOrder;
      final idOrder = b.id.compareTo(a.id);
      if (idOrder != 0) return idOrder;
      return a.name.compareTo(b.name);
    });
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
      // Enrichment failure should never block the UI, but must stay
      // observable (distinguishable from a genuine "no metadata found").
      appLogger.w(
        '[Series] Enriquecimento falhou para "${series.name}": $e',
      );
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
      SeriesItem? series;
      final db = _ref.read(databaseProvider);

      // The detail route can be opened before the list provider finishes.
      // Resolve the canonical item by ID first so the screen never depends on
      // another provider's timing.
      final dbSeries = await db.seriesDao.getSeriesById(_seriesId);
      if (dbSeries != null) {
        series = SeriesItem(
          id: dbSeries.id,
          playlistId: dbSeries.playlistId,
          name: dbSeries.name,
          coverUrl: dbSeries.coverUrl,
          categoryName: dbSeries.categoryName,
          sourceId: dbSeries.sourceId,
          plot: dbSeries.plot,
          cast: dbSeries.cast,
          director: dbSeries.director,
          genre: dbSeries.genre,
          rating: dbSeries.rating?.toString(),
        );
      } else {
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
        }
      }

      // A list-only item can still be valid for a M3U-backed source.
      if (series == null) {
        final seriesState = _ref.read(seriesScreenProvider);
        for (final candidate in seriesState.allSeries) {
          if (candidate.id == _seriesId && candidate.name.isNotEmpty) {
            series = candidate;
            break;
          }
        }
      }

      if (series == null) {
        state = state.copyWith(
          isLoading: false,
          failure: const DatabaseFailure(message: 'Série não encontrada.'),
        );
        return;
      }

      state = state.copyWith(series: series);

      // If already enriched with seasons data, parse it
      if (series.tmdbSeasonsJson != null && series.tmdbId != null) {
        final seasons = _parseSeasonsJson(series.tmdbSeasonsJson!);
        if (seasons != null && seasons.isNotEmpty) {
          state = state.copyWith(seasons: seasons, isLoading: false);
        } else {
          // Cache ausente ou corrompido: cai para os dados locais em vez de
          // exibir uma lista vazia que parece estado genuíno.
          await _loadLocalSeasons();
        }
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
            await tvResult.when(
              success: (details) async {
                final seasons = details.seasons.map((s) {
                  return SeasonItem(
                    id: s.seasonNumber,
                    seriesId: _seriesId,
                    seasonNumber: s.seasonNumber,
                    name: s.name,
                    episodeCount: s.episodeCount,
                    coverUrl: TmdbDataSource.getImageUrl(s.posterPath),
                  );
                }).toList();

                state = state.copyWith(
                  series: series,
                  seasons: seasons,
                  isLoading: false,
                  isLoadingEpisodes: true,
                );
                // Auto-load episodes for the first season
                if (seasons.isNotEmpty) {
                  await loadSeasonEpisodes(seasons.first.seasonNumber);
                }
              },
              failure: (f) async {
                appLogger.w(
                  '[SeriesDetail] Falha ao buscar temporadas no TMDB '
                  '(série $_seriesId): ${f.message}',
                );
                // Não exibir lista vazia como estado genuíno: aplica os dados
                // enriquecidos e cai para as temporadas locais/Xtream.
                state = state.copyWith(series: series);
                await _loadLocalSeasons();
              },
            );
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

    // 1. Fetch episode stream URLs from Xtream API. `null` = fetch failure
    // (distinguishable from a genuinely empty season).
    final xtreamEpisodes = await _fetchXtreamEpisodes(seasonNumber);
    if (xtreamEpisodes == null) {
      state = state.copyWith(
        isLoadingEpisodes: false,
        failure: const NetworkFailure(
          message: 'Erro ao carregar episódios do servidor.',
        ),
      );
      return;
    }

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
            // Localiza o episódio Xtream correspondente (busca explícita —
            // sem fabricar default silencioso).
            EpisodeItem? xtreamEp;
            for (final x in xtreamEpisodes) {
              if (x.episodeNumber == e.episodeNumber) {
                xtreamEp = x;
                break;
              }
            }
            if (xtreamEp == null) {
              appLogger.d(
                '[SeriesDetail] Episódio ${e.episodeNumber} da temporada '
                '$seasonNumber sem correspondência no Xtream (série '
                '$_seriesId); ficará sem stream URL.',
              );
            }
            return EpisodeItem(
              id: xtreamEp?.id ?? e.episodeNumber,
              seasonId: seasonNumber,
              seriesId: _seriesId,
              episodeNumber: e.episodeNumber,
              title: e.name.isNotEmpty ? e.name : (xtreamEp?.title ?? e.name),
              streamUrl: xtreamEp?.streamUrl ?? '', // vazio = não reproduzível
              plot: e.overview,
              duration: e.runtime?.toString(),
              coverUrl: e.stillPath != null && e.stillPath!.isNotEmpty
                  ? TmdbDataSource.getImageUrl(e.stillPath)
                  : xtreamEp?.coverUrl,
            );
          }).toList();
        },
        failure: (f) {
          appLogger.w(
            '[SeriesDetail] Falha ao buscar detalhes da temporada '
            '$seasonNumber no TMDB (série $_seriesId): ${f.message}',
          );
          return xtreamEpisodes; // Fall back to Xtream-only episodes
        },
      );
    } else {
      // No TMDB — use Xtream episodes directly
      finalEpisodes = xtreamEpisodes;
    }

    // Enrich episodes with watch progress from DB
    final enrichedEpisodes =
        await _enrichWithProgress(finalEpisodes, seasonNumber);

    final updatedSeasons = state.seasons.map((s) {
      if (s.seasonNumber == seasonNumber) {
        return SeasonItem(
          id: s.id,
          seriesId: s.seriesId,
          seasonNumber: s.seasonNumber,
          name: s.name,
          coverUrl: s.coverUrl,
          episodeCount: enrichedEpisodes.isNotEmpty
              ? enrichedEpisodes.length
              : s.episodeCount,
          episodes: enrichedEpisodes,
        );
      }
      return s;
    }).toList();

    state = state.copyWith(seasons: updatedSeasons, isLoadingEpisodes: false);
  }

  /// Enriches episodes with watch progress from the database.
  Future<List<EpisodeItem>> _enrichWithProgress(
      List<EpisodeItem> episodes, int seasonNumber) async {
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
        variables: [
          Variable.withInt(series.id),
          Variable.withInt(seasonNumber)
        ],
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
      // Progresso assistido é um enriquecimento opcional; não bloqueia a
      // lista, mas a falha deve ficar observável.
      appLogger.w(
        '[SeriesDetail] Falha ao carregar progresso dos episódios: $e',
      );
      return episodes;
    }
  }

  /// Helper to get playlist credentials (serverUrl, username, password) for a series.
  Future<({String serverUrl, String username, String password})?>
      _getPlaylistCredentials(int playlistId) async {
    try {
      final db = _ref.read(databaseProvider);
      var playlistRows = await db.customSelect(
        'SELECT url, username, credential_key FROM playlists WHERE id = ? LIMIT 1',
        variables: [Variable.withInt(playlistId)],
      ).get();

      if (playlistRows.isEmpty) {
        playlistRows = await db.customSelect(
          'SELECT p.url, p.username, p.credential_key FROM playlists p '
          'INNER JOIN channels c ON c.playlist_id = p.id '
          'WHERE c.id = ? LIMIT 1',
          variables: [Variable.withInt(_seriesId)],
        ).get();
      }

      if (playlistRows.isEmpty) {
        playlistRows = await db
            .customSelect(
              'SELECT url, username, credential_key FROM playlists LIMIT 1',
            )
            .get();
      }

      if (playlistRows.isEmpty) return null;

      final serverUrl = playlistRows.first.read<String>('url');
      final username =
          playlistRows.first.readNullable<String>('username') ?? '';
      final credentialKey =
          playlistRows.first.readNullable<String>('credential_key') ?? '';

      if (serverUrl.isEmpty || username.isEmpty || credentialKey.isEmpty) {
        return null;
      }

      // A coluna credential_key é a CHAVE do cofre seguro (spec §4.12) —
      // a senha real precisa ser resolvida por ela. Enviar a chave como
      // senha autenticava com lixo e a busca de episódios falhava sempre.
      var password = '';
      final stored = await _ref
          .read(credentialStoreProvider)
          .read(key: credentialKey);
      stored.when(
        success: (value) => password = value ?? '',
        failure: (f) =>
            appLogger.w('[SeriesDetail] Falha ao ler credencial: ${f.message}'),
      );

      // Legado: registros antigos podiam guardar a senha crua na coluna.
      if (password.isEmpty) password = credentialKey;

      return (serverUrl: serverUrl, username: username, password: password);
    } catch (e) {
      appLogger.w(
        '[SeriesDetail] Falha ao resolver credenciais da playlist: $e',
      );
      return null;
    }
  }

  /// Fetches episodes for a season from the Xtream API.
  ///
  /// Returns `null` when the fetch fails (surfaced as an error state by the
  /// caller); an empty list means the season genuinely has no episodes.
  Future<List<EpisodeItem>?> _fetchXtreamEpisodes(int seasonNumber) async {
    final series = state.series;
    if (series == null || series.sourceId == null) return [];

    try {
      final creds = await _getPlaylistCredentials(series.playlistId);
      if (creds == null) {
        appLogger.w(
          '[SeriesDetail] Sem credenciais para buscar episódios '
          '(série $_seriesId).',
        );
        return null;
      }

      final seriesIdInt = int.tryParse(series.sourceId!);
      if (seriesIdInt == null) {
        appLogger.w(
          '[SeriesDetail] sourceId inválido para episódios '
          '(série $_seriesId).',
        );
        return null;
      }

      final xtream = XtreamDataSource(client: DioClient());
      final result = await xtream.getSeriesInfo(
        serverUrl: creds.serverUrl,
        username: creds.username,
        password: creds.password,
        seriesId: seriesIdInt,
      );

      return await result.when(
        success: (info) {
          final seasonEpisodes = info.episodes[seasonNumber] ?? [];
          return seasonEpisodes.map((ep) {
            final streamUrl = xtream.buildSeriesStreamUrl(
              serverUrl: creds.serverUrl,
              username: creds.username,
              password: creds.password,
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
        failure: (f) {
          appLogger.w(
            '[SeriesDetail] Falha ao buscar episódios no Xtream '
            '(série $_seriesId): ${f.message}',
          );
          return null;
        },
      );
    } catch (e) {
      appLogger.w(
        '[SeriesDetail] Erro ao buscar episódios no Xtream '
        '(série $_seriesId): $e',
      );
      return null;
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
  ///
  /// Returns `null` when the payload is corrupt (distinguishable from a
  /// genuine empty season list, which parses to an empty list).
  List<SeasonItem>? _parseSeasonsJson(String json) {
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
    } catch (e) {
      appLogger.w(
        '[SeriesDetail] Falha ao interpretar temporadas em cache '
        '(série $_seriesId): $e',
      );
      return null;
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

          seasons.add(
            SeasonItem(
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
                  containerExtension:
                      e.readNullable<String>('container_extension'),
                  plot: e.readNullable<String>('plot'),
                  coverUrl: e.readNullable<String>('cover_url'),
                );
              }).toList(),
            ),
          );
        }
        state = state.copyWith(seasons: seasons, isLoading: false);
      } else {
        // No local data — fetch from Xtream API
        await _loadSeasonsFromXtream();
      }
    } catch (e) {
      appLogger.w(
        '[SeriesDetail] Falha ao carregar temporadas locais '
        '(série $_seriesId): $e',
      );
      state = state.copyWith(
        isLoading: false,
        failure: DatabaseFailure(
          message: 'Erro ao carregar temporadas da série.',
          originalError: e,
        ),
      );
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
      final creds = await _getPlaylistCredentials(series.playlistId);
      if (creds == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final seriesIdInt = int.tryParse(series.sourceId!);
      if (seriesIdInt == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      // Fetch series info from Xtream API
      final xtream = XtreamDataSource(client: DioClient());
      final result = await xtream.getSeriesInfo(
        serverUrl: creds.serverUrl,
        username: creds.username,
        password: creds.password,
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
                  serverUrl: creds.serverUrl,
                  username: creds.username,
                  password: creds.password,
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
        failure: (f) {
          appLogger.w(
            '[SeriesDetail] Falha ao buscar temporadas no Xtream '
            '(série $_seriesId): ${f.message}',
          );
          state = state.copyWith(isLoading: false, failure: f);
        },
      );
    } catch (e) {
      appLogger.w(
        '[SeriesDetail] Erro ao buscar temporadas no Xtream '
        '(série $_seriesId): $e',
      );
      state = state.copyWith(
        isLoading: false,
        failure: UnknownFailure(
          message: 'Erro ao carregar temporadas da série.',
          originalError: e,
        ),
      );
    }
  }
}
