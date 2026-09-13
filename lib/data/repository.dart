import 'dart:convert';
import 'package:drift/drift.dart';
import '../domain/models.dart';
import 'database.dart';

abstract interface class TournamentRepository {
  Future<List<Tournament>> all();
  Future<void> save(Tournament tournament);
  Future<void> importAll(List<Tournament> tournaments);
  Future<void> delete(String id);
  Future<void> deleteAll();
  Future<void> archiveExpired(DateTime now);
  Future<String?> language();
  Future<void> setLanguage(String language);
  Future<void> close();
}

class DriftTournamentRepository implements TournamentRepository {
  final AppDatabase db;
  DriftTournamentRepository(this.db);
  @override
  Future<List<Tournament>> all() async =>
      (await (db.select(
        db.tournamentRecords,
      )..orderBy([(r) => OrderingTerm.desc(r.created)])).get()).map((r) {
        final t = Tournament.fromJson(
          jsonDecode(r.payload) as Map<String, dynamic>,
        );
        t.archived = r.archived;
        return t;
      }).toList();
  Future<void> _write(Tournament t) => db
      .into(db.tournamentRecords)
      .insertOnConflictUpdate(
        TournamentRecordsCompanion.insert(
          id: t.id,
          name: t.name,
          created: t.created,
          archived: Value(t.archived),
          payload: jsonEncode(t.toJson()),
        ),
      );
  @override
  Future<void> save(Tournament tournament) =>
      db.transaction(() => _write(tournament));
  @override
  Future<void> importAll(List<Tournament> tournaments) =>
      db.transaction(() async {
        for (final t in tournaments) {
          await _write(t);
        }
      });
  @override
  Future<void> delete(String id) async {
    await (db.delete(db.tournamentRecords)..where((r) => r.id.equals(id))).go();
  }

  @override
  Future<void> deleteAll() async {
    await db.delete(db.tournamentRecords).go();
  }

  @override
  Future<void> archiveExpired(DateTime now) async {
    await (db.update(db.tournamentRecords)..where(
          (r) =>
              r.archived.equals(false) &
              r.created.isSmallerOrEqualValue(
                now.subtract(const Duration(days: 30)),
              ),
        ))
        .write(const TournamentRecordsCompanion(archived: Value(true)));
  }

  @override
  Future<String?> language() async => (await (db.select(
    db.preferences,
  )..where((p) => p.key.equals('language'))).getSingleOrNull())?.value;
  @override
  Future<void> setLanguage(String language) async {
    await db
        .into(db.preferences)
        .insertOnConflictUpdate(
          PreferencesCompanion.insert(key: 'language', value: language),
        );
  }

  @override
  Future<void> close() => db.close();
}
