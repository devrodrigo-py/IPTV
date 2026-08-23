import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/features/channels/providers/channels_provider.dart';

/// Holds the currently active profile ID.
/// Selected at app launch (Netflix-style), resets each session.
final activeProfileProvider = StateProvider<int>((ref) => 1);

/// Lists all profiles from the database.
final profilesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final db = ref.read(databaseProvider);
  return db.profileDao.getAllProfiles();
});

/// Whether to show profile selection on startup.
/// Only shows if there are 2+ profiles.
final shouldShowProfileSelectionProvider = FutureProvider<bool>((ref) async {
  final db = ref.read(databaseProvider);
  final count = await db.profileDao.getProfileCount();
  return count > 1;
});
