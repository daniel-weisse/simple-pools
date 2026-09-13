import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../domain/bracket_layout.dart';
import 'bracket_graph.dart';
import 'package:printing/printing.dart';
import '../domain/backup.dart';
import '../domain/engine.dart';
import '../domain/models.dart';
import '../services/files.dart';
import '../services/pdf_export.dart';
import '../services/tournament_service.dart';
import 'common.dart';

class TournamentScreen extends StatefulWidget {
  final Tournament tournament;
  final TournamentService service;
  const TournamentScreen({
    super.key,
    required this.tournament,
    required this.service,
  });
  @override
  State<TournamentScreen> createState() => _TournamentScreenState();
}

class _TournamentScreenState extends State<TournamentScreen> {
  late Tournament t = widget.tournament.copy();
  bool busy = false;
  final files = LocalFileService();
  Future<void> run(Future<void> Function() action) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${context.l.error}: $e')));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> commit(Tournament next, {String? edited}) async {
    final cleared = TournamentEngine.cleared(t, next, except: edited);
    if (cleared.isNotEmpty) {
      final names = cleared
          .map((id) {
            final b = t.bouts.firstWhere((b) => b.id == id);
            return '$id · ${t.label(b.a)} / ${t.label(b.b)}';
          })
          .join('\n');
      if (!await confirmAction(
        context,
        context.l.correctionTitle,
        '${context.l.correctionBody}\n\n$names',
        action: context.l.clearResults,
      )) {
        return;
      }
    }
    await widget.service.save(next);
    if (mounted) setState(() => t = next);
  }

  Future<void> score(Bout b) async {
    final scores = await showDialog<(int, int)>(
      context: context,
      builder: (_) => ScoreDialog(t: t, bout: b),
    );
    if (scores != null) {
      await commit(
        widget.service.previewScore(t, b.id, scores.$1, scores.$2),
        edited: b.id,
      );
    }
  }

  Future<int?> chooseSize(bool bracket) => showDialog<int>(
    context: context,
    builder: (c) => SimpleDialog(
      title: Text(bracket ? c.l.bracketSize : c.l.poolSize),
      children: [
        if (bracket)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(c.l.bracketHint),
          ),
        for (final n
            in bracket
                ? [
                    for (
                      var n = 2;
                      n <= TournamentEngine.nextPower(t.participants.length);
                      n *= 2
                    )
                      n,
                  ]
                : [for (var n = 3; n <= 12; n++) n])
          SimpleDialogOption(
            onPressed: () => Navigator.pop(c, n),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$n'),
                  if (bracket && n < t.participants.length)
                    Text(
                      c.l.eliminatedCount(t.participants.length - n),
                      style: Theme.of(c).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
  Future<void> resolve(int round) async {
    final rank = TournamentEngine.ranking(t, through: round);
    final orders = await showDialog<Map<String, List<String>>>(
      context: context,
      builder: (_) => TieDialog(t: t, groups: rank.unresolved),
    );
    if (orders != null) {
      final next = t.copy();
      next.tieOrders.addAll(orders);
      TournamentEngine.rebuild(next);
      await commit(next);
    }
  }

  Future<void> pdf({
    int? round,
    int? pool,
    bool bracket = false,
    bool rankings = false,
    bool print = false,
  }) async {
    final bytes = await PdfExport.generate(
      t,
      context.l,
      round: round,
      pool: pool,
      bracketOnly: bracket,
      rankingsOnly: rankings,
    );
    if (print && !kIsWeb) {
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: '${t.name}.pdf',
      );
    } else {
      await files.export('simple-pools-${t.id}.pdf', bytes, 'pdf');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final winner = TournamentEngine.winner(t);
    return DefaultTabController(
      length: winner == null ? 3 : 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(t.name),
          actions: [
            PopupMenuButton<String>(
              onSelected: (v) => run(() async {
                if (v == 'json') {
                  await files.export(
                    '${t.id}.json',
                    Uint8List.fromList(utf8.encode(Backup.encode([t]))),
                    'json',
                  );
                } else {
                  await pdf(print: v == 'print');
                }
              }),
              itemBuilder: (_) => [
                PopupMenuItem(value: 'pdf', child: Text(l.exportPdf)),
                if (!kIsWeb)
                  PopupMenuItem(value: 'print', child: Text(l.printPdf)),
                PopupMenuItem(value: 'json', child: Text(l.exportTournament)),
              ],
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: l.pools),
              Tab(text: l.rankings),
              Tab(text: l.bracket),
              if (winner != null) Tab(text: l.finalResults),
            ],
          ),
        ),
        body: Column(
          children: [
            if (busy) const LinearProgressIndicator(minHeight: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  StatusPill(
                    winner == null ? l.inProgress : l.completed,
                    complete: winner != null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      winner == null
                          ? '${t.participants.length} ${l.count}'
                          : '${l.winner}: ${t.label(winner)}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: AbsorbPointer(
                absorbing: busy,
                child: TabBarView(
                  children: [
                    poolView(),
                    rankingView(),
                    bracketView(),
                    if (winner != null) finalResultsView(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget poolView() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      for (var r = 0; r < t.rounds.length; r++) ...[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text(
            '${context.l.round} ${r + 1}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        if (t.rounds[r].pools.isEmpty) Text(context.l.roundPending),
        for (var p = 0; p < t.rounds[r].pools.length; p++)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: poolCard(r, p),
          ),
      ],
    ],
  );
  Widget poolCard(int r, int p) {
    final pool = t.rounds[r].pools[p];
    final l = context.l;
    if (pool.members.isEmpty) {
      return Section(title: '${l.pool} ${p + 1}', child: Text(l.roundPending));
    }
    return Card(
      child: ExpansionTile(
        initiallyExpanded: true,
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text('${l.pool} ${p + 1}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            exportButton(() => pdf(round: r, pool: p)),
            const Icon(Icons.expand_more),
          ],
        ),
        subtitle: Text(
          '${pool.bouts.where((b) => b.scored).length} / ${pool.bouts.length} · ${pool.members.map(t.label).join(", ")}',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              defaultColumnWidth: const IntrinsicColumnWidth(),
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              border: TableBorder.all(color: const Color(0xffd7dfd6)),
              children: [
                TableRow(
                  children: [
                    poolTableLabel(l.fencer),
                    for (var i = 0; i < pool.members.length; i++)
                      poolTableLabel('${i + 1}'),
                  ],
                ),
                for (var i = 0; i < pool.members.length; i++)
                  TableRow(
                    children: [
                      poolTableLabel('${i + 1}. ${t.label(pool.members[i])}'),
                      for (var j = 0; j < pool.members.length; j++)
                        matrixCell(pool, i, j),
                    ],
                  ),
              ],
            ),
          ),
          const Divider(),
          for (var i = 0; i < pool.bouts.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            boutTile(pool.bouts[i], number: i + 1),
          ],
        ],
      ),
    );
  }

  Widget poolTableLabel(String label) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    child: Text(label),
  );

  Widget matrixCell(Pool pool, int i, int j) {
    if (i == j) {
      return const TableCell(
        verticalAlignment: TableCellVerticalAlignment.fill,
        child: ColoredBox(color: Colors.black, child: SizedBox(width: 48)),
      );
    }
    final a = pool.members[i], b = pool.members[j];
    final bout = pool.bouts.firstWhere(
      (m) => (m.a == a && m.b == b) || (m.a == b && m.b == a),
    );
    return InkWell(
      onTap: () => run(() => score(bout)),
      child: poolTableLabel(
        bout.scored ? '${bout.a == a ? bout.sa : bout.sb}' : '-',
      ),
    );
  }

  Widget exportButton(Future<void> Function() action) => TextButton.icon(
    onPressed: () => run(action),
    icon: const Icon(Icons.picture_as_pdf_outlined),
    label: Text(context.l.exportPdf),
  );

  Widget boutTile(Bout b, {int? number}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          number == null ? context.l.bronze : '${context.l.bout} $number',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 480;
            final scores = [
              for (final value in [b.sa, b.sb])
                SizedBox(
                  width: 64,
                  child: OutlinedButton(
                    onPressed: b.a != null && b.b != null && !b.bye
                        ? () => run(() => score(b))
                        : null,
                    child: Text(value?.toString() ?? '+'),
                  ),
                ),
            ];
            if (wide) {
              return Row(
                children: [
                  Expanded(
                    child: Text(t.label(b.a), textAlign: TextAlign.right),
                  ),
                  const SizedBox(width: 12),
                  scores[0],
                  const SizedBox(width: 12),
                  scores[1],
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(t.label(b.b), textAlign: TextAlign.left),
                  ),
                ],
              );
            }
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Column(
                  children: [
                    Row(
                      children: [
                        for (final participant in [b.a, b.b])
                          Expanded(
                            child: Text(
                              t.label(participant),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        for (final score in scores)
                          Expanded(child: Center(child: score)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    ),
  );

  Widget finalResultsView() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Section(
        title: context.l.finalResults,
        child: Column(
          children: [
            for (final place in TournamentEngine.finalPlaces(t))
              ListTile(
                leading: Text(
                  '${place.$1}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                title: Text(t.label(place.$2)),
              ),
          ],
        ),
      ),
    ],
  );

  Widget rankingView() {
    final l = context.l;
    final ready = TournamentEngine.ready(t);
    final actionStyle = OutlinedButton.styleFrom(
      fixedSize: Size(
        min(300, MediaQuery.sizeOf(context).width - 40),
        max(56, MediaQuery.textScalerOf(context).scale(32) + 24),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        for (var r = 0; r < t.rounds.length; r++) ...[
          Section(
            title: '${l.rankings} · ${l.round} ${r + 1}',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: exportButton(() => pdf(round: r, rankings: true)),
                ),
                rankTable(r),
                const SizedBox(height: 12),
                if (t.rounds[r].complete &&
                    !TournamentEngine.ranking(t, through: r).resolved)
                  FilledButton.tonalIcon(
                    onPressed: () => run(() => resolve(r)),
                    icon: const Icon(Icons.swap_vert),
                    label: Text(l.resolveTies),
                  ),
                if (!t.rounds[r].complete) Text(l.poolProgress),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (t.bracketSize == null && !t.endedAtPools)
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton.icon(
                style: actionStyle,
                onPressed: ready
                    ? () => run(() async {
                        final size = await chooseSize(true);
                        if (size != null) {
                          final next = t.copy();
                          TournamentEngine.startBracket(next, size);
                          await commit(next);
                        }
                      })
                    : null,
                icon: const Icon(Icons.account_tree_outlined),
                label: Text(l.startBracket, textAlign: TextAlign.center),
              ),
              OutlinedButton(
                style: actionStyle,
                onPressed: ready && t.rounds.length < 20
                    ? () => run(() async {
                        final size = await chooseSize(false);
                        if (size != null) {
                          final next = t.copy();
                          TournamentEngine.addPoolRound(next, size);
                          await commit(next);
                        }
                      })
                    : null,
                child: Text(l.nextRound, textAlign: TextAlign.center),
              ),
              OutlinedButton(
                style: actionStyle,
                onPressed: ready
                    ? () => run(() async {
                        if (await confirmAction(
                          context,
                          l.endPools,
                          l.finishHint,
                        )) {
                          await commit(t.copy()..endedAtPools = true);
                        }
                      })
                    : null,
                child: Text(l.endPools, textAlign: TextAlign.center),
              ),
            ],
          ),
      ],
    );
  }

  Widget rankTable(int r) {
    final rank = TournamentEngine.ranking(t, through: r);
    final l = context.l;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 24,
        border: const TableBorder(
          verticalInside: BorderSide(color: Color(0xffd7dfd6)),
        ),
        columns: [
          for (final s in [
            l.rank,
            l.fencer,
            l.wins,
            l.hitsFor,
            l.hitsAgainst,
            l.difference,
          ])
            DataColumn(label: Text(s)),
        ],
        rows: [
          for (var i = 0; i < rank.rows.length; i++)
            DataRow(
              cells: [
                DataCell(
                  Text(
                    rank.unresolved.values.any(
                          (ids) => ids.contains(rank.rows[i].participant.id),
                        )
                        ? l.tied
                        : '${i + 1}',
                  ),
                ),
                DataCell(Text(t.label(rank.rows[i].participant.id))),
                DataCell(Text('${rank.rows[i].wins}')),
                DataCell(Text('${rank.rows[i].hitsFor}')),
                DataCell(Text('${rank.rows[i].hitsAgainst}')),
                DataCell(Text('${rank.rows[i].difference}')),
              ],
            ),
        ],
      ),
    );
  }

  Widget bracketView() {
    final l = context.l;
    if (t.bracket.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(l.noBracket, textAlign: TextAlign.center),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Wrap(
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            if (!t.thirdPlace &&
                t.bracket.length >= 2 &&
                t.bracket.last.single.a != null &&
                t.bracket.last.single.b != null)
              FilledButton.tonal(
                onPressed: () => run(() async {
                  final next = t.copy()..thirdPlace = true;
                  TournamentEngine.rebuild(next);
                  await commit(next);
                }),
                child: Text(l.thirdPlace),
              ),
            exportButton(() => pdf(bracket: true)),
          ],
        ),
        const SizedBox(height: 24),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: BracketGraph(
            t: t,
            layout: BracketLayout(t.bracket),
            onScore: (bout) => run(() => score(bout)),
          ),
        ),
        if (t.bronze != null)
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Section(title: l.bronze, child: boutTile(t.bronze!)),
          ),
      ],
    );
  }
}

class ScoreDialog extends StatefulWidget {
  final Tournament t;
  final Bout bout;
  const ScoreDialog({super.key, required this.t, required this.bout});
  @override
  State<ScoreDialog> createState() => _ScoreDialogState();
}

class _ScoreDialogState extends State<ScoreDialog> {
  late final a = TextEditingController(text: widget.bout.sa?.toString() ?? '');
  late final b = TextEditingController(text: widget.bout.sb?.toString() ?? '');
  bool invalid = false;
  @override
  void dispose() {
    a.dispose();
    b.dispose();
    super.dispose();
  }

  void submit() {
    final sa = int.tryParse(a.text), sb = int.tryParse(b.text);
    try {
      if (sa == null || sb == null) throw const FormatException();
      TournamentEngine.validateScore(sa, sb);
      Navigator.pop(context, (sa, sb));
    } catch (_) {
      setState(() => invalid = true);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.l.score),
    content: SizedBox(
      width: 400,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: a,
            textAlign: TextAlign.center,
            autofocus: true,
            keyboardType: TextInputType.number,
            maxLength: 3,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              counterText: '',
              labelText: widget.t.label(widget.bout.a),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: b,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 3,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onSubmitted: (_) => submit(),
            decoration: InputDecoration(
              counterText: '',
              labelText: widget.t.label(widget.bout.b),
            ),
          ),
          if (invalid)
            Text(
              context.l.scoreHint,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.l.cancel),
      ),
      FilledButton(onPressed: submit, child: Text(context.l.save)),
    ],
  );
}

