import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

/// Represents one slot in the multiview grid.
class MultiviewSlot {
  final int channelId;
  final String name;
  final String streamUrl;
  final Player player;
  final VideoController videoController;
  final bool isAudioActive;

  MultiviewSlot({
    required this.channelId,
    required this.name,
    required this.streamUrl,
    required this.player,
    required this.videoController,
    this.isAudioActive = false,
  });

  MultiviewSlot copyWith({bool? isAudioActive}) {
    return MultiviewSlot(
      channelId: channelId,
      name: name,
      streamUrl: streamUrl,
      player: player,
      videoController: videoController,
      isAudioActive: isAudioActive ?? this.isAudioActive,
    );
  }
}

/// State for the multiview feature.
class MultiviewState {
  final List<MultiviewSlot> slots;
  final bool isLoading;

  const MultiviewState({
    this.slots = const [],
    this.isLoading = false,
  });

  MultiviewState copyWith({
    List<MultiviewSlot>? slots,
    bool? isLoading,
  }) {
    return MultiviewState(
      slots: slots ?? this.slots,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Provider for multiview state.
final multiviewProvider =
    StateNotifierProvider.autoDispose<MultiviewNotifier, MultiviewState>(
  (ref) => MultiviewNotifier(),
);

/// Manages multiple simultaneous video streams.
class MultiviewNotifier extends StateNotifier<MultiviewState> {
  MultiviewNotifier() : super(const MultiviewState());

  /// Add a channel to multiview. Max 4 slots.
  Future<void> addChannel({
    required int channelId,
    required String name,
    required String streamUrl,
  }) async {
    if (state.slots.length >= 4) return;

    final player = Player();
    final controller = VideoController(player);

    // Convert live .ts URLs to .m3u8 for HLS
    var playUrl = streamUrl;
    if (streamUrl.contains('/live/') && streamUrl.endsWith('.ts')) {
      playUrl = '${streamUrl.substring(0, streamUrl.length - 3)}.m3u8';
    }

    // First slot gets audio, others are muted
    final isFirst = state.slots.isEmpty;
    if (!isFirst) {
      await player.setVolume(0);
    }

    final slot = MultiviewSlot(
      channelId: channelId,
      name: name,
      streamUrl: streamUrl,
      player: player,
      videoController: controller,
      isAudioActive: isFirst,
    );

    state = state.copyWith(slots: [...state.slots, slot]);

    // Start playback
    await player.open(Media(playUrl));
  }

  /// Remove a channel from multiview by index.
  Future<void> removeChannel(int index) async {
    if (index < 0 || index >= state.slots.length) return;

    final slot = state.slots[index];
    await slot.player.stop();
    await slot.player.dispose();

    final newSlots = List<MultiviewSlot>.from(state.slots)..removeAt(index);

    // If we removed the audio-active slot, activate the first remaining
    if (slot.isAudioActive && newSlots.isNotEmpty) {
      newSlots[0] = newSlots[0].copyWith(isAudioActive: true);
      await newSlots[0].player.setVolume(100);
    }

    state = state.copyWith(slots: newSlots);
  }

  /// Switch audio to a specific slot (mute all others).
  Future<void> setActiveAudio(int index) async {
    if (index < 0 || index >= state.slots.length) return;

    final newSlots = <MultiviewSlot>[];
    for (int i = 0; i < state.slots.length; i++) {
      final slot = state.slots[i];
      final isActive = i == index;
      newSlots.add(slot.copyWith(isAudioActive: isActive));
      await slot.player.setVolume(isActive ? 100 : 0);
    }

    state = state.copyWith(slots: newSlots);
  }

  /// Dispose all players when leaving multiview.
  Future<void> disposeAll() async {
    for (final slot in state.slots) {
      await slot.player.stop();
      await slot.player.dispose();
    }
    state = const MultiviewState();
  }

  @override
  void dispose() {
    for (final slot in state.slots) {
      slot.player.stop();
      slot.player.dispose();
    }
    super.dispose();
  }
}
