import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nebula_iptv/core/widgets/focusable_widget.dart';

/// Index-based traversal keeps large, lazily built catalogues navigable past
/// the viewport. At most visible/cache items own focus nodes.
class RemoteGridView extends StatefulWidget {
  final int itemCount, columns;
  final double aspectRatio, spacing;
  final IndexedWidgetBuilder itemBuilder;
  const RemoteGridView(
      {super.key,
      required this.itemCount,
      required this.columns,
      required this.itemBuilder,
      this.aspectRatio = .6,
      this.spacing = 12});

  @override
  State<RemoteGridView> createState() => _RemoteGridViewState();
}

class _RemoteGridViewState extends State<RemoteGridView> {
  final _scroll = ScrollController();
  final Map<int, FocusNode> _mountedItems = {};
  bool _moving = false;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  KeyEventResult _move(int index, KeyEvent event, double rowExtent) {
    final direction = RemoteKeys.direction(event.logicalKey);
    if (direction == null) return KeyEventResult.ignored;
    if (event is KeyUpEvent || _moving) return KeyEventResult.handled;
    final col = index % widget.columns;
    int next;
    switch (direction) {
      case TraversalDirection.left:
        if (col == 0) return KeyEventResult.ignored;
        next = index - 1;
      case TraversalDirection.right:
        if (col == widget.columns - 1 || index + 1 >= widget.itemCount) {
          return KeyEventResult.handled;
        }
        next = index + 1;
      case TraversalDirection.up:
        if (index < widget.columns) return KeyEventResult.ignored;
        next = index - widget.columns;
      case TraversalDirection.down:
        if ((index ~/ widget.columns + 1) * widget.columns >=
            widget.itemCount) {
          return KeyEventResult.handled;
        }
        next = (index + widget.columns).clamp(0, widget.itemCount - 1);
    }
    void focusTarget() {
      final root = _mountedItems[next];
      if (root == null) return;
      final targets = AppFocusTraversalPolicy.targets(root);
      if (targets.isNotEmpty) {
        targets.first.requestFocus();
        Scrollable.ensureVisible(targets.first.context!,
            duration: const Duration(milliseconds: 100),
            alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd);
      }
    }

    if (_mountedItems.containsKey(next)) {
      focusTarget();
    } else if (_scroll.hasClients) {
      _moving = true;
      _scroll.jumpTo((next ~/ widget.columns * rowExtent)
          .clamp(0, _scroll.position.maxScrollExtent));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _moving = false;
        focusTarget();
      });
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final width = (constraints.maxWidth -
                32 -
                (widget.columns - 1) * widget.spacing) /
            widget.columns;
        return GridView.builder(
          controller: _scroll,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: widget.columns,
              childAspectRatio: widget.aspectRatio,
              crossAxisSpacing: widget.spacing,
              mainAxisSpacing: widget.spacing),
          itemCount: widget.itemCount,
          itemBuilder: (context, index) => _RemoteGridItem(
            key: ValueKey(index),
            register: (node) => _mountedItems[index] = node,
            unregister: () => _mountedItems.remove(index),
            onKey: (node, event) => _move(
                index, event, width / widget.aspectRatio + widget.spacing),
            child: widget.itemBuilder(context, index),
          ),
        );
      });
}

class _RemoteGridItem extends StatefulWidget {
  final ValueChanged<FocusNode> register;
  final VoidCallback unregister;
  final FocusOnKeyEventCallback onKey;
  final Widget child;
  const _RemoteGridItem(
      {super.key,
      required this.register,
      required this.unregister,
      required this.onKey,
      required this.child});
  @override
  State<_RemoteGridItem> createState() => _RemoteGridItemState();
}

class _RemoteGridItemState extends State<_RemoteGridItem> {
  final _node = FocusNode(canRequestFocus: false, skipTraversal: true);
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
  Widget build(BuildContext context) =>
      Focus(focusNode: _node, onKeyEvent: widget.onKey, child: widget.child);
}
