import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_pools/domain/backup.dart';
import 'package:simple_pools/domain/engine.dart';
import 'package:simple_pools/domain/models.dart';

Tournament tournament(int n, {int size = 6, bool seeded = true}) {
  final t = Tournament(
    id: 'test',
    name: 'Club championship',
    created: DateTime.utc(2026, 1, 1),
    participants: [
      for (var i = 0; i < n; i++)
        Participant('f$i', 'Fencer $i', seed: seeded ? i + 1 : null),
    ],
  );
  TournamentEngine.addPoolRound(t, size);
  return t;
}

void finishPools(Tournament t) {
  for (final p in t.rounds.last.pools) {
    for (final b in p.bouts) {
      b.sa = 5;
      b.sb = 1;
    }
  }
  final ties = TournamentEngine.ranking(t).unresolved;
  t.tieOrders.addAll(ties.map((k, v) => MapEntry(k, List.of(v))));
}

void finishBracket(Tournament t) {
  for (var r = 0; r < t.bracket.length; r++) {
    for (final b in t.bracket[r]) {
      if (!b.bye) {
        b.sa = 15;
        b.sb = 4;
      }
    }
    TournamentEngine.rebuild(t);
  }
  if (t.bronze != null) {
    t.bronze!.sa = 15;
    t.bronze!.sb = 9;
  }
}

