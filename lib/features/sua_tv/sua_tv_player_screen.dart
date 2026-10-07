import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';
import 'package:nebula_iptv/core/theme/app_typography.dart';
import 'package:nebula_iptv/domain/services/video_player_service.dart';
import 'package:nebula_iptv/features/player/providers/player_provider.dart';
import 'package:nebula_iptv/features/sua_tv/providers/sua_tv_provider.dart';

/// Sua TV player — autoplay personal mix.
/// Plays items from the personalized queue sequentially.
///
/// Playback goes through the [VideoPlayerService] abstraction — the screen
/// never touches the concrete player package.
class SuaTvPlayerScreen extends ConsumerStatefulWidget {
  const SuaTvPlayerScreen({super.key});

  @override
  ConsumerState<SuaTvPlayerScreen> createState() => _SuaTvPlayerScreenState();
}

class _SuaTvPlayerScreenState extends ConsumerState<SuaTvPlayerScreen> {
  bool _showControls = true;
  bool _isExiting = false;
  bool _isPlaying = false;
  bool _surfaceReady = false;
  StreamSubscription<VideoPlaybackState>? _playbackSub;
  StreamSubscription<void>? _completedSub;
  Timer? _liveTimer;

  VideoPlayerService get _player => ref.read(videoPlayerServiceProvider);

  @override
  void initState() {
    super.initState();
    _initPlayer();
    // Auto-hide controls
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  Future<void> _initPlayer() async {
    final initResult = await _player.initialize();
    if (initResult.isFailure) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    _playbackSub = _player.playbackState.listen((playback) {
      if (!mounted) return;
      setState(() {
        _isPlaying = playback.status == PlaybackStatus.playing;
      });
    });
    _completedSub = _player.completed.listen((_) {
      if (mounted) _skipToNext();
    });

    if (mounted) setState(() => _surfaceReady = true);

    // Start playing the first item
    _playCurrentItem();
  }

  void _playCurrentItem() {
    final item = ref.read(suaTvCurrentItemProvider);
    if (item == null) return;

    var url = item.streamUrl;
    // HLS conversion for live streams
    if (url.contains('/live/') && url.endsWith('.ts')) {
      url = '${url.substring(0, url.length - 3)}.m3u8';
    }

    _player.play(url);

    // For live channels, advance after 5 minutes
    _liveTimer?.cancel();
    if (item.contentType == 'xtream' || item.contentType == 'm3u') {
      _liveTimer = Timer(const Duration(minutes: 5), () {
        if (mounted) _skipToNext();
      });
    }
  }

  void _skipToNext() {
    _liveTimer?.cancel();
    final queue = ref.read(suaTvQueueProvider).valueOrNull;
    final currentIndex = ref.read(suaTvCurrentIndexProvider);
    if (queue != null && currentIndex + 1 < queue.length) {
      ref.read(suaTvCurrentIndexProvider.notifier).state = currentIndex + 1;
      _playCurrentItem();
    } else {
      // Queue exhausted
      _goBack();
    }
  }

  Future<void> _goBack() async {
    if (_isExiting) return;
    _isExiting = true;

    setState(() => _surfaceReady = false);

    _liveTimer?.cancel();
    _playbackSub?.cancel();
    _completedSub?.cancel();
    // The player service is app-scoped — stop it, never dispose it here.
    await ref.read(playerProvider.notifier).stop();

    if (mounted) Navigator.of(context).pop();
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _player.pause();
    } else {
      _player.resume();
    }
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    _playbackSub?.cancel();
    _completedSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentItem = ref.watch(suaTvCurrentItemProvider);
    final nextItem = ref.watch(suaTvNextItemProvider);
    final currentIndex = ref.watch(suaTvCurrentIndexProvider);
    final queue = ref.watch(suaTvQueueProvider).valueOrNull;

    final surface = _surfaceReady ? _player.buildVideoSurface() : null;

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
              if (surface != null)
                Center(child: surface)
              else
                const SizedBox.expand(child: ColoredBox(color: Colors.black)),

              // Controls overlay
              if (_showControls) ...[
                // Top bar
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
                            onPressed: _goBack,
                          ),
                          const SizedBox(width: 12),
                          // Sua TV badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.solarCoral
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '▶ Sua TV',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              currentItem?.name ?? '',
                              style: AppTypography.title
                                  .copyWith(color: Colors.white),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Queue counter
                          if (queue != null)
                            Text(
                              '${currentIndex + 1}/${queue.length}',
                              style: AppTypography.label
                                  .copyWith(color: Colors.white70),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Bottom bar with next info and skip
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black54, Colors.transparent],
                      ),
                    ),
                    child: Row(
                      children: [
                        // Play/Pause
                        IconButton(
                          icon: Icon(
                            _isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                          onPressed: _togglePlayPause,
                        ),
                        const SizedBox(width: 16),
                        // Next info
                        Expanded(
                          child: nextItem != null
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'A seguir',
                                      style: AppTypography.caption.copyWith(
                                        color: Colors.white54,
                                        fontSize: 10,
                                      ),
                                    ),
                                    Text(
                                      nextItem.name,
                                      style: AppTypography.body
                                          .copyWith(color: Colors.white),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                )
                              : Text(
                                  'Última da fila',
                                  style: AppTypography.body
                                      .copyWith(color: Colors.white54),
                                ),
                        ),
                        // Skip button
                        IconButton(
                          icon: const Icon(
                            Icons.skip_next_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                          onPressed: _skipToNext,
                          tooltip: 'Próximo',
                        ),
                      ],
                    ),
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
        _togglePlayPause();
      case LogicalKeyboardKey.escape:
        _goBack();
      case LogicalKeyboardKey.arrowRight:
        _skipToNext();
      default:
        break;
    }
  }
}
