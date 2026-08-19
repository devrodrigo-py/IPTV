import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/core/theme/app_typography.dart';
import 'package:nebula_iptv/core/widgets/loading_view.dart';
import 'package:nebula_iptv/domain/services/video_player_service.dart';
import 'package:nebula_iptv/features/player/providers/player_provider.dart';
import 'package:nebula_iptv/features/player/widgets/player_controls.dart';
import 'package:nebula_iptv/features/player/widgets/player_error_overlay.dart';

/// Full-screen player screen.
///
/// Displays the video surface, overlays for controls/info/errors,
/// and handles keyboard shortcuts for desktop/TV.
class PlayerScreen extends ConsumerStatefulWidget {
  final String channelName;
  final String streamUrl;
  final String? logoUrl;

  const PlayerScreen({
    super.key,
    required this.channelName,
    required this.streamUrl,
    this.logoUrl,
  });

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    // Start playback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(playerProvider.notifier).playStream(widget.streamUrl);
    });
    // Auto-hide controls after 3s
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playerProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: KeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        onKeyEvent: _handleKeyEvent,
        child: GestureDetector(
          onTap: () => setState(() => _showControls = !_showControls),
          child: Stack(
            children: [
              // Video surface placeholder (media_kit Video widget goes here)
              const Center(
                child: SizedBox.expand(
                  child: ColoredBox(color: Colors.black),
                ),
              ),

              // Buffering indicator
              if (state.playbackState.status == PlaybackStatus.buffering)
                const Center(child: LoadingView()),

              // Error overlay
              if (state.playbackState.status == PlaybackStatus.error)
                PlayerErrorOverlay(
                  onRetry: () {
                    ref.read(playerProvider.notifier).retry(widget.streamUrl);
                  },
                ),

              // Controls overlay
              if (_showControls) ...[
                // Top bar (channel info)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black54, Colors.transparent],
                      ),
                    ),
                    child: SafeArea(
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            widget.channelName,
                            style: AppTypography.title.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Bottom controls
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: PlayerControls(
                    playbackState: state.playbackState,
                    onPlayPause: () {
                      final notifier = ref.read(playerProvider.notifier);
                      if (state.playbackState.status ==
                          PlaybackStatus.playing) {
                        notifier.pause();
                      } else {
                        notifier.resume();
                      }
                    },
                    onStop: () {
                      ref.read(playerProvider.notifier).stop();
                      Navigator.of(context).pop();
                    },
                    onVolumeChanged: (vol) {
                      ref.read(playerProvider.notifier).setVolume(vol);
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.space:
      case LogicalKeyboardKey.mediaPlayPause:
        final notifier = ref.read(playerProvider.notifier);
        final status = ref.read(playerProvider).playbackState.status;
        if (status == PlaybackStatus.playing) {
          notifier.pause();
        } else {
          notifier.resume();
        }
      case LogicalKeyboardKey.escape:
        Navigator.of(context).pop();
      case LogicalKeyboardKey.arrowUp:
        ref.read(playerProvider.notifier).setVolume(
              (ref.read(playerProvider).playbackState.volume + 0.1)
                  .clamp(0.0, 1.0),
            );
      case LogicalKeyboardKey.arrowDown:
        ref.read(playerProvider.notifier).setVolume(
              (ref.read(playerProvider).playbackState.volume - 0.1)
                  .clamp(0.0, 1.0),
            );
    }
  }
}
