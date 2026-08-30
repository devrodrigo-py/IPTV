import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';
import 'package:nebula_iptv/core/theme/app_typography.dart';
import 'package:nebula_iptv/core/widgets/nebula_brand.dart';
import 'package:nebula_iptv/data/database/app_database.dart';
import 'package:nebula_iptv/domain/providers/watch_providers.dart';
import 'package:nebula_iptv/domain/services/watch_tracking_service.dart';
import 'package:nebula_iptv/features/channels/providers/channels_provider.dart';
import 'package:nebula_iptv/features/player/player_screen.dart';
import 'package:nebula_iptv/features/search/providers/search_provider.dart';
import 'package:nebula_iptv/features/series/providers/series_provider.dart';
import 'package:nebula_iptv/features/series/series_detail_screen.dart';
import 'package:nebula_iptv/features/shared/widgets/content_row.dart';

final libraryRecentlyAddedProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final db = ref.read(databaseProvider);
  final rows = await db.customSelect('''
    SELECT id, name, logo_url, stream_url, source_type
    FROM channels
    WHERE source_type IN ('vod', 'series') AND is_active = 1
    ORDER BY id DESC LIMIT 20
  ''').get();
  return rows.map((row) => row.data).toList();
});

final libraryFavoritesProvider =
    FutureProvider.autoDispose<List<Channel>>((ref) async {
  final db = ref.read(databaseProvider);
  return db.favoritesDao.getFavoriteChannels();
});

/// Unified Netflix-style library, independent of raw playlist structure.
class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final continueWatching = ref.watch(continueWatchingProvider);
    final recent = ref.watch(libraryRecentlyAddedProvider);
    final favorites = ref.watch(libraryFavoritesProvider);
    final discovery = ref.watch(discoveryProvider);

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        const _LibraryHeader(),
        _buildContinue(context, continueWatching.valueOrNull ?? []),
        _buildRecent(context, ref, recent.valueOrNull ?? []),
        _buildFavorites(context, favorites.valueOrNull ?? []),
        _buildRecommended(discovery.valueOrNull ?? []),
        if ([continueWatching, recent, favorites, discovery]
            .every((state) => state.isLoading))
          const Padding(
            padding: EdgeInsets.all(48),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildContinue(
      BuildContext context, List<Map<String, dynamic>> items) {
    return _row(
      'Continue assistindo',
      items,
      progress: true,
      onTap: (item) => _openStream(context, item),
    );
  }

  Widget _buildRecent(
    BuildContext context,
    WidgetRef ref,
    List<Map<String, dynamic>> items,
  ) {
    return _row(
      'Adicionados recentemente',
      items,
      onTap: (item) {
        if (item['source_type'] == 'series') {
          final match = ref
              .read(seriesScreenProvider)
              .allSeries
              .where((series) => series.id == item['id']);
          if (match.isNotEmpty) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SeriesDetailScreen(series: match.first),
              ),
            );
          }
        } else {
          _openStream(context, item);
        }
      },
    );
  }

  Widget _buildFavorites(BuildContext context, List<Channel> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: ContentRow(
        title: 'Favoritos',
        items: items
            .map(
              (channel) => ContentRowItem(
                title: channel.name,
                imageUrl: channel.logoUrl,
                fallbackIcon: Icons.live_tv_rounded,
              ),
            )
            .toList(),
        onItemTap: (index) {
          final channel = items[index];
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PlayerScreen(
                channelName: channel.name,
                streamUrl: channel.streamUrl,
                logoUrl: channel.logoUrl,
                contentInfo: WatchContentInfo(
                  channelId: channel.id,
                  name: channel.name,
                  contentType: 'live',
                  thumbnailUrl: channel.logoUrl,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecommended(List<SearchResultItem> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: ContentRow(
        title: 'Recomendados para você',
        items: items
            .map(
              (item) => ContentRowItem(
                title: item.name,
                imageUrl: item.logoUrl,
                fallbackIcon:
                    item.isSeries ? Icons.tv_rounded : Icons.movie_rounded,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _row(
    String title,
    List<Map<String, dynamic>> items, {
    bool progress = false,
    required void Function(Map<String, dynamic>) onTap,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: ContentRow(
        title: title,
        items: items.map((item) {
          final value = (item['progress_percent'] as num?)?.toDouble();
          return ContentRowItem(
            title: item['content_name'] as String? ??
                item['name'] as String? ??
                'Conteúdo',
            imageUrl:
                item['thumbnail_url'] as String? ?? item['logo_url'] as String?,
            progress: progress && value != null ? value / 100 : null,
            fallbackIcon: item['source_type'] == 'series'
                ? Icons.tv_rounded
                : Icons.movie_rounded,
          );
        }).toList(),
        onItemTap: (index) => onTap(items[index]),
      ),
    );
  }

  void _openStream(BuildContext context, Map<String, dynamic> item) {
    final url = item['stream_url'] as String?;
    if (url == null || url.isEmpty) return;
    final name = item['content_name'] as String? ??
        item['name'] as String? ??
        'Conteúdo';
    final image =
        item['thumbnail_url'] as String? ?? item['logo_url'] as String?;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          channelName: name,
          streamUrl: url,
          logoUrl: image,
          contentInfo: WatchContentInfo(
            channelId: item['channel_id'] as int? ?? item['id'] as int,
            name: name,
            contentType: item['source_type'] as String? ?? 'vod',
            thumbnailUrl: image,
          ),
        ),
      ),
    );
  }
}

class _LibraryHeader extends StatelessWidget {
  const _LibraryHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF151235), Color(0xFF0C6566)]),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withValues(alpha: .18), blurRadius: 24)
        ],
      ),
      child: Row(
        children: [
          const NebulaBrand(height: 46),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              'Sua biblioteca, organizada para você',
              style: AppTypography.headline.copyWith(fontSize: 22),
            ),
          ),
        ],
      ),
    );
  }
}
