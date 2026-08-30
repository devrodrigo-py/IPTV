import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nebula_iptv/core/utils/string_similarity.dart';
import 'package:nebula_iptv/data/database/app_database.dart';
import 'package:nebula_iptv/domain/services/content_matching_service.dart';

void main() {
  late AppDatabase db;
  late ContentMatchingService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    service = ContentMatchingService(db.mediaWorkDao);
  });

  tearDown(() async {
    await db.close();
  });

  /// Inserts a media work with optional aliases, returns its ID.
  Future<int> seedWork(
    String canonicalTitle, {
    String type = 'movie',
    String? normalizedTitle,
    List<String> aliases = const [],
  }) async {
    final id = await db.mediaWorkDao.insertMediaWork(
      type: type,
      canonicalTitle: canonicalTitle,
      normalizedTitle: normalizedTitle,
    );
    for (final alias in aliases) {
      await db.mediaWorkDao.insertAlias(
        mediaWorkId: id,
        aliasText: alias,
        normalizedText: alias,
      );
    }
    return id;
  }

  group('ContentMatchingService.normalize', () {
    test('lowercases and preserves plain names', () {
      expect(service.normalize('Matrix'), 'matrix');
      expect(service.normalize('THE OFFICE'), 'the office');
    });

    test('removes accents and diacritics', () {
      expect(service.normalize('Ação Entre Amigos'), 'acao entre amigos');
      expect(service.normalize('Coração de Aço'), 'coracao de aco');
      expect(service.normalize('Niño Muerto'), 'nino muerto');
      expect(service.normalize('Straße'), 'strasse');
    });

    test('removes bracketed language and quality tags', () {
      expect(service.normalize('[DUB] Matrix'), 'matrix');
      expect(service.normalize('(Dublado) Titanic'), 'titanic');
      expect(service.normalize('Frozen [LEG]'), 'frozen');
      expect(service.normalize('Show Nacional'), 'show');
      expect(
        service.normalize('[FHD] Matrix (4K) 1080p'),
        'matrix',
      );
    });

    test('removes codec and quality tokens without brackets', () {
      expect(service.normalize('Stream H.265'), 'stream');
      expect(service.normalize('Movie HEVC'), 'movie');
      expect(service.normalize('Série HD'), 'serie');
    });

    test('removes season/episode markers', () {
      expect(service.normalize('Dark S01E02'), 'dark');
      expect(service.normalize('Lost T3E12'), 'lost');
      expect(service.normalize('Friends 2x05'), 'friends');
    });

    test('removes year in parentheses', () {
      expect(service.normalize('Matrix (2019)'), 'matrix');
    });

    test('converts separators to spaces', () {
      expect(
        service.normalize('The_Matrix.1999.1080p.BluRay'),
        'the matrix 1999 bluray',
      );
      expect(service.normalize('Break|Bad'), 'break bad');
      expect(service.normalize('Ben-Hur'), 'benhur');
    });

    test('strips trailing TV suffix but preserves leading TV', () {
      expect(service.normalize('Globo TV'), 'globo');
      expect(service.normalize('TV Globo'), 'tv globo');
      expect(service.normalize('MTV'), 'mtv');
    });

    test('keeps trailing numbers — they are part of real titles', () {
      // Regressão: o normalizer antigo tratava números finais como numeração
      // de canal e colapsava "The 100" em "the", fazendo o TMDB enriquecer
      // a série com temporadas de outro show (The Simpsons).
      expect(service.normalize('The 100'), 'the 100');
      expect(service.normalize('Room 104'), 'room 104');
      expect(service.normalize('ESPN 100'), 'espn 100');
      expect(service.normalize('HBO 2'), 'hbo 2');
    });

    test('removes punctuation and collapses whitespace', () {
      expect(
        service.normalize('  Peak!!  Blinders?  '),
        'peak blinders',
      );
      expect(
        service.normalize('Jurassic_Park: The Lost World... (HD)'),
        'jurassic park the lost world',
      );
    });

    test('returns empty string for tag-only names', () {
      expect(service.normalize('[FHD] (DUB)'), '');
      expect(service.normalize('   '), '');
    });
  });

  group('MatchThresholds', () {
    test('autoMerge is above pendingReview', () {
      expect(MatchThresholds.autoMerge, 0.85);
      expect(MatchThresholds.pendingReview, 0.60);
      expect(MatchThresholds.autoMerge,
          greaterThan(MatchThresholds.pendingReview));
    });
  });

  group('StringSimilarity (engine used by matching)', () {
    test('identical strings score 1.0', () {
      expect(StringSimilarity.jaroWinkler('matrix', 'matrix'), 1.0);
    });

    test('disjoint strings score 0.0', () {
      expect(StringSimilarity.jaroWinkler('aaaa', 'zzzz'), 0.0);
      expect(StringSimilarity.jaroWinkler('', 'abc'), 0.0);
    });

    test('close strings stay above autoMerge threshold', () {
      final score = StringSimilarity.jaroWinkler('matrix', 'matriz');
      expect(score, greaterThanOrEqualTo(MatchThresholds.autoMerge));
    });

    test('moderately different strings fall in pending range', () {
      final score = StringSimilarity.jaroWinkler('matrix', 'kamtra');
      expect(
          score,
          inExclusiveRange(
              MatchThresholds.pendingReview, MatchThresholds.autoMerge));
    });
  });

  group('ContentMatchingService.matchContent', () {
    test('returns noMatch with empty input for empty database', () async {
      final result = await service.matchContent('Matrix');

      expect(result.type, MatchType.noMatch);
      expect(result.confidence, 0.0);
      expect(result.mediaWork, isNull);
      expect(result.normalizedInput, 'matrix');
    });

    test('matches exact alias with confidence 1.0', () async {
      final workId = await seedWork(
        'Parks and Recreation',
        type: 'series',
        normalizedTitle: 'parks and recreation',
        aliases: ['parks e recreacao'],
      );

      final result = await service.matchContent(
        'Parks e Recreação',
        type: 'series',
      );

      expect(result.type, MatchType.exact);
      expect(result.confidence, 1.0);
      expect(result.mediaWork!.id, workId);
      expect(result.mediaWork!.canonicalTitle, 'Parks and Recreation');
      expect(result.normalizedInput, 'parks e recreacao');
    });

    test('fuzzy-matches identical normalized title', () async {
      await seedWork('Matrix', normalizedTitle: 'matrix');

      final result = await service.matchContent('MATRIX [FHD]');

      expect(result.type, MatchType.fuzzy);
      expect(result.confidence, 1.0);
      expect(result.mediaWork!.canonicalTitle, 'Matrix');
    });

    test('fuzzy-matches typos above autoMerge threshold', () async {
      await seedWork('Matrix', normalizedTitle: 'matrix');

      final result = await service.matchContent('matriz');

      expect(result.type, MatchType.fuzzy);
      expect(result.confidence, closeTo(0.933, 0.001));
      expect(result.mediaWork, isNotNull);
    });

    test('scores between thresholds go to pending review', () async {
      await seedWork('Matrix', normalizedTitle: 'matrix');

      final result = await service.matchContent('kamtra');

      expect(result.type, MatchType.pending);
      expect(
        result.confidence,
        inInclusiveRange(
            MatchThresholds.pendingReview, MatchThresholds.autoMerge),
      );
      expect(result.mediaWork, isNotNull);
    });

    test('scores below pendingReview are noMatch but keep best candidate',
        () async {
      await seedWork('Matrix', normalizedTitle: 'matrix');

      final result = await service.matchContent('zebra');

      expect(result.type, MatchType.noMatch);
      expect(result.confidence, lessThan(MatchThresholds.pendingReview));
      expect(result.mediaWork, isNotNull);
    });

    test('does not match works of a different type', () async {
      await seedWork('Matrix', type: 'movie', normalizedTitle: 'matrix');

      final result = await service.matchContent('Matrix', type: 'series');

      expect(result.type, MatchType.noMatch);
      expect(result.confidence, 0.0);
    });

    test('matching via alias beats title similarity', () async {
      // Alias points to a work whose title is very different.
      final workId = await seedWork(
        'Um Amigo de Verdade',
        type: 'movie',
        normalizedTitle: 'um amigo de verdade',
        aliases: ['the upside'],
      );

      final result = await service.matchContent('The Upside');

      expect(result.type, MatchType.exact);
      expect(result.mediaWork!.id, workId);
    });

    test('returns noMatch for input that normalizes to empty', () async {
      await seedWork('Matrix', normalizedTitle: 'matrix');

      final result = await service.matchContent('[FHD] (DUB)');

      expect(result.type, MatchType.noMatch);
      expect(result.normalizedInput, '');
      expect(result.mediaWork, isNull);
    });
  });

  group('ContentMatchingService.batchMatch', () {
    test('returns empty map for empty input', () async {
      expect(await service.batchMatch([]), isEmpty);
    });

    test('classifies each name and keys results by original input', () async {
      final workId = await seedWork(
        'Parks and Recreation',
        type: 'series',
        normalizedTitle: 'parks and recreation',
        aliases: ['parks e recreacao'],
      );
      await seedWork('Matrix', type: 'series', normalizedTitle: 'matrix');

      final results = await service.batchMatch(
        ['Parks e Recreação', 'MATRIZ', 'zebra', '[FHD] (DUB)'],
        type: 'series',
      );

      expect(results, hasLength(4));

      expect(results['Parks e Recreação']!.type, MatchType.exact);
      expect(results['Parks e Recreação']!.mediaWork!.id, workId);

      expect(results['MATRIZ']!.type, MatchType.fuzzy);
      expect(results['MATRIZ']!.confidence, closeTo(0.933, 0.001));

      expect(results['zebra']!.type, MatchType.noMatch);

      expect(results['[FHD] (DUB)']!.type, MatchType.noMatch);
      expect(results['[FHD] (DUB)']!.normalizedInput, '');
    });

    test('is consistent with matchContent for the same input', () async {
      await seedWork('Matrix', normalizedTitle: 'matrix');

      final single = await service.matchContent('matriz');
      final batch = await service.batchMatch(['matriz']);

      expect(batch['matriz']!.type, single.type);
      expect(batch['matriz']!.confidence, closeTo(single.confidence, 0.0001));
      expect(batch['matriz']!.mediaWork!.id, single.mediaWork!.id);
    });
  });

  group('MatchResult', () {
    test('toString carries type, confidence and normalized input', () {
      const result = MatchResult(
        type: MatchType.fuzzy,
        confidence: 0.9,
        normalizedInput: 'matrix',
      );
      expect(result.toString(), contains('fuzzy'));
      expect(result.toString(), contains('matrix'));
      expect(result.toString(), contains('0.900'));
    });
  });
}
