import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nebula_iptv/data/database/app_database.dart';
import 'package:nebula_iptv/data/database/tables/channels_table.dart';
import 'package:nebula_iptv/data/database/tables/playlists_table.dart';
import 'package:nebula_iptv/domain/services/channel_dedup_service.dart';

void main() {
  group('ChannelDeduplicationService.normalizeChannelName', () {
    test('strips bracketed and parenthesized quality tags', () {
      expect(
        ChannelDeduplicationService.normalizeChannelName('[FHD] HBO Max'),
        'hbo max',
      );
      expect(
        ChannelDeduplicationService.normalizeChannelName('Globo (4K)'),
        'globo',
      );
      expect(
        ChannelDeduplicationService.normalizeChannelName('[UHD] Discovery'),
        'discovery',
      );
      expect(
        ChannelDeduplicationService.normalizeChannelName('[BACKUP] HBO'),
        'hbo',
      );
      expect(
        ChannelDeduplicationService.normalizeChannelName('Nova [H.265]'),
        'nova',
      );
      expect(
        ChannelDeduplicationService.normalizeChannelName('Tech [HEVC]'),
        'tech',
      );
    });

    test('strips trailing quality suffixes', () {
      expect(
          ChannelDeduplicationService.normalizeChannelName('ESPN HD'), 'espn');
      expect(
        ChannelDeduplicationService.normalizeChannelName('ESPN fhd'),
        'espn',
      );
      expect(ChannelDeduplicationService.normalizeChannelName('TNT 4K'), 'tnt');
      expect(ChannelDeduplicationService.normalizeChannelName('FX SD'), 'fx');
    });

    test('is case-insensitive and removes diacritics', () {
      expect(
        ChannelDeduplicationService.normalizeChannelName('CANÇÃO'),
        ChannelDeduplicationService.normalizeChannelName('cancao'),
      );
      expect(
        ChannelDeduplicationService.normalizeChannelName('España HD'),
        'espana',
      );
    });

    test('normalizes separators (underscore, dash, dot)', () {
      expect(
        ChannelDeduplicationService.normalizeChannelName('Discovery_Kids'),
        'discovery kids',
      );
      expect(
        ChannelDeduplicationService.normalizeChannelName('Cartoon-Network'),
        'cartoon network',
      );
      expect(
        ChannelDeduplicationService.normalizeChannelName('Telecine.Pipoca'),
        'telecine pipoca',
      );
      expect(
        ChannelDeduplicationService.normalizeChannelName('Max-_Prime'),
        'max prime',
      );
    });

    test('preserves numbers that are part of the name', () {
      expect(
        ChannelDeduplicationService.normalizeChannelName('HBO Max 3'),
        'hbo max 3',
      );
      expect(
        ChannelDeduplicationService.normalizeChannelName('HBO Max 3'),
        isNot(ChannelDeduplicationService.normalizeChannelName('HBO Max')),
      );
      expect(
        ChannelDeduplicationService.normalizeChannelName('ESPN 2 [HD]'),
        'espn 2',
      );
    });

    test('does not treat differently-cased variants as distinct', () {
      expect(
        ChannelDeduplicationService.normalizeChannelName('ESPN'),
        ChannelDeduplicationService.normalizeChannelName('espn'),
      );
    });

    test('year in parentheses is kept (unlike content normalization)', () {
      expect(
        ChannelDeduplicationService.normalizeChannelName('Movie (2019) [HD]'),
        'movie (2019)',
      );
    });

    test('tag-only names normalize to empty', () {
      expect(ChannelDeduplicationService.normalizeChannelName('[HD]'), '');
    });
  });

  group('ChannelDeduplicationService.extractQualityTag', () {
    test('extracts bracketed tags anywhere in the name', () {
      expect(ChannelDeduplicationService.extractQualityTag('[4K] Canal'), '4K');
      expect(
        ChannelDeduplicationService.extractQualityTag('Canal [FHD]'),
        'FHD',
      );
      expect(ChannelDeduplicationService.extractQualityTag('[SD] Canal'), 'SD');
    });

    test('extracts parenthesized and trailing suffix tags', () {
      expect(ChannelDeduplicationService.extractQualityTag('Canal (HD)'), 'HD');
      expect(ChannelDeduplicationService.extractQualityTag('Canal 4K'), '4K');
      expect(
        ChannelDeduplicationService.extractQualityTag('canal fhd'),
        'FHD',
      );
    });

    test('maps UHD to 4K and BACKUP/ALTERNATIVO to ALTER', () {
      expect(
          ChannelDeduplicationService.extractQualityTag('[UHD] Canal'), '4K');
      expect(ChannelDeduplicationService.extractQualityTag('Canal UHD'), '4K');
      expect(
        ChannelDeduplicationService.extractQualityTag('[BACKUP] Canal'),
        'ALTER',
      );
      expect(
        ChannelDeduplicationService.extractQualityTag('[Alternativo] Canal'),
        'ALTER',
      );
    });

    test('returns null when there is no quality tag', () {
      expect(ChannelDeduplicationService.extractQualityTag('HBO Max'), isNull);
      expect(
        ChannelDeduplicationService.extractQualityTag('Canal FHD 2'),
        isNull,
      ); // suffix must be at end
    });

    test('first bracketed tag wins', () {
      expect(
        ChannelDeduplicationService.extractQualityTag('[FHD] Canal [SD]'),
        'FHD',
      );
    });
  });

  group('ChannelDeduplicationService.qualityPriority', () {
    test('ranks 4K > FHD > HD > SD > ALTER', () {
      const expected = {
        '4K': 100,
        'FHD': 80,
        'HD': 60,
        'SD': 40,
        'ALTER': 20,
      };
      expected.forEach((tag, priority) {
        expect(
          ChannelDeduplicationService.qualityPriority(tag),
          priority,
          reason: '$tag should have priority $priority',
        );
      });

      expect(
        ChannelDeduplicationService.qualityPriority('4K'),
        greaterThan(ChannelDeduplicationService.qualityPriority('FHD')),
      );
      expect(
        ChannelDeduplicationService.qualityPriority('FHD'),
        greaterThan(ChannelDeduplicationService.qualityPriority('HD')),
      );
      expect(
        ChannelDeduplicationService.qualityPriority('HD'),
        greaterThan(ChannelDeduplicationService.qualityPriority('SD')),
      );
      expect(
        ChannelDeduplicationService.qualityPriority('SD'),
        greaterThan(ChannelDeduplicationService.qualityPriority('ALTER')),
      );
    });

    test('unknown and missing tags get middle priority', () {
      expect(ChannelDeduplicationService.qualityPriority(null), 50);
      expect(ChannelDeduplicationService.qualityPriority('WEIRD'), 50);
    });
  });

  group('ChannelDeduplicationService.computeGroups', () {
    test('returns empty list for empty input', () {
      expect(ChannelDeduplicationService.computeGroups([]), isEmpty);
    });

    test('unique channels produce no groups', () {
      final groups = ChannelDeduplicationService.computeGroups([
        const ChannelNameInfo(id: 1, name: 'Globo [FHD]'),
        const ChannelNameInfo(id: 2, name: 'Disney (HD)'),
        const ChannelNameInfo(id: 3, name: 'Cartoon Network'),
      ]);
      expect(groups, isEmpty);
    });

    test('groups quality variants of the same channel together', () {
      final groups = ChannelDeduplicationService.computeGroups([
        const ChannelNameInfo(id: 1, name: 'Globo [FHD]'),
        const ChannelNameInfo(id: 2, name: 'Globo (HD)'),
        const ChannelNameInfo(id: 3, name: 'Globo SD'),
        const ChannelNameInfo(id: 4, name: 'Globo'),
      ]);

      expect(groups, hasLength(1));
      final group = groups.single;
      expect(group.normalizedName, 'globo');
      expect(group.members, hasLength(4));
      expect(group.members.map((m) => m.channelId), [1, 2, 4, 3]);
      expect(
        group.members.map((m) => m.qualityTag),
        ['FHD', 'HD', null, 'SD'],
      );
    });

    test('orders members best quality first (4K beats everything)', () {
      final groups = ChannelDeduplicationService.computeGroups([
        const ChannelNameInfo(id: 1, name: 'Discovery [HD]'),
        const ChannelNameInfo(id: 2, name: 'Discovery [4K]'),
        const ChannelNameInfo(id: 3, name: 'Discovery [SD]'),
      ]);

      expect(groups.single.members.first.channelId, 2);
      expect(groups.single.members.first.qualityTag, '4K');
      expect(groups.single.members.last.qualityTag, 'SD');
    });

    test('displayName comes from best member with tag stripped', () {
      final groups = ChannelDeduplicationService.computeGroups([
        const ChannelNameInfo(id: 1, name: 'ESPN Brasil HD'),
        const ChannelNameInfo(id: 2, name: 'ESPN Brasil [FHD]'),
      ]);

      expect(groups.single.displayName, 'ESPN Brasil');
      expect(groups.single.normalizedName, 'espn brasil');
      expect(groups.single.members.first.channelId, 2);
    });

    test('groups names across case, diacritics and tag styles', () {
      final groups = ChannelDeduplicationService.computeGroups([
        const ChannelNameInfo(id: 1, name: 'Canção [HD]'),
        const ChannelNameInfo(id: 2, name: 'CANCAO (FHD)'),
        const ChannelNameInfo(id: 3, name: 'CANCAO [ALTERNATIVO]'),
      ]);

      expect(groups, hasLength(1));
      expect(groups.single.normalizedName, 'cancao');
      expect(groups.single.members, hasLength(3));
    });

    test('ALTER/BACKUP variants group but rank last', () {
      final groups = ChannelDeduplicationService.computeGroups([
        const ChannelNameInfo(id: 1, name: 'SporTV [BACKUP]'),
        const ChannelNameInfo(id: 2, name: 'SporTV [HD]'),
      ]);

      expect(groups.single.members.first.channelId, 2);
      expect(groups.single.members.last.channelId, 1);
      expect(groups.single.members.last.qualityTag, 'ALTER');
    });

    test('names that normalize to empty never group', () {
      final groups = ChannelDeduplicationService.computeGroups([
        const ChannelNameInfo(id: 1, name: '[HD]'),
        const ChannelNameInfo(id: 2, name: '(4K)'),
      ]);
      expect(groups, isEmpty);
    });

    test('untagged duplicates still form a group with null tags', () {
      final groups = ChannelDeduplicationService.computeGroups([
        const ChannelNameInfo(id: 1, name: 'Telecine Action'),
        const ChannelNameInfo(id: 2, name: 'Telecine_Action'),
      ]);

      expect(groups, hasLength(1));
      expect(groups.single.normalizedName, 'telecine action');
      expect(groups.single.members, hasLength(2));
      expect(
        groups.single.members.every((m) => m.qualityTag == null),
        isTrue,
      );
    });
  });

  group('ChannelDeduplicationService.detectDuplicateChannels', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    Future<int> seedPlaylist() async {
      return db.playlistsDao.insertPlaylist(
        PlaylistsCompanion.insert(name: 'Dedup Test', type: PlaylistType.m3u),
      );
    }

    Future<int> seedChannel(
      int playlistId,
      String name, {
      bool isActive = true,
    }) {
      return db.channelsDao.insertChannel(
        ChannelsCompanion.insert(
          playlistId: playlistId,
          name: name,
          streamUrl: 'http://stream.test/$name',
          sourceType: ChannelSourceType.m3u,
          isActive: Value(isActive),
        ),
      );
    }

    test('creates one group for duplicated names, best quality as primary',
        () async {
      final playlistId = await seedPlaylist();
      final fhd = await seedChannel(playlistId, 'HBO Max [FHD]');
      final hd = await seedChannel(playlistId, 'HBO Max (HD)');
      await seedChannel(playlistId, 'Disney Channel');
      // Inactive variant must be ignored.
      await seedChannel(playlistId, 'HBO Max [SD]', isActive: false);
      await db.channelGroupDao.ensureTables();

      final service = ChannelDeduplicationService(
        db: db,
        groupDao: db.channelGroupDao,
      );
      final result =
          await service.detectDuplicateChannels(playlistId: playlistId);

      expect(result.groupsCreated, 1);
      expect(result.channelsGrouped, 2);
      expect(result.groupsSkipped, 0);

      final groups = await db.channelGroupDao.getAllGroups();
      expect(groups, hasLength(1));
      expect(groups.first.normalizedName, 'hbo max');
      expect(groups.first.displayName, 'HBO Max');
      expect(groups.first.source, 'auto');
      expect(groups.first.primaryChannelId, fhd);

      final members = await db.channelGroupDao.getGroupMembers(groups.first.id);
      expect(members, hasLength(2));
      expect(members.first.channelId, fhd);
      expect(members.first.qualityTag, 'FHD');
      expect(members.first.priority, greaterThan(members.last.priority));
      expect(members.last.channelId, hd);
      expect(members.last.qualityTag, 'HD');
    });

    test('skips channels when a group with the same normalized name exists',
        () async {
      final playlistId = await seedPlaylist();
      final fhd = await seedChannel(playlistId, 'HBO Max [FHD]');
      await seedChannel(playlistId, 'HBO Max (HD)');
      await db.channelGroupDao.ensureTables();

      // Pre-existing (e.g. manual) group for the same normalized name.
      await db.channelGroupDao.createGroup(
        displayName: 'HBO Max',
        normalizedName: 'hbo max',
        primaryChannelId: fhd,
        source: 'manual',
      );

      final service = ChannelDeduplicationService(
        db: db,
        groupDao: db.channelGroupDao,
      );
      final result =
          await service.detectDuplicateChannels(playlistId: playlistId);

      expect(result.groupsCreated, 0);
      expect(result.groupsSkipped, 1);
      expect(result.channelsGrouped, 0);
      expect(await db.channelGroupDao.getGroupCount(), 1);
    });

    test('returns zero counts when there are no channels', () async {
      final playlistId = await seedPlaylist();
      await db.channelGroupDao.ensureTables();

      final service = ChannelDeduplicationService(
        db: db,
        groupDao: db.channelGroupDao,
      );
      final result =
          await service.detectDuplicateChannels(playlistId: playlistId);

      expect(result.groupsCreated, 0);
      expect(result.channelsGrouped, 0);
      expect(result.groupsSkipped, 0);
      expect(await db.channelGroupDao.getGroupCount(), 0);
    });
  });
}
