import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

/// Creates the database connection for web (SQLite compiled to WASM).
///
/// Requires `web/sqlite3.wasm` and `web/drift_worker.js`, kept in version
/// lockstep with the `sqlite3`/`drift` packages (currently sqlite3 3.5.2,
/// drift 2.34.3). Opening is async, so the connection resolves lazily.
QueryExecutor createDatabaseConnection() {
  return DatabaseConnection.delayed(Future(() async {
    final result = await WasmDatabase.open(
      databaseName: 'nebula_iptv',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.js'),
    );
    return result.resolvedExecutor;
  }));
}
