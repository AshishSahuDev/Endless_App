import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

ThemeData buildDarkTheme() {
  final base = ThemeData(brightness: Brightness.dark);
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: kBgPrimary,
    fontFamily: GoogleFonts.sora().fontFamily,
    colorScheme: const ColorScheme.dark(
      primary: kAccentPurple,
      secondary: kAccentPink,
      surface: kBgSecondary,
      error: Color(0xFFEF4444),
    ),
    textTheme: GoogleFonts.soraTextTheme(base.textTheme).apply(
      bodyColor: kTextPrimary,
      displayColor: kTextPrimary,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: kBgPrimary,
      elevation: 0,
      iconTheme: const IconThemeData(color: kTextPrimary),
      titleTextStyle: GoogleFonts.sora(
        color: kTextPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: kAccentPurple,
      foregroundColor: Colors.white,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: kBgTertiary,
      contentTextStyle: TextStyle(color: kTextPrimary),
    ),
    dialogTheme: const DialogThemeData(backgroundColor: kBgSecondary),
    useMaterial3: true,
  );
}
