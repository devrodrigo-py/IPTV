/// Models for Xtream Codes API responses.
library;

/// These are raw DTOs — mapping to domain entities happens in the repository.
/// Authentication response from the Xtream API.
class XtreamAuthResponse {
  final XtreamUserInfo userInfo;
  final XtreamServerInfo serverInfo;

  const XtreamAuthResponse({
    required this.userInfo,
    required this.serverInfo,
  });

  factory XtreamAuthResponse.fromJson(Map<String, dynamic> json) {
    return XtreamAuthResponse(
      userInfo: XtreamUserInfo.fromJson(
        json['user_info'] as Map<String, dynamic>,
      ),
      serverInfo: XtreamServerInfo.fromJson(
        json['server_info'] as Map<String, dynamic>,
      ),
    );
  }
}

/// User info from Xtream authentication.
class XtreamUserInfo {
  final String username;
  final String status;
  final int auth;
  final String? expDate;
  final String? maxConnections;
  final String? activeCons;

  const XtreamUserInfo({
    required this.username,
    required this.status,
    required this.auth,
    this.expDate,
    this.maxConnections,
    this.activeCons,
  });

  factory XtreamUserInfo.fromJson(Map<String, dynamic> json) {
    return XtreamUserInfo(
      username: json['username']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      auth: _parseInt(json['auth']),
      expDate: json['exp_date']?.toString(),
      maxConnections: json['max_connections']?.toString(),
      activeCons: json['active_cons']?.toString(),
    );
  }

  /// Whether the account is authenticated.
  bool get isAuthenticated => auth == 1;

  /// Whether the account is expired.
  bool get isExpired {
    if (expDate == null || expDate!.isEmpty) return false;
    try {
      final expTimestamp = int.parse(expDate!);
      final expDateTime =
          DateTime.fromMillisecondsSinceEpoch(expTimestamp * 1000);
      return DateTime.now().isAfter(expDateTime);
    } catch (_) {
      return false;
    }
  }

  /// Whether max connections are exceeded.
  bool get isConnectionLimitReached {
    if (maxConnections == null || activeCons == null) return false;
    try {
      final max = int.parse(maxConnections!);
      final active = int.parse(activeCons!);
      return active >= max;
    } catch (_) {
      return false;
    }
  }
}

/// Server info from Xtream authentication.
class XtreamServerInfo {
  final String url;
  final String port;
  final String httpsPort;
  final String serverProtocol;

  const XtreamServerInfo({
    required this.url,
    required this.port,
    required this.httpsPort,
    required this.serverProtocol,
  });

  factory XtreamServerInfo.fromJson(Map<String, dynamic> json) {
    return XtreamServerInfo(
      url: json['url']?.toString() ?? '',
      port: json['port']?.toString() ?? '',
      httpsPort: json['https_port']?.toString() ?? '',
      serverProtocol: json['server_protocol']?.toString() ?? 'http',
    );
  }

  /// Constructs base URL from server info.
  String get baseUrl {
    final protocol = serverProtocol.isNotEmpty ? serverProtocol : 'http';
    final effectivePort = protocol == 'https' ? httpsPort : port;
    return '$protocol://$url:$effectivePort';
  }
}

/// A live stream category from Xtream API.
class XtreamCategory {
  final String categoryId;
  final String categoryName;

  const XtreamCategory({
    required this.categoryId,
    required this.categoryName,
  });

  factory XtreamCategory.fromJson(Map<String, dynamic> json) {
    return XtreamCategory(
      categoryId: json['category_id']?.toString() ?? '',
      categoryName: json['category_name']?.toString() ?? '',
    );
  }
}

/// A live stream entry from Xtream API.
class XtreamLiveStream {
  final int streamId;
  final String name;
  final String? streamIcon;
  final String? epgChannelId;
  final String? categoryId;
  final String? containerExtension;

  const XtreamLiveStream({
    required this.streamId,
    required this.name,
    this.streamIcon,
    this.epgChannelId,
    this.categoryId,
    this.containerExtension,
  });

