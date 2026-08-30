import 'dart:async';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nebula_iptv/core/errors/app_failure.dart';
import 'package:nebula_iptv/core/result/result.dart';
import 'package:nebula_iptv/data/database/app_database.dart';
import 'package:nebula_iptv/data/database/daos/app_settings_dao.dart';
import 'package:nebula_iptv/data/database/tables/playlists_table.dart';
import 'package:nebula_iptv/data/datasources/epg/epg_datasource.dart';
import 'package:nebula_iptv/data/datasources/epg/xmltv_parser.dart';
import 'package:nebula_iptv/data/repositories/epg_repository.dart';
import 'package:nebula_iptv/domain/services/epg_sync_scheduler.dart';

const _emptyResult =
    XmltvParseResult(channels: {}, programs: [], errorCount: 0);

/// Fake that records fetches and answers per URL. An optional [gate] holds
/// every fetch open until completed (used to pin a cycle in flight).
class FakeEpgDataSource implements EpgDataSource {
  final Map<String, Result<XmltvParseResult>> responses;
  Completer<void>? gate;
  final List<String> calls = [];

  FakeEpgDataSource(this.responses);

  @override
  Future<Result<XmltvParseResult>> fetchEpg(String url) async {
    calls.add(url);
    if (gate != null) {
      await gate!.future;
    }
    return responses[url] ??
        const Failure(NetworkFailure(message: 'url sem script de teste'));
  }

  @override
  Result<XmltvParseResult> parseContent(String content) {
    return const Success(_emptyResult);
  }
}

AppDatabase _createTestDb() => AppDatabase(NativeDatabase.memory());

Future<int> _insertPlaylist(
  AppDatabase db, {
  required String name,
  String? epgUrl,
}) {
  return db.playlistsDao.insertPlaylist(
    PlaylistsCompanion.insert(
      name: name,
      type: PlaylistType.m3u,
      url: const Value('http://example.com/list.m3u'),
      epgUrl: Value(epgUrl),
    ),
  );
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = _createTestDb();
  });

  tearDown(() async {
    await db.close();
  });

  group('EpgSyncScheduler', () {
    test('syncAll syncs every playlist with an EPG URL and skips the rest',
        () async {
      await _insertPlaylist(db, name: 'a', epgUrl: 'http://epg/a.xml');
      await _insertPlaylist(db, name: 'b');
      await _insertPlaylist(db, name: 'c', epgUrl: 'http://epg/c.xml');

      final dataSource = FakeEpgDataSource({
        'http://epg/a.xml': const Success(_emptyResult),
        'http://epg/c.xml': const Success(_emptyResult),
      });
      final scheduler = EpgSyncScheduler(
        db: db,
        epgRepository: EpgRepository(
          db: db,
          epgDataSource: dataSource,
        ),
        settingsDao: db.appSettingsDao,
        initialDelay: const Duration(milliseconds: 5),
      );

      await scheduler.syncAll();

      expect(dataSource.calls, ['http://epg/a.xml', 'http://epg/c.xml']);
    });

    test('one failing playlist does not abort the remaining ones', () async {
      await _insertPlaylist(db, name: 'a', epgUrl: 'http://epg/a.xml');
      await _insertPlaylist(db, name: 'b', epgUrl: 'http://epg/b.xml');

      final dataSource = FakeEpgDataSource({
        'http://epg/a.xml': const Failure(NetworkFailure(message: 'boom')),
        'http://epg/b.xml': const Success(_emptyResult),
      });
      final scheduler = EpgSyncScheduler(
        db: db,
        epgRepository: EpgRepository(
          db: db,
          epgDataSource: dataSource,
        ),
        settingsDao: db.appSettingsDao,
        initialDelay: const Duration(milliseconds: 5),
      );

      await scheduler.syncAll();

      expect(dataSource.calls, ['http://epg/a.xml', 'http://epg/b.xml']);
    });

    test('start() repeats on the configured interval and stop() halts',
        () async {
      await _insertPlaylist(db, name: 'a', epgUrl: 'http://epg/a.xml');

      final dataSource = FakeEpgDataSource({
        'http://epg/a.xml': const Success(_emptyResult),
      });
      final scheduler = EpgSyncScheduler(
        db: db,
        epgRepository: EpgRepository(
          db: db,
          epgDataSource: dataSource,
        ),
        settingsDao: db.appSettingsDao,
        initialDelay: const Duration(milliseconds: 5),
        intervalProvider: () => const Duration(milliseconds: 30),
      );

      scheduler.start();
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (dataSource.calls.length < 4 && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      scheduler.stop();

      expect(dataSource.calls.length, greaterThanOrEqualTo(4));

      final afterStop = dataSource.calls.length;
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(dataSource.calls.length, afterStop);
    });

    test('a cycle in flight blocks re-entry (no overlapping syncs)', () async {
      await _insertPlaylist(db, name: 'a', epgUrl: 'http://epg/a.xml');

      final gate = Completer<void>();
      final dataSource = FakeEpgDataSource({
        'http://epg/a.xml': const Success(_emptyResult),
      })
        ..gate = gate;
      final scheduler = EpgSyncScheduler(
        db: db,
        epgRepository: EpgRepository(
          db: db,
          epgDataSource: dataSource,
        ),
        settingsDao: db.appSettingsDao,
        initialDelay: const Duration(milliseconds: 5),
        intervalProvider: () => const Duration(milliseconds: 20),
      );

      scheduler.start();

      // The initial cycle is in flight and gated; extra start() calls and
      // the short timer must not stack a second concurrent sync.
      scheduler.start();
      scheduler.start();
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(dataSource.calls, hasLength(1));
      expect(scheduler.isSyncing, isTrue);

      gate.complete();
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (dataSource.calls.length < 2 && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(dataSource.calls.length, greaterThanOrEqualTo(2));
      scheduler.stop();
    });

    test('a recent last-sync defers the cycle until the interval elapses',
        () async {
      await _insertPlaylist(db, name: 'a', epgUrl: 'http://epg/a.xml');
      await db.appSettingsDao.setString(
        kSettingEpgLastSyncAtMs,
        '${DateTime.now().millisecondsSinceEpoch}',
      );

      final dataSource = FakeEpgDataSource({
        'http://epg/a.xml': const Success(_emptyResult),
      });
      final scheduler = EpgSyncScheduler(
        db: db,
        epgRepository: EpgRepository(
          db: db,
          epgDataSource: dataSource,
        ),
        settingsDao: db.appSettingsDao,
        intervalProvider: () => const Duration(hours: 6),
        initialDelay: const Duration(milliseconds: 10),
      );

      // Reabrir o app antes do intervalo não deve re-baixar o guia.
      scheduler.start();
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(dataSource.calls, isEmpty);
      scheduler.stop();

      // Intervalo cumprido → o ciclo roda.
      await db.appSettingsDao.setString(
        kSettingEpgLastSyncAtMs,
        '${DateTime.now().subtract(const Duration(hours: 7)).millisecondsSinceEpoch}',
      );
      scheduler.start();
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (dataSource.calls.isEmpty && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(dataSource.calls, isNotEmpty);
      scheduler.stop();
    });
  });
}
