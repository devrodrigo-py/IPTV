import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nebula_iptv/core/utils/platform_detector.dart';
import 'package:nebula_iptv/core/widgets/focusable_widget.dart';
import 'package:nebula_iptv/domain/services/video_player_service.dart';

class PlayerControls extends StatefulWidget {
  final VideoPlaybackState playbackState;
  final bool isLive, hasPreviousEpisode, hasNextEpisode;
  final VoidCallback? onPreviousEpisode, onNextEpisode, onReplay10, onForward10;
  final VoidCallback? onOpenSubtitles, onOpenAudio, onHide;
  final ValueChanged<Duration>? onSeek;
  final double playbackSpeed;
  final ValueChanged<double>? onSpeedChanged;
  final VoidCallback onPlayPause, onStop;
  final ValueChanged<double> onVolumeChanged;
  final FocusNode? primaryFocusNode;

  const PlayerControls(
      {super.key,
      required this.playbackState,
      this.isLive = false,
      this.hasPreviousEpisode = false,
      this.hasNextEpisode = false,
      this.onPreviousEpisode,
      this.onNextEpisode,
      this.onSeek,
      this.onReplay10,
      this.onForward10,
      this.playbackSpeed = 1,
      this.onSpeedChanged,
      this.onOpenSubtitles,
      this.onOpenAudio,
      required this.onPlayPause,
      required this.onStop,
      required this.onVolumeChanged,
      this.primaryFocusNode,
      this.onHide});

  @override
  State<PlayerControls> createState() => PlayerControlsState();
}

/// Only horizontal input on the timeline edits a preview. OK commits it;
/// Back or leaving the timeline cancels it without changing playback.
class PlayerControlsState extends State<PlayerControls> {
  final _timeline = FocusNode(debugLabel: 'Player timeline');
  final Map<String, FocusNode> _nodes = {};
  FocusNode? _lastButton;
  double? _previewSeconds;
  String _label = 'Reproduzir / pausar';

  bool get isScrubbing => _previewSeconds != null;
  bool get _hasTimeline =>
      !widget.isLive &&
      widget.onSeek != null &&
      widget.playbackState.duration.inMilliseconds > 0;
  double get _max => widget.playbackState.duration.inMilliseconds / 1000;
  double get _position => widget.playbackState.position.inMilliseconds / 1000;

  FocusNode _node(String id) => id == 'play' && widget.primaryFocusNode != null
      ? widget.primaryFocusNode!
      : _nodes.putIfAbsent(id, () => FocusNode(debugLabel: 'Player $id'));

  bool cancelScrub() {
    if (!isScrubbing) return false;
    setState(() => _previewSeconds = null);
    return true;
  }

