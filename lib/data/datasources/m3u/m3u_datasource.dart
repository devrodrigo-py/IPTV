import 'dart:io';

import 'package:nebula_iptv/core/errors/app_failure.dart';
import 'package:nebula_iptv/core/network/dio_client.dart';
import 'package:nebula_iptv/core/result/result.dart';
import 'package:nebula_iptv/data/datasources/m3u/m3u_parser.dart';

/// Data source responsible for fetching and parsing M3U playlists.
///
/// Supports fetching from URL or reading from a local file.
class M3uDataSource {
  final DioClient _client;
  final M3uParser _parser;

  M3uDataSource({
    required DioClient client,
    M3uParser parser = const M3uParser(),
  })  : _client = client,
        _parser = parser;

  /// Fetches and parses an M3U playlist from a URL.
  Future<Result<M3uParseResult>> fetchFromUrl(String url) async {
    final response = await _client.get<String>(url);

    return response.when(
      success: (res) {
        final content = res.data;
        if (content == null || content.isEmpty) {
          return const Failure(
            PlaylistParseFailure(message: 'A playlist está vazia.'),
          );
        }

        try {
          final result = _parser.parse(content);
          if (result.entries.isEmpty) {
            return const Failure(
              PlaylistParseFailure(
                message: 'Nenhum canal encontrado na playlist.',
              ),
            );
          }
          return Success(result);
        } catch (e) {
          return Failure(
            PlaylistParseFailure(
              message: 'Erro ao interpretar a playlist.',
              originalError: e,
            ),
          );
        }
      },
      failure: (f) => Failure(f),
    );
  }

  /// Parses an M3U playlist from a local file path.
  Future<Result<M3uParseResult>> readFromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        return const Failure(
          PlaylistParseFailure(message: 'Arquivo não encontrado.'),
        );
      }

      final content = await file.readAsString();
      if (content.isEmpty) {
        return const Failure(
          PlaylistParseFailure(message: 'O arquivo está vazio.'),
        );
      }

      final result = _parser.parse(content);
      if (result.entries.isEmpty) {
        return const Failure(
          PlaylistParseFailure(
            message: 'Nenhum canal encontrado no arquivo.',
          ),
        );
      }
      return Success(result);
    } on FileSystemException catch (e) {
      return Failure(
        PlaylistParseFailure(
          message: 'Erro ao ler o arquivo.',
          originalError: e,
        ),
      );
    }
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
}
