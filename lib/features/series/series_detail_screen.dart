import 'dart:ui';
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
import 'package:nebula_iptv/data/datasources/tmdb/tmdb_datasource.dart' show TmdbDataSource;
import 'package:nebula_iptv/core/constants/tmdb_constants.dart';
import 'package:nebula_iptv/core/result/result.dart';
import 'package:nebula_iptv/features/shared/widgets/star_rating.dart';
import 'package:nebula_iptv/features/shared/providers/rating_provider.dart';
import 'package:nebula_iptv/features/profiles/providers/profile_provider.dart';
import 'package:nebula_iptv/features/channels/providers/channels_provider.dart';

/// Series detail screen with seasons and episodes.
/// Fetches TMDB details on-demand.
class SeriesDetailScreen extends ConsumerStatefulWidget {
  final SeriesItem series;

  const SeriesDetailScreen({
    super.key,
    required this.series,
  });

  @override
  ConsumerState<SeriesDetailScreen> createState() => _SeriesDetailScreenState();
}

class _SeriesDetailScreenState extends ConsumerState<SeriesDetailScreen> {
  bool _isLoadingTmdb = false;
  // TMDB enriched data
  String? _tmdbBackdropUrl;
  String? _tmdbOverview;
  String? _tmdbGenres;
  String? _tmdbCast;
  String? _tmdbRating;

  SeriesItem get series => widget.series;

  @override
  void initState() {
    super.initState();
    _fetchTmdbDetails();
  }

