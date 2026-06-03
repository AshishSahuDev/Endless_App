# Coding Standards & Conventions
**Project:** Endless App | **Version:** 1.0 | **Date:** 2026-06-03 | **Author:** Ashish Sahu

---

## 1. Naming Conventions

| Type | Convention | Example |
|---|---|---|
| Files | `snake_case.dart` | `note_repository.dart` |
| Classes | `PascalCase` | `NoteRepository`, `CreateNoteUseCase` |
| Variables | `camelCase` | `noteTitle`, `isLoading` |
| Constants | `kCamelCase` | `kPrimaryColor`, `kDefaultPadding` |
| Private members | `_camelCase` | `_repository`, `_isar` |
| Enums | `PascalCase` values `camelCase` | `Priority.high`, `TransactionType.expense` |
| Providers | `camelCaseProvider` | `notesProvider`, `themeProvider` |
| Route names | `kebab-case` string | `'/notes/editor'`, `'/money/charts'` |
| Test files | match source + `_test` | `note_repository_test.dart` |

---

## 2. File Organization

- **One class per file** — no exceptions
- **Feature-first** folder structure (not layer-first)
- Generated files (`.g.dart`) stay next to their source file
- Test files mirror the `lib/` structure under `test/`

```dart
// ✅ Correct — one public class per file
// note_card.dart
class NoteCard extends StatelessWidget { ... }

// ❌ Wrong — two classes in one file
// note_widgets.dart
class NoteCard extends StatelessWidget { ... }
class NoteColorBadge extends StatelessWidget { ... }
```

---

## 3. Widget Best Practices

```dart
// ✅ Use const constructors wherever possible — prevents unnecessary rebuilds
class NoteCard extends StatelessWidget {
  const NoteCard({super.key, required this.note}); // const constructor
  final Note note;
  ...
}

// ✅ Extract widgets when build method exceeds ~30 lines
// ❌ Don't write 150-line build() methods with nested subtrees

// ✅ Prefer StatelessWidget — use StatefulWidget only when local state is truly needed
// (Most state lives in Riverpod, not widgets)

// ✅ Use `const` for all static widgets
const SizedBox(height: 16),
const Icon(Iconsax.note_text),

// ✅ Never put business logic in widgets
// ❌ Wrong:
onTap: () async {
  final isar = Isar.getInstance()!;
  await isar.writeTxn(() => isar.noteModels.delete(note.id)); // direct DB in widget!
}

// ✅ Correct:
onTap: () => ref.read(notesProvider.notifier).delete(note.id), // via provider
```

---

## 4. Riverpod Patterns

```dart
// ✅ Use @riverpod annotation for all providers
@riverpod
class NotesNotifier extends _$NotesNotifier {
  @override
  Future<List<Note>> build() async {
    return ref.watch(noteRepositoryProvider).getAllNotes();
  }
}

// ✅ Use AsyncNotifier for async data, Notifier for sync data
// ✅ Use ref.invalidateSelf() to refresh after mutations
// ❌ Never expose Isar directly through a provider — always go through Repository

// ✅ Read vs Watch — know the difference:
// ref.watch() — rebuilds widget when value changes (use in build())
// ref.read()  — one-time read, no rebuild (use in callbacks/event handlers)

// ✅ Provider naming: feature + purpose
final notesNotifierProvider = ...     // for AsyncNotifier
final currentNoteProvider = ...       // for single item
final noteSearchQueryProvider = ...   // for search string state
```

---

## 5. Isar Usage Patterns

```dart
// ✅ ALWAYS use writeTxn for any write operation
await isar.writeTxn(() async {
  await isar.noteModels.put(noteModel);
});

// ✅ Batch writes in a single transaction (faster + atomic)
await isar.writeTxn(() async {
  await isar.noteModels.put(note);
  await isar.reminderModels.put(linkedReminder); // both or neither
});

// ✅ Use Isar's query builder — never raw strings
final notes = await isar.noteModels
    .filter()
    .isPinnedEqualTo(true)
    .isArchivedEqualTo(false)
    .sortByUpdatedAtDesc()
    .findAll();

// ❌ Never use Isar directly in presentation layer
// ❌ Never store Isar instance in a widget

// ✅ Close Isar when app terminates (in main.dart dispose)
// In practice: Isar auto-closes on process end, but be explicit in tests
```

---

## 6. Error Handling

```dart
// ✅ Never swallow exceptions silently
// ❌ Wrong:
try {
  await _repository.createNote(note);
} catch (e) {
  // do nothing
}

// ✅ Correct: handle OR rethrow with typed exception
try {
  await _repository.createNote(note);
} on IsarError catch (e) {
  throw DatabaseException('Failed to save note: ${e.message}', cause: e);
}

// ✅ Use typed custom exceptions (see api_contracts.md)
// ValidationException, DatabaseException, AlarmException, etc.

// ✅ In presentation layer: show error to user via Snackbar
ref.listen(notesProvider, (prev, next) {
  if (next is AsyncError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Something went wrong. Please try again.')),
    );
  }
});
```

---

## 7. Comment Rules

```dart
// ✅ Document the WHY when it's non-obvious:

// Uses writeTxn here even for a single put because Isar requires
// all writes to be wrapped in a transaction, even single operations.
await isar.writeTxn(() async {
  await isar.noteModels.put(noteModel);
});

// ✅ Document workarounds with context:
// flutter_local_notifications requires channel registration on Android 8+
// even though we target 8.0 minimum — this is not redundant.
await _notificationsPlugin.resolvePlatformSpecificImplementation<
    AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);

// ❌ Don't document WHAT the code does (the code does that):
// Creates a new note   ← useless
final note = Note(id: 0, title: title, ...);

// ❌ Don't leave TODO comments in committed code without a linked issue
// TODO: fix this later  ← unacceptable

// ✅ Acceptable TODO format:
// TODO(ashish): [ENDLESS-42] Handle edge case where alarm fires during onboarding
```

---

## 8. Import Ordering

```dart
// Order: dart: → package: → relative (separated by blank lines)

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../models/note_model.dart';
```

---

## 9. Analysis Options

```yaml
# analysis_options.yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  errors:
    missing_required_param: error
    missing_return: error
    dead_code: warning
  exclude:
    - "**/*.g.dart"     # generated files
    - "**/*.freezed.dart"

linter:
  rules:
    - always_use_package_imports: false
    - prefer_const_constructors: true
    - prefer_const_widgets: true
    - avoid_print: true            # use debugPrint() instead
    - use_key_in_widget_constructors: true
    - prefer_final_fields: true
    - prefer_single_quotes: true   # use single quotes consistently
```

---

## 10. Commit Message Convention (Conventional Commits)

```
<type>(<scope>): <short description>

Types:
  feat     → new feature
  fix      → bug fix
  docs     → documentation only
  style    → formatting (no code change)
  refactor → code restructure (no feature/fix)
  test     → adding/changing tests
  chore    → build process, dependencies

Scope: the feature module (notes, tasks, money, alarms, reminders, core, ui)

Examples:
  feat(notes): add color picker to note editor
  fix(alarms): resolve background alarm not firing on API 31
  refactor(money): extract transaction grouping to date_utils
  test(tasks): add widget tests for task list swipe-to-complete
  docs(setup): update flutter installation steps for Ubuntu 24.04
  chore(deps): upgrade isar to 3.1.1
```

---

*Document: 03_coding_standards.md | Phase 6 — Dev Environment Setup*
