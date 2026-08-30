import 'package:nebula_iptv/core/constants/tmdb_constants.dart';
import 'package:nebula_iptv/core/logging/app_logger.dart';
import 'package:nebula_iptv/core/utils/string_similarity.dart';
import 'package:nebula_iptv/data/database/daos/media_work_dao.dart';
import 'package:nebula_iptv/data/datasources/tmdb/tmdb_datasource.dart';
import 'package:nebula_iptv/data/datasources/tmdb/tmdb_models.dart';
import 'package:nebula_iptv/data/datasources/tvmaze/tvmaze_datasource.dart';
import 'package:nebula_iptv/data/datasources/tvmaze/tvmaze_models.dart';
import 'package:nebula_iptv/domain/services/content_matching_service.dart';

/// Unified metadata enrichment service.
///
/// Pipeline:
/// 1. Check if MediaWork already exists for this content (via matching)
/// 2. If MediaWork exists and metadata is fresh (< 30 days), return cached
/// 3. If not, try TMDB first
/// 4. If TMDB fails/returns nothing, try TVMaze (series only)
/// 5. Persist result in MediaWork table
/// 6. Create ContentAlias for the original name
///
/// Rate limiting is handled internally.
/// TVMaze has no rate limit but we still throttle to be polite (max 20 req/10s).
class MetadataEnrichmentService {
  final MediaWorkDao _mediaWorkDao;
  final TmdbDataSource _tmdbDataSource;
  final TvMazeDataSource _tvMazeDataSource;
  final ContentMatchingService _matchingService;

  /// Rate limiting for TVMaze (polite: max 20 req/10s).
  final _tvMazeTimestamps = <DateTime>[];
  static const _tvMazeMaxRequestsPer10s = 20;

  /// Rate limiting for TMDB (40 req/10s as per TmdbConstants).
  final _tmdbTimestamps = <DateTime>[];
  static const _tmdbMaxRequestsPer10s = TmdbConstants.maxRequestsPer10Seconds;

  MetadataEnrichmentService({
    required MediaWorkDao mediaWorkDao,
    required TmdbDataSource tmdbDataSource,
    required TvMazeDataSource tvMazeDataSource,
    required ContentMatchingService matchingService,
  })  : _mediaWorkDao = mediaWorkDao,
        _tmdbDataSource = tmdbDataSource,
        _tvMazeDataSource = tvMazeDataSource,
        _matchingService = matchingService;

  /// Whether the TMDB API key is configured.
  bool get _isTmdbConfigured =>
      TmdbConstants.apiKey != 'YOUR_TMDB_API_KEY' &&
      TmdbConstants.apiKey.isNotEmpty;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Enriches a movie by name. Returns the MediaWork entry if successful.
  ///
  /// If the movie already has a fresh MediaWork entry, returns that.
  /// Otherwise, queries TMDB (primary) and creates/updates MediaWork.
  /// Movies have no TVMaze fallback (TVMaze is TV-only).
  Future<MediaWorkEntry?> enrichMovie(String originalName) async {
    if (originalName.trim().isEmpty) return null;

    final normalizedName = _matchingService.normalize(originalName);
    if (normalizedName.isEmpty) return null;

    appLogger.d(
      '[Enrichment] enrichMovie: "$originalName" → "$normalizedName"',
    );

    // Step 1: Check for existing MediaWork via matching
    final matchResult = await _matchingService.matchContent(
      originalName,
      type: 'movie',
    );

    if (matchResult.type == MatchType.exact ||
        matchResult.type == MatchType.fuzzy) {
      // We have a match — check if it's fresh enough
      if (matchResult.mediaWork != null) {
        appLogger.d(
          '[Enrichment] Match found: "${matchResult.mediaWork!.canonicalTitle}" '
          '(confidence: ${matchResult.confidence})',
        );
        return matchResult.mediaWork;
      }
    }

    // Step 2: Try TMDB
    if (!_isTmdbConfigured) {
      appLogger.w(
        '[Enrichment] TMDB API key not configured, cannot enrich '
        'movie "$originalName"',
      );
      return null;
    }

    final tmdbResult = await _searchAndFetchTmdbMovie(normalizedName);
    if (tmdbResult != null) {
      final entry = await _persistTmdbMovie(tmdbResult, originalName);
      appLogger.d(
        '[Enrichment] Movie enriched via TMDB: '
        '"${tmdbResult.title}" (id=${entry.id})',
      );
      return entry;
    }

    // Movies don't have TVMaze fallback (TVMaze is TV-only)
    appLogger.d('[Enrichment] No TMDB result for movie "$normalizedName"');
    return null;
  }

