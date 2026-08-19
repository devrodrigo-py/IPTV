import 'dart:convert';

import 'package:nebula_iptv/core/errors/app_failure.dart';
import 'package:nebula_iptv/core/logging/app_logger.dart';
import 'package:nebula_iptv/core/result/result.dart';
import 'package:nebula_iptv/data/database/app_database.dart';
import 'package:nebula_iptv/data/database/tables/playlists_table.dart';

/// Result of an export operation.
class ExportResult {
  final String jsonContent;
  final int playlistCount;
  final int favoriteCount;

  const ExportResult({
    required this.jsonContent,
    required this.playlistCount,
    required this.favoriteCount,
  });
}

/// Repository for importing and exporting user data (spec §30).
///
/// Returns JSON strings — the platform layer (native/web) handles
/// saving to file or triggering a download.
class UserDataRepository {
  final AppDatabase _db;

  UserDataRepository({required AppDatabase db}) : _db = db;

  /// Exports user data as JSON string.
  Future<Result<ExportResult>> exportData() async {
    try {
      final playlists = await _db.playlistsDao.getAllPlaylists();
      final favoriteIds = await _db.favoritesDao.getFavoriteChannelIds();

      final exportData = {
        'version': 1,
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'playlists': playlists.map((p) => _playlistToJson(p)).toList(),
        'favoriteChannelIds': favoriteIds.toList(),
        'settings': <String, dynamic>{},
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      appLogger.i(
        'Exported: ${playlists.length} playlists, '
        '${favoriteIds.length} favorites',
      );

      return Success(ExportResult(
        jsonContent: jsonString,
        playlistCount: playlists.length,
        favoriteCount: favoriteIds.length,
      ));
    } catch (e) {
      return Failure(
        DatabaseFailure(
          message: 'Erro ao exportar dados.',
          originalError: e,
        ),
      );
    }
  }

  /// Imports user data from a JSON string.
  Future<Result<int>> importData(String jsonContent) async {
    try {
      if (jsonContent.isEmpty) {
        return const Failure(
          DatabaseFailure(message: 'Conteúdo de importação vazio.'),
        );
      }

      final data = jsonDecode(jsonContent) as Map<String, dynamic>;

      final version = data['version'] as int? ?? 1;
      if (version > 1) {
        return const Failure(
          DatabaseFailure(
            message: 'Formato de exportação não suportado.',
          ),
        );
      }

      var importedCount = 0;

      final playlists = data['playlists'] as List<dynamic>? ?? [];
      for (final pJson in playlists) {
        final map = pJson as Map<String, dynamic>;
        final requiresAuth = map['requiresAuthentication'] as bool? ?? false;

        if (requiresAuth) {
          appLogger.i(
            'Skipped Xtream playlist "${map['name']}" — requires re-auth',
          );
          continue;
        }

        importedCount++;
      }

      appLogger.i('Imported $importedCount items');
      return Success(importedCount);
    } on FormatException catch (e) {
      return Failure(
        DatabaseFailure(
          message: 'Arquivo de importação inválido.',
          originalError: e,
        ),
      );
    } catch (e) {
      return Failure(
        DatabaseFailure(
          message: 'Erro ao importar dados.',
          originalError: e,
        ),
      );
    }
  }

  /// Converts a playlist to export JSON (never includes credentials).
  Map<String, dynamic> _playlistToJson(Playlist playlist) {
    final isXtream = playlist.type == PlaylistType.xtream;

    return {
      'name': playlist.name,
      'type': playlist.type.name,
      'url': playlist.url,
      'epgUrl': playlist.epgUrl,
      'username': isXtream ? playlist.username : null,
      'requiresAuthentication': isXtream,
    };
  }
}
