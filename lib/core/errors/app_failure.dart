/// Base class for all application failures.
///
/// Each failure type provides a user-friendly [message] and an optional
/// [originalError] for debugging purposes (never shown to the user).
sealed class AppFailure {
  /// User-friendly message suitable for UI display.
  String get message;

  /// The original error that caused this failure (for logging only).
  Object? get originalError;

  const AppFailure();

  @override
  String toString() => '$runtimeType: $message';
}

/// Network-related failure (timeout, no connection, server error).
final class NetworkFailure extends AppFailure {
  @override
  final String message;

  @override
  final Object? originalError;

  final int? statusCode;

  const NetworkFailure({
    required this.message,
    this.originalError,
    this.statusCode,
  });
}

/// Failure during M3U/M3U8 playlist parsing.
final class PlaylistParseFailure extends AppFailure {
  @override
  final String message;

  @override
  final Object? originalError;

  final int? lineNumber;

  const PlaylistParseFailure({
    required this.message,
    this.originalError,
    this.lineNumber,
  });
}

/// Database operation failure.
final class DatabaseFailure extends AppFailure {
  @override
  final String message;

  @override
  final Object? originalError;

  const DatabaseFailure({
    required this.message,
    this.originalError,
  });
}

/// Stream unavailable or playback failure after retries exhausted.
final class StreamUnavailableFailure extends AppFailure {
  @override
  final String message;

  @override
  final Object? originalError;

  const StreamUnavailableFailure({
    required this.message,
    this.originalError,
  });
}

/// Authentication failure (invalid credentials).
final class AuthenticationFailure extends AppFailure {
  @override
  final String message;

  @override
  final Object? originalError;

  const AuthenticationFailure({
    required this.message,
    this.originalError,
  });
}

/// Xtream account expired.
final class AccountExpiredFailure extends AppFailure {
  @override
  final String message;

  @override
  final Object? originalError;

  const AccountExpiredFailure({
    required this.message,
    this.originalError,
  });
}

/// Xtream connection limit reached.
final class ConnectionLimitFailure extends AppFailure {
  @override
  final String message;

  @override
  final Object? originalError;

  const ConnectionLimitFailure({
    required this.message,
    this.originalError,
  });
}

/// EPG/XMLTV parsing failure.
final class EpgParseFailure extends AppFailure {
  @override
  final String message;

  @override
  final Object? originalError;

  const EpgParseFailure({
    required this.message,
    this.originalError,
  });
}

/// Cache read/write failure.
final class CacheFailure extends AppFailure {
  @override
  final String message;

  @override
  final Object? originalError;

  const CacheFailure({
    required this.message,
    this.originalError,
  });
}

/// Credential storage failure.
final class CredentialFailure extends AppFailure {
  @override
  final String message;

  @override
  final Object? originalError;

  const CredentialFailure({
    required this.message,
    this.originalError,
  });
}

/// Fallback for unexpected errors.
final class UnknownFailure extends AppFailure {
  @override
  final String message;

  @override
  final Object? originalError;

  const UnknownFailure({
    this.message = 'Ocorreu um erro inesperado.',
    this.originalError,
  });
}
