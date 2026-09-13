import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_pools/data/database.dart';
import 'package:simple_pools/data/repository.dart';
import 'package:simple_pools/domain/engine.dart';
import 'package:simple_pools/domain/models.dart';
import 'package:simple_pools/services/tournament_service.dart';
import 'package:simple_pools/ui/app.dart';
import 'package:simple_pools/ui/detail.dart';
import 'package:simple_pools/l10n/app_localizations.dart';
import 'engine_test.dart' as fixtures;

void main() {
  testWidgets('duplicate labels appear in pools, rankings and knockout cards', (
    tester,
  ) async {
    final repo = DriftTournamentRepository(
      AppDatabase(NativeDatabase.memory()),
    );
    addTearDown(repo.close);
    final t = Tournament(
      id: 'duplicates',
      name: 'Duplicate names',
      created: DateTime.utc(2026),
      participants: [
        const Participant('first', 'Alex', seed: 2),
        const Participant('second', 'Alex', seed: 1),
      ],
    );
    TournamentEngine.addPoolRound(t, 3);
    fixtures.finishPools(t);
    TournamentEngine.startBracket(t, 2);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TournamentScreen(tournament: t, service: TournamentService(repo)),
      ),
    );
    await tester.pumpAndSettle();
    for (final tab in ['Pools', 'Rankings', 'Knockout']) {
      await tester.tap(find.widgetWithText(Tab, tab));
      await tester.pumpAndSettle();
      expect(find.text('Alex (1)'), findsOneWidget);
      expect(find.text('Alex (2)'), findsOneWidget);
      expect(find.text('Alex'), findsNothing);
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'create button follows short lists and stays at the bottom of long lists',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = DriftTournamentRepository(
        AppDatabase(NativeDatabase.memory()),
      );
      addTearDown(repo.close);
      for (var i = 0; i < 3; i++) {
        await repo.save(
          Tournament.fromJson({
            ...fixtures.tournament(2).toJson(),
            'id': 'layout-$i',
            'name': 'Tournament $i',
            'created': DateTime.now().toUtc().toIso8601String(),
          }),
        );
      }
      await tester.pumpWidget(SimplePoolsApp(service: TournamentService(repo)));
      await tester.pumpAndSettle();
      final button = find.ancestor(
        of: find.text('Start new tournament'),
        matching: find.byWidgetPredicate((widget) => widget is FilledButton),
      );
      expect(button, findsOneWidget);
      final lastCard = find.ancestor(
        of: find.text('Tournament 2'),
        matching: find.byType(Card),
      );
      expect(
        tester.getTopLeft(button).dy,
        closeTo(tester.getBottomLeft(lastCard).dy + 24, 1),
      );
      expect(tester.getTopLeft(button).dy, lessThan(500));

      // Narrowing the window wraps the cards into a scrolling list.
      tester.view.physicalSize = const Size(390, 600);
      await tester.pumpAndSettle();
      expect(button.hitTestable(), findsOneWidget);
      final pinnedPosition = tester.getTopLeft(button);
      expect(tester.getBottomLeft(button).dy, closeTo(580, 1));
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -600),
      );
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(button), pinnedPosition);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'Tournament name'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'pool controls stay accessible on mobile and filter score input',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = DriftTournamentRepository(
        AppDatabase(NativeDatabase.memory()),
      );
      final t = fixtures.tournament(2);
      await repo.save(t);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: TournamentScreen(
            tournament: t,
            service: TournamentService(repo),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Bout 1'), findsOneWidget);
      expect(
        find.text(t.rounds.single.pools.single.bouts.single.id),
        findsNothing,
      );
      expect(find.text('Rest break before this bout'), findsNothing);
      expect(
        tester.widget<Table>(find.byType(Table)).border!.verticalInside.style,
        BorderStyle.solid,
      );
      await tester.tap(find.text('+').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.enterText(find.byType(TextField).first, 'a1b234');
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        '123',
      );
      expect(find.text('3/3'), findsNothing);
      await tester.enterText(find.byType(TextField).first, '5');
      await tester.enterText(find.byType(TextField).last, '2');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(
        (await repo.all()).single.rounds.single.pools.single.bouts.single.sa,
        5,
      );
      await tester.tap(find.text('Pool 1'));
      await tester.pumpAndSettle();
      expect(find.text('Bout 1'), findsNothing);
      expect(find.text('Export PDF').hitTestable(), findsOneWidget);
      await tester.tap(find.text('Rankings'));
      await tester.pumpAndSettle();
      expect(find.text('Export PDF'), findsOneWidget);
      await tester.ensureVisible(find.text('Finish with pool ranking'));
      await tester.tap(find.text('Finish with pool ranking'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(Tab, 'Final results'), findsOneWidget);
      await tester.ensureVisible(find.widgetWithText(Tab, 'Final results'));
      await tester.tap(find.widgetWithText(Tab, 'Final results'));
      await tester.pumpAndSettle();
      expect(find.text('Fencer 0'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await repo.close();
    },
  );

  testWidgets(
    'knockout cards accept results and reveal final results after the final',
    (tester) async {
      final repo = DriftTournamentRepository(
        AppDatabase(NativeDatabase.memory()),
      );
      final t = fixtures.tournament(2);
      fixtures.finishPools(t);
      TournamentEngine.startBracket(t, 2);
      await repo.save(t);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: TournamentScreen(
            tournament: t,
            service: TournamentService(repo),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.widgetWithText(Tab, 'Final results'), findsNothing);
      await tester.tap(find.text('Knockout'));
      await tester.pumpAndSettle();
      expect(find.text('Enter result'), findsNothing);
      await tester.tap(find.text('k1.1'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.enterText(find.byType(TextField).first, '15');
      await tester.enterText(find.byType(TextField).last, '7');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('15'), findsOneWidget);
      expect(find.text(t.label(t.bracket.single.single.a)), findsNWidgets(2));
      expect(find.widgetWithText(Tab, 'Final results'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await repo.close();
    },
  );

  testWidgets('smaller brackets show the number eliminated immediately', (
    tester,
  ) async {
    final repo = DriftTournamentRepository(
      AppDatabase(NativeDatabase.memory()),
    );
    final t = fixtures.tournament(6);
    fixtures.finishPools(t);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TournamentScreen(tournament: t, service: TournamentService(repo)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rankings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Start knockout'),
      200,
      scrollable: find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      ),
    );
    await tester.tap(find.text('Start knockout'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('4 participants eliminated immediately'), findsOneWidget);
    expect(find.text('2 participants eliminated immediately'), findsOneWidget);
    expect(find.text('0 participants eliminated immediately'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await repo.close();
  });
  testWidgets('mobile setup saves fencers, hand, seed and pool size', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = DriftTournamentRepository(
      AppDatabase(NativeDatabase.memory()),
    );
    await tester.pumpWidget(SimplePoolsApp(service: TournamentService(repo)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start new tournament'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Tournament name'),
      'Sunday foil',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Fencer’s name'),
      'Ada',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Pre-seed (optional)'),
      '1',
    );
    await tester.ensureVisible(find.text('Add fencer'));
    await tester.tap(find.text('Add fencer'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(TextField, 'Fencer’s name'));
    await tester.enterText(
      find.widgetWithText(TextField, 'Fencer’s name'),
      'Ada',
    );
    await tester.ensureVisible(find.text('Add fencer'));
    await tester.tap(find.text('Add fencer'));
    await tester.pumpAndSettle();
    expect(find.text('Ada (1)'), findsOneWidget);
    expect(find.text('Ada (2)'), findsOneWidget);
    await tester.ensureVisible(find.text('Create pools'));
    await tester.tap(find.text('Create pools'));
    await tester.pumpAndSettle();
    expect(find.text('Sunday foil'), findsOneWidget);
    expect((await repo.all()).single.participants.length, 2);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await repo.close();
  });
  testWidgets('German desktop history opens completed tournament and bracket', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = DriftTournamentRepository(
      AppDatabase(NativeDatabase.memory()),
    );
    final t = fixtures.tournament(8);
    fixtures.finishPools(t);
    TournamentEngine.startBracket(t, 8);
    fixtures.finishBracket(t);
    await repo.save(t);
    await repo.setLanguage('de');
    await tester.pumpWidget(SimplePoolsApp(service: TournamentService(repo)));
    await tester.pumpAndSettle();
    // Old fixture dates are automatically archived on launch.
    await tester.tap(find.byTooltip('Menü'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archiv'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.name));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Direktausscheidung'));
    await tester.pumpAndSettle();
    expect(find.text('k1.1'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await repo.close();
  });
}
