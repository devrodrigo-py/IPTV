import 'package:nebula_iptv/data/database/app_database.dart';

/// Well-known keys persisted in the app_settings table.
const kSettingHealthCheckEnabled = 'health_check_enabled';
const kSettingEpgSyncIntervalHours = 'epg_sync_interval_hours';
const kSettingEpgLastSyncAtMs = 'epg_last_sync_at_ms';

/// EPG auto-sync default interval (spec §18).
const kDefaultEpgSyncIntervalHours = 6;

/// Key-value access to persisted application settings.
class AppSettingsDao {
  final AppDatabase _db;

  AppSettingsDao(this._db);

  /// Reads a raw value, or null when the key was never set.
  Future<String?> getString(String key) async {
    final rows = await (_db.select(_db.appSettings)
          ..where((t) => t.key.equals(key)))
        .get();
    return rows.isEmpty ? null : rows.first.value;
  }

  Future<void> setString(String key, String value) {
    return _db.into(_db.appSettings).insertOnConflictUpdate(
        AppSettingsCompanion.insert(key: key, value: value));
  }

  Future<bool> getBool(String key, {required bool defaultValue}) async {
    final raw = await getString(key);
    if (raw == null) return defaultValue;
    return raw == 'true';
  }

  Future<void> setBool(String key, {required bool value}) {
    return setString(key, value ? 'true' : 'false');
  }

  Future<int> getInt(String key, {required int defaultValue}) async {
    final raw = await getString(key);
    if (raw == null) return defaultValue;
    return int.tryParse(raw) ?? defaultValue;
  }

  Future<void> setInt(String key, {required int value}) {
    return setString(key, '$value');
  }
}
