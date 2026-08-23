import 'package:drift/drift.dart' hide Column;
import 'package:nebula_iptv/core/logging/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';
import 'package:nebula_iptv/core/theme/app_typography.dart';
import 'package:nebula_iptv/data/database/app_database.dart' hide SeriesItem;
import 'package:nebula_iptv/domain/providers/watch_providers.dart';
import 'package:nebula_iptv/domain/services/smart_favorites_service.dart';
import 'package:nebula_iptv/features/channels/providers/channels_provider.dart';
import 'package:nebula_iptv/features/player/player_screen.dart';
import 'package:nebula_iptv/features/series/series_detail_screen.dart';
import 'package:nebula_iptv/features/series/providers/series_provider.dart' show SeriesItem;
import 'package:nebula_iptv/domain/services/watch_tracking_service.dart';
import 'package:nebula_iptv/features/search/providers/search_provider.dart';
import 'package:nebula_iptv/features/shared/widgets/content_card.dart';
import 'package:nebula_iptv/features/shared/widgets/content_row.dart';
import 'package:nebula_iptv/features/shared/widgets/hero_banner.dart';
import 'package:nebula_iptv/features/shortcuts/providers/shortcut_provider.dart';
import 'package:nebula_iptv/features/profiles/providers/profile_provider.dart';
import 'package:nebula_iptv/l10n/app_localizations.dart';
import 'package:nebula_iptv/features/shared/providers/rating_provider.dart';
import 'package:nebula_iptv/features/shared/widgets/shortcut_context_menu.dart';
import 'package:nebula_iptv/features/sua_tv/sua_tv_player_screen.dart';

/// Provider for favorite channels on Home.
final homeFavoritesProvider = FutureProvider.autoDispose<List<Channel>>((ref) async {
  final db = ref.read(databaseProvider);
  return db.favoritesDao.getFavoriteChannels();
});

/// Provider for recently added VOD/Series (last 20).
final recentlyAddedProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final db = ref.read(databaseProvider);
  final rows = await db.customSelect(
    '''
    SELECT id, playlist_id, name, logo_url, stream_url, group_name, source_id, source_type
    FROM channels
    WHERE source_type IN ('vod', 'series')
      AND is_active = 1
      AND logo_url IS NOT NULL
      AND logo_url != ''
    ORDER BY id DESC
    LIMIT 20
    ''',
  ).get();
  return rows.map((r) => r.data).toList();
});

