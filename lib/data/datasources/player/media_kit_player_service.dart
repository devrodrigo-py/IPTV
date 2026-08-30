import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:media_kit/media_kit.dart' hide VideoTrack;
import 'package:media_kit_video/media_kit_video.dart';
import 'package:nebula_iptv/core/errors/app_failure.dart';
import 'package:nebula_iptv/core/logging/app_logger.dart';
import 'package:nebula_iptv/core/result/result.dart';
import 'package:nebula_iptv/domain/services/video_player_service.dart';

/// Concrete implementation of [VideoPlayerService] using media_kit (spec §4.1).
///
/// The presentation layer never imports this directly — it only
/// depends on [VideoPlayerService] and embeds the widget returned by
/// [buildVideoSurface].
class MediaKitPlayerService implements VideoPlayerService {
  Player? _player;
  VideoController? _videoController;

  final _playbackStateController =
      StreamController<VideoPlaybackState>.broadcast();
  final _bufferStateController = StreamController<VideoBufferState>.broadcast();
  final _errorController = StreamController<VideoPlayerError>.broadcast();
  final _audioTracksController = StreamController<List<VideoTrack>>.broadcast();
  final _subtitleTracksController =
      StreamController<List<VideoTrack>>.broadcast();
  final _completedController = StreamController<void>.broadcast();

  VideoPlaybackState _currentState = const VideoPlaybackState();
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  /// Exposes the underlying media_kit Player for the Video widget.
  Player? get player => _player;

  @override
  Future<Result<void>> initialize() async {
    if (_player != null) return const Success(null);
    try {
      _player = Player(
        configuration: const PlayerConfiguration(
          bufferSize: 32 * 1024 * 1024,
          logLevel: MPVLogLevel.warn,
        ),
      );
      // The render surface is owned by the service so the presentation
      // layer never touches media_kit types directly.
      _videoController = VideoController(_player!);
      _setupListeners();

      // Configure hardware decoding and network reconnection
      try {
        final mpv = _player!.platform as dynamic;
        await mpv.setProperty('hwdec', 'auto-safe');
        await mpv.setProperty(
          'stream-lavf-o',
          'reconnect=1,reconnect_streamed=1,reconnect_delay_max=5',
        );
      } catch (e) {
        // Propriedades são opcionais (dependem da plataforma/build do mpv).
        appLogger.d('[Player] mpv config opcional indisponível: $e');
      }

      appLogger.i(
          'MediaKit player initialized with hardware decoding and resilient reconnection');
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

      // Dynamic buffer: 2s for live zapping, 15s for VOD
      final isLive = url.contains('/live/') ||
          url.contains('.m3u8') ||
          url.endsWith('.ts');
      try {
        final mpv = _player!.platform as dynamic;
        await mpv.setProperty('demuxer-readahead-secs', isLive ? '2' : '15');
      } catch (e) {
        // Propriedade opcional; falha não deve interromper a reprodução.
        appLogger.d('[Player] Buffer dinâmico (mpv) indisponível: $e');
      }

      // For live streams, use .m3u8 extension (HLS) instead of .ts
      // This enables proper live streaming behavior (no download-and-play)
      var playUrl = url;
      if (url.contains('/live/') && url.endsWith('.ts')) {
        playUrl = '${url.substring(0, url.length - 3)}.m3u8';
      }
      await _player!.open(Media(playUrl));
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
  Future<Result<void>> seek(Duration position) async {
    try {
      await _player?.seek(position);
      return const Success(null);
    } catch (e) {
      return const Failure(
        StreamUnavailableFailure(message: 'Erro ao avançar/retroceder.'),
      );
    }
  }

  @override
  Future<Result<void>> setPlaybackSpeed(double speed) async {
    try {
      await _player?.setRate(speed);
      return const Success(null);
    } catch (e) {
      return const Failure(
        StreamUnavailableFailure(message: 'Erro ao ajustar velocidade.'),
      );
    }
  }

  @override
  Future<Result<void>> selectAudioTrack(String trackId) async {
    try {
      final tracks = _player?.state.tracks.audio ?? [];
      AudioTrack? track;
      for (final t in tracks) {
        if (t.id == trackId) {
          track = t;
          break;
        }
      }
      if (track == null) {
        // Não fabricar fallback silencioso: a faixa pedida não existe.
        appLogger.w(
          '[Player] Faixa de áudio "$trackId" não encontrada '
          '(${tracks.length} faixas disponíveis).',
        );
        return const Failure(
          StreamUnavailableFailure(message: 'Faixa de áudio não encontrada.'),
        );
      }
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
      if (trackId == null || trackId == 'no') {
        await _player?.setSubtitleTrack(SubtitleTrack.no());
      } else {
        final tracks = _player?.state.tracks.subtitle ?? [];
        SubtitleTrack? track;
        for (final t in tracks) {
          if (t.id == trackId) {
            track = t;
            break;
          }
        }
        if (track == null) {
          // Não fabricar fallback silencioso: a faixa pedida não existe.
          appLogger.w(
            '[Player] Faixa de legenda "$trackId" não encontrada '
            '(${tracks.length} faixas disponíveis).',
          );
          return const Failure(
            StreamUnavailableFailure(
              message: 'Faixa de legenda não encontrada.',
            ),
          );
        }
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
  Future<Result<void>> addExternalSubtitle(
    String uri, {
    String? title,
    String? language,
  }) async {
    try {
      final track = SubtitleTrack.uri(
        uri,
        title: title ?? 'Português (SRT)',
        language: language ?? 'pt-BR',
      );
      await _player?.setSubtitleTrack(track);
      return const Success(null);
    } catch (e) {
      return const Failure(
        StreamUnavailableFailure(message: 'Erro ao carregar legenda externa.'),
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
  Stream<void> get completed => _completedController.stream;

  @override
  Widget? buildVideoSurface() {
    final controller = _videoController;
    if (controller == null) return null;
    return Video(controller: controller);
  }

  @override
  VideoPlayerService createIndependentPlayer() {
    return MediaKitPlayerService();
  }

  @override
  Future<void> dispose() async {
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();
    await _player?.dispose();
    _player = null;
    _videoController = null;
    await _playbackStateController.close();
    await _bufferStateController.close();
    await _errorController.close();
    await _audioTracksController.close();
    await _subtitleTracksController.close();
    await _completedController.close();
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
        } else if (_currentState.status == PlaybackStatus.buffering) {
          final isPlaying = player.state.playing;
          _updateState(
            _currentState.copyWith(
              status:
                  isPlaying ? PlaybackStatus.playing : PlaybackStatus.paused,
            ),
          );
        }
      }),
    );

    _subscriptions.add(
      player.stream.position.listen((position) {
        if (_currentState.status == PlaybackStatus.buffering &&
            position > Duration.zero) {
          _updateState(
            _currentState.copyWith(
              position: position,
              status: player.state.playing
                  ? PlaybackStatus.playing
                  : PlaybackStatus.paused,
            ),
          );
        } else {
          _updateState(_currentState.copyWith(position: position));
        }
      }),
    );

    _subscriptions.add(
      player.stream.duration.listen((duration) {
        _updateState(_currentState.copyWith(duration: duration));
      }),
    );

    _subscriptions.add(
      player.stream.completed.listen((completed) {
        if (completed) {
          _completedController.add(null);
        }
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
