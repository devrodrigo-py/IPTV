import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nebula_iptv/data/database/app_database.dart';
import 'package:nebula_iptv/data/database/daos/app_settings_dao.dart';

void main() {
  late AppDatabase db;
  late AppSettingsDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = db.appSettingsDao;
  });

  tearDown(() async {
    await db.close();
  });

  group('AppSettingsDao', () {
    test('getString returns null for unset keys', () async {
      expect(await dao.getString('missing'), isNull);
    });

    test('setString/getString round trip and overwrite', () async {
      await dao.setString('theme', 'dark');
      expect(await dao.getString('theme'), 'dark');

      await dao.setString('theme', 'light');
      expect(await dao.getString('theme'), 'light');
    });

    test('getBool honors stored value and default', () async {
      expect(
        await dao.getBool(kSettingHealthCheckEnabled, defaultValue: true),
        isTrue,
      );

      await dao.setBool(kSettingHealthCheckEnabled, value: false);
      expect(
        await dao.getBool(kSettingHealthCheckEnabled, defaultValue: true),
        isFalse,
      );
    });

    test('getInt honors stored value and default', () async {
      expect(
        await dao.getInt(kSettingEpgSyncIntervalHours, defaultValue: 6),
        6,
      );

      await dao.setInt(kSettingEpgSyncIntervalHours, value: 24);
      expect(
        await dao.getInt(kSettingEpgSyncIntervalHours, defaultValue: 6),
        24,
      );
    });

    test('corrupted values fall back to the default', () async {
      await dao.setString(kSettingEpgSyncIntervalHours, 'not-a-number');
      expect(
        await dao.getInt(kSettingEpgSyncIntervalHours, defaultValue: 6),
        6,
      );
    });

    test('keys are independent', () async {
      await dao.setBool(kSettingHealthCheckEnabled, value: false);
      await dao.setInt(kSettingEpgSyncIntervalHours, value: 12);

      expect(
        await dao.getBool(kSettingHealthCheckEnabled, defaultValue: true),
        isFalse,
      );
      expect(
        await dao.getInt(kSettingEpgSyncIntervalHours, defaultValue: 6),
        12,
      );
    });
  });
}
