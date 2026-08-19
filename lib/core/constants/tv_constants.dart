/// Constants for Android TV / large screen experience.
///
/// Designed for 10-foot viewing distance (spec §21, §26).
abstract final class TvConstants {
  /// Minimum touch target for TV (larger than mobile).
  static const double minFocusableSize = 48.0;

  /// Padding around content for overscan safety.
  static const double overscanPadding = 48.0;

  /// Card size for channel grid on TV.
  static const double tvCardWidth = 200.0;
  static const double tvCardHeight = 140.0;

  /// Spacing between grid items.
  static const double gridSpacing = 16.0;

  /// Font scale factor for TV readability.
  static const double fontScaleFactor = 1.2;

  /// Animation duration for focus transitions.
  static const Duration focusAnimationDuration = Duration(milliseconds: 200);

  /// Scale factor when item is focused.
  static const double focusedScale = 1.05;
}
