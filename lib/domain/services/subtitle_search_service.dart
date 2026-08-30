import 'dart:io';

import 'package:dio/dio.dart';
import 'package:nebula_iptv/core/logging/app_logger.dart';
import 'package:path_provider/path_provider.dart';

class SubtitleResult {
  final String id;
  final String title;
  final String language;
  final String downloadUrl;
  final String? release;

  const SubtitleResult({
    required this.id,
    required this.title,
    required this.language,
    required this.downloadUrl,
    this.release,
  });
}

/// Service that searches for Portuguese and multi-language subtitles online.
///
/// Uses the OpenSubtitles REST API v1.
/// Ships with a default API key; users can override it via Settings.
class SubtitleSearchService {
  final Dio _dio;

  /// Default API key (NebulaIPTV consumer registered at opensubtitles.com)
  static const String _defaultApiKey = 'XoI4pKpfwxH9yxNpH7HLiltx34FaF380';

  SubtitleSearchService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                headers: {
                  'User-Agent': 'NebulaIPTV v1.0',
                  'Accept': 'application/json',
                },
              ),
            );

  /// Returns the path to the API key override file.
  static Future<File> _keyFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/opensubtitles_api_key.txt');
  }

  /// Gets the active API key. Returns custom key if set, otherwise default.
  static Future<String> getApiKey() async {
    try {
      final file = await _keyFile();
      if (file.existsSync()) {
        final custom = (await file.readAsString()).trim();
        if (custom.isNotEmpty) return custom;
      }
    } catch (e) {
      // Leitura best-effort: cai para a chave padrão, mas registra a causa.
      appLogger.d('[Subtitle] Falha ao ler chave de API customizada: $e');
    }
    return _defaultApiKey;
  }

  /// Saves a custom API key (overrides the default).
  static Future<void> saveApiKey(String apiKey) async {
    final file = await _keyFile();
    await file.writeAsString(apiKey.trim());
  }

  /// Removes the custom API key (reverts to default).
  static Future<void> clearApiKey() async {
    final file = await _keyFile();
    if (file.existsSync()) {
      await file.delete();
    }
  }

  /// Gets the saved custom key (null if using default).
  static Future<String?> getSavedApiKey() async {
    try {
      final file = await _keyFile();
      if (file.existsSync()) {
        final custom = (await file.readAsString()).trim();
        if (custom.isNotEmpty) return custom;
      }
    } catch (e) {
      // Leitura best-effort: sem chave salva é um estado válido, mas a
      // causa da falha deve ficar registrada.
      appLogger.d('[Subtitle] Falha ao ler chave de API salva: $e');
    }
    return null;
  }

  /// Searches for online subtitles by query and language.
  Future<List<SubtitleResult>> searchSubtitles({
    required String query,
    String language = 'pt-br',
    int? seasonNumber,
    int? episodeNumber,
  }) async {
    final results = <SubtitleResult>[];

    final apiKey = await getApiKey();

    try {
      // Clean query string (remove extra file extensions or tags)
      String cleanQuery = query
          .replaceAll(
            RegExp(
              r'\b(1080p|720p|4k|2160p|bluray|web-dl|x264|x265|hevc|aac|dual)\b',
              caseSensitive: false,
            ),
            '',
          )
          .replaceAll(RegExp(r'[._-]'), ' ')
          .trim();

      if (seasonNumber != null && episodeNumber != null) {
        final s = seasonNumber.toString().padLeft(2, '0');
        final e = episodeNumber.toString().padLeft(2, '0');
        cleanQuery = '$cleanQuery S${s}E$e';
      }

      appLogger.d(
        '[Subtitle] Searching online subtitles for: "$cleanQuery" ($language)',
      );

      // Query OpenSubtitles public API v1
      final response = await _dio.get(
        'https://api.opensubtitles.com/api/v1/subtitles',
        queryParameters: {
          'query': cleanQuery,
          'languages': language == 'pt-br' ? 'pt-BR,pt,por' : language,
        },
        options: Options(
          headers: {
            'Api-Key': apiKey,
          },
        ),
      );

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data['data'] as List?;
        if (data != null) {
          for (final item in data) {
            final attrs = item['attributes'] as Map<String, dynamic>?;
            if (attrs != null) {
              final files = attrs['files'] as List?;
              final fileId = files != null && files.isNotEmpty
                  ? files[0]['file_id']
                  : null;
              final release = attrs['release'] as String? ??
                  attrs['feature_details']?['title'] as String? ??
                  cleanQuery;
              final lang = attrs['language'] as String? ?? 'pt-br';

              if (fileId != null) {
                results.add(
                  SubtitleResult(
                    id: item['id']?.toString() ?? fileId.toString(),
                    title: release,
                    language: lang.toUpperCase(),
                    downloadUrl:
                        'https://api.opensubtitles.com/api/v1/download',
                    release: release,
                  ),
                );
              }
            }
          }
        }
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        appLogger.w('[Subtitle] OpenSubtitles API key is invalid or expired.');
      } else {
        appLogger.w('[Subtitle] Subtitle search failed: $e');
      }
    } catch (e) {
      appLogger.w('[Subtitle] Subtitle search failed or returned empty: $e');
    }

    return results;
  }
}
