import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:nebula_iptv/core/logging/app_logger.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Singleton global — os handlers de erro do main.dart e o bootstrap
/// compartilham a mesma instância.
final crashLog = CrashLogService();

/// Persiste erros/crashes em arquivo local para diagnóstico pós-mortem.
///
/// Não há telemetria de rede no app — este log é o destino dos handlers de
/// erro do [main]. Recuperação: `adb pull` do arquivo (caminho logado no
/// boot) ou cópia manual em desktop. Rotação: mantém as últimas [maxLines]
/// linhas; um crash nunca deve encher o disco.
class CrashLogService {
  static const _fileName = 'crash_log.txt';
  static const _maxLines = 2000;

  File? _file;
  bool _failedOnce = false;

  /// Inicializa o arquivo (best-effort — sem storage disponível, vira no-op).
  Future<void> init() async {
    if (kIsWeb) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final logDir = Directory(p.join(dir.path, 'nebula_iptv'));
      if (!logDir.existsSync()) logDir.createSync(recursive: true);
      _file = File(p.join(logDir.path, _fileName));
      appLogger.i('[CrashLog] ${_file!.path}');
    } catch (e) {
      _file = null;
      appLogger.w('[CrashLog] Indisponível: $e');
    }
  }

  /// Anexa uma entrada com timestamp. Nunca lança — é o último recurso.
  void write(String message, {Object? error, StackTrace? stackTrace}) {
    if (_file == null || _failedOnce) return;
    try {
      final buffer = StringBuffer()
        ..writeln('=== ${DateTime.now().toIso8601String()} ===')
        ..writeln(message);
      if (error != null) buffer.writeln('error: $error');
      if (stackTrace != null) {
        buffer.writeln(
          stackTrace.toString().length > 4000
              ? stackTrace.toString().substring(0, 4000)
              : stackTrace.toString(),
        );
      }
      buffer.writeln();

      _rotateIfLarge();
      _file!.writeAsStringSync(buffer.toString(),
          mode: FileMode.append, flush: false);
    } catch (e) {
      _failedOnce = true;
      debugPrint('[CrashLog] falhou e foi desativado: $e');
    }
  }

  void _rotateIfLarge() {
    try {
      if (!_file!.existsSync()) return;
      final lines = _file!.readAsLinesSync();
      if (lines.length > _maxLines) {
        _file!.writeAsStringSync(
          lines.skip(lines.length - _maxLines ~/ 2).join('\n'),
        );
      }
    } catch (_) {
      // Rotação é opcional; a escrita tentará de novo na próxima entrada.
    }
  }
}
