/// Models for TMDB API responses.

/// A genre from TMDB.
class TmdbGenre {
  final int id;
  final String name;

  const TmdbGenre({required this.id, required this.name});

  factory TmdbGenre.fromJson(Map<String, dynamic> json) {
    return TmdbGenre(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
    );
  }
}

/// A cast member from TMDB.
class TmdbCastMember {
  final int id;
  final String name;
  final String? character;
  final String? profilePath;

  const TmdbCastMember({
    required this.id,
    required this.name,
    this.character,
    this.profilePath,
  });

  factory TmdbCastMember.fromJson(Map<String, dynamic> json) {
    return TmdbCastMember(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      character: json['character'] as String?,
      profilePath: json['profile_path'] as String?,
    );
  }
}

/// A search result from TMDB (movie or TV show).
class TmdbSearchResult {
  final int id;
  final String title;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final String? releaseDate;
  final double voteAverage;
  final List<int> genreIds;
  final String mediaType;

  const TmdbSearchResult({
    required this.id,
    required this.title,
    this.overview,
    this.posterPath,
    this.backdropPath,
    this.releaseDate,
    this.voteAverage = 0.0,
    this.genreIds = const [],
    this.mediaType = 'movie',
  });

  factory TmdbSearchResult.fromJson(Map<String, dynamic> json, {String? type}) {
    final mediaType = type ?? json['media_type'] as String? ?? 'movie';
    return TmdbSearchResult(
      id: json['id'] as int,
      title: (json['title'] ?? json['name'] ?? '') as String,
      overview: json['overview'] as String?,
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      releaseDate:
          (json['release_date'] ?? json['first_air_date']) as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      genreIds: (json['genre_ids'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      mediaType: mediaType,
    );
  }
}

/// Detailed movie information from TMDB.
class TmdbMovieDetails {
  final int id;
  final String title;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final String? releaseDate;
  final int? runtime;
  final double voteAverage;
  final List<TmdbGenre> genres;
  final List<TmdbCastMember> cast;
  final String? director;

  const TmdbMovieDetails({
    required this.id,
    required this.title,
    this.overview,
    this.posterPath,
    this.backdropPath,
    this.releaseDate,
    this.runtime,
    this.voteAverage = 0.0,
    this.genres = const [],
    this.cast = const [],
    this.director,
  });

  factory TmdbMovieDetails.fromJson(Map<String, dynamic> json) {
    final credits = json['credits'] as Map<String, dynamic>?;
    final castList = (credits?['cast'] as List<dynamic>?)
            ?.take(10)
            .map((e) => TmdbCastMember.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    String? director;
    final crew = credits?['crew'] as List<dynamic>?;
    if (crew != null) {
      for (final member in crew) {
        if ((member as Map<String, dynamic>)['job'] == 'Director') {
          director = member['name'] as String?;
          break;
        }
      }
    }

    return TmdbMovieDetails(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      overview: json['overview'] as String?,
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      releaseDate: json['release_date'] as String?,
      runtime: json['runtime'] as int?,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      genres: (json['genres'] as List<dynamic>?)
              ?.map((e) => TmdbGenre.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      cast: castList,
      director: director,
    );
  }

  /// Comma-separated genre names.
  String get genreNames => genres.map((g) => g.name).join(', ');

  /// Comma-separated cast names.
  String get castNames => cast.map((c) => c.name).join(', ');
}

/// A season summary from TMDB.
class TmdbSeason {
  final int seasonNumber;
  final String? name;
  final int episodeCount;
  final String? posterPath;
  final String? overview;

  const TmdbSeason({
    required this.seasonNumber,
    this.name,
    this.episodeCount = 0,
    this.posterPath,
    this.overview,
  });

  factory TmdbSeason.fromJson(Map<String, dynamic> json) {
    return TmdbSeason(
      seasonNumber: json['season_number'] as int? ?? 0,
      name: json['name'] as String?,
      episodeCount: json['episode_count'] as int? ?? 0,
      posterPath: json['poster_path'] as String?,
      overview: json['overview'] as String?,
    );
  }
}

/// An episode from TMDB.
class TmdbEpisode {
  final int episodeNumber;
  final String name;
  final String? overview;
  final String? stillPath;
  final String? airDate;
  final int? runtime;
  final double voteAverage;

  const TmdbEpisode({
    required this.episodeNumber,
    required this.name,
    this.overview,
    this.stillPath,
    this.airDate,
    this.runtime,
    this.voteAverage = 0.0,
  });

  factory TmdbEpisode.fromJson(Map<String, dynamic> json) {
    return TmdbEpisode(
      episodeNumber: json['episode_number'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      overview: json['overview'] as String?,
      stillPath: json['still_path'] as String?,
      airDate: json['air_date'] as String?,
      runtime: json['runtime'] as int?,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Detailed TV show information from TMDB.
class TmdbTvDetails {
  final int id;
  final String name;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final String? firstAirDate;
  final double voteAverage;
  final List<TmdbGenre> genres;
  final List<TmdbSeason> seasons;
  final int numberOfSeasons;
  final List<TmdbCastMember> cast;

  const TmdbTvDetails({
    required this.id,
    required this.name,
    this.overview,
    this.posterPath,
    this.backdropPath,
    this.firstAirDate,
    this.voteAverage = 0.0,
    this.genres = const [],
    this.seasons = const [],
    this.numberOfSeasons = 0,
    this.cast = const [],
  });

  factory TmdbTvDetails.fromJson(Map<String, dynamic> json) {
    final credits = json['credits'] as Map<String, dynamic>?;
    final castList = (credits?['cast'] as List<dynamic>?)
            ?.take(10)
            .map((e) => TmdbCastMember.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return TmdbTvDetails(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      overview: json['overview'] as String?,
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      firstAirDate: json['first_air_date'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      genres: (json['genres'] as List<dynamic>?)
              ?.map((e) => TmdbGenre.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      seasons: (json['seasons'] as List<dynamic>?)
              ?.map((e) => TmdbSeason.fromJson(e as Map<String, dynamic>))
              .where((s) => s.seasonNumber > 0) // Exclude specials (season 0)
              .toList() ??
          [],
      numberOfSeasons: json['number_of_seasons'] as int? ?? 0,
      cast: castList,
    );
  }

  /// Comma-separated genre names.
  String get genreNames => genres.map((g) => g.name).join(', ');

  /// Comma-separated cast names.
  String get castNames => cast.map((c) => c.name).join(', ');
}
