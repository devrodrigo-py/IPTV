import 'package:drift/drift.dart' hide Column;
import 'package:nebula_iptv/core/logging/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';
import 'package:nebula_iptv/core/theme/app_typography.dart';
import 'package:nebula_iptv/core/widgets/focusable_widget.dart';
import 'package:nebula_iptv/data/database/app_database.dart' hide SeriesItem;
import 'package:nebula_iptv/domain/providers/watch_providers.dart';
import 'package:nebula_iptv/domain/services/smart_favorites_service.dart';
import 'package:nebula_iptv/features/channels/providers/channels_provider.dart';
import 'package:nebula_iptv/features/player/player_screen.dart';
import 'package:nebula_iptv/features/series/series_detail_screen.dart';
import 'package:nebula_iptv/features/series/providers/series_provider.dart' show SeriesItem;
import 'package:nebula_iptv/domain/services/watch_tracking_service.dart';
import 'package:nebula_iptv/features/search/providers/search_provider.dart';
import 'package:nebula_iptv/l10n/app_localizations.dart';

/// Provider for favorite channels on Home.
final homeFavoritesProvider = FutureProvider<List<Channel>>((ref) async {
  final db = ref.read(databaseProvider);
  return db.favoritesDao.getFavoriteChannels();
});

/// Home screen — main content area.
///
/// Shows "Continue Watching", "Most Watched", and "Favorites".
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final continueWatching = ref.watch(continueWatchingProvider);
    final mostWatched = ref.watch(mostWatchedProvider);
    final favorites = ref.watch(homeFavoritesProvider);
    final discovery = ref.watch(discoveryProvider);

    // Trigger background enrichment (runs 30s after app start)
    ref.watch(batchEnrichmentTriggerProvider);

    final hasContent = continueWatching.valueOrNull?.isNotEmpty == true ||
        mostWatched.valueOrNull?.isNotEmpty == true ||
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
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: continueWatching.value!.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final entry = continueWatching.value![index];
                return _ContinueWatchingCard(
                  entry: entry,
                  onTap: () => _playFromHistory(context, ref, entry),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Most Watched section
        if (mostWatched.valueOrNull?.isNotEmpty == true) ...[
          const _SectionHeader(title: 'Mais assistidos'),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: mostWatched.value!.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = mostWatched.value![index];
                return _MostWatchedCard(
                  item: item,
                  onTap: () {
                    if (item.streamUrl != null && item.streamUrl!.isNotEmpty) {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => PlayerScreen(
                          channelName: item.name,
                          streamUrl: item.streamUrl!,
                        ),
                      ));
                    }
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
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: favorites.value!.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final channel = favorites.value![index];
                return _ChannelCard(
                  channel: channel,
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => PlayerScreen(
                        channelName: channel.name,
                        streamUrl: channel.streamUrl,
                        logoUrl: channel.logoUrl,
                      ),
                    ));
                  },
                );
              },
            ),
          ),
        ],

        // Discovery / Recommendations
        if (discovery.valueOrNull?.isNotEmpty == true) ...[
          const _SectionHeader(title: 'Recomendados para você'),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: discovery.value!.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = discovery.value![index];
                return _DiscoveryCard(
                  item: item,
                  onTap: () => _openSearchResult(context, ref, item),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],

        // "Surpreenda-me" button
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: ElevatedButton.icon(
              onPressed: () => _showSurpriseMe(context, ref),
              icon: const Text('🎲', style: TextStyle(fontSize: 20)),
              label: const Text('Surpreenda-me'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surfaceElevated,
                foregroundColor: AppColors.textPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _openSearchResult(BuildContext context, WidgetRef ref, SearchResultItem item) {
    if (item.isSeries) {
      final seriesItem = SeriesItem(
        id: item.id,
        playlistId: item.playlistId,
        name: item.name,
        coverUrl: item.logoUrl,
        categoryName: item.groupName,
        sourceId: item.sourceId,
      );
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => SeriesDetailScreen(series: seriesItem),
      ));
    } else {
      if (item.streamUrl == null || item.streamUrl!.isEmpty) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => PlayerScreen(
          channelName: item.name,
          streamUrl: item.streamUrl!,
          logoUrl: item.logoUrl,
          contentInfo: WatchContentInfo(
            channelId: item.id,
            name: item.name,
            contentType: item.isVod ? 'vod' : 'live',
            thumbnailUrl: item.logoUrl,
          ),
        ),
      ));
    }
  }

  void _showSurpriseMe(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _SurpriseMeSheet(
        onPick: (contentType) async {
          Navigator.of(ctx).pop();
          final db = ref.read(databaseProvider);
          final String whereClause;
          if (contentType == 'vod') {
            whereClause = "source_type = 'vod'";
          } else if (contentType == 'series') {
            whereClause = "source_type = 'series'";
          } else {
            whereClause = "source_type IN ('xtream', 'm3u')";
          }
          final rows = await db.customSelect(
            'SELECT id, playlist_id, name, logo_url, stream_url, group_name, source_id, source_type '
            'FROM channels WHERE $whereClause AND is_active = 1 '
            'ORDER BY RANDOM() LIMIT 1',
          ).get();
          if (rows.isEmpty || !context.mounted) return;
          final row = rows.first;
          final item = SearchResultItem(
            id: row.read<int>('id'),
            playlistId: row.read<int>('playlist_id'),
            name: row.read<String>('name'),
            logoUrl: row.readNullable<String>('logo_url'),
            streamUrl: row.readNullable<String>('stream_url'),
            groupName: row.readNullable<String>('group_name'),
            sourceId: row.readNullable<String>('source_id'),
            sourceType: row.read<String>('source_type'),
          );
          if (context.mounted) _openSearchResult(context, ref, item);
        },
      ),
    );
  }

    void _playFromHistory(BuildContext context, WidgetRef ref, Map<String, dynamic> entry) async {
    final streamUrl = entry['stream_url'] as String?;
    final name = entry['content_name'] as String? ??
        entry['channel_name'] as String? ??
        'Canal';
    final contentType = entry['content_type'] as String? ?? 'live';
    final channelId = entry['channel_id'] as int? ?? 0;
    final thumbnailUrl = entry['thumbnail_url'] as String?;

    // Series: navigate to detail screen
    if (contentType == 'series') {
      try {
        final db = ref.read(databaseProvider);
        // Series are stored in channels table with source_type='series'
        final chRows = await db.customSelect(
          'SELECT * FROM channels WHERE id = ?',
          variables: [Variable.withInt(channelId)],
        ).get();
        if (chRows.isNotEmpty && context.mounted) {
          final ch = chRows.first;
          final seriesItem = SeriesItem(
            id: ch.read<int>('id'),
            playlistId: ch.read<int>('playlist_id'),
            name: ch.read<String>('name'),
            coverUrl: ch.readNullable<String>('logo_url'),
            categoryName: ch.readNullable<String>('group_name'),
            sourceId: ch.readNullable<String>('source_id'),
          );
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => SeriesDetailScreen(series: seriesItem),
          ));
        }
      } catch (e, st) {
        appLogger.e('[Home] Error opening series: $e\n$st');
      }
      return;
    }

    if (streamUrl == null || streamUrl.isEmpty) return;

    final progressPercent = (entry['progress_percent'] as num?)?.toDouble() ?? 0.0;
    final totalDurationMs = entry['total_duration_ms'] as int? ?? 0;
    final watchedDurationMs = entry['watched_duration_ms'] as int? ?? 0;
    final seekToMs = (progressPercent > 0 && totalDurationMs > 0)
        ? (progressPercent * totalDurationMs).round()
        : watchedDurationMs;

    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PlayerScreen(
        channelName: name,
        streamUrl: streamUrl,
        contentInfo: WatchContentInfo(
          channelId: channelId,
          name: name,
          contentType: contentType,
          thumbnailUrl: thumbnailUrl,
        ),
        seekToMs: seekToMs > 5000 ? seekToMs : null,
      ),
    ));
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
  final Map<String, dynamic> entry;
  final VoidCallback onTap;

  const _ContinueWatchingCard({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = entry['content_name'] as String? ??
        entry['channel_name'] as String? ??
        'Canal';
    final thumbnailUrl = entry['thumbnail_url'] as String? ??
        entry['logo_url'] as String?;
    final progress = (entry['progress_percent'] as num?)?.toDouble() ?? 0.0;
    final totalMs = entry['total_duration_ms'] as int? ?? 0;
    final watchedMs = entry['watched_duration_ms'] as int? ?? 0;
    final remainingMin = ((totalMs - (totalMs * progress)) / 60000).round();
    final episodeTitle = entry['episode_title'] as String?;

    return FocusableWidget(
      onPressed: onTap,
      borderRadius: BorderRadius.circular(12),
      builder: (context, isFocused) => Container(
        width: 200,
        decoration: BoxDecoration(
          color: isFocused ? AppColors.surfaceElevated : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: isFocused
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail area
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: thumbnailUrl != null && thumbnailUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: Image.network(
                          thumbnailUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.play_circle_outline,
                                color: AppColors.primary, size: 32),
                          ),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.play_circle_outline,
                            color: AppColors.primary, size: 32),
                      ),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTypography.label.copyWith(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (episodeTitle != null)
                    Text(
                      episodeTitle,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (remainingMin > 0)
                    Text(
                      '${remainingMin}min restantes',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppColors.surface,
                      color: AppColors.primary,
                      minHeight: 3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MostWatchedCard extends StatelessWidget {
  final dynamic item;
  final VoidCallback onTap;

  const _MostWatchedCard({required this.item, required this.onTap});

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
          border: isFocused
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up_rounded,
                    color: AppColors.primary, size: 18),
                const SizedBox(width: 6),
                Text(
                  item.formattedWatchTime,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.name,
              style: AppTypography.label.copyWith(fontSize: 12),
              maxLines: 2,
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

  const _ChannelCard({required this.channel, required this.onTap});

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
          border: isFocused
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (channel.logoUrl != null && channel.logoUrl!.isNotEmpty)
              Image.network(
                channel.logoUrl!,
                height: 24,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.live_tv_rounded,
                  color: AppColors.textSecondary,
                  size: 24,
                ),
              )
            else
              const Icon(
                Icons.live_tv_rounded,
                color: AppColors.textSecondary,
                size: 24,
              ),
            const SizedBox(height: 8),
            Text(
              channel.name,
              style: AppTypography.label.copyWith(fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}


class _DiscoveryCard extends StatelessWidget {
  final SearchResultItem item;
  final VoidCallback onTap;

  const _DiscoveryCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster/Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              child: SizedBox(
                height: 120,
                width: 130,
                child: item.logoUrl != null && item.logoUrl!.isNotEmpty
                    ? Image.network(
                        item.logoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.surfaceElevated,
                          child: const Icon(Icons.movie_rounded, color: AppColors.primary),
                        ),
                      )
                    : Container(
                        color: AppColors.surfaceElevated,
                        child: Icon(
                          item.isSeries ? Icons.tv_rounded : Icons.movie_rounded,
                          color: AppColors.primary,
                          size: 32,
                        ),
                      ),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: AppTypography.caption.copyWith(fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SurpriseMeSheet extends StatelessWidget {
  final void Function(String contentType) onPick;

  const _SurpriseMeSheet({required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '🎲 Surpreenda-me',
            style: AppTypography.title.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 8),
          Text(
            'Escolha o tipo de conteúdo:',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _SurpriseOption(
                icon: Icons.movie_rounded,
                label: 'Filme',
                onTap: () => onPick('vod'),
              ),
              _SurpriseOption(
                icon: Icons.tv_rounded,
                label: 'Série',
                onTap: () => onPick('series'),
              ),
              _SurpriseOption(
                icon: Icons.live_tv_rounded,
                label: 'Canal',
                onTap: () => onPick('live'),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SurpriseOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SurpriseOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 32),
            const SizedBox(height: 8),
            Text(label, style: AppTypography.caption.copyWith(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
