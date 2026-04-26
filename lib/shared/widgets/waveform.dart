import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/format.dart';

class WaveformLine extends StatelessWidget {
  final int seed;
  final int bars;
  final double height;
  final Color color;
  final double opacity;

  const WaveformLine({
    super.key,
    this.seed = 7,
    this.bars = 48,
    this.height = 24,
    this.color = AppTokens.fg,
    this.opacity = 0.7,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _WaveformLinePainter(seed: seed, bars: bars, color: color),
        ),
      ),
    );
  }
}

class _WaveformLinePainter extends CustomPainter {
  final int seed;
  final int bars;
  final Color color;
  _WaveformLinePainter({required this.seed, required this.bars, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final vals = waveformBars(seed, bars);
    final gap = size.width / bars;
    final w = gap * 0.45;
    final paint = Paint()..color = color;
    for (var i = 0; i < bars; i++) {
      final v = math.max(0.05, vals[i]);
      final h = v * size.height * 0.9;
      final x = i * gap + (gap - w) / 2;
      final y = size.height / 2 - h / 2;
      final r = w / 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformLinePainter old) =>
      old.seed != seed || old.bars != bars || old.color != color;
}

class StaticWaveform extends StatelessWidget {
  final int seed;
  final int bars;
  final double height;
  final double progress;
  final Color accent;
  final Color dim;
  final bool playing;

  const StaticWaveform({
    super.key,
    required this.seed,
    this.bars = 64,
    this.height = 80,
    this.progress = 0,
    required this.accent,
    this.dim = const Color(0x2EFFFFFF),
    this.playing = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _StaticWaveformPainter(
          seed: seed,
          bars: bars,
          progress: progress,
          accent: accent,
          dim: dim,
          playing: playing,
        ),
      ),
    );
  }
}

class _StaticWaveformPainter extends CustomPainter {
  final int seed;
  final int bars;
  final double progress;
  final Color accent;
  final Color dim;
  final bool playing;
  _StaticWaveformPainter({
    required this.seed,
    required this.bars,
    required this.progress,
    required this.accent,
    required this.dim,
    required this.playing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final vals = waveformBars(seed, bars);
    final gap = size.width / bars;
    final w = gap * 0.55;
    for (var i = 0; i < bars; i++) {
      final v = math.max(0.08, vals[i]);
      final h = v * size.height * 0.92;
      final x = i * gap + (gap - w) / 2;
      final y = size.height / 2 - h / 2;
      final frac = (i + 0.5) / bars;
      final played = frac <= progress;
      final paint = Paint()..color = played ? accent : dim;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(w / 2)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StaticWaveformPainter old) =>
      old.seed != seed ||
      old.bars != bars ||
      old.progress != progress ||
      old.accent != accent ||
      old.dim != dim ||
      old.playing != playing;
}
