import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/core/constants/tv_constants.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';
import 'package:nebula_iptv/core/theme/app_typography.dart';
import 'package:nebula_iptv/core/widgets/tv_focusable_card.dart';
import 'package:nebula_iptv/data/database/app_database.dart';
import 'package:nebula_iptv/features/home/home_screen.dart';
import 'package:nebula_iptv/l10n/app_localizations.dart';

/// TV-optimized home screen with large cards for 10-foot UI.
///
/// Shows "Continue Watching" and "Favorites" as horizontal
/// scrollable rows of focusable cards.
class TvHome extends ConsumerWidget {
  const TvHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final continueWatching = ref.watch(continueWatchingProvider);
    final favorites = ref.watch(homeFavoritesProvider);

    return FocusTraversalGroup(
      child: ListView(
        children: [
          // Title
          Text(
            l10n.appTitle,
            style: AppTypography.display.copyWith(
              fontSize:
                  AppTypography.display.fontSize! * TvConstants.fontScaleFactor,
            ),
          ),
          const SizedBox(height: 32),

          // Continue Watching
          if (continueWatching.valueOrNull?.isNotEmpty == true) ...[
            Text(
              'Continuar assistindo',
              style: AppTypography.title.copyWith(
                fontSize:
                    AppTypography.title.fontSize! * TvConstants.fontScaleFactor,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: TvConstants.tvCardHeight,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: continueWatching.value!.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: TvConstants.gridSpacing),
                itemBuilder: (context, index) {
                  final entry = continueWatching.value![index];
                  return TvFocusableCard(
                    autofocus: index == 0,
                    onPressed: () {
                      // Navigate to player
                    },
                    child: _TvHistoryCardContent(
                      channelId: entry.channelId,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
          ],

          // Favorites
          if (favorites.valueOrNull?.isNotEmpty == true) ...[
            Text(
              l10n.favorites,
              style: AppTypography.title.copyWith(
                fontSize:
                    AppTypography.title.fontSize! * TvConstants.fontScaleFactor,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: TvConstants.tvCardHeight,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: favorites.value!.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: TvConstants.gridSpacing),
                itemBuilder: (context, index) {
                  final channel = favorites.value![index];
                  return TvFocusableCard(
                    onPressed: () {
                      // Navigate to player
                    },
                    child: _TvChannelCardContent(channel: channel),
                  );
                },
              ),
            ),
          ],

          // Empty state
          if (continueWatching.valueOrNull?.isEmpty != false &&
              favorites.valueOrNull?.isEmpty != false)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 80),
                child: Column(
                  children: [
                    const Icon(
                      Icons.live_tv_rounded,
                      size: 80,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.homeEmptyMessage,
                      style: AppTypography.title.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: AppTypography.title.fontSize! *
                            TvConstants.fontScaleFactor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TvHistoryCardContent extends StatelessWidget {
  final int channelId;
  const _TvHistoryCardContent({required this.channelId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Icon(
            Icons.play_circle_filled_rounded,
            color: AppColors.primary,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'Canal #$channelId',
            style: AppTypography.body.copyWith(
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _TvChannelCardContent extends StatelessWidget {
  final Channel channel;
  const _TvChannelCardContent({required this.channel});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Icon(
            Icons.live_tv_rounded,
            color: AppColors.textSecondary,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            channel.name,
            style: AppTypography.body.copyWith(fontSize: 16),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
