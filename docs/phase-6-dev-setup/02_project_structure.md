# Project Structure & pubspec.yaml
**Project:** Endless App | **Version:** 1.0 | **Date:** 2026-06-03 | **Author:** Ashish Sahu

---

## pubspec.yaml

```yaml
name: endless
description: Notes, Tasks, Reminders, Alarms & Money Manager — one app for Gen-Z
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.3.0 <4.0.0'
  flutter: ">=3.24.0"

dependencies:
  flutter:
    sdk: flutter

  # ── State Management ──────────────────────────────────
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5

  # ── Local Database ────────────────────────────────────
  isar: ^3.1.0+1
  isar_flutter_libs: ^3.1.0+1   # native Isar binaries for Flutter

  # ── Alarms & Notifications ────────────────────────────
  alarm: ^4.0.2
  flutter_local_notifications: ^17.2.2
  permission_handler: ^11.3.1   # request exact alarm + notification permissions
  timezone: ^0.9.4              # for timezone-aware notification scheduling

  # ── Navigation ────────────────────────────────────────
  go_router: ^14.2.0

  # ── Charts ───────────────────────────────────────────
  fl_chart: ^0.68.0

  # ── Animations ───────────────────────────────────────
  flutter_animate: ^4.5.0
  lottie: ^3.1.2                # Lottie JSON animations (confetti etc.)

  # ── UI Components ─────────────────────────────────────
  flutter_slidable: ^3.1.1      # swipe-to-action on list items
  drag_and_drop_lists: ^0.4.2   # drag-and-drop task reorder
  glassmorphism: ^3.0.0         # glassmorphism cards

  # ── Typography & Icons ────────────────────────────────
  google_fonts: ^6.2.1          # Sora, Plus Jakarta Sans, Space Grotesk, Fira Code
  iconsax: ^0.0.8               # Gen-Z icon set

  # ── Security ─────────────────────────────────────────
  local_auth: ^2.2.0            # biometric + PIN authentication

  # ── Date & Number Formatting ──────────────────────────
  intl: ^0.19.0                 # date formatting, number formatting with locale

  # ── Utilities ────────────────────────────────────────
  path_provider: ^2.1.4         # get app documents directory for Isar
  shared_preferences: ^2.3.2    # lightweight key-value (theme, onboarding flag)
  uuid: ^4.4.2                  # generate unique IDs where needed
  collection: ^1.18.0           # groupBy utility for transaction grouping

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0         # lint rules
  build_runner: ^2.4.12         # code generation (Riverpod + Isar)
  isar_generator: ^3.1.0+1      # generates Isar schema code
  riverpod_generator: ^2.4.3    # generates @riverpod provider boilerplate
  custom_lint: ^0.6.7           # riverpod_lint dependency
  riverpod_lint: ^2.3.13        # Riverpod-specific lint rules

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/animations/        # Lottie JSON files
    - assets/sounds/            # alarm sound files (.mp3)
  fonts:
    - family: Sora
      fonts:
        - asset: assets/fonts/Sora-Regular.ttf
        - asset: assets/fonts/Sora-Medium.ttf   weight: 500
        - asset: assets/fonts/Sora-SemiBold.ttf weight: 600
        - asset: assets/fonts/Sora-Bold.ttf     weight: 700
```

---

## Complete Folder Structure

