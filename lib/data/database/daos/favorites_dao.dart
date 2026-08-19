import 'package:drift/drift.dart';
import 'package:nebula_iptv/data/database/app_database.dart';
import 'package:nebula_iptv/data/database/tables/channels_table.dart';
import 'package:nebula_iptv/data/database/tables/favorites_table.dart';

part 'favorites_dao.g.dart';

/// Data access object for favorites.
@DriftAccessor(tables: [Favorites, Channels])
class FavoritesDao extends DatabaseAccessor<AppDatabase>
    with _$FavoritesDaoMixin {
  FavoritesDao(super.db);

  /// Returns all favorite channels (joined with channel data).
  Future<List<Channel>> getFavoriteChannels() {
    final query = select(channels).join([
      innerJoin(favorites, favorites.channelId.equalsExp(channels.id)),
    ])
      ..where(channels.isActive.equals(true))
      ..orderBy([OrderingTerm.asc(channels.name)]);

    return query.map((row) => row.readTable(channels)).get();
  }

  /// Checks if a channel is a favorite.
  Future<bool> isFavorite(int channelId) async {
    final query = select(favorites)
      ..where((f) => f.channelId.equals(channelId));
    final result = await query.getSingleOrNull();
    return result != null;
  }

  /// Adds a channel to favorites. Returns the favorite ID.
  /// Silently succeeds if already a favorite (ON CONFLICT IGNORE).
  Future<int> addFavorite(int channelId) {
    return into(favorites).insert(
      FavoritesCompanion(
        channelId: Value(channelId),
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  /// Removes a channel from favorites.
  Future<int> removeFavorite(int channelId) {
    return (delete(favorites)..where((f) => f.channelId.equals(channelId)))
        .go();
  }

  /// Toggles favorite status. Returns the new status.
  Future<bool> toggleFavorite(int channelId) async {
    final exists = await isFavorite(channelId);
    if (exists) {
      await removeFavorite(channelId);
      return false;
    } else {
      await addFavorite(channelId);
      return true;
    }
  }

  /// Returns favorite channel IDs (for efficient lookup).
  Future<Set<int>> getFavoriteChannelIds() async {
    final query = selectOnly(favorites)..addColumns([favorites.channelId]);
    final rows = await query.get();
    return rows.map((r) => r.read(favorites.channelId)!).toSet();
  }

  /// Watches favorites (reactive stream).
  Stream<List<Channel>> watchFavoriteChannels() {
    final query = select(channels).join([
      innerJoin(favorites, favorites.channelId.equalsExp(channels.id)),
    ])
      ..where(channels.isActive.equals(true))
      ..orderBy([OrderingTerm.asc(channels.name)]);

    return query.map((row) => row.readTable(channels)).watch();
  }
}
