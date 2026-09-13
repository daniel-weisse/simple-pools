import 'dart:convert';
import 'dart:typed_data';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_pools/data/database.dart';
import 'package:simple_pools/data/repository.dart';
import 'package:simple_pools/domain/backup.dart';
import 'package:simple_pools/domain/models.dart';
import 'package:simple_pools/l10n/app_localizations.dart';
import 'package:simple_pools/services/files.dart';
import 'package:simple_pools/services/tournament_service.dart';
import 'package:simple_pools/ui/app.dart';
import 'engine_test.dart' as fixtures;

class MemoryFiles implements FileService {
  String? source;
  String? filename;
  Uint8List? exported;

  @override
  Future<String?> importJson() async => source;

  @override
  Future<void> export(
    String filename,
    Uint8List bytes,
    String extension,
  ) async {
    this.filename = filename;
    exported = bytes;
    expect(extension, 'json');
  }
}

Tournament tournament(String id) => Tournament.fromJson({
  ...fixtures.tournament(4).toJson(),
  'id': id,
  'name': id,
  'created': DateTime.now().toUtc().toIso8601String(),
});

Future<void> mount(
  WidgetTester tester,
  DriftTournamentRepository repo,
  MemoryFiles files,
) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: HomeScreen(
        service: TournamentService(repo),
        setLocale: (_) async {},
        fileService: files,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> menuAction(WidgetTester tester, String label) async {
  await tester.tap(find.byTooltip('Menu'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  // A pending transfer displays an indeterminate progress indicator.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  late DriftTournamentRepository repo;
  late MemoryFiles files;
  setUp(() {
    repo = DriftTournamentRepository(AppDatabase(NativeDatabase.memory()));
    files = MemoryFiles();
  });
  tearDown(() => repo.close());

  testWidgets('main menu exports only the selected archived tournament', (
    tester,
  ) async {
    final selected = tournament('Archived')..archived = true;
    await repo.save(selected);
    await repo.save(tournament('Other'));
    await mount(tester, repo, files);
    await menuAction(tester, 'Export tournament backup');
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Archived'),
      ),
    );
    await tester.pumpAndSettle();
    expect(files.filename, 'simple-pools-Archived.json');
    expect(
      Backup.decode(utf8.decode(files.exported!)).single.toJson(),
      selected.toJson(),
    );
    expect((await repo.all()).length, 2);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'import cancellation preserves data and confirmation replaces only its match',
    (tester) async {
      final original = tournament('Existing');
      final other = tournament('Other');
      await repo.save(original);
      await repo.save(other);
      final updated = original.copy()..name = 'Imported name';
      files.source = Backup.encode([updated]);
      await mount(tester, repo, files);
      await menuAction(tester, 'Import tournament');
      expect(find.textContaining('same ID will be replaced'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(
        (await repo.all()).firstWhere((t) => t.id == original.id).name,
        original.name,
      );
      await menuAction(tester, 'Import tournament');
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      final saved = await repo.all();
      expect(saved.length, 2);
      expect(
        saved.firstWhere((t) => t.id == original.id).toJson(),
        updated.toJson(),
      );
      expect(
        saved.firstWhere((t) => t.id == other.id).toJson(),
        other.toJson(),
      );
      expect(find.text('Imported name'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'empty history imports one tournament and rejects invalid or multi-tournament files',
    (tester) async {
      await mount(tester, repo, files);
      for (final source in [
        null,
        'invalid JSON',
        Backup.encode([]),
        Backup.encode([tournament('One'), tournament('Two')]),
      ]) {
        files.source = source;
        await menuAction(tester, 'Import tournament');
        await tester.pumpAndSettle();
        expect(await repo.all(), isEmpty);
        expect(find.byType(AlertDialog), findsNothing);
      }
      files.source = Backup.encode([tournament('New')]);
      await menuAction(tester, 'Import tournament');
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect((await repo.all()).single.name, 'New');
      expect(find.text('New'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
