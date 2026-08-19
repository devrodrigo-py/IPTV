import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';
import 'package:nebula_iptv/core/theme/app_typography.dart';
import 'package:nebula_iptv/core/widgets/focusable_widget.dart';
import 'package:nebula_iptv/data/database/app_database.dart';
import 'package:nebula_iptv/features/channels/providers/channels_provider.dart';
import 'package:nebula_iptv/l10n/app_localizations.dart';

/// Provider for "Continue Watching" section on Home.
final continueWatchingProvider =
    FutureProvider<List<WatchHistoryEntry>>((ref) async {
  final db = ref.read(databaseProvider);
  return db.watchHistoryDao.getRecentHistory(limit: 10);
});

/// Provider for favorite channels on Home.
final homeFavoritesProvider = FutureProvider<List<Channel>>((ref) async {
  final db = ref.read(databaseProvider);
  return db.favoritesDao.getFavoriteChannels();
});

/// Home screen — main content area.
///
/// Adapts to available data: shows "Continue Watching", "Favorites",
/// or a welcome message when no data exists (spec §15).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final continueWatching = ref.watch(continueWatchingProvider);
    final favorites = ref.watch(homeFavoritesProvider);

    final hasContent = continueWatching.valueOrNull?.isNotEmpty == true ||
        favorites.valueOrNull?.isNotEmpty == true;

    if (!hasContent) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.live_tv_rounded,
              size: 64,
              color: AppColors.primary,
            ),
            const SizedBox(height: 24),
            Text(l10n.appTitle, style: AppTypography.headline),
            const SizedBox(height: 8),
            Text(
              l10n.homeEmptyMessage,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Continue Watching section
        if (continueWatching.valueOrNull?.isNotEmpty == true) ...[
          const _SectionHeader(title: 'Continuar assistindo'),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: continueWatching.value!.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final entry = continueWatching.value![index];
                return _ContinueWatchingCard(
                  channelId: entry.channelId,
                  onTap: () {
                    // Navigate to player
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Favorites section
        if (favorites.valueOrNull?.isNotEmpty == true) ...[
          _SectionHeader(title: l10n.favorites),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: favorites.value!.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final channel = favorites.value![index];
                return _ChannelCard(
                  channel: channel,
                  onTap: () {
                    // Navigate to player
                  },
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: AppTypography.title);
  }
}

class _ContinueWatchingCard extends StatelessWidget {
  final int channelId;
  final VoidCallback onTap;

  const _ContinueWatchingCard({
    required this.channelId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FocusableWidget(
      onPressed: onTap,
      borderRadius: BorderRadius.circular(12),
      builder: (context, isFocused) => Container(
        width: 160,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isFocused ? AppColors.surfaceElevated : AppColors.card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.play_circle_filled_rounded,
              color: AppColors.primary,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              'Canal #$channelId',
              style: AppTypography.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChannelCard extends StatelessWidget {
  final Channel channel;
  final VoidCallback onTap;

  const _ChannelCard({
    required this.channel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FocusableWidget(
      onPressed: onTap,
      borderRadius: BorderRadius.circular(12),
      builder: (context, isFocused) => Container(
        width: 160,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isFocused ? AppColors.surfaceElevated : AppColors.card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.live_tv_rounded,
              color: AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              channel.name,
              style: AppTypography.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
