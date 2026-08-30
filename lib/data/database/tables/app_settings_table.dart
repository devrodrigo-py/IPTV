import 'package:drift/drift.dart';

/// Key-value store for persisted application settings (toggle de health
/// check, intervalo de sincronização do EPG — spec §18).
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
