import 'dart:async';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nebula_iptv/core/errors/app_failure.dart';
import 'package:nebula_iptv/core/network/dio_client.dart';
import 'package:nebula_iptv/core/result/result.dart';
import 'package:nebula_iptv/data/database/app_database.dart';
import 'package:nebula_iptv/data/database/tables/channels_table.dart';
import 'package:nebula_iptv/data/database/tables/playlists_table.dart';
import 'package:nebula_iptv/data/datasources/tmdb/tmdb_datasource.dart';
import 'package:nebula_iptv/domain/services/batch_enrichment_service.dart';

/// Returns the TMDB payload for a request, or a Failure to simulate an error.
typedef _TmdbScript = Future<Result<Map<String, dynamic>>> Function(
  String path,
  Map<String, dynamic> query,
);

/// Fake DioClient that serves scripted TMDB responses — no network.
class _ScriptedDioClient extends Fake implements DioClient {
  _ScriptedDioClient(this.script);

  final _TmdbScript script;

  @override
  Future<Result<Response<T>>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final result = await script(path, queryParameters ?? const {});
    return result.map(
      (data) => Response<T>(
        requestOptions: RequestOptions(path: path),
        data: data as T,
      ),
    );
  }
}

void main() {
  late AppDatabase db;
  final recordedCalls = <String>[];

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    recordedCalls.clear();
  });

  tearDown(() async {
    await db.close();
  });

  /// Builds the service with a scripted TMDB client.
  BatchEnrichmentService buildService(_TmdbScript script) {
    recordedCalls.clear();
    final client = _ScriptedDioClient(script);
    return BatchEnrichmentService(
      db: db,
      tmdbDs: TmdbDataSource(client: client),
      aliasesDao: db.searchAliasesDao,
    );
  }

  _TmdbScript scriptedTv({
    required Map<String, String> ptBrTitles,
    required Map<String, String> enUsTitles,
  }) {
    return (path, query) async {
      final lang = query['language'] as String;
      final q = query['query'] as String;
      recordedCalls.add('/search/tv|$lang|$q');
      final title = lang == 'pt-BR' ? ptBrTitles[q] : enUsTitles[q];
      if (title == null) {
        return const Failure(NetworkFailure(message: 'no script'));
      }
      return Success({
        'results': [
          {'id': 1, 'name': title},
        ],
      });
    };
  }

  Future<int> seedPlaylist() async {
    return db.playlistsDao.insertPlaylist(
      PlaylistsCompanion.insert(name: 'Enrich Test', type: PlaylistType.m3u),
    );
  }

  Future<int> seedChannel(
    int playlistId,
    String name, {
    required ChannelSourceType type,
  }) {
    return db.channelsDao.insertChannel(
      ChannelsCompanion.insert(
        playlistId: playlistId,
        name: name,
        streamUrl: 'http://stream.test/$name',
        sourceType: type,
      ),
    );
  }

  Future<Set<String>> aliasTextsFor(int channelId) async {
    final rows = await db.customSelect(
      'SELECT alias FROM search_aliases WHERE channel_id = ?',
      variables: [Variable.withInt(channelId)],
    ).get();
    return rows.map((r) => r.read<String>('alias')).toSet();
  }

  group('BatchEnrichmentService', () {
    test('enriches a series channel and stores pt-BR + en-US aliases',
        () async {
      final playlistId = await seedPlaylist();
      final channelId = await seedChannel(
        playlistId,
        'Parks Recreation [HD]',
        type: ChannelSourceType.series,
      );

      final service = buildService(
        scriptedTv(
          ptBrTitles: {'Parks Recreation': 'Parks e Recreação'},
          enUsTitles: {'Parks Recreation': 'Parks and Recreation'},
        ),
      );

      await service.runEnrichment();

      expect(service.isRunning, isFalse);
      expect(service.processed, 1);
      expect(service.matched, 1);
      expect(service.total, 1);
      expect(service.progress, 1.0);

      // Name was cleaned before searching TMDB.
      expect(recordedCalls, contains('/search/tv|pt-BR|Parks Recreation'));
      expect(recordedCalls, contains('/search/tv|en-US|Parks Recreation'));

      expect(await db.searchAliasesDao.getEnrichedChannelIds(), {channelId});
      expect(
        await aliasTextsFor(channelId),
        {'Parks e Recreação', 'Parks and Recreation', 'Parks Recreation [HD]'},
      );
    });

    test('skips channels that already have aliases', () async {
      final playlistId = await seedPlaylist();
      final channelId = await seedChannel(
        playlistId,
        'Enriched Show',
        type: ChannelSourceType.series,
      );
      await db.searchAliasesDao.insertAlias(
        channelId: channelId,
        alias: 'existing',
        normalizedAlias: 'existing',
      );

      final service = buildService(
        scriptedTv(
          ptBrTitles: const {},
          enUsTitles: const {},
        ),
      );

      await service.runEnrichment();

      // Counted as processed but never sent to TMDB.
      expect(service.processed, 1);
      expect(recordedCalls, isEmpty);
      expect(await aliasTextsFor(channelId), {'existing'});
      expect(service.matched, 0);
    });

    test('a failing TMDB search does not abort the batch', () async {
      final playlistId = await seedPlaylist();
      final brokenId = await seedChannel(
        playlistId,
        'Broken Show',
        type: ChannelSourceType.series,
      );
      final goodId = await seedChannel(
        playlistId,
        'Good Show',
        type: ChannelSourceType.series,
      );

      final service = buildService((path, query) async {
        final lang = query['language'] as String;
        final q = query['query'] as String;
        recordedCalls.add('/search/tv|$lang|$q');
        if (q == 'Broken Show') {
          return const Failure(NetworkFailure(message: 'timeout'));
        }
        return const Success({
          'results': [
            {'id': 2, 'name': 'Good Show'},
          ],
        });
      });

      await service.runEnrichment();

      expect(service.isRunning, isFalse);
      expect(service.processed, 2);
      expect(service.matched, 1);

      expect(await aliasTextsFor(brokenId), isEmpty);
      expect(await aliasTextsFor(goodId), isNotEmpty);
      expect(await db.searchAliasesDao.getEnrichedChannelIds(), {goodId});
    });

    test('rejects results sharing no significant word with the channel',
        () async {
      final playlistId = await seedPlaylist();
      final channelId = await seedChannel(
        playlistId,
        'Zebra Planet',
        type: ChannelSourceType.vod,
      );

      final service = buildService((path, query) async {
        final lang = query['language'] as String;
        final q = query['query'] as String;
        recordedCalls.add('/search/movie|$lang|$q');
        return const Success({
          'results': [
            {'id': 5, 'title': 'Matrix Reloaded'},
          ],
        });
      });

      await service.runEnrichment();

      expect(service.matched, 0);
      expect(await aliasTextsFor(channelId), isEmpty);
      // No en-US follow-up after an unreasonable match.
      expect(recordedCalls, hasLength(1));
    });

    test('handles empty TMDB results without failing', () async {
      final playlistId = await seedPlaylist();
      await seedChannel(
        playlistId,
        'Unknown Movie [1080p]',
        type: ChannelSourceType.vod,
      );

      final service = buildService((path, query) async {
        recordedCalls.add('/search/movie|${query['language']}');
        return const Success({'results': []});
      });

      await service.runEnrichment();

      expect(service.processed, 1);
      expect(service.matched, 0);
      expect(service.isRunning, isFalse);
    });

    test('processes all pages when batchSize is smaller than the input',
        () async {
      final playlistId = await seedPlaylist();
      await seedChannel(
        playlistId,
        'VOD Movie One [1080p]',
        type: ChannelSourceType.vod,
      );
      await seedChannel(
        playlistId,
        'VOD Movie Two',
        type: ChannelSourceType.vod,
      );
      await seedChannel(
        playlistId,
        'VOD Movie Three',
        type: ChannelSourceType.vod,
      );

      final service = buildService((path, query) async {
        recordedCalls.add('/search/movie|${query['language']}');
        return const Success({'results': []});
      });

      await service.runEnrichment(batchSize: 1);

      // Three channels with batchSize 1 → 3 paged queries, all processed.
      expect(service.total, 3);
      expect(service.processed, 3);
      expect(recordedCalls, hasLength(3));
    });

    test('ignores a re-entrant run while already running', () async {
      final playlistId = await seedPlaylist();
      await seedChannel(
        playlistId,
        'Gated Show',
        type: ChannelSourceType.series,
      );

      final gate = Completer<void>();
      var tvCalls = 0;
      final service = buildService((path, query) async {
        if (path.endsWith('/search/tv') && query['language'] == 'pt-BR') {
          tvCalls++;
          if (tvCalls == 1) await gate.future;
        }
        return const Success({
          'results': [
            {'id': 9, 'name': 'Gated Show'},
          ],
        });
      });

      final firstRun = service.runEnrichment();
      expect(service.isRunning, isTrue);

      // Second call while the first is blocked must be a no-op.
      await service.runEnrichment();

      gate.complete();
      await firstRun;

      expect(service.isRunning, isFalse);
      expect(service.processed, 1);
      expect(service.matched, 1);
    });

    test('stop() halts processing between items', () async {
      final playlistId = await seedPlaylist();
      final firstId = await seedChannel(
        playlistId,
        'First Show',
        type: ChannelSourceType.series,
      );
      final secondId = await seedChannel(
        playlistId,
        'Second Show',
        type: ChannelSourceType.series,
      );

      // Stop is requested while the first item is being enriched.
      late BatchEnrichmentService service;
      var ptBrCalls = 0;
      final client = _ScriptedDioClient((path, query) async {
        if (query['language'] == 'pt-BR') {
          ptBrCalls++;
          if (ptBrCalls == 1) service.stop();
        }
        return Success({
          'results': [
            {'id': 3, 'name': query['query'] as String},
          ],
        });
      });
      service = BatchEnrichmentService(
        db: db,
        tmdbDs: TmdbDataSource(client: client),
        aliasesDao: db.searchAliasesDao,
      );

      await service.runEnrichment();

      expect(service.processed, 1);
      expect(service.matched, 1);
      expect(await db.searchAliasesDao.getEnrichedChannelIds(), {firstId});
      expect(await aliasTextsFor(secondId), isEmpty);
    });
  });
}
