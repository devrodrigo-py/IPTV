import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/features/channels/providers/channels_provider.dart';
import 'package:nebula_iptv/features/profiles/providers/profile_provider.dart';

/// Provider that returns the user's rating for a specific channel.
final ratingProvider =
    FutureProvider.autoDispose.family<double?, int>((ref, channelId) async {
  final profileId = ref.watch(activeProfileProvider);
  final db = ref.read(databaseProvider);
  return db.ratingsDao.getRating(profileId, channelId);
});

/// Provider for top-rated items (used on Home screen).
final topRatedProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final profileId = ref.watch(activeProfileProvider);
  final db = ref.read(databaseProvider);
  return db.ratingsDao.getTopRated(profileId, limit: 20);
});

/// Provider for total rating count.
final ratingCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final profileId = ref.watch(activeProfileProvider);
  final db = ref.read(databaseProvider);
  return db.ratingsDao.getRatingCount(profileId);
});
