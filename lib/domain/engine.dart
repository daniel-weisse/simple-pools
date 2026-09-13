import 'dart:math';
import 'models.dart';

class TournamentEngine {
  static void validateScore(int a, int b) {
    if (a < 0 || b < 0 || a > 999 || b > 999 || a == b) {
      throw ArgumentError('Scores must be different integers from 0 to 999.');
    }
  }

  static List<Pool> pools(List<String> ranked, int size, int round) {
    if (size < 3 || size > 12 || ranked.length < 2) {
      throw ArgumentError('Invalid pool size or participants');
    }
    final count = (ranked.length / size).ceil();
    final groups = List.generate(count, (_) => <String>[]);
    for (var i = 0; i < ranked.length; i++) {
      final row = i ~/ count;
      groups[row.isEven ? i % count : count - 1 - i % count].add(ranked[i]);
    }
    return [
      for (var i = 0; i < groups.length; i++)
        Pool(groups[i], schedule(groups[i], 'p${round + 1}.${i + 1}')),
    ];
  }

  // Multi-start minimum-conflict scheduling. Small pools use exhaustive search;
  // larger pools normally admit a zero-conflict schedule (the global minimum).
  static List<Bout> schedule(List<String> ids, String prefix) {
    final pairs = <(int, int)>[
      for (var a = 0; a < ids.length; a++)
        for (var b = a + 1; b < ids.length; b++) (a, b),
    ];
    bool overlap(int a, int b) =>
        pairs[a].$1 == pairs[b].$1 ||
        pairs[a].$1 == pairs[b].$2 ||
        pairs[a].$2 == pairs[b].$1 ||
        pairs[a].$2 == pairs[b].$2;
    var best = List.generate(pairs.length, (i) => i);
    var bestCost = pairs.length;
    final random = Random(ids.length);
    for (var attempt = 0; attempt < 120 && bestCost > 0; attempt++) {
      final remaining = List.generate(pairs.length, (i) => i)..shuffle(random);
      final order = <int>[];
      var cost = 0;
      while (remaining.isNotEmpty) {
        var index = order.isEmpty
            ? 0
            : remaining.indexWhere((i) => !overlap(order.last, i));
        if (index < 0) {
          index = 0;
          cost++;
        }
        order.add(remaining.removeAt(index));
      }
      if (cost < bestCost) {
        bestCost = cost;
        best = order;
      }
    }
    if (ids.length <= 4 && bestCost > 0) {
      void search(List<int> order, Set<int> left, int cost) {
        if (cost >= bestCost) return;
        if (left.isEmpty) {
          best = List.of(order);
          bestCost = cost;
          return;
        }
        for (final i in left) {
          search(
            [...order, i],
            {...left}..remove(i),
            cost + (order.isNotEmpty && overlap(order.last, i) ? 1 : 0),
          );
        }
      }

      search([], best.toSet(), 0);
    }
    return [
      for (var i = 0; i < best.length; i++)
        Bout(
          '$prefix.${i + 1}',
          ids[pairs[best[i]].$1],
          ids[pairs[best[i]].$2],
          rest: i > 0 && overlap(best[i - 1], best[i]),
        ),
    ];
  }

