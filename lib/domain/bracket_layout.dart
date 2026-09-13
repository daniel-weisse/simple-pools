import 'models.dart';

// Shared coordinates keep the interactive bracket and vector PDF identical.
class BracketLayout {
  static const cardWidth = 220.0;
  static const cardHeight = 100.0;
  static const gap = 160.0;
  static const rowHeight = 140.0;
  static const headingHeight = 36.0;
  final List<List<Bout>> rounds;
  BracketLayout(this.rounds);

  double get width => rounds.length * (cardWidth + gap);
  double get height => headingHeight + rounds.first.length * rowHeight;
  double x(int round) => round * (cardWidth + gap);
  double centerY(int round, int bout) =>
      headingHeight + (bout + .5) * (1 << round) * rowHeight;
  double top(int round, int bout) => centerY(round, bout) - cardHeight / 2;
}
