import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;
import '../../core/theme/oklch.dart';
import '../../core/utils/format.dart';

enum VizStyle { spectrum, waveform, monolith, gradient, oscilloscope }

VizStyle parseVizStyle(String s) {
  switch (s) {
    case 'spectrum':
      return VizStyle.spectrum;
    case 'waveform':
      return VizStyle.waveform;
    case 'monolith':
      return VizStyle.monolith;
    case 'gradient':
      return VizStyle.gradient;
    case 'oscilloscope':
      return VizStyle.oscilloscope;
  }
  return VizStyle.spectrum;
}

class _LevelEngine {
  final int bins;
  final int seed;
  final double speed;
  final List<double> _levels;
  double _lastT = 0;

  _LevelEngine({required this.bins, required this.seed, this.speed = 1})
      : _levels = List.filled(bins, 0);

  List<double> get levels => _levels;

  void tick(double tSeconds, bool playing) {
    final dt = math.min(0.05, _lastT == 0 ? 0.016 : (tSeconds - _lastT));
    _lastT = tSeconds;
    final base = seed * 0.013;
    for (var i = 0; i < bins; i++) {
      if (!playing) {
        final idle = 0.06 + 0.03 * math.sin(tSeconds * 0.8 + i * 0.2);
        _levels[i] += (idle - _levels[i]) * math.min(1.0, dt * 3);
        _levels[i] = _levels[i].clamp(0.0, 1.0);
        continue;
      }
      final freq = i / bins;
      final env = math.pow(1 - freq, 0.6) * 0.9 + 0.1;
      final kick = math.pow(
              math.max(0, math.sin(tSeconds * 2 * math.pi * 1.7 + base)), 3)
          .toDouble();
      final bass = math.sin(tSeconds * 3 + i * 0.3 + base) * 0.4 + 0.6;
      final mid = math.sin(tSeconds * 7 * speed + i * 0.9 - base * 2) * 0.5 + 0.5;
      final hi = math.sin(tSeconds * 13 * speed + i * 2.1 + base * 3) * 0.5 + 0.5;
      final n = (math.sin(tSeconds * 23 + i * 11.3 + base) + 1) * 0.5;
      final lowW = math.pow(1 - freq, 2);
      final midW = 1 - (freq - 0.5).abs() * 2;
      final hiW = math.pow(freq, 2);
      var v = lowW * (bass * 0.7 + kick * 0.8) +
          midW * (mid * 0.7 + kick * 0.2) +
          hiW * (hi * 0.55 + n * 0.3);
      v = (v * env).clamp(0.0, 1.0);
      final cur = _levels[i];
      final rate = v > cur ? 18.0 : 6.0;
      _levels[i] = (cur + (v - cur) * math.min(1.0, dt * rate)).clamp(0.0, 1.0);
    }
  }
}

class Visualizer extends StatefulWidget {
  final VizStyle style;
  final int seed;
  final double progress;
  final double height;
  final Color accent;
  final bool playing;
  final bool interactive;
  final ValueChanged<double>? onScrub;
  final VoidCallback? onScrubStart;
  final VoidCallback? onScrubEnd;

  const Visualizer({
    super.key,
    this.style = VizStyle.waveform,
    required this.seed,
    this.progress = 0,
    this.height = 80,
    required this.accent,
    this.playing = false,
    this.interactive = true,
    this.onScrub,
    this.onScrubStart,
    this.onScrubEnd,
  });

  @override
  State<Visualizer> createState() => _VisualizerState();
}

