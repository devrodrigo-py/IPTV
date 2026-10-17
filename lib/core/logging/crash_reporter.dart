/// Inject a Sentry/Crashlytics adapter at the composition root if desired.
/// No adapter is installed and no network telemetry is sent by default.
abstract interface class CrashReporter {
  Future<void> report({required String message, String? error, String? stackTrace});
}
