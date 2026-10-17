import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/core/logging/app_logger.dart';
import 'package:nebula_iptv/domain/providers/health_check_providers.dart';
import 'package:nebula_iptv/domain/providers/watch_providers.dart';
import 'package:nebula_iptv/domain/services/health_check_service.dart';
import 'package:nebula_iptv/domain/services/stream_reconnection_service.dart';
import 'package:nebula_iptv/domain/services/video_player_service.dart';
import 'package:nebula_iptv/domain/services/watch_tracking_service.dart';

/// State for the player screen.
class PlayerState {
  final VideoPlaybackState playbackState;
  final VideoBufferState bufferState;
  final ReconnectionStatus reconnectionStatus;
  final int reconnectionAttempt;

  const PlayerState({
    this.playbackState = const VideoPlaybackState(),
    this.bufferState = const VideoBufferState(),
    this.reconnectionStatus = ReconnectionStatus.idle,
    this.reconnectionAttempt = 0,
  });

  PlayerState copyWith({
    VideoPlaybackState? playbackState,
    VideoBufferState? bufferState,
    ReconnectionStatus? reconnectionStatus,
    int? reconnectionAttempt,
  }) {
    return PlayerState(
      playbackState: playbackState ?? this.playbackState,
      bufferState: bufferState ?? this.bufferState,
      reconnectionStatus: reconnectionStatus ?? this.reconnectionStatus,
      reconnectionAttempt: reconnectionAttempt ?? this.reconnectionAttempt,
    );
  }
}

/// Provider for the video player service.
/// Must be overridden in app bootstrap.
final videoPlayerServiceProvider = Provider<VideoPlayerService>((ref) {
  throw UnimplementedError('videoPlayerServiceProvider must be overridden');
});

/// Provider for the player screen state.
final playerProvider =
    StateNotifierProvider.autoDispose<PlayerNotifier, PlayerState>(
  (ref) => PlayerNotifier(ref),
);

/// Owns a playback session. Opens are serialized; superseded sessions cannot
/// seek, reconnect or publish state into the next channel.
class PlayerNotifier extends StateNotifier<PlayerState> {
  final Ref _ref;
  StreamReconnectionService? _reconnectionService;
  StreamSubscription<ReconnectionStatus>? _reconnectionSubscription;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  VideoPlayerService? _service;
  WatchTrackingService? _tracking;
  ChannelHealthCheckService? _health;
  Future<void> _queue = Future.value();
  Timer? _bufferWatchdog;
  int _session = 0;
  int? _pendingSeekMs;
  String? _currentUrl;
  WatchContentInfo? _contentInfo;
  PlayerNotifier(this._ref) : super(const PlayerState());

  bool _current(int session) => mounted && session == _session;
  Future<T> _serial<T>(Future<T> Function() operation) {
    final next = _queue.then((_) => operation());
    _queue = next.then<void>((_) {}, onError: (Object error, StackTrace stack) {
      appLogger.w('player.operation.failed');
    });
    return next;
  }

  Future<void> _unsubscribe() async {
    final subscriptions = [..._subscriptions];
    _subscriptions.clear();
    for (final sub in subscriptions) {
      await sub.cancel();
    }
  }

  void _cancelRecovery() {
    _bufferWatchdog?.cancel();
    _bufferWatchdog = null;
    _reconnectionSubscription?.cancel();
    _reconnectionSubscription = null;
    _reconnectionService?.dispose();
    _reconnectionService = null;
  }

  Future<void> playStream(String url,
      {WatchContentInfo? contentInfo, int? seekToMs}) {
    final session = ++_session;
    _cancelRecovery();
    _currentUrl = url;
    _contentInfo = contentInfo;
    _service ??= _ref.read(videoPlayerServiceProvider);
    _tracking ??= _ref.read(watchTrackingServiceProvider);
    _health ??= _ref.read(healthCheckServiceProvider);
    state = const PlayerState(
        playbackState: VideoPlaybackState(status: PlaybackStatus.buffering));
    return _serial(() async {
      if (!_current(session)) return;
      await _unsubscribe();
      await _tracking!.stopTracking();
      if (!_current(session)) return;
      _pendingSeekMs = seekToMs;
      _listen(session);
      if (contentInfo != null) _tracking!.startTracking(contentInfo);
      _health!.pause();
      _armWatchdog(session);
      try {
        final result = await _service!.play(url);
        if (_current(session) && result.isFailure) _failed(session);
      } catch (_) {
        if (_current(session)) _failed(session);
      }
    });
  }

