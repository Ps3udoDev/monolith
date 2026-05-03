import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';

/// Splash. Aesthetic notes:
/// - OLED-true black, magenta accent, restrained (no logo image, no spinner).
/// - The waveform is the identity: bars erupt, then settle into a quiet idle pulse.
/// - Wordmark letters reveal staggered. A hairline progress fills under it.
/// - Mono caption pins the "local" ethos. Whole thing fades to the home route.
class SplashScreen extends StatefulWidget {
  final Duration duration;
  final VoidCallback onDone;

  const SplashScreen({
    super.key,
    this.duration = const Duration(milliseconds: 2200),
    required this.onDone,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _ringPulse;
  bool _exiting = false;

  static const _word = 'MONOLITH';

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration);
    _ringPulse = CurvedAnimation(parent: _c, curve: Curves.easeInOut);
    _c.forward().then((_) async {
      if (!mounted) return;
      setState(() => _exiting = true);
      await Future<void>.delayed(const Duration(milliseconds: 320));
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppTokens.accent();
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInCubic,
      opacity: _exiting ? 0 : 1,
      child: ColoredBox(
        color: AppTokens.bg,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedBuilder(
              animation: _ringPulse,
              builder: (_, _) => Center(
                child: SizedBox(
                  width: 360,
                  height: 360,
                  child: CustomPaint(
                    painter: _GlowPainter(
                      accent: accent,
                      energy: 0.3 + 0.5 * _ringPulse.value,
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _c,
                      builder: (_, _) {
                        // Bars: 0..0.4 erupt; after settle into idle breathing.
                        final t = _c.value;
                        return SizedBox(
                          width: 240,
                          height: 64,
                          child: CustomPaint(
                            painter: _SplashBarsPainter(
                              t: t,
                              accent: accent,
                              seed: 7,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 22),
                    _Wordmark(progress: _c, accent: accent, word: _word),
                    const SizedBox(height: 28),
                    AnimatedBuilder(
                      animation: _c,
                      builder: (_, _) => SizedBox(
                        width: 200,
                        child: _ProgressHairline(progress: _c.value),
                      ),
                    ),
                    const SizedBox(height: 20),
                    AnimatedBuilder(
                      animation: _c,
                      builder: (_, _) {
                        // caption fades in 0.5..0.8
                        final f = ((_c.value - 0.5) / 0.3).clamp(0.0, 1.0);
                        return Opacity(
                          opacity: f,
                          child: Text(
                            'LOCAL · 100% ON DEVICE',
                            style: AppType.mono(
                              size: 10.5,
                              color: AppTokens.dim,
                              letterSpacing: 2.4,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  final AnimationController progress;
  final Color accent;
  final String word;
  const _Wordmark({required this.progress, required this.accent, required this.word});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (_, _) {
        final t = progress.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < word.length; i++) _Letter(
              char: word[i],
              t: t,
              startAt: 0.18 + i * 0.04,
              endAt: 0.18 + i * 0.04 + 0.18,
              accent: accent,
              isAccent: i == word.length - 1,
            ),
          ],
        );
      },
    );
  }
}

class _Letter extends StatelessWidget {
  final String char;
  final double t;
  final double startAt;
  final double endAt;
  final Color accent;
  final bool isAccent;

  const _Letter({
    required this.char,
    required this.t,
    required this.startAt,
    required this.endAt,
    required this.accent,
    this.isAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    final raw = ((t - startAt) / (endAt - startAt)).clamp(0.0, 1.0);
    final eased = Curves.easeOutCubic.transform(raw);
    return Opacity(
      opacity: eased,
      child: Transform.translate(
        offset: Offset(0, (1 - eased) * 6),
        child: Text(
          char,
          style: AppType.sans(
            size: 30,
            weight: FontWeight.w500,
            color: AppTokens.fg,
            letterSpacing: -0.6,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _ProgressHairline extends StatelessWidget {
  final double progress;
  const _ProgressHairline({required this.progress});

  @override
  Widget build(BuildContext context) {
    final accent = AppTokens.accent();
    final eased = Curves.easeInOutCubic.transform(progress);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 2,
        color: AppTokens.surface3,
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: eased,
            child: Container(
              decoration: BoxDecoration(
                color: accent,
                boxShadow: [BoxShadow(color: AppTokens.accentSoft(), blurRadius: 10)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashBarsPainter extends CustomPainter {
  final double t;
  final Color accent;
  final int seed;
  _SplashBarsPainter({required this.t, required this.accent, required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    const bins = 32;
    final gap = size.width / bins;
    final w = gap * 0.42;
    final tt = t.clamp(0.0, 1.0);
    final time = tt * 6.28;
    final paint = Paint()..color = accent;

    for (var i = 0; i < bins; i++) {
      final freq = (i - bins / 2).abs() / (bins / 2);
      final s = (i * 9301 + seed * 49297) % 233280 / 233280;
      final mid = math.sin(time * 1.7 + i * 0.5 + seed) * 0.5 + 0.5;
      // amplitude shape: tallest at center, decaying outward + live mid
      final live = (1 - freq) * (0.35 + 0.65 * mid);
      final idle = 0.06 + 0.04 * math.sin(time * 0.6 + i * 0.3);
      final v = idle + (live + s * 0.15) * 0.95;
      final h = math.max(2.0, math.min(1.0, v) * size.height * 0.95);
      final x = i * gap + (gap - w) / 2;
      final y = size.height / 2 - h / 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(w / 2)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SplashBarsPainter old) => old.t != t;
}

class _GlowPainter extends CustomPainter {
  final Color accent;
  final double energy;
  _GlowPainter({required this.accent, required this.energy});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.5;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [
            accent.withValues(alpha: (0.10 * energy).clamp(0.0, 1.0)),
            accent.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: r))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 36),
    );
  }

  @override
  bool shouldRepaint(_GlowPainter old) => old.energy != energy;
}