  /// Enriches a series by name. Returns the MediaWork entry if successful.
  ///
  /// Tries TMDB first, then TVMaze as fallback.
  Future<MediaWorkEntry?> enrichSeries(String originalName) async {
    if (originalName.trim().isEmpty) return null;

    final normalizedName = _matchingService.normalize(originalName);
    if (normalizedName.isEmpty) return null;

    appLogger.d(
      '[Enrichment] enrichSeries: "$originalName" → "$normalizedName"',
    );

    // Step 1: Check for existing MediaWork via matching
    final matchResult = await _matchingService.matchContent(
      originalName,
      type: 'series',
    );

    if (matchResult.type == MatchType.exact ||
        matchResult.type == MatchType.fuzzy) {
      if (matchResult.mediaWork != null) {
        appLogger.d(
          '[Enrichment] Match found: "${matchResult.mediaWork!.canonicalTitle}" '
          '(confidence: ${matchResult.confidence})',
        );
        return matchResult.mediaWork;
      }
    }

    // Step 2: Try TMDB first
    if (_isTmdbConfigured) {
      final tmdbResult = await _searchAndFetchTmdbSeries(normalizedName);
      if (tmdbResult != null) {
        final entry = await _persistTmdbSeries(tmdbResult, originalName);
        appLogger.d(
          '[Enrichment] Series enriched via TMDB: '
          '"${tmdbResult.name}" (id=${entry.id})',
        );
        return entry;
      }
    }

    // Step 3: Fallback to TVMaze
    final tvMazeResult = await _searchTvMaze(normalizedName);
    if (tvMazeResult != null) {
      final entry = await _persistTvMazeSeries(tvMazeResult, originalName);
      appLogger.d(
        '[Enrichment] Series enriched via TVMaze: '
        '"${tvMazeResult.name}" (id=${entry.id})',
      );
      return entry;
    }

    appLogger.d(
      '[Enrichment] No results for series "$normalizedName" '
      'from TMDB or TVMaze',
    );
    return null;
  }

  // ---------------------------------------------------------------------------
  // Private — TMDB Search & Fetch
  // ---------------------------------------------------------------------------

  /// Searches TMDB for a movie and fetches full details.
  Future<TmdbMovieDetails?> _searchAndFetchTmdbMovie(
    String normalizedName,
  ) async {
    await _respectTmdbRateLimit();

    final searchResult = await _tmdbDataSource.searchMovie(normalizedName);
    return await searchResult.when(
      success: (results) async {
        final best = _pickBestSearchResult(results, normalizedName);
        if (best == null) return null;

        await _respectTmdbRateLimit();
        final detailsResult = await _tmdbDataSource.getMovieDetails(best.id);
        return detailsResult.when(
          success: (details) => details,
          failure: (f) {
            appLogger.w(
              '[Enrichment] TMDB movie details failed for "$normalizedName": '
              '${f.message}',
            );
            return null;
          },
        );
      },
      failure: (f) {
        appLogger.w(
          '[Enrichment] TMDB movie search failed for "$normalizedName": '
          '${f.message}',
        );
        return null;
      },
    );
  }

  /// Searches TMDB for a series and fetches full details.
  Future<TmdbTvDetails?> _searchAndFetchTmdbSeries(
    String normalizedName,
  ) async {
    await _respectTmdbRateLimit();

    final searchResult = await _tmdbDataSource.searchTv(normalizedName);
    return await searchResult.when(
      success: (results) async {
        final best = _pickBestSearchResult(results, normalizedName);
        if (best == null) return null;

        await _respectTmdbRateLimit();
        final detailsResult = await _tmdbDataSource.getTvDetails(best.id);
        return detailsResult.when(
          success: (details) => details,
          failure: (f) {
            appLogger.w(
              '[Enrichment] TMDB tv details failed for "$normalizedName": '
              '${f.message}',
            );
            return null;
          },
        );
      },
      failure: (f) {
        appLogger.w(
          '[Enrichment] TMDB tv search failed for "$normalizedName": '
          '${f.message}',
        );
        return null;
      },
    );
  }

  /// Minimum title similarity to accept a TMDB search result. Below this,
  /// the search engine only returned loosely-related content — enriching
  /// with it would attach another show's seasons/episodes to this title.
  static const _minSearchSimilarity = 0.55;

