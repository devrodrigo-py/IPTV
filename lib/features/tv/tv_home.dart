import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/core/constants/tv_constants.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';
import 'package:nebula_iptv/core/theme/app_typography.dart';
import 'package:nebula_iptv/core/widgets/cached_logo.dart';
import 'package:nebula_iptv/core/widgets/tv_focusable_card.dart';
import 'package:nebula_iptv/data/database/app_database.dart' hide SeriesItem;
import 'package:nebula_iptv/features/channels/providers/channels_provider.dart';
import 'package:nebula_iptv/domain/providers/watch_providers.dart';
import 'package:nebula_iptv/domain/services/watch_tracking_service.dart';
import 'package:nebula_iptv/features/home/home_screen.dart';
import 'package:nebula_iptv/features/player/player_screen.dart';
import 'package:nebula_iptv/features/series/providers/series_provider.dart' show SeriesItem;
import 'package:nebula_iptv/features/series/series_detail_screen.dart';
import 'package:nebula_iptv/l10n/app_localizations.dart';

/// TV-optimized home screen with large cards for 10-foot UI.
///
/// Shows "Continue Watching" and "Favorites" as horizontal
/// scrollable rows of focusable cards.
class TvHome extends ConsumerWidget {
  const TvHome({super.key});

  void _playFromHistory(BuildContext context, WidgetRef ref, Map<String, dynamic> entry) async {
    final streamUrl = entry['stream_url'] as String?;
    final name = entry['content_name'] as String? ??
        entry['channel_name'] as String? ?? 'Canal';
    final contentType = entry['content_type'] as String? ?? 'live';
    final channelId = entry['channel_id'] as int? ?? 0;
    final thumbnailUrl = entry['thumbnail_url'] as String? ?? entry['logo_url'] as String?;

    // Series: navigate to detail screen
    if (contentType == 'series') {
      try {
        final db = ref.read(databaseProvider);
        final ch = await (db.select(db.channels)..where((c) => c.id.equals(channelId))).getSingleOrNull();
        if (ch != null && context.mounted) {
          final seriesItem = SeriesItem(
            id: ch.id,
            playlistId: ch.playlistId,
            name: ch.name,
            coverUrl: ch.logoUrl,
            categoryName: ch.groupName,
            sourceId: ch.sourceId,
          );
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => SeriesDetailScreen(series: seriesItem),
          ));
        }
      } catch (_) {}
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
        logoUrl: thumbnailUrl,
        seekToMs: seekToMs > 0 ? seekToMs : null,
        contentInfo: WatchContentInfo(
          channelId: channelId,
          name: name,
          contentType: contentType,
          thumbnailUrl: thumbnailUrl,
        ),
      ),
    ));
  }

  void _playChannel(BuildContext context, Channel channel) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PlayerScreen(
        channelName: channel.name,
        streamUrl: channel.streamUrl,
        logoUrl: channel.logoUrl,
        contentInfo: WatchContentInfo(
          channelId: channel.id,
          name: channel.name,
          contentType: channel.sourceType.name,
          thumbnailUrl: channel.logoUrl,
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final continueWatching = ref.watch(continueWatchingProvider);
    final favorites = ref.watch(homeFavoritesProvider);

    return FocusTraversalGroup(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        children: [
          // Title
          Text(
            l10n.appTitle,
            style: AppTypography.display.copyWith(
              fontSize: AppTypography.display.fontSize! * TvConstants.fontScaleFactor,
            ),
          ),
          const SizedBox(height: 24),

          // Continue Watching
          if (continueWatching.valueOrNull?.isNotEmpty == true) ...[
            Text(
              'Continuar assistindo',
              style: AppTypography.title.copyWith(
                fontSize: AppTypography.title.fontSize! * TvConstants.fontScaleFactor,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: continueWatching.value!.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: TvConstants.gridSpacing),
                itemBuilder: (context, index) {
                  final entry = continueWatching.value![index];
                  return TvFocusableCard(
                    autofocus: index == 0,
                    onPressed: () => _playFromHistory(context, ref, entry),
                    child: _TvHistoryCardContent(entry: entry),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
          ],

          // Favorites
          if (favorites.valueOrNull?.isNotEmpty == true) ...[
            Text(
              l10n.favorites,
              style: AppTypography.title.copyWith(
                fontSize: AppTypography.title.fontSize! * TvConstants.fontScaleFactor,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: favorites.value!.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: TvConstants.gridSpacing),
                itemBuilder: (context, index) {
                  final channel = favorites.value![index];
                  return TvFocusableCard(
                    onPressed: () => _playChannel(context, channel),
                    child: _TvChannelCardContent(channel: channel),
                  );
                },
              ),
            ),
          ],

          // Empty state
          if (continueWatching.valueOrNull?.isEmpty != false &&
              favorites.valueOrNull?.isEmpty != false)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 80),
                child: Column(
                  children: [
                    const Icon(
                      Icons.live_tv_rounded,
                      size: 80,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.homeEmptyMessage,
                      style: AppTypography.title.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: AppTypography.title.fontSize! *
                            TvConstants.fontScaleFactor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TvHistoryCardContent extends StatelessWidget {
  final Map<String, dynamic> entry;
  const _TvHistoryCardContent({required this.entry});

  @override
  Widget build(BuildContext context) {
    final name = entry['content_name'] as String? ??
        entry['channel_name'] as String? ?? 'Canal';
    final thumbnailUrl = entry['thumbnail_url'] as String? ?? entry['logo_url'] as String?;
    final progress = (entry['progress_percent'] as num?)?.toDouble() ?? 0.0;

    return Stack(
      children: [
        // Thumbnail or placeholder
        if (thumbnailUrl != null && thumbnailUrl.isNotEmpty)
          Positioned.fill(
            child: Image.network(
              thumbnailUrl,
              fit: BoxFit.cover,
              cacheWidth: 300,
              cacheHeight: 200,
              errorBuilder: (_, __, ___) => _buildFallback(),
            ),
          )
        else
          Positioned.fill(child: _buildFallback()),

        // Dark gradient overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.85),
                ],
              ),
            ),
          ),
        ),

        // Info and progress bar
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              if (progress > 0.02) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFallback() {
    return Container(
      color: AppColors.surfaceElevated,
      child: const Center(
        child: Icon(Icons.play_circle_fill_rounded, color: AppColors.primary, size: 40),
      ),
    );
  }
}

class _TvChannelCardContent extends StatelessWidget {
  final Channel channel;
  const _TvChannelCardContent({required this.channel});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CachedLogo(
            imageUrl: channel.logoUrl,
            size: 54,
          ),
          const SizedBox(height: 12),
          Text(
            channel.name,
            style: AppTypography.body.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
