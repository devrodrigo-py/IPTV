import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/features/channels/providers/channels_provider.dart';
import 'package:nebula_iptv/features/profiles/providers/profile_provider.dart';

/// Provider for user shortcuts (pinned channels/movies/series).
final shortcutsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final profileId = ref.watch(activeProfileProvider);
  final db = ref.read(databaseProvider);
  return db.shortcutDao.getShortcuts(profileId);
});

/// Provider to check if a channel is a shortcut.
final isShortcutProvider =
    FutureProvider.autoDispose.family<bool, int>((ref, channelId) async {
  final profileId = ref.watch(activeProfileProvider);
  final db = ref.read(databaseProvider);
  return db.shortcutDao.isShortcut(profileId, channelId);
});
