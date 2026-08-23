import 'package:flutter/material.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';
import 'package:nebula_iptv/core/theme/app_typography.dart';
import 'package:nebula_iptv/core/widgets/focusable_widget.dart';
import 'package:nebula_iptv/features/series/providers/series_provider.dart';

/// Episode list tile — Netflix-style with episode number, title,
/// duration, and play button.
class EpisodeTile extends StatelessWidget {
  final EpisodeItem episode;
  final VoidCallback onPlay;

  const EpisodeTile({
    super.key,
    required this.episode,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: FocusableWidget(
        onPressed: onPlay,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        builder: (context, isFocused) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isFocused ? AppColors.surfaceElevated : AppColors.surface,
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              border: isFocused
                  ? Border.all(color: AppColors.primary.withValues(alpha: 0.5))
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    // Episode number
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${episode.episodeNumber}',
                          style: AppTypography.title.copyWith(
                            color: AppColors.primary,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Episode info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            episode.title,
                            style: AppTypography.body.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (episode.duration != null &&
                                  episode.duration!.isNotEmpty) ...[
                                Icon(
                                  Icons.schedule_rounded,
                                  size: 12,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  episode.duration!,
                                  style: AppTypography.caption,
                                ),
                                const SizedBox(width: 12),
                              ],
                              if (episode.containerExtension != null)
                                Text(
                                  episode.containerExtension!.toUpperCase(),
                                  style: AppTypography.caption.copyWith(
                                    fontSize: 10,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                            ],
                          ),
                          if (episode.plot != null &&
                              episode.plot!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              episode.plot!,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Play button
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isFocused
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        episode.watchProgress >= 0.95
                            ? Icons.check_rounded
                            : Icons.play_arrow_rounded,
                        color: isFocused ? Colors.white : AppColors.primary,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                // Watch progress bar
                if (episode.watchProgress > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: episode.watchProgress,
                        minHeight: 3,
                        backgroundColor: AppColors.surfaceElevated,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          episode.watchProgress >= 0.95
                              ? Colors.green
                              : AppColors.primary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
