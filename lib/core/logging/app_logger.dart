import 'dart:convert';
import 'package:logger/logger.dart';

/// URLs may embed provider credentials in their path as well as their query.
String sanitizeLogMessage(Object? value) => value.toString()
    .replaceAll(RegExp(r'https?://[^\s\)\]\}]+'), '[url redacted]')
    .replaceAll(RegExp(r'(password|username|token|authorization)\s*[:=]\s*[^\s,;]+',
      caseSensitive: false), '[credential redacted]');

final appLogger = Logger(filter: _AppLogFilter(), printer: StructuredLogPrinter());

class StructuredLogPrinter extends LogPrinter {
  @override
  List<String> log(LogEvent event) => [jsonEncode({
    'timestamp': event.time.toUtc().toIso8601String(),
    'level': event.level.name,
    'message': sanitizeLogMessage(event.message),
    if (event.error != null) 'error': sanitizeLogMessage(event.error),
    if (event.stackTrace != null) 'stack': sanitizeLogMessage(event.stackTrace),
  })];
}

class _AppLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    const release = bool.fromEnvironment('dart.vm.product');
    return !release || event.level.index >= Level.warning.index;
  }
}
