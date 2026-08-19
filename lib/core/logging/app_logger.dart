import 'package:logger/logger.dart';

/// Application-wide logger instance.
///
/// Uses the `logger` package with a filter that disables verbose logs
/// in release builds.
final appLogger = Logger(
  filter: _AppLogFilter(),
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 5,
    lineLength: 80,
    colors: true,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
);

/// Custom log filter: in release mode, only warnings and above are shown.
class _AppLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    // In debug mode, show all logs.
    // In release mode, show only warning and above.
    const isRelease = bool.fromEnvironment('dart.vm.product');
    if (isRelease) {
      return event.level.index >= Level.warning.index;
    }
    return true;
  }
}
