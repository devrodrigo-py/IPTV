import 'package:drift/drift.dart';
import 'package:nebula_iptv/data/database/daos/channels_dao.dart';
import 'package:nebula_iptv/data/database/daos/epg_dao.dart';
import 'package:nebula_iptv/data/database/daos/favorites_dao.dart';
import 'package:nebula_iptv/data/database/daos/playlists_dao.dart';
import 'package:nebula_iptv/data/database/daos/watch_history_dao.dart';
import 'package:nebula_iptv/data/database/tables/channels_table.dart';
import 'package:nebula_iptv/data/database/tables/epg_programs_table.dart';
import 'package:nebula_iptv/data/database/tables/favorites_table.dart';
import 'package:nebula_iptv/data/database/tables/playlists_table.dart';
import 'package:nebula_iptv/data/database/tables/watch_history_table.dart';

part 'app_database.g.dart';

/// Main application database.
///
/// Uses Drift with schemaVersion incremental migrations (spec 4.9).
/// First version starts here in Phase 3.
@DriftDatabase(
  tables: [
    Playlists,
    Channels,
    Favorites,
    WatchHistoryEntries,
    EpgPrograms,
  ],
  daos: [
    PlaylistsDao,
    ChannelsDao,
    FavoritesDao,
    WatchHistoryDao,
    EpgDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        // Create indexes for frequently queried fields (spec 31.1)
        await _createIndexes(m);
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Future migrations will be added here.
        // Rule: a published migration is never edited (spec 4.9).
      },
    );
  }

  Future<void> _createIndexes(Migrator m) async {
    // Channels
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_channels_playlist_id '
      'ON channels (playlist_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_channels_source_id '
      'ON channels (source_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_channels_tvg_id '
      'ON channels (tvg_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_channels_name '
      'ON channels (name)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_channels_group_name '
      'ON channels (group_name)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_channels_is_active '
      'ON channels (is_active)',
    );

    // Favorites
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_favorites_channel_id '
      'ON favorites (channel_id)',
    );

    // EPG Programs
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_epg_programs_channel_id '
      'ON epg_programs (channel_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_epg_programs_start_time '
      'ON epg_programs (start_time_utc)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_epg_programs_channel_start '
      'ON epg_programs (channel_id, start_time_utc)',
    );

    // Watch History
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_watch_history_channel_id '
      'ON watch_history_entries (channel_id)',
    );
  }
}
