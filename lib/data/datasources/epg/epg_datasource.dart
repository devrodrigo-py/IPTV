import 'package:nebula_iptv/core/errors/app_failure.dart';
import 'package:nebula_iptv/core/network/dio_client.dart';
import 'package:nebula_iptv/core/result/result.dart';
import 'package:nebula_iptv/core/utils/isolate_parse.dart';
import 'package:nebula_iptv/data/datasources/epg/xmltv_parser.dart';

/// Data source for fetching and parsing EPG/XMLTV data.
///
/// Parsing runs outside the main thread — XMLTV files routinely reach
/// tens of megabytes (spec §31).
class EpgDataSource {
  final DioClient _client;
  final XmltvParser _parser;

  EpgDataSource({
    required DioClient client,
    XmltvParser parser = const XmltvParser(),
  })  : _client = client,
        _parser = parser;

  /// Fetches and parses XMLTV from a URL.
  Future<Result<XmltvParseResult>> fetchEpg(String url) async {
    final response = await _client.get<String>(url);

    return await response.when(
      success: (res) async {
        final content = res.data;
        if (content == null || content.isEmpty) {
          return const Failure(
            EpgParseFailure(message: 'EPG vazio.'),
          );
        }

        try {
          // Capture only the parser — touching instance state would
          // implicitly capture `this` (and the DioClient), which cannot
          // cross an isolate boundary.
          final parser = _parser;
          final result = await parseInIsolate(
            content,
            (String c) => parser.parse(c),
          );
          if (result.programs.isEmpty) {
            return const Failure(
              EpgParseFailure(
                message: 'Nenhum programa encontrado no EPG.',
              ),
            );
          }
          return Success(result);
        } catch (e) {
          return Failure(
            EpgParseFailure(
              message: 'Erro ao interpretar o EPG.',
              originalError: e,
            ),
          );
        }
      },
      failure: (f) => Failure(f),
    );
  }

  /// Parses raw XMLTV content directly (for testing).
  Result<XmltvParseResult> parseContent(String content) {
    if (content.isEmpty) {
      return const Failure(
        EpgParseFailure(message: 'Conteúdo EPG vazio.'),
      );
    }

    try {
      final result = _parser.parse(content);
      if (result.programs.isEmpty) {
        return const Failure(
          EpgParseFailure(message: 'Nenhum programa encontrado.'),
        );
      }
      return Success(result);
    } catch (e) {
      return Failure(
        EpgParseFailure(
          message: 'Erro ao interpretar o EPG.',
          originalError: e,
        ),
      );
    }
  }
}
