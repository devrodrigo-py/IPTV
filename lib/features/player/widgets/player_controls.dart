import 'package:flutter/material.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';
import 'package:nebula_iptv/domain/services/video_player_service.dart';

/// Bottom controls overlay for the player.
class PlayerControls extends StatelessWidget {
  final VideoPlaybackState playbackState;
  final VoidCallback onPlayPause;
  final VoidCallback onStop;
  final ValueChanged<double> onVolumeChanged;

  const PlayerControls({
    super.key,
    required this.playbackState,
    required this.onPlayPause,
    required this.onStop,
    required this.onVolumeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black54, Colors.transparent],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Stop
            IconButton(
              icon: const Icon(Icons.stop_rounded, color: Colors.white),
              iconSize: 32,
              onPressed: onStop,
            ),
            const SizedBox(width: 16),

            // Play/Pause
            IconButton(
              icon: Icon(
                playbackState.status == PlaybackStatus.playing
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: Colors.white,
              ),
              iconSize: 48,
              onPressed: onPlayPause,
            ),
            const SizedBox(width: 24),

            // Volume
            const Icon(Icons.volume_up_rounded, color: Colors.white70),
            const SizedBox(width: 8),
            SizedBox(
              width: 120,
              child: SliderTheme(
                data: const SliderThemeData(
                  activeTrackColor: AppColors.primary,
                  inactiveTrackColor: Colors.white24,
                  thumbColor: AppColors.primary,
                  thumbShape: RoundSliderThumbShape(
                    enabledThumbRadius: 6,
                  ),
                  trackHeight: 3,
                ),
                child: Slider(
                  value: playbackState.volume,
                  onChanged: onVolumeChanged,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
