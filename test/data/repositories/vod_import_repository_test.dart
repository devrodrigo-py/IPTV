import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nebula_iptv/core/network/dio_client.dart';
import 'package:nebula_iptv/core/result/result.dart';
import 'package:nebula_iptv/data/database/app_database.dart';
import 'package:nebula_iptv/data/database/tables/playlists_table.dart';
import 'package:nebula_iptv/data/datasources/credentials/memory_credential_store.dart';
import 'package:nebula_iptv/data/datasources/xtream/xtream_datasource.dart';
import 'package:nebula_iptv/data/datasources/xtream/xtream_models.dart';
import 'package:nebula_iptv/data/repositories/vod_import_repository.dart';

/// Fake that serves canned VOD payloads — no network involved.
class FakeXtreamDataSource extends XtreamDataSource {
  FakeXtreamDataSource() : super(client: DioClient());

  List<XtreamVodStream> vodStreams = [];
  List<XtreamCategory> categories = [];

  @override
  Future<Result<List<XtreamVodStream>>> getVodStreams({
    required String serverUrl,
    required String username,
    required String password,
    int? portOverride,
    String? categoryId,
    bool allowInsecureCertificates = false,
  }) async {
    return Success(vodStreams);
  }

  @override
  Future<Result<List<XtreamCategory>>> getVodCategories({
    required String serverUrl,
    required String username,
    required String password,
    int? portOverride,
    bool allowInsecureCertificates = false,
  }) async {
    return Success(categories);
  }

  @override
  String buildVodStreamUrl({
    required String serverUrl,
    required String username,
    required String password,
    required int streamId,
    int? portOverride,
    String extension = 'mp4',
  }) {
    return 'http://stream.example.com/$streamId.$extension';
  }
}

XtreamVodStream _stream(int id, String name) => XtreamVodStream(
      streamId: id,
      name: name,
      streamIcon: 'http://img.example.com/$id.png',
      categoryId: '10',
      containerExtension: 'mp4',
    );

void main() {
  late AppDatabase db;
  late FakeXtreamDataSource dataSource;
  late VodImportRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dataSource = FakeXtreamDataSource();
    dataSource.categories = [
      const XtreamCategory(categoryId: '10', categoryName: 'Filmes'),
    ];
    repo = VodImportRepository(
      db: db,
      xtreamDataSource: dataSource,
      credentialStore: MemoryCredentialStore(),
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> insertPlaylist() {
    return db.playlistsDao.insertPlaylist(
      PlaylistsCompanion.insert(
        name: 'Xtream',
        type: PlaylistType.xtream,
        url: const Value('http://server.example.com'),
      ),
    );
  }

  VodImportResult dataOf(Result<VodImportResult> r) => r.when(
        success: (data) => data,
        failure: (f) => throw StateError('esperava sucesso: ${f.message}'),
      );

  group('VodImportRepository (batch reconcile)', () {
    test('first import inserts all movies and mirrors them into channels',
        () async {
      dataSource.vodStreams = [_stream(1, 'Movie A'), _stream(2, 'Movie B')];
      final playlistId = await insertPlaylist();

      final result = await repo.importVod(
        playlistId: playlistId,
        serverUrl: 'http://server.example.com',
        username: 'user',
        password: 'pass',
      );

      final data = dataOf(result);
      expect(data.moviesAdded, 2);

      final vodRows = await db.select(db.vodItems).get();
      expect(vodRows, hasLength(2));
      expect(vodRows.every((r) => r.isActive), isTrue);
      expect(vodRows.every((r) => r.categoryName == 'Filmes'), isTrue);

      final channelRows = await db.select(db.channels).get();
      expect(channelRows, hasLength(2));
    });

    test('second import applies the diff in one pass', () async {
      dataSource.vodStreams = [_stream(1, 'Movie A'), _stream(2, 'Movie B')];
      final playlistId = await insertPlaylist();
      await repo.importVod(
        playlistId: playlistId,
        serverUrl: 'http://server.example.com',
        username: 'user',
        password: 'pass',
      );

      // A changed (update), B vanished (deactivate), C appeared (insert).
      dataSource.vodStreams = [_stream(1, 'Movie A v2'), _stream(3, 'Movie C')];
      final data = dataOf(
        await repo.importVod(
          playlistId: playlistId,
          serverUrl: 'http://server.example.com',
          username: 'user',
          password: 'pass',
        ),
      );

      expect(data.moviesAdded, 1);
      expect(data.moviesUpdated, 1);
      expect(data.moviesDeactivated, 1);

      final bySourceId = {
        for (final row in await db.select(db.vodItems).get()) row.sourceId: row,
      };
      expect(bySourceId, hasLength(3));
      expect(bySourceId['1']!.name, 'Movie A v2');
      expect(bySourceId['1']!.isActive, isTrue);
      expect(bySourceId['2']!.isActive, isFalse);
      expect(bySourceId['3']!.name, 'Movie C');
      expect(bySourceId['3']!.isActive, isTrue);

      // Mirror rows in the channels table follow the same diff.
      final mirrorBySourceId = {
        for (final row in await db.select(db.channels).get())
          row.sourceId!: row,
      };
      expect(mirrorBySourceId, hasLength(3));
      expect(mirrorBySourceId['1']!.name, 'Movie A v2');
      expect(mirrorBySourceId['1']!.isActive, isTrue);
      expect(mirrorBySourceId['2']!.isActive, isFalse);
      expect(mirrorBySourceId['3']!.isActive, isTrue);
    });

    test('unchanged but inactive movies are reactivated', () async {
      dataSource.vodStreams = [_stream(1, 'Movie A'), _stream(2, 'Movie B')];
      final playlistId = await insertPlaylist();
      await repo.importVod(
        playlistId: playlistId,
        serverUrl: 'http://server.example.com',
        username: 'user',
        password: 'pass',
      );

      await (db.update(db.vodItems)..where((v) => v.sourceId.equals('1')))
          .write(const VodItemsCompanion(isActive: Value(false)));

      final data = dataOf(
        await repo.importVod(
          playlistId: playlistId,
          serverUrl: 'http://server.example.com',
          username: 'user',
          password: 'pass',
        ),
      );

      expect(data.moviesAdded, 0);
      expect(data.moviesUpdated, 1);
      expect(data.moviesDeactivated, 0);

      final row = await (db.select(db.vodItems)
            ..where((v) => v.sourceId.equals('1')))
          .getSingle();
      expect(row.isActive, isTrue);
    });
  });
}