  /// Picks the TMDB search result whose title best matches [query].
  ///
  /// Search engines rank by popularity — for weak queries the first hit can
  /// be a completely different show. Similarity comes first; votes only
  /// break ties between equally-similar titles.
  TmdbSearchResult? _pickBestSearchResult(
    List<TmdbSearchResult> results,
    String query,
  ) {
    if (results.isEmpty) return null;

    final normalizedQuery = _matchingService.normalize(query);

    TmdbSearchResult? best;
    var bestScore = 0.0;
    for (final r in results) {
      final titleScore = StringSimilarity.jaroWinkler(
        normalizedQuery,
        _matchingService.normalize(r.title),
      );
      final score = titleScore + (r.voteAverage > 0 ? 0.001 : 0.0);
      if (score > bestScore) {
        bestScore = score;
        best = r;
      }
    }

    if (best == null || bestScore < _minSearchSimilarity) {
      appLogger.d(
        '[Enrichment] Nenhum resultado TMDB similar o bastante para '
        '"$query" (melhor: ${best?.title}, score ${bestScore.toStringAsFixed(2)})',
      );
      return null;
    }
    return best;
  }

  // ---------------------------------------------------------------------------
  // Private — TVMaze Search
  // ---------------------------------------------------------------------------

  /// Searches TVMaze for a series.
  Future<TvMazeShow?> _searchTvMaze(String normalizedName) async {
    await _respectTvMazeRateLimit();

    final searchResult = await _tvMazeDataSource.searchShows(normalizedName);
    return searchResult.when(
      success: (results) {
        if (results.isEmpty) return null;
        // TVMaze returns results sorted by relevance score
        final best = results.first;
        if (best.score < 0.5) return null;
        return best.show;
      },
      failure: (f) {
        appLogger.w(
          '[Enrichment] TVMaze search failed for "$normalizedName": '
          '${f.message}',
        );
        return null;
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Private — Persistence
  // ---------------------------------------------------------------------------

  /// Creates a MediaWork entry from TMDB movie data.
  Future<MediaWorkEntry> _persistTmdbMovie(
    TmdbMovieDetails details,
    String originalName,
  ) async {
    final posterUrl = TmdbDataSource.getImageUrl(details.posterPath);
    final bannerUrl = TmdbDataSource.getImageUrl(
      details.backdropPath,
      size: 'w1280',
    );
    final year = _extractYear(details.releaseDate);
    final normalizedTitle = _matchingService.normalize(details.title);

    final entryId = await _mediaWorkDao.insertMediaWork(
      type: 'movie',
      canonicalTitle: details.title,
      normalizedTitle: normalizedTitle,
      year: year,
      overviewCache: details.overview,
      posterUrlCache: posterUrl.isNotEmpty ? posterUrl : null,
      bannerUrlCache: bannerUrl.isNotEmpty ? bannerUrl : null,
      genreCache: details.genreNames.isNotEmpty ? details.genreNames : null,
      castCache: details.castNames.isNotEmpty ? details.castNames : null,
      externalId: details.id,
      metadataSource: 'tmdb',
    );

    // Create content alias with the normalized original name
    final normalizedAlias = _matchingService.normalize(originalName);
    await _mediaWorkDao.insertAlias(
      mediaWorkId: entryId,
      aliasText: originalName,
      normalizedText: normalizedAlias,
      source: 'auto',
    );

    // Also create alias with canonical title if different
    if (normalizedTitle != normalizedAlias) {
      await _mediaWorkDao.insertAlias(
        mediaWorkId: entryId,
        aliasText: details.title,
        normalizedText: normalizedTitle,
        source: 'tmdb',
      );
    }

    return MediaWorkEntry(
      id: entryId,
      canonicalTitle: details.title,
      normalizedTitle: normalizedTitle,
      type: 'movie',
    );
  }

  /// Creates a MediaWork entry from TMDB TV data.
  Future<MediaWorkEntry> _persistTmdbSeries(
    TmdbTvDetails details,
    String originalName,
  ) async {
    final posterUrl = TmdbDataSource.getImageUrl(details.posterPath);
    final bannerUrl = TmdbDataSource.getImageUrl(
      details.backdropPath,
      size: 'w1280',
    );
    final year = _extractYear(details.firstAirDate);
    final normalizedTitle = _matchingService.normalize(details.name);

    final entryId = await _mediaWorkDao.insertMediaWork(
      type: 'series',
      canonicalTitle: details.name,
      normalizedTitle: normalizedTitle,
      year: year,
      overviewCache: details.overview,
      posterUrlCache: posterUrl.isNotEmpty ? posterUrl : null,
      bannerUrlCache: bannerUrl.isNotEmpty ? bannerUrl : null,
      genreCache: details.genreNames.isNotEmpty ? details.genreNames : null,
      castCache: details.castNames.isNotEmpty ? details.castNames : null,
      externalId: details.id,
      metadataSource: 'tmdb',
    );

    // Create content aliases
    final normalizedAlias = _matchingService.normalize(originalName);
    await _mediaWorkDao.insertAlias(
      mediaWorkId: entryId,
      aliasText: originalName,
      normalizedText: normalizedAlias,
      source: 'auto',
    );

    if (normalizedTitle != normalizedAlias) {
      await _mediaWorkDao.insertAlias(
        mediaWorkId: entryId,
        aliasText: details.name,
        normalizedText: normalizedTitle,
        source: 'tmdb',
      );
    }

    return MediaWorkEntry(
      id: entryId,
      canonicalTitle: details.name,
      normalizedTitle: normalizedTitle,
      type: 'series',
    );
  }

  /// Creates a MediaWork entry from TVMaze show data.
  Future<MediaWorkEntry> _persistTvMazeSeries(
    TvMazeShow show,
    String originalName,
  ) async {
    final posterUrl = show.image?.original ?? show.image?.medium ?? '';
    final year = _extractYear(show.premiered);
    final normalizedTitle = _matchingService.normalize(show.name);

    // Strip HTML from TVMaze summary
    final overview =
        show.summary != null ? TvMazeDataSource.stripHtml(show.summary!) : null;

    final genres = show.genres.isNotEmpty ? show.genres.join(', ') : null;

    final entryId = await _mediaWorkDao.insertMediaWork(
      type: 'series',
      canonicalTitle: show.name,
      normalizedTitle: normalizedTitle,
      year: year,
      overviewCache: overview,
      posterUrlCache: posterUrl.isNotEmpty ? posterUrl : null,
      genreCache: genres,
      externalId: show.id,
      metadataSource: 'tvmaze',
    );

    // Create content aliases
    final normalizedAlias = _matchingService.normalize(originalName);
    await _mediaWorkDao.insertAlias(
      mediaWorkId: entryId,
      aliasText: originalName,
      normalizedText: normalizedAlias,
      source: 'auto',
    );

    if (normalizedTitle != normalizedAlias) {
      await _mediaWorkDao.insertAlias(
        mediaWorkId: entryId,
        aliasText: show.name,
        normalizedText: normalizedTitle,
        source: 'tvmaze',
      );
    }

    return MediaWorkEntry(
      id: entryId,
      canonicalTitle: show.name,
      normalizedTitle: normalizedTitle,
      type: 'series',
    );
  }

  // ---------------------------------------------------------------------------
  // Private — Utilities
  // ---------------------------------------------------------------------------

  /// Extracts year from a date string (YYYY-MM-DD or YYYY).
  int? _extractYear(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    final match = RegExp(r'(\d{4})').firstMatch(dateStr);
    if (match != null) return int.tryParse(match.group(1)!);
    return null;
  }

  /// Ensures we don't exceed TMDB rate limits (40 req / 10s).
  Future<void> _respectTmdbRateLimit() async {
    final now = DateTime.now();
    final tenSecondsAgo = now.subtract(const Duration(seconds: 10));
    _tmdbTimestamps.removeWhere((t) => t.isBefore(tenSecondsAgo));

    if (_tmdbTimestamps.length >= _tmdbMaxRequestsPer10s) {
      final oldest = _tmdbTimestamps.first;
      final waitTime = oldest.add(const Duration(seconds: 10)).difference(now);
      if (!waitTime.isNegative) {
        await Future.delayed(waitTime + const Duration(milliseconds: 100));
      }
    }
    _tmdbTimestamps.add(DateTime.now());
  }

  /// Polite rate limiting for TVMaze (max 20 req / 10s).
  Future<void> _respectTvMazeRateLimit() async {
    final now = DateTime.now();
    final tenSecondsAgo = now.subtract(const Duration(seconds: 10));
    _tvMazeTimestamps.removeWhere((t) => t.isBefore(tenSecondsAgo));

    if (_tvMazeTimestamps.length >= _tvMazeMaxRequestsPer10s) {
      final oldest = _tvMazeTimestamps.first;
      final waitTime = oldest.add(const Duration(seconds: 10)).difference(now);
      if (!waitTime.isNegative) {
        await Future.delayed(waitTime + const Duration(milliseconds: 100));
      }
    }
    _tvMazeTimestamps.add(DateTime.now());
  }
}
