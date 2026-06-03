import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

ThemeData buildDarkTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: kBgPrimary,
    colorScheme: const ColorScheme.dark(
      primary: kAccentPurple,
      secondary: kAccentPink,
      surface: kBgSecondary,
      error: Color(0xFFEF4444),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: kBgPrimary,
      elevation: 0,
      iconTheme: IconThemeData(color: kTextPrimary),
      titleTextStyle: TextStyle(color: kTextPrimary, fontSize: 20, fontWeight: FontWeight.bold),
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
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: kTextPrimary),
      bodySmall: TextStyle(color: kTextSecondary),
    ),
    useMaterial3: true,
  );
}
