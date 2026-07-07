#!/usr/bin/env python3
"""
Kakuro generator with unique-solution verification.

Rules:
- Grid of white (fillable) and black (blocked/clue) cells.
- White cells form horizontal and vertical runs. Each run has a sum clue
  shown in the black cell immediately before it.
- Fill each white cell with a digit 1-9 such that each run sums to its clue
  and contains no repeated digit.
"""

import random
import sys


def gen_layout(H, W, rng, black_frac=0.28, tries=200):
    for _ in range(tries):
        black = [[False] * W for _ in range(H)]
        for c in range(W):
            black[0][c] = True
        for r in range(H):
            black[r][0] = True
        for r in range(1, H):
            for c in range(1, W):
                if rng.random() < black_frac:
                    black[r][c] = True
        white = [[not black[r][c] for c in range(W)] for r in range(H)]
        changed = True
        while changed:
            changed = False
            for r in range(1, H):
                c = 1
                while c < W:
                    if white[r][c]:
                        start = c
                        while c < W and white[r][c]:
                            c += 1
                        if c - start == 1:
                            white[r][start] = False
                            changed = True
                    else:
                        c += 1
            for c in range(1, W):
                r = 1
                while r < H:
                    if white[r][c]:
                        start = r
                        while r < H and white[r][c]:
                            r += 1
                        if r - start == 1:
                            white[start][c] = False
                            changed = True
                    else:
                        r += 1
        white_count = sum(sum(row) for row in white)
        if white_count < (H - 1) * (W - 1) * 0.35:
            continue
        return white
    return None


def find_runs(white, H, W):
    runs = []
    for r in range(H):
        c = 0
        while c < W:
            if white[r][c]:
                start = c
                while c < W and white[r][c]:
                    c += 1
                cells = [(r, cc) for cc in range(start, c)]
                if len(cells) >= 2:
                    runs.append({"cells": cells, "dir": "h"})
            else:
                c += 1
    for c in range(W):
        r = 0
        while r < H:
            if white[r][c]:
                start = r
                while r < H and white[r][c]:
                    r += 1
                cells = [(rr, c) for rr in range(start, r)]
                if len(cells) >= 2:
                    runs.append({"cells": cells, "dir": "v"})
            else:
                r += 1
    return runs


def _all_run_solutions(H, W, white, clue_map, cap=5, node_limit=200000):
    """Like count_solutions but returns up to `cap` distinct solution grids
    (not just a count), for diagnostics/repair. Returns (solutions, aborted)
    where aborted=True means the node budget ran out before the search could
    prove there are no more solutions -- callers MUST NOT treat a short
    solution list as proof of uniqueness when aborted is True."""
    runs = find_runs(white, H, W)
    for run in runs:
        r0, c0 = run["cells"][0]
        if run["dir"] == "h":
            br, bc = r0, c0 - 1
            key = "right"
        else:
            br, bc = r0 - 1, c0
            key = "down"
        run["sum"] = clue_map.get((br, bc), {}).get(key)

    cell_runs = {}
    for run in runs:
        for cell in run["cells"]:
            cell_runs.setdefault(cell, []).append(run)

    grid = [[0] * W for _ in range(H)]
    cells = [(r, c) for r in range(H) for c in range(W) if white[r][c]]
    cells.sort(key=lambda rc: -len(cell_runs.get(rc, [])))

    found = []
    nodes = [0]
    aborted = [False]

    def run_feasible(run):
        vals = [grid[r][c] for (r, c) in run["cells"] if grid[r][c] != 0]
        if run["sum"] is None:
            return True
        if len(set(vals)) != len(vals):
            return False
        total = sum(vals)
        remaining = len(run["cells"]) - len(vals)
        if total > run["sum"]:
            return False
        if remaining == 0:
            return total == run["sum"]
        used = set(vals)
        avail = sorted(d for d in range(1, 10) if d not in used)
        if len(avail) < remaining:
            return False
        min_add = sum(avail[:remaining])
        max_add = sum(avail[-remaining:])
        if total + min_add > run["sum"]:
            return False
        if total + max_add < run["sum"]:
            return False
        return True

    def bt(i):
        if len(found) >= cap or aborted[0]:
            return
        nodes[0] += 1
        if nodes[0] > node_limit:
            aborted[0] = True
            return
        if i == len(cells):
            found.append([row[:] for row in grid])
            return
        r, c = cells[i]
        for v in range(1, 10):
            grid[r][c] = v
            ok = True
            for run in cell_runs.get((r, c), []):
                if not run_feasible(run):
                    ok = False
                    break
            if ok:
                bt(i + 1)
            grid[r][c] = 0
            if len(found) >= cap or aborted[0]:
                return

    bt(0)
    return found, aborted[0]


