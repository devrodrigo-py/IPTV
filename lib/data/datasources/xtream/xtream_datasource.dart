import 'package:nebula_iptv/core/errors/app_failure.dart';
import 'package:nebula_iptv/core/network/dio_client.dart';
import 'package:nebula_iptv/core/result/result.dart';
import 'package:nebula_iptv/data/datasources/xtream/xtream_models.dart';

/// Data source for Xtream Codes API interactions.
///
/// Handles authentication, fetching categories, and live streams
/// via the player_api.php endpoint (spec §12).
class XtreamDataSource {
  final DioClient _client;

  XtreamDataSource({required DioClient client}) : _client = client;

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
  }) async {
    final baseUrl = _buildBaseUrl(serverUrl, portOverride);
    final url = '$baseUrl/player_api.php'
        '?username=$username&password=$password';

    final response = await _client.get<Map<String, dynamic>>(url);

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

  /// Fetches live stream categories.
  Future<Result<List<XtreamCategory>>> getLiveCategories({
    required String serverUrl,
    required String username,
    required String password,
    int? portOverride,
  }) async {
    final baseUrl = _buildBaseUrl(serverUrl, portOverride);
    final url = '$baseUrl/player_api.php'
        '?username=$username&password=$password'
        '&action=get_live_categories';

    final response = await _client.get<List<dynamic>>(url);

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

  /// Fetches live streams (all or by category).
  Future<Result<List<XtreamLiveStream>>> getLiveStreams({
    required String serverUrl,
    required String username,
    required String password,
    int? portOverride,
    String? categoryId,
  }) async {
    final baseUrl = _buildBaseUrl(serverUrl, portOverride);
    var url = '$baseUrl/player_api.php'
        '?username=$username&password=$password'
        '&action=get_live_streams';

    if (categoryId != null && categoryId.isNotEmpty) {
      url += '&category_id=$categoryId';
    }

    final response = await _client.get<List<dynamic>>(url);

    return response.when(
      success: (res) {
        final data = res.data;
        if (data == null) return const Success([]);

        try {
          final streams = data
              .cast<Map<String, dynamic>>()
              .map(XtreamLiveStream.fromJson)
              .toList();
          return Success(streams);
        } catch (e) {
          return Failure(
            PlaylistParseFailure(
              message: 'Erro ao interpretar lista de canais.',
              originalError: e,
            ),
          );
        }
      },
      failure: (f) => Failure(f),
    );
  }

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

  /// Builds the base URL with optional port override.
  String _buildBaseUrl(String serverUrl, int? portOverride) {
    var url = serverUrl.trim();
    // Remove trailing slash
    if (url.endsWith('/')) url = url.substring(0, url.length - 1);

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
