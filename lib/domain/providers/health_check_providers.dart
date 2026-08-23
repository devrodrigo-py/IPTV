import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/data/database/daos/health_check_dao.dart';
import 'package:nebula_iptv/domain/services/health_check_service.dart';
import 'package:nebula_iptv/features/channels/providers/channels_provider.dart';

/// Provider for the HealthCheckDao.
final healthCheckDaoProvider = Provider<HealthCheckDao>((ref) {
  final db = ref.read(databaseProvider);
  return db.healthCheckDao;
});

/// Provider for the ChannelHealthCheckService.
final healthCheckServiceProvider = Provider<ChannelHealthCheckService>((ref) {
  final dao = ref.read(healthCheckDaoProvider);
  return ChannelHealthCheckService(dao: dao);
});

/// Provider for health statistics (reactive).
final healthStatsProvider = FutureProvider<HealthStats>((ref) async {
  final dao = ref.read(healthCheckDaoProvider);
  await dao.ensureTable();
  return dao.getHealthStats();
});
