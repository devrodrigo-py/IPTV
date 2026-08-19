import 'package:nebula_iptv/core/result/result.dart';

/// Playback state of the video player.
enum PlaybackStatus {
  idle,
  buffering,
  playing,
  paused,
  stopped,
  error,
}

/// Represents the current state of video playback.
class VideoPlaybackState {
  final PlaybackStatus status;
  final Duration position;
  final Duration duration;
  final double volume;
  final bool isFullscreen;

  const VideoPlaybackState({
    this.status = PlaybackStatus.idle,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.volume = 1.0,
    this.isFullscreen = false,
  });

  VideoPlaybackState copyWith({
    PlaybackStatus? status,
    Duration? position,
    Duration? duration,
    double? volume,
    bool? isFullscreen,
  }) {
    return VideoPlaybackState(
      status: status ?? this.status,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
      isFullscreen: isFullscreen ?? this.isFullscreen,
    );
  }
}

/// Represents buffer state.
class VideoBufferState {
  final bool isBuffering;
  final double bufferPercent;

  const VideoBufferState({
    this.isBuffering = false,
    this.bufferPercent = 0.0,
  });
}

/// Structured error event from the player.
class VideoPlayerError {
  final String code;
  final String message;
  final Object? originalError;

  const VideoPlayerError({
    required this.code,
    required this.message,
    this.originalError,
  });

  @override
  String toString() => 'VideoPlayerError($code: $message)';
}

/// An audio or subtitle track.
class VideoTrack {
  final String id;
  final String? title;
  final String? language;

  const VideoTrack({
    required this.id,
    this.title,
    this.language,
  });
}

/// Abstract interface for video playback (spec §4.1, §13).
///
/// The domain and presentation layers interact only with this interface.
/// The concrete implementation (media_kit) lives in the data layer.
abstract interface class VideoPlayerService {
  /// Initializes the player engine.
  Future<Result<void>> initialize();

  /// Starts playback of the given stream URL.
  Future<Result<void>> play(String url);

  /// Pauses playback.
  Future<Result<void>> pause();

  /// Resumes playback after pause.
  Future<Result<void>> resume();

  /// Stops playback completely.
  Future<Result<void>> stop();

  /// Sets volume (0.0 to 1.0).
  Future<Result<void>> setVolume(double volume);

  /// Selects an audio track by ID.
  Future<Result<void>> selectAudioTrack(String trackId);

  /// Selects a subtitle track by ID (null to disable).
  Future<Result<void>> selectSubtitleTrack(String? trackId);

  /// Stream of playback state changes.
  Stream<VideoPlaybackState> get playbackState;

  /// Stream of buffer state changes.
  Stream<VideoBufferState> get bufferState;

  /// Stream of player errors.
  Stream<VideoPlayerError> get errors;

  /// Stream of available audio tracks.
  Stream<List<VideoTrack>> get audioTracks;

  /// Stream of available subtitle tracks.
  Stream<List<VideoTrack>> get subtitleTracks;

  /// Releases all player resources.
  Future<void> dispose();
}
