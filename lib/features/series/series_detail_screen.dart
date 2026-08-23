import 'package:flutter/material.dart';
import 'package:nebula_iptv/core/logging/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';
import 'package:nebula_iptv/core/theme/app_typography.dart';
import 'package:nebula_iptv/core/widgets/focusable_widget.dart';
import 'package:nebula_iptv/core/widgets/loading_view.dart';
import 'package:nebula_iptv/features/player/player_screen.dart';
import 'package:nebula_iptv/domain/services/watch_tracking_service.dart';
import 'package:nebula_iptv/features/series/providers/series_provider.dart';
import 'package:nebula_iptv/features/series/widgets/episode_tile.dart';
import 'package:nebula_iptv/features/series/widgets/season_selector.dart';

/// Series detail screen with seasons and episodes.
///
/// Netflix-style layout: cover image, series info, season selector tabs,
/// and episode list for the selected season.
class SeriesDetailScreen extends ConsumerWidget {
  final SeriesItem series;

  const SeriesDetailScreen({
    super.key,
    required this.series,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(seriesDetailProvider(series.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App bar with cover
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            backgroundColor: AppColors.background,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Cover image
                  if (series.coverUrl != null && series.coverUrl!.isNotEmpty)
                    Image.network(
                      series.coverUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildCoverPlaceholder(),
                    )
                  else
                    _buildCoverPlaceholder(),

                  // Gradient overlay
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.transparent,
                          AppColors.background,
                        ],
                        stops: [0.0, 0.4, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Series info and episodes
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(series.name, style: AppTypography.headline),
                  const SizedBox(height: 12),

                  // Metadata row
                  Row(
                    children: [
                      if (series.rating != null &&
                          series.rating!.isNotEmpty &&
                          series.rating != '0') ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                series.rating!,
                                style: AppTypography.label.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (series.genre != null &&
                          series.genre!.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            series.genre!,
                            style: AppTypography.label,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (series.categoryName != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            series.categoryName!,
                            style: AppTypography.label,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Plot/Synopsis
                  if (series.plot != null && series.plot!.isNotEmpty) ...[
                    Text(
                      series.plot!,
                      style: AppTypography.body.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Director
                  if (series.director != null &&
                      series.director!.isNotEmpty) ...[
                    _buildInfoRow('Diretor', series.director!),
                    const SizedBox(height: 8),
                  ],

                  // Cast
                  if (series.cast != null && series.cast!.isNotEmpty) ...[
                    _buildInfoRow('Elenco', series.cast!),
                    const SizedBox(height: 8),
                  ],

                  const SizedBox(height: 24),
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: 16),

                  // Seasons section
                  _buildSeasonsSection(context, ref, state),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonsSection(
    BuildContext context,
    WidgetRef ref,
    SeriesDetailState state,
  ) {
    if (state.isLoading) {
      return const SizedBox(
        height: 200,
        child: LoadingView(),
      );
    }

    if (state.seasons.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Temporadas', style: AppTypography.title),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.upcoming_rounded,
                    size: 40,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Temporadas e episódios serão carregados\nquando a integração com Xtream for concluída.',
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final currentSeason = state.currentSeason;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Text('Temporadas', style: AppTypography.title),
        const SizedBox(height: 12),

        // Season selector tabs
        SeasonSelector(
          seasons: state.seasons,
          selectedIndex: state.selectedSeasonIndex,
          onSelected: (index) {
            ref
                .read(seriesDetailProvider(series.id).notifier)
                .selectSeason(index);
          },
        ),
        const SizedBox(height: 16),

        // Episode list
        if (currentSeason != null && currentSeason.episodes.isNotEmpty)
          ...currentSeason.episodes.map(
            (episode) => EpisodeTile(
              episode: episode,
              onPlay: () => _playEpisode(context, episode),
            ),
          )
        else if (state.isLoadingEpisodes)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'Nenhum episódio disponível nesta temporada.',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildCoverPlaceholder() {
    return Container(
      color: AppColors.surfaceElevated,
      child: const Center(
        child: Icon(
          Icons.tv_rounded,
          size: 80,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  void _playEpisode(BuildContext context, EpisodeItem episode) {
    // Calculate seek position from saved watch data
    // watchedDurationMs = actual player position in ms (most reliable)
    int? seekToMs;
    if (episode.watchProgress > 0.01 && episode.watchProgress < 0.95) {
      if (episode.watchedDurationMs > 5000) {
        seekToMs = episode.watchedDurationMs;
      } else if (episode.totalDurationMs > 0) {
        seekToMs = (episode.watchProgress * episode.totalDurationMs).round();
      }
    }
    appLogger.d('[Series] Play episode ${episode.episodeNumber}: progress=${episode.watchProgress}, watchedMs=${episode.watchedDurationMs}, totalMs=${episode.totalDurationMs}, seekToMs=$seekToMs');

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          channelName: '\${series.name} - \${episode.title}',
          streamUrl: episode.streamUrl,
          contentInfo: WatchContentInfo(
            channelId: series.id,
            name: series.name,
            contentType: 'series',
            thumbnailUrl: episode.coverUrl ?? series.coverUrl,
            seriesId: series.id,
            seasonNumber: episode.seasonId,
            episodeNumber: episode.episodeNumber,
            episodeTitle: episode.title,
          ),
          seekToMs: seekToMs != null && seekToMs > 5000 ? seekToMs : null,
        ),
      ),
    );
  }
}
