import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';

class LoadingBars extends StatefulWidget {
  final double size;
  final Color? color;
  final int barCount;

  const LoadingBars({
    super.key,
    this.size = 26,
    this.color,
    this.barCount = 3,
  });

  @override
  State<LoadingBars> createState() => _LoadingBarsState();
}

class _LoadingBarsState extends State<LoadingBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppTokens.accent();
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, _) => CustomPaint(
          painter: _LoadingBarsPainter(
            t: _ctrl.value,
            color: color,
            barCount: widget.barCount,
          ),
        ),
      ),
    );
  }
}

class _LoadingBarsPainter extends CustomPainter {
  final double t;
  final Color color;
  final int barCount;

  _LoadingBarsPainter({
    required this.t,
    required this.color,
    required this.barCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final time = t * 2 * math.pi;
    final w = size.width / (barCount * 2.2);
    final totalBarsWidth = w * barCount;
    final gap = (size.width - totalBarsWidth) / (barCount + 1);
    final paint = Paint()..color = color;

    for (var i = 0; i < barCount; i++) {
      final phase = i * (2 * math.pi / barCount);
      final amp = math.sin(time + phase) * 0.5 + 0.5; // 0..1
      final h = (0.32 + amp * 0.6) * size.height;
      final x = gap + i * (w + gap);
      final y = (size.height - h) / 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, w, h),
          Radius.circular(w / 2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_LoadingBarsPainter old) =>
      old.t != t || old.color != color || old.barCount != barCount;
}
