import 'package:flutter/material.dart';
import 'package:nebula_iptv/core/constants/app_constants.dart';
import 'package:nebula_iptv/l10n/app_localizations.dart';

/// Convenience extensions on [BuildContext].
extension ContextExtensions on BuildContext {
  /// Access the current [ThemeData].
  ThemeData get theme => Theme.of(this);

  /// Access the current [ColorScheme].
  ColorScheme get colorScheme => theme.colorScheme;

  /// Access the current [TextTheme].
  TextTheme get textTheme => theme.textTheme;

  /// Access localized strings.
  AppLocalizations get l10n => AppLocalizations.of(this)!;

  /// Current screen width.
  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// Current screen height.
  double get screenHeight => MediaQuery.sizeOf(this).height;

  /// Whether the current layout is mobile-sized.
  bool get isMobile => screenWidth < AppConstants.mobileMaxWidth;

  /// Whether the current layout is tablet-sized.
  bool get isTablet =>
      screenWidth >= AppConstants.mobileMaxWidth &&
      screenWidth < AppConstants.tabletMaxWidth;

  /// Whether the current layout is desktop-sized.
  bool get isDesktop => screenWidth >= AppConstants.tabletMaxWidth;
}
