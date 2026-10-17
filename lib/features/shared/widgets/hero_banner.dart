import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';
import 'package:nebula_iptv/core/theme/app_typography.dart';
import 'package:nebula_iptv/core/widgets/focusable_widget.dart';
import 'package:nebula_iptv/core/widgets/nebula_cached_image.dart';

class HeroBannerItem {
  final String title;
  final String? subtitle, imageUrl, description, label;
  final VoidCallback? onPlay, onDetails;
  const HeroBannerItem(
      {required this.title,
      this.subtitle,
      this.imageUrl,
      this.description,
      this.label,
      this.onPlay,
      this.onDetails});
}

/// Actions participate in native traversal. The banner never consumes Back
/// or directional keys; changing the featured title is an explicit action.
class HeroBanner extends StatefulWidget {
  final List<HeroBannerItem> items;
  final double height;
  const HeroBanner({super.key, required this.items, this.height = 380});
  @override
  State<HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<HeroBanner> {
  int _index = 0;
  bool _focused = false;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 12), (_) {
      if (!mounted ||
          _focused ||
          widget.items.length < 2 ||
          MediaQuery.disableAnimationsOf(context) ||
          ModalRoute.of(context)?.isCurrent != true) {
        return;
      }
      setState(() => _index = (_index + 1) % widget.items.length);
    });
  }

  @override
  void didUpdateWidget(HeroBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_index >= widget.items.length) _index = 0;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();
    final item = widget.items[_index];
    return Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onFocusChange: (value) => _focused = value,
        child: SizedBox(
            height: widget.height,
            child: LayoutBuilder(builder: (context, constraints) {
              final compact = constraints.maxWidth < 600;
              return Stack(fit: StackFit.expand, children: [
                Positioned.fill(
                    left: compact ? 0 : constraints.maxWidth * .28,
                    child: NebulaCachedImage(
                        imageUrl: item.imageUrl,
                        fit: BoxFit.cover,
                        cacheWidth: 1280,
                        placeholder:
                            const ColoredBox(color: AppColors.surface))),
                const DecoratedBox(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                  AppColors.background,
                  Color(0xCC0A0A12),
                  Color(0x220A0A12)
                ], stops: [
                  0,
                  .45,
                  1
                ]))),
                const DecoratedBox(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                      Colors.transparent,
                      Colors.transparent,
                      AppColors.background
                    ],
                            stops: [
                      0,
                      .68,
                      1
                    ]))),
                Padding(
                    padding: EdgeInsets.fromLTRB(compact ? 24 : 32, 24, 24, 40),
                    child: Align(
                        alignment: Alignment.bottomLeft,
                        child: SizedBox(
                            width: compact
                                ? constraints.maxWidth
                                : constraints.maxWidth * .65,
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.label ?? 'EM DESTAQUE',
                                      style: AppTypography.label.copyWith(
                                          color: AppColors.primary,
                                          letterSpacing: 2,
                                          fontSize: 12)),
                                  const SizedBox(height: 12),
                                  Text(item.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.display.copyWith(
                                          fontSize: compact ? 30 : 38,
                                          height: 1.08)),
                                  if (item.subtitle?.isNotEmpty == true) ...[
                                    const SizedBox(height: 12),
                                    Text(item.subtitle!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.body
                                            .copyWith(color: Colors.white70)),
                                  ],
                                  if (item.description?.isNotEmpty == true) ...[
                                    const SizedBox(height: 10),
                                    Text(item.description!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.body.copyWith(
                                            fontSize: 15,
                                            color: Colors.white70)),
                                  ],
                                  const SizedBox(height: 20),
                                  Wrap(spacing: 12, runSpacing: 8, children: [
                                    if (item.onPlay != null)
                                      _HeroAction(
                                          label: 'Assistir',
                                          icon: Icons.play_arrow_rounded,
                                          primary: true,
                                          onPressed: item.onPlay!),
                                    if (item.onDetails != null)
                                      _HeroAction(
                                          label: 'Mais informações',
                                          icon: Icons.info_outline_rounded,
                                          onPressed: item.onDetails!),
                                  ]),
                                ])))),
                if (widget.items.length > 1)
                  Positioned(
                      right: 24,
                      bottom: 8,
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text('${_index + 1} / ${widget.items.length}',
                            style: AppTypography.caption),
                        IconButton(
                            tooltip: 'Destaque anterior',
                            onPressed: () => setState(() => _index =
                                (_index - 1 + widget.items.length) %
                                    widget.items.length),
                            icon: const Icon(Icons.chevron_left)),
                        IconButton(
                            tooltip: 'Próximo destaque',
                            onPressed: () => setState(() =>
                                _index = (_index + 1) % widget.items.length),
                            icon: const Icon(Icons.chevron_right)),
                      ])),
              ]);
            })));
  }
}

class _HeroAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool primary;
  const _HeroAction(
      {required this.label,
      required this.icon,
      required this.onPressed,
      this.primary = false});
  @override
  Widget build(BuildContext context) => FocusableWidget(
      onPressed: onPressed,
      builder: (_, focused) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
              color: primary ? Colors.white : const Color(0xFF292B34),
              borderRadius: BorderRadius.circular(6)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: primary ? Colors.black : Colors.white, size: 23),
            const SizedBox(width: 8),
            Text(label,
                style: AppTypography.body.copyWith(
                    color: primary ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w700)),
          ])));
}
