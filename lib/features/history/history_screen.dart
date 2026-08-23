import 'package:drift/drift.dart' hide Column;
import 'package:nebula_iptv/core/logging/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';
import 'package:nebula_iptv/core/theme/app_typography.dart';
import 'package:nebula_iptv/core/widgets/loading_view.dart';
import 'package:nebula_iptv/data/database/app_database.dart' hide SeriesItem;
import 'package:nebula_iptv/domain/providers/watch_providers.dart';
import 'package:nebula_iptv/features/channels/providers/channels_provider.dart';
import 'package:nebula_iptv/features/player/player_screen.dart';
import 'package:nebula_iptv/features/series/series_detail_screen.dart';
import 'package:nebula_iptv/features/series/providers/series_provider.dart' show SeriesItem;
import 'package:nebula_iptv/domain/services/watch_tracking_service.dart';

/// History screen — shows recent viewing activity.
///
/// Tabs: Todos | Canais | Filmes | Séries
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _selectedFilter = 'all';

  static const _filters = [
    ('all', 'Todos'),
    ('live', 'Canais'),
    ('vod', 'Filmes'),
    ('series', 'Séries'),
  ];

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(watchHistoryProvider(
      _selectedFilter == 'all' ? null : _selectedFilter,
    ));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('Histórico', style: AppTypography.headline),
        ),

        // Filter chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters.map((filter) {
                final isSelected = _selectedFilter == filter.$1;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter.$2),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _selectedFilter = filter.$1);
                    },
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                    checkmarkColor: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // History list
        Expanded(
          child: historyAsync.when(
            loading: () => const LoadingView(),
            error: (e, _) => Center(
              child: Text(
                'Erro ao carregar histórico',
                style: AppTypography.body.copyWith(color: AppColors.textSecondary),
              ),
            ),
            data: (entries) {
              if (entries.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.history_rounded,
                        size: 48,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Nenhum histórico ainda.\nComece a assistir para ver seu histórico aqui.',
                        textAlign: TextAlign.center,
                        style: AppTypography.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return _HistoryTile(
                    entry: entry,
                    onTap: () => _playEntry(entry),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _playEntry(Map<String, dynamic> entry) async {
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
        if (chRows.isNotEmpty && mounted) {
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
        appLogger.e('[History] Error opening series: $e\n$st');
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

    Navigator.of(context).push(
      MaterialPageRoute(
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
      ),
    );
  }
}

/// A single history entry tile.
class _HistoryTile extends StatelessWidget {
  final Map<String, dynamic> entry;
  final VoidCallback onTap;

  const _HistoryTile({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = entry['content_name'] as String? ??
        entry['channel_name'] as String? ??
        'Canal';
    final logoUrl = entry['thumbnail_url'] as String? ??
        entry['logo_url'] as String?;
    final contentType = entry['content_type'] as String? ?? 'live';
    final progressPercent = (entry['progress_percent'] as num?)?.toDouble() ?? 0.0;
    final watchedMs = entry['watched_duration_ms'] as int? ?? 0;
    final lastWatched = entry['last_watched_at'] as String?;
    final episodeTitle = entry['episode_title'] as String?;
    final seasonNumber = entry['season_number'] as int?;
    final episodeNumber = entry['episode_number'] as int?;

    // Format time ago
    final timeAgo = _formatTimeAgo(lastWatched);

    // Build subtitle
    String subtitle = '';
    if (contentType == 'series' && seasonNumber != null && episodeNumber != null) {
      subtitle = 'T$seasonNumber E$episodeNumber';
      if (episodeTitle != null) subtitle += ' • $episodeTitle';
    } else if (contentType == 'live') {
      subtitle = _formatDuration(watchedMs);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            // Thumbnail/logo
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: logoUrl != null && logoUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        logoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.live_tv_rounded,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  : Icon(
                      _getIcon(contentType),
                      color: AppColors.textSecondary,
                    ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTypography.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (timeAgo.isNotEmpty)
                    Text(
                      timeAgo,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  // Progress bar for VOD/series
                  if (contentType != 'live' && progressPercent > 0) ...[
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: progressPercent,
                        backgroundColor: AppColors.surface,
                        color: AppColors.primary,
                        minHeight: 3,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Play icon
            const Icon(
              Icons.play_circle_outline_rounded,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(String contentType) {
    return switch (contentType) {
      'vod' => Icons.movie_rounded,
      'series' => Icons.tv_rounded,
      _ => Icons.live_tv_rounded,
    };
  }

  String _formatTimeAgo(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 1) return 'Agora';
      if (diff.inMinutes < 60) return 'Há ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'Há ${diff.inHours}h';
      if (diff.inDays < 7) return 'Há ${diff.inDays} dias';
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return '';
    }
  }

  String _formatDuration(int ms) {
    if (ms <= 0) return '';
    final minutes = ms ~/ 60000;
    if (minutes < 60) return '${minutes}min assistidos';
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    return '${hours}h ${remaining}min assistidos';
  }
}
