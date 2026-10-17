import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nebula_iptv/core/widgets/nebula_focus_ring.dart';

/// Focus management infrastructure for keyboard and D-pad navigation.
///
/// Provides consistent focus behavior across all platforms,
/// prepared from Phase 2 to avoid retrofitting in Phase 9 (Android TV).

/// A widget that wraps its child with a visible focus indicator.
///
/// Used as the base building block for all focusable interactive
/// components in the Design System.
class FocusableWidget extends StatefulWidget {
  final Widget Function(BuildContext context, bool isFocused) builder;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool canRequestFocus;
  final BorderRadius borderRadius;

  /// Forces the gradient ring regardless of focus — used by persistent
  /// states like the selected item of a navigation menu. The glow halo
  /// remains focus-only.
  final bool showRing;
  final bool decorateFocus;
  final ValueChanged<bool>? onFocusChange;

  const FocusableWidget({
    super.key,
    required this.builder,
    this.onPressed,
    this.onLongPress,
    this.focusNode,
    this.autofocus = false,
    this.canRequestFocus = true,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.showRing = false,
    this.decorateFocus = true,
    this.onFocusChange,
  });

  @override
  State<FocusableWidget> createState() => _FocusableWidgetState();
}

class _FocusableWidgetState extends State<FocusableWidget> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  Timer? _holdTimer;
  bool _selectDown = false;
  bool _longPressed = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(FocusableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      if (oldWidget.focusNode == null) _focusNode.dispose();
      _focusNode = widget.focusNode ?? FocusNode();
    }
  }

  void _handleFocusChange(bool hasFocus) {
    if (!hasFocus) {
      _holdTimer?.cancel();
      _selectDown = false;
    }
    setState(() => _isFocused = hasFocus);
    widget.onFocusChange?.call(hasFocus);
    if (hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_focusNode.hasFocus) return;
        Scrollable.ensureVisible(context,
            duration: const Duration(milliseconds: 120),
            alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd);
      });
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (!node.hasPrimaryFocus) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.contextMenu &&
        widget.onLongPress != null) {
      if (event is KeyDownEvent) widget.onLongPress!();
      return KeyEventResult.handled;
    }
    if (RemoteKeys.isSelect(event.logicalKey)) {
      if (event is KeyDownEvent) {
        if (widget.onLongPress == null) {
          widget.onPressed?.call();
        } else {
          _selectDown = true;
          _longPressed = false;
          _holdTimer?.cancel();
          _holdTimer = Timer(const Duration(milliseconds: 650), () {
            if (!mounted || !_focusNode.hasPrimaryFocus || !_selectDown) return;
            _longPressed = true;
            widget.onLongPress?.call();
          });
        }
      } else if (event is KeyUpEvent && _selectDown) {
        _holdTimer?.cancel();
        _selectDown = false;
        if (!_longPressed) widget.onPressed?.call();
      }
      // Consume the entire press, including repeats and key-up. Holding OK
      // must never activate the next control after a page transition.
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      canRequestFocus: widget.canRequestFocus,
      onFocusChange: _handleFocusChange,
      onKeyEvent: _handleKeyEvent,
      child: Semantics(
        button: true,
        enabled: widget.canRequestFocus,
        focused: _isFocused,
        child: GestureDetector(
          onTap: widget.onPressed,
          onLongPress: widget.onLongPress,
          child: NebulaFocusRing(
            focused: widget.decorateFocus && (_isFocused || widget.showRing),
            withGlow: _isFocused,
            radius: widget.borderRadius.topLeft.x,
            // Borda transparente de 3px mantém o layout estável entre os
            // estados focado/não focado; o anel em gradiente é pintado por cima.
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                borderRadius: widget.borderRadius,
                border: Border.all(
                  color: Colors.transparent,
                  width: 3,
                ),
              ),
              child: widget.builder(context, _isFocused),
            ),
          ),
        ),
      ),
    );
  }
}

