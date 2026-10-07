import 'package:drift/drift.dart';
import 'package:nebula_iptv/data/database/app_database.dart';

/// DAO for user shortcuts/pins (Etapa 6).
///
/// Allows users to pin channels/movies/series for quick access.
class ShortcutDao extends DatabaseAccessor<AppDatabase> {
  ShortcutDao(super.db);

  /// Get all shortcuts for a profile, ordered by position.
  Future<List<Map<String, dynamic>>> getShortcuts(int profileId) async {
    final rows = await customSelect(
      '''
      SELECT s.*, c.name, c.logo_url, c.stream_url, c.source_type, c.group_name
      FROM user_shortcuts s
      JOIN channels c ON c.id = s.channel_id
      WHERE s.profile_id = ? AND c.is_active = 1
      ORDER BY s.position ASC
      ''',
      variables: [Variable.withInt(profileId)],
    ).get();
    return rows.map((r) => r.data).toList();
  }

  /// Check if a channel is already a shortcut for this profile.
  Future<bool> isShortcut(int profileId, int channelId) async {
    final rows = await customSelect(
      'SELECT id FROM user_shortcuts WHERE profile_id = ? AND channel_id = ?',
      variables: [Variable.withInt(profileId), Variable.withInt(channelId)],
    ).get();
    return rows.isNotEmpty;
  }

  /// Add a shortcut. Returns the new ID.
  Future<int> addShortcut(int profileId, int channelId) async {
    // Get max position
    final posRows = await customSelect(
      'SELECT COALESCE(MAX(position), 0) as max_pos FROM user_shortcuts WHERE profile_id = ?',
      variables: [Variable.withInt(profileId)],
    ).get();
    final nextPos = (posRows.first.data['max_pos'] as int) + 1;

    return customInsert(
      'INSERT INTO user_shortcuts (profile_id, channel_id, position) VALUES (?, ?, ?)',
      variables: [
        Variable.withInt(profileId),
        Variable.withInt(channelId),
        Variable.withInt(nextPos),
      ],
    );
  }

  /// Remove a shortcut by channel ID for a profile.
  Future<void> removeShortcut(int profileId, int channelId) async {
    await customUpdate(
      'DELETE FROM user_shortcuts WHERE profile_id = ? AND channel_id = ?',
      variables: [Variable.withInt(profileId), Variable.withInt(channelId)],
      updates: {},
    );
  }

  /// Remove a shortcut by ID.
  Future<void> removeShortcutById(int id) async {
    await customUpdate(
      'DELETE FROM user_shortcuts WHERE id = ?',
      variables: [Variable.withInt(id)],
      updates: {},
    );
  }

  /// Get shortcut count for a profile.
  Future<int> getShortcutCount(int profileId) async {
    final rows = await customSelect(
      'SELECT COUNT(*) as cnt FROM user_shortcuts WHERE profile_id = ?',
      variables: [Variable.withInt(profileId)],
    ).get();
    return rows.first.data['cnt'] as int;
  }
}
