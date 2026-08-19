import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nebula_iptv/core/constants/tv_constants.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';
import 'package:nebula_iptv/core/theme/app_typography.dart';
import 'package:nebula_iptv/features/tv/tv_channel_grid.dart';
import 'package:nebula_iptv/features/tv/tv_home.dart';
import 'package:nebula_iptv/l10n/app_localizations.dart';

/// TV-optimized shell with sidebar navigation via D-pad.
///
/// Designed for 10-foot UI: large text, overscan padding,
/// prominent focus indicators, and keyboard/remote-only navigation.
class TvShell extends StatefulWidget {
  const TvShell({super.key});

  @override
  State<TvShell> createState() => _TvShellState();
}

class _TvShellState extends State<TvShell> {
  int _selectedIndex = 0;
  final _navFocusNode = FocusNode();

  @override
  void dispose() {
    _navFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(TvConstants.overscanPadding),
        child: Row(
          children: [
            // TV Sidebar (slim, icon-based)
            _TvSidebar(
              selectedIndex: _selectedIndex,
              focusNode: _navFocusNode,
              onSelected: (index) => setState(() => _selectedIndex = index),
              labels: [
                l10n.home,
                l10n.channels,
                l10n.favorites,
                l10n.settings,
              ],
              icons: const [
                Icons.home_rounded,
                Icons.live_tv_rounded,
                Icons.favorite_rounded,
                Icons.settings_rounded,
              ],
            ),
            const SizedBox(width: 24),
            // Content
            Expanded(
              child: _getContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getContent() {
    return switch (_selectedIndex) {
      0 => const TvHome(),
      1 => const TvChannelGrid(),
      _ => const TvHome(),
    };
  }
}

/// Slim sidebar for TV with large icons and D-pad focus.
class _TvSidebar extends StatelessWidget {
  final int selectedIndex;
  final FocusNode focusNode;
  final ValueChanged<int> onSelected;
  final List<String> labels;
  final List<IconData> icons;

  const _TvSidebar({
    required this.selectedIndex,
    required this.focusNode,
    required this.onSelected,
    required this.labels,
    required this.icons,
  });

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(icons.length, (index) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: _TvNavButton(
                icon: icons[index],
                label: labels[index],
                isSelected: selectedIndex == index,
                autofocus: index == 0,
                onPressed: () => onSelected(index),
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// A single TV navigation button with focus ring.
class _TvNavButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool autofocus;
  final VoidCallback onPressed;

  const _TvNavButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onPressed,
    this.autofocus = false,
  });

  @override
  State<_TvNavButton> createState() => _TvNavButtonState();
}

class _TvNavButtonState extends State<_TvNavButton> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final isHighlighted = widget.isSelected || _isFocused;

    return Focus(
      autofocus: widget.autofocus,
      onFocusChange: (f) => setState(() => _isFocused = f),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.select)) {
          widget.onPressed();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: TvConstants.focusAnimationDuration,
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: isHighlighted
                ? AppColors.primary.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isFocused ? AppColors.focusRing : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                color:
                    isHighlighted ? AppColors.primary : AppColors.textSecondary,
                size: 28,
              ),
              const SizedBox(height: 4),
              Text(
                widget.label,
                style: AppTypography.caption.copyWith(
                  color: isHighlighted
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontSize: 9,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
