import 'package:drift/drift.dart';
import 'package:drift/web.dart';

/// Creates the database connection for web platform.
/// Uses sql.js with the WASM file served from web/ folder.
QueryExecutor createDatabaseConnection() {
  return WebDatabase('nebula_iptv');
}
