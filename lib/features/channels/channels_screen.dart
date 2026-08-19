import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/features/player/player_screen.dart';
import 'package:nebula_iptv/core/widgets/empty_view.dart';
import 'package:nebula_iptv/core/widgets/error_view.dart';
import 'package:nebula_iptv/core/widgets/loading_view.dart';
import 'package:nebula_iptv/features/channels/providers/channels_provider.dart';
import 'package:nebula_iptv/features/channels/widgets/channel_list_tile.dart';
import 'package:nebula_iptv/features/channels/widgets/channel_search_bar.dart';
import 'package:nebula_iptv/features/channels/widgets/group_filter_chips.dart';
import 'package:nebula_iptv/l10n/app_localizations.dart';

/// Channel Browser screen (Phase 5).
///
/// Displays all active channels with search, category filters,
/// and favorite toggle. Uses ListView.builder for virtualized
/// scrolling with thousands of channels.
class ChannelsScreen extends ConsumerWidget {
  const ChannelsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(channelsScreenProvider);

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: ChannelSearchBar(
            onChanged: (query) {
              ref.read(channelsScreenProvider.notifier).search(query);
            },
          ),
        ),

        // Group filter chips
        if (state.groups.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GroupFilterChips(
              groups: state.groups,
              selectedGroup: state.selectedGroup,
              onSelected: (group) {
                ref.read(channelsScreenProvider.notifier).filterByGroup(group);
              },
            ),
          ),

        const SizedBox(height: 8),

        // Channel list
        Expanded(
          child: _buildContent(context, state, ref, l10n),
        ),
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    ChannelsScreenState state,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    if (state.isLoading) {
      return const LoadingView();
    }

    if (state.failure != null) {
      return ErrorView(
        failure: state.failure!,
        onRetry: () => ref.read(channelsScreenProvider.notifier).refresh(),
      );
    }

    if (state.filteredChannels.isEmpty) {
      return EmptyView(
        icon: Icons.live_tv_rounded,
        message: state.searchQuery.isNotEmpty
            ? 'Nenhum canal encontrado para "${state.searchQuery}"'
            : l10n.channels,
      );
    }

    return ListView.builder(
      itemCount: state.filteredChannels.length,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (context, index) {
        final channel = state.filteredChannels[index];
        final isFavorite = state.favoriteIds.contains(channel.id);

        return ChannelListTile(
          channel: channel,
          isFavorite: isFavorite,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PlayerScreen(
                  channelName: channel.name,
                  streamUrl: channel.streamUrl,
                  logoUrl: channel.logoUrl,
                ),
              ),
            );
          },
          onFavoriteToggle: () {
            ref.read(channelsScreenProvider.notifier).toggleFavorite(
                  channel.id,
                );
          },
        );
      },
    );
  }
}
