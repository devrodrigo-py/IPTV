import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nebula_iptv/data/database/app_database.dart';
import 'package:nebula_iptv/domain/services/alias_repair_service.dart';
import 'package:nebula_iptv/domain/services/content_matching_service.dart';

void main() {
  late AppDatabase db;
  late ContentMatchingService matching;
  late AliasRepairService repair;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    matching = ContentMatchingService(db.mediaWorkDao);
    repair = AliasRepairService(db: db, matching: matching);
  });

  tearDown(() async {
    await db.close();
  });

  group('AliasRepairService', () {
    test('removes aliases normalized by the old trailing-number rule',
        () async {
      await db.mediaWorkDao.ensureTables();

      final simpsonsId = await db.mediaWorkDao.insertMediaWork(
        type: 'series',
        canonicalTitle: 'The Simpsons',
        normalizedTitle: 'the simpsons',
      );

      // Poluição do normalizer antigo: "The 100" virava "the", que casava
      // exato com este alias e carregava metadados de outro show.
      await db.mediaWorkDao.insertAlias(
        mediaWorkId: simpsonsId,
        aliasText: 'The 100',
        normalizedText: 'the',
        source: 'auto',
      );
      await db.mediaWorkDao.insertAlias(
        mediaWorkId: simpsonsId,
        aliasText: 'Os Simpsons',
        normalizedText: 'os simpsons',
        source: 'auto',
      );

      final result = await repair.repair();

      expect(result.aliasesRemoved, 1);
      final remaining = await db.mediaWorkDao.getAllAliases(type: 'series');
      expect(remaining, hasLength(1));
      expect(remaining.first.normalizedText, 'os simpsons');
    });

    test('re-normalizes work titles stored by the old rule', () async {
      await db.mediaWorkDao.ensureTables();

      await db.mediaWorkDao.insertMediaWork(
        type: 'series',
        canonicalTitle: 'The 100',
        normalizedTitle: 'the',
      );

      final result = await repair.repair();

      expect(result.titlesRepaired, 1);
      // O matching volta a encontrar a obra pelo novo normalized_title
      // (match fuzzy 1.0 ≥ 0.85) em vez de duplicá-la.
      final match = await matching.matchContent('The 100', type: 'series');
      expect(match.type, MatchType.fuzzy);
      expect(match.mediaWork!.canonicalTitle, 'The 100');
    });

    test('is idempotent — second run changes nothing', () async {
      await db.mediaWorkDao.ensureTables();

      await db.mediaWorkDao.insertMediaWork(
        type: 'series',
        canonicalTitle: 'The 100',
        normalizedTitle: 'the',
      );
      await db.mediaWorkDao.insertAlias(
        mediaWorkId: 1,
        aliasText: 'The 100',
        normalizedText: 'the',
      );

      await repair.repair();
      final second = await repair.repair();

      expect(second.aliasesRemoved, 0);
      expect(second.titlesRepaired, 0);
    });
  });
}