def fill_grid(white, H, W, rng, tries=30):
    """Produce a filled grid via plain backtracking (any valid fill; sums
    derived from it are checked for uniqueness by the caller, which retries
    with different layouts/fills as needed since most random fills are not
    uniquely determined by their sums alone)."""
    runs = find_runs(white, H, W)
    if not runs:
        return None
    cell_runs = {}
    for run in runs:
        for cell in run["cells"]:
            cell_runs.setdefault(cell, []).append(run)

    grid = [[0] * W for _ in range(H)]
    cells = [(r, c) for r in range(H) for c in range(W) if white[r][c]]

    def run_values(run):
        return [grid[r][c] for (r, c) in run["cells"] if grid[r][c] != 0]

    def bt(i, order):
        if i == len(order):
            return True
        r, c = order[i]
        opts = list(range(1, 10))
        rng.shuffle(opts)
        for v in opts:
            ok = True
            for run in cell_runs.get((r, c), []):
                if v in run_values(run):
                    ok = False
                    break
            if ok:
                grid[r][c] = v
                if bt(i + 1, order):
                    return True
                grid[r][c] = 0
        return False

    for _ in range(tries):
        for r in range(H):
            for c in range(W):
                grid[r][c] = 0
        order = cells[:]
        rng.shuffle(order)
        order.sort(key=lambda rc: -len(cell_runs.get(rc, [])))
        if bt(0, order):
            return grid
    return None


def repair_to_unique(white, H, W, grid, clue_map, rng, max_rounds=12):
    """Given a filled grid whose derived clues are NOT unique, try to reach
    uniqueness by re-randomizing the fill of cells that differ between two
    found solutions (the actual sources of ambiguity), keeping the rest fixed
    where possible, and recomputing clues. This converges far faster than
    regenerating whole fresh layouts because it directly targets the
    ambiguous cells."""
    import time as _time
    start = _time.time()
    cur_grid = [row[:] for row in grid]
    for _ in range(max_rounds):
        if _time.time() - start > 1.5:
            return None, None
        cm = compute_clues(cur_grid, white, H, W)
        sols, aborted = _all_run_solutions(H, W, white, cm, cap=2, node_limit=60000)
        if not aborted and len(sols) <= 1:
            # search completed without exhausting the budget and found at
            # most one solution. Double-check with the authoritative counter
            # (same algorithm, but count_solutions is the single source of
            # truth used everywhere else, so route the final accept through
            # it to avoid any drift between the two implementations).
            n = count_solutions(H, W, white, cm, cap=2, node_limit=120000)
            if n == 1:
                return cur_grid, cm
            if n > 2:
                continue  # inconclusive; try another repair round
            # n == 2: genuinely not unique despite the shorter search saying
            # so -- fall through to use these sols for a repair attempt
            sols, aborted = _all_run_solutions(
                H, W, white, cm, cap=2, node_limit=120000)
            if aborted or len(sols) < 2:
                continue
        if aborted or len(sols) < 2:
            # inconclusive at this budget -- can't identify two solutions to
            # diff against, so skip repairing this round (try a fresh round
            # or give up after max_rounds).
            continue
        # two distinct solutions found; identify differing cells and
        # re-roll just those cells' runs
        a, b = sols[0], sols[1]
        diff_cells = [(r, c) for r in range(H) for c in range(W)
                      if white[r][c] and a[r][c] != b[r][c]]
        if not diff_cells:
            return cur_grid, cm
        # pick one differing cell, find its runs, and re-fill just those
        # runs' cells with a fresh random valid assignment
        runs = find_runs(white, H, W)
        cell_runs = {}
        for run in runs:
            for cell in run["cells"]:
                cell_runs.setdefault(cell, []).append(run)
        target = rng.choice(diff_cells)
        affected_runs = cell_runs.get(target, [])
        affected_cells = set()
        for run in affected_runs:
            affected_cells.update(run["cells"])
        # clear and re-fill just these cells via local backtracking
        saved = {cell: cur_grid[cell[0]][cell[1]] for cell in affected_cells}
        for cell in affected_cells:
            cur_grid[cell[0]][cell[1]] = 0

        def run_values(run):
            return [cur_grid[r][c] for (r, c) in run["cells"]
                    if cur_grid[r][c] != 0]

        ordered = list(affected_cells)
        rng.shuffle(ordered)

        def bt(i):
            if i == len(ordered):
                return True
            r, c = ordered[i]
            opts = list(range(1, 10))
            rng.shuffle(opts)
            for v in opts:
                ok = True
                for run in cell_runs.get((r, c), []):
                    if v in run_values(run):
                        ok = False
                        break
                if ok:
                    cur_grid[r][c] = v
                    if bt(i + 1):
                        return True
                    cur_grid[r][c] = 0
            return False

        if not bt(0):
            # restore and give up this round
            for cell, val in saved.items():
                cur_grid[cell[0]][cell[1]] = val
            continue
    cm = compute_clues(cur_grid, white, H, W)
    n = count_solutions(H, W, white, cm, cap=2, node_limit=200000)
    if n == 1:
        return cur_grid, cm
    return None, None


def compute_clues(grid, white, H, W):
    runs = find_runs(white, H, W)
    clue_map = {}
    for run in runs:
        r0, c0 = run["cells"][0]
        total = sum(grid[r][c] for (r, c) in run["cells"])
        if run["dir"] == "h":
            br, bc = r0, c0 - 1
            clue_map.setdefault((br, bc), {})["right"] = total
        else:
            br, bc = r0 - 1, c0
            clue_map.setdefault((br, bc), {})["down"] = total
    return clue_map


