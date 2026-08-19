import 'package:drift/drift.dart';
import 'package:nebula_iptv/data/database/tables/channels_table.dart';

/// SQLite table definition for favorites.
///
/// Favorites are stored in a separate table from channels.
/// A channel's favorite status is determined by the existence
/// of a row here, not by a field on the channel itself.
class Favorites extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get channelId => integer().unique().references(Channels, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