  static Ranking ranking(Tournament t, {int? through}) {
    final rows = {for (final p in t.participants) p.id: Standing(p)};
    final end = through ?? t.rounds.length - 1;
    for (var i = 0; i <= end; i++) {
      for (final p in t.rounds[i].pools) {
        for (final b in p.bouts.where((b) => b.scored)) {
          rows[b.a]!.hitsFor += b.sa!;
          rows[b.a]!.hitsAgainst += b.sb!;
          rows[b.b]!.hitsFor += b.sb!;
          rows[b.b]!.hitsAgainst += b.sa!;
          rows[b.winner]!.wins++;
        }
      }
    }
    int compare(Standing a, Standing b) {
      var c = b.wins.compareTo(a.wins);
      if (c == 0) c = b.difference.compareTo(a.difference);
      if (c == 0) {
        c = (a.participant.seed ?? 0x7fffffff).compareTo(
          b.participant.seed ?? 0x7fffffff,
        );
      }
      return c;
    }

    final sorted = rows.values.toList()
      ..sort((a, b) {
        final c = compare(a, b);
        return c == 0 ? a.participant.id.compareTo(b.participant.id) : c;
      });
    final unresolved = <String, List<String>>{};
    for (var start = 0; start < sorted.length;) {
      var stop = start + 1;
      while (stop < sorted.length &&
          compare(sorted[start], sorted[stop]) == 0) {
        stop++;
      }
      if (stop - start > 1) {
        final ids =
            sorted.sublist(start, stop).map((r) => r.participant.id).toList()
              ..sort();
        final key =
            '$end:${sorted[start].wins}:${sorted[start].difference}:${ids.join(",")}';
        final order = t.tieOrders[key];
        if (order != null &&
            order.length == ids.length &&
            order.toSet().containsAll(ids)) {
          final group = sorted.sublist(start, stop)
            ..sort(
              (a, b) => order
                  .indexOf(a.participant.id)
                  .compareTo(order.indexOf(b.participant.id)),
            );
          sorted.replaceRange(start, stop, group);
        } else {
          unresolved[key] = ids;
        }
      }
      start = stop;
    }
    return Ranking(sorted, unresolved);
  }

  static List<String> initialOrder(Tournament t) {
    final positions = {
      for (var i = 0; i < t.participants.length; i++) t.participants[i].id: i,
    };
    final ordered = List<Participant>.of(t.participants)
      ..sort((a, b) {
        final result = (a.seed ?? 0x7fffffff).compareTo(b.seed ?? 0x7fffffff);
        return result == 0
            ? positions[a.id]!.compareTo(positions[b.id]!)
            : result;
      });
    return ordered.map((p) => p.id).toList();
  }

  static bool ready(Tournament t) =>
      t.rounds.isNotEmpty &&
      t.rounds.every((r) => r.complete) &&
      ranking(t).resolved;
  static void addPoolRound(Tournament t, int size) {
    if (t.bracketSize != null ||
        t.endedAtPools ||
        (t.rounds.isNotEmpty && !ready(t))) {
      throw StateError('Finish pools and resolve ties first');
    }
    t.rounds.add(
      PoolRound(
        size,
        pools(
          t.rounds.isEmpty
              ? initialOrder(t)
              : ranking(t).rows.map((r) => r.participant.id).toList(),
          size,
          t.rounds.length,
        ),
      ),
    );
  }

  static int nextPower(int n) {
    var size = 2;
    while (size < n) {
      size *= 2;
    }
    return size;
  }

  static List<int> seedPositions(int size) {
    var seeds = [1, 2];
    while (seeds.length < size) {
      final sum = seeds.length * 2 + 1;
      seeds = [
        for (final s in seeds) ...[s, sum - s],
      ];
    }
    return seeds;
  }

  static void startBracket(Tournament t, int size) {
    if (!ready(t) ||
        t.endedAtPools ||
        t.bracketSize != null ||
        size < 2 ||
        size > nextPower(t.participants.length) ||
        size & (size - 1) != 0) {
      throw StateError('Invalid bracket');
    }
    t.bracketSize = size;
    rebuild(t);
  }

