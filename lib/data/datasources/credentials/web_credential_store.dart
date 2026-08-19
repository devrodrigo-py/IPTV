// Web credential store — placeholder for web platform.
// Uses dart:js_interop + package:web in modern Flutter.
// This file is only imported on web builds.

import 'package:nebula_iptv/core/credentials/credential_store.dart';
import 'package:nebula_iptv/core/result/result.dart';

/// Web implementation of [CredentialStore] using in-memory storage.
///
/// In production, this should use Web Crypto API or a secure
/// storage mechanism. For now, uses memory (same as MemoryCredentialStore).
class WebCredentialStore implements CredentialStore {
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
