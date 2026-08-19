import 'package:flutter/material.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';
import 'package:nebula_iptv/core/theme/app_typography.dart';
import 'package:nebula_iptv/features/shell/widgets/nav_item.dart';
import 'package:nebula_iptv/l10n/app_localizations.dart';

/// Sidebar navigation for desktop and tablet layouts.
///
/// Collapses to icons-only on tablet, and is replaced by
/// bottom navigation on mobile.
class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final bool isCollapsed;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.isCollapsed = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final destinations = [
      _NavDestination(Icons.home_rounded, l10n.home),
      _NavDestination(Icons.live_tv_rounded, l10n.channels),
      _NavDestination(Icons.favorite_rounded, l10n.favorites),
      _NavDestination(Icons.history_rounded, l10n.history),
      _NavDestination(Icons.playlist_play_rounded, l10n.playlists),
      _NavDestination(Icons.schedule_rounded, l10n.epg),
      _NavDestination(Icons.settings_rounded, l10n.settings),
    ];

    return FocusTraversalGroup(
      child: Container(
        width: isCollapsed ? 72 : 220,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            right: BorderSide(
              color: AppColors.divider,
              width: 1,
            ),
          ),
        ),
        child: Column(
          children: [
            // Logo / Title
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isCollapsed ? 12 : 20,
                vertical: 24,
              ),
              child: Row(
                mainAxisAlignment: isCollapsed
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.blur_on_rounded,
                    color: AppColors.primary,
                    size: 28,
                  ),
                  if (!isCollapsed) ...[
                    const SizedBox(width: 12),
                    const Text(
                      'Nebula',
                      style: AppTypography.title,
                    ),
                  ],
                ],
              ),
            ),

            const Divider(height: 1),
            const SizedBox(height: 8),

            // Navigation Items
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isCollapsed ? 8 : 12,
                ),
                child: ListView.separated(
                  itemCount: destinations.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    return NavItem(
                      icon: destinations[index].icon,
                      label: destinations[index].label,
                      isSelected: selectedIndex == index,
                      isCollapsed: isCollapsed,
                      onTap: () => onDestinationSelected(index),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavDestination {
  final IconData icon;
  final String label;

  const _NavDestination(this.icon, this.label);
}
