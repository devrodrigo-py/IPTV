import 'package:nebula_iptv/core/errors/app_failure.dart';
import 'package:nebula_iptv/core/network/dio_client.dart';
import 'package:nebula_iptv/core/result/result.dart';
import 'package:nebula_iptv/core/utils/isolate_parse.dart';
import 'package:nebula_iptv/core/utils/url_normalization.dart';
import 'package:nebula_iptv/data/datasources/m3u/m3u_parser.dart';

/// Data source responsible for fetching and parsing M3U playlists.
///
/// Supports fetching from URL. File import is available only on
/// native platforms (handled by the UI layer).
///
/// Parsing runs outside the main thread (spec §31 — large playlists
/// must not block the UI).
class M3uDataSource {
  final DioClient _client;
  final M3uParser _parser;

  M3uDataSource({
    required DioClient client,
    M3uParser parser = const M3uParser(),
  })  : _client = client,
        _parser = parser;

  /// Fetches and parses an M3U playlist from a URL.
  Future<Result<M3uParseResult>> fetchFromUrl(
    String url, {
    bool allowInsecureCertificates = false,
  }) async {
    final normalizedUrl = url.trim().normalizeServerUrl();
    if (allowInsecureCertificates) _client.allowInsecureFor(normalizedUrl);
    try {
      final response = await _client.get<String>(normalizedUrl);

      return await response.when(
        success: (res) async {
          final content = res.data;
          if (content == null || content.isEmpty) {
            return const Failure(
              PlaylistParseFailure(message: 'A playlist está vazia.'),
            );
          }

          return _parseAndValidate(
            content,
            emptyMessage: 'Nenhum canal encontrado na playlist.',
            errorMessage: 'Erro ao interpretar a playlist.',
          );
        },
        failure: (f) => Failure(f),
      );
    } finally {
      if (allowInsecureCertificates) _client.disallowInsecureFor(normalizedUrl);
    }
  }

  /// Parses an M3U playlist from file content (platform-agnostic).
  Future<Result<M3uParseResult>> readFromContent(String content) async {
    if (content.isEmpty) {
      return const Failure(
        PlaylistParseFailure(message: 'O arquivo está vazio.'),
      );
    }

    return _parseAndValidate(
      content,
      emptyMessage: 'Nenhum canal encontrado no arquivo.',
      errorMessage: 'Erro ao interpretar o conteúdo.',
    );
  }

  /// Parses raw M3U content directly (useful for testing).
  Result<M3uParseResult> parseContent(String content) {
    if (content.isEmpty) {
      return const Failure(
        PlaylistParseFailure(message: 'Conteúdo vazio.'),
      );
    }

    try {
      final result = _parser.parse(content);
      if (result.entries.isEmpty) {
        return const Failure(
          PlaylistParseFailure(message: 'Nenhum canal encontrado.'),
        );
      }
      return Success(result);
    } catch (e) {
      return Failure(
        PlaylistParseFailure(
          message: 'Erro ao interpretar o conteúdo.',
          originalError: e,
        ),
      );
    }
  }

  /// Runs the parser off the main thread and validates the outcome.
  Future<Result<M3uParseResult>> _parseAndValidate(
    String content, {
    required String emptyMessage,
    required String errorMessage,
  }) async {
    try {
      // Capture only the parser — a closure that touches instance state
      // would implicitly capture `this` (and the DioClient it holds),
      // which cannot cross an isolate boundary.
      final parser = _parser;
      final result = await parseInIsolate(
        content,
        (String c) => parser.parse(c),
      );
      if (result.entries.isEmpty) {
        return Failure(PlaylistParseFailure(message: emptyMessage));
      }
      return Success(result);
    } catch (e) {
      return Failure(
        PlaylistParseFailure(message: errorMessage, originalError: e),
      );
    }
  }
}
