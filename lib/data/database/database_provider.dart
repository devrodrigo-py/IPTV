import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/core/credentials/credential_store.dart';
import 'package:nebula_iptv/data/database/app_database.dart';
import 'package:nebula_iptv/data/database/connection/connection.dart';
import 'package:nebula_iptv/data/datasources/credentials/memory_credential_store.dart';
import 'package:nebula_iptv/data/datasources/credentials/secure_credential_store.dart';
import 'package:nebula_iptv/data/datasources/credentials/web_credential_store.dart';

/// Creates the database for the current platform.
///
/// Uses conditional import to select NativeDatabase (Windows/Android)
/// or WasmDatabase (Web) at compile time.
AppDatabase createDatabase() {
  return AppDatabase(createDatabaseConnection());
}

/// Platform-appropriate [CredentialStore] (spec §4.12).
///
/// Native platforms use the platform secure storage; web keeps the
/// in-memory store (no persistent secure storage is available there yet).
final credentialStoreProvider = Provider<CredentialStore>((ref) {
  if (kIsWeb) {
    return WebCredentialStore();
  }
  return SecureCredentialStore();
});

/// In-memory store for tests and dev overrides.
MemoryCredentialStore createMemoryCredentialStore() {
  return MemoryCredentialStore();
}

/// Root dependency overridden once during bootstrap.
final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('databaseProvider must be overridden');
});
