import 'dart:async';

import 'package:nebula_iptv/core/errors/app_failure.dart';
import 'package:nebula_iptv/core/logging/app_logger.dart';
import 'package:nebula_iptv/core/result/result.dart';
import 'package:nebula_iptv/domain/services/video_player_service.dart';
import 'package:video_player/video_player.dart';

/// Web implementation of [VideoPlayerService] using video_player package.
///
/// Supports HLS/DASH streams that the browser can play natively.
/// Limitation: CORS — most IPTV servers don't send CORS headers,
/// so streams may not load directly in the browser without a proxy.
class WebPlayerService implements VideoPlayerService {
  VideoPlayerController? _controller;

  final _playbackStateController =
      StreamController<VideoPlaybackState>.broadcast();
  final _bufferStateController =
      StreamController<VideoBufferState>.broadcast();
  final _errorController = StreamController<VideoPlayerError>.broadcast();
  final _audioTracksController =
      StreamController<List<VideoTrack>>.broadcast();
  final _subtitleTracksController =
      StreamController<List<VideoTrack>>.broadcast();

  VideoPlaybackState _currentState = const VideoPlaybackState();

  @override
  Future<Result<void>> initialize() async {
    return const Success(null);
  }

  @override
  Future<Result<void>> play(String url) async {
    try {
      await _controller?.dispose();
      _updateState(_currentState.copyWith(status: PlaybackStatus.buffering));

      _controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await _controller!.initialize();

      _controller!.addListener(_onPlayerUpdate);
      await _controller!.play();

      appLogger.i('Web player: playing $url');
      return const Success(null);
    } catch (e) {
      _errorController.add(VideoPlayerError(
        code: 'WEB_PLAY_ERROR',
        message: 'Não foi possível reproduzir o stream no navegador.',
        originalError: e,
      ));
      _updateState(_currentState.copyWith(status: PlaybackStatus.error));
      return Failure(
        StreamUnavailableFailure(
          message: 'Erro ao reproduzir. '
              'O stream pode não ser compatível com o navegador.',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Result<void>> pause() async {
    await _controller?.pause();
    return const Success(null);
  }

  @override
  Future<Result<void>> resume() async {
    await _controller?.play();
    return const Success(null);
  }

  @override
  Future<Result<void>> stop() async {
    await _controller?.pause();
    await _controller?.seekTo(Duration.zero);
    _updateState(const VideoPlaybackState(status: PlaybackStatus.stopped));
    return const Success(null);
  }

  @override
  Future<Result<void>> setVolume(double volume) async {
    await _controller?.setVolume(volume);
    _updateState(_currentState.copyWith(volume: volume));
    return const Success(null);
  }

  @override
  Future<Result<void>> selectAudioTrack(String trackId) async {
    // video_player web doesn't support audio track selection
    return const Success(null);
  }

  @override
  Future<Result<void>> selectSubtitleTrack(String? trackId) async {
    // video_player web doesn't support subtitle track selection
    return const Success(null);
  }

  @override
  Stream<VideoPlaybackState> get playbackState =>
      _playbackStateController.stream;

  @override
  Stream<VideoBufferState> get bufferState => _bufferStateController.stream;

  @override
  Stream<VideoPlayerError> get errors => _errorController.stream;

  @override
  Stream<List<VideoTrack>> get audioTracks => _audioTracksController.stream;

  @override
  Stream<List<VideoTrack>> get subtitleTracks =>
      _subtitleTracksController.stream;

  @override
  Future<void> dispose() async {
    _controller?.removeListener(_onPlayerUpdate);
    await _controller?.dispose();
    _controller = null;
    await _playbackStateController.close();
    await _bufferStateController.close();
    await _errorController.close();
    await _audioTracksController.close();
    await _subtitleTracksController.close();
  }

  void _onPlayerUpdate() {
    final controller = _controller;
    if (controller == null) return;

    final value = controller.value;

    PlaybackStatus status;
    if (value.hasError) {
      status = PlaybackStatus.error;
      _errorController.add(VideoPlayerError(
        code: 'PLAYBACK_ERROR',
        message: value.errorDescription ?? 'Erro de reprodução',
      ));
    } else if (value.isBuffering) {
      status = PlaybackStatus.buffering;
    } else if (value.isPlaying) {
      status = PlaybackStatus.playing;
    } else {
      status = PlaybackStatus.paused;
    }

    _updateState(VideoPlaybackState(
      status: status,
      position: value.position,
      duration: value.duration,
      volume: value.volume,
    ));

    _bufferStateController.add(VideoBufferState(
      isBuffering: value.isBuffering,
    ));
  }

  void _updateState(VideoPlaybackState newState) {
    _currentState = newState;
    _playbackStateController.add(newState);
  }
}
