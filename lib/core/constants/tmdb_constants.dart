/// TMDB API configuration.
///
/// To obtain your own API key:
/// 1. Create a free account at https://www.themoviedb.org/signup
/// 2. Go to https://www.themoviedb.org/settings/api
/// 3. Request an API key (select "Developer" option)
/// 4. Replace the placeholder below with your key
abstract final class TmdbConstants {
  /// TMDB API v3 key. Replace with your own key.
  static const apiKey = '064e778ffefb262053318d9beaceb4c3';

  /// TMDB API base URL.
  static const baseUrl = 'https://api.themoviedb.org/3';

  /// TMDB image CDN base URL.
  static const imageBaseUrl = 'https://image.tmdb.org/t/p';

  /// Default language for metadata (Portuguese - Brazil).
  static const defaultLanguage = 'pt-BR';

  /// Fallback language when PT-BR is not available.
  static const fallbackLanguage = 'en-US';

  /// Image sizes available from TMDB CDN.
  static const posterSizeSmall = 'w185';
  static const posterSizeMedium = 'w342';
  static const posterSizeLarge = 'w500';
  static const posterSizeOriginal = 'original';
  static const backdropSizeMedium = 'w780';
  static const backdropSizeLarge = 'w1280';

  /// Rate limiting: TMDB allows ~40 requests per 10 seconds.
  static const maxRequestsPer10Seconds = 40;

  /// Cache duration for metadata (7 days).
  static const cacheDuration = Duration(days: 7);
}