  Future<void> _fetchTmdbDetails() async {
    // Skip if already has plot
    if (series.plot != null && series.plot!.isNotEmpty) return;
    if (series.tmdbOverview != null && series.tmdbOverview!.isNotEmpty) return;

    setState(() => _isLoadingTmdb = true);

    try {
      final tmdb = TmdbDataSource();
      final searchResult = await tmdb.searchTv(series.name);
      if (searchResult case Failure()) {
        setState(() => _isLoadingTmdb = false);
        return;
      }
      final results = (searchResult as Success).data;
      if (results.isEmpty) {
        setState(() => _isLoadingTmdb = false);
        return;
      }

      final match = results.first;
      final detailsResult = await tmdb.getTvDetails(match.id);
      if (detailsResult case Failure()) {
        setState(() => _isLoadingTmdb = false);
        return;
      }

      final details = (detailsResult as Success).data;

      if (mounted) {
        setState(() {
          _tmdbBackdropUrl = details.backdropPath != null
              ? '${TmdbConstants.imageBaseUrl}/${TmdbConstants.backdropSizeLarge}${details.backdropPath}'
              : null;
          _tmdbOverview = details.overview;
          _tmdbGenres = details.genres.map((g) => g.name).join(', ');
          _tmdbCast = details.cast.take(5).map((c) => c.name).join(', ');
          _tmdbRating = details.voteAverage > 0
              ? details.voteAverage.toStringAsFixed(1)
              : null;
          _isLoadingTmdb = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingTmdb = false);
    }
  }

  String? get _backdropUrl =>
      _tmdbBackdropUrl ?? series.tmdbBackdropUrl ?? series.coverUrl;
  String? get _synopsis =>
      _tmdbOverview ?? series.tmdbOverview ?? series.plot;
  String? get _genres => _tmdbGenres ?? series.tmdbGenres ?? series.genre;
  String? get _cast => _tmdbCast ?? series.tmdbCast ?? series.cast;
  String? get _rating => _tmdbRating ?? series.rating;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(seriesDetailProvider(series.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App bar with cover
          SliverAppBar(
            expandedHeight: 300,
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
                  if (_backdropUrl != null && _backdropUrl!.isNotEmpty)
                    _buildBackdropImage()
                  else
                    _buildCoverPlaceholder(),

                  // Gradient overlay
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black26,
                          Colors.transparent,
                          Colors.black54,
                          AppColors.background,
                        ],
                        stops: [0.0, 0.3, 0.7, 1.0],
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
                  _buildMetadataRow(),
                  const SizedBox(height: 16),

                  // User rating
                  _buildUserRating(),
                  const SizedBox(height: 16),

                  // Loading TMDB
                  if (_isLoadingTmdb)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    ),

                  // Synopsis
                  if (_synopsis != null && _synopsis!.isNotEmpty) ...[
                    Text(
                      _synopsis!,
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
                  if (_cast != null && _cast!.isNotEmpty) ...[
                    _buildInfoRow('Elenco', _cast!),
                    const SizedBox(height: 8),
                  ],

                  // Genres
                  if (_genres != null && _genres!.isNotEmpty) ...[
                    _buildInfoRow('Gêneros', _genres!),
                    const SizedBox(height: 8),
                  ],

                  const SizedBox(height: 24),
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: 16),

                  // Seasons section
                  _buildSeasonsSection(context, state),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataRow() {
    final items = <Widget>[];

    if (_rating != null && _rating!.isNotEmpty && _rating != '0') {
      items.add(Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
            const SizedBox(width: 4),
            Text(
              _rating!,
              style: AppTypography.label.copyWith(
                color: Colors.amber,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ));
    }

    if (_genres != null && _genres!.isNotEmpty) {
      if (items.isNotEmpty) items.add(const SizedBox(width: 12));
      items.add(Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          _genres!.split(',').first.trim(),
          style: AppTypography.label,
        ),
      ));
    }

    if (series.categoryName != null) {
      if (items.isNotEmpty) items.add(const SizedBox(width: 12));
      items.add(Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          series.categoryName!,
          style: AppTypography.label,
        ),
      ));
    }

    if (items.isEmpty) return const SizedBox.shrink();
    return Row(children: items);
  }

  Widget _buildBackdropImage() {
    final url = _backdropUrl!;
    // If we have a TMDB backdrop (wide image), use directly
    if (_tmdbBackdropUrl != null ||
        (series.tmdbBackdropUrl != null && series.tmdbBackdropUrl!.isNotEmpty)) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildCoverPlaceholder(),
      );
    }
    // Otherwise blur the cover/poster
    return Stack(
      fit: StackFit.expand,
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildCoverPlaceholder(),
          ),
        ),
        Center(
          child: Image.network(
            url,
            fit: BoxFit.contain,
            height: 220,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  Widget _buildSeasonsSection(BuildContext context, SeriesDetailState state) {
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
        Text('Temporadas', style: AppTypography.title),
        const SizedBox(height: 12),

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

        if (currentSeason != null && currentSeason.episodes.isNotEmpty)
          ...currentSeason.episodes.asMap().entries.map(
            (entry) => EpisodeTile(
              episode: entry.value,
              onPlay: () => _playEpisode(
                context,
                entry.value,
                seasonEpisodes: currentSeason.episodes,
                episodeIndex: entry.key,
              ),
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

  Widget _buildUserRating() {
    final ratingAsync = ref.watch(ratingProvider(series.id));
    final currentRating = ratingAsync.valueOrNull ?? 0.0;

    return Row(
      children: [
        Text(
          'Sua avaliação:',
          style: AppTypography.body.copyWith(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 12),
        StarRating(
          rating: currentRating,
          onRatingChanged: (value) async {
            final profileId = ref.read(activeProfileProvider);
            final db = ref.read(databaseProvider);
            await db.ratingsDao.setRating(profileId, series.id, value);
            ref.invalidate(ratingProvider(series.id));
          },
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

  void _playEpisode(
    BuildContext context,
    EpisodeItem episode, {
    List<EpisodeItem>? seasonEpisodes,
    int? episodeIndex,
  }) {
    int? seekToMs;
    if (episode.watchProgress > 0.01 && episode.watchProgress < 0.95) {
      if (episode.watchedDurationMs > 5000) {
        seekToMs = episode.watchedDurationMs;
      } else if (episode.totalDurationMs > 0) {
        seekToMs = (episode.watchProgress * episode.totalDurationMs).round();
      }
    }
    appLogger.d('[Series] Play episode ${episode.episodeNumber}: progress=${episode.watchProgress}, seekToMs=$seekToMs');

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          channelName: '${series.name} - ${episode.title}',
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
          episodePlaylist: seasonEpisodes,
          currentEpisodeIndex: episodeIndex,
        ),
      ),
    );
  }
}