  // Replay dependencies in topological order. Retain a result only if the two
  // occupants of its slot are unchanged. Call on a copy before committing.
  static void rebuild(Tournament t) {
    final old = {for (final b in t.bouts) b.id: b};
    Bout keep(Bout fresh) {
      final previous = old[fresh.id];
      if (previous != null &&
          previous.a == fresh.a &&
          previous.b == fresh.b &&
          !fresh.bye) {
        fresh.sa = previous.sa;
        fresh.sb = previous.sb;
      }
      return fresh;
    }

    for (var i = 0; i < t.rounds.length; i++) {
      final available = i == 0 || t.rounds.take(i).every((r) => r.complete);
      final uncertain = i == 0
          ? <String>{}
          : ranking(
              t,
              through: i - 1,
            ).unresolved.values.expand((ids) => ids).toSet();
      final ids = i == 0
          ? initialOrder(t)
          : ranking(
              t,
              through: i - 1,
            ).rows.map((r) => r.participant.id).toList();
      t.rounds[i].pools = available
          ? pools(ids, t.rounds[i].size, i)
                .map(
                  (p) => p.members.any(uncertain.contains)
                      ? Pool([], [])
                      : Pool(p.members, p.bouts.map(keep).toList()),
                )
                .toList()
          : [];
    }
    if (t.bracketSize == null) return;
    final size = t.bracketSize!;
    final entrants = t.rounds.every((r) => r.complete)
        ? ranking(t).rows.take(size).map((r) => r.participant.id).toList()
        : <String>[];
    final uncertain = ranking(t).unresolved.values.expand((ids) => ids).toSet();
    final positions = seedPositions(size);
    t.bracket = [];
    for (var n = size ~/ 2, round = 0; n >= 1; n ~/= 2, round++) {
      final matches = <Bout>[];
      for (var i = 0; i < n; i++) {
        String? a, b;
        var bye = false;
        if (round == 0) {
          a = positions[2 * i] <= entrants.length
              ? entrants[positions[2 * i] - 1]
              : null;
          b = positions[2 * i + 1] <= entrants.length
              ? entrants[positions[2 * i + 1] - 1]
              : null;
          bye = entrants.isNotEmpty && (a == null || b == null);
          if (uncertain.contains(a)) a = null;
          if (uncertain.contains(b)) b = null;
          if (a == null && b == null) bye = false;
        } else {
          a = t.bracket[round - 1][2 * i].winner;
          b = t.bracket[round - 1][2 * i + 1].winner;
        }
        matches.add(keep(Bout('k${round + 1}.${i + 1}', a, b, bye: bye)));
      }
      t.bracket.add(matches);
    }
    t.bronze = t.thirdPlace && t.bracket.length >= 2
        ? keep(
            Bout(
              'bronze',
              t.bracket[t.bracket.length - 2][0].loser,
              t.bracket[t.bracket.length - 2][1].loser,
            ),
          )
        : null;
  }

  static Tournament corrected(Tournament source, String id, int a, int b) {
    validateScore(a, b);
    final t = source.copy();
    final bout = t.bouts.firstWhere((b) => b.id == id);
    if (bout.a == null || bout.b == null || bout.bye) {
      throw StateError('Bout is not ready');
    }
    bout.sa = a;
    bout.sb = b;
    rebuild(t);
    return t;
  }

  static List<String> cleared(
    Tournament before,
    Tournament after, {
    String? except,
  }) {
    final next = {for (final b in after.bouts) b.id: b};
    return before.bouts
        .where(
          (b) =>
              b.id != except &&
              b.scored &&
              (next[b.id] == null || !next[b.id]!.scored),
        )
        .map((b) => b.id)
        .toList();
  }

  static String? winner(Tournament t) {
    if (!ready(t)) return null;
    if (t.endedAtPools) return ranking(t).rows.first.participant.id;
    if (t.bracket.isEmpty || (t.thirdPlace && t.bronze?.complete != true)) {
      return null;
    }
    return t.bracket.last.single.winner;
  }

  static List<(int, String)> finalPlaces(Tournament t) {
    if (winner(t) == null) return [];
    final seeds = ranking(t).rows.map((r) => r.participant.id).toList();
    if (t.endedAtPools) {
      return [for (var i = 0; i < seeds.length; i++) (i + 1, seeds[i])];
    }
    final places = <(int, String)>[
      (1, t.bracket.last.single.winner!),
      (2, t.bracket.last.single.loser!),
    ];
    for (var r = t.bracket.length - 2; r >= 0; r--) {
      final losers =
          t.bracket[r].map((b) => b.loser).whereType<String>().toList()
            ..sort((a, b) => seeds.indexOf(a).compareTo(seeds.indexOf(b)));
      for (final id in losers) {
        places.add((
          r == t.bracket.length - 2 && t.thirdPlace
              ? (id == t.bronze!.winner ? 3 : 4)
              : t.bracket[r].length + 1,
          id,
        ));
      }
    }
    for (var i = t.bracketSize!; i < seeds.length; i++) {
      places.add((i + 1, seeds[i]));
    }
    places.sort((a, b) => a.$1.compareTo(b.$1));
    return places;
  }
}
