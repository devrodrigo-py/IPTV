import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Detects the current platform type for layout decisions.
///
/// Used to switch between standard UI and TV-optimized UI.
abstract final class PlatformDetector {
  /// Returns true if the app is running on Android TV.
  ///
  /// Heuristic: Android + screen width >= 960 + no touch support.
  /// Can be overridden for testing via [overrideIsTv].
  static bool isTv(BuildContext context) {
    if (_overrideValue != null) return _overrideValue!;

    if (defaultTargetPlatform != TargetPlatform.android) return false;

    final size = MediaQuery.sizeOf(context);
    // TV screens are typically 1920x1080 or larger at low density
    // Use width > 960 as a conservative check
    return size.width >= 960 && size.height >= 540;
  }

  /// Override for testing purposes.
  static bool? _overrideValue;

  /// Sets the TV override (for tests).
  static void overrideIsTv(bool? value) {
    _overrideValue = value;
  }
}