class _VisualizerState extends State<Visualizer>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  late final _LevelEngine _engine;
  double _t = 0;

  int get _bins {
    switch (widget.style) {
      case VizStyle.spectrum:
        return 56;
      case VizStyle.waveform:
        return 72;
      case VizStyle.monolith:
        return 40;
      case VizStyle.gradient:
        return 32;
      case VizStyle.oscilloscope:
        return 120;
    }
  }

  double get _speed {
    switch (widget.style) {
      case VizStyle.gradient:
        return 0.6;
      case VizStyle.oscilloscope:
        return 1.6;
      case VizStyle.waveform:
        return 0.8;
      default:
        return 1.0;
    }
  }

  @override
  void initState() {
    super.initState();
    _engine = _LevelEngine(bins: _bins, seed: widget.seed, speed: _speed);
    _ticker = createTicker((d) {
      _t = d.inMicroseconds / 1e6;
      _engine.tick(_t, widget.playing);
      if (mounted) setState(() {});
    })
      ..start();
  }

  @override
  void didUpdateWidget(covariant Visualizer old) {
    super.didUpdateWidget(old);
    if (old.seed != widget.seed || old.style != widget.style) {
      _engine._lastT = 0;
      for (var i = 0; i < _engine.levels.length; i++) {
        _engine.levels[i] = 0;
      }
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _handleDown(double frac) {
    if (!widget.interactive) return;
    widget.onScrubStart?.call();
    widget.onScrub?.call(frac);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: widget.interactive
          ? (d) {
              widget.onScrubStart?.call();
            }
          : null,
      onHorizontalDragUpdate: widget.interactive
          ? (d) {
              final box = context.findRenderObject() as RenderBox?;
              if (box == null) return;
              final local = box.globalToLocal(d.globalPosition);
              widget.onScrub?.call((local.dx / box.size.width).clamp(0.0, 1.0));
            }
          : null,
      onHorizontalDragEnd: widget.interactive
          ? (_) {
              widget.onScrubEnd?.call();
            }
          : null,
      onTapDown: widget.interactive
          ? (d) {
              final box = context.findRenderObject() as RenderBox?;
              if (box == null) return;
              _handleDown((d.localPosition.dx / box.size.width).clamp(0.0, 1.0));
            }
          : null,
      onTapUp: widget.interactive ? (_) => widget.onScrubEnd?.call() : null,
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: CustomPaint(
          painter: _VisualizerPainter(
            style: widget.style,
            levels: _engine.levels,
            seed: widget.seed,
            progress: widget.progress,
            accent: widget.accent,
            t: _t,
          ),
        ),
      ),
    );
  }
}

class _VisualizerPainter extends CustomPainter {
  final VizStyle style;
  final List<double> levels;
  final int seed;
  final double progress;
  final Color accent;
  final double t;