abstract final class RemoteKeys {
  static const shortcuts = <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.select, includeRepeats: false):
        ActivateIntent(),
    SingleActivator(LogicalKeyboardKey.gameButtonA, includeRepeats: false):
        ActivateIntent(),
    SingleActivator(LogicalKeyboardKey.goBack, includeRepeats: false):
        RemoteBackIntent(),
    SingleActivator(LogicalKeyboardKey.escape, includeRepeats: false):
        RemoteBackIntent(),
  };
  static bool isSelect(LogicalKeyboardKey key) =>
      key == LogicalKeyboardKey.select ||
      key == LogicalKeyboardKey.enter ||
      key == LogicalKeyboardKey.numpadEnter ||
      key == LogicalKeyboardKey.space ||
      key == LogicalKeyboardKey.gameButtonA;

  static bool isBack(LogicalKeyboardKey key) =>
      key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.goBack;

  static TraversalDirection? direction(LogicalKeyboardKey key) => switch (key) {
        LogicalKeyboardKey.arrowUp => TraversalDirection.up,
        LogicalKeyboardKey.arrowDown => TraversalDirection.down,
        LogicalKeyboardKey.arrowLeft => TraversalDirection.left,
        LogicalKeyboardKey.arrowRight => TraversalDirection.right,
        _ => null,
      };
}

class RemoteBackIntent extends Intent {
  const RemoteBackIntent();
}

/// Traversal policy that ensures predictable D-pad navigation
/// following a top-to-bottom, left-to-right order.
class AppFocusTraversalPolicy extends FocusTraversalPolicy {
  AppFocusTraversalPolicy();

  @override
  FocusNode? findFirstFocusInDirection(
          FocusNode currentNode, TraversalDirection direction) =>
      ReadingOrderTraversalPolicy()
          .findFirstFocusInDirection(currentNode, direction);

  @override
  Iterable<FocusNode> sortDescendants(
          Iterable<FocusNode> descendants, FocusNode currentNode) =>
      ReadingOrderTraversalPolicy().sortDescendants(descendants, currentNode);

  final Map<ScrollableState, FocusNode> _rowMemory = {};

  static List<FocusNode> targets(FocusNode root) => root.traversalDescendants
      .where((n) =>
          n is! FocusScopeNode &&
          n.context != null &&
          n.rect.width > 0 &&
          n.rect.height > 0 &&
          (!n.traversalDescendants.any((child) => child is! FocusScopeNode) ||
              n.context!.findAncestorWidgetOfExactType<FocusableWidget>() !=
                  null))
      .toList();

  @override
  bool inDirection(FocusNode currentNode, TraversalDirection direction) {
    final scope = currentNode.nearestScope;
    if (scope == null) return false;
    final current = currentNode.rect;
    final horizontal = direction == TraversalDirection.left ||
        direction == TraversalDirection.right;
    final forward = direction == TraversalDirection.right ||
        direction == TraversalDirection.down;
    final candidates = targets(scope).where((n) {
      if (n == currentNode) return false;
      final rect = n.rect;
      final delta = horizontal
          ? rect.center.dx - current.center.dx
          : rect.center.dy - current.center.dy;
      if (forward ? delta <= 1 : delta >= -1) return false;
      // Left/right stay in the current visual row. At its edge, the owning
      // region decides whether to open the sidebar or stay put.
      return !horizontal ||
          (rect.top < current.bottom - 2 && rect.bottom > current.top + 2);
    }).toList();
    if (candidates.isEmpty) return false;
    double mainDistance(FocusNode n) => horizontal
        ? (n.rect.center.dx - current.center.dx).abs()
        : (n.rect.center.dy - current.center.dy).abs();
    candidates.sort((a, b) => mainDistance(a).compareTo(mainDistance(b)));
    FocusNode target = candidates.first;
    if (!horizontal) {
      final nearestY = target.rect.center.dy;
      final row = candidates
          .where((n) => (n.rect.center.dy - nearestY).abs() < 24)
          .toList();
      row.sort((a, b) => (a.rect.center.dx - current.center.dx)
          .abs()
          .compareTo((b.rect.center.dx - current.center.dx).abs()));
      target = row.first;
      final lane = Scrollable.maybeOf(target.context!, axis: Axis.horizontal);
      final remembered = _rowMemory[lane];
      if (remembered != null && row.contains(remembered)) target = remembered;
    }
    if (currentNode.context != null) {
      final lane =
          Scrollable.maybeOf(currentNode.context!, axis: Axis.horizontal);
      if (lane != null) _rowMemory[lane] = currentNode;
    }
    _rowMemory
        .removeWhere((lane, node) => !lane.mounted || node.context == null);
    target.requestFocus();
    Scrollable.ensureVisible(target.context!,
        duration: const Duration(milliseconds: 120),
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd);
    return true;
  }
}
