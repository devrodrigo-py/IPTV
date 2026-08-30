import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:nebula_iptv/core/errors/app_failure.dart';
import 'package:nebula_iptv/core/network/dio_client.dart';
import 'package:nebula_iptv/core/result/result.dart';
import 'package:nebula_iptv/core/utils/isolate_parse.dart';
import 'package:nebula_iptv/core/utils/url_normalization.dart';
import 'package:nebula_iptv/data/datasources/xtream/xtream_models.dart';

/// Data source for Xtream Codes API interactions.
///
/// Handles authentication, fetching categories, live streams,
/// VOD (movies), and series via the player_api.php endpoint (spec §12).
///
/// List payloads (live/VOD/series) are decoded and mapped outside the
/// main thread — they routinely reach tens of thousands of entries.
class XtreamDataSource {
  final DioClient _client;

  XtreamDataSource({required DioClient client}) : _client = client;

  // ───────────────────────────────────────────────────────────────────────────
  // Authentication
  // ───────────────────────────────────────────────────────────────────────────

  /// Authenticates with an Xtream server and validates the account.
  ///
  /// Returns [XtreamAuthResponse] on success, or a specific failure:
  /// - [AuthenticationFailure] for invalid credentials
  /// - [AccountExpiredFailure] for expired accounts
  /// - [ConnectionLimitFailure] for max connections reached
  Future<Result<XtreamAuthResponse>> authenticate({
    required String serverUrl,
    required String username,
    required String password,
    int? portOverride,
    bool allowInsecureCertificates = false,
  }) async {
    final baseUrl = _buildBaseUrl(serverUrl, portOverride);
    final url = '$baseUrl/player_api.php'
        '?username=$username&password=$password';

    final response = await _get<Map<String, dynamic>>(
      url,
      allowInsecureCertificates: allowInsecureCertificates,
    );

    return response.when(
      success: (res) {
        final data = res.data;
        if (data == null) {
          return const Failure(
            AuthenticationFailure(
              message: 'Resposta vazia do servidor.',
            ),
          );
        }

        try {
          final authResponse = XtreamAuthResponse.fromJson(data);
          final userInfo = authResponse.userInfo;

          // Validate authentication
          if (!userInfo.isAuthenticated) {
            return const Failure(
              AuthenticationFailure(
                message: 'Credenciais inválidas.',
              ),
            );
          }

          // Check expiration
          if (userInfo.isExpired) {
            return const Failure(
              AccountExpiredFailure(
                message: 'Sua conta expirou. '
                    'Entre em contato com seu provedor.',
              ),
            );
          }

          // Check connection limit
          if (userInfo.isConnectionLimitReached) {
            return const Failure(
              ConnectionLimitFailure(
                message: 'Limite de conexões simultâneas atingido.',
              ),
            );
          }

          return Success(authResponse);
        } catch (e) {
          return Failure(
            AuthenticationFailure(
              message: 'Erro ao processar resposta do servidor.',
              originalError: e,
            ),
          );
        }
      },
      failure: (f) => Failure(f),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Live Streams
  // ───────────────────────────────────────────────────────────────────────────

  /// Fetches live stream categories.
  Future<Result<List<XtreamCategory>>> getLiveCategories({
    required String serverUrl,
    required String username,
    required String password,
    int? portOverride,
    bool allowInsecureCertificates = false,
  }) async {
    return _fetchCategories(
      serverUrl: serverUrl,
      username: username,
      password: password,
      portOverride: portOverride,
      action: 'get_live_categories',
      allowInsecureCertificates: allowInsecureCertificates,
    );
  }

  /// Fetches live streams (all or by category).
  Future<Result<List<XtreamLiveStream>>> getLiveStreams({
    required String serverUrl,
    required String username,
    required String password,
    int? portOverride,
    String? categoryId,
    bool allowInsecureCertificates = false,
  }) async {
    final baseUrl = _buildBaseUrl(serverUrl, portOverride);
    var url = '$baseUrl/player_api.php'
        '?username=$username&password=$password'
        '&action=get_live_streams';

    if (categoryId != null && categoryId.isNotEmpty) {
      url += '&category_id=$categoryId';
    }

    return _fetchList(
      url,
      parseItem: XtreamLiveStream.fromJson,
      parseErrorMessage: 'Erro ao interpretar lista de canais.',
      allowInsecureCertificates: allowInsecureCertificates,
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // VOD (Movies)
  // ───────────────────────────────────────────────────────────────────────────

  /// Fetches VOD (movie) categories.
  Future<Result<List<XtreamCategory>>> getVodCategories({
    required String serverUrl,
    required String username,
    required String password,
    int? portOverride,
    bool allowInsecureCertificates = false,
  }) async {
    return _fetchCategories(
      serverUrl: serverUrl,
      username: username,
      password: password,
      portOverride: portOverride,
      action: 'get_vod_categories',
      allowInsecureCertificates: allowInsecureCertificates,
    );
  }

  /// Fetches VOD streams (all or by category).
  Future<Result<List<XtreamVodStream>>> getVodStreams({
    required String serverUrl,
    required String username,
    required String password,
    int? portOverride,
    String? categoryId,
    bool allowInsecureCertificates = false,
  }) async {
    final baseUrl = _buildBaseUrl(serverUrl, portOverride);
    var url = '$baseUrl/player_api.php'
        '?username=$username&password=$password'
        '&action=get_vod_streams';

    if (categoryId != null && categoryId.isNotEmpty) {
      url += '&category_id=$categoryId';
    }

    return _fetchList(
      url,
      parseItem: XtreamVodStream.fromJson,
      parseErrorMessage: 'Erro ao interpretar lista de filmes.',
      allowInsecureCertificates: allowInsecureCertificates,
    );
  }

  /// Fetches detailed info for a specific VOD item.
  Future<Result<XtreamVodInfo>> getVodInfo({
    required String serverUrl,
    required String username,
    required String password,
    required int vodId,
    int? portOverride,
  }) async {
    final baseUrl = _buildBaseUrl(serverUrl, portOverride);
    final url = '$baseUrl/player_api.php'
        '?username=$username&password=$password'
        '&action=get_vod_info&vod_id=$vodId';

    final response = await _client.get<Map<String, dynamic>>(url);

    return response.when(
      success: (res) {
        final data = res.data;
        if (data == null) {
          return const Failure(
            PlaylistParseFailure(
              message: 'Informações do filme não encontradas.',
            ),
          );
        }

        try {
          return Success(XtreamVodInfo.fromJson(data));
        } catch (e) {
          return Failure(
            PlaylistParseFailure(
              message: 'Erro ao interpretar informações do filme.',
              originalError: e,
            ),
          );
        }
      },
      failure: (f) => Failure(f),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Series
  // ───────────────────────────────────────────────────────────────────────────

  /// Fetches series categories.
  Future<Result<List<XtreamCategory>>> getSeriesCategories({
    required String serverUrl,
    required String username,
    required String password,
    int? portOverride,
    bool allowInsecureCertificates = false,
  }) async {
    return _fetchCategories(
      serverUrl: serverUrl,
      username: username,
      password: password,
      portOverride: portOverride,
      action: 'get_series_categories',
      allowInsecureCertificates: allowInsecureCertificates,
    );
  }

  /// Fetches series list (all or by category).
  Future<Result<List<XtreamSeries>>> getSeries({
    required String serverUrl,
    required String username,
    required String password,
    int? portOverride,
    String? categoryId,
    bool allowInsecureCertificates = false,
  }) async {
    final baseUrl = _buildBaseUrl(serverUrl, portOverride);
    var url = '$baseUrl/player_api.php'
        '?username=$username&password=$password'
        '&action=get_series';

    if (categoryId != null && categoryId.isNotEmpty) {
      url += '&category_id=$categoryId';
    }

    return _fetchList(
      url,
      parseItem: XtreamSeries.fromJson,
      parseErrorMessage: 'Erro ao interpretar lista de séries.',
      allowInsecureCertificates: allowInsecureCertificates,
    );
  }

  /// Fetches detailed info for a specific series (seasons + episodes).
  Future<Result<XtreamSeriesInfo>> getSeriesInfo({
    required String serverUrl,
    required String username,
    required String password,
    required int seriesId,
    int? portOverride,
  }) async {
    final baseUrl = _buildBaseUrl(serverUrl, portOverride);
    final url = '$baseUrl/player_api.php'
        '?username=$username&password=$password'
        '&action=get_series_info&series_id=$seriesId';

    final response = await _client.get<Map<String, dynamic>>(url);

    return response.when(
      success: (res) {
        final data = res.data;
        if (data == null) {
          return const Failure(
            PlaylistParseFailure(
              message: 'Informações da série não encontradas.',
            ),
          );
        }

        try {
          return Success(XtreamSeriesInfo.fromJson(data));
        } catch (e) {
          return Failure(
            PlaylistParseFailure(
              message: 'Erro ao interpretar informações da série.',
              originalError: e,
            ),
          );
        }
      },
      failure: (f) => Failure(f),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Stream URL Builders
  // ───────────────────────────────────────────────────────────────────────────

  /// Builds the stream URL for a live channel (spec §12).
  ///
  /// Format: http(s)://host:port/live/user/pass/streamId.ext
  String buildStreamUrl({
    required String serverUrl,
    required String username,
    required String password,
    required int streamId,
    int? portOverride,
    String extension = 'ts',
  }) {
    final baseUrl = _buildBaseUrl(serverUrl, portOverride);
    return '$baseUrl/live/$username/$password/$streamId.$extension';
  }

  /// Builds the stream URL for a VOD (movie).
  ///
  /// Format: http(s)://host:port/movie/user/pass/streamId.ext
  String buildVodStreamUrl({
    required String serverUrl,
    required String username,
    required String password,
    required int streamId,
    int? portOverride,
    String extension = 'mp4',
  }) {
    final baseUrl = _buildBaseUrl(serverUrl, portOverride);
    return '$baseUrl/movie/$username/$password/$streamId.$extension';
  }

  /// Builds the stream URL for a series episode.
  ///
  /// Format: http(s)://host:port/series/user/pass/episodeId.ext
  String buildSeriesStreamUrl({
    required String serverUrl,
    required String username,
    required String password,
    required String episodeId,
    int? portOverride,
    String extension = 'mp4',
  }) {
    final baseUrl = _buildBaseUrl(serverUrl, portOverride);
    return '$baseUrl/series/$username/$password/$episodeId.$extension';
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Private Helpers
  // ───────────────────────────────────────────────────────────────────────────

  /// GET that optionally opts the request host into invalid-certificate
  /// acceptance (per-source opt-in, ADR-005). The opt-in is scoped to the
  /// request and removed afterwards.
  Future<Result<Response<T>>> _get<T>(
    String url, {
    bool allowInsecureCertificates = false,
    Options? options,
  }) async {
    if (!allowInsecureCertificates) {
      return _client.get<T>(url, options: options);
    }
    _client.allowInsecureFor(url);
    try {
      return await _client.get<T>(url, options: options);
    } finally {
      _client.disallowInsecureFor(url);
    }
  }

  /// Fetches a large list endpoint, decoding and mapping the raw JSON
  /// body outside the main thread.
  Future<Result<List<T>>> _fetchList<T>(
    String url, {
    required T Function(Map<String, dynamic>) parseItem,
    required String parseErrorMessage,
    bool allowInsecureCertificates = false,
  }) async {
    final response = await _get<String>(
      url,
      allowInsecureCertificates: allowInsecureCertificates,
      options: Options(responseType: ResponseType.plain),
    );

    return await response.when(
      success: (res) async {
        final raw = res.data;
        if (raw == null || raw.isEmpty) return const Success([]);

        try {
          final items = await parseInIsolate(raw, (String body) {
            final decoded = jsonDecode(body);
            if (decoded is! List) {
              throw const FormatException('Resposta não é uma lista.');
            }
            return decoded.cast<Map<String, dynamic>>().map(parseItem).toList();
          });
          return Success(items);
        } catch (e) {
          return Failure(
            PlaylistParseFailure(
              message: parseErrorMessage,
              originalError: e,
            ),
          );
        }
      },
      failure: (f) => Failure(f),
    );
  }

  /// Generic category fetcher (all category endpoints share the same format).
  Future<Result<List<XtreamCategory>>> _fetchCategories({
    required String serverUrl,
    required String username,
    required String password,
    required String action,
    int? portOverride,
    bool allowInsecureCertificates = false,
  }) async {
    final baseUrl = _buildBaseUrl(serverUrl, portOverride);
    final url = '$baseUrl/player_api.php'
        '?username=$username&password=$password'
        '&action=$action';

    final response = await _get<List<dynamic>>(
      url,
      allowInsecureCertificates: allowInsecureCertificates,
    );

    return response.when(
      success: (res) {
        final data = res.data;
        if (data == null) return const Success([]);

        try {
          final categories = data
              .cast<Map<String, dynamic>>()
              .map(XtreamCategory.fromJson)
              .toList();
          return Success(categories);
        } catch (e) {
          return Failure(
            PlaylistParseFailure(
              message: 'Erro ao interpretar categorias.',
              originalError: e,
            ),
          );
        }
      },
      failure: (f) => Failure(f),
    );
  }

  /// Builds the base URL with optional port override.
  String _buildBaseUrl(String serverUrl, int? portOverride) {
    var url = serverUrl.trim().normalizeServerUrl();

    // Apply port override if provided
    if (portOverride != null) {
      final uri = Uri.tryParse(url);
      if (uri != null) {
        url = uri.replace(port: portOverride).toString();
      }
    }

    return url;
  }
}
