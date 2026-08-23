import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:nebula_iptv/core/constants/tmdb_constants.dart';
import 'package:nebula_iptv/data/database/app_database.dart';
import 'package:nebula_iptv/data/datasources/tmdb/tmdb_datasource.dart';
import 'package:nebula_iptv/data/datasources/tmdb/tmdb_models.dart';

/// Cached TMDB metadata entry.
class TmdbCacheEntry {
  final int id;
  final String sourceId;
  final String mediaType;
  final int tmdbId;
  final String title;
  final String? overview;
  final String? posterUrl;
  final String? backdropUrl;
  final double? voteAverage;
  final String? genres;
  final String? castNames;
  final String? director;
  final String? releaseDate;
  final int? runtime;
  final String? seasonsJson;
  final DateTime fetchedAt;

  const TmdbCacheEntry({
    required this.id,
    required this.sourceId,
    required this.mediaType,
    required this.tmdbId,
    required this.title,
    this.overview,
    this.posterUrl,
    this.backdropUrl,
    this.voteAverage,
    this.genres,
    this.castNames,
    this.director,
    this.releaseDate,
    this.runtime,
    this.seasonsJson,
    required this.fetchedAt,
  });
}

/// Manual DAO for the tmdb_cache table (no code generation).
class TmdbCacheDao extends DatabaseAccessor<AppDatabase> {
  TmdbCacheDao(super.db);

  /// Creates the cache table if it doesn't exist.
  Future<void> ensureTable() async {
    await customStatement('''
      CREATE TABLE IF NOT EXISTS tmdb_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        source_id TEXT NOT NULL,
        media_type TEXT NOT NULL,
        tmdb_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        overview TEXT,
        poster_url TEXT,
        backdrop_url TEXT,
        vote_average REAL,
        genres TEXT,
        cast_names TEXT,
        director TEXT,
        release_date TEXT,
        runtime INTEGER,
        seasons_json TEXT,
        fetched_at TEXT NOT NULL,
        UNIQUE(source_id, media_type)
      )
    ''');
  }

  /// Gets cached metadata for a source ID and media type.
  Future<TmdbCacheEntry?> getCached(String sourceId, String mediaType) async {
    final results = await customSelect(
      'SELECT * FROM tmdb_cache WHERE source_id = ? AND media_type = ?',
      variables: [Variable.withString(sourceId), Variable.withString(mediaType)],
    ).get();

    if (results.isEmpty) return null;

    final row = results.first;
    final fetchedAt = DateTime.tryParse(row.read<String>('fetched_at')) ??
        DateTime.now();

    // Check if cache is expired
    if (DateTime.now().difference(fetchedAt) > TmdbConstants.cacheDuration) {
      return null; // Expired, will be re-fetched
    }

    return TmdbCacheEntry(
      id: row.read<int>('id'),
      sourceId: row.read<String>('source_id'),
      mediaType: row.read<String>('media_type'),
      tmdbId: row.read<int>('tmdb_id'),
      title: row.read<String>('title'),
      overview: row.readNullable<String>('overview'),
      posterUrl: row.readNullable<String>('poster_url'),
      backdropUrl: row.readNullable<String>('backdrop_url'),
      voteAverage: row.readNullable<double>('vote_average'),
      genres: row.readNullable<String>('genres'),
      castNames: row.readNullable<String>('cast_names'),
      director: row.readNullable<String>('director'),
      releaseDate: row.readNullable<String>('release_date'),
      runtime: row.readNullable<int>('runtime'),
      seasonsJson: row.readNullable<String>('seasons_json'),
      fetchedAt: fetchedAt,
    );
  }

