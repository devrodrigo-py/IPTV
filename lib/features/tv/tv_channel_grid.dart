import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/core/constants/tv_constants.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';
import 'package:nebula_iptv/core/theme/app_typography.dart';
import 'package:nebula_iptv/core/widgets/loading_view.dart';
import 'package:nebula_iptv/core/widgets/tv_focusable_card.dart';
import 'package:nebula_iptv/features/channels/providers/channels_provider.dart';
import 'package:nebula_iptv/l10n/app_localizations.dart';

/// TV-optimized channel grid with large cards.
///
/// Uses a wrap/grid layout with D-pad navigation between cards.
/// Each card is focusable and scales when selected.
class TvChannelGrid extends ConsumerWidget {
  const TvChannelGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(channelsScreenProvider);

    if (state.isLoading) return const LoadingView();

    if (state.allChannels.isEmpty) {
      return Center(
        child: Text(
          l10n.channels,
          style: AppTypography.title.copyWith(
            color: AppColors.textSecondary,
            fontSize:
                AppTypography.title.fontSize! * TvConstants.fontScaleFactor,
          ),
        ),
      );
    }

    return FocusTraversalGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.channels,
            style: AppTypography.headline.copyWith(
              fontSize: AppTypography.headline.fontSize! *
                  TvConstants.fontScaleFactor,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: TvConstants.gridSpacing,
                mainAxisSpacing: TvConstants.gridSpacing,
                childAspectRatio:
                    TvConstants.tvCardWidth / TvConstants.tvCardHeight,
              ),
              itemCount: state.allChannels.length,
              itemBuilder: (context, index) {
                final channel = state.allChannels[index];
                return TvFocusableCard(
                  autofocus: index == 0,
                  onPressed: () {
                    // Navigate to player
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.live_tv_rounded,
                          color: AppColors.textSecondary,
                          size: 28,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          channel.name,
                          style: AppTypography.body.copyWith(fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (channel.groupName != null)
                          Text(
                            channel.groupName!,
                            style: AppTypography.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
