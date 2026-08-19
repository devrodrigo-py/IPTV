import 'package:flutter/material.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';
import 'package:nebula_iptv/l10n/app_localizations.dart';

/// Bottom navigation bar for mobile layout.
///
/// Shows only the most important destinations.
/// Settings and secondary pages are accessible from the "More" option.
class MobileBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const MobileBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return NavigationBar(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.primary.withValues(alpha: 0.15),
      selectedIndex: selectedIndex.clamp(0, 4),
      onDestinationSelected: onDestinationSelected,
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home_rounded),
          label: l10n.home,
        ),
        NavigationDestination(
          icon: const Icon(Icons.live_tv_outlined),
          selectedIcon: const Icon(Icons.live_tv_rounded),
          label: l10n.channels,
        ),
        NavigationDestination(
          icon: const Icon(Icons.favorite_outline_rounded),
          selectedIcon: const Icon(Icons.favorite_rounded),
          label: l10n.favorites,
        ),
        NavigationDestination(
          icon: const Icon(Icons.playlist_play_outlined),
          selectedIcon: const Icon(Icons.playlist_play_rounded),
          label: l10n.playlists,
        ),
        NavigationDestination(
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings_rounded),
          label: l10n.settings,
        ),
      ],
    );
  }
}
