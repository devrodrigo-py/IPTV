import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nebula_iptv/core/credentials/credential_store.dart';
import 'package:nebula_iptv/core/errors/app_failure.dart';
import 'package:nebula_iptv/core/logging/app_logger.dart';
import 'package:nebula_iptv/core/result/result.dart';

/// Native implementation of [CredentialStore] backed by the platform
/// secure storage (DPAPI on Windows, EncryptedSharedPreferences on Android).
///
/// Passwords are never written to the Drift database — the database stores
/// only the [CredentialStore] key (spec §4.12).
class SecureCredentialStore implements CredentialStore {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  Future<Result<void>> save({
    required String key,
    required String value,
  }) async {
    try {
      await _storage.write(key: key, value: value);
      return const Success(null);
    } catch (e) {
      appLogger.e('CredentialStore.save failed', error: e);
      return Failure(
        CredentialFailure(
          message: 'Não foi possível salvar as credenciais.',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Result<String?>> read({required String key}) async {
    try {
      final value = await _storage.read(key: key);
      return Success(value);
    } catch (e) {
      appLogger.e('CredentialStore.read failed', error: e);
      return Failure(
        CredentialFailure(
          message: 'Não foi possível ler as credenciais.',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Result<void>> delete({required String key}) async {
    try {
      await _storage.delete(key: key);
      return const Success(null);
    } catch (e) {
      appLogger.e('CredentialStore.delete failed', error: e);
      return Failure(
        CredentialFailure(
          message: 'Não foi possível remover as credenciais.',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Result<bool>> exists({required String key}) async {
    try {
      final exists = await _storage.containsKey(key: key);
      return Success(exists);
    } catch (e) {
      appLogger.e('CredentialStore.exists failed', error: e);
      return Failure(
        CredentialFailure(
          message: 'Não foi possível verificar as credenciais.',
          originalError: e,
        ),
      );
    }
  }
}
