import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/format.dart';

class Cover extends StatelessWidget {
  final String tone;
  final double size;
  final double radius;
  final int bars;
  final int seed;

  const Cover({
    super.key,
    this.tone = 'c-indigo',
    this.size = 56,
    this.radius = 10,
    this.bars = 18,
    this.seed = 7,
  });

  @override
  Widget build(BuildContext context) {
    final t = kCoverTones[tone] ?? kCoverTones['c-indigo']!;
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: CustomPaint(
          painter: _CoverPainter(tone: t, bars: bars, seed: seed),
          size: Size(size, size),
        ),
      ),
    );
  }
}

class _CoverPainter extends CustomPainter {
  final CoverTone tone;
  final int bars;
  final int seed;
  _CoverPainter({required this.tone, required this.bars, required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [tone.a, tone.b],
    );
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));

    final w = size.width;
    final h = size.height;
    canvas.drawLine(
      Offset(w * 0.08, h * 0.5),
      Offset(w * 0.92, h * 0.5),
      Paint()
        ..color = const Color(0x1AFFFFFF)
        ..strokeWidth = h * 0.007,
    );

    final vals = waveformBars(seed, bars);
    final gap = (w * 0.84) / bars;
    final barW = gap * 0.55;
    final barPaint = Paint()..color = const Color(0xD1FFFFFF);
    for (var i = 0; i < bars; i++) {
      final v = vals[i];
      final barH = h * 0.10 + v * h * 0.60;
      final x = w * 0.08 + i * gap + (gap - barW) / 2;
      final y = h * 0.5 - barH / 2;
      final r = barW / 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, barW, barH), Radius.circular(r)),
        barPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_CoverPainter oldDelegate) =>
      oldDelegate.tone != tone || oldDelegate.bars != bars || oldDelegate.seed != seed;
}