void main() {
  test('equal pre-seeds retain entry order across platforms', () {
    final t = tournament(48, seeded: false);
    expect(TournamentEngine.initialOrder(t), t.participants.map((p) => p.id));
  });
  test('a new pool tie preserves knockout bouts with known participants', () {
    final t = tournament(8, size: 12, seeded: false);
    finishPools(t);
    TournamentEngine.startBracket(t, 8);
    finishBracket(t);
    final b = t.bouts.firstWhere((b) => b.a == 'f0' && b.b == 'f2');
    final next = TournamentEngine.corrected(t, b.id, 1, 5);
    expect(TournamentEngine.ranking(next).resolved, false);
    expect(next.bracket.first[1].a, 'f3');
    expect(next.bracket.first[1].b, 'f4');
    expect(next.bracket.first[1].scored, true);
    expect(next.bracket.first.first.scored, false);
    expect(TournamentEngine.winner(next), isNull);
    Backup.validate(next);
  });
  test('all supported pool assignments are balanced and complete', () {
    for (var n = 2; n <= 128; n++) {
      for (var size = 3; size <= 12; size++) {
        final groups = TournamentEngine.pools(
          [for (var i = 0; i < n; i++) '$i'],
          size,
          0,
        );
        final counts = groups.map((p) => p.members.length).toList()..sort();
        expect(counts.last - counts.first, lessThanOrEqualTo(1));
        expect(counts.last, lessThanOrEqualTo(size));
        expect(groups.expand((p) => p.members).toSet().length, n);
      }
    }
  });
  test('snake seeding distributes the highest ranks across pools', () {
    final groups = TournamentEngine.pools(
      [for (var i = 1; i <= 12; i++) '$i'],
      6,
      0,
    );
    expect(groups[0].members, ['1', '4', '5', '8', '9', '12']);
    expect(groups[1].members, ['2', '3', '6', '7', '10', '11']);
  });
  test('every pair occurs once and rest markers match actual conflicts', () {
    for (var n = 2; n <= 12; n++) {
      final bouts = TournamentEngine.schedule([
        for (var i = 0; i < n; i++) '$i',
      ], 'p');
      expect(bouts.length, n * (n - 1) ~/ 2);
      expect(bouts.map((b) => '${b.a}/${b.b}').toSet().length, bouts.length);
      var rests = 0;
      for (var i = 1; i < bouts.length; i++) {
        final previous = bouts[i - 1], current = bouts[i];
        final conflict = [
          previous.a,
          previous.b,
        ].any((id) => id == current.a || id == current.b);
        expect(current.rest, conflict);
        if (conflict) rests++;
      }
      if (n == 3) expect(rests, 2);
      if (n == 4) expect(rests, 2);
      if (n >= 5) expect(rests, 0, reason: 'Pool size $n');
    }
  });
  test('wins, then hit difference, then pre-seed determine ranking', () {
    final t = tournament(3);
    for (final b in t.bouts) {
      b.sa = 5;
      b.sb = 0;
    }
    final rank = TournamentEngine.ranking(t);
    expect(rank.rows.map((r) => r.wins), [2, 1, 0]);
    expect(rank.rows.map((r) => r.difference), [10, 0, -10]);
    expect(rank.resolved, true);
  });
  test('unseeded ties require an explicit order. Pre-seeds break ties', () {
    final t = tournament(3, seeded: false);
    for (final b in t.bouts) {
      final cyclicWin =
          (b.a == 'f0' && b.b == 'f1') || (b.a == 'f1' && b.b == 'f2');
      b.sa = cyclicWin ? 5 : 3;
      b.sb = cyclicWin ? 3 : 5;
    }
    final rank = TournamentEngine.ranking(t);
    expect(rank.unresolved.length, 1);
    expect(TournamentEngine.ready(t), false);
    t.tieOrders[rank.unresolved.keys.single] = ['f2', 'f1', 'f0'];
    expect(TournamentEngine.ranking(t).rows.first.participant.id, 'f2');
    expect(TournamentEngine.ready(t), true);
    final seeded = tournament(3);
    final zeroRank = TournamentEngine.ranking(seeded);
    expect(zeroRank.resolved, true);
    expect(zeroRank.rows.map((r) => r.participant.id), ['f0', 'f1', 'f2']);
  });
  test('second pool round uses first ranking and adds both rounds', () {
    final t = tournament(8, size: 4);
    finishPools(t);
    final before = TournamentEngine.ranking(
      t,
    ).rows.fold(0, (s, r) => s + r.wins);
    final first = TournamentEngine.ranking(t).rows.first.participant.id;
    TournamentEngine.addPoolRound(t, 4);
    expect(t.rounds.last.pools.first.members.first, first);
    finishPools(t);
    expect(
      TournamentEngine.ranking(t).rows.fold(0, (s, r) => s + r.wins),
      before * 2,
    );
  });
  test('standard seed positions keep top two apart until the final', () {
    expect(TournamentEngine.seedPositions(8), [1, 8, 4, 5, 2, 7, 3, 6]);
    for (final size in [2, 4, 8, 16, 32, 64, 128]) {
      final seeds = TournamentEngine.seedPositions(size);
      expect(seeds.toSet().length, size);
      for (var i = 0; i < size; i += 2) {
        expect(seeds[i] + seeds[i + 1], size + 1);
      }
    }
  });
  test('byes go to top ranks and smaller brackets eliminate bottom ranks', () {
    final t = tournament(6);
    finishPools(t);
    final ranked = TournamentEngine.ranking(t).rows;
    TournamentEngine.startBracket(t, 8);
    expect(
      t.bracket.first.where((b) => b.bye).map((b) => b.winner).toSet(),
      ranked.take(2).map((r) => r.participant.id).toSet(),
    );
    finishBracket(t);
    expect(TournamentEngine.winner(t), isNotNull);
    expect(TournamentEngine.finalPlaces(t).length, 6);
    final small = tournament(6);
    finishPools(small);
    TournamentEngine.startBracket(small, 4);
    expect(
      small.bracket.first.expand((b) => [b.a, b.b]).toSet(),
      TournamentEngine.ranking(
        small,
      ).rows.take(4).map((r) => r.participant.id).toSet(),
    );
    finishBracket(small);
    expect(TournamentEngine.finalPlaces(small).length, 6);
  });
  test(
    'correction propagates to final and bronze while preserving unaffected scores',
    () {
      final t = tournament(8);
      finishPools(t);
      TournamentEngine.startBracket(t, 8);
      t.thirdPlace = true;
      TournamentEngine.rebuild(t);
      finishBracket(t);
      final corrected = TournamentEngine.corrected(t, 'k1.1', 2, 15);
      expect(TournamentEngine.cleared(t, corrected, except: 'k1.1').toSet(), {
        'k2.1',
        'k3.1',
        'bronze',
      });
      expect(corrected.bracket[1][1].scored, true);
      expect(TournamentEngine.winner(corrected), isNull);
      expect(TournamentEngine.finalPlaces(corrected), isEmpty);
      expect(
        t.bracket.last.single.scored,
        true,
        reason: 'Preview must not mutate original',
      );
      final sameWinner = TournamentEngine.corrected(t, 'k1.1', 15, 8);
      expect(TournamentEngine.cleared(t, sameWinner), isEmpty);
      expect(TournamentEngine.winner(sameWinner), TournamentEngine.winner(t));
    },
  );
  test(
    'semifinal loser change invalidates bronze even if final winner stays',
    () {
      final t = tournament(4);
      finishPools(t);
      TournamentEngine.startBracket(t, 4);
      t.thirdPlace = true;
      TournamentEngine.rebuild(t);
      finishBracket(t);
      final corrected = TournamentEngine.corrected(t, 'k1.2', 2, 15);
      expect(corrected.bronze!.scored, false);
      expect(corrected.bracket.last.single.scored, false);
    },
  );
  test('pool corrections reseed later pools and knockouts', () {
    final t = tournament(8, size: 4);
    finishPools(t);
    TournamentEngine.addPoolRound(t, 4);
    finishPools(t);
    TournamentEngine.startBracket(t, 8);
    finishBracket(t);
    final b = t.rounds.first.pools.first.bouts.first;
    final next = TournamentEngine.corrected(t, b.id, 0, 99);
    expect(
      TournamentEngine.cleared(t, next).where((id) => id.startsWith('p2')),
      isNotEmpty,
    );
    expect(
      TournamentEngine.cleared(t, next).where((id) => id.startsWith('k')),
      isNotEmpty,
    );
    expect(TournamentEngine.winner(next), isNull);
    Backup.validate(next);
  });
  test('pool-only winner becomes pending after an unresolved correction', () {
    final t = tournament(3, seeded: false);
    finishPools(t);
    t.endedAtPools = true;
    expect(TournamentEngine.winner(t), isNotNull);
    final b = t.bouts.firstWhere((b) => b.a == 'f0' && b.b == 'f2');
    final next = TournamentEngine.corrected(t, b.id, 1, 5);
    expect(TournamentEngine.winner(next), isNull);
  });
  test(
    'backup round trip preserves completed tournaments and rejects corrupt data',
    () {
      final t = tournament(7);
      finishPools(t);
      TournamentEngine.startBracket(t, 8);
      finishBracket(t);
      expect(Backup.decode(Backup.encode([t])).single.toJson(), t.toJson());
      final j = jsonDecode(Backup.encode([t])) as Map<String, dynamic>;
      expect(j['format'], 'simple-pools');
      j['format'] = 'open-pools';
      expect(() => Backup.decode(jsonEncode(j)), throwsFormatException);
      j['format'] = 'unknown';
      expect(() => Backup.decode(jsonEncode(j)), throwsFormatException);
      j['format'] = 'simple-pools';
      j['version'] = 999;
      expect(() => Backup.decode(jsonEncode(j)), throwsFormatException);
      expect(() => Backup.decode(Backup.encode([t, t])), throwsFormatException);
      final broken = t.copy();
      broken.bracket.last.single.sa = -1;
      expect(
        () => Backup.decode(Backup.encode([broken])),
        throwsFormatException,
      );
      final wrong = t.copy();
      wrong.rounds.first.pools.first.members.removeLast();
      expect(
        () => Backup.decode(Backup.encode([wrong])),
        throwsFormatException,
      );
      expect(() => Backup.decode('{'), throwsFormatException);
    },
  );
  test('draws and invalid scores cannot enter the state', () {
    final t = tournament(3);
    for (final scores in [(5, 5), (-1, 3), (1000, 2)]) {
      expect(
        () => TournamentEngine.corrected(
          t,
          t.bouts.first.id,
          scores.$1,
          scores.$2,
        ),
        throwsArgumentError,
      );
    }
  });
}
