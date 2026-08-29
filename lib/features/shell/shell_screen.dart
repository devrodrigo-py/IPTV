import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/core/constants/app_constants.dart';
import 'package:nebula_iptv/core/widgets/focusable_widget.dart';
import 'package:nebula_iptv/features/channels/channels_screen.dart';
import 'package:nebula_iptv/features/epg/epg_screen.dart';
import 'package:nebula_iptv/features/favorites/favorites_screen.dart';
import 'package:nebula_iptv/features/history/history_screen.dart';
import 'package:nebula_iptv/features/home/home_screen.dart';
import 'package:nebula_iptv/features/playlists/playlists_screen.dart';
import 'package:nebula_iptv/features/settings/settings_screen.dart';
import 'package:nebula_iptv/features/stats/stats_screen.dart';
import 'package:nebula_iptv/features/vod/vod_screen.dart';
import 'package:nebula_iptv/features/series/series_screen.dart';
import 'package:nebula_iptv/features/library/library_screen.dart';
import 'package:nebula_iptv/features/shell/widgets/mobile_bottom_nav.dart';
import 'package:nebula_iptv/features/shell/widgets/sidebar.dart';
import 'package:nebula_iptv/features/shell/widgets/top_bar.dart';
import 'package:nebula_iptv/features/shell/providers/shell_navigation_provider.dart';
import 'package:nebula_iptv/l10n/app_localizations.dart';

/// Main shell that provides the application's navigation structure.
///
/// Adapts layout based on screen size:
/// - Desktop: Full sidebar + top bar + content
/// - Tablet: Collapsed sidebar (icons only) + top bar + content
/// - Mobile: Bottom navigation + content
class ShellScreen extends ConsumerStatefulWidget {
  const ShellScreen({super.key});

  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen> {
  int get _selectedIndex => ref.watch(shellNavigationProvider);

  /// Maps navigation indices to page titles (localized).
  String _getTitle(AppLocalizations l10n) {
    return switch (_selectedIndex) {
      0 => l10n.home,
      1 => l10n.channels,
      2 => 'Filmes',
      3 => 'Séries',
      4 => l10n.favorites,
      5 => l10n.history,
      6 => l10n.playlists,
      7 => l10n.epg,
      8 => 'Estatísticas',
      9 => l10n.settings,
      10 => 'Biblioteca',
      _ => l10n.home,
    };
  }

  /// Maps navigation indices to page content.
  Widget _getContent() {
    return switch (_selectedIndex) {
      0 => const HomeScreen(),
      1 => const ChannelsScreen(),
      2 => const VodScreen(),
      3 => const SeriesScreen(),
      4 => const FavoritesScreen(),
      5 => const HistoryScreen(),
      6 => const PlaylistsScreen(),
      7 => const EpgScreen(),
      8 => const StatsScreen(),
      9 => const SettingsScreen(),
      10 => const LibraryScreen(),
      _ => const HomeScreen(),
    };
  }

  /// Maps mobile bottom nav index to full nav index.
  int _mobileToFullIndex(int mobileIndex) {
    return switch (mobileIndex) {
      0 => 0, // Home
      1 => 1, // Channels
      2 => 4, // Favorites
      3 => 6, // Playlists
      4 => 9, // Settings
      _ => 0,
    };
  }

  /// Maps full nav index to mobile bottom nav index.
  int _fullToMobileIndex(int fullIndex) {
    return switch (fullIndex) {
      0 => 0,
      1 => 1,
      2 => 0, // Films → Home on mobile
      3 => 0, // Series → Home on mobile
      4 => 2,
      6 => 3,
      9 => 4,
      _ => 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < AppConstants.mobileMaxWidth;
    final isTablet = screenWidth >= AppConstants.mobileMaxWidth &&
        screenWidth < AppConstants.tabletMaxWidth;

    return FocusTraversalGroup(
      policy: AppFocusTraversalPolicy(),
      child: Shortcuts(
        shortcuts: _buildShortcuts(),
        child: Scaffold(
          body: isMobile
              ? _buildMobileLayout(l10n)
              : _buildDesktopLayout(l10n, isCollapsed: isTablet),
          bottomNavigationBar: isMobile
              ? MobileBottomNav(
                  selectedIndex: _fullToMobileIndex(_selectedIndex),
                  onDestinationSelected: (index) {
                    ref.read(shellNavigationProvider.notifier).state =
                        _mobileToFullIndex(index);
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(
    AppLocalizations l10n, {
    required bool isCollapsed,
  }) {
    return Row(
      children: [
        Sidebar(
          selectedIndex: _selectedIndex,
          isCollapsed: isCollapsed,
          onDestinationSelected: (index) {
            ref.read(shellNavigationProvider.notifier).state = index;
          },
        ),
        Expanded(
          child: Column(
            children: [
              TopBar(title: _getTitle(l10n)),
              Expanded(child: _getContent()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(AppLocalizations l10n) {
    return Column(
      children: [
        TopBar(title: _getTitle(l10n)),
        Expanded(child: _getContent()),
      ],
    );
  }

  /// Keyboard shortcuts for navigation.
  Map<ShortcutActivator, Intent> _buildShortcuts() {
    return {
      const SingleActivator(LogicalKeyboardKey.digit1, alt: true):
          const _NavigateIntent(0),
      const SingleActivator(LogicalKeyboardKey.digit2, alt: true):
          const _NavigateIntent(1),
      const SingleActivator(LogicalKeyboardKey.digit3, alt: true):
          const _NavigateIntent(2),
      const SingleActivator(LogicalKeyboardKey.digit4, alt: true):
          const _NavigateIntent(3),
      const SingleActivator(LogicalKeyboardKey.digit5, alt: true):
          const _NavigateIntent(4),
      const SingleActivator(LogicalKeyboardKey.digit6, alt: true):
          const _NavigateIntent(5),
      const SingleActivator(LogicalKeyboardKey.digit7, alt: true):
          const _NavigateIntent(6),
      const SingleActivator(LogicalKeyboardKey.digit8, alt: true):
          const _NavigateIntent(7),
      const SingleActivator(LogicalKeyboardKey.digit9, alt: true):
          const _NavigateIntent(8),
    };
  }
}

class _NavigateIntent extends Intent {
  final int index;
  const _NavigateIntent(this.index);
}
