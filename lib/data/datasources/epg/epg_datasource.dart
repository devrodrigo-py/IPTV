import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:nebula_iptv/core/errors/app_failure.dart';
import 'package:nebula_iptv/core/network/dio_client.dart';
import 'package:nebula_iptv/core/result/result.dart';
import 'package:nebula_iptv/core/utils/isolate_parse.dart';
import 'package:nebula_iptv/data/datasources/epg/xmltv_parser.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Data source for fetching and parsing EPG/XMLTV data.
///
/// Native: download em streaming para arquivo temporário e parse DENTRO do
/// isolate lendo o arquivo — o corpo (dezenas de MB, spec §31) nunca vive
/// inteiro na RAM do isolate principal (foi canditado a travar/crashar
/// dispositivos fracos). Web mantém o caminho por string (sem FS).
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
    if (kIsWeb) return _fetchViaString(url);
    return _fetchViaTempFile(url);
  }

  Future<Result<XmltvParseResult>> _fetchViaTempFile(String url) async {
    final Directory tempDir;
    try {
      tempDir = await getTemporaryDirectory();
    } catch (e) {
      // Sem storage: cai para o caminho por string.
      return _fetchViaString(url);
    }

    final tmpFile = File(p.join(
        tempDir.path, 'epg_${DateTime.now().millisecondsSinceEpoch}.xml'));
    try {
      final download = await _client.download(url, tmpFile.path);
      return await download.when(
        success: (_) async {
          if (!tmpFile.existsSync() || tmpFile.lengthSync() == 0) {
            return const Failure(EpgParseFailure(message: 'EPG vazio.'));
          }

          try {
            // Capture only the parser — tocar estado da instância capturaria
            // `this` (e o DioClient), que não cruza fronteira de isolate.
            final parser = _parser;
            final result = await parseInIsolate(
              tmpFile.path,
              (String path) => parser.parse(File(path).readAsStringSync()),
            );
            return _validate(result);
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
    } finally {
      if (tmpFile.existsSync()) {
        try {
          tmpFile.deleteSync();
        } catch (_) {}
      }
    }
  }

  /// Caminho legado (web / fallback sem FS): corpo inteiro como string.
  Future<Result<XmltvParseResult>> _fetchViaString(String url) async {
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
          final parser = _parser;
          final result = await parseInIsolate(
            content,
            (String c) => parser.parse(c),
          );
          return _validate(result);
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

  Result<XmltvParseResult> _validate(XmltvParseResult result) {
    if (result.programs.isEmpty) {
      return const Failure(
        EpgParseFailure(
          message: 'Nenhum programa encontrado no EPG.',
        ),
      );
    }
    return Success(result);
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
