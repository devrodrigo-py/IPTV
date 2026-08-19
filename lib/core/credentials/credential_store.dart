import 'package:nebula_iptv/core/result/result.dart';

/// Abstraction for secure credential storage.
///
/// Implementations should use platform-specific secure storage
/// (e.g., Keychain on macOS/iOS, EncryptedSharedPreferences on Android,
/// DPAPI on Windows).
///
/// The domain layer interacts only with this interface — never with
/// the underlying secure storage mechanism directly.
abstract interface class CredentialStore {
  /// Saves a credential identified by [key].
  Future<Result<void>> save({
    required String key,
    required String value,
  });

  /// Reads a credential by [key]. Returns `null` if not found.
  Future<Result<String?>> read({required String key});

  /// Deletes a credential by [key].
  Future<Result<void>> delete({required String key});

  /// Checks if a credential exists for [key].
  Future<Result<bool>> exists({required String key});
}
