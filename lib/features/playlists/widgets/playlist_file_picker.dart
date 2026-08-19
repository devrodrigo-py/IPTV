import 'package:file_picker/file_picker.dart';
import 'package:nebula_iptv/core/errors/app_failure.dart';
import 'package:nebula_iptv/core/result/result.dart';

/// Cross-platform file picker for M3U playlist import.
///
/// Works on web, desktop, and mobile. On web, opens the browser's
/// native file picker dialog. Returns the file content as a String.
class PlaylistFilePicker {
  /// Opens a file picker dialog for M3U files.
  /// Returns the file content as a String, or a Failure.
  Future<Result<FilePickResult>> pickPlaylistFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['m3u', 'm3u8', 'txt'],
        withData: true, // Required for web (no file path access)
      );

      if (result == null || result.files.isEmpty) {
        return const Failure(
          PlaylistParseFailure(message: 'Nenhum arquivo selecionado.'),
        );
      }

      final file = result.files.first;

      // On web, we get bytes. On native, we might get a path.
      String content;
      if (file.bytes != null) {
        content = String.fromCharCodes(file.bytes!);
      } else {
        return const Failure(
          PlaylistParseFailure(
            message: 'Não foi possível ler o arquivo.',
          ),
        );
      }

      if (content.isEmpty) {
        return const Failure(
          PlaylistParseFailure(message: 'O arquivo está vazio.'),
        );
      }

      return Success(FilePickResult(
        content: content,
        fileName: file.name,
      ));
    } catch (e) {
      return Failure(
        PlaylistParseFailure(
          message: 'Erro ao selecionar arquivo.',
          originalError: e,
        ),
      );
    }
  }
}

/// Result from picking a file.
class FilePickResult {
  final String content;
  final String fileName;

  const FilePickResult({
    required this.content,
    required this.fileName,
  });
}