  factory XtreamLiveStream.fromJson(Map<String, dynamic> json) {
    return XtreamLiveStream(
      streamId: _parseInt(json['stream_id']),
      name: json['name']?.toString() ?? '',
      streamIcon: json['stream_icon']?.toString(),
      epgChannelId: json['epg_channel_id']?.toString(),
      categoryId: json['category_id']?.toString(),
      containerExtension: json['container_extension']?.toString(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VOD (Movies) Models
// ─────────────────────────────────────────────────────────────────────────────

/// A VOD (movie) stream entry from Xtream API.
class XtreamVodStream {
  final int streamId;
  final String name;
  final String? streamIcon;
  final String? containerExtension;
  final String? categoryId;
  final String? plot;
  final String? cast;
  final String? director;
  final String? genre;
  final double? rating;
  final String? added;
  final int? duration;
  final String? durationSecs;
  final String? year;

  const XtreamVodStream({
    required this.streamId,
    required this.name,
    this.streamIcon,
    this.containerExtension,
    this.categoryId,
    this.plot,
    this.cast,
    this.director,
    this.genre,
    this.rating,
    this.added,
    this.duration,
    this.durationSecs,
    this.year,
  });

  factory XtreamVodStream.fromJson(Map<String, dynamic> json) {
    return XtreamVodStream(
      streamId: _parseInt(json['stream_id'] ?? json['num']),
      name: json['name']?.toString() ?? '',
      streamIcon: json['stream_icon']?.toString(),
      containerExtension: json['container_extension']?.toString(),
      categoryId: json['category_id']?.toString(),
      plot: json['plot']?.toString(),
      cast: json['cast']?.toString(),
      director: json['director']?.toString(),
      genre: json['genre']?.toString(),
      rating: _parseDouble(json['rating'] ?? json['rating_5based']),
      added: json['added']?.toString(),
      duration: _parseNullableInt(json['duration']),
      durationSecs: json['duration_secs']?.toString(),
      year: json['year']?.toString(),
    );
  }
}

/// Detailed VOD info (response from get_vod_info).
class XtreamVodInfo {
  final XtreamVodInfoData? movieData;
  final String? containerExtension;

  const XtreamVodInfo({
    this.movieData,
    this.containerExtension,
  });

  factory XtreamVodInfo.fromJson(Map<String, dynamic> json) {
    final info = json['info'] as Map<String, dynamic>?;
    final movieData = json['movie_data'] as Map<String, dynamic>?;

    return XtreamVodInfo(
      movieData: info != null
          ? XtreamVodInfoData.fromJson(info, movieData)
          : null,
      containerExtension:
          movieData?['container_extension']?.toString() ??
          json['container_extension']?.toString(),
    );
  }
}

/// Detailed movie data from get_vod_info.
class XtreamVodInfoData {
  final String? name;
  final String? plot;
  final String? cast;
  final String? director;
  final String? genre;
  final double? rating;
  final String? coverBig;
  final String? releaseDate;
  final String? year;
  final int? duration;
  final String? durationSecs;
  final String? backdrop;
  final String? youtubeTrailer;
  final String? tmdbId;

  const XtreamVodInfoData({
    this.name,
    this.plot,
    this.cast,
    this.director,
    this.genre,
    this.rating,
    this.coverBig,
    this.releaseDate,
    this.year,
    this.duration,
    this.durationSecs,
    this.backdrop,
    this.youtubeTrailer,
    this.tmdbId,
  });

  factory XtreamVodInfoData.fromJson(
    Map<String, dynamic> info,
    Map<String, dynamic>? movieData,
  ) {
    return XtreamVodInfoData(
      name: info['name']?.toString() ?? movieData?['name']?.toString(),
      plot: info['plot']?.toString() ?? info['description']?.toString(),
      cast: info['cast']?.toString() ?? info['actors']?.toString(),
      director: info['director']?.toString(),
      genre: info['genre']?.toString(),
      rating: _parseDouble(info['rating'] ?? info['rating_5based']),
      coverBig: info['cover_big']?.toString() ?? info['movie_image']?.toString(),
      releaseDate: info['releasedate']?.toString() ?? info['release_date']?.toString(),
      year: info['year']?.toString(),
      duration: _parseNullableInt(info['duration']),
      durationSecs: info['duration_secs']?.toString(),
      backdrop: info['backdrop_path']?.isNotEmpty == true
          ? 'https://image.tmdb.org/t/p/w780${info['backdrop_path']}'
          : null,
      youtubeTrailer: info['youtube_trailer']?.toString(),
      tmdbId: info['tmdb_id']?.toString(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Series Models
// ─────────────────────────────────────────────────────────────────────────────

/// A series entry from Xtream API (get_series).
class XtreamSeries {
  final int seriesId;
  final String name;
  final String? cover;
  final String? plot;
  final String? cast;
  final String? director;
  final String? genre;
  final double? rating;
  final String? categoryId;
  final String? backdropPath;
  final String? year;
  final String? lastModified;

  const XtreamSeries({
    required this.seriesId,
    required this.name,
    this.cover,
    this.plot,
    this.cast,
    this.director,
    this.genre,
    this.rating,
    this.categoryId,
    this.backdropPath,
    this.year,
    this.lastModified,
  });

  factory XtreamSeries.fromJson(Map<String, dynamic> json) {
    return XtreamSeries(
      seriesId: _parseInt(json['series_id']),
      name: json['name']?.toString() ?? '',
      cover: json['cover']?.toString(),
      plot: json['plot']?.toString(),
      cast: json['cast']?.toString(),
      director: json['director']?.toString(),
      genre: json['genre']?.toString(),
      rating: _parseDouble(json['rating'] ?? json['rating_5based']),
      categoryId: json['category_id']?.toString(),
      backdropPath: json['backdrop_path']?.isNotEmpty == true
          ? json['backdrop_path'].toString()
          : null,
      year: json['year']?.toString(),
      lastModified: json['last_modified']?.toString(),
    );
  }
}

/// Detailed series info (response from get_series_info).
class XtreamSeriesInfo {
  final XtreamSeriesInfoData? info;
  final List<XtreamSeason> seasons;
  final Map<int, List<XtreamEpisode>> episodes;

  const XtreamSeriesInfo({
    this.info,
    this.seasons = const [],
    this.episodes = const {},
  });

  factory XtreamSeriesInfo.fromJson(Map<String, dynamic> json) {
    // Parse info
    XtreamSeriesInfoData? info;
    if (json['info'] is Map<String, dynamic>) {
      info = XtreamSeriesInfoData.fromJson(
        json['info'] as Map<String, dynamic>,
      );
    }

    // Parse seasons
    final seasonsList = <XtreamSeason>[];
    if (json['seasons'] is List) {
      for (final s in json['seasons'] as List) {
        if (s is Map<String, dynamic>) {
          seasonsList.add(XtreamSeason.fromJson(s));
        }
      }
    }

    // Parse episodes (keyed by season number)
    final episodesMap = <int, List<XtreamEpisode>>{};
    if (json['episodes'] is Map) {
      final episodesRaw = json['episodes'] as Map<String, dynamic>;
      for (final entry in episodesRaw.entries) {
        final seasonNum = int.tryParse(entry.key) ?? 0;
        if (entry.value is List) {
          episodesMap[seasonNum] = (entry.value as List)
              .whereType<Map<String, dynamic>>()
              .map(XtreamEpisode.fromJson)
              .toList();
        }
      }
    }

    return XtreamSeriesInfo(
      info: info,
      seasons: seasonsList,
      episodes: episodesMap,
    );
  }
}

/// Series metadata from get_series_info → info.
class XtreamSeriesInfoData {
  final String? name;
  final String? cover;
  final String? plot;
  final String? cast;
  final String? director;
  final String? genre;
  final double? rating;
  final String? releaseDate;
  final String? backdropPath;
  final String? youtubeTrailer;
  final String? tmdbId;

  const XtreamSeriesInfoData({
    this.name,
    this.cover,
    this.plot,
    this.cast,
    this.director,
    this.genre,
    this.rating,
    this.releaseDate,
    this.backdropPath,
    this.youtubeTrailer,
    this.tmdbId,
  });

  factory XtreamSeriesInfoData.fromJson(Map<String, dynamic> json) {
    return XtreamSeriesInfoData(
      name: json['name']?.toString(),
      cover: json['cover']?.toString(),
      plot: json['plot']?.toString() ?? json['description']?.toString(),
      cast: json['cast']?.toString(),
      director: json['director']?.toString(),
      genre: json['genre']?.toString(),
      rating: _parseDouble(json['rating'] ?? json['rating_5based']),
      releaseDate: json['releaseDate']?.toString() ?? json['release_date']?.toString(),
      backdropPath: json['backdrop_path']?.isNotEmpty == true
          ? json['backdrop_path'].toString()
          : null,
      youtubeTrailer: json['youtube_trailer']?.toString(),
      tmdbId: json['tmdb_id']?.toString(),
    );
  }
}

/// A season within a series.
class XtreamSeason {
  final int seasonNumber;
  final String? name;
  final String? cover;
  final String? coverBig;
  final int? episodeCount;
  final String? airDate;

  const XtreamSeason({
    required this.seasonNumber,
    this.name,
    this.cover,
    this.coverBig,
    this.episodeCount,
    this.airDate,
  });

  factory XtreamSeason.fromJson(Map<String, dynamic> json) {
    return XtreamSeason(
      seasonNumber: _parseInt(json['season_number']),
      name: json['name']?.toString(),
      cover: json['cover']?.toString(),
      coverBig: json['cover_big']?.toString(),
      episodeCount: _parseNullableInt(json['episode_count']),
      airDate: json['air_date']?.toString(),
    );
  }
}

/// An episode within a season.
class XtreamEpisode {
  final String id;
  final int episodeNum;
  final String title;
  final String? containerExtension;
  final String? plot;
  final String? duration;
  final int? durationSecs;
  final String? coverBig;
  final double? rating;
  final String? releaseDate;
  final String? directSource;
  final XtreamEpisodeInfo? info;

  const XtreamEpisode({
    required this.id,
    required this.episodeNum,
    required this.title,
    this.containerExtension,
    this.plot,
    this.duration,
    this.durationSecs,
    this.coverBig,
    this.rating,
    this.releaseDate,
    this.directSource,
    this.info,
  });

  factory XtreamEpisode.fromJson(Map<String, dynamic> json) {
    XtreamEpisodeInfo? info;
    if (json['info'] is Map<String, dynamic>) {
      info = XtreamEpisodeInfo.fromJson(json['info'] as Map<String, dynamic>);
    }

    return XtreamEpisode(
      id: json['id']?.toString() ?? '',
      episodeNum: _parseInt(json['episode_num']),
      title: json['title']?.toString() ?? 'Episódio ${json['episode_num']}',
      containerExtension: json['container_extension']?.toString(),
      plot: info?.plot ?? json['plot']?.toString(),
      duration: info?.duration ?? json['duration']?.toString(),
      durationSecs: info?.durationSecs ?? _parseNullableInt(json['duration_secs']),
      coverBig: info?.coverBig ?? json['cover_big']?.toString(),
      rating: info?.rating ?? _parseDouble(json['rating']),
      releaseDate: info?.releaseDate ?? json['release_date']?.toString(),
      directSource: json['direct_source']?.toString(),
      info: info,
    );
  }
}

/// Extra info embedded in an episode object.
class XtreamEpisodeInfo {
  final String? plot;
  final String? duration;
  final int? durationSecs;
  final String? coverBig;
  final double? rating;
  final String? releaseDate;
  final String? movieImage;

  const XtreamEpisodeInfo({
    this.plot,
    this.duration,
    this.durationSecs,
    this.coverBig,
    this.rating,
    this.releaseDate,
    this.movieImage,
  });

  factory XtreamEpisodeInfo.fromJson(Map<String, dynamic> json) {
    return XtreamEpisodeInfo(
      plot: json['plot']?.toString(),
      duration: json['duration']?.toString(),
      durationSecs: _parseNullableInt(json['duration_secs']),
      coverBig: json['cover_big']?.toString() ?? json['movie_image']?.toString(),
      rating: _parseDouble(json['rating']),
      releaseDate: json['releasedate']?.toString() ?? json['release_date']?.toString(),
      movieImage: json['movie_image']?.toString(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Utility Helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Safely parses an int from dynamic (may be String or int).
int _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

/// Safely parses a nullable int from dynamic.
int? _parseNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

/// Safely parses a double from dynamic.
double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
