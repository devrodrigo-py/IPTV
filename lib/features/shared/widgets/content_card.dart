import 'package:flutter/material.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';
import 'package:nebula_iptv/core/theme/app_typography.dart';
import 'package:nebula_iptv/core/widgets/focusable_widget.dart';
import 'package:nebula_iptv/core/widgets/nebula_cached_image.dart';

/// One action, one focus node. Fixed geometry keeps focus and scroll stable.
class ContentCard extends StatelessWidget {
  final String title;
  final String? imageUrl, subtitle, badge;
  final double? progress;
  final IconData fallbackIcon;
  final VoidCallback? onTap;
  final double width;
  final FocusNode? focusNode;
  final String? heroTag;
  final void Function(Offset position)? onSecondaryTap;
  const ContentCard(
      {super.key,
      required this.title,
      this.imageUrl,
      this.subtitle,
      this.progress,
      this.badge,
      this.fallbackIcon = Icons.movie_rounded,
      this.onTap,
      this.width = 140,
      this.focusNode,
      this.heroTag,
      this.onSecondaryTap});

  @override
  Widget build(BuildContext context) {
    void openMenu() {
      final box = context.findRenderObject() as RenderBox?;
      if (box != null) {
        onSecondaryTap?.call(box.localToGlobal(box.size.center(Offset.zero)));
      }
    }

    final poster = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: NebulaCachedImage(
            imageUrl: imageUrl,
            width: width,
            height: width * 1.5,
            fit: BoxFit.cover,
            cacheWidth:
                (width * MediaQuery.devicePixelRatioOf(context)).round(),
            placeholder: ColoredBox(
                color: AppColors.surfaceElevated,
                child: Center(
                    child:
                        Icon(fallbackIcon, size: 40, color: Colors.white24)))));
    return RepaintBoundary(
        child: SizedBox(
            width: width,
            child: GestureDetector(
                onSecondaryTapUp: onSecondaryTap == null
                    ? null
                    : (event) => onSecondaryTap!(event.globalPosition),
                child: FocusableWidget(
                    focusNode: focusNode,
                    canRequestFocus: onTap != null,
                    onPressed: onTap,
                    onLongPress: onSecondaryTap == null ? null : openMenu,
                    decorateFocus: false,
                    builder: (context, focused) => AnimatedScale(
                        scale: focused ? 1.035 : 1,
                        duration: const Duration(milliseconds: 130),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                  height: width * 1.5,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: focused
                                              ? Colors.white
                                              : Colors.transparent,
                                          width: 3)),
                                  child: Stack(fit: StackFit.expand, children: [
                                    if (heroTag != null)
                                      Hero(tag: heroTag!, child: poster)
                                    else
                                      poster,
                                    if (badge != null)
                                      Positioned(
                                          top: 8,
                                          left: 8,
                                          child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                  color: AppColors.background,
                                                  borderRadius:
                                                      BorderRadius.circular(4)),
                                              child: Text(badge!,
                                                  style: AppTypography.caption
                                                      .copyWith(
                                                          color:
                                                              Colors.white)))),
                                    if (progress != null)
                                      Positioned(
                                          left: 0,
                                          right: 0,
                                          bottom: 0,
                                          child: LinearProgressIndicator(
                                              value: progress!.clamp(0, 1),
                                              minHeight: 4,
                                              backgroundColor: Colors.white24,
                                              color: AppColors.primary)),
                                  ])),
                              const SizedBox(height: 10),
                              Text(title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.body.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: focused
                                          ? Colors.white
                                          : AppColors.textPrimary)),
                              if (subtitle != null)
                                Text(subtitle!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.caption
                                        .copyWith(fontSize: 12)),
                            ]))))));
  }
}
