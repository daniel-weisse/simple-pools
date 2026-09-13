import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../domain/backup.dart';
import '../domain/engine.dart';
import '../domain/models.dart';
import '../l10n/app_localizations.dart';
import '../services/files.dart';
import '../services/tournament_service.dart';
import 'common.dart';
import 'create.dart';
import 'detail.dart';

class SimplePoolsApp extends StatefulWidget {
  final TournamentService service;
  const SimplePoolsApp({super.key, required this.service});
  @override
  State<SimplePoolsApp> createState() => _SimplePoolsAppState();
}

class _SimplePoolsAppState extends State<SimplePoolsApp> {
  Locale? locale;
  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    try {
      final code = await widget.service.repository.language();
      if (mounted && code != null) setState(() => locale = Locale(code));
    } catch (_) {
      /* Home presents storage errors. */
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Simple Pools',
    debugShowCheckedModeBanner: false,
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: paper,
      colorScheme: ColorScheme.fromSeed(
        seedColor: green,
        surface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: paper,
        foregroundColor: ink,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xffe1e6df)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: paper,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    ),
    home: HomeScreen(
      service: widget.service,
      setLocale: (code) async {
        await widget.service.repository.setLanguage(code);
        if (mounted) setState(() => locale = Locale(code));
      },
    ),
  );
}

