import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';

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

  const FocusableWidget({
    super.key,
    required this.builder,
    this.onPressed,
    this.onLongPress,
    this.focusNode,
    this.autofocus = false,
    this.canRequestFocus = true,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  State<FocusableWidget> createState() => _FocusableWidgetState();
}

class _FocusableWidgetState extends State<FocusableWidget> {
  late final FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _handleFocusChange(bool hasFocus) {
    setState(() => _isFocused = hasFocus);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.select) {
        widget.onPressed?.call();
        return KeyEventResult.handled;
      }
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
      child: GestureDetector(
        onTap: widget.onPressed,
        onLongPress: widget.onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            border: _isFocused
                ? Border.all(
                    color: AppColors.focusRing,
                    width: 2,
                  )
                : Border.all(
                    color: Colors.transparent,
                    width: 2,
                  ),
          ),
          child: widget.builder(context, _isFocused),
        ),
      ),
    );
  }
}

/// Traversal policy that ensures predictable D-pad navigation
/// following a top-to-bottom, left-to-right order.
class AppFocusTraversalPolicy extends OrderedTraversalPolicy {
  AppFocusTraversalPolicy();
}