/// Home screen — Netflix-style with hero banner and carousels.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final continueWatching = ref.watch(continueWatchingProvider);
    final mostWatched = ref.watch(mostWatchedProvider);
    final favorites = ref.watch(homeFavoritesProvider);
    final discovery = ref.watch(discoveryProvider);
    final recentlyAdded = ref.watch(recentlyAddedProvider);
    final shortcuts = ref.watch(shortcutsProvider);
    final topRated = ref.watch(topRatedProvider);

    // Trigger background enrichment (runs 30s after app start)
    ref.watch(batchEnrichmentTriggerProvider);

    final hasContent = continueWatching.valueOrNull?.isNotEmpty == true ||
        mostWatched.valueOrNull?.isNotEmpty == true ||
        favorites.valueOrNull?.isNotEmpty == true ||
        recentlyAdded.valueOrNull?.isNotEmpty == true;

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
      padding: EdgeInsets.zero,
      children: [
        // Hero Banner — from continue watching or discovery
        _buildHeroBanner(context, ref, continueWatching, discovery),

        const SizedBox(height: 20),

        // Shortcuts / Pinned items
        if (shortcuts.valueOrNull?.isNotEmpty == true)
          _buildShortcutsRow(context, ref, shortcuts.value!),

        // Continue Watching carousel (with progress bars)
        if (continueWatching.valueOrNull?.isNotEmpty == true)
          _buildContinueWatchingRow(context, ref, continueWatching.value!),

        // Favorites carousel
        if (favorites.valueOrNull?.isNotEmpty == true)
          _buildFavoritesRow(context, ref, favorites.value!, l10n),

        // Discovery / Recommendations
        if (discovery.valueOrNull?.isNotEmpty == true)
          _buildDiscoveryRow(context, ref, discovery.value!),

        // Recently added
        if (recentlyAdded.valueOrNull?.isNotEmpty == true)
          _buildRecentlyAddedRow(context, ref, recentlyAdded.value!),

        // Top rated by user
        if (topRated.valueOrNull?.isNotEmpty == true)
          _buildTopRatedRow(context, topRated.value!),

        // Most watched
        if (mostWatched.valueOrNull?.isNotEmpty == true)
          _buildMostWatchedRow(context, ref, mostWatched.value!),

        // "Surpreenda-me" button
        Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: _buildSuaTvButton(context),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
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

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildHeroBanner(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Map<String, dynamic>>> continueWatching,
    AsyncValue<List<SearchResultItem>> discovery,
  ) {
    final heroItems = <HeroBannerItem>[];

    // Use continue watching items first
    final cwItems = continueWatching.valueOrNull ?? [];
    for (final entry in cwItems.take(3)) {
      final name = entry['content_name'] as String? ??
          entry['channel_name'] as String? ?? 'Canal';
      final thumbnailUrl = entry['thumbnail_url'] as String? ??
          entry['logo_url'] as String?;
      final progress = (entry['progress_percent'] as num?)?.toDouble() ?? 0.0;
      final remainingMin = (() {
        final totalMs = entry['total_duration_ms'] as int? ?? 0;
        return ((totalMs - (totalMs * progress)) / 60000).round();
      })();

      heroItems.add(HeroBannerItem(
        title: name,
        subtitle: remainingMin > 0
            ? '${remainingMin}min restantes'
            : 'Continuar assistindo',
        imageUrl: thumbnailUrl,
        onPlay: () => _playFromHistory(context, ref, entry),
      ));
    }

    // Fill from discovery if not enough
    final discItems = discovery.valueOrNull ?? [];
    for (final item in discItems.take(5 - heroItems.length)) {
      if (item.logoUrl != null && item.logoUrl!.isNotEmpty) {
        heroItems.add(HeroBannerItem(
          title: item.name,
          subtitle: item.groupName?.split('|').last.trim(),
          imageUrl: item.logoUrl,
          onPlay: () => _openSearchResult(context, ref, item),
          onDetails: () => _openSearchResult(context, ref, item),
        ));
      }
    }

    if (heroItems.isEmpty) return const SizedBox.shrink();

    return HeroBanner(items: heroItems);
  }

  Widget _buildContinueWatchingRow(
    BuildContext context,
    WidgetRef ref,
    List<Map<String, dynamic>> items,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Continuar assistindo',
                style: AppTypography.title.copyWith(fontSize: 16)),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 230,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final entry = items[index];
                final name = entry['content_name'] as String? ??
                    entry['channel_name'] as String? ?? 'Canal';
                final thumbnailUrl = entry['thumbnail_url'] as String? ??
                    entry['logo_url'] as String?;
                final progress =
                    (entry['progress_percent'] as num?)?.toDouble() ?? 0.0;

                return Padding(
                  padding: EdgeInsets.only(
                      right: index < items.length - 1 ? 12 : 0),
                  child: ContentCard(
                    title: name,
                    imageUrl: thumbnailUrl,
                    progress: progress > 0.01 ? progress : null,
                    fallbackIcon: _iconForContentType(
                        entry['content_type'] as String? ?? 'live'),
                    onTap: () => _playFromHistory(context, ref, entry),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesRow(
    BuildContext context,
    WidgetRef ref,
    List<Channel> channels,
    AppLocalizations l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: ContentRow(
        title: l10n.favorites,
        items: channels.map((ch) {
          return ContentRowItem(
            title: ch.name,
            imageUrl: ch.logoUrl,
            fallbackIcon: Icons.live_tv_rounded,
          );
        }).toList(),
        onItemTap: (index) {
          final channel = channels[index];
          Navigator.of(context).push(MaterialPageRoute(
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
          ));
        },
        onItemSecondaryTap: (index, position) {
          final channel = channels[index];
          showShortcutContextMenu(
            context, ref,
            position: position,
            channelId: channel.id,
            channelName: channel.name,
          );
        },
      ),
    );
  }

  Widget _buildDiscoveryRow(
    BuildContext context,
    WidgetRef ref,
    List<SearchResultItem> items,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: ContentRow(
        title: 'Recomendados para você',
        items: items.map((item) {
          return ContentRowItem(
            title: item.name,
            imageUrl: item.logoUrl,
            fallbackIcon:
                item.isSeries ? Icons.tv_rounded : Icons.movie_rounded,
          );
        }).toList(),
        onItemTap: (index) {
          _openSearchResult(context, ref, items[index]);
        },
      ),
    );
  }

  Widget _buildRecentlyAddedRow(
    BuildContext context,
    WidgetRef ref,
    List<Map<String, dynamic>> items,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: ContentRow(
        title: 'Adicionados recentemente',
        items: items.map((item) {
          final sourceType = item['source_type'] as String? ?? '';
          return ContentRowItem(
            title: item['name'] as String? ?? '',
            imageUrl: item['logo_url'] as String?,
            badge: 'Novo',
            fallbackIcon:
                sourceType == 'series' ? Icons.tv_rounded : Icons.movie_rounded,
          );
        }).toList(),
        onItemTap: (index) {
          final item = items[index];
          final searchItem = SearchResultItem(
            id: item['id'] as int,
            playlistId: item['playlist_id'] as int? ?? 0,
            name: item['name'] as String? ?? '',
            logoUrl: item['logo_url'] as String?,
            streamUrl: item['stream_url'] as String?,
            groupName: item['group_name'] as String?,
            sourceId: item['source_id'] as String?,
            sourceType: item['source_type'] as String? ?? 'vod',
          );
          _openSearchResult(context, ref, searchItem);
        },
        onItemSecondaryTap: (index, position) {
          final item = items[index];
          showShortcutContextMenu(
            context, ref,
            position: position,
            channelId: item['id'] as int,
            channelName: item['name'] as String? ?? '',
          );
        },
      ),
    );
  }


  Widget _buildTopRatedRow(BuildContext context, List<Map<String, dynamic>> items) {
    final rowItems = items.map((item) {
      return ContentRowItem(
        title: item['name'] as String? ?? '',
        imageUrl: item['logo_url'] as String?,
        subtitle: '⭐ ${(item['rating'] as num?)?.toStringAsFixed(1) ?? ''}',
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: ContentRow(
        title: '⭐ Seus mais bem avaliados',
        items: rowItems,
        onItemTap: (index) {
          final item = items[index];
          final streamUrl = item['stream_url'] as String? ?? '';
          final name = item['name'] as String? ?? '';
          if (streamUrl.isNotEmpty) {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => PlayerScreen(
                channelName: name,
                streamUrl: streamUrl,
              ),
            ));
          }
        },
      ),
    );
  }

  Widget _buildMostWatchedRow(
    BuildContext context,
    WidgetRef ref,
    List<FavoriteSuggestion> items,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: ContentRow(
        title: 'Mais assistidos',
        items: items.map((item) {
          return ContentRowItem(
            title: item.name,
            subtitle: item.formattedWatchTime,
            fallbackIcon: Icons.trending_up_rounded,
          );
        }).toList(),
        onItemTap: (index) {
          final item = items[index];
          if (item.streamUrl != null && item.streamUrl!.isNotEmpty) {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => PlayerScreen(
                channelName: item.name,
                streamUrl: item.streamUrl!,
              ),
            ));
          }
        },
      ),
    );
  }

  IconData _iconForContentType(String type) {
    switch (type) {
      case 'vod':
        return Icons.movie_rounded;
      case 'series':
        return Icons.tv_rounded;
      default:
        return Icons.live_tv_rounded;
    }
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

  Widget _buildShortcutsRow(
    BuildContext context,
    WidgetRef ref,
    List<Map<String, dynamic>> items,
  ) {
    final rowItems = items.map((item) {
      final name = item['name'] as String? ?? '';
      final logoUrl = item['logo_url'] as String?;
      final sourceType = item['source_type'] as String? ?? 'xtream';
      return ContentRowItem(
        title: name,
        imageUrl: logoUrl,
        fallbackIcon: sourceType == 'vod'
            ? Icons.movie_rounded
            : sourceType == 'series'
                ? Icons.tv_rounded
                : Icons.live_tv_rounded,
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: ContentRow(
        title: '⚡ Meus Atalhos',
        items: rowItems,
        onItemTap: (index) {
          final item = items[index];
          final streamUrl = item['stream_url'] as String? ?? '';
          final name = item['name'] as String? ?? '';
          final logoUrl = item['logo_url'] as String?;
          final channelId = item['channel_id'] as int? ?? 0;
          final sourceType = item['source_type'] as String? ?? 'xtream';
          if (streamUrl.isNotEmpty) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PlayerScreen(
                  channelName: name,
                  streamUrl: streamUrl,
                  logoUrl: logoUrl,
                  contentInfo: WatchContentInfo(
                    channelId: channelId,
                    name: name,
                    contentType: sourceType == 'live' ? 'live' : 'vod',
                    thumbnailUrl: logoUrl,
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
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
        entry['channel_name'] as String? ?? 'Canal';
    final contentType = entry['content_type'] as String? ?? 'live';
    final channelId = entry['channel_id'] as int? ?? 0;
    final thumbnailUrl = entry['thumbnail_url'] as String?;

    // Series: navigate to detail screen
    if (contentType == 'series') {
      try {
        final db = ref.read(databaseProvider);
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
  Widget _buildSuaTvButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SuaTvPlayerScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, Color(0xFFF107A3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.play_circle_filled_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text('Sua TV', style: AppTypography.body.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
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
            Text(label,
                style: AppTypography.caption
                    .copyWith(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
