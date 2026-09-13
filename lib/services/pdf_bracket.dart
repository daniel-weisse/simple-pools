import 'dart:math' as math;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../domain/bracket_layout.dart';
import '../domain/models.dart';
import '../l10n/app_localizations.dart';

pw.Widget pdfBracket(Tournament t, AppLocalizations l, BracketLayout layout) {
  pw.Widget line(double x, double y, double width, double height) =>
      pw.Positioned(
        left: x,
        top: y,
        child: pw.Container(
          width: math.max(1, width),
          height: math.max(1, height),
          color: PdfColors.green800,
        ),
      );
  pw.Widget card(Bout b) => pw.Container(
    width: BracketLayout.cardWidth,
    height: BracketLayout.cardHeight,
    padding: const pw.EdgeInsets.all(10),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey400),
      borderRadius: pw.BorderRadius.circular(10),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          b.bye ? '${b.id} · ${l.bye}' : b.id,
          style: const pw.TextStyle(fontSize: 11, color: PdfColors.green800),
        ),
        for (final entry in [(b.a, b.sa), (b.b, b.sb)])
          pw.Expanded(
            child: pw.Row(
              children: [
                pw.Flexible(
                  child: pw.Text(
                    t.label(entry.$1),
                    maxLines: 1,
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: entry.$1 != null && b.winner == entry.$1
                          ? pw.FontWeight.bold
                          : pw.FontWeight.normal,
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Text(
                  entry.$2?.toString() ?? '',
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
      ],
    ),
  );
  return pw.SizedBox(
    width: layout.width,
    height: layout.height + (t.bronze == null ? 0 : 160),
    child: pw.Stack(
      children: [
        for (var r = 0; r < t.bracket.length; r++) ...[
          pw.Positioned(
            left: layout.x(r),
            top: 0,
            child: pw.Text('${l.round} ${r + 1} · ${t.bracket[r].length * 2}'),
          ),
          for (var i = 0; i < t.bracket[r].length; i++) ...[
            pw.Positioned(
              left: layout.x(r),
              top: layout.top(r, i),
              child: card(t.bracket[r][i]),
            ),
            line(
              layout.x(r) + BracketLayout.cardWidth,
              layout.centerY(r, i),
              BracketLayout.gap - 12,
              1,
            ),
            if (r + 1 < t.bracket.length) ...[
              line(
                layout.x(r + 1) - 12,
                math.min(layout.centerY(r, i), layout.centerY(r + 1, i ~/ 2)),
                1,
                (layout.centerY(r, i) - layout.centerY(r + 1, i ~/ 2)).abs(),
              ),
              line(layout.x(r + 1) - 12, layout.centerY(r + 1, i ~/ 2), 12, 1),
            ],
            if (t.bracket[r][i].winner != null)
              pw.Positioned(
                left: layout.x(r) + BracketLayout.cardWidth + 4,
                top: layout.centerY(r, i) - 32,
                child: pw.SizedBox(
                  width: BracketLayout.gap - 12,
                  child: pw.Text(
                    t.label(t.bracket[r][i].winner),
                    maxLines: 2,
                    style: const pw.TextStyle(
                      fontSize: 11,
                      color: PdfColors.green800,
                    ),
                  ),
                ),
              ),
          ],
        ],
        if (t.bronze != null) ...[
          pw.Positioned(
            left: 0,
            top: layout.height + 12,
            child: pw.Text(l.bronze),
          ),
          pw.Positioned(
            left: 0,
            top: layout.height + 40,
            child: card(t.bronze!),
          ),
        ],
      ],
    ),
  );
}

pw.Widget poolMatrix(Tournament t, Pool pool, AppLocalizations l) {
  final stats = {
    for (final id in pool.members)
      id: Standing(t.participants.firstWhere((p) => p.id == id)),
  };
  for (final b in pool.bouts.where((b) => b.scored)) {
    stats[b.a]!.hitsFor += b.sa!;
    stats[b.a]!.hitsAgainst += b.sb!;
    stats[b.b]!.hitsFor += b.sb!;
    stats[b.b]!.hitsAgainst += b.sa!;
    stats[b.winner]!.wins++;
  }
  String cell(String a, String b) {
    if (a == b) return '';
    final bout = pool.bouts.firstWhere(
      (m) => (m.a == a && m.b == b) || (m.a == b && m.b == a),
    );
    return bout.scored ? '${bout.a == a ? bout.sa : bout.sb}' : '';
  }

  return pw.TableHelper.fromTextArray(
    headers: [
      l.fencer,
      for (var i = 0; i < pool.members.length; i++) '${i + 1}',
      l.wins,
      l.hitsFor,
      l.hitsAgainst,
      l.difference,
    ],
    data: [
      for (var i = 0; i < pool.members.length; i++)
        [
          '${i + 1}. ${t.label(pool.members[i])}',
          for (final opponent in pool.members) cell(pool.members[i], opponent),
          '${stats[pool.members[i]]!.wins}',
          '${stats[pool.members[i]]!.hitsFor}',
          '${stats[pool.members[i]]!.hitsAgainst}',
          '${stats[pool.members[i]]!.difference}',
        ],
    ],
    columnWidths: {0: const pw.FlexColumnWidth(4)},
    border: pw.TableBorder.all(color: PdfColors.grey400),
    headerDecoration: const pw.BoxDecoration(color: PdfColors.green50),
    cellStyle: const pw.TextStyle(fontSize: 8),
    headerStyle: const pw.TextStyle(fontSize: 8),
    cellPadding: const pw.EdgeInsets.all(4),
    // The header occupies row zero; opponent columns start at column one.
    cellDecoration: (column, value, row) => column == row
        ? const pw.BoxDecoration(color: PdfColors.black)
        : const pw.BoxDecoration(),
  );
}