def count_solutions(H, W, white, clue_map, cap=2, node_limit=400000):
    runs = find_runs(white, H, W)
    for run in runs:
        r0, c0 = run["cells"][0]
        if run["dir"] == "h":
            br, bc = r0, c0 - 1
            key = "right"
        else:
            br, bc = r0 - 1, c0
            key = "down"
        run["sum"] = clue_map.get((br, bc), {}).get(key)

    cell_runs = {}
    for run in runs:
        for cell in run["cells"]:
            cell_runs.setdefault(cell, []).append(run)

    grid = [[0] * W for _ in range(H)]
    cells = [(r, c) for r in range(H) for c in range(W) if white[r][c]]
    cells.sort(key=lambda rc: -len(cell_runs.get(rc, [])))

    solutions = [0]
    nodes = [0]
    aborted = [False]

    def run_feasible(run):
        vals = [grid[r][c] for (r, c) in run["cells"] if grid[r][c] != 0]
        if run["sum"] is None:
            return True
        if len(set(vals)) != len(vals):
            return False
        total = sum(vals)
        remaining = len(run["cells"]) - len(vals)
        if total > run["sum"]:
            return False
        if remaining == 0:
            return total == run["sum"]
        used = set(vals)
        avail = sorted(d for d in range(1, 10) if d not in used)
        if len(avail) < remaining:
            return False
        min_add = sum(avail[:remaining])
        max_add = sum(avail[-remaining:])
        if total + min_add > run["sum"]:
            return False
        if total + max_add < run["sum"]:
            return False
        return True

    def bt(i):
        if solutions[0] >= cap or aborted[0]:
            return
        nodes[0] += 1
        if nodes[0] > node_limit:
            aborted[0] = True
            return
        if i == len(cells):
            solutions[0] += 1
            return
        r, c = cells[i]
        for v in range(1, 10):
            grid[r][c] = v
            ok = True
            for run in cell_runs.get((r, c), []):
                if not run_feasible(run):
                    ok = False
                    break
            if ok:
                bt(i + 1)
            grid[r][c] = 0
            if solutions[0] >= cap or aborted[0]:
                return

    bt(0)
    if aborted[0]:
        return cap + 1
    return solutions[0]


def make_puzzle(H, W, rng, black_frac=0.28, max_tries=3, time_budget=3.0):
    import time as _time
    start = _time.time()
    for _ in range(max_tries):
        if _time.time() - start > time_budget:
            return None
        white = gen_layout(H, W, rng, black_frac=black_frac)
        if white is None:
            continue
        grid = fill_grid(white, H, W, rng)
        if grid is None:
            continue
        clue_map = compute_clues(grid, white, H, W)
        n = count_solutions(H, W, white, clue_map, cap=2, node_limit=150000)
        if n == 1:
            return white, clue_map, grid
        if _time.time() - start > time_budget:
            return None
        # attempt targeted repair instead of discarding this layout outright
        repaired_grid, repaired_clues = repair_to_unique(
            white, H, W, grid, clue_map, rng, max_rounds=12)
        if repaired_grid is not None:
            return white, repaired_clues, repaired_grid
    return None


def serialize(H, W, white, clue_map, grid, pid, tier):
    flat_white = []
    flat_grid = []
    flat_right = []
    flat_down = []
    for r in range(H):
        for c in range(W):
            flat_white.append(1 if white[r][c] else 0)
            flat_grid.append(grid[r][c])
            cm = clue_map.get((r, c), {})
            flat_right.append(cm.get("right", 0) or 0)
            flat_down.append(cm.get("down", 0) or 0)
    return {
        "id": pid, "tier": tier, "h": H, "w": W,
        "white": flat_white, "solution": flat_grid,
        "clueRight": flat_right, "clueDown": flat_down,
    }


def main():
    rng = random.Random(20260705)
    tiers = [
        (50, 6, 6, "easy"),
        (50, 7, 7, "medium"),
        (50, 8, 8, "hard"),
    ]
    out = []
    pid = 0
    for cnt, H, W, tier in tiers:
        made = attempts = 0
        black_frac = 0.26 if tier == "easy" else (0.28 if tier == "medium" else 0.3)
        while made < cnt and attempts < cnt * 30:
            attempts += 1
            res = make_puzzle(H, W, rng, black_frac=black_frac, max_tries=10)
            if res is None:
                continue
            white, clue_map, grid = res
            out.append(serialize(H, W, white, clue_map, grid, pid, tier))
            pid += 1
            made += 1
            if made % 10 == 0:
                print(f"  {tier} {H}x{W}: {made}/{cnt}", file=sys.stderr)
        print(f"Tier {tier}: {made} ({attempts} attempts)", file=sys.stderr)
    import json
    with open("/home/claude/kakuro/puzzles.json", "w") as f:
        json.dump(out, f)
    print(f"TOTAL: {len(out)}", file=sys.stderr)


if __name__ == "__main__":
    main()
