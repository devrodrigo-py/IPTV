import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/core/network/dio_client.dart';
import 'package:nebula_iptv/data/database/daos/app_settings_dao.dart';
import 'package:nebula_iptv/data/datasources/epg/epg_datasource.dart';
import 'package:nebula_iptv/data/repositories/epg_repository.dart';
import 'package:nebula_iptv/domain/services/epg_sync_scheduler.dart';
import 'package:nebula_iptv/features/channels/providers/channels_provider.dart'
    show databaseProvider;

/// Provider for the EPG repository (shared by import flows and the
/// periodic scheduler).
final epgRepositoryProvider = Provider<EpgRepository>((ref) {
  final db = ref.read(databaseProvider);
  return EpgRepository(
    db: db,
    epgDataSource: EpgDataSource(client: DioClient()),
  );
});

/// EPG auto-sync interval in hours (spec §18 — default 6h, configurable).
///
/// Seeded from the persisted setting at bootstrap; changes are persisted
/// by the settings screen and applied via [epgSyncSchedulerProvider].
final epgSyncIntervalHoursProvider = StateProvider<int>(
  (ref) => kDefaultEpgSyncIntervalHours,
);

/// Periodic EPG sync (spec §18).
final epgSyncSchedulerProvider = Provider<EpgSyncScheduler>((ref) {
  final db = ref.read(databaseProvider);
  return EpgSyncScheduler(
    db: db,
    epgRepository: ref.read(epgRepositoryProvider),
    intervalProvider: () =>
        Duration(hours: ref.read(epgSyncIntervalHoursProvider)),
  );
});