class HomeScreen extends StatefulWidget {
  final TournamentService service;
  final Future<void> Function(String) setLocale;
  final FileService? fileService;
  const HomeScreen({
    super.key,
    required this.service,
    required this.setLocale,
    this.fileService,
  });
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  List<Tournament>? tournaments;
  Object? error;
  int page = 0;
  bool busy = false;
  bool pinCreateButton = true;
  final historyContentKey = GlobalKey();
  late final FileService files = widget.fileService ?? LocalFileService();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    reload();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) reload();
  }

  Future<void> reload() async {
    try {
      final list = await widget.service.load();
      if (mounted) {
        setState(() {
          tournaments = list;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = e);
    }
  }

  Future<void> run(Future<void> Function() action) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await action();
      await reload();
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

  Future<void> open(Tournament t) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) =>
            TournamentScreen(tournament: t, service: widget.service),
      ),
    );
    await reload();
  }

  Future<void> create() async {
    final t = await Navigator.push<Tournament>(
      context,
      MaterialPageRoute(builder: (_) => CreateScreen(service: widget.service)),
    );
    if (t != null && mounted) await open(t);
    await reload();
  }

  Future<void> restoreBackup() async {
    final source = await files.importJson();
    if (source == null) return;
    final imported = Backup.decode(source);
    if (!mounted) return;
    if (await confirmAction(
      context,
      context.l.importTitle,
      '${context.l.importHint}\n\n${context.l.importCount}: ${imported.length}',
    )) {
      await widget.service.restore(imported);
    }
  }

  Future<void> exportTournament(Tournament tournament) => files.export(
    'simple-pools-${tournament.id}.json',
    Uint8List.fromList(utf8.encode(Backup.encode([tournament]))),
    'json',
  );

  Future<void> chooseTournamentToExport() async {
    final selected = await showDialog<Tournament>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(c.l.exportTournament),
        content: SizedBox(
          width: 400,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final t in tournaments ?? <Tournament>[])
                ListTile(
                  title: Text(t.name),
                  subtitle: Text(
                    '${DateFormat.yMMMd(c.l.localeName).format(t.created.toLocal())}'
                    '${t.archived ? ' · ${c.l.archive}' : ''}',
                  ),
                  onTap: () => Navigator.pop(c, t),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text(c.l.cancel),
          ),
        ],
      ),
    );
    if (selected != null) await exportTournament(selected);
  }

  Future<void> importTournament() async {
    final source = await files.importJson();
    if (source == null || !mounted) return;
    final imported = Backup.decode(source);
    if (imported.length != 1) {
      throw FormatException(context.l.singleTournamentRequired);
    }
    if (await confirmAction(
      context,
      context.l.importTournament,
      '${imported.single.name}\n\n${context.l.importTournamentHint}',
    )) {
      await widget.service.restore(imported);
      await reload();
      if (!mounted) return;
      final saved = tournaments?.where((t) => t.id == imported.single.id);
      if (saved != null && saved.isNotEmpty) {
        setState(() => page = saved.first.archived ? 1 : 0);
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l.success)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Image(
              image: AssetImage('assets/icons/fencer.png'),
              width: 24,
              height: 24,
              excludeFromSemantics: true,
            ),
            SizedBox(width: 10),
            Text(
              'SIMPLE POOLS',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        actions: [
          Builder(
            builder: (c) => IconButton(
              tooltip: l.menu,
              onPressed: () => Scaffold.of(c).openEndDrawer(),
              icon: const Icon(Icons.menu),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      endDrawer: Drawer(
        shape: const RoundedRectangleBorder(),
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l.appName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              for (var i = 0; i < 3; i++)
                ListTile(
                  selected: page == i,
                  leading: Icon(
                    [
                      Icons.grid_view_rounded,
                      Icons.inventory_2_outlined,
                      Icons.tune,
                    ][i],
                  ),
                  title: Text([l.home, l.archive, l.options][i]),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => page = i);
                  },
                ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.download),
                title: Text(l.exportTournament),
                enabled: !busy && (tournaments?.isNotEmpty ?? false),
                onTap: () {
                  Navigator.pop(context);
                  run(chooseTournamentToExport);
                },
              ),
              ListTile(
                leading: const Icon(Icons.upload),
                title: Text(l.importTournament),
                enabled: !busy && tournaments != null,
                onTap: () {
                  Navigator.pop(context);
                  run(importTournament);
                },
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: AbsorbPointer(
          absorbing: busy,
          child: Column(
            children: [
              if (busy) const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(l.storageError),
                              const SizedBox(height: 12),
                              Text('$error'),
                              TextButton(
                                onPressed: reload,
                                child: Text(l.retry),
                              ),
                            ],
                          ),
                        ),
                      )
                    : tournaments == null
                    ? const Center(child: CircularProgressIndicator())
                    : Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1180),
                          child: page == 2 ? options() : history(),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar:
          page == 0 &&
              pinCreateButton &&
              (tournaments?.any((t) => !t.archived) ?? false)
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                child: newTournamentButton(),
              ),
            )
          : null,
    );
  }

  Widget newTournamentButton() => Center(
    heightFactor: 1,
    child: FilledButton.icon(
      onPressed: busy ? null : create,
      icon: const Icon(Icons.add),
      label: Text(context.l.newTournament),
    ),
  );

  Widget history() {
    final l = context.l;
    final list = tournaments!.where((t) => t.archived == (page == 1)).toList();
    final content = Column(
      key: historyContentKey,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (page == 1) ...[
          Text(l.archiveHint, style: const TextStyle(color: Color(0xff66766e))),
          const SizedBox(height: 20),
        ],
        Row(
          children: [
            Text(
              page == 0 ? l.home : l.archive,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(width: 12),
            StatusPill('${list.length}', complete: true),
          ],
        ),
        const SizedBox(height: 20),
        if (list.isEmpty && page == 0)
          OutlinedButton(
            onPressed: busy ? null : create,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 70, horizontal: 24),
              side: const BorderSide(color: Color(0xffd7dfd6)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Column(
              children: [
                const Icon(Icons.add, size: 64),
                const SizedBox(height: 24),
                Text(
                  l.newTournament,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          )
        else if (list.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 70, horizontal: 24),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xffd7dfd6)),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                const Icon(Icons.emoji_events_outlined, size: 64, color: green),
                const SizedBox(height: 24),
                Text(
                  l.archiveEmpty,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(l.archiveHint, textAlign: TextAlign.center),
              ],
            ),
          )
        else
          LayoutBuilder(
            builder: (c, constraints) {
              final columns = constraints.maxWidth >= 850
                  ? 3
                  : constraints.maxWidth >= 560
                  ? 2
                  : 1;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: list
                    .map(
                      (t) => SizedBox(
                        width:
                            (constraints.maxWidth - 16 * (columns - 1)) /
                            columns,
                        child: tournamentCard(t),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        const SizedBox(height: 24),
      ],
    );
    return LayoutBuilder(
      builder: (viewportContext, constraints) {
        if (page == 0 && list.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || !viewportContext.mounted || page != 0) return;
            final contentBox = historyContentKey.currentContext
                ?.findRenderObject();
            final viewportBox = viewportContext.findRenderObject();
            if (contentBox is! RenderBox || viewportBox is! RenderBox) return;
            // Use the unscrolled list height so scrolling cannot move the button.
            final buttonTop =
                viewportBox.localToGlobal(Offset.zero).dy +
                24 +
                contentBox.size.height;
            final shouldPin =
                buttonTop >= MediaQuery.sizeOf(context).height / 2;
            if (pinCreateButton != shouldPin) {
              setState(() => pinCreateButton = shouldPin);
            }
          });
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              content,
              if (page == 0 && list.isNotEmpty && !pinCreateButton)
                newTournamentButton(),
            ],
          ),
        );
      },
    );
  }

  Widget tournamentCard(Tournament t) {
    final l = context.l;
    final winner = TournamentEngine.winner(t);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => open(t),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  StatusPill(
                    winner == null ? l.inProgress : l.completed,
                    complete: winner != null,
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    onSelected: (action) => run(() async {
                      if (action == 'rename') {
                        final name = await editText(
                          context,
                          l.rename,
                          initial: t.name,
                        );
                        if (name != null) {
                          final copy = t.copy()..name = name;
                          await widget.service.save(copy);
                        }
                      } else if (action == 'export') {
                        await exportTournament(t);
                      } else if (action == 'delete') {
                        if (await confirmAction(
                          context,
                          l.delete,
                          l.deleteHint,
                        )) {
                          await widget.service.repository.delete(t.id);
                        }
                      } else {
                        final copy = t.copy()..archived = !t.archived;
                        await widget.service.save(copy);
                      }
                    }),
                    itemBuilder: (_) => [
                      PopupMenuItem(value: 'rename', child: Text(l.rename)),
                      PopupMenuItem(
                        value: 'export',
                        child: Text(l.exportTournament),
                      ),
                      if (!t.archived)
                        PopupMenuItem(
                          value: 'archive',
                          child: Text(l.archiveAction),
                        ),
                      if (t.archived)
                        PopupMenuItem(value: 'delete', child: Text(l.delete)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                t.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: ink,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '${t.participants.length} ${l.count}  ·  ${DateFormat.yMMMd(l.localeName).format(t.created.toLocal())}',
                style: const TextStyle(fontSize: 12, color: Color(0xff66766e)),
              ),
              const Divider(height: 32),
              Row(
                children: [
                  const Icon(
                    Icons.emoji_events_outlined,
                    size: 19,
                    color: green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      winner == null
                          ? '${l.winner}: ${l.pending}'
                          : t.label(winner),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget options() {
    final l = context.l;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(l.options, style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 28),
        Section(
          title: l.language,
          child: DropdownButtonFormField<String>(
            initialValue: Localizations.localeOf(context).languageCode,
            items: const [
              DropdownMenuItem(value: 'en', child: Text('English')),
              DropdownMenuItem(value: 'de', child: Text('Deutsch')),
            ],
            onChanged: (value) {
              if (value != null) run(() => widget.setLocale(value));
            },
          ),
        ),
        const SizedBox(height: 20),
        Section(
          title: l.backup,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.backupHint),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => run(
                      () async => files.export(
                        'simple-pools-backup.json',
                        Uint8List.fromList(
                          utf8.encode(Backup.encode(tournaments!)),
                        ),
                        'json',
                      ),
                    ),
                    icon: const Icon(Icons.download),
                    label: Text(l.exportJson),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => run(restoreBackup),
                    icon: const Icon(Icons.upload),
                    label: Text(l.importJson),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Section(
          title: l.deleteAll,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.deleteAllHint),
              const SizedBox(height: 16),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red.shade800,
                ),
                onPressed: () => run(() async {
                  if (await confirmAction(
                    context,
                    l.deleteAll,
                    l.deleteAllHint,
                  )) {
                    await widget.service.repository.deleteAll();
                  }
                }),
                icon: const Icon(Icons.delete_outline),
                label: Text(l.deleteAll),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
