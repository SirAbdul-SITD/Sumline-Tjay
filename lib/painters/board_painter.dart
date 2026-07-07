import 'package:flutter/material.dart';
import '../models/puzzle.dart';
import '../services/palette.dart';

class BoardPainter extends CustomPainter {
  final Puzzle puzzle;
  final List<List<int>> grid;
  final int? selR;
  final int? selC;
  final Set<String> conflicts;

  BoardPainter({
    required this.puzzle,
    required this.grid,
    required this.selR,
    required this.selC,
    required this.conflicts,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final h = puzzle.h, w = puzzle.w;
    final cell = size.width / w;

    for (int r = 0; r < h; r++) {
      for (int c = 0; c < w; c++) {
        final rect = Rect.fromLTWH(c * cell, r * cell, cell, cell);
        final isWhite = puzzle.white[r][c];
        if (!isWhite) {
          canvas.drawRect(rect, Paint()..color = Palette.blackCell);
          final cr = puzzle.clueRight[r][c];
          final cd = puzzle.clueDown[r][c];
          if (cr > 0 || cd > 0) {
            final diag = Paint()
              ..color = Palette.line
              ..strokeWidth = 1;
            canvas.drawLine(rect.topLeft, rect.bottomRight, diag);
          }
          if (cd > 0) {
            final tp = TextPainter(
              text: TextSpan(
                  text: '$cd',
                  style: TextStyle(
                      color: Palette.gold,
                      fontSize: cell * 0.26,
                      fontWeight: FontWeight.w700)),
              textDirection: TextDirection.ltr,
            )..layout();
            tp.paint(
                canvas,
                Offset(rect.left + cell * 0.08,
                    rect.top + cell * 0.5 - tp.height / 2));
          }
          if (cr > 0) {
            final tp = TextPainter(
              text: TextSpan(
                  text: '$cr',
                  style: TextStyle(
                      color: Palette.gold,
                      fontSize: cell * 0.26,
                      fontWeight: FontWeight.w700)),
              textDirection: TextDirection.ltr,
            )..layout();
            tp.paint(
                canvas,
                Offset(rect.right - cell * 0.08 - tp.width,
                    rect.top + cell * 0.06));
          }
        } else {
          final isSel = r == selR && c == selC;
          final isConf = conflicts.contains('$r,$c');
          final v = grid[r][c];
          Color fill;
          if (isConf) {
            fill = Palette.coral.withValues(alpha: 0.55);
          } else if (isSel) {
            fill = Palette.selCell;
          } else if (v > 0) {
            fill = Palette.whiteCellFilled;
          } else {
            fill = Palette.whiteCell;
          }
          canvas.drawRect(rect, Paint()..color = fill);
          if (isSel) {
            canvas.drawRect(
                rect.deflate(1.5),
                Paint()
                  ..color = Palette.gold
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 2.5);
          }
          if (v > 0) {
            final tp = TextPainter(
              text: TextSpan(
                  text: '$v',
                  style: TextStyle(
                      color: Palette.ink,
                      fontSize: cell * 0.44,
                      fontWeight: FontWeight.w700)),
              textDirection: TextDirection.ltr,
            )..layout();
            tp.paint(
                canvas, rect.center - Offset(tp.width / 2, tp.height / 2));
          }
        }
      }
    }

    final gridPaint = Paint()
      ..color = Palette.line
      ..strokeWidth = 1;
    for (int r = 0; r <= h; r++) {
      canvas.drawLine(
          Offset(0, r * cell), Offset(size.width, r * cell), gridPaint);
    }
    for (int c = 0; c <= w; c++) {
      canvas.drawLine(
          Offset(c * cell, 0), Offset(c * cell, size.height), gridPaint);
    }
    canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..color = Palette.haze.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant BoardPainter old) =>
      old.grid != grid ||
      old.selR != selR ||
      old.selC != selC ||
      old.conflicts != conflicts ||
      old.puzzle != puzzle;
}
