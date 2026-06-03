import 'package:flutter/material.dart';

// Dark theme (primary)
const kBgPrimary = Color(0xFF0A0A0F);
const kBgSecondary = Color(0xFF12121A);
const kBgTertiary = Color(0xFF1A1A26);

// Accent palette
const kAccentPurple = Color(0xFF7C3AED);
const kAccentPink = Color(0xFFEC4899);
const kAccentBlue = Color(0xFF3B82F6);
const kAccentGreen = Color(0xFF10B981);
const kAccentOrange = Color(0xFFF59E0B);

// Glass
const kGlassBg = Color(0x1AFFFFFF);
const kGlassBorder = Color(0x33FFFFFF);

// Text
const kTextPrimary = Color(0xFFFFFFFF);
const kTextSecondary = Color(0xFFB0B0C8);
const kTextHint = Color(0xFF6B6B80);

// Note colors (color picker palette)
const kNoteColors = [
  Color(0xFF1A1A26), // default dark
  Color(0xFF1A1040), // purple tint
  Color(0xFF100A1A), // deep purple
  Color(0xFF0D1A2E), // blue tint
  Color(0xFF0D1A18), // teal tint
  Color(0xFF1A0D0D), // red tint
  Color(0xFF1A1200), // amber tint
  Color(0xFF0D1A0D), // green tint
];

// Gradient presets
const kGradientPurplePink = LinearGradient(
  colors: [kAccentPurple, kAccentPink],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const kGradientBluePurple = LinearGradient(
  colors: [kAccentBlue, kAccentPurple],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);
