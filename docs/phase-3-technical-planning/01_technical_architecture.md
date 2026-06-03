# Technical Architecture Document
## Endless — Personal Productivity & Finance App

---

| Field    | Value                            |
|----------|----------------------------------|
| Document | Technical Architecture Document  |
| Version  | 1.0                              |
| Date     | 2026-06-03                       |
| Author   | Ashish Sahu                      |
| Status   | Approved                         |
| Phase    | Phase 3 — Technical Planning     |

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Layer Responsibilities](#2-layer-responsibilities)
3. [Project Folder Structure](#3-project-folder-structure)
4. [Technology Stack](#4-technology-stack)
5. [Dependency Injection](#5-dependency-injection)
6. [State Management Patterns](#6-state-management-patterns)
7. [Navigation Strategy](#7-navigation-strategy)
8. [Background Processing Architecture](#8-background-processing-architecture)

---

## 1. Architecture Overview

Endless follows **Clean Architecture** combined with the **MVVM** (Model-View-ViewModel) presentation pattern. The codebase is organised into three distinct layers with strict unidirectional dependency flow: Presentation depends on Domain, Data depends on Domain, but Domain depends on nothing.

### 1.1 Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                     PRESENTATION LAYER                          │
│  ┌──────────────────┐   ┌────────────────────────────────────┐  │
│  │  Flutter Widgets  │   │    Riverpod Providers / Notifiers  │  │
│  │  (Screens, Pages) │◄──│  (StateNotifier, AsyncNotifier)   │  │
│  └──────────────────┘   └────────────────────────────────────┘  │
│                                    │                            │
│                          calls Use Cases via                    │
│                          Provider injection                     │
└─────────────────────────────────────┬───────────────────────────┘
                                      │  (depends on)
┌─────────────────────────────────────▼───────────────────────────┐
│                       DOMAIN LAYER                              │
│  ┌─────────────────┐  ┌──────────────────┐  ┌───────────────┐  │
│  │   Entities       │  │   Use Cases       │  │  Repository   │  │
│  │ (Pure Dart)      │  │ (Business Logic)  │  │  Interfaces   │  │
│  │ Note, Task, etc. │  │ CreateNote,       │  │  (abstract    │  │
│  └─────────────────┘  │ GetTasks, etc.    │  │   classes)    │  │
│                        └──────────────────┘  └───────────────┘  │
└─────────────────────────────────────┬───────────────────────────┘
                                      │  (implements)
┌─────────────────────────────────────▼───────────────────────────┐
│                        DATA LAYER                               │
│  ┌──────────────────────┐  ┌────────────────┐  ┌─────────────┐ │
│  │ Repository Impls      │  │  Isar Database │  │  Data Models│ │
│  │ (NoteRepositoryImpl)  │  │  (DataSource)  │  │ (NoteModel) │ │
│  │                       │──│               │──│ toEntity()  │ │
│  └──────────────────────┘  └────────────────┘  └─────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

### 1.2 Dependency Rule

- **Domain layer** has zero dependencies on Flutter, Isar, or any external package. It is pure Dart.
- **Data layer** imports Domain to implement repository interfaces; it imports Isar for persistence.
- **Presentation layer** imports Domain to call use cases; it imports Riverpod for state management and Flutter for widgets. It never imports Isar models directly.

### 1.3 Feature-First Organisation

Each of the five features (notes, tasks, reminders, alarms, money) is self-contained in its own directory under `lib/features/`. Each feature directory has its own `data/`, `domain/`, and `presentation/` subdirectories. Code in one feature module must not import directly from another feature's `data/` or `domain/` layers — cross-feature communication happens only via shared entities or through the `core/` module.

---

## 2. Layer Responsibilities

### 2.1 Presentation Layer

**Purpose:** Display data to the user and respond to user input. Contains all Flutter-specific code.

**Components:**

| Component         | Responsibility                                                                   |
|-------------------|----------------------------------------------------------------------------------|
| Screen/Page        | Top-level widget for a route; assembles sub-widgets; reads providers             |
| Widget (feature)  | Reusable UI component within a feature (e.g., `NoteCard`, `TaskListItem`)        |
| Provider (Riverpod)| Exposes state to the widget tree; calls use cases on user actions                |
| Notifier          | Holds and mutates state; delegates business logic exclusively to use cases       |

**Rules:**
- Screens must not contain business logic. Any conditional behaviour that depends on data must be in the Notifier or Use Case.
- Widgets should be `const` wherever possible.
- No `BuildContext` is stored in Notifiers.
- Providers are `@riverpod`-annotated and code-generated via `riverpod_annotation`.

**Example — Notes Presentation:**
```dart
// presentation/screens/notes_list_screen.dart
class NotesListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesListProvider);
    return notesAsync.when(
      data: (notes) => NoteGrid(notes: notes),
      loading: () => const NotesLoadingShimmer(),
      error: (e, _) => const ErrorDisplay(),
    );
  }
}
```

---

### 2.2 Domain Layer

**Purpose:** Encapsulate all business rules and application logic. Framework-agnostic pure Dart.

**Components:**

| Component            | Responsibility                                                                  |
|----------------------|---------------------------------------------------------------------------------|
| Entity               | Immutable data class representing a domain object (Note, Task, Transaction)    |
| Use Case             | Single-responsibility class; one public `execute()` or `call()` method          |
| Repository Interface | Abstract class defining the data contract; no implementation detail             |

**Rules:**
- No `import 'package:flutter/...'` anywhere in domain layer.
- No `import 'package:isar/...'` anywhere in domain layer.
- Entities use only Dart built-in types or other domain entities.
- Each use case file is named `verb_noun_use_case.dart` (e.g., `create_note_use_case.dart`).

**Example — Note Entity:**
```dart
// domain/entities/note.dart
class Note {
  final int id;
  final String title;
  final String body;
  final int colorIndex;
  final bool isPinned;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Note({
    required this.id,
    required this.title,
    required this.body,
    required this.colorIndex,
    required this.isPinned,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
  });

  Note copyWith({
    int? id, String? title, String? body, int? colorIndex,
    bool? isPinned, bool? isArchived, DateTime? createdAt, DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id, title: title ?? this.title, body: body ?? this.body,
      colorIndex: colorIndex ?? this.colorIndex, isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived, createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
```

**Example — Use Case:**
```dart
// domain/use_cases/create_note_use_case.dart
class CreateNoteUseCase {
  final NoteRepository _repository;
  CreateNoteUseCase(this._repository);

  Future<Note> call({
    required String title,
    required String body,
    int colorIndex = 0,
    bool isPinned = false,
  }) async {
    final now = DateTime.now();
    final note = Note(
      id: Isar.autoIncrement,
      title: title.trim(),
      body: body,
      colorIndex: colorIndex,
      isPinned: isPinned,
      isArchived: false,
      createdAt: now,
      updatedAt: now,
    );
    return _repository.createNote(note);
  }
}
```

---

### 2.3 Data Layer

**Purpose:** Implement repository interfaces using Isar. Handle all persistence and data mapping.

**Components:**

| Component              | Responsibility                                                                    |
|------------------------|-----------------------------------------------------------------------------------|
| Data Model (Isar)      | Isar-annotated collection class; maps to/from domain Entity                       |
| Repository Impl        | Implements domain Repository interface; uses Isar data source                    |
| Local Data Source      | Direct Isar DB operations; abstracted behind the repository                       |

**Rules:**
- All Isar write operations must be wrapped in `isar.writeTxn()`.
- Data models must implement `toEntity()` and provide `fromEntity()` static methods.
- Repository implementations catch Isar exceptions and rethrow as domain `DatabaseException`.

**Example — NoteModel:**
```dart
// data/models/note_model.dart
import 'package:isar/isar.dart';
import '../../domain/entities/note.dart';

part 'note_model.g.dart';

@Collection()
class NoteModel {
  Id id = Isar.autoIncrement;

  @Index(type: IndexType.value)
  late String title;

  late String body;
  late int colorIndex;
  late bool isPinned;
  late bool isArchived;
  late DateTime createdAt;

  @Index(type: IndexType.value)
  late DateTime updatedAt;

  Note toEntity() => Note(
    id: id, title: title, body: body, colorIndex: colorIndex,
    isPinned: isPinned, isArchived: isArchived,
    createdAt: createdAt, updatedAt: updatedAt,
  );

  static NoteModel fromEntity(Note note) {
    final model = NoteModel()
      ..id = note.id
      ..title = note.title
      ..body = note.body
      ..colorIndex = note.colorIndex
      ..isPinned = note.isPinned
      ..isArchived = note.isArchived
      ..createdAt = note.createdAt
      ..updatedAt = note.updatedAt;
    return model;
  }
}
```

---

## 3. Project Folder Structure

```
lib/
├── main.dart                          # App entry point, Isar init, ProviderScope
├── app.dart                           # MaterialApp.router, theme setup, GoRouter
│
├── core/
│   ├── constants/
│   │   ├── app_colors.dart            # All colour constants (hex values)
│   │   ├── app_strings.dart           # All string literals (no hardcoded strings in UI)
│   │   ├── app_sizes.dart             # Spacing, radius, icon size constants
│   │   └── app_assets.dart            # Asset path constants (images, Lottie files)
│   ├── theme/
│   │   ├── app_theme.dart             # ThemeData for dark and light themes
│   │   ├── app_text_styles.dart       # TextStyle definitions for all type roles
│   │   └── app_decorations.dart       # InputDecoration, CardDecoration helpers
│   ├── utils/
│   │   ├── date_formatter.dart        # DateTime → human-readable string helpers
│   │   ├── currency_formatter.dart    # double → "$1,234.56" with currency symbol
│   │   ├── validators.dart            # Common form field validators
│   │   └── debouncer.dart             # Timer-based debounce utility class
│   ├── widgets/
│   │   ├── app_button.dart            # Primary, ghost, icon button widgets
│   │   ├── app_card.dart              # Glassmorphism card widget
│   │   ├── app_fab.dart               # Gradient FAB widget
│   │   ├── app_bottom_sheet.dart      # Styled bottom sheet wrapper
│   │   ├── app_text_field.dart        # Floating-label text input widget
│   │   ├── app_chip.dart              # Pill chip / tag widget
│   │   ├── app_snackbar.dart          # Helper to show styled snackbars
│   │   ├── app_empty_state.dart       # Empty state illustration + message widget
│   │   ├── app_loading_shimmer.dart   # Shimmer loading placeholder widgets
│   │   └── confirmation_dialog.dart   # Reusable confirm/cancel dialog
│   ├── errors/
│   │   ├── exceptions.dart            # DatabaseException, AlarmException, etc.
│   │   └── failure.dart               # Sealed class for operation results
│   └── di/
│       └── isar_provider.dart         # Riverpod provider for Isar instance
│
├── features/
│   ├── notes/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── note_model.dart           # Isar collection class
│   │   │   │   └── note_model.g.dart         # Generated by build_runner
│   │   │   ├── datasources/
│   │   │   │   └── note_local_datasource.dart # Raw Isar queries
│   │   │   └── repositories/
│   │   │       └── note_repository_impl.dart  # Implements NoteRepository
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── note.dart                  # Pure Dart Note entity
│   │   │   ├── repositories/
│   │   │   │   └── note_repository.dart       # Abstract interface
│   │   │   └── use_cases/
│   │   │       ├── create_note_use_case.dart
│   │   │       ├── update_note_use_case.dart
│   │   │       ├── delete_note_use_case.dart
│   │   │       ├── get_all_notes_use_case.dart
│   │   │       ├── get_archived_notes_use_case.dart
│   │   │       ├── pin_note_use_case.dart
│   │   │       ├── archive_note_use_case.dart
│   │   │       └── search_notes_use_case.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── notes_list_provider.dart   # @riverpod AsyncNotifier
│   │       │   └── note_editor_provider.dart
│   │       ├── screens/
│   │       │   ├── notes_list_screen.dart
│   │       │   ├── note_editor_screen.dart
│   │       │   └── notes_archive_screen.dart
│   │       └── widgets/
│   │           ├── note_card.dart
│   │           ├── note_color_picker.dart
│   │           └── notes_grid.dart
│   │
│   ├── tasks/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── task_model.dart
│   │   │   │   └── task_category_model.dart
│   │   │   ├── datasources/
│   │   │   │   └── task_local_datasource.dart
│   │   │   └── repositories/
│   │   │       └── task_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── task.dart
│   │   │   │   └── task_category.dart
│   │   │   ├── repositories/
│   │   │   │   └── task_repository.dart
│   │   │   └── use_cases/
│   │   │       ├── create_task_use_case.dart
│   │   │       ├── update_task_use_case.dart
│   │   │       ├── delete_task_use_case.dart
│   │   │       ├── complete_task_use_case.dart
│   │   │       ├── get_tasks_use_case.dart
│   │   │       ├── get_tasks_by_category_use_case.dart
│   │   │       └── reorder_tasks_use_case.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── tasks_list_provider.dart
│   │       │   └── task_categories_provider.dart
│   │       ├── screens/
│   │       │   ├── tasks_list_screen.dart
│   │       │   └── task_categories_screen.dart
│   │       └── widgets/
│   │           ├── task_list_item.dart
│   │           ├── task_creation_sheet.dart
│   │           ├── priority_selector.dart
│   │           └── task_filter_chips.dart
│   │
│   ├── reminders/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── reminder_model.dart
│   │   │   ├── datasources/
│   │   │   │   └── reminder_local_datasource.dart
│   │   │   └── repositories/
│   │   │       └── reminder_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── reminder.dart
│   │   │   ├── repositories/
│   │   │   │   └── reminder_repository.dart
│   │   │   └── use_cases/
│   │   │       ├── create_reminder_use_case.dart
│   │   │       ├── update_reminder_use_case.dart
│   │   │       ├── delete_reminder_use_case.dart
│   │   │       ├── get_reminders_use_case.dart
│   │   │       ├── snooze_reminder_use_case.dart
│   │   │       └── toggle_reminder_use_case.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── reminders_provider.dart
│   │       ├── screens/
│   │       │   ├── reminders_list_screen.dart
│   │       │   └── reminder_create_screen.dart
│   │       └── widgets/
│   │           ├── reminder_card.dart
│   │           └── recurrence_selector.dart
│   │
│   ├── alarms/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── alarm_model.dart
│   │   │   ├── datasources/
│   │   │   │   └── alarm_local_datasource.dart
│   │   │   └── repositories/
│   │   │       └── alarm_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── alarm.dart
│   │   │   ├── repositories/
│   │   │   │   └── alarm_repository.dart
│   │   │   └── use_cases/
│   │   │       ├── create_alarm_use_case.dart
│   │   │       ├── update_alarm_use_case.dart
│   │   │       ├── delete_alarm_use_case.dart
│   │   │       ├── toggle_alarm_use_case.dart
│   │   │       └── get_alarms_use_case.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── alarms_provider.dart
│   │       ├── screens/
│   │       │   ├── alarms_list_screen.dart
│   │       │   ├── alarm_create_screen.dart
│   │       │   └── alarm_ringing_screen.dart
│   │       └── widgets/
│   │           ├── alarm_list_item.dart
│   │           ├── alarm_time_picker.dart
│   │           ├── alarm_sound_picker.dart
│   │           └── repeat_days_selector.dart
│   │
│   └── money/
│       ├── data/
│       │   ├── models/
│       │   │   ├── transaction_model.dart
│       │   │   ├── transaction_category_model.dart
│       │   │   └── savings_goal_model.dart
│       │   ├── datasources/
│       │   │   └── money_local_datasource.dart
│       │   └── repositories/
│       │       └── money_repository_impl.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   ├── transaction.dart
│       │   │   ├── transaction_category.dart
│       │   │   └── savings_goal.dart
│       │   ├── repositories/
│       │   │   └── money_repository.dart
│       │   └── use_cases/
│       │       ├── add_transaction_use_case.dart
│       │       ├── update_transaction_use_case.dart
│       │       ├── delete_transaction_use_case.dart
│       │       ├── get_transactions_use_case.dart
│       │       ├── get_transactions_by_date_range_use_case.dart
│       │       ├── get_monthly_summary_use_case.dart
│       │       ├── check_budget_alert_use_case.dart
│       │       ├── create_savings_goal_use_case.dart
│       │       ├── update_savings_goal_use_case.dart
│       │       └── get_category_spending_use_case.dart
│       └── presentation/
│           ├── providers/
│           │   ├── transactions_provider.dart
│           │   ├── money_summary_provider.dart
│           │   ├── savings_goals_provider.dart
│           │   └── budget_alert_provider.dart
│           ├── screens/
│           │   ├── money_dashboard_screen.dart
│           │   ├── charts_screen.dart
│           │   ├── transaction_history_screen.dart
│           │   └── savings_goals_screen.dart
│           └── widgets/
│               ├── transaction_list_item.dart
│               ├── add_transaction_sheet.dart
│               ├── summary_card.dart
│               ├── budget_progress_bar.dart
│               ├── savings_goal_card.dart
│               ├── pie_chart_widget.dart
│               ├── bar_chart_widget.dart
│               └── line_chart_widget.dart
│
├── navigation/
│   ├── app_router.dart                # GoRouter configuration, all route definitions
│   ├── bottom_nav_bar.dart            # Custom animated bottom navigation bar widget
│   └── routes.dart                   # Route name constants
│
└── settings/
    ├── data/
    │   ├── models/
    │   │   └── app_settings_model.dart
    │   └── repositories/
    │       └── settings_repository_impl.dart
    ├── domain/
    │   ├── entities/
    │   │   └── app_settings.dart
    │   ├── repositories/
    │   │   └── settings_repository.dart
    │   └── use_cases/
    │       ├── get_settings_use_case.dart
    │       ├── update_theme_use_case.dart
    │       ├── update_currency_use_case.dart
    │       └── toggle_app_lock_use_case.dart
    └── presentation/
        ├── providers/
        │   └── settings_provider.dart
        └── screens/
            └── settings_screen.dart
```

---

## 4. Technology Stack

| Category             | Technology               | Version    | Justification                                                                   |
|----------------------|--------------------------|------------|---------------------------------------------------------------------------------|
| Framework            | Flutter                  | 3.x stable | Cross-platform, single codebase, Dart null-safety, 60fps rendering              |
| Language             | Dart                     | 3.x        | Null-safe, strong-typed, async/await, code generation support                   |
| State Management     | Riverpod                 | 2.4.x      | Provider replacement, testable, no BuildContext dependency, code generation    |
| Local Database       | Isar                     | 3.1.x      | Fastest Flutter-native NoSQL DB, reactive queries, excellent schema generation  |
| Routing              | GoRouter                 | 13.x       | Declarative, URL-based, deep link support, typed routes                         |
| Charts               | fl_chart                 | 0.66.x     | Feature-rich, customisable, supports pie/bar/line charts                        |
| Animations           | flutter_animate          | 4.3.x      | Chainable declarative animations, no boilerplate                                |
| Lottie               | lottie                   | 3.0.x      | Smooth vector animations (confetti, empty states)                               |
| Notifications        | flutter_local_notifications | 17.x    | Mature, supports Android/iOS, scheduled notifications, action buttons           |
| Alarms               | alarm                    | 4.0.x      | Dedicated alarm package with background wake-lock support                       |
| Fonts                | google_fonts             | 6.1.x      | Bundles Sora, Plus Jakarta Sans, Space Grotesk offline                          |
| Icons                | iconsax                  | 0.0.8      | Gen-Z aesthetic icon pack, 1000+ icons, outline + bold variants                 |
| Biometric Auth       | local_auth               | 2.1.x      | Fingerprint, Face ID, device credential fallback                                |
| Permissions          | permission_handler       | 11.x       | Unified permission API for Android and iOS                                      |
| Swipe Actions        | flutter_slidable         | 3.0.x      | Swipe-to-complete, swipe-to-delete with custom actions                          |
| Drag and Drop        | drag_and_drop_lists      | 0.4.x      | Task list reordering with smooth animations                                     |
| Glassmorphism        | glassmorphism            | 3.0.x      | Pre-built blurred glass card widgets                                            |
| Date/Number Format   | intl                     | 0.19.x     | Locale-aware date, time, and currency formatting                                |
| Path Provider        | path_provider            | 2.1.x      | Isar database file path resolution                                              |
| Code Gen (Riverpod)  | riverpod_annotation      | 2.3.x      | @riverpod annotation support                                                    |
| Code Gen (Isar)      | isar_generator           | 3.1.x      | Generates .g.dart schema files from annotations                                 |
| Build Runner         | build_runner             | 2.4.x      | Runs code generators                                                            |
| Linting              | flutter_lints            | 3.0.x      | Enforces Dart style guidelines                                                  |

---

## 5. Dependency Injection

Riverpod is used for all dependency injection. There is no manual `locator` or `GetIt` setup. Every dependency is a Riverpod provider, making the entire dependency graph testable and overridable.

### 5.1 Provider Hierarchy

```
isarProvider (FutureProvider<Isar>)
    │
    ├── noteDataSourceProvider (Provider<NoteLocalDataSource>)
    │       └── noteRepositoryProvider (Provider<NoteRepository>)
    │               ├── createNoteUseCaseProvider
    │               ├── updateNoteUseCaseProvider
    │               ├── deleteNoteUseCaseProvider
    │               └── ...
    │                       └── notesListProvider (AsyncNotifier)
    │
    ├── taskDataSourceProvider → taskRepositoryProvider → [task use case providers]
    │                                                              └── tasksListProvider
    │
    ├── reminderDataSourceProvider → reminderRepositoryProvider → [reminder use case providers]
    │
    ├── alarmDataSourceProvider → alarmRepositoryProvider → [alarm use case providers]
    │
    └── moneyDataSourceProvider → moneyRepositoryProvider → [money use case providers]
```

### 5.2 Isar Provider

```dart
// core/di/isar_provider.dart
@Riverpod(keepAlive: true)
Future<Isar> isar(IsarRef ref) async {
  final dir = await getApplicationDocumentsDirectory();
  return Isar.open(
    [
      NoteModelSchema, TaskModelSchema, TaskCategoryModelSchema,
      ReminderModelSchema, AlarmModelSchema, TransactionModelSchema,
      TransactionCategoryModelSchema, SavingsGoalModelSchema,
      AppSettingsModelSchema,
    ],
    directory: dir.path,
    name: 'endless_db',
  );
}
```

### 5.3 Repository Provider Example

```dart
// features/notes/data/repositories/note_repository_impl_provider.dart
@riverpod
NoteRepository noteRepository(NoteRepositoryRef ref) {
  final isar = ref.watch(isarProvider).requireValue;
  return NoteRepositoryImpl(NoteLocalDataSource(isar));
}
```

### 5.4 Use Case Provider Example

```dart
@riverpod
CreateNoteUseCase createNoteUseCase(CreateNoteUseCaseRef ref) {
  return CreateNoteUseCase(ref.watch(noteRepositoryProvider));
}
```

---

## 6. State Management Patterns

### 6.1 AsyncNotifier (for list screens with async data)

Used when state comes from async operations like database reads.

```dart
// features/notes/presentation/providers/notes_list_provider.dart
@riverpod
class NotesList extends _$NotesList {
  @override
  Future<List<Note>> build() async {
    final useCase = ref.watch(getAllNotesUseCaseProvider);
    return useCase();
  }

  Future<void> createNote({required String title, required String body, int colorIndex = 0}) async {
    final createUseCase = ref.read(createNoteUseCaseProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () async {
        await createUseCase(title: title, body: body, colorIndex: colorIndex);
        return ref.read(getAllNotesUseCaseProvider)();
      },
    );
  }

  Future<void> deleteNote(int id) async {
    final deleteUseCase = ref.read(deleteNoteUseCaseProvider);
    await deleteUseCase(id);
    ref.invalidateSelf();
  }
}
```

### 6.2 Notifier (for synchronous, simpler state)

Used for UI-only state like filter selection, search query, FAB visibility.

```dart
@riverpod
class TaskFilter extends _$TaskFilter {
  @override
  TaskFilterType build() => TaskFilterType.all;

  void setFilter(TaskFilterType filter) {
    state = filter;
  }
}
```

### 6.3 Provider (for simple, derived, or singleton values)

Used for use cases, repositories, and settings that do not change state themselves.

### 6.4 Reactive Database Queries (Isar Watch)

For real-time UI updates when the database changes (e.g., task completion updating the badge count):

```dart
@riverpod
Stream<int> incompleteTaskCount(IncompleteTaskCountRef ref) {
  final isar = ref.watch(isarProvider).requireValue;
  return isar.taskModels
      .filter()
      .isDoneEqualTo(false)
      .watch(fireImmediately: true)
      .map((tasks) => tasks.length);
}
```

---

## 7. Navigation Strategy

### 7.1 GoRouter Configuration

GoRouter is used as the app's router. All routes are defined centrally in `lib/navigation/app_router.dart`.

```dart
// navigation/app_router.dart
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.home,
    redirect: (context, state) async {
      final settings = await ref.read(getSettingsUseCaseProvider)();
      if (!settings.isOnboardingComplete) return Routes.onboarding;
      return null;
    },
    routes: [
      GoRoute(path: Routes.onboarding, builder: (_, __) => const OnboardingScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: Routes.notes, builder: ...)]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.tasks, builder: ...)]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.reminders, builder: ...)]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.alarms, builder: ...)]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.money, builder: ...)]),
        ],
      ),
      GoRoute(path: Routes.noteEditor, builder: ...),
      GoRoute(path: Routes.alarmRinging, builder: ...),
      GoRoute(path: Routes.settings, builder: ...),
    ],
  );
});
```

### 7.2 Route Constants

```dart
// navigation/routes.dart
class Routes {
  static const onboarding   = '/onboarding';
  static const home         = '/notes';
  static const notes        = '/notes';
  static const noteEditor   = '/notes/editor';
  static const tasks        = '/tasks';
  static const reminders    = '/reminders';
  static const alarms       = '/alarms';
  static const alarmRinging = '/alarms/ringing';
  static const money        = '/money';
  static const charts       = '/money/charts';
  static const savingsGoals = '/money/goals';
  static const history      = '/money/history';
  static const settings     = '/settings';
}
```

---

## 8. Background Processing Architecture

### 8.1 Alarm Background Architecture

The `alarm` package uses a foreground service (Android) and a background task (iOS) to guarantee the alarm fires even when the app is killed.

```
┌─────────────────────────────────────────────────────────────┐
│  User sets alarm → AlarmRepositoryImpl saves to Isar        │
│                  → alarm.set(AlarmSettings(...)) called      │
│                                                             │
│  At scheduled time:                                         │
│  Android: AlarmManager wakes → Flutter Engine starts        │
│           → AlarmRingCallback fires                         │
│           → AlarmRingingScreen pushed to foreground         │
│                                                             │
│  iOS: BGTaskScheduler / Critical Alert fires               │
│       → AlarmRingingScreen shown on lock screen            │
└─────────────────────────────────────────────────────────────┘
```

**Alarm callback setup in main.dart:**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Alarm.init(showDebugLogs: false);
  Alarm.ringStream.stream.listen((alarmSettings) {
    // Navigate to ringing screen
    navigatorKey.currentState?.pushNamed(Routes.alarmRinging, arguments: alarmSettings);
  });
  runApp(ProviderScope(child: EndlessApp()));
}
```

### 8.2 Notification Architecture

Reminders use `flutter_local_notifications` with a scheduled notification. On device reboot, a `BroadcastReceiver` (Android) re-schedules all active reminders from Isar.

```dart
// In Android MainApplication or dedicated receiver:
// android/app/src/main/java/...BootReceiver.java (configured in AndroidManifest)
// Calls back into Flutter via method channel to trigger re-scheduling
```

On the Flutter side, a `NotificationService` singleton in `core/` handles:
1. Initialisation (request permissions, create channels)
2. Scheduling a notification at a future DateTime
3. Cancelling a notification by ID
4. Re-scheduling all active reminders (called on boot)

### 8.3 App Lock Architecture

```
App resumes from background
         │
         ▼
AppLifecycleObserver detects AppLifecycleState.resumed
         │
         ▼
Check: isAppLockEnabled AND time since backgrounded > 30s
         │ Yes
         ▼
Push LockScreen on top of navigator stack (opaque, blocks all content)
         │
         ▼
User authenticates (biometric or PIN)
         │ Success
         ▼
LockScreen pops; content visible
```

The `AppLifecycleObserver` is a `WidgetsBindingObserver` attached to the root `app.dart` widget's `initState`. It records the timestamp when the app goes to background and checks the elapsed time on resume.
