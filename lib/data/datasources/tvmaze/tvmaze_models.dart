/// Models for TVMaze API responses.
///
/// TVMaze is used as a fallback datasource when TMDB does not return results,
/// particularly useful for lesser-known series. TVMaze does not require an API key.

class TvMazeShow {
  final int id;
  final String name;
  final String? summary;
  final String? language;
  final String? premiered;
  final TvMazeRating? rating;
  final TvMazeImage? image;
  final List<String> genres;
  final int? runtime;

  const TvMazeShow({
    required this.id,
    required this.name,
    this.summary,
    this.language,
    this.premiered,
    this.rating,
    this.image,
    this.genres = const [],
    this.runtime,
  });

  factory TvMazeShow.fromJson(Map<String, dynamic> json) {
    return TvMazeShow(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      summary: json['summary'] as String?,
      language: json['language'] as String?,
      premiered: json['premiered'] as String?,
      rating: json['rating'] != null
          ? TvMazeRating.fromJson(json['rating'] as Map<String, dynamic>)
          : null,
      image: json['image'] != null
          ? TvMazeImage.fromJson(json['image'] as Map<String, dynamic>)
          : null,
      genres: (json['genres'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      runtime: json['runtime'] as int?,
    );
  }

  @override
  String toString() => 'TvMazeShow(id: $id, name: $name)';
}

class TvMazeRating {
  final double? average;

  const TvMazeRating({this.average});

  factory TvMazeRating.fromJson(Map<String, dynamic> json) {
    return TvMazeRating(
      average: (json['average'] as num?)?.toDouble(),
    );
  }

  @override
  String toString() => 'TvMazeRating(average: $average)';
}

class TvMazeImage {
  final String? medium;
  final String? original;

  const TvMazeImage({this.medium, this.original});

  factory TvMazeImage.fromJson(Map<String, dynamic> json) {
    return TvMazeImage(
      medium: json['medium'] as String?,
      original: json['original'] as String?,
    );
  }

  @override
  String toString() => 'TvMazeImage(medium: $medium, original: $original)';
}

class TvMazeSeason {
  final int id;
  final int number;
  final String? name;
  final int? episodeOrder;
  final String? premiereDate;
  final TvMazeImage? image;

  const TvMazeSeason({
    required this.id,
    required this.number,
    this.name,
    this.episodeOrder,
    this.premiereDate,
    this.image,
  });

  factory TvMazeSeason.fromJson(Map<String, dynamic> json) {
    return TvMazeSeason(
      id: json['id'] as int,
      number: json['number'] as int,
      name: json['name'] as String?,
      episodeOrder: json['episodeOrder'] as int?,
      premiereDate: json['premiereDate'] as String?,
      image: json['image'] != null
          ? TvMazeImage.fromJson(json['image'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  String toString() => 'TvMazeSeason(id: $id, number: $number)';
}

class TvMazeEpisode {
  final int id;
  final String name;
  final int season;
  final int number;
  final String? summary;
  final int? runtime;
  final String? airdate;
  final TvMazeImage? image;

  const TvMazeEpisode({
    required this.id,
    required this.name,
    required this.season,
    required this.number,
    this.summary,
    this.runtime,
    this.airdate,
    this.image,
  });

  factory TvMazeEpisode.fromJson(Map<String, dynamic> json) {
    return TvMazeEpisode(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      season: json['season'] as int? ?? 0,
      number: json['number'] as int? ?? 0,
      summary: json['summary'] as String?,
      runtime: json['runtime'] as int?,
      airdate: json['airdate'] as String?,
      image: json['image'] != null
          ? TvMazeImage.fromJson(json['image'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  String toString() =>
      'TvMazeEpisode(id: $id, name: $name, S${season}E$number)';
}

class TvMazeSearchResult {
  final double score;
  final TvMazeShow show;

  const TvMazeSearchResult({
    required this.score,
    required this.show,
  });

  factory TvMazeSearchResult.fromJson(Map<String, dynamic> json) {
    return TvMazeSearchResult(
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      show: TvMazeShow.fromJson(json['show'] as Map<String, dynamic>),
    );
  }

  @override
  String toString() => 'TvMazeSearchResult(score: $score, show: ${show.name})';
}
