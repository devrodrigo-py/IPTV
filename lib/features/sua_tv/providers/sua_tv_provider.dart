import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/domain/services/sua_tv_service.dart';
import 'package:nebula_iptv/features/channels/providers/channels_provider.dart';
import 'package:nebula_iptv/features/profiles/providers/profile_provider.dart';

/// Provider for the Sua TV queue.
final suaTvQueueProvider =
    FutureProvider.autoDispose<List<SuaTvItem>>((ref) async {
  final db = ref.read(databaseProvider);
  final profileId = ref.read(activeProfileProvider);
  final service = SuaTvService(db, profileId);
  return service.generateQueue();
});

/// Current index in the Sua TV queue.
final suaTvCurrentIndexProvider = StateProvider.autoDispose<int>((ref) => 0);

/// Current item being played in Sua TV.
final suaTvCurrentItemProvider = Provider.autoDispose<SuaTvItem?>((ref) {
  final queue = ref.watch(suaTvQueueProvider).valueOrNull;
  final index = ref.watch(suaTvCurrentIndexProvider);
  if (queue == null || index >= queue.length) return null;
  return queue[index];
});

/// Next item in the queue (for "A seguir" display).
final suaTvNextItemProvider = Provider.autoDispose<SuaTvItem?>((ref) {
  final queue = ref.watch(suaTvQueueProvider).valueOrNull;
  final index = ref.watch(suaTvCurrentIndexProvider);
  if (queue == null || index + 1 >= queue.length) return null;
  return queue[index + 1];
});
