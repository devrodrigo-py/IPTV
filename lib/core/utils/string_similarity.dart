import 'dart:math';

/// String similarity utilities for content matching.
///
/// Implements Jaro-Winkler distance algorithm for fuzzy matching
/// of IPTV content names against the MediaWork database.
abstract final class StringSimilarity {
  /// Computes the Jaro similarity between two strings.
  /// Returns a value between 0.0 (no similarity) and 1.0 (identical).
  static double jaro(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    final maxDist = (max(s1.length, s2.length) ~/ 2) - 1;
    if (maxDist < 0) return 0.0;

    final s1Matches = List<bool>.filled(s1.length, false);
    final s2Matches = List<bool>.filled(s2.length, false);

    int matches = 0;
    int transpositions = 0;

    // Find matching characters within the allowed distance window.
    for (int i = 0; i < s1.length; i++) {
      final start = max(0, i - maxDist);
      final end = min(i + maxDist + 1, s2.length);

      for (int j = start; j < end; j++) {
        if (s2Matches[j] || s1[i] != s2[j]) continue;
        s1Matches[i] = true;
        s2Matches[j] = true;
        matches++;
        break;
      }
    }

    if (matches == 0) return 0.0;

    // Count transpositions (matched chars in different order).
    int k = 0;
    for (int i = 0; i < s1.length; i++) {
      if (!s1Matches[i]) continue;
      while (!s2Matches[k]) {
        k++;
      }
      if (s1[i] != s2[k]) transpositions++;
      k++;
    }

    final m = matches.toDouble();
    return (m / s1.length + m / s2.length + (m - transpositions / 2) / m) / 3;
  }

  /// Computes the Jaro-Winkler similarity between two strings.
  /// Gives bonus weight to common prefixes (up to 4 chars).
  /// Returns a value between 0.0 and 1.0.
  ///
  /// [prefixScale] controls how much weight is given to common prefixes
  /// (standard value is 0.1, must not exceed 0.25).
  static double jaroWinkler(
    String s1,
    String s2, {
    double prefixScale = 0.1,
  }) {
    assert(
      prefixScale >= 0 && prefixScale <= 0.25,
      'prefixScale must be between 0 and 0.25',
    );

    final jaroSim = jaro(s1, s2);

    // Determine common prefix length (up to 4 characters).
    int prefixLength = 0;
    final maxPrefix = min(4, min(s1.length, s2.length));
    for (int i = 0; i < maxPrefix; i++) {
      if (s1[i] == s2[i]) {
        prefixLength++;
      } else {
        break;
      }
    }

    return jaroSim + (prefixLength * prefixScale * (1 - jaroSim));
  }
}
