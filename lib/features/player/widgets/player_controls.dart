import 'package:flutter/material.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';
import 'package:nebula_iptv/domain/services/video_player_service.dart';

/// Comprehensive bottom controls overlay for the player.
///
/// Includes:
/// - Seekbar (timeline slider) with current position and total duration for VOD/Series
/// - Replay 10s and Forward 10s buttons
/// - Previous Episode and Next Episode buttons for series
/// - Playback speed selector (0.5x, 0.75x, 1.0x, 1.25x, 1.5x, 2.0x)
/// - Volume slider
class PlayerControls extends StatefulWidget {
  final VideoPlaybackState playbackState;
  final bool isLive;
  final bool hasPreviousEpisode;
  final bool hasNextEpisode;
  final VoidCallback? onPreviousEpisode;
  final VoidCallback? onNextEpisode;
  final ValueChanged<Duration>? onSeek;
  final VoidCallback? onReplay10;
  final VoidCallback? onForward10;
  final double playbackSpeed;
  final ValueChanged<double>? onSpeedChanged;
  final VoidCallback? onOpenSubtitles;
  final VoidCallback? onOpenAudio;
  final VoidCallback onPlayPause;
  final VoidCallback onStop;
  final ValueChanged<double> onVolumeChanged;

  const PlayerControls({
    super.key,
    required this.playbackState,
    this.isLive = false,
    this.hasPreviousEpisode = false,
    this.hasNextEpisode = false,
    this.onPreviousEpisode,
    this.onNextEpisode,
    this.onSeek,
    this.onReplay10,
    this.onForward10,
    this.playbackSpeed = 1.0,
    this.onSpeedChanged,
    this.onOpenSubtitles,
    this.onOpenAudio,
    required this.onPlayPause,
    required this.onStop,
    required this.onVolumeChanged,
  });

  @override
  State<PlayerControls> createState() => _PlayerControlsState();
}

class _PlayerControlsState extends State<PlayerControls> {
  double? _dragPositionSeconds;

  String _formatDuration(Duration d) {
    if (d.isNegative) return '00:00';
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final position = widget.playbackState.position;
    final duration = widget.playbackState.duration;
    final hasDuration = !widget.isLive && duration > Duration.zero;

    final currentSeconds = _dragPositionSeconds ??
        position.inSeconds.toDouble().clamp(
            0.0, duration.inSeconds.toDouble().clamp(1.0, double.infinity));
    final maxSeconds =
        duration.inSeconds.toDouble().clamp(1.0, double.infinity);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black87,
            Colors.black54,
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Timeline / Seek Bar (for VOD and Series)
            if (hasDuration) ...[
              Row(
                children: [
                  Text(
                    _formatDuration(Duration(seconds: currentSeconds.round())),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SliderTheme(
                      data: const SliderThemeData(
                        activeTrackColor: AppColors.primary,
                        inactiveTrackColor: Colors.white24,
                        thumbColor: AppColors.primary,
                        thumbShape:
                            RoundSliderThumbShape(enabledThumbRadius: 7),
                        overlayShape:
                            RoundSliderOverlayShape(overlayRadius: 14),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: currentSeconds.clamp(0.0, maxSeconds),
                        min: 0.0,
                        max: maxSeconds,
                        onChanged: (val) {
                          setState(() {
                            _dragPositionSeconds = val;
                          });
                        },
                        onChangeEnd: (val) {
                          setState(() {
                            _dragPositionSeconds = null;
                          });
                          widget.onSeek?.call(Duration(seconds: val.round()));
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDuration(duration),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],

            // 2. Control Buttons Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left: Speed Selector & Volume
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Playback Speed Button (VOD/Series)
                    if (!widget.isLive)
                      PopupMenuButton<double>(
                        initialValue: widget.playbackSpeed,
                        tooltip: 'Velocidade',
                        onSelected: (speed) {
                          widget.onSpeedChanged?.call(speed);
                        },
                        itemBuilder: (context) => [
                          0.5,
                          0.75,
                          1.0,
                          1.25,
                          1.5,
                          2.0,
                        ]
                            .map(
                              (s) => PopupMenuItem(
                                value: s,
                                child:
                                    Text('${s}x${s == 1.0 ? ' (Normal)' : ''}'),
                              ),
                            )
                            .toList(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.speed_rounded,
                                  color: Colors.white, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.playbackSpeed}x',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(width: 16),

                    // Volume
                    const Icon(Icons.volume_up_rounded,
                        color: Colors.white70, size: 20),
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 90,
                      child: SliderTheme(
                        data: const SliderThemeData(
                          activeTrackColor: AppColors.primary,
                          inactiveTrackColor: Colors.white24,
                          thumbColor: AppColors.primary,
                          thumbShape:
                              RoundSliderThumbShape(enabledThumbRadius: 5),
                          trackHeight: 3,
                        ),
                        child: Slider(
                          value: widget.playbackState.volume,
                          onChanged: widget.onVolumeChanged,
                        ),
                      ),
                    ),
                  ],
                ),

                // Center: Main Playback Controls
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Previous Episode (for Series)
                    if (widget.hasPreviousEpisode)
                      IconButton(
                        icon: const Icon(Icons.skip_previous_rounded,
                            color: Colors.white),
                        iconSize: 32,
                        tooltip: 'Episódio Anterior',
                        onPressed: widget.onPreviousEpisode,
                      ),

                    // Replay 10s (VOD/Series)
                    if (!widget.isLive)
                      IconButton(
                        icon: const Icon(Icons.replay_10_rounded,
                            color: Colors.white),
                        iconSize: 32,
                        tooltip: 'Voltar 10s',
                        onPressed: widget.onReplay10,
                      ),

                    const SizedBox(width: 8),

                    // Play/Pause Button (Highlighted)
                    Material(
                      color: AppColors.primary,
                      shape: const CircleBorder(),
                      elevation: 4,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: widget.onPlayPause,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            widget.playbackState.status ==
                                    PlaybackStatus.playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Forward 10s (VOD/Series)
                    if (!widget.isLive)
                      IconButton(
                        icon: const Icon(Icons.forward_10_rounded,
                            color: Colors.white),
                        iconSize: 32,
                        tooltip: 'Avançar 10s',
                        onPressed: widget.onForward10,
                      ),

                    // Next Episode (for Series)
                    if (widget.hasNextEpisode)
                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded,
                            color: Colors.white),
                        iconSize: 32,
                        tooltip: 'Próximo Episódio',
                        onPressed: widget.onNextEpisode,
                      ),
                  ],
                ),

                // Right: CC, Audio, Stop Buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Subtitles / CC
                    if (widget.onOpenSubtitles != null)
                      IconButton(
                        icon: const Icon(Icons.closed_caption_rounded,
                            color: Colors.white),
                        iconSize: 26,
                        tooltip: 'Legendas (CC)',
                        onPressed: widget.onOpenSubtitles,
                      ),

                    // Audio Tracks
                    if (widget.onOpenAudio != null)
                      IconButton(
                        icon: const Icon(Icons.audiotrack_rounded,
                            color: Colors.white),
                        iconSize: 24,
                        tooltip: 'Áudio (Dublado / Original)',
                        onPressed: widget.onOpenAudio,
                      ),

                    // Stop
                    IconButton(
                      icon:
                          const Icon(Icons.stop_rounded, color: Colors.white70),
                      iconSize: 28,
                      tooltip: 'Parar e Voltar',
                      onPressed: widget.onStop,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
