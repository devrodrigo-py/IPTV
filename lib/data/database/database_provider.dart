import 'package:nebula_iptv/data/database/app_database.dart';
import 'package:nebula_iptv/data/database/connection/connection.dart';

/// Creates the database for the current platform.
///
/// Uses conditional import to select NativeDatabase (Windows/Android)
/// or WasmDatabase (Web) at compile time.
AppDatabase createDatabase() {
  return AppDatabase(createDatabaseConnection());
}
