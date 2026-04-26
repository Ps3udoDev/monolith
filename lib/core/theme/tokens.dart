import 'package:flutter/material.dart';
import 'oklch.dart';

class AppTokens {
  static const Color bg = Color(0xFF05050A);
  static const Color surface1 = Color(0xFF0D0D12);
  static const Color surface2 = Color(0xFF15151C);
  static const Color surface3 = Color(0xFF1C1C25);
  static const Color fg = Color(0xFFF2F2F6);

  static const Color dim = Color(0x8CF2F2F6);
  static const Color dim2 = Color(0x5CF2F2F6);
  static const Color hairline = Color(0x0FFFFFFF);
  static const Color hairlineStrong = Color(0x1FFFFFFF);

  static const double accentL = 0.72;
  static const double accentC = 0.22;
  static const double accentHueDefault = 340;

  // Mutable so settings can re-tint the whole app at runtime without
  // threading the hue through every call site. Updated by PlayerState.setAccentHue.
  static double accentHueValue = accentHueDefault;

  static Color accent({double? hue}) =>
      oklch(accentL, accentC, hue ?? accentHueValue);
  static Color accentSoft({double? hue}) =>
      oklch(accentL, accentC, hue ?? accentHueValue, 0.18);

  static Color tonalLow(double hue) => oklch(0.22, 0.04, hue);
  static Color tonalLower(double hue) => oklch(0.14, 0.02, hue);
  static Color tonalSignature(double hue) => oklch(0.85, 0.09, hue);

  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 14;
  static const double radiusXl = 16;
  static const double radiusPill = 999;
}

class CoverTone {
  final Color a;
  final Color b;
  final double hue;
  const CoverTone({required this.a, required this.b, required this.hue});
}

const Map<String, CoverTone> kCoverTones = {
  'c-indigo': CoverTone(a: Color(0xFF1A2440), b: Color(0xFF3B4A7A), hue: 262),
  'c-clay': CoverTone(a: Color(0xFF3A1F18), b: Color(0xFF7A3A28), hue: 28),
  'c-moss': CoverTone(a: Color(0xFF1A2A22), b: Color(0xFF3D5A46), hue: 150),
  'c-sodium': CoverTone(a: Color(0xFF3A2A10), b: Color(0xFF9A6A20), hue: 45),
  'c-bone': CoverTone(a: Color(0xFF2A2824), b: Color(0xFF6A655A), hue: 40),
};
