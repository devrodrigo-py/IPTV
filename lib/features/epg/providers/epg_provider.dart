import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/data/database/app_database.dart';
import 'package:nebula_iptv/features/channels/providers/channels_provider.dart';

/// Provider that returns the currently airing EPG program for a given channel ID.
final currentProgramProvider =
    FutureProvider.autoDispose.family<EpgProgram?, int>((ref, channelId) async {
  final db = ref.read(databaseProvider);
  return db.epgDao.getCurrentProgram(channelId);
});
