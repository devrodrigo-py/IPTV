import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';
import 'package:nebula_iptv/core/theme/app_typography.dart';
import 'package:nebula_iptv/core/widgets/focusable_widget.dart';
import 'package:nebula_iptv/features/player/player_screen.dart';
import 'package:nebula_iptv/domain/services/watch_tracking_service.dart';
import 'package:nebula_iptv/features/vod/providers/vod_provider.dart';
import 'package:nebula_iptv/data/datasources/tmdb/tmdb_datasource.dart' show TmdbDataSource;
import 'package:nebula_iptv/core/constants/tmdb_constants.dart';
import 'package:nebula_iptv/core/result/result.dart';
import 'package:nebula_iptv/features/shared/widgets/star_rating.dart';
import 'package:nebula_iptv/features/shared/providers/rating_provider.dart';
import 'package:nebula_iptv/data/database/app_database.dart' hide VodItem;
import 'package:nebula_iptv/data/datasources/xtream/xtream_datasource.dart';
import 'package:nebula_iptv/core/network/dio_client.dart';
import 'package:nebula_iptv/features/profiles/providers/profile_provider.dart';
import 'package:nebula_iptv/features/channels/providers/channels_provider.dart';

/// Movie detail screen — Netflix-style layout with backdrop, synopsis, metadata.
/// Fetches TMDB details on-demand when opened.
class VodDetailScreen extends ConsumerStatefulWidget {
  final VodItem movie;

  const VodDetailScreen({
    super.key,
    required this.movie,
  });

  @override
  ConsumerState<VodDetailScreen> createState() => _VodDetailScreenState();
}

class _VodDetailScreenState extends ConsumerState<VodDetailScreen> {
  bool _synopsisExpanded = false;
  late VodItem _movie;
  bool _isLoadingTmdb = false;

  @override
  void initState() {
    super.initState();
    _movie = widget.movie;
    _fetchTmdbDetails();
  }

  /// Fetch TMDB metadata on-demand if not already enriched.
  Future<void> _fetchTmdbDetails() async {
    // Skip if already has TMDB data
    if (_movie.tmdbOverview != null && _movie.tmdbOverview!.isNotEmpty) return;

    setState(() => _isLoadingTmdb = true);

    try {
      final tmdb = TmdbDataSource();

      // Search for the movie by name
      final searchResult = await tmdb.searchMovie(_movie.name);
      if (searchResult case Failure()) {
        setState(() => _isLoadingTmdb = false);
        return;
      }
      final results = (searchResult as Success).data;
      if (results.isEmpty) {
        setState(() => _isLoadingTmdb = false);
        return;
      }

      // Fetch full details
      final match = results.first;
      final detailsResult = await tmdb.getMovieDetails(match.id);
      if (detailsResult case Failure()) {
        setState(() => _isLoadingTmdb = false);
        return;
      }

      final details = (detailsResult as Success).data;

      // Update the movie with TMDB data
      setState(() {
        _movie = _movie.copyWithEnrichment(
          tmdbPosterUrl: details.posterPath != null
              ? '${TmdbConstants.imageBaseUrl}/${TmdbConstants.posterSizeLarge}${details.posterPath}'
              : null,
          tmdbBackdropUrl: details.backdropPath != null
              ? '${TmdbConstants.imageBaseUrl}/${TmdbConstants.backdropSizeLarge}${details.backdropPath}'
              : null,
          tmdbOverview: details.overview,
          tmdbGenres: details.genres.map((g) => g.name).join(', '),
          tmdbCast: details.cast.take(5).map((c) => c.name).join(', '),
          tmdbDirector: details.director,
          tmdbRating: details.voteAverage,
          tmdbReleaseDate: details.releaseDate,
          tmdbRuntime: details.runtime,
          tmdbId: details.id,
        );
        _isLoadingTmdb = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoadingTmdb = false);
    }
  }

  /// Best backdrop: TMDB backdrop > TMDB poster > logoUrl
  String? get _backdropUrl =>
      _movie.tmdbBackdropUrl ?? _movie.tmdbPosterUrl ?? _movie.logoUrl;

  /// Year from TMDB release date
  String? get _year {
    if (_movie.tmdbReleaseDate != null && _movie.tmdbReleaseDate!.length >= 4) {
      return _movie.tmdbReleaseDate!.substring(0, 4);
    }
    return null;
  }

  /// Runtime formatted
  String? get _runtime {
    if (_movie.tmdbRuntime != null && _movie.tmdbRuntime! > 0) {
      final h = _movie.tmdbRuntime! ~/ 60;
      final m = _movie.tmdbRuntime! % 60;
      return h > 0 ? '${h}h ${m}min' : '${m}min';
    }
    if (_movie.duration != null && _movie.duration!.isNotEmpty) {
      return _movie.duration!;
    }
    return null;
  }

  /// Rating display
  String? get _rating => _movie.displayRating;

  /// Synopsis
  String? get _synopsis => _movie.displayOverview ?? _movie.plot;

  /// Cast
  String? get _cast => _movie.tmdbCast ?? _movie.cast;

  /// Director
  String? get _director => _movie.tmdbDirector ?? _movie.director;

  /// Genres
  String? get _genres => _movie.tmdbGenres;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Backdrop header
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
                  // Backdrop image with blur if it's a poster
                  if (_backdropUrl != null && _backdropUrl!.isNotEmpty)
                    _buildBackdropImage()
                  else
                    _buildBackdropPlaceholder(),

                  // Dark gradient overlay
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

          // Movie details content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    _movie.name,
                    style: AppTypography.display.copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: 10),

                  // Metadata row: Year • Rating ★ • Duration
                  _buildMetadataRow(),
                  const SizedBox(height: 12),

