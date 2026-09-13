import 'dart:convert';
import 'engine.dart';
import 'models.dart';

class Backup {
  static const formatVersion = 1;
  static String encode(List<Tournament> tournaments) =>
      const JsonEncoder.withIndent('  ').convert({
        'format': 'simple-pools',
        'version': formatVersion,
        'tournaments': tournaments.map((t) => t.toJson()).toList(),
      });
  static List<Tournament> decode(String source) {
    if (source.length > 20 * 1024 * 1024) {
      throw const FormatException('Backup exceeds 20 MB');
    }
    try {
      final j = jsonDecode(source) as Map<String, dynamic>;
      if (j['format'] != 'simple-pools' ||
          j['version'] != formatVersion ||
          (j['tournaments'] as List).length > 1000) {
        throw const FormatException('Unsupported backup');
      }
      final tournaments = (j['tournaments'] as List)
          .map((t) => Tournament.fromJson(Map<String, dynamic>.from(t as Map)))
          .toList();
      final ids = <String>{};
      for (final t in tournaments) {
        if (!ids.add(t.id)) throw const FormatException('Duplicate tournament');
        validate(t);
      }
      return tournaments;
    } catch (e) {
      throw FormatException('Invalid simple-pools backup: $e');
    }
  }

  static void validate(Tournament t) {
    bool validId(String id) => RegExp(r'^[a-zA-Z0-9_-]{1,100}$').hasMatch(id);
    if (!validId(t.id) ||
        t.name.trim().isEmpty ||
        t.name.length > 200 ||
        t.participants.length < 2 ||
        t.participants.length > 128 ||
        t.rounds.isEmpty ||
        t.rounds.length > 20) {
      throw const FormatException('Invalid tournament');
    }
    final ids = <String>{};
    for (final p in t.participants) {
      if (!validId(p.id) ||
          !ids.add(p.id) ||
          p.name.trim().isEmpty ||
          p.name.length > 100 ||
          (p.seed != null && (p.seed! < 1 || p.seed! > 9999))) {
        throw const FormatException('Invalid participant');
      }
    }
    for (final r in t.rounds) {
      if (r.size < 3 || r.size > 12) {
        throw const FormatException('Invalid pool size');
      }
    }
    if (t.bracketSize != null &&
        (t.bracketSize! < 2 ||
            t.bracketSize! > TournamentEngine.nextPower(ids.length) ||
            t.bracketSize! & (t.bracketSize! - 1) != 0 ||
            t.endedAtPools)) {
      throw const FormatException('Invalid bracket size');
    }
    if (t.thirdPlace && (t.bracketSize == null || t.bracketSize! < 4)) {
      throw const FormatException('Invalid bronze bout');
    }
    for (final order in t.tieOrders.values) {
      if (order.length < 2 ||
          order.toSet().length != order.length ||
          !ids.containsAll(order)) {
        throw const FormatException('Invalid tie resolution');
      }
    }
    final boutIds = <String>{};
    for (final b in t.bouts) {
      if (!boutIds.add(b.id) ||
          (b.a != null && !ids.contains(b.a)) ||
          (b.b != null && !ids.contains(b.b)) ||
          (b.sa == null) != (b.sb == null)) {
        throw const FormatException('Invalid bout');
      }
      if (b.scored) {
        if (b.a == null || b.b == null || b.a == b.b || b.bye) {
          throw const FormatException('Invalid scored bout');
        }
        TournamentEngine.validateScore(b.sa!, b.sb!);
      }
    }
    final canonical = t.copy();
    TournamentEngine.rebuild(canonical);
    if (jsonEncode(canonical.rounds.map((r) => r.toJson()).toList()) !=
            jsonEncode(t.rounds.map((r) => r.toJson()).toList()) ||
        jsonEncode(
              canonical.bracket
                  .map((r) => r.map((b) => b.toJson()).toList())
                  .toList(),
            ) !=
            jsonEncode(
              t.bracket.map((r) => r.map((b) => b.toJson()).toList()).toList(),
            ) ||
        jsonEncode(canonical.bronze?.toJson()) !=
            jsonEncode(t.bronze?.toJson())) {
      throw const FormatException('Inconsistent tournament dependencies');
    }
  }
}
