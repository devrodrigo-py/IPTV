import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nebula_iptv/core/widgets/focusable_widget.dart';
import 'package:nebula_iptv/core/widgets/tv_safe_area.dart';

class TvDestination {
  final IconData icon;
  final String label;
  const TvDestination(this.icon, this.label);
}

/// Two independent focus regions. The rail never participates in vertical
/// content traversal, and expanding its labels never moves the posters.
class TvNavigationShell extends StatefulWidget {
  final List<TvDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onSearch;
  final Widget child;
  const TvNavigationShell(
      {super.key,
      required this.destinations,
      required this.selectedIndex,
      required this.onSelected,
      required this.onSearch,
      required this.child});

  @override
  State<TvNavigationShell> createState() => _TvNavigationShellState();
}

class _TvNavigationShellState extends State<TvNavigationShell> {
  final _content = FocusScopeNode(
      debugLabel: 'TV content',
      directionalTraversalEdgeBehavior: TraversalEdgeBehavior.stop);
  final _rail = FocusScopeNode(
      debugLabel: 'TV menu',
      directionalTraversalEdgeBehavior: TraversalEdgeBehavior.stop);
  final _policy = AppFocusTraversalPolicy();
  late final List<FocusNode> _menu;
  FocusNode? _lastContent;
  bool _expanded = true;

  @override
  void initState() {
    super.initState();
    _menu = List.generate(
        widget.destinations.length + 1,
        (i) => FocusNode(
            debugLabel: i == 0 ? 'TV search' : 'TV destination ${i - 1}'));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _menu[widget.selectedIndex + 1].requestFocus();
    });
  }

  @override
  void didUpdateWidget(TvNavigationShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) _lastContent = null;
  }

  @override
  void dispose() {
    _content.dispose();
    _rail.dispose();
    for (final node in _menu) {
      node.dispose();
    }
    super.dispose();
  }

  void _enterContent() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final targets = AppFocusTraversalPolicy.targets(_content);
      if (_lastContent != null && targets.contains(_lastContent)) {
        _lastContent!.requestFocus();
      } else if (targets.isNotEmpty) {
        targets.sort((a, b) {
          final y = a.rect.top.compareTo(b.rect.top);
          return y == 0 ? a.rect.left.compareTo(b.rect.left) : y;
        });
        targets.first.requestFocus();
      } else {
        _content.requestFocus();
      }
    });
    // Schedule even when the selected page has not changed.
    setState(() => _expanded = false);
  }

  void _openMenu() {
    if (_content.hasFocus) _lastContent = FocusManager.instance.primaryFocus;
    _menu[widget.selectedIndex + 1].requestFocus();
  }

  void _select(int menuIndex) {
    if (menuIndex == 0) {
      widget.onSearch();
      return;
    }
    if (menuIndex - 1 != widget.selectedIndex) _lastContent = null;
    widget.onSelected(menuIndex - 1);
    _enterContent();
  }

  KeyEventResult _menuKey(FocusNode node, KeyEvent event) {
    final direction = RemoteKeys.direction(event.logicalKey);
    if (direction != null) {
      if (event is KeyUpEvent) return KeyEventResult.handled;
      final index = _menu.indexWhere((n) => n.hasFocus);
      if (direction == TraversalDirection.up ||
          direction == TraversalDirection.down) {
        final target = (index + (direction == TraversalDirection.down ? 1 : -1))
            .clamp(0, _menu.length - 1);
        _menu[target].requestFocus();
      } else if (direction == TraversalDirection.right &&
          event is KeyDownEvent) {
        _select(index < 0 ? widget.selectedIndex + 1 : index);
      }
      return KeyEventResult.handled;
    }
    if (RemoteKeys.isBack(event.logicalKey)) {
      if (widget.selectedIndex == 0) return KeyEventResult.ignored;
      if (event is KeyDownEvent && widget.selectedIndex != 0) {
        widget.onSelected(0);
        _menu[1].requestFocus();
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _contentKey(FocusNode node, KeyEvent event) {
    if (RemoteKeys.isBack(event.logicalKey)) {
      if (event is KeyDownEvent) _openMenu();
      return KeyEventResult.handled;
    }
    final direction = RemoteKeys.direction(event.logicalKey);
    if (direction == null) return KeyEventResult.ignored;
    if (event is KeyUpEvent) return KeyEventResult.handled;
    final current = FocusManager.instance.primaryFocus;
    if (current == _content) {
      if (direction == TraversalDirection.left) {
        _openMenu();
      } else {
        _enterContent();
      }
    } else if (current != null &&
        !_policy.inDirection(current, direction) &&
        direction == TraversalDirection.left) {
      _openMenu();
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _rail.hasFocus && widget.selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_content.hasFocus) {
          _openMenu();
        } else {
          widget.onSelected(0);
          _menu[1].requestFocus();
        }
      },
      child: ColoredBox(
        color: const Color(0xFF08090C),
        child: TvSafeArea(
          child: Stack(children: [
            Positioned.fill(
              left: 56,
              child: FocusScope(
                node: _content,
                onKeyEvent: _contentKey,
                child: FocusTraversalGroup(
                    policy: _policy,
                    child: KeyedSubtree(
                        key: ValueKey(widget.selectedIndex),
                        child: widget.child)),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: FocusScope(
                node: _rail,
                onKeyEvent: _menuKey,
                onFocusChange: (focused) {
                  if (mounted) setState(() => _expanded = focused);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: _expanded ? 208 : 52,
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                    colors: [
                      const Color(0xFF08090C),
                      const Color(0xFF08090C)
                          .withValues(alpha: _expanded ? .98 : .85)
                    ],
                  )),
                  child: LayoutBuilder(builder: (context, constraints) {
                    final itemHeight =
                        ((constraints.maxHeight - 16) / _menu.length)
                            .clamp(40.0, 52.0);
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 4),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        for (var i = 0; i < _menu.length; i++)
                          SizedBox(
                            height: itemHeight,
                            child: FocusableWidget(
                              key: ValueKey('tv-menu-$i'),
                              focusNode: _menu[i],
                              decorateFocus: false,
                              onPressed: () => _select(i),
                              builder: (context, focused) => Container(
                                decoration: BoxDecoration(
                                  color: focused
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border(
                                      left: BorderSide(
                                          color: !focused &&
                                                  i == widget.selectedIndex + 1
                                              ? Colors.white
                                              : Colors.transparent,
                                          width: 2)),
                                ),
                                child: Row(children: [
                                  SizedBox(
                                      width: 36,
                                      child: Icon(
                                        i == 0
                                            ? Icons.search_rounded
                                            : widget.destinations[i - 1].icon,
                                        size: 18,
                                        color: focused
                                            ? Colors.black
                                            : i == widget.selectedIndex + 1
                                                ? Colors.white
                                                : Colors.white60,
                                      )),
                                  if (_expanded)
                                    Expanded(
                                        child: Text(
                                      i == 0
                                          ? 'Buscar'
                                          : widget.destinations[i - 1].label,
                                      maxLines: 1,
                                      overflow: TextOverflow.clip,
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: focused
                                              ? Colors.black
                                              : Colors.white70),
                                    )),
                                ]),
                              ),
                            ),
                          ),
                      ]),
                    );
                  }),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
