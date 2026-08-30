import 'package:nebula_iptv/core/logging/app_logger.dart';
import 'package:nebula_iptv/data/database/app_database.dart';
import 'package:nebula_iptv/domain/services/content_matching_service.dart';

/// One-shot data repair for metadata written by the old name normalizer.
///
/// The previous [ContentMatchingService.normalize] stripped trailing numbers
/// ("The 100" → "the"), so enrichment aliased many different titles onto one
/// wrong MediaWork — a series detail screen could load another show's
/// seasons/episodes entirely. This repair re-normalizes stored data with the
/// fixed algorithm:
///
/// - media_works.normalized_title is recomputed from canonical_title (safe —
///   the row is the canonical identity).
/// - content_aliases rows whose normalized_text changed are DELETED: the
///   alias→work mapping may point at the wrong work, and deleting is safe —
///   the alias is rebuilt on the next enrichment with a verified match.
///
/// Idempotent: rows written by the fixed normalizer recompute identically
/// and are left alone. Cheap: the catalog's alias count is in the hundreds.
class AliasRepairService {
  final AppDatabase _db;
  final ContentMatchingService _matching;

  AliasRepairService(
      {required AppDatabase db, required ContentMatchingService matching})
      : _db = db,
        _matching = matching;

  /// Runs the repair and returns how many rows were touched.
  Future<({int aliasesRemoved, int titlesRepaired})> repair() async {
    try {
      await _db.mediaWorkDao.ensureTables();

      var aliasesRemoved = 0;
      for (final alias in await _db.mediaWorkDao.getAllAliasRowsForRepair()) {
        final recomputed = _matching.normalize(alias.aliasText);
        if (recomputed != alias.normalizedText) {
          await _db.mediaWorkDao.deleteAliasRow(alias.id);
          aliasesRemoved++;
        }
      }

      var titlesRepaired = 0;
      for (final work in await _db.mediaWorkDao.getWorkTitleRowsForRepair()) {
        final recomputed = _matching.normalize(work.canonicalTitle);
        if (recomputed != work.normalizedTitle) {
          await _db.mediaWorkDao.updateNormalizedTitle(work.id, recomputed);
          titlesRepaired++;
        }
      }

      if (aliasesRemoved > 0 || titlesRepaired > 0) {
        appLogger.i(
          '[AliasRepair] $aliasesRemoved aliases removidos, '
          '$titlesRepaired títulos re-normalizados (correção do normalizer antigo)',
        );
      }
      return (aliasesRemoved: aliasesRemoved, titlesRepaired: titlesRepaired);
    } catch (e) {
      // Reparo é best-effort: nunca bloquear o bootstrap por ele.
      appLogger.w('[AliasRepair] Falhou (best-effort): $e');
      return const (aliasesRemoved: 0, titlesRepaired: 0);
    }
  }
}