  /// Caches movie metadata.
  Future<void> cacheMovie(String sourceId, TmdbMovieDetails details) async {
    final posterUrl = TmdbDataSource.getImageUrl(
      details.posterPath,
      size: TmdbConstants.posterSizeLarge,
    );
    final backdropUrl = TmdbDataSource.getImageUrl(
      details.backdropPath,
      size: TmdbConstants.backdropSizeLarge,
    );

    await customInsert(
      '''INSERT OR REPLACE INTO tmdb_cache 
         (source_id, media_type, tmdb_id, title, overview, poster_url, 
          backdrop_url, vote_average, genres, cast_names, director, 
          release_date, runtime, fetched_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
      variables: [
        Variable.withString(sourceId),
        Variable.withString('movie'),
        Variable.withInt(details.id),
        Variable.withString(details.title),
        Variable.withString(details.overview ?? ''),
        Variable.withString(posterUrl),
        Variable.withString(backdropUrl),
        Variable.withReal(details.voteAverage),
        Variable.withString(details.genreNames),
        Variable.withString(details.castNames),
        Variable.withString(details.director ?? ''),
        Variable.withString(details.releaseDate ?? ''),
        Variable.withInt(details.runtime ?? 0),
        Variable.withString(DateTime.now().toIso8601String()),
      ],
    );
  }

  /// Caches TV series metadata.
  Future<void> cacheSeries(String sourceId, TmdbTvDetails details) async {
    final posterUrl = TmdbDataSource.getImageUrl(
      details.posterPath,
      size: TmdbConstants.posterSizeLarge,
    );
    final backdropUrl = TmdbDataSource.getImageUrl(
      details.backdropPath,
      size: TmdbConstants.backdropSizeLarge,
    );

    // Serialize seasons to JSON
    final seasonsJson = jsonEncode(
      details.seasons
          .map((s) => {
                'season_number': s.seasonNumber,
                'name': s.name,
                'episode_count': s.episodeCount,
                'poster_path': s.posterPath,
              })
          .toList(),
    );

    await customInsert(
      '''INSERT OR REPLACE INTO tmdb_cache 
         (source_id, media_type, tmdb_id, title, overview, poster_url, 
          backdrop_url, vote_average, genres, cast_names, 
          release_date, seasons_json, fetched_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
      variables: [
        Variable.withString(sourceId),
        Variable.withString('tv'),
        Variable.withInt(details.id),
        Variable.withString(details.name),
        Variable.withString(details.overview ?? ''),
        Variable.withString(posterUrl),
        Variable.withString(backdropUrl),
        Variable.withReal(details.voteAverage),
        Variable.withString(details.genreNames),
        Variable.withString(details.castNames),
        Variable.withString(details.firstAirDate ?? ''),
        Variable.withString(seasonsJson),
        Variable.withString(DateTime.now().toIso8601String()),
      ],
    );
  }

  /// Gets all cached entries for a media type (for batch loading).
  Future<Map<String, TmdbCacheEntry>> getAllCachedByType(
      String mediaType) async {
    final results = await customSelect(
      'SELECT * FROM tmdb_cache WHERE media_type = ?',
      variables: [Variable.withString(mediaType)],
    ).get();

    final map = <String, TmdbCacheEntry>{};
    for (final row in results) {
      final entry = TmdbCacheEntry(
        id: row.read<int>('id'),
        sourceId: row.read<String>('source_id'),
        mediaType: row.read<String>('media_type'),
        tmdbId: row.read<int>('tmdb_id'),
        title: row.read<String>('title'),
        overview: row.readNullable<String>('overview'),
        posterUrl: row.readNullable<String>('poster_url'),
        backdropUrl: row.readNullable<String>('backdrop_url'),
        voteAverage: row.readNullable<double>('vote_average'),
        genres: row.readNullable<String>('genres'),
        castNames: row.readNullable<String>('cast_names'),
        director: row.readNullable<String>('director'),
        releaseDate: row.readNullable<String>('release_date'),
        runtime: row.readNullable<int>('runtime'),
        seasonsJson: row.readNullable<String>('seasons_json'),
        fetchedAt:
            DateTime.tryParse(row.read<String>('fetched_at')) ?? DateTime.now(),
      );
      map[entry.sourceId] = entry;
    }
    return map;
  }

  /// Clears all cache.
  Future<void> clearAll() async {
    await customStatement('DELETE FROM tmdb_cache');
  }

  /// Clears expired cache entries.
  Future<void> clearExpired() async {
    final cutoff = DateTime.now()
        .subtract(TmdbConstants.cacheDuration)
        .toIso8601String();
    await customUpdate(
      'DELETE FROM tmdb_cache WHERE fetched_at < ?',
      variables: [Variable.withString(cutoff)],
      updates: {},
    );
  }
}
