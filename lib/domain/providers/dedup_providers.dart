import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/data/database/daos/channel_group_dao.dart';
import 'package:nebula_iptv/domain/providers/content_providers.dart';
import 'package:nebula_iptv/domain/services/channel_dedup_service.dart';
import 'package:nebula_iptv/domain/services/content_dedup_service.dart';
import 'package:nebula_iptv/features/channels/providers/channels_provider.dart';

/// Provider for the ChannelGroupDao.
final channelGroupDaoProvider = Provider<ChannelGroupDao>((ref) {
  final db = ref.read(databaseProvider);
  return db.channelGroupDao;
});

/// Provider for the channel deduplication service.
final channelDeduplicationServiceProvider =
    Provider<ChannelDeduplicationService>((ref) {
  final db = ref.read(databaseProvider);
  final groupDao = ref.read(channelGroupDaoProvider);
  return ChannelDeduplicationService(db: db, groupDao: groupDao);
});

/// Provider for the content deduplication service.
final contentDeduplicationServiceProvider =
    Provider<ContentDeduplicationService>((ref) {
  final db = ref.read(databaseProvider);
  final matchingService = ref.read(contentMatchingServiceProvider);
  return ContentDeduplicationService(db: db, matchingService: matchingService);
});
