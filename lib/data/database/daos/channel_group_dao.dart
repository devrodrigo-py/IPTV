import 'package:drift/drift.dart';
import 'package:nebula_iptv/data/database/app_database.dart';
import 'package:nebula_iptv/data/database/tables/channel_group_tables.dart';

/// A channel group entry.
class ChannelGroupEntry {
  final int id;
  final String displayName;
  final String normalizedName;
  final int? primaryChannelId;
  final double confidenceScore;
  final String source;
  final DateTime createdAt;

  const ChannelGroupEntry({
    required this.id,
    required this.displayName,
    required this.normalizedName,
    this.primaryChannelId,
    this.confidenceScore = 1.0,
    this.source = 'auto',
    required this.createdAt,
  });
}

/// A member of a channel group.
class ChannelGroupMember {
  final int id;
  final int groupId;
  final int channelId;
  final String? qualityTag;
  final int priority;

  const ChannelGroupMember({
    required this.id,
    required this.groupId,
    required this.channelId,
    this.qualityTag,
    this.priority = 0,
  });
}

/// DAO for the channel_groups and channel_group_members tables.
///
/// Manages grouping of quality-variant channels (e.g. HBO Max [FHD/HD/SD]).
class ChannelGroupDao extends DatabaseAccessor<AppDatabase> {
  ChannelGroupDao(super.db);

  /// Creates tables if they don't exist.
  Future<void> ensureTables() async {
    await customStatement(ChannelGroupSql.createChannelGroups);
    await customStatement(ChannelGroupSql.createChannelGroupMembers);
    for (final idx in ChannelGroupSql.createIndexes) {
      await customStatement(idx);
    }
  }

  /// Creates a new channel group and returns its ID.
  Future<int> createGroup({
    required String displayName,
    required String normalizedName,
    int? primaryChannelId,
    double confidenceScore = 1.0,
    String source = 'auto',
  }) async {
    return customInsert(
      '''
      INSERT INTO channel_groups 
        (display_name, normalized_name, primary_channel_id, confidence_score, source)
      VALUES (?, ?, ?, ?, ?)
      ''',
      variables: [
        Variable.withString(displayName),
        Variable.withString(normalizedName),
        if (primaryChannelId != null)
          Variable.withInt(primaryChannelId)
        else
          const Variable(null),
        Variable.withReal(confidenceScore),
        Variable.withString(source),
      ],
    );
  }

  /// Adds a channel member to a group.
  Future<void> addMember({
    required int groupId,
    required int channelId,
    String? qualityTag,
    int priority = 0,
  }) async {
    await customInsert(
      '''
      INSERT OR IGNORE INTO channel_group_members 
        (group_id, channel_id, quality_tag, priority)
      VALUES (?, ?, ?, ?)
      ''',
      variables: [
        Variable.withInt(groupId),
        Variable.withInt(channelId),
        if (qualityTag != null)
          Variable.withString(qualityTag)
        else
          const Variable(null),
        Variable.withInt(priority),
      ],
    );
  }

  /// Gets the group a channel belongs to (if any).
  Future<ChannelGroupEntry?> getGroupForChannel(int channelId) async {
    final results = await customSelect(
      '''
      SELECT cg.* FROM channel_groups cg
      INNER JOIN channel_group_members cgm ON cgm.group_id = cg.id
      WHERE cgm.channel_id = ?
      LIMIT 1
      ''',
      variables: [Variable.withInt(channelId)],
    ).get();

    if (results.isEmpty) return null;
    return _rowToGroup(results.first);
  }

  /// Gets all members of a group.
  Future<List<ChannelGroupMember>> getGroupMembers(int groupId) async {
    final results = await customSelect(
      'SELECT * FROM channel_group_members WHERE group_id = ? ORDER BY priority DESC',
      variables: [Variable.withInt(groupId)],
    ).get();

    return results.map(_rowToMember).toList();
  }

  /// Gets all groups with pagination.
  Future<List<ChannelGroupEntry>> getAllGroups({
    int limit = 50,
    int offset = 0,
  }) async {
    final results = await customSelect(
      'SELECT * FROM channel_groups ORDER BY display_name LIMIT ? OFFSET ?',
      variables: [Variable.withInt(limit), Variable.withInt(offset)],
    ).get();

    return results.map(_rowToGroup).toList();
  }

  /// Gets group count.
  Future<int> getGroupCount() async {
    final results = await customSelect(
      'SELECT COUNT(*) as count FROM channel_groups',
    ).get();
    return results.first.read<int>('count');
  }

  /// Sets the primary channel for a group.
  Future<void> setGroupPrimary(int groupId, int channelId) async {
    await customUpdate(
      'UPDATE channel_groups SET primary_channel_id = ? WHERE id = ?',
      variables: [Variable.withInt(channelId), Variable.withInt(groupId)],
      updates: {},
    );
  }

  /// Deletes a group (members cascade).
  Future<void> deleteGroup(int groupId) async {
    await customUpdate(
      'DELETE FROM channel_groups WHERE id = ?',
      variables: [Variable.withInt(groupId)],
      updates: {},
    );
  }

  /// Checks if a group with this normalized name already exists.
  Future<int?> findGroupByNormalizedName(String normalizedName) async {
    final results = await customSelect(
      'SELECT id FROM channel_groups WHERE normalized_name = ? LIMIT 1',
      variables: [Variable.withString(normalizedName)],
    ).get();

    if (results.isEmpty) return null;
    return results.first.read<int>('id');
  }

  /// Deletes all auto-generated groups (preserves manual).
  Future<int> clearAutoGroups() async {
    final results = await customSelect(
      "SELECT COUNT(*) as count FROM channel_groups WHERE source = 'auto'",
    ).get();
    final count = results.first.read<int>('count');

    await customUpdate(
      "DELETE FROM channel_groups WHERE source = 'auto'",
      variables: [],
      updates: {},
    );
    return count;
  }

  ChannelGroupEntry _rowToGroup(QueryRow row) {
    return ChannelGroupEntry(
      id: row.read<int>('id'),
      displayName: row.read<String>('display_name'),
      normalizedName: row.read<String>('normalized_name'),
      primaryChannelId: row.readNullable<int>('primary_channel_id'),
      confidenceScore: row.read<double>('confidence_score'),
      source: row.read<String>('source'),
      createdAt: DateTime.tryParse(
            row.read<String>('created_at'),
          ) ??
          DateTime.now(),
    );
  }

  ChannelGroupMember _rowToMember(QueryRow row) {
    return ChannelGroupMember(
      id: row.read<int>('id'),
      groupId: row.read<int>('group_id'),
      channelId: row.read<int>('channel_id'),
      qualityTag: row.readNullable<String>('quality_tag'),
      priority: row.read<int>('priority'),
    );
  }
}
