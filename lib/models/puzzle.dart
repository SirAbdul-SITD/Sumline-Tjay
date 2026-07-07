class Puzzle {
  final int id;
  final String tier;
  final int h;
  final int w;
  final List<List<bool>> white;
  final List<List<int>> solution;
  final List<List<int>> clueRight;
  final List<List<int>> clueDown;

  Puzzle({
    required this.id,
    required this.tier,
    required this.h,
    required this.w,
    required this.white,
    required this.solution,
    required this.clueRight,
    required this.clueDown,
  });

  factory Puzzle.fromJson(Map<String, dynamic> j) {
    final h = j['h'] as int;
    final w = j['w'] as int;
    final wf = (j['white'] as List).map((e) => e as int).toList();
    final sol = (j['solution'] as List).map((e) => e as int).toList();
    final cr = (j['clueRight'] as List).map((e) => e as int).toList();
    final cd = (j['clueDown'] as List).map((e) => e as int).toList();
    return Puzzle(
      id: j['id'] as int,
      tier: j['tier'] as String,
      h: h,
      w: w,
      white:
          List.generate(h, (r) => List.generate(w, (c) => wf[r * w + c] == 1)),
      solution:
          List.generate(h, (r) => List.generate(w, (c) => sol[r * w + c])),
      clueRight:
          List.generate(h, (r) => List.generate(w, (c) => cr[r * w + c])),
      clueDown:
          List.generate(h, (r) => List.generate(w, (c) => cd[r * w + c])),
    );
  }

  int get whiteCellCount {
    int n = 0;
    for (final row in white) {
      for (final v in row) {
        if (v) n++;
      }
    }
    return n;
  }
}
