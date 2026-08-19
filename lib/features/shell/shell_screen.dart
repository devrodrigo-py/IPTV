import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nebula_iptv/core/constants/app_constants.dart';
import 'package:nebula_iptv/core/widgets/focusable_widget.dart';
import 'package:nebula_iptv/features/channels/channels_screen.dart';
import 'package:nebula_iptv/features/epg/epg_screen.dart';
import 'package:nebula_iptv/features/favorites/favorites_screen.dart';
import 'package:nebula_iptv/features/history/history_screen.dart';
import 'package:nebula_iptv/features/home/home_screen.dart';
import 'package:nebula_iptv/features/playlists/playlists_screen.dart';
import 'package:nebula_iptv/features/settings/settings_screen.dart';
import 'package:nebula_iptv/features/shell/widgets/mobile_bottom_nav.dart';
import 'package:nebula_iptv/features/shell/widgets/sidebar.dart';
import 'package:nebula_iptv/features/shell/widgets/top_bar.dart';
import 'package:nebula_iptv/l10n/app_localizations.dart';

/// Main shell that provides the application's navigation structure.
///
/// Adapts layout based on screen size:
/// - Desktop: Full sidebar + top bar + content
/// - Tablet: Collapsed sidebar (icons only) + top bar + content
/// - Mobile: Bottom navigation + content
class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _selectedIndex = 0;

  /// Maps navigation indices to page titles (localized).
  String _getTitle(AppLocalizations l10n) {
    return switch (_selectedIndex) {
      0 => l10n.home,
      1 => l10n.channels,
      2 => l10n.favorites,
      3 => l10n.history,
      4 => l10n.playlists,
      5 => l10n.epg,
      6 => l10n.settings,
      _ => l10n.home,
    };
  }

  /// Maps navigation indices to page content.
  Widget _getContent() {
    return switch (_selectedIndex) {
      0 => const HomeScreen(),
      1 => const ChannelsScreen(),
      2 => const FavoritesScreen(),
      3 => const HistoryScreen(),
      4 => const PlaylistsScreen(),
      5 => const EpgScreen(),
      6 => const SettingsScreen(),
      _ => const HomeScreen(),
    };
  }

  /// Maps mobile bottom nav index to full nav index.
  int _mobileToFullIndex(int mobileIndex) {
    return switch (mobileIndex) {
      0 => 0, // Home
      1 => 1, // Channels
      2 => 2, // Favorites
      3 => 4, // Playlists
      4 => 6, // Settings
      _ => 0,
    };
  }

  /// Maps full nav index to mobile bottom nav index.
  int _fullToMobileIndex(int fullIndex) {
    return switch (fullIndex) {
      0 => 0,
      1 => 1,
      2 => 2,
      4 => 3,
      6 => 4,
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
                    setState(() {
                      _selectedIndex = _mobileToFullIndex(index);
                    });
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
            setState(() => _selectedIndex = index);
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
    };
  }
}

class _NavigateIntent extends Intent {
  final int index;
  const _NavigateIntent(this.index);
}
