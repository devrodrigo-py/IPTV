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
import 'package:nebula_iptv/data/repositories/series_import_repository.dart';

/// Fake that serves canned series payloads — no network involved.
class FakeXtreamDataSource extends XtreamDataSource {
  FakeXtreamDataSource() : super(client: DioClient());

  List<XtreamSeries> seriesList = [];
  List<XtreamCategory> categories = [];

  @override
  Future<Result<List<XtreamSeries>>> getSeries({
    required String serverUrl,
    required String username,
    required String password,
    int? portOverride,
    String? categoryId,
    bool allowInsecureCertificates = false,
  }) async {
    return Success(seriesList);
  }

  @override
  Future<Result<List<XtreamCategory>>> getSeriesCategories({
    required String serverUrl,
    required String username,
    required String password,
    int? portOverride,
    bool allowInsecureCertificates = false,
  }) async {
    return Success(categories);
  }
}

XtreamSeries _series(int id, String name, {double? rating}) => XtreamSeries(
      seriesId: id,
      name: name,
      cover: 'http://img.example.com/$id.png',
      categoryId: '20',
      rating: rating,
    );

void main() {
  late AppDatabase db;
  late FakeXtreamDataSource dataSource;
  late SeriesImportRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dataSource = FakeXtreamDataSource();
    dataSource.categories = [
      const XtreamCategory(categoryId: '20', categoryName: 'Séries'),
    ];
    repo = SeriesImportRepository(
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

  SeriesImportResult dataOf(Result<SeriesImportResult> r) => r.when(
        success: (data) => data,
        failure: (f) => throw StateError('esperava sucesso: ${f.message}'),
      );

  group('SeriesImportRepository (batch reconcile)', () {
    test('first import inserts all series and mirrors them into channels',
        () async {
      dataSource.seriesList = [_series(1, 'Series A'), _series(2, 'Series B')];
      final playlistId = await insertPlaylist();

      final data = dataOf(
        await repo.importSeries(
          playlistId: playlistId,
          serverUrl: 'http://server.example.com',
          username: 'user',
          password: 'pass',
        ),
      );

      expect(data.seriesAdded, 2);

      final seriesRows = await db.select(db.seriesItems).get();
      expect(seriesRows, hasLength(2));
      expect(seriesRows.every((r) => r.isActive), isTrue);
      expect(seriesRows.every((r) => r.categoryName == 'Séries'), isTrue);

      final channelRows = await db.select(db.channels).get();
      expect(channelRows, hasLength(2));
    });

    test('second import applies the diff in one pass', () async {
      dataSource.seriesList = [_series(1, 'Series A'), _series(2, 'Series B')];
      final playlistId = await insertPlaylist();
      await repo.importSeries(
        playlistId: playlistId,
        serverUrl: 'http://server.example.com',
        username: 'user',
        password: 'pass',
      );

      // A changed (update), B vanished (deactivate), C appeared (insert).
      dataSource.seriesList = [
        _series(1, 'Series A', rating: 8.5),
        _series(3, 'Series C'),
      ];
      final data = dataOf(
        await repo.importSeries(
          playlistId: playlistId,
          serverUrl: 'http://server.example.com',
          username: 'user',
          password: 'pass',
        ),
      );

      expect(data.seriesAdded, 1);
      expect(data.seriesUpdated, 1);
      expect(data.seriesDeactivated, 1);

      final bySourceId = {
        for (final row in await db.select(db.seriesItems).get())
          row.sourceId: row,
      };
      expect(bySourceId, hasLength(3));
      expect(bySourceId['1']!.rating, 8.5);
      expect(bySourceId['1']!.isActive, isTrue);
      expect(bySourceId['2']!.isActive, isFalse);
      expect(bySourceId['3']!.name, 'Series C');

      final mirrorBySourceId = {
        for (final row in await db.select(db.channels).get())
          row.sourceId!: row,
      };
      expect(mirrorBySourceId, hasLength(3));
      expect(mirrorBySourceId['2']!.isActive, isFalse);
      expect(mirrorBySourceId['3']!.isActive, isTrue);
    });
  });
}
