import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:nebula_iptv/core/network/dio_client.dart';
import 'package:nebula_iptv/data/database/app_database.dart';
import 'package:nebula_iptv/data/datasources/m3u/m3u_datasource.dart';
import 'package:nebula_iptv/data/repositories/playlist_import_repository.dart';

/// Performance benchmark for M3U import + refresh reconciliation (items 2-3
/// of the remediation round). Run with:
///
///   flutter run -t tool/perf_bench.dart -d windows
///
/// Measures, against a throwaway database:
///   - import wall time + max main-isolate event-loop gap (parse blocking)
///   - refresh (reconcile) wall time + event-loop gap
///   - process RSS
/// Source playlist is served by the local bench server on port 8931.
Future<void> main() async {
  final dbFile = File(
    '${Directory.systemTemp.path}/nebula_perf_bench.db',
  );
  if (dbFile.existsSync()) dbFile.deleteSync();

  final db = AppDatabase(NativeDatabase.createInBackground(dbFile));
  final repo = PlaylistImportRepository(
    db: db,
    m3uDataSource: M3uDataSource(client: DioClient()),
  );

  // Event-loop heartbeat: measures how long the main isolate stalls.
  var lastTick = DateTime.now();
  var maxGapImport = Duration.zero;
  var maxGapRefresh = Duration.zero;
  var inRefresh = false;
  final heartbeat = Timer.periodic(const Duration(milliseconds: 5), (_) {
    final now = DateTime.now();
    final gap = now.difference(lastTick);
    lastTick = now;
    if (inRefresh) {
      if (gap > maxGapRefresh) maxGapRefresh = gap;
    } else {
      if (gap > maxGapImport) maxGapImport = gap;
    }
  });

  // ── Import ──────────────────────────────────────────────────────────────
  final importSw = Stopwatch()..start();
  final importResult = await repo.importFromUrl(
    name: 'bench-20k',
    url: 'http://127.0.0.1:8931/big.m3u',
  );
  importSw.stop();

  importResult.when(
    success: (r) => stdout.writeln(
      'IMPORT_TOTAL_MS ${importSw.elapsedMilliseconds} | '
      'MAX_LOOP_GAP_IMPORT_MS ${maxGapImport.inMilliseconds} | '
      'channels ${r.channelsAdded}',
    ),
    failure: (f) => stdout.writeln('IMPORT_FAILED ${f.message}'),
  );

  // ── Refresh (reconcile with real diff: adds/removes/renames) ────────────
  _mutateSourceFile();

  final playlist = await db.playlistsDao.getAllPlaylists();
  if (playlist.isEmpty) {
    stdout.writeln('BENCH_ABORT no playlist row');
    heartbeat.cancel();
    await db.close();
    exit(2);
  }

  inRefresh = true;
  final refreshSw = Stopwatch()..start();
  final refreshResult = await repo.refreshPlaylist(playlist.first.id);
  refreshSw.stop();

  refreshResult.when(
    success: (r) => stdout.writeln(
      'REFRESH_TOTAL_MS ${refreshSw.elapsedMilliseconds} | '
      'MAX_LOOP_GAP_REFRESH_MS ${maxGapRefresh.inMilliseconds} | '
      'added ${r.channelsAdded} updated ${r.channelsUpdated} '
      'deactivated ${r.channelsDeactivated}',
    ),
    failure: (f) => stdout.writeln('REFRESH_FAILED ${f.message}'),
  );

  final rssMb = ProcessInfo.currentRss / (1024 * 1024);
  stdout.writeln('RSS_MB ${rssMb.toStringAsFixed(1)}');
  stdout.writeln('BENCH_DONE');

  heartbeat.cancel();
  await db.close();
  exit(0);
}

/// Rewrites the served playlist with a realistic diff: removes 2000
/// channels, renames 5000, adds 2000 new ones.
void _mutateSourceFile() {
  final file = File('C:/Users/digor/AppData/Local/Temp/nebula-perf/big.m3u');
  final content = file.readAsStringSync();
  final blocks = content.split('\n#EXTINF');
  final out = StringBuffer(blocks.first);
  var index = 0;
  var removed = 0;
  var renamed = 0;
  for (var i = 1; i < blocks.length; i++) {
    index++;
    if (index % 10 == 0) {
      removed++;
      continue; // remove
    }
    var block = '\n#EXTINF${blocks[i]}';
    if (index % 4 == 0) {
      final nameStart = block.lastIndexOf(',');
      if (nameStart != -1) {
        block =
            '${block.substring(0, nameStart)},ATUALIZADO ${block.substring(nameStart + 1)}';
        renamed++;
      }
    }
    out.write(block);
  }
  for (var i = 0; i < 2000; i++) {
    out.write(
      '#EXTINF:-1 tvg-id="new$i" tvg-name="Novo Canal $i" '
      'group-title="Novos",Novo Canal $i\n'
      'http://localhost:8931/new$i.ts\n',
    );
  }
  file.writeAsStringSync(out.toString());
  stdout.writeln('SOURCE_MUTATED removed=$removed renamed=$renamed added=2000');
}
