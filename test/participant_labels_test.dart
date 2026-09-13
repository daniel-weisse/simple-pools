import 'package:flutter_test/flutter_test.dart';
import 'package:simple_pools/domain/backup.dart';
import 'package:simple_pools/domain/engine.dart';
import 'package:simple_pools/domain/models.dart';

Tournament tournament(List<Participant> participants) => Tournament(
  id: 'labels',
  name: 'Duplicate names',
  created: DateTime.utc(2026),
  participants: participants,
);

void main() {
  test('each exact name group is numbered from its highest pre-seed', () {
    final t = tournament([
      const Participant('a', 'Alex', seed: 9),
      const Participant('b', 'Sam', seed: 5),
      const Participant('c', 'Alex', seed: 1),
      const Participant('d', 'Sam', seed: 2),
      const Participant('e', 'Alex', seed: 4),
      const Participant('f', 'alex', seed: 3),
      const Participant('g', 'Alex ', seed: 6),
      const Participant('h', 'Robin'),
    ]);

    expect(t.participants.map((p) => t.label(p.id)), [
      'Alex (3)',
      'Sam (2)',
      'Alex (1)',
      'Sam (1)',
      'Alex (2)',
      'alex',
      'Alex ',
      'Robin',
    ]);
    expect(t.label(null), '-');
  });

  test(
    'equal seeds use entry order and unseeded names follow seeded names',
    () {
      final t = tournament([
        const Participant('f2', 'Alex'),
        const Participant('f3', 'Alex', seed: 2),
        const Participant('f10', 'Alex'),
        const Participant('f11', 'Alex', seed: 2),
        const Participant('f12', 'Alex', seed: 9999),
      ]);

      expect(t.participants.map((p) => t.label(p.id)), [
        'Alex (4)',
        'Alex (1)',
        'Alex (5)',
        'Alex (2)',
        'Alex (3)',
      ]);
    },
  );

  test('adding and removing duplicate names updates setup labels', () {
    final participants = [const Participant('first', 'Alex', seed: 5)];
    expect(participants.first.displayName(participants), 'Alex');
    participants.add(const Participant('second', 'Alex', seed: 1));
    expect(participants.first.displayName(participants), 'Alex (2)');
    expect(participants.last.displayName(participants), 'Alex (1)');
    participants.removeLast();
    expect(participants.first.displayName(participants), 'Alex');
    expect(participants.first.name, 'Alex');
  });

  test(
    'labels survive results, copies and backups without renaming participants',
    () {
      final t = tournament([
        const Participant('first', 'Alex', seed: 1),
        const Participant('second', 'Alex', seed: 2),
      ]);
      TournamentEngine.addPoolRound(t, 3);
      final bout = t.bouts.single;
      bout.sa = bout.a == 'second' ? 5 : 1;
      bout.sb = bout.b == 'second' ? 5 : 1;
      expect(TournamentEngine.ranking(t).rows.first.participant.id, 'second');
      TournamentEngine.startBracket(t, 2);

      for (final saved in [
        t,
        t.copy(),
        Backup.decode(Backup.encode([t])).single,
      ]) {
        expect(saved.label('first'), 'Alex (1)');
        expect(saved.label('second'), 'Alex (2)');
        expect(saved.participants.map((p) => p.name), ['Alex', 'Alex']);
      }
    },
  );
}
