import 'package:drift/drift.dart';
part 'database.g.dart';

class TournamentRecords extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  DateTimeColumn get created => dateTime()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  TextColumn get payload => text()();
  @override
  Set<Column> get primaryKey => {id};
}

class Preferences extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [TournamentRecords, Preferences])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);
  @override
  int get schemaVersion => 1;
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      throw StateError('No migration from $from to $to');
    },
  );
}
