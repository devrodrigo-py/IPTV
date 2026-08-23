import 'package:nebula_iptv/core/errors/app_failure.dart';
import 'package:nebula_iptv/core/network/dio_client.dart';
import 'package:nebula_iptv/core/result/result.dart';
import 'package:nebula_iptv/data/datasources/tvmaze/tvmaze_models.dart';

/// Data source for TVMaze API interactions.
///
/// TVMaze is used as a fallback when TMDB does not return results,
/// particularly useful for lesser-known series.
/// TVMaze does NOT require an API key — it is fully open.
///
/// Base URL: https://api.tvmaze.com
class TvMazeDataSource {
  static const String _baseUrl = 'https://api.tvmaze.com';

  final DioClient _client;

  TvMazeDataSource({DioClient? client})
      : _client = client ?? DioClient(baseUrl: _baseUrl);

  /// Searches shows by name. Returns list ordered by relevance score.
  ///
  /// Endpoint: GET /search/shows?q={query}
  Future<Result<List<TvMazeSearchResult>>> searchShows(String query) async {
    final response = await _client.get<List<dynamic>>(
      '/search/shows',
      queryParameters: {'q': query},
    );

    return response.when(
      success: (res) {
        final data = res.data;
        if (data == null || data.isEmpty) return const Success([]);

        final results = data
            .map((e) =>
                TvMazeSearchResult.fromJson(e as Map<String, dynamic>))
            .toList();
        return Success(results);
      },
      failure: (f) => Failure(f),
    );
  }

  /// Gets show details by TVMaze ID.
  ///
  /// Endpoint: GET /shows/{id}
  Future<Result<TvMazeShow>> getShowDetails(int tvMazeId) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/shows/$tvMazeId',
    );

    return response.when(
      success: (res) {
        final data = res.data;
        if (data == null) {
          return const Failure(NetworkFailure(
            message: 'Resposta vazia do TVMaze.',
          ));
        }
        return Success(TvMazeShow.fromJson(data));
      },
      failure: (f) => Failure(f),
    );
  }

  /// Gets all seasons for a show.
  ///
  /// Endpoint: GET /shows/{id}/seasons
  Future<Result<List<TvMazeSeason>>> getSeasons(int showId) async {
    final response = await _client.get<List<dynamic>>(
      '/shows/$showId/seasons',
    );

    return response.when(
      success: (res) {
        final data = res.data;
        if (data == null || data.isEmpty) return const Success([]);

        final seasons = data
            .map((e) => TvMazeSeason.fromJson(e as Map<String, dynamic>))
            .toList();
        return Success(seasons);
      },
      failure: (f) => Failure(f),
    );
  }

  /// Gets all episodes for a season.
  ///
  /// Endpoint: GET /seasons/{id}/episodes
  Future<Result<List<TvMazeEpisode>>> getSeasonEpisodes(int seasonId) async {
    final response = await _client.get<List<dynamic>>(
      '/seasons/$seasonId/episodes',
    );

    return response.when(
      success: (res) {
        final data = res.data;
        if (data == null || data.isEmpty) return const Success([]);

        final episodes = data
            .map((e) => TvMazeEpisode.fromJson(e as Map<String, dynamic>))
            .toList();
        return Success(episodes);
      },
      failure: (f) => Failure(f),
    );
  }

  /// Strips HTML tags from TVMaze summaries.
  ///
  /// TVMaze returns summaries as HTML (e.g., `<p>Description here</p>`).
  /// This utility removes all HTML tags and trims whitespace.
  static String stripHtml(String? html) {
    if (html == null || html.isEmpty) return '';
    return html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }
}
