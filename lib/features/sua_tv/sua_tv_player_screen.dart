import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';
import 'package:nebula_iptv/core/theme/app_typography.dart';
import 'package:nebula_iptv/domain/services/sua_tv_service.dart';
import 'package:nebula_iptv/features/sua_tv/providers/sua_tv_provider.dart';

/// Sua TV player — autoplay personal mix.
/// Plays items from the personalized queue sequentially.
class SuaTvPlayerScreen extends ConsumerStatefulWidget {
  const SuaTvPlayerScreen({super.key});

  @override
  ConsumerState<SuaTvPlayerScreen> createState() => _SuaTvPlayerScreenState();
}

class _SuaTvPlayerScreenState extends ConsumerState<SuaTvPlayerScreen> {
  Player? _player;
  VideoController? _videoController;
  bool _showControls = true;
  bool _isExiting = false;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
  Timer? _liveTimer;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

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
    _player = Player();
    setState(() {
      _videoController = VideoController(_player!);
    });

    _positionSub = _player!.stream.position.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });
    _durationSub = _player!.stream.duration.listen((dur) {
      if (mounted) setState(() => _duration = dur);
    });

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

    _player?.open(Media(url));

    // For live channels, advance after 5 minutes
    _liveTimer?.cancel();
    if (item.contentType == 'xtream' || item.contentType == 'm3u') {
      _liveTimer = Timer(const Duration(minutes: 5), () {
        if (mounted) _skipToNext();
      });
    }

    // For VOD, listen for completion
    _player?.stream.completed.listen((completed) {
      if (completed && mounted) {
        _skipToNext();
      }
    });
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

    setState(() => _videoController = null);
    await Future.delayed(const Duration(milliseconds: 100));

    _liveTimer?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    await _player?.stop();
    await _player?.dispose();

    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentItem = ref.watch(suaTvCurrentItemProvider);
    final nextItem = ref.watch(suaTvNextItemProvider);
    final currentIndex = ref.watch(suaTvCurrentIndexProvider);
    final queue = ref.watch(suaTvQueueProvider).valueOrNull;

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
                Center(child: Video(controller: _videoController!))
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
                        horizontal: 24, vertical: 16),
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
                            icon: const Icon(Icons.arrow_back_rounded,
                                color: Colors.white),
                            onPressed: _goBack,
                          ),
                          const SizedBox(width: 12),
                          // Sua TV badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.primary, Color(0xFFF107A3)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '▶ Sua TV',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
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
                        horizontal: 24, vertical: 16),
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
                            _player?.state.playing == true
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                          onPressed: () {
                            if (_player?.state.playing == true) {
                              _player?.pause();
                            } else {
                              _player?.play();
                            }
                          },
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
                                          color: Colors.white54, fontSize: 10),
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
                          icon: const Icon(Icons.skip_next_rounded,
                              color: Colors.white, size: 32),
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
        if (_player?.state.playing == true) {
          _player?.pause();
        } else {
          _player?.play();
        }
      case LogicalKeyboardKey.escape:
        _goBack();
      case LogicalKeyboardKey.arrowRight:
        _skipToNext();
      default:
        break;
    }
  }
}