  @override
  void dispose() {
    _timeline.dispose();
    for (final node in _nodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  String _time(double seconds) {
    final d = Duration(seconds: seconds.round().clamp(0, 10000000));
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '${d.inHours}:$m:$s' : '$m:$s';
  }

  void _commit() {
    final preview = _previewSeconds;
    if (preview == null) return;
    widget.onSeek
        ?.call(Duration(milliseconds: (preview.clamp(0, _max) * 1000).round()));
    setState(() => _previewSeconds = null);
  }

  KeyEventResult _timelineKey(FocusNode node, KeyEvent event) {
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight) {
      if (event is! KeyUpEvent) {
        setState(() => _previewSeconds = ((_previewSeconds ?? _position) +
                (key == LogicalKeyboardKey.arrowRight ? 10 : -10))
            .clamp(0, _max));
      }
      return KeyEventResult.handled;
    }
    if (RemoteKeys.isSelect(key)) {
      if (event is KeyDownEvent) _commit();
      return KeyEventResult.handled;
    }
    if (RemoteKeys.isBack(key) && isScrubbing) {
      if (event is KeyDownEvent) cancelScrub();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _speedMenu() async {
    final speed = await showDialog<double>(
        context: context,
        builder: (context) =>
            SimpleDialog(title: const Text('Velocidade'), children: [
              for (final speed in [.5, .75, 1.0, 1.25, 1.5, 2.0])
                ListTile(
                    autofocus: speed == widget.playbackSpeed,
                    title: Text('${speed}x${speed == 1 ? ' · Normal' : ''}'),
                    trailing: speed == widget.playbackSpeed
                        ? const Icon(Icons.check)
                        : null,
                    onTap: () => Navigator.pop(context, speed)),
            ]));
    if (mounted && speed != null) widget.onSpeedChanged?.call(speed);
  }

  @override
  Widget build(BuildContext context) {
    final playing = widget.playbackState.status == PlaybackStatus.playing;
    final buttons = <_Control>[
      if (widget.hasPreviousEpisode)
        _Control('previous', Icons.skip_previous, 'Episódio anterior',
            widget.onPreviousEpisode),
      if (!widget.isLive)
        _Control(
            'replay', Icons.replay_10, 'Voltar 10 segundos', widget.onReplay10),
      _Control('play', playing ? Icons.pause : Icons.play_arrow,
          playing ? 'Pausar' : 'Reproduzir', widget.onPlayPause),
      if (!widget.isLive)
        _Control('forward', Icons.forward_10, 'Avançar 10 segundos',
            widget.onForward10),
      if (widget.hasNextEpisode)
        _Control(
            'next', Icons.skip_next, 'Próximo episódio', widget.onNextEpisode),
      if (!widget.isLive && widget.onSpeedChanged != null)
        _Control('speed', Icons.speed, 'Velocidade · ${widget.playbackSpeed}x',
            _speedMenu),
      if (widget.onOpenSubtitles != null)
        _Control('subtitles', Icons.closed_caption_outlined, 'Legendas',
            widget.onOpenSubtitles),
      if (widget.onOpenAudio != null)
        _Control(
            'audio', Icons.audiotrack_outlined, 'Áudio', widget.onOpenAudio),
      _Control('stop', Icons.close, 'Fechar reprodução', widget.onStop),
    ].where((button) => button.action != null).toList();

    return Focus(
      canRequestFocus: false,
      onKeyEvent: (node, event) {
        final direction = RemoteKeys.direction(event.logicalKey);
        if (direction == null) return KeyEventResult.ignored;
        if (event is KeyUpEvent) return KeyEventResult.handled;
        if (direction == TraversalDirection.up) {
          if (!_timeline.hasFocus && _hasTimeline) {
            _timeline.requestFocus();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        }
        if (direction == TraversalDirection.down) {
          if (_timeline.hasFocus) {
            (_lastButton ?? _node('play')).requestFocus();
          } else {
            widget.onHide?.call();
          }
          return KeyEventResult.handled;
        }
        final index = buttons.indexWhere((b) => _node(b.id).hasFocus);
        if (index >= 0) {
          final next =
              (index + (direction == TraversalDirection.right ? 1 : -1))
                  .clamp(0, buttons.length - 1);
          _node(buttons[next].id).requestFocus();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black87])),
        child: SafeArea(
            top: false,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (_hasTimeline)
                Focus(
                  focusNode: _timeline,
                  onKeyEvent: _timelineKey,
                  onFocusChange: (focused) => setState(() {
                    if (!focused) _previewSeconds = null;
                  }),
                  child: Semantics(
                    label: 'Linha do tempo',
                    value: _time((_previewSeconds ?? _position).clamp(0, _max)),
                    child: Container(
                      key: const ValueKey('player-timeline'),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: _timeline.hasFocus
                                  ? Colors.white70
                                  : Colors.transparent)),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(children: [
                        Text(
                            _time(
                                (_previewSeconds ?? _position).clamp(0, _max)),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12)),
                        Expanded(
                            child: ExcludeFocus(
                                child: Slider(
                          value: (_previewSeconds ?? _position).clamp(0, _max),
                          min: 0,
                          max: _max,
                          activeColor: Colors.white,
                          inactiveColor: Colors.white24,
                          onChanged: (value) =>
                              setState(() => _previewSeconds = value),
                          onChangeEnd: (_) => _commit(),
                        ))),
                        Text(_time(_max),
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12)),
                      ]),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final button in buttons)
                      Tooltip(
                        message: button.label,
                        child: FocusableWidget(
                          key: ValueKey('player-${button.id}'),
                          focusNode: _node(button.id),
                          decorateFocus: false,
                          onFocusChange: (focused) {
                            if (focused) {
                              setState(() {
                                _lastButton = _node(button.id);
                                _label = button.label;
                              });
                            }
                          },
                          onPressed: button.action,
                          builder: (context, focused) => Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                                color: focused
                                    ? Colors.white
                                    : button.id == 'play'
                                        ? Colors.white12
                                        : Colors.transparent,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                    color: focused
                                        ? Colors.white
                                        : Colors.transparent)),
                            child: Icon(button.icon,
                                size: button.id == 'play' ? 28 : 22,
                                color: focused ? Colors.black : Colors.white),
                          ),
                        ),
                      ),
                    if (!PlatformDetector.isTv(context))
                      SizedBox(
                          width: 100,
                          child: Slider(
                              value: widget.playbackState.volume.clamp(0, 1),
                              onChanged: widget.onVolumeChanged)),
                  ]),
              const SizedBox(height: 8),
              Text(
                  _timeline.hasFocus
                      ? isScrubbing
                          ? 'OK para confirmar · Voltar para cancelar'
                          : '← → Escolher posição · ↓ Controles'
                      : _label,
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ])),
      ),
    );
  }
}

class _Control {
  final String id, label;
  final IconData icon;
  final VoidCallback? action;
  const _Control(this.id, this.icon, this.label, this.action);
}
