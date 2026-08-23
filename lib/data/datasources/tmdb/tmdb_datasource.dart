import 'package:nebula_iptv/core/constants/tmdb_constants.dart';
import 'package:nebula_iptv/core/errors/app_failure.dart';
import 'package:nebula_iptv/core/network/dio_client.dart';
import 'package:nebula_iptv/core/result/result.dart';
import 'package:nebula_iptv/data/datasources/tmdb/tmdb_models.dart';

/// Data source for TMDB API interactions.
///
/// Provides search and detail methods for movies and TV shows.
class TmdbDataSource {
  final DioClient _client;

  TmdbDataSource({DioClient? client})
      : _client = client ?? DioClient(baseUrl: TmdbConstants.baseUrl);

  /// Searches for movies by name.
  Future<Result<List<TmdbSearchResult>>> searchMovie(
    String query, {
    String language = TmdbConstants.defaultLanguage,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      '${TmdbConstants.baseUrl}/search/movie',
      queryParameters: {
        'api_key': TmdbConstants.apiKey,
        'query': query,
        'language': language,
        'page': 1,
        'include_adult': false,
      },
    );

    return response.when(
      success: (res) {
        final data = res.data;
        if (data == null) return const Success([]);

        final results = (data['results'] as List<dynamic>?)
                ?.map((e) => TmdbSearchResult.fromJson(
                    e as Map<String, dynamic>,
                    type: 'movie'))
                .toList() ??
            [];
        return Success(results);
      },
      failure: (f) => Failure(f),
    );
  }

  /// Searches for TV shows by name.
  Future<Result<List<TmdbSearchResult>>> searchTv(
    String query, {
    String language = TmdbConstants.defaultLanguage,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      '${TmdbConstants.baseUrl}/search/tv',
      queryParameters: {
        'api_key': TmdbConstants.apiKey,
        'query': query,
        'language': language,
        'page': 1,
      },
    );

    return response.when(
      success: (res) {
        final data = res.data;
        if (data == null) return const Success([]);

        final results = (data['results'] as List<dynamic>?)
                ?.map((e) => TmdbSearchResult.fromJson(
                    e as Map<String, dynamic>,
                    type: 'tv'))
                .toList() ??
            [];
        return Success(results);
      },
      failure: (f) => Failure(f),
    );
  }

  /// Gets detailed movie information including credits.
  Future<Result<TmdbMovieDetails>> getMovieDetails(
    int tmdbId, {
    String language = TmdbConstants.defaultLanguage,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      '${TmdbConstants.baseUrl}/movie/$tmdbId',
      queryParameters: {
        'api_key': TmdbConstants.apiKey,
        'language': language,
        'append_to_response': 'credits',
      },
    );

    return response.when(
      success: (res) {
        final data = res.data;
        if (data == null) {
          return const Failure(NetworkFailure(
            message: 'Resposta vazia do TMDB.',
          ));
        }
        return Success(TmdbMovieDetails.fromJson(data));
      },
      failure: (f) => Failure(f),
    );
  }

  /// Gets detailed TV show information including credits.
  Future<Result<TmdbTvDetails>> getTvDetails(
    int tmdbId, {
    String language = TmdbConstants.defaultLanguage,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      '${TmdbConstants.baseUrl}/tv/$tmdbId',
      queryParameters: {
        'api_key': TmdbConstants.apiKey,
        'language': language,
        'append_to_response': 'credits',
      },
    );

    return response.when(
      success: (res) {
        final data = res.data;
        if (data == null) {
          return const Failure(NetworkFailure(
            message: 'Resposta vazia do TMDB.',
          ));
        }
        return Success(TmdbTvDetails.fromJson(data));
      },
      failure: (f) => Failure(f),
    );
  }

  /// Gets season details with episodes.
  Future<Result<List<TmdbEpisode>>> getTvSeasonDetails(
    int tvId,
    int seasonNumber, {
    String language = TmdbConstants.defaultLanguage,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      '${TmdbConstants.baseUrl}/tv/$tvId/season/$seasonNumber',
      queryParameters: {
        'api_key': TmdbConstants.apiKey,
        'language': language,
      },
    );

    return response.when(
      success: (res) {
        final data = res.data;
        if (data == null) return const Success([]);

        final episodes = (data['episodes'] as List<dynamic>?)
                ?.map(
                    (e) => TmdbEpisode.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];
        return Success(episodes);
      },
      failure: (f) => Failure(f),
    );
  }

  /// Builds a full image URL from a TMDB path.
  static String getImageUrl(String? path, {String size = 'w500'}) {
    if (path == null || path.isEmpty) return '';
    return '${TmdbConstants.imageBaseUrl}/$size$path';
  }
}
