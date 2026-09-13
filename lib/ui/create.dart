import 'package:flutter/material.dart';
import '../domain/engine.dart';
import '../domain/models.dart';
import '../services/tournament_service.dart';
import 'common.dart';

class CreateScreen extends StatefulWidget {
  final TournamentService service;
  const CreateScreen({super.key, required this.service});
  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  final name = TextEditingController();
  final fencer = TextEditingController();
  final seed = TextEditingController();
  final participants = <Participant>[];
  bool left = false, busy = false;
  int size = 6, serial = 0;
  String? error;
  @override
  void dispose() {
    name.dispose();
    fencer.dispose();
    seed.dispose();
    super.dispose();
  }

  void add() {
    final n = int.tryParse(seed.text.trim());
    if (fencer.text.trim().isEmpty ||
        fencer.text.trim().length > 100 ||
        (seed.text.trim().isNotEmpty && (n == null || n < 1 || n > 9999))) {
      setState(() => error = context.l.validation);
      return;
    }
    if (participants.length >= 128) return;
    setState(() {
      participants.add(
        Participant(
          'f${++serial}',
          fencer.text.trim(),
          leftHanded: left,
          seed: n,
        ),
      );
      fencer.clear();
      seed.clear();
      left = false;
      error = null;
    });
  }

  Future<void> create() async {
    if (name.text.trim().isEmpty || name.text.trim().length > 200) {
      setState(() => error = context.l.validation);
      return;
    }
    if (participants.length < 2) {
      setState(() => error = context.l.minimum);
      return;
    }
    setState(() => busy = true);
    try {
      final t = Tournament(
        id: 't${DateTime.now().microsecondsSinceEpoch}',
        name: name.text.trim(),
        created: DateTime.now(),
        participants: List.of(participants),
      );
      TournamentEngine.addPoolRound(t, size);
      await widget.service.save(t);
      if (mounted) Navigator.pop(context, t);
    } catch (e) {
      if (mounted) {
        setState(() {
          error = '${context.l.error}: $e';
          busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Scaffold(
      appBar: AppBar(title: Text(l.newTournament)),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: AbsorbPointer(
            absorbing: busy,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  l.setup,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                Text(l.setupHint),
                const SizedBox(height: 28),
                Section(
                  title: l.name,
                  child: TextField(
                    controller: name,
                    maxLength: 200,
                    style: Theme.of(context).textTheme.titleLarge,
                    decoration: InputDecoration(labelText: l.name),
                  ),
                ),
                const SizedBox(height: 20),
                Section(
                  title: '${l.participants} · ${participants.length}',
                  child: Column(
                    children: [
                      TextField(
                        controller: fencer,
                        maxLength: 100,
                        decoration: InputDecoration(
                          labelText: l.participantName,
                        ),
                        onSubmitted: (_) => add(),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<bool>(
                              key: ValueKey(left),
                              initialValue: left,
                              decoration: InputDecoration(labelText: l.hand),
                              items: [
                                DropdownMenuItem(
                                  value: false,
                                  child: Text(l.right),
                                ),
                                DropdownMenuItem(
                                  value: true,
                                  child: Text(l.left),
                                ),
                              ],
                              onChanged: (v) =>
                                  setState(() => left = v ?? false),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: seed,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(labelText: l.seed),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: participants.length < 128 ? add : null,
                          icon: const Icon(Icons.add),
                          label: Text(l.add),
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (final p in participants)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: paper,
                            child: Text('${participants.indexOf(p) + 1}'),
                          ),
                          title: Text(p.displayName(participants)),
                          subtitle: Text(
                            '${p.leftHanded ? l.left : l.right}${p.seed == null ? '' : ' · #${p.seed}'}',
                          ),
                          trailing: IconButton(
                            tooltip: l.remove,
                            onPressed: () =>
                                setState(() => participants.remove(p)),
                            icon: const Icon(Icons.close),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<int>(
                  initialValue: size,
                  decoration: InputDecoration(labelText: l.poolSize),
                  items: [
                    for (var n = 3; n <= 12; n++)
                      DropdownMenuItem(value: n, child: Text('$n')),
                  ],
                  onChanged: (v) => setState(() => size = v!),
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: busy ? null : create,
                  icon: busy
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_forward),
                  label: Text(l.create),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
