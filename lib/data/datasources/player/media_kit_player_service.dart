import 'dart:async';

import 'package:media_kit/media_kit.dart' hide VideoTrack;
import 'package:nebula_iptv/core/errors/app_failure.dart';
import 'package:nebula_iptv/core/logging/app_logger.dart';
import 'package:nebula_iptv/core/result/result.dart';
import 'package:nebula_iptv/domain/services/video_player_service.dart';

/// Concrete implementation of [VideoPlayerService] using media_kit (spec §4.1).
///
/// The presentation layer never imports this directly — it only
/// depends on [VideoPlayerService].
class MediaKitPlayerService implements VideoPlayerService {
  Player? _player;

  final _playbackStateController =
      StreamController<VideoPlaybackState>.broadcast();
  final _bufferStateController = StreamController<VideoBufferState>.broadcast();
  final _errorController = StreamController<VideoPlayerError>.broadcast();
  final _audioTracksController = StreamController<List<VideoTrack>>.broadcast();
  final _subtitleTracksController =
      StreamController<List<VideoTrack>>.broadcast();

  VideoPlaybackState _currentState = const VideoPlaybackState();
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  @override
  Future<Result<void>> initialize() async {
    try {
      _player = Player();
      _setupListeners();
      appLogger.i('MediaKit player initialized');
      return const Success(null);
    } catch (e) {
      return Failure(
        StreamUnavailableFailure(
          message: 'Erro ao inicializar o player.',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Result<void>> play(String url) async {
    if (_player == null) {
      final initResult = await initialize();
      if (initResult.isFailure) return initResult;
    }

    try {
      _updateState(_currentState.copyWith(status: PlaybackStatus.buffering));
      await _player!.open(Media(url));
      return const Success(null);
    } catch (e) {
      _emitError('PLAY_ERROR', 'Erro ao reproduzir stream.', e);
      return Failure(
        StreamUnavailableFailure(
          message: 'Não foi possível reproduzir o canal.',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Result<void>> pause() async {
    try {
      await _player?.pause();
      return const Success(null);
    } catch (e) {
      return Failure(
        StreamUnavailableFailure(
          message: 'Erro ao pausar.',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Result<void>> resume() async {
    try {
      await _player?.play();
      return const Success(null);
    } catch (e) {
      return Failure(
        StreamUnavailableFailure(
          message: 'Erro ao retomar reprodução.',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Result<void>> stop() async {
    try {
      await _player?.stop();
      _updateState(const VideoPlaybackState(status: PlaybackStatus.stopped));
      return const Success(null);
    } catch (e) {
      return Failure(
        StreamUnavailableFailure(
          message: 'Erro ao parar reprodução.',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Result<void>> setVolume(double volume) async {
    try {
      await _player?.setVolume(volume * 100); // media_kit uses 0-100
      _updateState(_currentState.copyWith(volume: volume));
      return const Success(null);
    } catch (e) {
      return const Failure(
        StreamUnavailableFailure(message: 'Erro ao ajustar volume.'),
      );
    }
  }

  @override
  Future<Result<void>> selectAudioTrack(String trackId) async {
    try {
      final tracks = _player?.state.tracks.audio ?? [];
      final track = tracks.firstWhere(
        (t) => t.id == trackId,
        orElse: () => tracks.first,
      );
      await _player?.setAudioTrack(track);
      return const Success(null);
    } catch (e) {
      return const Failure(
        StreamUnavailableFailure(message: 'Erro ao selecionar áudio.'),
      );
    }
  }

  @override
  Future<Result<void>> selectSubtitleTrack(String? trackId) async {
    try {
      if (trackId == null) {
        await _player?.setSubtitleTrack(SubtitleTrack.no());
      } else {
        final tracks = _player?.state.tracks.subtitle ?? [];
        final track = tracks.firstWhere(
          (t) => t.id == trackId,
          orElse: () => SubtitleTrack.no(),
        );
        await _player?.setSubtitleTrack(track);
      }
      return const Success(null);
    } catch (e) {
      return const Failure(
        StreamUnavailableFailure(message: 'Erro ao selecionar legenda.'),
      );
    }
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
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();
    await _player?.dispose();
    _player = null;
    await _playbackStateController.close();
    await _bufferStateController.close();
    await _errorController.close();
    await _audioTracksController.close();
    await _subtitleTracksController.close();
  }

  void _setupListeners() {
    final player = _player!;

    _subscriptions.add(
      player.stream.playing.listen((playing) {
        _updateState(
          _currentState.copyWith(
            status: playing ? PlaybackStatus.playing : PlaybackStatus.paused,
          ),
        );
      }),
    );

    _subscriptions.add(
      player.stream.buffering.listen((buffering) {
        _bufferStateController.add(VideoBufferState(isBuffering: buffering));
        if (buffering) {
          _updateState(
            _currentState.copyWith(status: PlaybackStatus.buffering),
          );
        }
      }),
    );

    _subscriptions.add(
      player.stream.position.listen((position) {
        _updateState(_currentState.copyWith(position: position));
      }),
    );

    _subscriptions.add(
      player.stream.duration.listen((duration) {
        _updateState(_currentState.copyWith(duration: duration));
      }),
    );

    _subscriptions.add(
      player.stream.error.listen((error) {
        if (error.isNotEmpty) {
          _emitError('STREAM_ERROR', error, null);
          _updateState(
            _currentState.copyWith(status: PlaybackStatus.error),
          );
        }
      }),
    );

    _subscriptions.add(
      player.stream.tracks.listen((tracks) {
        _audioTracksController.add(
          tracks.audio
              .map(
                (t) => VideoTrack(
                  id: t.id,
                  title: t.title,
                  language: t.language,
                ),
              )
              .toList(),
        );
        _subtitleTracksController.add(
          tracks.subtitle
              .map(
                (t) => VideoTrack(
                  id: t.id,
                  title: t.title,
                  language: t.language,
                ),
              )
              .toList(),
        );
      }),
    );
  }

  void _updateState(VideoPlaybackState newState) {
    _currentState = newState;
    _playbackStateController.add(newState);
  }

  void _emitError(String code, String message, Object? originalError) {
    _errorController.add(
      VideoPlayerError(
        code: code,
        message: message,
        originalError: originalError,
      ),
    );
  }
}
