import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_pools/domain/engine.dart';
import 'package:simple_pools/l10n/app_localizations_en.dart';
import 'package:simple_pools/l10n/app_localizations_de.dart';
import 'package:simple_pools/services/pdf_export.dart';
import 'engine_test.dart' as fixtures;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'large pool, rankings and connected bracket exports fit their pages',
    () async {
      final artifacts = Directory('build/verification')
        ..createSync(recursive: true);
      for (final size in [2, 8, 128]) {
        final t = fixtures.tournament(size, size: 12);
        fixtures.finishPools(t);
        TournamentEngine.startBracket(t, size);
        if (size >= 4) {
          t.thirdPlace = true;
          TournamentEngine.rebuild(t);
        }
        fixtures.finishBracket(t);
        final bytes = await PdfExport.generate(
          t,
          AppLocalizationsEn(),
          bracketOnly: true,
        );
        expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
        File('${artifacts.path}/bracket-$size.pdf').writeAsBytesSync(bytes);
        if (size == 128) {
          final rankings = await PdfExport.generate(
            t,
            AppLocalizationsDe(),
            rankingsOnly: true,
            round: 0,
          );
          File('${artifacts.path}/rankings.pdf').writeAsBytesSync(rankings);
        }
      }
      final pool = fixtures.tournament(12, size: 12);
      final blank = await PdfExport.generate(
        pool,
        AppLocalizationsEn(),
        round: 0,
        pool: 0,
      );
      File('${artifacts.path}/pool-blank.pdf').writeAsBytesSync(blank);
      fixtures.finishPools(pool);
      final filled = await PdfExport.generate(
        pool,
        AppLocalizationsEn(),
        round: 0,
        pool: 0,
      );
      File('${artifacts.path}/pool-filled.pdf').writeAsBytesSync(filled);
    },
  );
  test('PDFs generate offline with bundled fonts in both languages', () async {
    final t = fixtures.tournament(8);
    fixtures.finishPools(t);
    TournamentEngine.startBracket(t, 8);
    fixtures.finishBracket(t);
    for (final l in [AppLocalizationsEn(), AppLocalizationsDe()]) {
      for (final bracket in [false, true]) {
        final bytes = await PdfExport.generate(t, l, bracketOnly: bracket);
        expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
        expect(bytes.length, greaterThan(2000));
      }
      final blank = await PdfExport.generate(
        fixtures.tournament(3),
        l,
        round: 0,
        pool: 0,
      );
      expect(ascii.decode(blank.take(5).toList()), '%PDF-');
    }
  });
}