  void _listen(int session) {
    _subscriptions.add(_service!.playbackState.listen((playback) {
      if (!_current(session)) return;
      state = state.copyWith(playbackState: playback);
      _tracking?.setPlaying(playback.status == PlaybackStatus.playing);
      if (playback.status == PlaybackStatus.playing &&
          playback.position > Duration.zero) {
        _bufferWatchdog?.cancel();
        _bufferWatchdog = null;
        if (_pendingSeekMs case final int target when target > 0) {
          _pendingSeekMs = null;
          _service!.seek(Duration(milliseconds: target));
        }
        if (_contentInfo != null) {
          _tracking!.updateProgress(
              position: playback.position, duration: playback.duration);
        }
      } else if (playback.status == PlaybackStatus.error) {
        _startReconnection(session);
      } else if (playback.status == PlaybackStatus.buffering) {
        _armWatchdog(session);
      }
    }));
    _subscriptions.add(_service!.bufferState.listen((buffer) {
      if (!_current(session)) return;
      state = state.copyWith(bufferState: buffer);
      if (buffer.isBuffering) _armWatchdog(session);
    }));
  }

  void _armWatchdog(int session) {
    if (_bufferWatchdog != null || _reconnectionService?.isReconnecting == true) {
      return;
    }
    _bufferWatchdog = Timer(const Duration(seconds: 20), () {
      _bufferWatchdog = null;
      if (_current(session)) _failed(session);
    });
  }

  void _failed(int session) {
    state = state.copyWith(
        playbackState:
            state.playbackState.copyWith(status: PlaybackStatus.error));
    _startReconnection(session);
  }

  void _startReconnection(int session) {
    if (!_current(session) || _currentUrl == null) return;
    _bufferWatchdog?.cancel();
    _bufferWatchdog = null;
    if (_reconnectionService == null) {
      final url = _currentUrl!;
      _reconnectionService = StreamReconnectionService(
          onReconnect: () => _serial(() async {
                if (!_current(session)) return false;
                final ready = Completer<bool>();
                final listener = _service!.playbackState.listen((playback) {
                  if (ready.isCompleted) return;
                  if (playback.status == PlaybackStatus.playing &&
                      playback.position > Duration.zero) {
                    ready.complete(true);
                  } else if (playback.status == PlaybackStatus.error) {
                    ready.complete(false);
                  }
                });
                try {
                  if (_contentInfo?.contentType != 'live') {
                    _pendingSeekMs =
                        state.playbackState.position.inMilliseconds;
                  }
                  final opened = await _service!.play(url);
                  if (!_current(session) || opened.isFailure) return false;
                  return await ready.future.timeout(const Duration(seconds: 15),
                      onTimeout: () => false);
                } finally {
                  await listener.cancel();
                }
              }));
      _reconnectionSubscription = _reconnectionService!.status.listen((status) {
        if (_current(session)) {
          state = state.copyWith(
              reconnectionStatus: status,
              reconnectionAttempt: _reconnectionService!.attempt);
        }
      });
    }
    _reconnectionService!.start();
  }

  Future<void> pause() async {
    await _service?.pause();
  }

  Future<void> resume() async {
    await _service?.resume();
  }

  Future<void> stop() {
    ++_session;
    _cancelRecovery();
    _currentUrl = null;
    return _serial(() async {
      await _unsubscribe();
      await _tracking?.stopTracking();
      await _service?.stop();
      _health?.resume();
    });
  }

  Future<void> setVolume(double value) async {
    await _service?.setVolume(value);
  }

  Future<void> seek(Duration target) async {
    await _service?.seek(target);
  }

  Future<void> setPlaybackSpeed(double speed) async {
    await _service?.setPlaybackSpeed(speed);
  }

  Future<void> selectAudioTrack(String trackId) async {
    await _service?.selectAudioTrack(trackId);
  }

  Future<void> selectSubtitleTrack(String? trackId) async {
    await _service?.selectSubtitleTrack(trackId);
  }

  Future<void> addExternalSubtitle(String uri,
      {String? title, String? language}) async {
    await _service?.addExternalSubtitle(uri, title: title, language: language);
  }

  Future<void> retry(String url) => playStream(url,
      contentInfo: _contentInfo,
      seekToMs: state.playbackState.position.inMilliseconds);

  @override
  void dispose() {
    ++_session;
    _cancelRecovery();
    unawaited(_unsubscribe());
    final service = _service;
    final tracking = _tracking;
    unawaited(_serial(() async {
      await tracking?.stopTracking();
      await service?.stop();
      _health?.resume();
    }));
    super.dispose();
  }
}
