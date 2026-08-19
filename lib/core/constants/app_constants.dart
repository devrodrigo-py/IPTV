/// Application-wide constants.
///
/// Centralizes magic numbers and configuration values.
abstract final class AppConstants {
  /// Application name.
  static const appName = 'Nebula IPTV';

  /// Application version.
  static const appVersion = '0.1.0';

  // --- Breakpoints ---
  static const mobileMaxWidth = 600.0;
  static const tabletMaxWidth = 1024.0;

  // --- Network ---
  static const defaultConnectTimeout = Duration(seconds: 15);
  static const defaultReceiveTimeout = Duration(seconds: 30);
  static const defaultSendTimeout = Duration(seconds: 15);
}
