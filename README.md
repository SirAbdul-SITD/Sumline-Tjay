# Sumline

A sum-arithmetic logic puzzle for Android (Flutter), based on Kakuro.
Balance every run.

## Run

```bash
cd sumline
flutter create .
flutter pub get
flutter run
```

## The puzzle

White cells form horizontal and vertical **runs** (maximal contiguous
stretches). Each run has a sum clue shown in the black cell immediately
before it. Fill every white cell with a digit **1-9** so each run sums to
its clue with **no digit repeated** within that run.

**Tap** a white cell to select it, then **type** its digit and press enter
(or the backspace button to clear it). Digits that repeat within the same
run are flagged in red.

## Why every level is solvable — and why this was the hardest generator yet

Kakuro turned out to be the trickiest puzzle type in this catalog to
generate reliably. The naive approach — carve a black/white layout, fill it
with any valid random digit assignment, derive sums, check uniqueness — works
for other logic puzzles but **almost never** works for Kakuro: in early
testing, 0 out of 300 randomly-filled layouts produced a uniquely-solvable
puzzle. Kakuro's real constraining power comes from which specific sums are
chosen (sums near the numeric extremes for a run's length have far fewer
valid digit combinations), not just from the layout shape.

`generator.py` instead:

1. Carves a white-cell layout (avoiding degenerate length-1 runs), same
   general technique as the other region-based puzzles in this catalog.
2. Fills it with a first valid digit assignment via backtracking.
3. If the resulting sums aren't uniquely solvable (the common case), runs a
   **targeted repair pass**: finds two genuinely different valid fillings for
   the current sums, isolates exactly which cells differ between them, and
   re-rolls only the runs touching those cells — rather than discarding the
   whole layout and starting over. This repair loop is bounded by both a
   node-count budget and a wall-clock time budget per attempt, so no single
   attempt can stall a batch.
4. A puzzle is only accepted after an **authoritative, independent**
   `count_solutions` check confirms exactly one solution — this check is
   deliberately kept separate from the repair loop's own internal (budget-
   limited) solution search, after an earlier version of this generator had
   a bug where a budget-truncated search was mistaken for confirmed
   uniqueness. That bug produced puzzles that looked fine but had 2+ valid
   solutions; it was caught by re-verifying every generated puzzle from
   scratch with a fresh, independent solver pass before shipping.

Even with this fix, 8×8 Kakuro puzzles that are uniquely solvable are
genuinely rare to hit — which is why the hard tier ships with **25** puzzles
rather than 50.

All 125 shipped boards were independently re-verified for structure (every
run sums correctly with no repeated digits) and uniqueness before bundling.

## Project layout

```
lib/
  main.dart
  models/puzzle.dart
  services/        palette, puzzle_repository, progress, settings, audio
  painters/board_painter.dart      # black/white cells, corner sum clues
  screens/         home, level_select, game, settings
assets/
  data/puzzles.json                # 125 verified puzzles
  audio/                           # procedural SFX + ambient track
screens/                           # Play Store screenshots (1080x1920)
generator.py                       # reference generator/solver
```

## Notes

- State persists locally via `shared_preferences`. No network, no accounts.
- Audio is procedurally generated WAV; the ambient track is intentionally
  large so the release build comfortably exceeds typical minimum size
  requirements.
