import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;
import '../../core/utils/format.dart';
import 'visualizer.dart';

class VisualizerRing extends StatefulWidget {
  final int seed;
  final int bars;
  final double size;
  final double progress;
  final Color accent;
  final bool playing;
  final VizStyle style;
  final Widget? child;
  final ValueChanged<double>? onScrub;
  final VoidCallback? onScrubStart;
  final VoidCallback? onScrubEnd;
  final double innerRadius;
  final double outerMax;

  const VisualizerRing({
    super.key,
    required this.seed,
    this.bars = 110,
    this.size = 300,
    this.progress = 0,
    required this.accent,
    this.playing = false,
    this.style = VizStyle.spectrum,
    this.child,
    this.onScrub,
    this.onScrubStart,
    this.onScrubEnd,
    this.innerRadius = 0.56,
    this.outerMax = 0.98,
  });

  @override
  State<VisualizerRing> createState() => _VisualizerRingState();
}

class _VisualizerRingState extends State<VisualizerRing>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  late List<double> _levels;
  late List<double> _state;
  double _last = 0;

  @override
  void initState() {
    super.initState();
    _levels = List.filled(widget.bars, 0);
    _state = List.filled(widget.bars, 0);
    _ticker = createTicker(_tick)..start();
  }

  void _tick(Duration d) {
    final t = d.inMicroseconds / 1e6;
    final dt = math.min(0.05, _last == 0 ? 0.016 : (t - _last));
    _last = t;
    final base = widget.seed * 0.013;
    final bins = widget.bars;
    final speed = widget.style == VizStyle.oscilloscope ? 1.5 : 1.0;
    for (var i = 0; i < bins; i++) {
      double target;
      if (!widget.playing) {
        target = 0.06 + 0.03 * math.sin(t * 0.8 + i * 0.2);
      } else {
        final freq = i / bins;
        final env = math.pow(1 - freq, 0.6) * 0.9 + 0.1;
        final kick = math.pow(
                math.max(0, math.sin(t * 2 * math.pi * 1.7 + base)), 3)
            .toDouble();
        final bass = math.sin(t * 3 + i * 0.3 + base) * 0.4 + 0.6;
        final mid = math.sin(t * 7 * speed + i * 0.9 - base * 2) * 0.5 + 0.5;
        final hi = math.sin(t * 13 * speed + i * 2.1 + base * 3) * 0.5 + 0.5;
        final n = (math.sin(t * 23 + i * 11.3 + base) + 1) * 0.5;
        final lowW = math.pow(1 - freq, 2);
        final midW = 1 - (freq - 0.5).abs() * 2;
        final hiW = math.pow(freq, 2);
        var v = lowW * (bass * 0.7 + kick * 0.8) +
            midW * (mid * 0.7 + kick * 0.2) +
            hiW * (hi * 0.55 + n * 0.3);
        target = (v * env).clamp(0.0, 1.0);
      }
      final cur = _state[i];
      final rate = target > cur ? 18.0 : 6.0;
      _state[i] = (cur + (target - cur) * math.min(1.0, dt * rate)).clamp(0.0, 1.0);
      _levels[i] = _state[i];
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  double _angleFromOffset(Offset local) {
    final c = Offset(widget.size / 2, widget.size / 2);
    final v = local - c;
    var a = math.atan2(v.dx, -v.dy) / (2 * math.pi);
    if (a < 0) a += 1;
    return a;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (d) {
          widget.onScrubStart?.call();
          widget.onScrub?.call(_angleFromOffset(d.localPosition));
        },
        onPanUpdate: (d) {
          widget.onScrub?.call(_angleFromOffset(d.localPosition));
        },
        onPanEnd: (_) => widget.onScrubEnd?.call(),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _RingGlowPainter(
                    accent: widget.accent,
                    energy: _levels.fold<double>(0, (s, v) => s + v) / _levels.length,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _RingPainter(
                    levels: _levels,
                    baseShape: waveformBars(widget.seed, widget.bars),
                    style: widget.style,
                    accent: widget.accent,
                    progress: widget.progress,
                    innerRadius: widget.innerRadius,
                    outerMax: widget.outerMax,
                  ),
                ),
              ),
            ),
            if (widget.child != null) widget.child!,
          ],
        ),
      ),
    );
  }
}

class _RingGlowPainter extends CustomPainter {
  final Color accent;
  final double energy;
  _RingGlowPainter({required this.accent, required this.energy});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.5;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          accent.withValues(alpha: (0.08 + energy * 0.22).clamp(0.0, 1.0)),
          accent.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: c, radius: r))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(c, r, paint);
  }

  @override
  bool shouldRepaint(_RingGlowPainter old) => true;
}

class _RingPainter extends CustomPainter {
  final List<double> levels;
  final List<double> baseShape;
  final VizStyle style;
  final Color accent;
  final double progress;
  final double innerRadius;
  final double outerMax;

  _RingPainter({
    required this.levels,
    required this.baseShape,
    required this.style,
    required this.accent,
    required this.progress,
    required this.innerRadius,
    required this.outerMax,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final R = size.width * 0.5;
    final bars = levels.length;
    final dimColor = const Color(0x1AFFFFFF);
    final basePaint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = R * 0.014;

    for (var i = 0; i < bars; i++) {
      final angle = (i / bars) * 2 * math.pi - math.pi / 2;
      final shape = baseShape[i];
      final lv = levels[i];
      double v;
      switch (style) {
        case VizStyle.spectrum:
          v = lv;
          break;
        case VizStyle.oscilloscope:
          v = 0.25 + lv * 0.75;
          break;
        default:
          v = shape * 0.5 + lv * 0.7;
      }
      v = math.max(0.04, v);
      final r1 = innerRadius * R;
      final r2 = (innerRadius + v * (outerMax - innerRadius)) * R;
      final x1 = cx + math.cos(angle) * r1;
      final y1 = cy + math.sin(angle) * r1;
      final x2 = cx + math.cos(angle) * r2;
      final y2 = cy + math.sin(angle) * r2;
      final frac = (i + 0.5) / bars;
      final played = frac <= progress;
      basePaint.color = played ? accent : dimColor;
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), basePaint);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => true;
}
