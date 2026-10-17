import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nebula_iptv/data/database/app_database.dart';
import 'package:nebula_iptv/data/database/daos/watch_stats_dao.dart';
import 'package:nebula_iptv/data/database/tables/channels_table.dart';
import 'package:nebula_iptv/data/database/tables/playlists_table.dart';
import 'package:nebula_iptv/data/repositories/catalog_repository.dart';

void main() {
  late AppDatabase db;
  late CatalogRepository repo;
  late int playlist;
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = CatalogRepository(db);
    playlist = await db.playlistsDao.insertPlaylist(
      PlaylistsCompanion.insert(name: 'Fixture', type: PlaylistType.m3u));
  });
  tearDown(() async => db.close());
  Future<int> insert(String name, {ChannelSourceType type = ChannelSourceType.vod,
    bool active = true, String group = 'Cinema'}) =>
    db.channelsDao.insertChannel(ChannelsCompanion.insert(playlistId: playlist,
      name: name, streamUrl: 'https://example.invalid/movie', sourceType: type,
      isActive: Value(active), groupName: Value(group)));
  test('discovery is bounded and excludes live and inactive items', () async {
    for (var i = 0; i < 180; i++) { await insert('Movie $i'); }
    await insert('Live', type: ChannelSourceType.m3u);
    await insert('Hidden', active: false);
    final home = await repo.watchHome().first;
    expect(home.featured, hasLength(4));
    final titles = home.shelves.expand((s) => s.items).map((i) => i.title);
    expect(titles, isNot(contains('Live')));
    expect(titles, isNot(contains('Hidden')));
    expect(home.shelves.last.items, hasLength(16));
  });
  test('favorites stream reflects add/remove without reload', () async {
    final id = await insert('Saved');
    final stream = repo.watchMyList().asBroadcastStream();
    final initial = stream.first;
    expect(await initial, isEmpty);
    final added = stream.firstWhere((items) => items.isNotEmpty);
    await db.favoritesDao.addFavorite(id);
    expect((await added).single.id, id);
    final removed = stream.firstWhere((items) => items.isEmpty);
    await db.favoritesDao.removeFavorite(id);
    expect(await removed, isEmpty);
  });
  test('resume uses actual duration and allows rewinding', () async {
    final id = await insert('Resume');
    final stats = WatchStatsDao(db);
    await stats.upsertWatchEntry(channelId: id, watchedDurationMs: 30000,
      progressPercent: .5, totalDurationMs: 60000, contentType: 'vod');
    expect((await repo.watchContinueWatching().first).single.resumeMs, 30000);
    await stats.upsertWatchEntry(channelId: id, watchedDurationMs: 10000,
      progressPercent: 0, totalDurationMs: 0, contentType: 'vod');
    final resumed = (await repo.watchContinueWatching().first).single;
    expect(resumed.resumeMs, 10000);
    expect(resumed.progress, 0);
  });
}
