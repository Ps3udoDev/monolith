import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tokens.dart';

class AppType {
  static TextStyle sans({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = AppTokens.fg,
    double height = 1.3,
    double letterSpacing = 0,
  }) =>
      GoogleFonts.manrope(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  static TextStyle mono({
    double size = 11,
    FontWeight weight = FontWeight.w400,
    Color color = AppTokens.dim,
    double letterSpacing = 0.04,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
      );

  static TextStyle eyebrow({Color color = AppTokens.dim}) => mono(
        size: 10.5,
        weight: FontWeight.w500,
        color: color,
        letterSpacing: 1.5,
      );

  static TextStyle display({Color color = AppTokens.fg}) => sans(
        size: 32,
        weight: FontWeight.w500,
        color: color,
        height: 1.05,
        letterSpacing: -0.6,
      );

  static TextStyle title({Color color = AppTokens.fg}) => sans(
        size: 22,
        weight: FontWeight.w500,
        color: color,
        height: 1.2,
        letterSpacing: -0.3,
      );

  static TextStyle body({Color color = AppTokens.fg, double size = 14.5}) =>
      sans(size: size, color: color, height: 1.4);

  static TextStyle caption({Color color = AppTokens.dim, double size = 12}) =>
      sans(size: size, color: color, height: 1.35);

  static TextStyle sectionLabel({Color color = AppTokens.dim2}) =>
      mono(size: 10.5, color: color, letterSpacing: 1.4);
}
