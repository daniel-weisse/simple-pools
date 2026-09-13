import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_pools/data/database.dart';
import 'package:simple_pools/data/repository.dart';
import 'package:simple_pools/domain/engine.dart';
import 'engine_test.dart' as fixtures;

void main() {
  test(
    'SQLite survives close and reopen, including locale and archiving boundary',
    () async {
      final dir = await Directory.systemTemp.createTemp('simple-pools-test');
      final file = File('${dir.path}/test.sqlite');
      var repo = DriftTournamentRepository(AppDatabase(NativeDatabase(file)));
      final t = fixtures.tournament(4);
      await repo.save(t);
      await repo.setLanguage('de');
      await repo.close();
      repo = DriftTournamentRepository(AppDatabase(NativeDatabase(file)));
      expect((await repo.all()).single.toJson(), t.toJson());
      expect(await repo.language(), 'de');
      await repo.archiveExpired(
        t.created.add(const Duration(days: 29, hours: 23)),
      );
      expect((await repo.all()).single.archived, false);
      await repo.archiveExpired(t.created.add(const Duration(days: 30)));
      expect((await repo.all()).single.archived, true);
      await repo.delete(t.id);
      expect(await repo.all(), isEmpty);
      await repo.close();
      await dir.delete(recursive: true);
    },
  );
  test(
    'correction and dependency invalidation are persisted atomically',
    () async {
      final repo = DriftTournamentRepository(
        AppDatabase(NativeDatabase.memory()),
      );
      final t = fixtures.tournament(4);
      fixtures.finishPools(t);
      TournamentEngine.startBracket(t, 4);
      fixtures.finishBracket(t);
      await repo.save(t);
      final next = TournamentEngine.corrected(t, 'k1.1', 1, 15);
      await repo.save(next);
      final read = (await repo.all()).single;
      expect(read.bracket.first.first.winner, next.bracket.first.first.winner);
      expect(read.bracket.last.single.scored, false);
      expect(TournamentEngine.winner(read), isNull);
      await repo.close();
    },
  );
  test('a failed import transaction rolls back every preceding write', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final repo = DriftTournamentRepository(db);
    final t = fixtures.tournament(3);
    await repo.save(t);
    await db.customStatement(
      "CREATE TRIGGER reject_bad BEFORE INSERT ON tournament_records WHEN NEW.name = 'reject' BEGIN SELECT RAISE(ABORT, 'test failure'); END",
    );
    final changed = t.copy()..name = 'changed';
    final rejected = t.copy()..name = 'reject';
    await expectLater(repo.importAll([changed, rejected]), throwsA(anything));
    expect((await repo.all()).single.name, t.name);
    await repo.deleteAll();
    expect(await repo.all(), isEmpty);
    await repo.close();
  });
}
