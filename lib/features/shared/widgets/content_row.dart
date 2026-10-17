import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:nebula_iptv/core/theme/app_typography.dart';
import 'package:nebula_iptv/core/widgets/focusable_widget.dart';
import 'package:nebula_iptv/features/shared/widgets/content_card.dart';

class ContentRowItem {
  final String title;
  final String? imageUrl, subtitle, badge, heroTag;
  final double? progress;
  final IconData fallbackIcon;
  final int? channelId;
  const ContentRowItem(
      {required this.title,
      this.imageUrl,
      this.subtitle,
      this.progress,
      this.badge,
      this.heroTag,
      this.fallbackIcon = Icons.movie_rounded,
      this.channelId});
}

/// Index traversal includes the final action. Only mounted cards own nodes.
class ContentRow extends StatefulWidget {
  final String title;
  final List<ContentRowItem> items;
  final VoidCallback? onSeeAll;
  final ValueChanged<int>? onItemTap;
  final void Function(int index, Offset position)? onItemSecondaryTap;
  final double cardWidth, height;
  const ContentRow(
      {super.key,
      required this.title,
      required this.items,
      this.onSeeAll,
      this.onItemTap,
      this.onItemSecondaryTap,
      this.cardWidth = 148,
      this.height = 286});
  @override
  State<ContentRow> createState() => _ContentRowState();
}

class _ContentRowState extends State<ContentRow> {
  final _scroll = ScrollController();
  final Map<int, FocusNode> _nodes = {};
  bool _moving = false;
  int get _count => widget.items.length + (widget.onSeeAll != null ? 1 : 0);
  double get _extent => widget.cardWidth + 18;
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  KeyEventResult _move(int index, KeyEvent event) {
    final direction = RemoteKeys.direction(event.logicalKey);
    if (direction != TraversalDirection.left &&
        direction != TraversalDirection.right) {
      return KeyEventResult.ignored;
    }
    if (event is KeyUpEvent || _moving) return KeyEventResult.handled;
    final next = index + (direction == TraversalDirection.right ? 1 : -1);
    if (next < 0) return KeyEventResult.ignored;
    if (next >= _count) return KeyEventResult.handled;
    if (_nodes[next] != null) {
      _nodes[next]!.requestFocus();
    } else if (_scroll.hasClients) {
      _moving = true;
      _scroll
          .jumpTo((next * _extent).clamp(0, _scroll.position.maxScrollExtent));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _moving = false;
        _nodes[next]?.requestFocus();
      });
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(widget.title,
                  style: AppTypography.title.copyWith(fontSize: 21))),
          const SizedBox(height: 8),
          SizedBox(
            height: math.max(widget.height, widget.cardWidth * 1.5 + 80),
            child: ListView.builder(
              scrollCacheExtent: ScrollCacheExtent.pixels(_extent * 2), key: PageStorageKey(widget.title),
              controller: _scroll,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              itemExtent: _extent,
              itemCount: _count,
              itemBuilder: (context, index) => _RowTarget(
                key: ValueKey(index),
                register: (node) => _nodes[index] = node,
                unregister: () => _nodes.remove(index),
                onKey: (_, event) => _move(index, event),
                builder: (node) {
                  if (index == widget.items.length) {
                    return FocusableWidget(
                        focusNode: node,
                        onPressed: widget.onSeeAll,
                        builder: (_, focused) => Center(
                                child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                  Icon(Icons.arrow_forward_rounded,
                                      size: 32,
                                      color: focused
                                          ? Colors.white
                                          : Colors.white54),
                                  const SizedBox(height: 12),
                                  Text('Ver todos', style: AppTypography.body),
                                ])));
                  }
                  final item = widget.items[index];
                  return ContentCard(
                      focusNode: node,
                      title: item.title,
                      imageUrl: item.imageUrl,
                      subtitle: item.subtitle,
                      badge: item.badge,
                      heroTag: item.heroTag,
                      progress: item.progress,
                      fallbackIcon: item.fallbackIcon,
                      width: widget.cardWidth,
                      onTap: widget.onItemTap == null
                          ? null
                          : () => widget.onItemTap!(index),
                      onSecondaryTap: widget.onItemSecondaryTap == null
                          ? null
                          : (p) => widget.onItemSecondaryTap!(index, p));
                },
              ),
            ),
          ),
        ]);
  }
}

class _RowTarget extends StatefulWidget {
  final ValueChanged<FocusNode> register;
  final VoidCallback unregister;
  final FocusOnKeyEventCallback onKey;
  final Widget Function(FocusNode) builder;
  const _RowTarget(
      {super.key,
      required this.register,
      required this.unregister,
      required this.onKey,
      required this.builder});
  @override
  State<_RowTarget> createState() => _RowTargetState();
}

class _RowTargetState extends State<_RowTarget> {
  final _node = FocusNode(debugLabel: 'carousel action');
  @override
  void initState() {
    super.initState();
    widget.register(_node);
  }

  @override
  void dispose() {
    widget.unregister();
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: widget.onKey,
      child: Padding(
          padding: const EdgeInsets.only(right: 18),
          child: widget.builder(_node)));
}