```
endless/
│
├── pubspec.yaml
├── pubspec.lock
├── analysis_options.yaml
├── README.md
│
├── android/                         ← Android native config
│   └── app/src/main/
│       ├── AndroidManifest.xml      ← permissions (see setup guide)
│       └── res/
│           └── drawable/            ← launcher icon, notification icons
│
├── ios/                             ← iOS native config
│   └── Runner/
│       ├── Info.plist               ← NSUserNotificationUsageDescription etc.
│       └── AppDelegate.swift        ← alarm package setup
│
├── assets/
│   ├── animations/
│   │   ├── confetti.json            ← savings goal celebration
│   │   ├── empty_notes.json         ← empty state illustration
│   │   ├── empty_tasks.json
│   │   └── onboarding_money.json
│   ├── images/
│   │   ├── logo.png
│   │   └── icon.png
│   └── sounds/
│       ├── alarm_default.mp3
│       ├── alarm_gentle.mp3
│       ├── alarm_digital.mp3
│       ├── alarm_birds.mp3
│       └── alarm_classic.mp3
│
└── lib/
    │
    ├── main.dart                    ← app entry point, Riverpod ProviderScope
    ├── app.dart                     ← MaterialApp, theme, GoRouter setup
    │
    ├── core/
    │   ├── constants/
    │   │   ├── app_colors.dart      ← all color constants (dark + light)
    │   │   ├── app_text_styles.dart ← all TextStyle definitions
    │   │   ├── app_sizes.dart       ← spacing, radius constants
    │   │   └── app_strings.dart     ← all user-visible strings
    │   │
    │   ├── theme/
    │   │   ├── app_theme.dart       ← ThemeData for dark + light
    │   │   └── theme_provider.dart  ← Riverpod provider for ThemeMode
    │   │
    │   ├── database/
    │   │   ├── isar_service.dart    ← Isar.open() + singleton
    │   │   └── database_provider.dart ← Riverpod provider for Isar instance
    │   │
    │   ├── navigation/
    │   │   ├── app_router.dart      ← GoRouter configuration, all routes
    │   │   └── bottom_nav.dart      ← BottomNavBar widget with animated pill
    │   │
    │   ├── errors/
    │   │   └── app_exceptions.dart  ← custom exception classes
    │   │
    │   ├── utils/
    │   │   ├── date_utils.dart      ← formatDate(), isToday(), groupByDate()
    │   │   ├── currency_utils.dart  ← formatCurrency(), parseCurrency()
    │   │   └── result.dart          ← Result<T> sealed class
    │   │
    │   └── widgets/                 ← reusable UI components
    │       ├── app_button.dart      ← PrimaryButton, GhostButton
    │       ├── glass_card.dart      ← GlassmorphismCard widget
    │       ├── empty_state.dart     ← EmptyStateWidget (Lottie + text)
    │       ├── error_state.dart     ← ErrorStateWidget
    │       ├── confirm_dialog.dart  ← DeleteConfirmDialog
    │       ├── gradient_text.dart   ← GradientText widget
    │       └── loading_overlay.dart ← LoadingOverlay widget
    │
    ├── features/
    │   │
    │   ├── onboarding/
    │   │   ├── presentation/
    │   │   │   ├── screens/
    │   │   │   │   ├── splash_screen.dart
    │   │   │   │   └── onboarding_screen.dart
    │   │   │   └── providers/
    │   │   │       └── onboarding_provider.dart
    │   │   └── domain/
    │   │       └── use_cases/
    │   │           └── complete_onboarding_use_case.dart
    │   │
    │   ├── notes/
    │   │   ├── data/
    │   │   │   ├── models/
    │   │   │   │   ├── note_model.dart        ← Isar @collection
    │   │   │   │   └── note_model.g.dart      ← generated by isar_generator
    │   │   │   ├── datasources/
    │   │   │   │   └── note_local_datasource.dart ← raw Isar queries
    │   │   │   └── repositories/
    │   │   │       └── note_repository_impl.dart  ← implements NoteRepository
    │   │   │
    │   │   ├── domain/
    │   │   │   ├── entities/
    │   │   │   │   └── note.dart              ← pure Dart entity
    │   │   │   ├── repositories/
    │   │   │   │   └── note_repository.dart   ← abstract interface
    │   │   │   └── use_cases/
    │   │   │       ├── create_note_use_case.dart
    │   │   │       ├── update_note_use_case.dart
    │   │   │       ├── delete_note_use_case.dart
    │   │   │       ├── toggle_pin_use_case.dart
    │   │   │       ├── toggle_archive_use_case.dart
    │   │   │       └── search_notes_use_case.dart
    │   │   │
    │   │   └── presentation/
    │   │       ├── screens/
    │   │       │   ├── notes_list_screen.dart
    │   │       │   └── note_editor_screen.dart
    │   │       ├── widgets/
    │   │       │   ├── note_card.dart
    │   │       │   └── color_picker.dart
    │   │       └── providers/
    │   │           └── notes_provider.dart    ← @riverpod NotesNotifier
    │   │
    │   ├── tasks/                   ← same structure as notes/
    │   │   ├── data/
    │   │   ├── domain/
    │   │   └── presentation/
    │   │
    │   ├── reminders/               ← same structure
    │   │   ├── data/
    │   │   ├── domain/
    │   │   └── presentation/
    │   │
    │   ├── alarms/                  ← same structure
    │   │   ├── data/
    │   │   ├── domain/
    │   │   └── presentation/
    │   │
    │   ├── money/                   ← same structure
    │   │   ├── data/
    │   │   │   ├── models/          ← TransactionModel, CategoryModel, SavingsGoalModel
    │   │   │   ├── datasources/
    │   │   │   └── repositories/
    │   │   ├── domain/
    │   │   │   ├── entities/
    │   │   │   ├── repositories/
    │   │   │   └── use_cases/       ← add_transaction, get_monthly_summary, etc.
    │   │   └── presentation/
    │   │       ├── screens/         ← dashboard, history, charts, goals
    │   │       ├── widgets/         ← transaction_card, budget_bar, chart_widgets
    │   │       └── providers/
    │   │
    │   └── settings/
    │       ├── data/
    │       │   └── repositories/
    │       │       └── settings_repository_impl.dart
    │       ├── domain/
    │       │   ├── entities/
    │       │   │   └── app_settings.dart
    │       │   └── repositories/
    │       │       └── settings_repository.dart
    │       └── presentation/
    │           ├── screens/
    │           │   ├── settings_screen.dart
    │           │   └── app_lock_screen.dart
    │           └── providers/
    │               └── settings_provider.dart
    │
    └── test/                        ← mirrors lib/ structure
        ├── core/
        │   └── utils/
        ├── features/
        │   ├── notes/
        │   │   ├── data/
        │   │   ├── domain/
        │   │   └── presentation/
        │   └── money/
        └── helpers/
            └── test_helpers.dart    ← mock Isar, test factories
```

---

## main.dart

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/database/isar_service.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Isar database
  final isarService = IsarService();
  await isarService.init();

  runApp(
    ProviderScope(
      overrides: [
        isarServiceProvider.overrideWithValue(isarService),
      ],
      child: const EndlessApp(),
    ),
  );
}
```

---

## Code Generation Commands

Run these after modifying Isar models or Riverpod providers:

```bash
# One-time generation
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode (auto-regenerates on save — use during development)
flutter pub run build_runner watch --delete-conflicting-outputs
```

---

*Document: 02_project_structure.md | Phase 6 — Dev Environment Setup*
