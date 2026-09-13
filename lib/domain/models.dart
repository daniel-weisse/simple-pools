import 'dart:convert';

class Participant {
  final String id;
  final String name;
  final bool leftHanded;
  final int? seed;
  const Participant(this.id, this.name, {this.leftHanded = false, this.seed});

  String displayName(List<Participant> participants) {
    final matches = participants.indexed
        .where((entry) => entry.$2.name == name)
        .toList();
    if (matches.length < 2) return name;
    // Lower seeds rank first. Equal or missing seeds retain entry order.
    matches.sort((a, b) {
      final order = (a.$2.seed ?? 0x7fffffff).compareTo(
        b.$2.seed ?? 0x7fffffff,
      );
      return order == 0 ? a.$1.compareTo(b.$1) : order;
    });
    final number = matches.indexWhere((entry) => entry.$2.id == id) + 1;
    return '$name ($number)';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'left': leftHanded,
    'seed': seed,
  };
  factory Participant.fromJson(Map<String, dynamic> j) => Participant(
    j['id'] as String,
    j['name'] as String,
    leftHanded: j['left'] as bool,
    seed: j['seed'] as int?,
  );
}

class Bout {
  final String id;
  final String? a;
  final String? b;
  int? sa;
  int? sb;
  final bool bye;
  final bool rest;
  Bout(
    this.id,
    this.a,
    this.b, {
    this.sa,
    this.sb,
    this.bye = false,
    this.rest = false,
  });
  bool get scored => sa != null && sb != null;
  bool get complete => scored || bye;
  String? get winner => scored
      ? (sa! > sb! ? a : b)
      : bye
      ? a ?? b
      : null;
  String? get loser => scored ? (sa! > sb! ? b : a) : null;
  Map<String, dynamic> toJson() => {
    'id': id,
    'a': a,
    'b': b,
    'sa': sa,
    'sb': sb,
    'bye': bye,
    'rest': rest,
  };
  factory Bout.fromJson(Map<String, dynamic> j) => Bout(
    j['id'] as String,
    j['a'] as String?,
    j['b'] as String?,
    sa: j['sa'] as int?,
    sb: j['sb'] as int?,
    bye: j['bye'] as bool,
    rest: j['rest'] as bool,
  );
}

class Pool {
  final List<String> members;
  final List<Bout> bouts;
  Pool(this.members, this.bouts);
  Map<String, dynamic> toJson() => {
    'members': members,
    'bouts': bouts.map((b) => b.toJson()).toList(),
  };
  factory Pool.fromJson(Map<String, dynamic> j) => Pool(
    List<String>.from(j['members'] as List),
    (j['bouts'] as List)
        .map((b) => Bout.fromJson(Map<String, dynamic>.from(b as Map)))
        .toList(),
  );
}

class PoolRound {
  final int size;
  List<Pool> pools;
  PoolRound(this.size, this.pools);
  bool get complete =>
      pools.isNotEmpty &&
      pools.every(
        (p) => p.members.length >= 2 && p.bouts.every((b) => b.complete),
      );
  Map<String, dynamic> toJson() => {
    'size': size,
    'pools': pools.map((p) => p.toJson()).toList(),
  };
  factory PoolRound.fromJson(Map<String, dynamic> j) => PoolRound(
    j['size'] as int,
    (j['pools'] as List)
        .map((p) => Pool.fromJson(Map<String, dynamic>.from(p as Map)))
        .toList(),
  );
}

class Tournament {
  final String id;
  String name;
  final DateTime created;
  bool archived;
  final List<Participant> participants;
  List<PoolRound> rounds;
  int? bracketSize;
  List<List<Bout>> bracket;
  bool thirdPlace;
  Bout? bronze;
  bool endedAtPools;
  Map<String, List<String>> tieOrders;
  Tournament({
    required this.id,
    required this.name,
    required this.created,
    required this.participants,
    this.archived = false,
    List<PoolRound>? rounds,
    this.bracketSize,
    List<List<Bout>>? bracket,
    this.thirdPlace = false,
    this.bronze,
    this.endedAtPools = false,
    Map<String, List<String>>? tieOrders,
  }) : rounds = rounds ?? [],
       bracket = bracket ?? [],
       tieOrders = tieOrders ?? {};
  Iterable<Bout> get bouts sync* {
    for (final r in rounds) {
      for (final p in r.pools) {
        yield* p.bouts;
      }
    }
    for (final r in bracket) {
      yield* r;
    }
    if (bronze != null) yield bronze!;
  }

  String label(String? id) => id == null
      ? '-'
      : participants.firstWhere((p) => p.id == id).displayName(participants);
  Tournament copy() => Tournament.fromJson(
    jsonDecode(jsonEncode(toJson())) as Map<String, dynamic>,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'created': created.toUtc().toIso8601String(),
    'archived': archived,
    'participants': participants.map((p) => p.toJson()).toList(),
    'rounds': rounds.map((r) => r.toJson()).toList(),
    'bracketSize': bracketSize,
    'bracket': bracket.map((r) => r.map((b) => b.toJson()).toList()).toList(),
    'thirdPlace': thirdPlace,
    'bronze': bronze?.toJson(),
    'endedAtPools': endedAtPools,
    'tieOrders': tieOrders,
  };
  factory Tournament.fromJson(Map<String, dynamic> j) => Tournament(
    id: j['id'] as String,
    name: j['name'] as String,
    created: DateTime.parse(j['created'] as String),
    archived: j['archived'] as bool,
    participants: (j['participants'] as List)
        .map((p) => Participant.fromJson(Map<String, dynamic>.from(p as Map)))
        .toList(),
    rounds: (j['rounds'] as List)
        .map((r) => PoolRound.fromJson(Map<String, dynamic>.from(r as Map)))
        .toList(),
    bracketSize: j['bracketSize'] as int?,
    bracket: (j['bracket'] as List)
        .map(
          (r) => (r as List)
              .map((b) => Bout.fromJson(Map<String, dynamic>.from(b as Map)))
              .toList(),
        )
        .toList(),
    thirdPlace: j['thirdPlace'] as bool,
    bronze: j['bronze'] == null
        ? null
        : Bout.fromJson(Map<String, dynamic>.from(j['bronze'] as Map)),
    endedAtPools: j['endedAtPools'] as bool,
    tieOrders: (j['tieOrders'] as Map).map(
      (k, v) => MapEntry(k as String, List<String>.from(v as List)),
    ),
  );
}

class Standing {
  final Participant participant;
  int wins = 0, hitsFor = 0, hitsAgainst = 0;
  Standing(this.participant);
  int get difference => hitsFor - hitsAgainst;
}

class Ranking {
  final List<Standing> rows;
  final Map<String, List<String>> unresolved;
  Ranking(this.rows, this.unresolved);
  bool get resolved => unresolved.isEmpty;
}