  _VisualizerPainter({
    required this.style,
    required this.levels,
    required this.seed,
    required this.progress,
    required this.accent,
    required this.t,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (style) {
      case VizStyle.spectrum:
        _paintSpectrum(canvas, size);
        break;
      case VizStyle.waveform:
        _paintWaveform(canvas, size);
        break;
      case VizStyle.monolith:
        _paintMonolith(canvas, size);
        break;
      case VizStyle.gradient:
        _paintGradient(canvas, size);
        break;
      case VizStyle.oscilloscope:
        _paintOscilloscope(canvas, size);
        break;
    }
  }

  void _paintSpectrum(Canvas canvas, Size size) {
    final bins = levels.length;
    final gap = size.width / bins;
    final w = gap * 0.55;
    final dim = const Color(0x38FFFFFF);
    for (var i = 0; i < bins; i++) {
      final v = levels[i];
      final h = math.max(2.0, v * size.height * 0.92);
      final x = i * gap + (gap - w) / 2;
      final y = size.height / 2 - h / 2;
      final frac = (i + 0.5) / bins;
      final played = frac <= progress;
      final paint = Paint()..color = played ? accent : dim;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h),
            Radius.circular(math.min(w / 2, 0.9))),
        paint,
      );
    }
  }

  void _paintWaveform(Canvas canvas, Size size) {
    final bins = levels.length;
    final base = waveformBars(seed, bins);
    final gap = size.width / bins;
    final w = gap * 0.48;
    final dim = const Color(0x2EFFFFFF);
    for (var i = 0; i < bins; i++) {
      final live = levels[i];
      final v = math.max(0.04, base[i] * (0.55 + live * 0.9));
      final h = v * size.height * 0.92;
      final x = i * gap + (gap - w) / 2;
      final y = size.height / 2 - h / 2;
      final frac = (i + 0.5) / bins;
      final played = frac <= progress;
      final paint = Paint()..color = played ? accent : dim;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(w / 2)),
        paint,
      );
    }
  }

  void _paintMonolith(Canvas canvas, Size size) {
    final bins = levels.length;
    final gap = size.width / bins;
    final w = gap * 0.42;
    const segs = 8;
    final segH = size.height * 0.96 / segs;
    for (var i = 0; i < bins; i++) {
      final v = levels[i];
      final lit = (v * segs).round();
      final x = i * gap + (gap - w) / 2;
      final frac = (i + 0.5) / bins;
      final played = frac <= progress;
      for (var s = 0; s < segs; s++) {
        final y = size.height - (s + 1) * segH + segH * 0.06;
        final isLit = s < lit;
        Color color;
        if (!isLit) {
          color = const Color(0x0DFFFFFF);
        } else if (s >= segs - 2) {
          color = oklch(0.75, 0.22, 20);
        } else if (s >= segs - 4) {
          color = oklch(0.85, 0.18, 70);
        } else {
          color = played ? accent : const Color(0x52FFFFFF);
        }
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, w, segH * 0.88),
            const Radius.circular(0.4),
          ),
          Paint()..color = color,
        );
      }
    }
  }

  void _paintGradient(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)),
      Paint()..color = const Color(0x05FFFFFF),
    );

    final energy = levels.fold<double>(0, (s, v) => s + v) / levels.length;
    final low = levels.take(10).fold<double>(0, (s, v) => s + v) / 10;
    final hi = levels.skip(levels.length - 10).fold<double>(0, (s, v) => s + v) / 10;

    final blue = oklch(0.72, 0.22, 200);

    final g1 = ui.Gradient.radial(
      Offset(size.width * 0.30, size.height * 0.5),
      size.width * 0.5,
      [accent.withValues(alpha: (0.7 + low * 0.3).clamp(0.0, 1.0)), accent.withValues(alpha: 0)],
    );
    canvas.drawRect(Offset.zero & size, Paint()..shader = g1);

    final g2 = ui.Gradient.radial(
      Offset(size.width * 0.70, size.height * 0.5),
      size.width * 0.45,
      [blue.withValues(alpha: (0.5 + hi * 0.5).clamp(0.0, 1.0)), blue.withValues(alpha: 0)],
    );
    canvas.drawRect(Offset.zero & size, Paint()..shader = g2);

    final centerC = Offset(size.width / 2, size.height / 2);
    for (var k = 0; k < 3; k++) {
      final rPx = (12 + k * 8 + low * (14 + k * 6)) * size.height / 100;
      canvas.drawCircle(
        centerC,
        rPx,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = accent.withValues(alpha: ((0.5 - k * 0.12) * (0.6 + low)).clamp(0.0, 1.0))
          ..strokeWidth = (0.4 + low * 0.8) * size.height / 50,
      );
    }

    canvas.drawLine(
      Offset(progress * size.width, 0),
      Offset(progress * size.width, size.height),
      Paint()
        ..color = accent.withValues(alpha: 0.5)
        ..strokeWidth = 1,
    );

    final glow = energy.clamp(0.0, 1.0);
    if (glow > 0.001) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = Colors.white.withValues(alpha: glow * 0.05),
      );
    }
  }

  void _paintOscilloscope(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12));
    canvas.drawRRect(rrect, Paint()..color = const Color(0x05FFFFFF));
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0x0FFFFFFF)
        ..strokeWidth = 1,
    );

    final gridPaint = Paint()
      ..color = const Color(0x0AFFFFFF)
      ..strokeWidth = 0.6;
    for (final f in [0.25, 0.5, 0.75]) {
      canvas.drawLine(
        Offset(0, size.height * f),
        Offset(size.width, size.height * f),
        gridPaint,
      );
    }

    final pts = levels.length;
    final step = size.width / (pts - 1);
    final path = Path();
    for (var i = 0; i < pts; i++) {
      final v = levels[i];
      final sign = i.isEven ? 1 : -1;
      final y = size.height / 2 + sign * v * size.height * 0.42;
      final x = i * step;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = accent.withValues(alpha: 0.3),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.4)
        ..color = accent,
    );
    canvas.drawLine(
      Offset(progress * size.width, 0),
      Offset(progress * size.width, size.height),
      Paint()
        ..color = const Color(0x40FFFFFF)
        ..strokeWidth = 0.6,
    );
  }

  @override
  bool shouldRepaint(_VisualizerPainter old) => true;
}
