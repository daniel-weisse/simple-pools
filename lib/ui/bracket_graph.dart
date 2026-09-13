import 'package:flutter/material.dart';
import '../domain/bracket_layout.dart';
import '../domain/models.dart';
import 'common.dart';

class BracketGraph extends StatelessWidget {
  final Tournament t;
  final BracketLayout layout;
  final ValueChanged<Bout> onScore;
  const BracketGraph({
    super.key,
    required this.t,
    required this.layout,
    required this.onScore,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: layout.width,
    height: layout.height,
    child: Stack(
      children: [
        Positioned.fill(child: CustomPaint(painter: _BracketLines(layout))),
        for (var r = 0; r < t.bracket.length; r++) ...[
          Positioned(
            left: layout.x(r),
            top: 0,
            child: Text(
              '${context.l.round} ${r + 1} · ${t.bracket[r].length * 2}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          for (var i = 0; i < t.bracket[r].length; i++) ...[
            Positioned(
              left: layout.x(r),
              top: layout.top(r, i),
              width: BracketLayout.cardWidth,
              height: BracketLayout.cardHeight,
              child: _card(context, t.bracket[r][i]),
            ),
            if (t.bracket[r][i].winner != null)
              Positioned(
                left: layout.x(r) + BracketLayout.cardWidth + 4,
                top: layout.centerY(r, i) - 32,
                width: BracketLayout.gap - 12,
                child: Text(
                  t.label(t.bracket[r][i].winner),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: green),
                ),
              ),
          ],
        ],
      ],
    ),
  );

  Widget _card(BuildContext context, Bout b) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: b.a != null && b.b != null && !b.bye ? () => onScore(b) : null,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              b.bye ? '${b.id} · ${context.l.bye}' : b.id,
              style: const TextStyle(fontSize: 11, color: green),
            ),
            for (final (index, (participant, score)) in [
              (b.a, b.sa),
              (b.b, b.sb),
            ].indexed) ...[
              if (index == 1) const Divider(height: 1),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        t.label(participant),
                        textAlign: TextAlign.left,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight:
                              participant != null && b.winner == participant
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(score?.toString() ?? '', textAlign: TextAlign.right),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _BracketLines extends CustomPainter {
  final BracketLayout layout;
  _BracketLines(this.layout);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = green
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    for (var r = 0; r < layout.rounds.length; r++) {
      for (var i = 0; i < layout.rounds[r].length; i++) {
        final x = layout.x(r) + BracketLayout.cardWidth;
        final y = layout.centerY(r, i);
        final end = x + BracketLayout.gap;
        final path = Path()..moveTo(x, y);
        if (r + 1 < layout.rounds.length) {
          final target = layout.centerY(r + 1, i ~/ 2);
          path
            ..lineTo(end - 12, y)
            ..lineTo(end - 12, target)
            ..lineTo(end, target);
        } else {
          path.lineTo(end - 12, y);
        }
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_BracketLines oldDelegate) => oldDelegate.layout != layout;
}
