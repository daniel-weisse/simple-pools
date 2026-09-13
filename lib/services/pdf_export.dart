import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../domain/engine.dart';
import '../domain/bracket_layout.dart';
import 'pdf_bracket.dart';
import '../domain/models.dart';
import '../l10n/app_localizations.dart';

class PdfExport {
  static Future<Uint8List> generate(
    Tournament t,
    AppLocalizations l, {
    int? round,
    int? pool,
    bool bracketOnly = false,
    bool rankingsOnly = false,
  }) async {
    final font = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Inter-Regular.ttf'),
    );
    final document = pw.Document(
      title: t.name,
      author: 'Simple Pools',
      theme: pw.ThemeData.withFont(base: font, bold: font),
    );
    pw.Widget title(String subtitle) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(t.name, style: const pw.TextStyle(fontSize: 24)),
        pw.SizedBox(height: 8),
        pw.Text(subtitle),
        pw.Divider(),
      ],
    );
    pw.Widget table(List<String> headers, List<List<String>> data) =>
        pw.TableHelper.fromTextArray(
          headers: headers,
          data: data,
          headerDecoration: const pw.BoxDecoration(color: PdfColors.green50),
          cellStyle: const pw.TextStyle(fontSize: 9),
          headerStyle: const pw.TextStyle(fontSize: 9),
          cellPadding: const pw.EdgeInsets.all(6),
        );
    pw.Widget ranking(int r) {
      final rank = TournamentEngine.ranking(t, through: r);
      return table(
        [l.rank, l.fencer, l.wins, l.hitsFor, l.hitsAgainst, l.difference],
        [
          for (var i = 0; i < rank.rows.length; i++)
            [
              rank.unresolved.values.any(
                    (ids) => ids.contains(rank.rows[i].participant.id),
                  )
                  ? l.tied
                  : '${i + 1}',
              t.label(rank.rows[i].participant.id),
              '${rank.rows[i].wins}',
              '${rank.rows[i].hitsFor}',
              '${rank.rows[i].hitsAgainst}',
              '${rank.rows[i].difference}',
            ],
        ],
      );
    }

    if (rankingsOnly) {
      for (var r = 0; r < t.rounds.length; r++) {
        if (round != null && round != r) continue;
        document.addPage(
          pw.MultiPage(
            header: (_) => title('${l.rankings} - ${l.round} ${r + 1}'),
            build: (_) => [ranking(r)],
          ),
        );
      }
    }
    if (!bracketOnly && !rankingsOnly) {
      for (var r = 0; r < t.rounds.length; r++) {
        if (round != null && round != r) continue;
        for (var p = 0; p < t.rounds[r].pools.length; p++) {
          if (pool != null && pool != p) continue;
          final current = t.rounds[r].pools[p];
          document.addPage(
            pw.MultiPage(
              maxPages: 200,
              header: (_) => title('${l.round} ${r + 1} · ${l.pool} ${p + 1}'),
              build: (_) => [
                poolMatrix(t, current, l),
                pw.SizedBox(height: 16),
                table(
                  [l.fencer, l.hand, l.seedColumn],
                  [
                    for (final id in current.members)
                      [
                        t.label(id),
                        t.participants.firstWhere((p) => p.id == id).leftHanded
                            ? l.left
                            : l.right,
                        t.participants
                                .firstWhere((p) => p.id == id)
                                .seed
                                ?.toString() ??
                            '-',
                      ],
                  ],
                ),
                pw.SizedBox(height: 16),
                table(
                  [l.bout, l.fencer, l.result, l.fencer],
                  [
                    for (var i = 0; i < current.bouts.length; i++)
                      [
                        '${i + 1}',
                        t.label(current.bouts[i].a),
                        current.bouts[i].scored
                            ? '${current.bouts[i].sa} : ${current.bouts[i].sb}'
                            : '',
                        t.label(current.bouts[i].b),
                      ],
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Text('${l.rankings} · ${l.round} ${r + 1}'),
                pw.SizedBox(height: 8),
                ranking(r),
              ],
            ),
          );
        }
      }
    }
    if (!rankingsOnly &&
        round == null &&
        pool == null &&
        t.bracket.isNotEmpty) {
      final layout = BracketLayout(t.bracket);
      const scale = .7;
      final graphHeight = layout.height + (t.bronze == null ? 0 : 160);
      document.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(
            layout.width * scale + 48,
            graphHeight * scale + 130,
          ),
          margin: const pw.EdgeInsets.all(24),
          build: (_) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              title(l.bracket),
              pw.SizedBox(height: 12),
              pw.SizedBox(
                width: layout.width * scale,
                height: graphHeight * scale,
                child: pw.FittedBox(child: pdfBracket(t, l, layout)),
              ),
            ],
          ),
        ),
      );
    }
    final finalPlaces = TournamentEngine.finalPlaces(t);
    if (finalPlaces.isNotEmpty &&
        round == null &&
        !rankingsOnly &&
        !bracketOnly) {
      document.addPage(
        pw.MultiPage(
          header: (_) => title(l.finalRanking),
          build: (_) => [
            table(
              [l.rank, l.fencer],
              [
                for (final p in finalPlaces) ['${p.$1}', t.label(p.$2)],
              ],
            ),
          ],
        ),
      );
    }
    if (document.document.pdfPageList.pages.isEmpty) {
      document.addPage(pw.Page(build: (_) => title(l.pending)));
    }
    return document.save();
  }
}
