import 'package:nebula_iptv/core/credentials/credential_store.dart';
import 'package:nebula_iptv/core/result/result.dart';

/// In-memory credential store for development and testing.
///
/// In production, this should be replaced with a platform-specific
/// secure storage implementation (flutter_secure_storage or equivalent).
/// The interface contract remains the same (spec 4.12).
class MemoryCredentialStore implements CredentialStore {
  final Map<String, String> _store = {};

  @override
  Future<Result<void>> save({
    required String key,
    required String value,
  }) async {
    _store[key] = value;
    return const Success(null);
  }

  @override
  Future<Result<String?>> read({required String key}) async {
    return Success(_store[key]);
  }

  @override
  Future<Result<void>> delete({required String key}) async {
    _store.remove(key);
    return const Success(null);
  }

  @override
  Future<Result<bool>> exists({required String key}) async {
    return Success(_store.containsKey(key));
  }
}
