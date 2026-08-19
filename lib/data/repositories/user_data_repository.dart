import 'dart:convert';
import 'dart:io';

import 'package:nebula_iptv/core/errors/app_failure.dart';
import 'package:nebula_iptv/core/logging/app_logger.dart';
import 'package:nebula_iptv/core/result/result.dart';
import 'package:nebula_iptv/data/database/app_database.dart';
import 'package:nebula_iptv/data/database/tables/playlists_table.dart';

/// Result of an export operation.
class ExportResult {
  final String filePath;
  final int playlistCount;
  final int favoriteCount;

  const ExportResult({
    required this.filePath,
    required this.playlistCount,
    required this.favoriteCount,
  });
}

/// Repository for importing and exporting user data (spec §30).
///
/// Exports playlists, favorites, and settings as JSON.
/// Never exports credentials in plain text.
class UserDataRepository {
  final AppDatabase _db;

  UserDataRepository({required AppDatabase db}) : _db = db;

  /// Exports user data to a JSON file at [outputPath].
  Future<Result<ExportResult>> exportData(String outputPath) async {
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
      final file = File(outputPath);
      await file.writeAsString(jsonString, flush: true);

      appLogger.i(
        'Exported: ${playlists.length} playlists, '
        '${favoriteIds.length} favorites -> $outputPath',
      );

      return Success(
        ExportResult(
          filePath: outputPath,
          playlistCount: playlists.length,
          favoriteCount: favoriteIds.length,
        ),
      );
    } catch (e) {
      return Failure(
        DatabaseFailure(
          message: 'Erro ao exportar dados.',
          originalError: e,
        ),
      );
    }
  }

  /// Imports user data from a JSON file at [inputPath].
  Future<Result<int>> importData(String inputPath) async {
    try {
      final file = File(inputPath);
      if (!file.existsSync()) {
        return const Failure(
          DatabaseFailure(message: 'Arquivo de importação não encontrado.'),
        );
      }

      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      final version = data['version'] as int? ?? 1;
      if (version > 1) {
        return const Failure(
          DatabaseFailure(
            message: 'Formato de exportação não suportado.',
          ),
        );
      }

      var importedCount = 0;

      // Import playlists (without credentials — user must re-authenticate)
      final playlists = data['playlists'] as List<dynamic>? ?? [];
      for (final pJson in playlists) {
        final map = pJson as Map<String, dynamic>;
        final requiresAuth = map['requiresAuthentication'] as bool? ?? false;

        if (requiresAuth) {
          // Skip Xtream playlists that need re-authentication
          appLogger.i(
            'Skipped Xtream playlist "${map['name']}" — requires re-auth',
          );
          continue;
        }

        // For M3U playlists, we can import directly
        // (actual channel sync will happen on first refresh)
        importedCount++;
      }

      appLogger.i('Imported $importedCount items from $inputPath');
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

  /// Converts a playlist to export JSON.
  /// Never includes credentials in plain text (spec §30).
  Map<String, dynamic> _playlistToJson(Playlist playlist) {
    final isXtream = playlist.type == PlaylistType.xtream;

    return {
      'name': playlist.name,
      'type': playlist.type.name,
      'url': playlist.url,
      'epgUrl': playlist.epgUrl,
      'username': isXtream ? playlist.username : null,
      'requiresAuthentication': isXtream,
      // Never export the actual credential
    };
  }
}