                  // Category chip + genre chips
                  if (_movie.categoryName != null || _genres != null)
                    Wrap(
                      spacing: 8,
                      children: [
                        if (_movie.categoryName != null)
                          _buildChip(_movie.shortCategory),
                        if (_genres != null)
                          ..._genres!
                              .split(',')
                              .take(3)
                              .map((g) => _buildChip(g.trim())),
                      ],
                    ),
                  const SizedBox(height: 20),

                  // Play button
                  _buildPlayButton(),
                  const SizedBox(height: 16),

                  // User rating
                  _buildUserRating(),
                  const SizedBox(height: 20),

                  // Loading indicator for TMDB fetch
                  if (_isLoadingTmdb)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),

                  // Synopsis
                  if (_synopsis != null && _synopsis!.isNotEmpty) ...[
                    Text('Sinopse', style: AppTypography.title),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => setState(
                          () => _synopsisExpanded = !_synopsisExpanded),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _synopsis!,
                            style: AppTypography.body.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.6,
                            ),
                            maxLines: _synopsisExpanded ? null : 4,
                            overflow: _synopsisExpanded
                                ? null
                                : TextOverflow.ellipsis,
                          ),
                          if (_synopsis!.length > 200)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                _synopsisExpanded
                                    ? 'Ver menos'
                                    : 'Ver mais...',
                                style: AppTypography.label.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Director
                  if (_director != null && _director!.isNotEmpty) ...[
                    _buildInfoRow(Icons.movie_creation_outlined, 'Diretor',
                        _director!),
                    const SizedBox(height: 12),
                  ],

                  // Cast
                  if (_cast != null && _cast!.isNotEmpty) ...[
                    _buildInfoRow(Icons.people_outline_rounded, 'Elenco',
                        _cast!),
                    const SizedBox(height: 12),
                  ],

                  // Genres
                  if (_genres != null && _genres!.isNotEmpty) ...[
                    _buildInfoRow(
                        Icons.category_outlined, 'Gêneros', _genres!),
                    const SizedBox(height: 12),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackdropImage() {
    final url = _backdropUrl!;
    // If we have a dedicated backdrop (wide image), use it directly
    if (_movie.tmdbBackdropUrl != null && _movie.tmdbBackdropUrl!.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildBackdropPlaceholder(),
      );
    }
    // Otherwise use poster/logo with blur overlay for a softer look
    return Stack(
      fit: StackFit.expand,
      children: [
        // Blurred background
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildBackdropPlaceholder(),
          ),
        ),
        // Centered image on top
        Center(
          child: Image.network(
            url,
            fit: BoxFit.contain,
            height: 250,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  Widget _buildBackdropPlaceholder() {
    return Container(
      color: AppColors.surfaceElevated,
      child: const Center(
        child: Icon(
          Icons.movie_rounded,
          size: 80,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildMetadataRow() {
    final items = <Widget>[];

    if (_year != null) {
      items.add(Text(
        _year!,
        style: AppTypography.body.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ));
    }

    if (_rating != null && _rating != '0' && _rating != '0.0' && _rating!.isNotEmpty) {
      if (items.isNotEmpty) items.add(_dot());
      items.add(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
          const SizedBox(width: 4),
          Text(
            _rating!,
            style: AppTypography.body.copyWith(
              color: Colors.amber,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ));
    }

    if (_runtime != null) {
      if (items.isNotEmpty) items.add(_dot());
      items.add(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.schedule_rounded,
              size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            _runtime!,
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Row(children: items);
  }

  Widget _dot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(
        '•',
        style: AppTypography.body.copyWith(color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(
        label,
        style: AppTypography.label.copyWith(fontSize: 11),
      ),
    );
  }

  Widget _buildPlayButton() {
    return FocusableWidget(
      onPressed: () => _playMovie(context),
      borderRadius: BorderRadius.circular(12),
      builder: (context, isFocused) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isFocused ? AppColors.primaryVariant : AppColors.primary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isFocused
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
            SizedBox(width: 8),
            Text(
              'Assistir',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: AppTypography.body.copyWith(fontSize: 13),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }


  Widget _buildUserRating() {
    final ratingAsync = ref.watch(ratingProvider(_movie.id));
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
            await db.ratingsDao.setRating(profileId, _movie.id, value);
            ref.invalidate(ratingProvider(_movie.id));
          },
        ),
      ],
    );
  }

  Future<void> _playMovie(BuildContext context) async {
    var url = _movie.streamUrl;
    if (url.isEmpty || !url.startsWith('http')) {
      final db = ref.read(databaseProvider);
      final ch = await db.channelsDao.getChannelById(_movie.id);
      if (ch != null && ch.streamUrl.isNotEmpty && ch.streamUrl.startsWith('http')) {
        url = ch.streamUrl;
      } else {
        final playlist = await db.playlistsDao.getPlaylistById(_movie.playlistId);
        if (playlist != null && playlist.url.isNotEmpty) {
          final xtream = XtreamDataSource(client: DioClient());
          url = xtream.buildVodStreamUrl(
            serverUrl: playlist.url,
            username: playlist.username ?? '',
            password: playlist.credentialKey ?? '',
            streamId: _movie.id,
            extension: _movie.containerExtension ?? 'mp4',
          );
        }
      }
    }

    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          channelName: _movie.name,
          streamUrl: url,
          logoUrl: _movie.logoUrl,
          contentInfo: WatchContentInfo(
            channelId: _movie.id,
            name: _movie.name,
            contentType: 'vod',
            thumbnailUrl: _movie.tmdbPosterUrl ?? _movie.logoUrl,
          ),
        ),
      ),
    );
  }
}
