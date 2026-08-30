import 'package:drift/drift.dart';
import 'package:nebula_iptv/data/database/app_database.dart';

/// DAO for user profiles (Etapa 6).
///
/// Uses raw SQL (no codegen) following project conventions.
class ProfileDao extends DatabaseAccessor<AppDatabase> {
  ProfileDao(super.db);

  /// Get all profiles ordered by creation date.
  Future<List<Map<String, dynamic>>> getAllProfiles() async {
    final rows = await customSelect(
      'SELECT * FROM profiles ORDER BY created_at ASC',
    ).get();
    return rows.map((r) => r.data).toList();
  }

  /// Get the default profile.
  Future<Map<String, dynamic>?> getDefaultProfile() async {
    final rows = await customSelect(
      'SELECT * FROM profiles WHERE is_default = 1 LIMIT 1',
    ).get();
    if (rows.isEmpty) return null;
    return rows.first.data;
  }

  /// Get profile by ID.
  Future<Map<String, dynamic>?> getProfileById(int id) async {
    final rows = await customSelect(
      'SELECT * FROM profiles WHERE id = ?',
      variables: [Variable.withInt(id)],
    ).get();
    if (rows.isEmpty) return null;
    return rows.first.data;
  }

  /// Get the count of profiles.
  Future<int> getProfileCount() async {
    final rows = await customSelect(
      'SELECT COUNT(*) as cnt FROM profiles',
    ).get();
    return rows.first.data['cnt'] as int;
  }

  /// Insert a new profile. Returns the new ID.
  Future<int> insertProfile({
    required String name,
    String avatarIcon = 'person',
    String avatarColor = '#7B2FF7',
  }) async {
    return customInsert(
      'INSERT INTO profiles (name, avatar_icon, avatar_color, is_default) VALUES (?, ?, ?, 0)',
      variables: [
        Variable.withString(name),
        Variable.withString(avatarIcon),
        Variable.withString(avatarColor),
      ],
    );
  }

  /// Update an existing profile.
  Future<void> updateProfile({
    required int id,
    required String name,
    required String avatarIcon,
    required String avatarColor,
  }) async {
    await customUpdate(
      'UPDATE profiles SET name = ?, avatar_icon = ?, avatar_color = ? WHERE id = ?',
      variables: [
        Variable.withString(name),
        Variable.withString(avatarIcon),
        Variable.withString(avatarColor),
        Variable.withInt(id),
      ],
      updates: {},
    );
  }

  /// Delete a profile (cannot delete default).
  Future<void> deleteProfile(int id) async {
    // Don't delete the default profile
    await customUpdate(
      'DELETE FROM profiles WHERE id = ? AND is_default = 0',
      variables: [Variable.withInt(id)],
      updates: {},
    );
    // Also delete associated shortcuts
    await customUpdate(
      'DELETE FROM user_shortcuts WHERE profile_id = ?',
      variables: [Variable.withInt(id)],
      updates: {},
    );
  }

  /// Ensure at least one profile exists (creates default if needed).
  Future<void> ensureDefaultProfile() async {
    final count = await getProfileCount();
    if (count == 0) {
      await customInsert(
        "INSERT INTO profiles (id, name, avatar_icon, avatar_color, is_default) VALUES (1, 'Principal', 'person', '#7B2FF7', 1)",
      );
    }
  }
}
