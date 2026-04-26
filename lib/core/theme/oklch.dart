import 'dart:math' as math;
import 'package:flutter/material.dart';

Color oklch(double l, double c, double h, [double alpha = 1.0]) {
  final hr = h * math.pi / 180.0;
  final aLab = c * math.cos(hr);
  final bLab = c * math.sin(hr);

  final lp = l + 0.3963377774 * aLab + 0.2158037573 * bLab;
  final mp = l - 0.1055613458 * aLab - 0.0638541728 * bLab;
  final sp = l - 0.0894841775 * aLab - 1.2914855480 * bLab;

  final L = lp * lp * lp;
  final M = mp * mp * mp;
  final S = sp * sp * sp;

  double r = 4.0767416621 * L - 3.3077115913 * M + 0.2309699292 * S;
  double g = -1.2684380046 * L + 2.6097574011 * M - 0.3413193965 * S;
  double b = -0.0041960863 * L - 0.7034186147 * M + 1.7076147010 * S;

  double encode(double v) {
    if (v <= 0) return 0;
    if (v >= 1) return 1;
    return v >= 0.0031308
        ? 1.055 * math.pow(v, 1 / 2.4) - 0.055
        : 12.92 * v;
  }

  return Color.from(
    alpha: alpha,
    red: encode(r),
    green: encode(g),
    blue: encode(b),
  );
}
