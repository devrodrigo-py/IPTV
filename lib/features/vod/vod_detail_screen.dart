import 'package:flutter/material.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';
import 'package:nebula_iptv/core/theme/app_typography.dart';
import 'package:nebula_iptv/core/widgets/focusable_widget.dart';
import 'package:nebula_iptv/features/player/player_screen.dart';
import 'package:nebula_iptv/domain/services/watch_tracking_service.dart';
import 'package:nebula_iptv/features/vod/providers/vod_provider.dart';

/// Movie detail screen with poster, info, and play button.
///
/// Displays full movie information in a Netflix-style layout
/// with a large backdrop/poster and metadata below.
class VodDetailScreen extends StatelessWidget {
  final VodItem movie;

  const VodDetailScreen({
    super.key,
    required this.movie,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App bar with poster backdrop
          SliverAppBar(
            expandedHeight: 400,
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
                  // Poster/backdrop
                  if (movie.logoUrl != null && movie.logoUrl!.isNotEmpty)
                    Image.network(
                      movie.logoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildBackdropPlaceholder(),
                    )
                  else
                    _buildBackdropPlaceholder(),

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
                        stops: [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Movie info
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    movie.name,
                    style: AppTypography.headline,
                  ),
                  const SizedBox(height: 12),

                  // Metadata row
                  Row(
                    children: [
                      if (movie.rating != null &&
                          movie.rating!.isNotEmpty &&
                          movie.rating != '0') ...[
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
                                movie.rating!,
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
                      if (movie.duration != null &&
                          movie.duration!.isNotEmpty) ...[
                        Icon(
                          Icons.schedule_rounded,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          movie.duration!,
                          style: AppTypography.label,
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (movie.categoryName != null) ...[
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
                            movie.categoryName!,
                            style: AppTypography.label,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Play button
                  FocusableWidget(
                    onPressed: () => _playMovie(context),
                    borderRadius: BorderRadius.circular(12),
                    builder: (context, isFocused) => Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: isFocused
                            ? AppColors.primaryVariant
                            : AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isFocused
                            ? [
                                BoxShadow(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.4),
                                  blurRadius: 12,
                                ),
                              ]
                            : null,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
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
                  ),
                  const SizedBox(height: 24),

                  // Plot/Synopsis
                  if (movie.plot != null && movie.plot!.isNotEmpty) ...[
                    Text('Sinopse', style: AppTypography.title),
                    const SizedBox(height: 8),
                    Text(
                      movie.plot!,
                      style: AppTypography.body.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Director
                  if (movie.director != null &&
                      movie.director!.isNotEmpty) ...[
                    _buildInfoRow('Diretor', movie.director!),
                    const SizedBox(height: 12),
                  ],

                  // Cast
                  if (movie.cast != null && movie.cast!.isNotEmpty) ...[
                    _buildInfoRow('Elenco', movie.cast!),
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

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
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

  void _playMovie(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          channelName: movie.name,
          streamUrl: movie.streamUrl,
          logoUrl: movie.logoUrl,
          contentInfo: WatchContentInfo(
            channelId: movie.id,
            name: movie.name,
            contentType: 'vod',
            thumbnailUrl: movie.tmdbPosterUrl ?? movie.logoUrl,
          )),
      ),
    );
  }
}
