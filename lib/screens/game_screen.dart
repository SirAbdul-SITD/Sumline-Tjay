import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/puzzle.dart';
import '../painters/board_painter.dart';
import '../services/palette.dart';
import '../services/progress_service.dart';
import '../services/settings_service.dart';
import '../services/audio_manager.dart';

class GameScreen extends StatefulWidget {
  final Puzzle puzzle;
  final AudioManager audio;
  final VoidCallback? onNext;
  const GameScreen({
    super.key,
    required this.puzzle,
    required this.audio,
    this.onNext,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late List<List<int>> grid;
  int? selR, selC;
  bool won = false;
  int moves = 0;

  int get _h => widget.puzzle.h;
  int get _w => widget.puzzle.w;

  @override
  void initState() {
    super.initState();
    grid = List.generate(_h, (_) => List.filled(_w, 0));
  }

  void _haptic() {
    if (context.read<SettingsService>().haptics) {
      HapticFeedback.selectionClick();
    }
  }

  void _selectCell(int r, int c) {
    if (won) return;
    if (!widget.puzzle.white[r][c]) return;
    setState(() {
      selR = r;
      selC = c;
    });
    widget.audio.tap();
  }

  void _enterValue(int value) {
    if (won || selR == null || selC == null) return;
    setState(() {
      grid[selR!][selC!] = value;
      moves++;
    });
    if (value == 0) {
      widget.audio.clear();
    } else {
      widget.audio.place();
    }
    _haptic();
    _checkWin();
  }

  List<List<int>> _rowRun(int r, int c) {
    final p = widget.puzzle;
    int c0 = c, c1 = c;
    while (c0 > 0 && p.white[r][c0 - 1]) {
      c0--;
    }
    while (c1 < _w - 1 && p.white[r][c1 + 1]) {
      c1++;
    }
    return [for (int cc = c0; cc <= c1; cc++) [r, cc]];
  }

  List<List<int>> _colRun(int r, int c) {
    final p = widget.puzzle;
    int r0 = r, r1 = r;
    while (r0 > 0 && p.white[r0 - 1][c]) {
      r0--;
    }
    while (r1 < _h - 1 && p.white[r1 + 1][c]) {
      r1++;
    }
    return [for (int rr = r0; rr <= r1; rr++) [rr, c]];
  }

  Set<String> _conflicts() {
    final out = <String>{};
    final p = widget.puzzle;
    for (int r = 0; r < _h; r++) {
      for (int c = 0; c < _w; c++) {
        if (!p.white[r][c] || grid[r][c] == 0) continue;
        final rowRun = _rowRun(r, c);
        if (rowRun.length > 1 && rowRun.first[1] == c) {
          final seen = <int, List<List<int>>>{};
          for (final cell in rowRun) {
            final v = grid[cell[0]][cell[1]];
            if (v > 0) seen.putIfAbsent(v, () => []).add(cell);
          }
          for (final cells in seen.values) {
            if (cells.length > 1) {
              for (final cell in cells) {
                out.add('${cell[0]},${cell[1]}');
              }
            }
          }
        }
        final colRun = _colRun(r, c);
        if (colRun.length > 1 && colRun.first[0] == r) {
          final seen = <int, List<List<int>>>{};
          for (final cell in colRun) {
            final v = grid[cell[0]][cell[1]];
            if (v > 0) seen.putIfAbsent(v, () => []).add(cell);
          }
          for (final cells in seen.values) {
            if (cells.length > 1) {
              for (final cell in cells) {
                out.add('${cell[0]},${cell[1]}');
              }
            }
          }
        }
      }
    }
    return out;
  }

  void _checkWin() {
    final p = widget.puzzle;
    for (int r = 0; r < _h; r++) {
      for (int c = 0; c < _w; c++) {
        if (p.white[r][c] && grid[r][c] == 0) return;
      }
    }
    if (_conflicts().isNotEmpty) return;
    for (int r = 0; r < _h; r++) {
      for (int c = 0; c < _w; c++) {
        final cr = p.clueRight[r][c];
        if (cr > 0) {
          int cc = c + 1, sum = 0;
          while (cc < _w && p.white[r][cc]) {
            sum += grid[r][cc];
            cc++;
          }
          if (sum != cr) return;
        }
        final cd = p.clueDown[r][c];
        if (cd > 0) {
          int rr = r + 1, sum = 0;
          while (rr < _h && p.white[rr][c]) {
            sum += grid[rr][c];
            rr++;
          }
          if (sum != cd) return;
        }
      }
    }
    won = true;
    widget.audio.win();
    final stars = _starRating();
    context.read<ProgressService>().recordWin(p.id, stars);
    Future.delayed(const Duration(milliseconds: 300), _showWinSheet);
  }

  int _starRating() {
    final cells = widget.puzzle.whiteCellCount;
    if (moves <= cells) return 3;
    if (moves <= (cells * 1.5).round()) return 2;
    return 1;
  }

  void _showWinSheet() {
    final stars = _starRating();
    showModalBottomSheet(
      context: context,
      backgroundColor: Palette.panel,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ledger Balanced',
                style: TextStyle(
                    color: Palette.cream,
                    fontSize: 24,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    i < stars ? Icons.star : Icons.star_border,
                    color: i < stars ? Palette.gold : Palette.haze,
                    size: 44,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text('Solved in $moves entries',
                style: const TextStyle(color: Palette.haze, fontSize: 14)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Palette.cream,
                      side: const BorderSide(color: Palette.line),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Levels'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Palette.gold,
                      foregroundColor: Palette.wine,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                      widget.onNext?.call();
                    },
                    child: const Text('Next'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _reset() {
    setState(() {
      grid = List.generate(_h, (_) => List.filled(_w, 0));
      selR = null;
      selC = null;
      moves = 0;
      won = false;
    });
    widget.audio.tap();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.puzzle;
    final conflicts = _conflicts();
    final enabled = selR != null && selC != null;
    return Scaffold(
      backgroundColor: Palette.wine,
      appBar: AppBar(
        backgroundColor: Palette.wine,
        elevation: 0,
        foregroundColor: Palette.cream,
        title: Text('Level ${p.id + 1}',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _reset),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Fill white cells with 1–9. Each run must sum to its clue '
                'and never repeat a digit.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Palette.haze.withValues(alpha: 0.9),
                    fontSize: 12.5,
                    height: 1.4),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: Center(
                child: LayoutBuilder(builder: (context, cons) {
                  final side = (cons.maxWidth < cons.maxHeight
                          ? cons.maxWidth
                          : cons.maxHeight) -
                      32;
                  final cell = side / _w;
                  return GestureDetector(
                    onTapUp: (d) {
                      final c = (d.localPosition.dx / cell)
                          .floor()
                          .clamp(0, _w - 1);
                      final r = (d.localPosition.dy / cell)
                          .floor()
                          .clamp(0, _h - 1);
                      _selectCell(r, c);
                    },
                    child: CustomPaint(
                      size: Size(side, side),
                      painter: BoardPainter(
                        puzzle: p,
                        grid: grid,
                        selR: selR,
                        selC: selC,
                        conflicts: conflicts,
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 10),
            Opacity(
              opacity: enabled ? 1.0 : 0.4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (int d = 1; d <= 9; d++)
                      SizedBox(
                        width: 52,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Palette.raised,
                            foregroundColor: Palette.cream,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: enabled ? () => _enterValue(d) : null,
                          child: Text('$d',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Palette.raised,
                          foregroundColor: Palette.coral,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: enabled ? () => _enterValue(0) : null,
                        child: const Icon(Icons.backspace_outlined, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Entries: $moves',
                      style:
                          const TextStyle(color: Palette.haze, fontSize: 14)),
                  Text(p.tier.toUpperCase(),
                      style: TextStyle(
                          color: Palette.tierColors[p.tier],
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
