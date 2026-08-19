import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/core/widgets/empty_view.dart';
import 'package:nebula_iptv/core/widgets/loading_view.dart';
import 'package:nebula_iptv/data/database/app_database.dart';
import 'package:nebula_iptv/features/channels/providers/channels_provider.dart';
import 'package:nebula_iptv/features/channels/widgets/channel_list_tile.dart';
import 'package:nebula_iptv/l10n/app_localizations.dart';

/// Provider for favorite channels list.
final favoriteChannelsProvider = FutureProvider<List<Channel>>((ref) async {
  final db = ref.read(databaseProvider);
  return db.favoritesDao.getFavoriteChannels();
});

/// Favorites screen showing only favorited channels.
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final favoritesAsync = ref.watch(favoriteChannelsProvider);

    return favoritesAsync.when(
      loading: () => const LoadingView(),
      error: (_, __) => EmptyView(
        icon: Icons.favorite_rounded,
        message: l10n.favorites,
      ),
      data: (channels) {
        if (channels.isEmpty) {
          return const EmptyView(
            icon: Icons.favorite_border_rounded,
            message: 'Adicione canais aos favoritos para vê-los aqui',
          );
        }

        return ListView.builder(
          itemCount: channels.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final channel = channels[index];
            return ChannelListTile(
              channel: channel,
              isFavorite: true,
              onTap: () {
                // Player navigation in Phase 6
              },
              onFavoriteToggle: () async {
                final db = ref.read(databaseProvider);
                await db.favoritesDao.removeFavorite(channel.id);
                ref.invalidate(favoriteChannelsProvider);
                ref.read(channelsScreenProvider.notifier).refresh();
              },
            );
          },
        );
      },
    );
  }
}