class TieDialog extends StatefulWidget {
  final Tournament t;
  final Map<String, List<String>> groups;
  const TieDialog({super.key, required this.t, required this.groups});
  @override
  State<TieDialog> createState() => _TieDialogState();
}

class _TieDialogState extends State<TieDialog> {
  late final orders = widget.groups.map(
    (k, v) => MapEntry(k, List<String>.of(v)),
  );
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.l.resolveTies),
    content: SizedBox(
      width: 500,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.l.tiesHint),
            for (final group in orders.values) ...[
              const Divider(height: 32),
              for (var i = 0; i < group.length; i++)
                Row(
                  children: [
                    Expanded(
                      child: Text('${i + 1}. ${widget.t.label(group[i])}'),
                    ),
                    IconButton(
                      tooltip: context.l.moveUp,
                      onPressed: i > 0
                          ? () => setState(() {
                              final id = group.removeAt(i);
                              group.insert(i - 1, id);
                            })
                          : null,
                      icon: const Icon(Icons.arrow_upward),
                    ),
                    IconButton(
                      tooltip: context.l.moveDown,
                      onPressed: i < group.length - 1
                          ? () => setState(() {
                              final id = group.removeAt(i);
                              group.insert(i + 1, id);
                            })
                          : null,
                      icon: const Icon(Icons.arrow_downward),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.l.cancel),
      ),
      TextButton(
        onPressed: () => setState(() {
          for (final group in orders.values) {
            group.shuffle(Random.secure());
          }
        }),
        child: Text(context.l.randomize),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, orders),
        child: Text(context.l.applyOrder),
      ),
    ],
  );
}
