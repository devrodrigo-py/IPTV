import 'package:drift/drift.dart';
import 'package:nebula_iptv/data/database/app_database.dart';

/// DAO for user ratings (Etapa 7).
///
/// Uses raw SQL (no codegen) following project conventions.
class RatingsDao extends DatabaseAccessor<AppDatabase> {
  RatingsDao(super.db);

  /// Get the user's rating for a specific channel.
  Future<double?> getRating(int profileId, int channelId) async {
    final rows = await customSelect(
      'SELECT rating FROM user_ratings WHERE profile_id = ? AND channel_id = ?',
      variables: [Variable.withInt(profileId), Variable.withInt(channelId)],
    ).get();
    if (rows.isEmpty) return null;
    return (rows.first.data['rating'] as num?)?.toDouble();
  }

  /// Set (insert or update) a rating for a channel.
  Future<void> setRating(int profileId, int channelId, double rating) async {
    await customStatement(
      '''
      INSERT INTO user_ratings (profile_id, channel_id, rating, updated_at)
      VALUES (?, ?, ?, datetime('now'))
      ON CONFLICT(profile_id, channel_id)
      DO UPDATE SET rating = excluded.rating, updated_at = datetime('now')
      ''',
      [profileId, channelId, rating],
    );
  }

  /// Remove a rating.
  Future<void> removeRating(int profileId, int channelId) async {
    await customStatement(
      'DELETE FROM user_ratings WHERE profile_id = ? AND channel_id = ?',
      [profileId, channelId],
    );
  }

  /// Get top rated items with channel info.
  Future<List<Map<String, dynamic>>> getTopRated(int profileId, {int limit = 20}) async {
    final rows = await customSelect(
      '''
      SELECT
        r.channel_id,
        r.rating,
        r.updated_at,
        c.name,
        c.logo_url,
        c.stream_url,
        c.source_type,
        c.group_name
      FROM user_ratings r
      INNER JOIN channels c ON c.id = r.channel_id
      WHERE r.profile_id = ? AND r.rating >= 4.0
      ORDER BY r.rating DESC, r.updated_at DESC
      LIMIT ?
      ''',
      variables: [Variable.withInt(profileId), Variable.withInt(limit)],
    ).get();
    return rows.map((r) => r.data).toList();
  }

  /// Get total number of ratings by profile.
  Future<int> getRatingCount(int profileId) async {
    final rows = await customSelect(
      'SELECT COUNT(*) as cnt FROM user_ratings WHERE profile_id = ?',
      variables: [Variable.withInt(profileId)],
    ).get();
    return (rows.first.data['cnt'] as int?) ?? 0;
  }

  /// Get average rating by profile.
  Future<double> getAverageRating(int profileId) async {
    final rows = await customSelect(
      'SELECT AVG(rating) as avg_rating FROM user_ratings WHERE profile_id = ?',
      variables: [Variable.withInt(profileId)],
    ).get();
    return (rows.first.data['avg_rating'] as num?)?.toDouble() ?? 0.0;
  }
}
