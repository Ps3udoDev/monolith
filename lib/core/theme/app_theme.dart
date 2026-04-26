import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tokens.dart';

ThemeData buildAppTheme() {
  final accent = AppTokens.accent();
  final scheme = ColorScheme(
    brightness: Brightness.dark,
    primary: accent,
    onPrimary: const Color(0xFF0A0A0C),
    secondary: accent,
    onSecondary: const Color(0xFF0A0A0C),
    surface: AppTokens.bg,
    onSurface: AppTokens.fg,
    surfaceContainerLowest: AppTokens.bg,
    surfaceContainerLow: AppTokens.surface1,
    surfaceContainer: AppTokens.surface2,
    surfaceContainerHigh: AppTokens.surface3,
    surfaceContainerHighest: AppTokens.surface3,
    error: const Color(0xFFFF6B7A),
    onError: const Color(0xFF0A0A0C),
  );

  final textTheme = GoogleFonts.manropeTextTheme(ThemeData.dark().textTheme).apply(
    bodyColor: AppTokens.fg,
    displayColor: AppTokens.fg,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppTokens.bg,
    canvasColor: AppTokens.bg,
    splashColor: const Color(0x14FFFFFF),
    highlightColor: const Color(0x0AFFFFFF),
    hoverColor: const Color(0x0FFFFFFF),
    textTheme: textTheme,
    iconTheme: const IconThemeData(color: AppTokens.fg, size: 22),
    dividerColor: AppTokens.hairline,
    visualDensity: VisualDensity.standard,
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: ZoomPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    }),
  );
}
