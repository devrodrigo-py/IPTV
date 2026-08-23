import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:nebula_iptv/core/theme/app_typography.dart';
import 'package:nebula_iptv/data/datasources/player/media_kit_player_service.dart';
import 'package:nebula_iptv/domain/services/video_player_service.dart';
import 'package:nebula_iptv/features/player/providers/player_provider.dart';
import 'package:nebula_iptv/domain/services/watch_tracking_service.dart';
import 'package:nebula_iptv/features/channels/providers/channels_provider.dart';
import 'package:nebula_iptv/features/player/widgets/player_controls.dart';
import 'package:nebula_iptv/features/player/widgets/player_error_overlay.dart';
import 'package:nebula_iptv/features/player/widgets/quality_selector.dart';
import 'package:nebula_iptv/domain/services/quality_service.dart';

/// Full-screen player screen.
///
/// Displays the video surface, overlays for controls/info/errors,
/// and handles keyboard shortcuts for desktop/TV.
class PlayerScreen extends ConsumerStatefulWidget {
  final String channelName;
  final String streamUrl;
  final String? logoUrl;
  final WatchContentInfo? contentInfo;
  final int? seekToMs;

  const PlayerScreen({
    super.key,
    required this.channelName,
    required this.streamUrl,
    this.logoUrl,
    this.contentInfo,
    this.seekToMs,
  });

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  bool _showControls = true;
  VideoController? _videoController;
  List<QualityVariant> _qualityVariants = [];
  String _currentQuality = 'Auto';

  @override
  void initState() {
    super.initState();

    // Create VideoController for media_kit on native platforms
    if (!kIsWeb) {
      final playerService = ref.read(videoPlayerServiceProvider);
      if (playerService is MediaKitPlayerService) {
        // Initialize player first if needed, then create controller
        playerService.initialize().then((_) {
          if (mounted && playerService.player != null) {
            setState(() {
              _videoController = VideoController(playerService.player!);
            });
          }
        });
      }
    }

    // Start playback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(playerProvider.notifier).playStream(
        widget.streamUrl,
        contentInfo: widget.contentInfo,
        seekToMs: widget.seekToMs,
      );
    });
    // Auto-hide controls after 3s
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showControls = false);
    });
    // Load quality variants
    _loadQualityVariants();
  }

  @override
  void dispose() {
    _videoController = null;
    super.dispose();
  }

  Future<void> _loadQualityVariants() async {
    try {
      final db = ref.read(databaseProvider);
      final qualityService = QualityService(db);
      // We need a channelId — extract from contentInfo
      final channelId = widget.contentInfo?.channelId;
      if (channelId == null) return;
      final variants = await qualityService.getQualityVariants(channelId);
      if (mounted && variants.isNotEmpty) {
        setState(() => _qualityVariants = variants);
      }
    } catch (_) {}
  }

  Future<void> _switchQuality(QualityVariant? variant) async {
    final url = variant?.streamUrl ?? widget.streamUrl;
    setState(() => _currentQuality = variant?.name ?? 'Auto');
    await ref.read(playerProvider.notifier).stop();
    await ref.read(playerProvider.notifier).playStream(url, contentInfo: widget.contentInfo);
  }

  /// Safely stop playback and navigate back.
  bool _isExiting = false;

  Future<void> _goBack() async {
    if (_isExiting) return;
    _isExiting = true;

    // 1. Remove video widget from tree by nulling controller
    setState(() {
      _videoController = null;
    });

    // 2. Give the native surface time to release
    await Future.delayed(const Duration(milliseconds: 100));

    // 3. Stop playback (includes saving watch tracking)
    await ref.read(playerProvider.notifier).stop();

    // 4. Navigate back
    if (mounted) {
      Navigator.of(context).pop();
    }
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
              // Video surface
              if (_videoController != null)
                Center(
                  child: Video(
                    controller: _videoController!,
                  ),
                )
              else
                const SizedBox.expand(child: ColoredBox(color: Colors.black)),

              // Buffering indicator — small spinner in bottom-left corner
              if (state.playbackState.status == PlaybackStatus.buffering)
                const Positioned(
                  bottom: 80,
                  left: 16,
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white54,
                    ),
                  ),
                ),

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
                            onPressed: () => _goBack(),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.channelName,
                              style: AppTypography.title.copyWith(
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_qualityVariants.isNotEmpty)
                            QualitySelector(
                              variants: _qualityVariants,
                              currentQuality: _currentQuality,
                              onQualitySelected: _switchQuality,
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
                      _goBack();
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
        _goBack();
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
      case LogicalKeyboardKey.arrowLeft:
        // Seek -10s
        final service = ref.read(videoPlayerServiceProvider);
        if (service is MediaKitPlayerService && service.player != null) {
          final pos = service.player!.state.position;
          final target = pos - const Duration(seconds: 10);
          service.player!.seek(target < Duration.zero ? Duration.zero : target);
        }
      case LogicalKeyboardKey.arrowRight:
        // Seek +10s
        final service = ref.read(videoPlayerServiceProvider);
        if (service is MediaKitPlayerService && service.player != null) {
          final pos = service.player!.state.position;
          service.player!.seek(pos + const Duration(seconds: 10));
        }
      case LogicalKeyboardKey.keyF:
        // Toggle fullscreen (maximize/restore window)
        // Not implemented without window_manager — placeholder
        break;
      case LogicalKeyboardKey.keyM:
        // Mute toggle
        final currentVol = ref.read(playerProvider).playbackState.volume;
        ref.read(playerProvider.notifier).setVolume(currentVol > 0 ? 0.0 : 1.0);
      default:
        break;
    }
  }
}
