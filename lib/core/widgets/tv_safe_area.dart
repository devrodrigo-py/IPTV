import 'package:flutter/widgets.dart';
import 'package:nebula_iptv/core/utils/platform_detector.dart';

class TvSafeArea extends StatelessWidget {
  final Widget child;
  const TvSafeArea({super.key, required this.child});

  static EdgeInsets paddingOf(BuildContext context) {
    if (!PlatformDetector.isTv(context)) return EdgeInsets.zero;
    final size = MediaQuery.sizeOf(context);
    return EdgeInsets.symmetric(
        horizontal: size.width * .035, vertical: size.height * .04);
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        minimum: paddingOf(context),
        child: child,
      );
}
