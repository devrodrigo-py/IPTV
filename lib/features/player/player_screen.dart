import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/core/logging/app_logger.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';
import 'package:nebula_iptv/core/theme/app_typography.dart';
import 'package:nebula_iptv/core/widgets/focusable_widget.dart';
import 'package:nebula_iptv/core/widgets/live_indicator.dart';
import 'package:nebula_iptv/core/widgets/tv_safe_area.dart';
import 'package:nebula_iptv/domain/services/quality_service.dart';
import 'package:nebula_iptv/domain/services/video_player_service.dart';
import 'package:nebula_iptv/domain/services/watch_tracking_service.dart';
import 'package:nebula_iptv/features/channels/providers/channels_provider.dart';
import 'package:nebula_iptv/features/player/providers/player_provider.dart';
import 'package:nebula_iptv/features/player/widgets/nebula_buffering_indicator.dart';
import 'package:nebula_iptv/features/player/widgets/player_controls.dart';
import 'package:nebula_iptv/features/player/widgets/player_error_overlay.dart';
import 'package:nebula_iptv/features/player/widgets/quality_selector.dart';
import 'package:nebula_iptv/features/player/widgets/quick_channel_drawer.dart';
import 'package:nebula_iptv/features/player/widgets/track_selector_drawer.dart';
import 'package:nebula_iptv/features/series/providers/series_provider.dart'
    show EpisodeItem;

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
  final List<EpisodeItem>? episodePlaylist;
  final int? currentEpisodeIndex;

  const PlayerScreen({
    super.key,
    required this.channelName,
    required this.streamUrl,
    this.logoUrl,
    this.contentInfo,
    this.seekToMs,
    this.episodePlaylist,
    this.currentEpisodeIndex,
  });

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  bool _showControls = true;
  bool _showQuickDrawer = false;
  bool _surfaceReady = false;
  List<QualityVariant> _qualityVariants = [];
  String _currentQuality = 'Auto';
  double _currentSpeed = 1.0;
  bool _dismissedAutoPlay = false;
  String? _selectedAudioTrackId;
  String? _selectedSubtitleTrackId;

  late String _currentChannelName;
  late String _currentStreamUrl;
  WatchContentInfo? _currentContentInfo;
  int? _currentEpisodeIndex;
  List<EpisodeItem>? _episodePlaylist;
  Timer? _zapDebounceTimer;
  Timer? _hideControlsTimer;
  final _keyboardFocusNode = FocusNode(debugLabel: 'Player surface');
  final _playPauseFocusNode = FocusNode(debugLabel: 'Player play/pause');
  final _controlsKey = GlobalKey<PlayerControlsState>();
  bool _allowPop = false;

  bool get _isLive =>
      _currentContentInfo?.contentType != 'vod' &&
      _currentContentInfo?.contentType != 'series';
  bool get _hasPrevEpisode =>
      _episodePlaylist != null &&
      _currentEpisodeIndex != null &&
      _currentEpisodeIndex! > 0;
  bool get _hasNextEpisode =>
      _episodePlaylist != null &&
      _currentEpisodeIndex != null &&
      (_currentEpisodeIndex! + 1) < _episodePlaylist!.length;

  @override
  void initState() {
    super.initState();
    _currentChannelName = widget.channelName;
    _currentStreamUrl = widget.streamUrl;
    _currentContentInfo = widget.contentInfo;
    _currentEpisodeIndex = widget.currentEpisodeIndex;
    _episodePlaylist = widget.episodePlaylist;
    HardwareKeyboard.instance.addHandler(_observeActivity);

    // Ensure the player is initialized so the render surface is available.
    // The surface widget itself comes from the VideoPlayerService abstraction.
    final playerService = ref.read(videoPlayerServiceProvider);
    playerService.initialize().then((_) {
      if (mounted) {
        setState(() => _surfaceReady = true);
      }
    });

    // Start playback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _keyboardFocusNode.requestFocus();
      ref.read(playerProvider.notifier).playStream(
            _currentStreamUrl,
            contentInfo: _currentContentInfo,
            seekToMs: widget.seekToMs,
          );
    });

    _resetHideControlsTimer();
    _loadQualityVariants();
  }

  void _switchEpisode(int newIndex) {
    if (_episodePlaylist == null ||
        newIndex < 0 ||
        newIndex >= _episodePlaylist!.length) {
      return;
    }
    final nextEp = _episodePlaylist![newIndex];
    setState(() {
      _currentEpisodeIndex = newIndex;
      _currentChannelName =
          '${widget.contentInfo?.name ?? 'Série'} - ${nextEp.title}';
      _currentStreamUrl = nextEp.streamUrl;
      _currentContentInfo = WatchContentInfo(
        channelId: widget.contentInfo?.channelId ?? nextEp.seriesId,
        name: widget.contentInfo?.name ?? 'Série',
        contentType: 'series',
        thumbnailUrl: nextEp.coverUrl ?? widget.logoUrl,
        seriesId: nextEp.seriesId,
        seasonNumber: nextEp.seasonId,
        episodeNumber: nextEp.episodeNumber,
        episodeTitle: nextEp.title,
      );
      _dismissedAutoPlay = false;
      _showControls = true;
    });

    ref.read(playerProvider.notifier).stop().then((_) {
      ref.read(playerProvider.notifier).playStream(
            _currentStreamUrl,
            contentInfo: _currentContentInfo,
          );
      _resetHideControlsTimer();
    });
  }

  Future<void> _openQuickDrawer() async {
    if (_showQuickDrawer || !_isLive) return;
    setState(() => _showQuickDrawer = true);
    _hideControlsTimer?.cancel();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Align(
          alignment: Alignment.centerLeft,
          child: TvSafeArea(
            child: Material(
                color: Colors.transparent,
                child: Focus(
                  canRequestFocus: false,
                  onKeyEvent: (node, event) {
                    if (RemoteKeys.isBack(event.logicalKey)) {
                      if (event is KeyDownEvent) Navigator.pop(dialogContext);
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: QuickChannelDrawer(
                    currentChannelId: _currentContentInfo?.channelId,
                    onClose: () => Navigator.pop(dialogContext),
                    onChannelSelected: (channel) {
                      setState(() {
                        _currentChannelName = channel.name;
                        _currentStreamUrl = channel.streamUrl;
                        _currentContentInfo = WatchContentInfo(
                            channelId: channel.id,
                            name: channel.name,
                            contentType: 'live',
                            thumbnailUrl: channel.logoUrl);
                      });
                      ref.read(playerProvider.notifier).playStream(
                          _currentStreamUrl,
                          contentInfo: _currentContentInfo);
                      _loadQualityVariants();
                      Navigator.pop(dialogContext);
                    },
                  ),
                )),
          )),
    );
    if (!mounted) return;
    setState(() => _showQuickDrawer = false);
    _revealControls();
  }

  void _showTrackSelectorDrawer() {
    showDialog<void>(
      context: context,
      builder: (_) => TrackSelectorDrawer(
        contentTitle: _currentChannelName,
        selectedAudioTrackId: _selectedAudioTrackId,
        selectedSubtitleTrackId: _selectedSubtitleTrackId,
        seasonNumber: _currentContentInfo?.seasonNumber,
        episodeNumber: _currentContentInfo?.episodeNumber,
        onSelectAudio: (trackId) {
          setState(() => _selectedAudioTrackId = trackId);
          ref.read(playerProvider.notifier).selectAudioTrack(trackId);
        },
        onSelectSubtitle: (trackId) {
          setState(() => _selectedSubtitleTrackId = trackId);
          ref.read(playerProvider.notifier).selectSubtitleTrack(trackId);
        },
        onAddExternalSubtitle: (uri) {
          setState(() => _selectedSubtitleTrackId = 'external');
          ref.read(playerProvider.notifier).addExternalSubtitle(
                uri,
                title: 'Português (Online/Externo)',
                language: 'pt-BR',
              );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Legenda carregada com sucesso!')),
          );
        },
      ),
    );
  }

  void _resetHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted ||
          ModalRoute.of(context)?.isCurrent != true ||
          _showQuickDrawer ||
          _controlsKey.currentState?.isScrubbing == true) {
        return;
      }
      _hideControls();
    });
  }

  bool _observeActivity(KeyEvent event) {
    // Activity observation never dispatches actions; the focus tree owns input.
    if (mounted && _keyboardFocusNode.hasFocus && event is! KeyUpEvent) {
      _resetHideControlsTimer();
    }
    return false;
  }

  void _hideControls() {
    _hideControlsTimer?.cancel();
    _keyboardFocusNode.requestFocus();
    setState(() => _showControls = false);
  }

  void _revealControls() {
    setState(() => _showControls = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _showControls) _playPauseFocusNode.requestFocus();
    });
    _resetHideControlsTimer();
  }

  void _handleBack() {
    if (_controlsKey.currentState?.cancelScrub() == true) return;
    if (_showQuickDrawer) {
      setState(() => _showQuickDrawer = false);
      _revealControls();
    } else if (_showControls) {
      _hideControls();
    } else {
      _goBack();
    }
  }

  void _togglePlayback() {
    final notifier = ref.read(playerProvider.notifier);
    if (ref.read(playerProvider).playbackState.status ==
        PlaybackStatus.playing) {
      notifier.pause();
    } else {
      notifier.resume();
    }
  }

  void _seekBy(int seconds) {
    if (_isLive) return;
    final playback = ref.read(playerProvider).playbackState;
    final maxMs = playback.duration.inMilliseconds;
    if (maxMs <= 0) return;
    final ms =
        (playback.position.inMilliseconds + seconds * 1000).clamp(0, maxMs);
    ref.read(playerProvider.notifier).seek(Duration(milliseconds: ms));
  }

  void _zapChannel(bool next) {
    if (!_isLive) return;

    final channels = ref.read(channelsScreenProvider).allChannels;
    if (channels.isEmpty) return;

    final currentId = _currentContentInfo?.channelId;
    int currentIndex = -1;
    if (currentId != null) {
      currentIndex = channels.indexWhere((c) => c.id == currentId);
    }
    if (currentIndex == -1) {
      currentIndex =
          channels.indexWhere((c) => c.streamUrl == _currentStreamUrl);
    }
    if (currentIndex == -1) currentIndex = 0;

    int nextIndex;
    if (next) {
      nextIndex = (currentIndex + 1) % channels.length;
    } else {
      nextIndex = (currentIndex - 1 + channels.length) % channels.length;
    }

    final targetChannel = channels[nextIndex];
    setState(() {
      _currentChannelName = targetChannel.name;
      _currentStreamUrl = targetChannel.streamUrl;
      _currentContentInfo = WatchContentInfo(
        channelId: targetChannel.id,
        name: targetChannel.name,
        contentType: 'live',
        thumbnailUrl: targetChannel.logoUrl,
      );
      _showControls = true;
    });

    _zapDebounceTimer?.cancel();
    _zapDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      ref.read(playerProvider.notifier).playStream(
            _currentStreamUrl,
            contentInfo: _currentContentInfo,
          );
      _loadQualityVariants();
    });

    _resetHideControlsTimer();
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_observeActivity);
    _keyboardFocusNode.dispose();
    _playPauseFocusNode.dispose();
    _zapDebounceTimer?.cancel();
    _hideControlsTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadQualityVariants() async {
    try {
      final db = ref.read(databaseProvider);
      final qualityService = QualityService(db);
      final channelId = _currentContentInfo?.channelId;
      if (channelId == null) return;
      final variants = await qualityService.getQualityVariants(channelId);
      if (mounted && variants.isNotEmpty) {
        setState(() => _qualityVariants = variants);
      }
    } catch (e) {
      // Variantes de qualidade são opcionais; sem elas o seletor fica
      // oculto (distinguível), mas a falha deve ficar registrada.
      appLogger.w('[Player] Falha ao carregar variantes de qualidade: $e');
    }
  }

  Future<void> _switchQuality(QualityVariant? variant) async {
    final url = variant?.streamUrl ?? _currentStreamUrl;
    setState(() => _currentQuality = variant?.name ?? 'Auto');
    await ref.read(playerProvider.notifier).stop();
    await ref
        .read(playerProvider.notifier)
        .playStream(url, contentInfo: _currentContentInfo);
  }

  /// Safely stop playback and navigate back.
  bool _isExiting = false;

  Future<void> _goBack() async {
    if (_isExiting) return;
    _isExiting = true;

    // 1. Remove video widget from tree
    setState(() {
      _surfaceReady = false;
    });

    // 2. Give the native surface time to release
    await Future.delayed(const Duration(milliseconds: 100));

    // 3. Stop playback (includes saving watch tracking)
    await ref.read(playerProvider.notifier).stop();

    // 4. Navigate back
    if (mounted) {
      setState(() => _allowPop = true);
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playerProvider);
    final safe = TvSafeArea.paddingOf(context);

    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Focus(
          focusNode: _keyboardFocusNode,
          onKeyEvent: _handleKeyEvent,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _showControls ? _hideControls() : _revealControls(),
            child: Stack(
              children: [
                // Video surface — provided by the VideoPlayerService abstraction
                Builder(
                  builder: (context) {
                    final surface = _surfaceReady
                        ? ref
                            .watch(videoPlayerServiceProvider)
                            .buildVideoSurface()
                        : null;
                    if (surface != null) {
                      return Center(child: ExcludeFocus(child: surface));
                    }
                    return const SizedBox.expand(
                      child: ColoredBox(color: Colors.black),
                    );
                  },
                ),

                // Buffering — indicador da marca (triângulo de play pulsante)
                // com grace period de 2s: não pisca em streams que conectam
                // rápido (Issue #1 da crítica; DESIGN.md §3).
                if (state.playbackState.status == PlaybackStatus.buffering)
                  const Positioned.fill(
                    child: Center(
                      child: NebulaBufferingIndicator(size: 72),
                    ),
                  ),

                // Error overlay
                if (state.playbackState.status == PlaybackStatus.error)
                  PlayerErrorOverlay(
                    onRetry: () {
                      ref
                          .read(playerProvider.notifier)
                          .retry(_currentStreamUrl);
                    },
                  ),

                // Controls overlay
                if (_showControls) ...[
                  // Top bar (channel info)
                  Positioned(
                    top: safe.top,
                    left: safe.left,
                    right: safe.right,
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
                                _currentChannelName,
                                style: AppTypography.title.copyWith(
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_isLive) ...[
                              const LiveIndicator(label: 'Ao vivo'),
                              const SizedBox(width: 12),
                            ],
                            if (_isLive)
                              IconButton(
                                icon: Icon(
                                  _showQuickDrawer
                                      ? Icons.menu_open_rounded
                                      : Icons.list_rounded,
                                  color: Colors.white,
                                ),
                                tooltip: 'Guia de canais',
                                onPressed: _openQuickDrawer,
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
                    bottom: safe.bottom,
                    left: safe.left,
                    right: safe.right,
                    child: PlayerControls(
                      key: _controlsKey,
                      primaryFocusNode: _playPauseFocusNode,
                      onHide: _hideControls,
                      playbackState: state.playbackState,
                      isLive: _isLive,
                      hasPreviousEpisode: _hasPrevEpisode,
                      hasNextEpisode: _hasNextEpisode,
                      playbackSpeed: _currentSpeed,
                      onSpeedChanged: (speed) {
                        setState(() => _currentSpeed = speed);
                        ref
                            .read(playerProvider.notifier)
                            .setPlaybackSpeed(speed);
                      },
                      onOpenSubtitles: _showTrackSelectorDrawer,
                      onOpenAudio: _showTrackSelectorDrawer,
                      onPreviousEpisode: _hasPrevEpisode
                          ? () => _switchEpisode(_currentEpisodeIndex! - 1)
                          : null,
                      onNextEpisode: _hasNextEpisode
                          ? () => _switchEpisode(_currentEpisodeIndex! + 1)
                          : null,
                      onSeek: (target) {
                        ref.read(playerProvider.notifier).seek(target);
                      },
                      onReplay10: () => _seekBy(-10),
                      onForward10: () => _seekBy(10),
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
                        _goBack();
                      },
                      onVolumeChanged: (vol) {
                        ref.read(playerProvider.notifier).setVolume(vol);
                      },
                    ),
                  ),
                ],

                // Auto-Play Next Episode overlay (when 15s remaining in series)
                if (!_dismissedAutoPlay &&
                    _hasNextEpisode &&
                    state.playbackState.duration > const Duration(minutes: 1) &&
                    state.playbackState.position >=
                        state.playbackState.duration -
                            const Duration(seconds: 15)) ...[
                  Positioned(
                    bottom: 90,
                    right: 24,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(14),
                        border:
                            Border.all(color: AppColors.primary, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.skip_next_rounded,
                              color: AppColors.primary, size: 24),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Próximo episódio em ${(state.playbackState.duration - state.playbackState.position).inSeconds.clamp(1, 15)}s',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                _episodePlaylist![_currentEpisodeIndex! + 1]
                                    .title,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 14),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () =>
                                _switchEpisode(_currentEpisodeIndex! + 1),
                            child: const Text('Assistir Agora',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12)),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.close_rounded,
                                color: Colors.white60, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () =>
                                setState(() => _dismissedAutoPlay = true),
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
      ),
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (ModalRoute.of(context)?.isCurrent != true) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final direction = RemoteKeys.direction(key);
    final recognized = direction != null ||
        RemoteKeys.isSelect(key) ||
        RemoteKeys.isBack(key) ||
        const [
          LogicalKeyboardKey.mediaPlayPause,
          LogicalKeyboardKey.mediaPlay,
          LogicalKeyboardKey.mediaPause,
          LogicalKeyboardKey.mediaStop,
          LogicalKeyboardKey.mediaRewind,
          LogicalKeyboardKey.mediaFastForward,
          LogicalKeyboardKey.channelUp,
          LogicalKeyboardKey.channelDown,
          LogicalKeyboardKey.contextMenu,
        ].contains(key);
    if (event is KeyUpEvent) {
      return recognized ? KeyEventResult.handled : KeyEventResult.ignored;
    }
    if (RemoteKeys.isBack(key)) {
      if (event is KeyDownEvent) _handleBack();
      return KeyEventResult.handled;
    }
    if (_showQuickDrawer) return KeyEventResult.ignored;
    if (direction != null) {
      if (!_showControls || _keyboardFocusNode.hasPrimaryFocus) {
        _revealControls();
      } else {
        FocusManager.instance.primaryFocus?.focusInDirection(direction);
      }
      return KeyEventResult.handled;
    }
    if (RemoteKeys.isSelect(key)) {
      if (event is KeyDownEvent && _keyboardFocusNode.hasPrimaryFocus) {
        _revealControls();
      }
      return KeyEventResult.handled;
    }
    if (event is! KeyDownEvent) {
      return recognized ? KeyEventResult.handled : KeyEventResult.ignored;
    }
    switch (key) {
      case LogicalKeyboardKey.mediaPlayPause:
        _togglePlayback();
      case LogicalKeyboardKey.mediaPlay:
        ref.read(playerProvider.notifier).resume();
      case LogicalKeyboardKey.mediaPause:
        ref.read(playerProvider.notifier).pause();
      case LogicalKeyboardKey.mediaStop:
        _goBack();
      case LogicalKeyboardKey.mediaRewind:
        _seekBy(-10);
      case LogicalKeyboardKey.mediaFastForward:
        _seekBy(10);
      case LogicalKeyboardKey.channelUp:
        _zapChannel(false);
      case LogicalKeyboardKey.channelDown:
        _zapChannel(true);
      case LogicalKeyboardKey.contextMenu:
        if (_isLive) {
          _openQuickDrawer();
        } else {
          _showTrackSelectorDrawer();
        }
      case LogicalKeyboardKey.keyM:
        final volume = ref.read(playerProvider).playbackState.volume;
        ref.read(playerProvider.notifier).setVolume(volume > 0 ? 0 : 1);
      case LogicalKeyboardKey.keyC:
      case LogicalKeyboardKey.keyA:
        _showTrackSelectorDrawer();
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }
}
