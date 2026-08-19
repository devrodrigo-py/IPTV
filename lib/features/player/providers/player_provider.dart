import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/domain/services/stream_reconnection_service.dart';
import 'package:nebula_iptv/domain/services/video_player_service.dart';

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

/// Manages player state, playback, and reconnection.
class PlayerNotifier extends StateNotifier<PlayerState> {
  final Ref _ref;
  StreamReconnectionService? _reconnectionService;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  String? _currentUrl;

  PlayerNotifier(this._ref) : super(const PlayerState());

  /// Starts playing a stream URL.
  Future<void> playStream(String url) async {
    _currentUrl = url;
    final player = _ref.read(videoPlayerServiceProvider);

    // Listen to player streams
    _subscriptions.add(
      player.playbackState.listen((playback) {
        if (mounted) {
          state = state.copyWith(playbackState: playback);

          // Trigger reconnection on error
          if (playback.status == PlaybackStatus.error) {
            _startReconnection();
          }
        }
      }),
    );

    _subscriptions.add(
      player.bufferState.listen((buffer) {
        if (mounted) {
          state = state.copyWith(bufferState: buffer);
        }
      }),
    );

    await player.play(url);
  }

  /// Pauses playback.
  Future<void> pause() async {
    await _ref.read(videoPlayerServiceProvider).pause();
  }

  /// Resumes playback.
  Future<void> resume() async {
    await _ref.read(videoPlayerServiceProvider).resume();
  }

  /// Stops playback.
  Future<void> stop() async {
    _reconnectionService?.cancel();
    await _ref.read(videoPlayerServiceProvider).stop();
  }

  /// Sets volume (0.0 - 1.0).
  Future<void> setVolume(double volume) async {
    await _ref.read(videoPlayerServiceProvider).setVolume(volume);
  }

  /// Manual retry after reconnection exhausted.
  Future<void> retry(String url) async {
    _reconnectionService?.reset();
    state = state.copyWith(
      reconnectionStatus: ReconnectionStatus.idle,
      reconnectionAttempt: 0,
    );
    await playStream(url);
  }

  void _startReconnection() {
    if (_currentUrl == null) return;

    _reconnectionService?.dispose();
    _reconnectionService = StreamReconnectionService(
      onReconnect: () async {
        final result =
            await _ref.read(videoPlayerServiceProvider).play(_currentUrl!);
        return result.isSuccess;
      },
    );

    _reconnectionService!.status.listen((status) {
      if (mounted) {
        state = state.copyWith(
          reconnectionStatus: status,
          reconnectionAttempt: _reconnectionService!.attempt,
        );
      }
    });

    _reconnectionService!.start();
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _reconnectionService?.dispose();
    super.dispose();
  }
}
