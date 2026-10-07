import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/core/logging/app_logger.dart';
import 'package:nebula_iptv/domain/providers/health_check_providers.dart';
import 'package:nebula_iptv/domain/providers/watch_providers.dart';
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

/// Manages player state, playback, reconnection, and watch tracking.
class PlayerNotifier extends StateNotifier<PlayerState> {
  final Ref _ref;
  StreamReconnectionService? _reconnectionService;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  String? _currentUrl;
  WatchContentInfo? _contentInfo;

  PlayerNotifier(this._ref) : super(const PlayerState());

  /// Starts playing a stream URL with optional content info for tracking.
  Future<void> playStream(
    String url, {
    WatchContentInfo? contentInfo,
    int? seekToMs,
  }) async {
    _currentUrl = url;
    _contentInfo = contentInfo;

    final player = _ref.read(videoPlayerServiceProvider);

    // Listen to player streams
    _subscriptions.add(
      player.playbackState.listen((playback) {
        if (mounted) {
          state = state.copyWith(playbackState: playback);

          // Update watch tracking with progress (on every state change while
          // playing). media_kit forwards position updates through this stream.
          if (_contentInfo != null &&
              playback.status == PlaybackStatus.playing &&
              playback.position > Duration.zero) {
            _ref.read(watchTrackingServiceProvider).updateProgress(
                  position: playback.position,
                  duration: playback.duration,
                );
          }

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

    // Start watch tracking
    if (_contentInfo != null) {
      _ref.read(watchTrackingServiceProvider).startTracking(_contentInfo!);
    }

    // Background health checks pause during playback
    _ref.read(healthCheckServiceProvider).pause();

    await player.play(url);

    // Seek to saved position if resuming
    if (seekToMs != null && seekToMs > 0) {
      final targetMs = seekToMs; // Capture for closure
      appLogger.d('[Player] Will seek to ${targetMs}ms once stream is playing');
      // Once a real position arrives (video is playing), do the seek
      late final StreamSubscription<VideoPlaybackState> seekSub;
      seekSub = player.playbackState.listen((playback) {
        if (playback.position.inMilliseconds > 100) {
          seekSub.cancel();
          appLogger.d(
            '[Player] Stream playing at ${playback.position.inMilliseconds}ms, '
            'seeking to ${targetMs}ms',
          );
          player.seek(Duration(milliseconds: targetMs));
        }
      });
      // Safety timeout: cancel listener after 15s if video never starts
      Future.delayed(const Duration(seconds: 15), () {
        seekSub.cancel();
      });
    }
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
    // Stop watch tracking
    await _ref.read(watchTrackingServiceProvider).stopTracking();
    await _ref.read(videoPlayerServiceProvider).stop();
    // Health checks may resume when nothing is playing
    _ref.read(healthCheckServiceProvider).resume();
  }

  /// Sets volume (0.0 - 1.0).
  Future<void> setVolume(double volume) async {
    await _ref.read(videoPlayerServiceProvider).setVolume(volume);
  }

  /// Seeks to a specific target duration.
  Future<void> seek(Duration target) async {
    await _ref.read(videoPlayerServiceProvider).seek(target);
  }

  /// Sets playback speed rate (e.g. 0.5, 1.0, 1.25, 1.5, 2.0).
  Future<void> setPlaybackSpeed(double speed) async {
    await _ref.read(videoPlayerServiceProvider).setPlaybackSpeed(speed);
  }

  /// Selects an audio track by ID.
  Future<void> selectAudioTrack(String trackId) async {
    await _ref.read(videoPlayerServiceProvider).selectAudioTrack(trackId);
  }

  /// Selects a subtitle track by ID (pass null to disable).
  Future<void> selectSubtitleTrack(String? trackId) async {
    await _ref.read(videoPlayerServiceProvider).selectSubtitleTrack(trackId);
  }

  /// Injects an external subtitle (.srt, .vtt).
  Future<void> addExternalSubtitle(String uri,
      {String? title, String? language}) async {
    await _ref.read(videoPlayerServiceProvider).addExternalSubtitle(
          uri,
          title: title,
          language: language,
        );
  }

  /// Manual retry after reconnection exhausted.
  Future<void> retry(String url) async {
    _reconnectionService?.reset();
    state = state.copyWith(
      reconnectionStatus: ReconnectionStatus.idle,
      reconnectionAttempt: 0,
    );
    await playStream(url, contentInfo: _contentInfo);
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
    // Stop watch tracking (fire-and-forget in dispose)
    try {
      _ref.read(watchTrackingServiceProvider).stopTracking();
    } catch (e) {
      appLogger.d('[Player] Falha ao parar tracking no dispose: $e');
    }
    // Stop playback when leaving the player screen (safe to call even if already stopped)
    try {
      _ref.read(videoPlayerServiceProvider).stop();
    } catch (e) {
      // Player may already be disposed — ignore, but keep it observable
      appLogger.d('[Player] Falha ao parar playback no dispose: $e');
    }
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _reconnectionService?.dispose();
    super.dispose();
  }
}
