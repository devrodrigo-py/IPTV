import 'package:drift/drift.dart';
import 'package:nebula_iptv/data/database/app_database.dart';
import 'package:nebula_iptv/data/database/tables/channels_table.dart';

part 'channels_dao.g.dart';

/// Data access object for channels.
@DriftAccessor(tables: [Channels])
class ChannelsDao extends DatabaseAccessor<AppDatabase>
    with _$ChannelsDaoMixin {
  ChannelsDao(super.db);

  /// Returns all active channels for a playlist.
  Future<List<Channel>> getChannelsByPlaylist(int playlistId) {
    return (select(channels)
          ..where((c) => c.playlistId.equals(playlistId))
          ..where((c) => c.isActive.equals(true))
          ..orderBy([(c) => OrderingTerm.asc(c.name)]))
        .get();
  }

  /// Returns all active channels across all playlists.
  Future<List<Channel>> getAllActiveChannels() {
    return (select(channels)
          ..where((c) => c.isActive.equals(true))
          ..orderBy([(c) => OrderingTerm.asc(c.name)]))
        .get();
  }

  /// Returns channels by group name.
  Future<List<Channel>> getChannelsByGroup(String groupName) {
    return (select(channels)
          ..where((c) => c.groupName.equals(groupName))
          ..where((c) => c.isActive.equals(true))
          ..orderBy([(c) => OrderingTerm.asc(c.name)]))
        .get();
  }

  /// Searches channels by name (partial match).
  Future<List<Channel>> searchChannels(String query) {
    return (select(channels)
          ..where(
            (c) => c.name.like('%$query%') & c.isActive.equals(true),
          )
          ..orderBy([(c) => OrderingTerm.asc(c.name)])
          ..limit(100))
        .get();
  }

  /// Returns a single channel by ID.
  Future<Channel?> getChannelById(int id) {
    return (select(channels)..where((c) => c.id.equals(id))).getSingleOrNull();
  }

  /// Returns a channel by sourceId within a playlist.
  Future<Channel?> getChannelBySourceId(int playlistId, String sourceId) {
    return (select(channels)
          ..where(
            (c) =>
                c.playlistId.equals(playlistId) & c.sourceId.equals(sourceId),
          ))
        .getSingleOrNull();
  }

  /// Inserts a channel and returns its ID.
  Future<int> insertChannel(ChannelsCompanion entry) {
    return into(channels).insert(entry);
  }

  /// Batch-inserts multiple channels.
  Future<void> insertChannels(List<ChannelsCompanion> entries) {
    return batch((b) => b.insertAll(channels, entries));
  }

  /// Updates an existing channel.
  Future<bool> updateChannel(ChannelsCompanion entry) {
    return update(channels).replace(entry);
  }

  /// Marks channels as inactive (soft delete during refresh).
  Future<int> deactivateChannelsForPlaylist(int playlistId) {
    return (update(channels)..where((c) => c.playlistId.equals(playlistId)))
        .write(
      ChannelsCompanion(
        isActive: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Activates a specific channel.
  Future<int> activateChannel(int id) {
    return (update(channels)..where((c) => c.id.equals(id))).write(
      ChannelsCompanion(
        isActive: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Returns distinct group names for active channels.
  Future<List<String>> getDistinctGroups() async {
    final query = selectOnly(channels, distinct: true)
      ..addColumns([channels.groupName])
      ..where(channels.isActive.equals(true))
      ..where(channels.groupName.isNotNull())
      ..orderBy([OrderingTerm.asc(channels.groupName)]);

    final rows = await query.get();
    return rows
        .map((row) => row.read(channels.groupName))
        .whereType<String>()
        .toList();
  }

  /// Watches active channels for a playlist (reactive stream).
  Stream<List<Channel>> watchChannelsByPlaylist(int playlistId) {
    return (select(channels)
          ..where((c) => c.playlistId.equals(playlistId))
          ..where((c) => c.isActive.equals(true))
          ..orderBy([(c) => OrderingTerm.asc(c.name)]))
        .watch();
  }
}
