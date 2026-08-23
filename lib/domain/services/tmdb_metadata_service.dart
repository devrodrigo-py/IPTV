import 'dart:async';

import 'package:nebula_iptv/core/constants/tmdb_constants.dart';
import 'package:nebula_iptv/core/logging/app_logger.dart';
import 'package:nebula_iptv/data/datasources/tmdb/tmdb_datasource.dart';
import 'package:nebula_iptv/data/datasources/tmdb/tmdb_models.dart';

/// Service that matches IPTV content names to TMDB metadata.
///
/// Handles name normalization, search, and rate limiting.
class TmdbMetadataService {
  final TmdbDataSource _dataSource;
  final _requestTimestamps = <DateTime>[];
  static const _maxRequestsPer10s = TmdbConstants.maxRequestsPer10Seconds;

  TmdbMetadataService({TmdbDataSource? dataSource})
      : _dataSource = dataSource ?? TmdbDataSource();

  /// Enriches a movie name with TMDB metadata.
  ///
  /// Returns null if no match is found or API key is not configured.
  Future<TmdbMovieDetails?> enrichMovie(String name) async {
    if (TmdbConstants.apiKey == 'YOUR_TMDB_API_KEY') return null;

    await _respectRateLimit();

    final normalizedName = _normalizeName(name);
    if (normalizedName.isEmpty) return null;

    final searchResult = await _dataSource.searchMovie(normalizedName);
    return await searchResult.when(
      success: (results) async {
        if (results.isEmpty) return null;

        // Take the first result with reasonable confidence
        final best = results.first;
        if (best.voteAverage == 0 && results.length > 1) {
          // Skip zero-rated if better options exist
          for (final r in results) {
            if (r.voteAverage > 0) {
              return await _fetchMovieDetails(r.id);
            }
          }
        }
        return await _fetchMovieDetails(best.id);
      },
      failure: (_) => null,
    );
  }

  /// Enriches a TV series name with TMDB metadata.
  ///
  /// Returns null if no match is found or API key is not configured.
  Future<TmdbTvDetails?> enrichSeries(String name) async {
    if (TmdbConstants.apiKey == 'YOUR_TMDB_API_KEY') return null;

    await _respectRateLimit();

    final normalizedName = _normalizeName(name);
    if (normalizedName.isEmpty) return null;

    final searchResult = await _dataSource.searchTv(normalizedName);
    return await searchResult.when(
      success: (results) async {
        if (results.isEmpty) return null;
        final best = results.first;
        return await _fetchTvDetails(best.id);
      },
      failure: (_) => null,
    );
  }

  /// Gets episodes for a specific season.
  Future<List<TmdbEpisode>> getSeasonEpisodes(
    int tvId,
    int seasonNumber,
  ) async {
    if (TmdbConstants.apiKey == 'YOUR_TMDB_API_KEY') return [];

    await _respectRateLimit();

    final result = await _dataSource.getTvSeasonDetails(tvId, seasonNumber);
    return result.when(
      success: (episodes) => episodes,
      failure: (_) => [],
    );
  }

  /// Fetches full movie details.
  Future<TmdbMovieDetails?> _fetchMovieDetails(int tmdbId) async {
    await _respectRateLimit();
    final result = await _dataSource.getMovieDetails(tmdbId);
    return result.when(
      success: (details) => details,
      failure: (_) => null,
    );
  }

  /// Fetches full TV show details.
  Future<TmdbTvDetails?> _fetchTvDetails(int tmdbId) async {
    await _respectRateLimit();
    final result = await _dataSource.getTvDetails(tmdbId);
    return result.when(
      success: (details) => details,
      failure: (_) => null,
    );
  }

  /// Normalizes an IPTV content name for search.
  ///
  /// Removes quality tags, year brackets, episode/season markers, etc.
  String _normalizeName(String name) {
    var normalized = name;

    // Remove common quality tags
    normalized = normalized.replaceAll(
        RegExp(r'\[?(4K|UHD|FHD|HD|SD|720p|1080p|2160p)\]?',
            caseSensitive: false),
        '');

    // Remove brackets with content like [DUB], [LEG], [Nacional]
    normalized = normalized.replaceAll(
        RegExp(r'\[(DUB|LEG|DUAL|Nacional|Legendado|Dublado)\]',
            caseSensitive: false),
        '');

    // Remove parentheses with year (keep the year for search)
    final yearMatch = RegExp(r'\((\d{4})\)').firstMatch(normalized);
    if (yearMatch != null) {
      normalized = normalized.replaceAll(yearMatch.group(0)!, '');
    }

    // Remove season/episode markers
    normalized = normalized.replaceAll(
        RegExp(r'S\d{1,2}E\d{1,2}', caseSensitive: false), '');

    // Remove common separators and clean up
    normalized = normalized.replaceAll(RegExp(r'[_\-\.]+'), ' ');
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ');
    normalized = normalized.trim();

    // Remove trailing numbering like "01", "02" that might be channel numbers
    normalized = normalized.replaceAll(RegExp(r'\s+\d{1,2}$'), '');

    appLogger.d('TMDB normalize: "$name" → "$normalized"');
    return normalized;
  }

  /// Ensures we don't exceed TMDB rate limits (40 req / 10s).
  Future<void> _respectRateLimit() async {
    final now = DateTime.now();
    final tenSecondsAgo = now.subtract(const Duration(seconds: 10));

    // Remove timestamps older than 10 seconds
    _requestTimestamps.removeWhere((t) => t.isBefore(tenSecondsAgo));

    if (_requestTimestamps.length >= _maxRequestsPer10s) {
      // Wait until the oldest request in the window is >10s old
      final oldest = _requestTimestamps.first;
      final waitTime =
          oldest.add(const Duration(seconds: 10)).difference(now);
      if (waitTime.isNegative == false) {
        await Future.delayed(waitTime + const Duration(milliseconds: 100));
      }
    }

    _requestTimestamps.add(DateTime.now());
  }
}
