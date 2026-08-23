import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:nebula_iptv/core/theme/app_colors.dart';
import 'package:nebula_iptv/core/theme/app_typography.dart';
import 'package:nebula_iptv/features/multiview/providers/multiview_provider.dart';

/// Full-screen multiview displaying 2-4 channels simultaneously.
class MultiviewScreen extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> channels;

  const MultiviewScreen({
    super.key,
    required this.channels,
  });

  @override
  ConsumerState<MultiviewScreen> createState() => _MultiviewScreenState();
}

class _MultiviewScreenState extends ConsumerState<MultiviewScreen> {
  @override
  void initState() {
    super.initState();
    _initializeChannels();
  }

  Future<void> _initializeChannels() async {
    final notifier = ref.read(multiviewProvider.notifier);
    for (final ch in widget.channels) {
      await notifier.addChannel(
        channelId: ch['id'] as int,
        name: ch['name'] as String,
        streamUrl: ch['stream_url'] as String,
      );
    }
  }

  Future<void> _goBack() async {
    await ref.read(multiviewProvider.notifier).disposeAll();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(multiviewProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: KeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.escape) {
            _goBack();
          }
        },
        child: Stack(
          children: [
            // Video grid
            _buildGrid(state.slots),

            // Top overlay with back button
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                        ),
                        onPressed: _goBack,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Multiview (${state.slots.length} canais)',
                        style: AppTypography.title.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(List<MultiviewSlot> slots) {
    if (slots.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final count = slots.length;

    if (count == 1) {
      return _buildSlotCell(slots[0], 0);
    }

    if (count == 2) {
      return Row(
        children: [
          Expanded(child: _buildSlotCell(slots[0], 0)),
          const SizedBox(width: 2),
          Expanded(child: _buildSlotCell(slots[1], 1)),
        ],
      );
    }

    if (count == 3) {
      return Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildSlotCell(slots[0], 0)),
                const SizedBox(width: 2),
                Expanded(child: _buildSlotCell(slots[1], 1)),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Expanded(child: _buildSlotCell(slots[2], 2)),
        ],
      );
    }

    // 4 slots — 2x2 grid
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildSlotCell(slots[0], 0)),
              const SizedBox(width: 2),
              Expanded(child: _buildSlotCell(slots[1], 1)),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildSlotCell(slots[2], 2)),
              const SizedBox(width: 2),
              Expanded(child: _buildSlotCell(slots[3], 3)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSlotCell(MultiviewSlot slot, int index) {
    return GestureDetector(
      onTap: () {
        ref.read(multiviewProvider.notifier).setActiveAudio(index);
      },
      child: Container(
        decoration: BoxDecoration(
          border: slot.isAudioActive
              ? Border.all(color: AppColors.primary, width: 3)
              : null,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video
            Video(
              controller: slot.videoController,
            ),

            // Channel name overlay at bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                  ),
                ),
                child: Row(
                  children: [
                    if (slot.isAudioActive)
                      const Padding(
                        padding: EdgeInsets.only(right: 6),
                        child: Icon(
                          Icons.volume_up_rounded,
                          color: AppColors.primary,
                          size: 16,
                        ),
                      ),
                    Expanded(
                      child: Text(
                        slot.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Close button
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                onPressed: () {
                  ref.read(multiviewProvider.notifier).removeChannel(index);
                },
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white70,
                  size: 20,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black45,
                  padding: const EdgeInsets.all(4),
                  minimumSize: const Size(28, 28),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
