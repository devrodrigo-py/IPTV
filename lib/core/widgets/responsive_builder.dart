import 'package:flutter/material.dart';
import 'package:nebula_iptv/core/constants/app_constants.dart';

/// Enum representing the current layout breakpoint.
enum LayoutType { mobile, tablet, desktop }

/// Builds different widgets based on the current screen size.
///
/// Provides responsive layout without requiring manual MediaQuery
/// calls in every widget.
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context) mobile;
  final Widget Function(BuildContext context)? tablet;
  final Widget Function(BuildContext context)? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  /// Returns the current [LayoutType] based on screen width.
  static LayoutType layoutType(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= AppConstants.tabletMaxWidth) return LayoutType.desktop;
    if (width >= AppConstants.mobileMaxWidth) return LayoutType.tablet;
    return LayoutType.mobile;
  }

  @override
  Widget build(BuildContext context) {
    final type = layoutType(context);

    return switch (type) {
      LayoutType.desktop => (desktop ?? tablet ?? mobile)(context),
      LayoutType.tablet => (tablet ?? mobile)(context),
      LayoutType.mobile => mobile(context),
    };
  }
}
