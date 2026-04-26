import 'dart:math' as math;

String fmtDur(num seconds) {
  final s = seconds.toInt();
  final m = s ~/ 60;
  final r = s % 60;
  return '$m:${r.toString().padLeft(2, '0')}';
}

List<double> waveformBars(int seed, [int count = 64]) {
  final bars = <double>[];
  var s = seed * 9301 + 49297;
  for (var i = 0; i < count; i++) {
    s = (s * 9301 + 49297) % 233280;
    final r = s / 233280.0;
    final env = 0.35 + 0.55 * math.pow(math.sin((i / count) * math.pi), 0.8);
    final noise = 0.55 + 0.45 * r;
    final wob = 0.7 + 0.3 * math.sin(i * 0.5 + seed);
    bars.add(math.min(1.0, env * noise * wob));
  }
  return bars;
}
