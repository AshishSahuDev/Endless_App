# Database Design Document
**Project:** Endless App | **Version:** 1.0 | **Date:** 2026-06-03 | **Author:** Ashish Sahu

---

## 1. Database Technology: Isar

Isar is a cross-platform NoSQL database built for Flutter. It stores data as typed collections (like tables), supports complex queries without raw SQL, and runs fully offline on-device.

**Why Isar over SQLite:**
- 10x faster read/write than sqflite on Flutter
- Type-safe queries (no raw SQL strings — caught at compile time)
- Native async support — non-blocking UI
- Built-in full-text search
- Works with Riverpod natively

---

## 2. Collections (Schemas)

### 2.1 NoteModel

```dart
import 'package:isar/isar.dart';
part 'note_model.g.dart';

@collection
class NoteModel {
  Id id = Isar.autoIncrement;

  @Index(type: IndexType.value)
  late String title;

  late String body;           // plain text (rich text stored as delta JSON)
  String richTextDelta = '';  // Quill delta JSON for rich text
  int colorIndex = 0;         // 0=default,1=red,2=orange,3=yellow,4=green,5=blue,6=purple,7=pink

  @Index(type: IndexType.value)
  bool isPinned = false;

  bool isArchived = false;

  @Index(type: IndexType.value)
  late DateTime createdAt;

  late DateTime updatedAt;

  // Full-text search index on title + body
  @Index(type: IndexType.value, composite: [CompositeIndex('body')])
  String get searchText => '$title $body';
}
```

**Indexes:** `title`, `isPinned`, `createdAt`, composite search index on title+body

---

### 2.2 TaskCategoryModel

```dart
@collection
class TaskCategoryModel {
  Id id = Isar.autoIncrement;
  late String name;        // "Work", "Personal", "Shopping", etc.
  int colorIndex = 0;
  int iconIndex = 0;
  bool isDefault = true;   // default categories cannot be deleted
  late DateTime createdAt;
}
```

---

### 2.3 TaskModel

```dart
@collection
class TaskModel {
  Id id = Isar.autoIncrement;

  @Index(type: IndexType.value)
  late String title;

  bool isDone = false;

  @Index(type: IndexType.value)
  int priority = 1;         // 0=Low, 1=Medium, 2=High

  DateTime? dueDate;

  @Index(type: IndexType.value)
  late int categoryId;      // FK → TaskCategoryModel.id

  late DateTime createdAt;
  DateTime? completedAt;

  // Soft delete: completed tasks auto-hide after 30 days
  bool get isExpired =>
      isDone && completedAt != null &&
      DateTime.now().difference(completedAt!).inDays > 30;
}
```

**Indexes:** `priority`, `categoryId`, `isDone`, `createdAt`

---

### 2.4 ReminderModel

```dart
@collection
class ReminderModel {
  Id id = Isar.autoIncrement;

  late String title;
  late String message;

  @Index(type: IndexType.value)
  late DateTime scheduledAt;

  bool isRecurring = false;
  String recurType = 'none'; // 'none' | 'daily' | 'weekly' | 'biweekly' | 'monthly'
  List<int> recurDays = [];  // for weekly: [1,3,5] = Mon,Wed,Fri

  int? linkedNoteId;         // optional FK → NoteModel.id
  int? linkedTaskId;         // optional FK → TaskModel.id

  bool isSnoozed = false;
  DateTime? snoozedUntil;
  bool isCompleted = false;

  late DateTime createdAt;
}
```

**Indexes:** `scheduledAt`, `isCompleted`

---

### 2.5 AlarmModel

```dart
@collection
class AlarmModel {
  Id id = Isar.autoIncrement;  // also used as alarm package ID

  late String label;            // e.g., "7AM LECTURE"
  late String timeHHMM;         // "07:00" — stored as string for simplicity
  int hour = 7;
  int minute = 0;

  bool isEnabled = true;
  int soundIndex = 0;           // 0=default,1=gentle,2=digital,3=birds,4=classic

  int snoozeMinutes = 5;        // 5, 10, or 15

  // Repeat: List<int> where 0=Sun,1=Mon,...,6=Sat
  List<int> repeatDays = [];    // empty = one-time alarm

  late DateTime createdAt;
  DateTime? lastFiredAt;
}
```

**Indexes:** `isEnabled`, `hour`, `minute`

---

### 2.6 TransactionCategoryModel

```dart
@collection
class TransactionCategoryModel {
  Id id = Isar.autoIncrement;
  late String name;             // "Food & Drink", "Transport", etc.
  late String iconName;         // iconsax icon name
  int colorIndex = 0;
  bool isDefault = true;        // defaults cannot be deleted
  double budgetLimit = 0;       // 0 = no limit set
  late DateTime createdAt;
}

// Default categories seeded on first launch:
// 1=Food & Drink, 2=Transport, 3=Shopping, 4=Entertainment,
// 5=Bills & Utilities, 6=Health, 7=Education, 8=Rent, 9=Other
// Income categories: 10=Salary, 11=Freelance, 12=Gift, 13=Other Income
```

---

### 2.7 TransactionModel

```dart
@collection
class TransactionModel {
  Id id = Isar.autoIncrement;

  @Index(type: IndexType.value)
  String type = 'expense';      // 'income' | 'expense'

  late double amount;           // always positive

  @Index(type: IndexType.value)
  late int categoryId;          // FK → TransactionCategoryModel.id

  String note = '';             // optional description

  @Index(type: IndexType.value)
  late DateTime date;           // date of transaction (not entry time)

  late DateTime createdAt;

  // Computed helpers (not stored)
  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';
}
```

**Indexes:** `type`, `categoryId`, `date`, `createdAt`

---

### 2.8 SavingsGoalModel

```dart
@collection
class SavingsGoalModel {
  Id id = Isar.autoIncrement;
  late String name;             // "Goa Trip", "MacBook Pro"
  late double targetAmount;
  double currentAmount = 0;
  DateTime? deadline;
  bool isAchieved = false;
  DateTime? achievedAt;
  late DateTime createdAt;

  double get progressPercent =>
      targetAmount > 0 ? (currentAmount / targetAmount * 100).clamp(0, 100) : 0;

  bool get isOverdue =>
      deadline != null && !isAchieved && DateTime.now().isAfter(deadline!);
}
```

---

### 2.9 AppSettingsModel (Singleton)

```dart
@collection
class AppSettingsModel {
  Id id = 1;                    // always ID=1, singleton

  String theme = 'dark';        // 'dark' | 'light'
  String currency = 'INR';      // 'INR' | 'USD' | etc.
  String currencySymbol = '₹';

  bool isAppLockEnabled = false;
  String lockType = 'none';     // 'none' | 'pin' | 'biometric'
  String? pinHash;              // bcrypt hash of PIN

  double monthlyIncome = 0;     // used for budget baseline

  bool hasCompletedOnboarding = false;

  late DateTime createdAt;
  late DateTime updatedAt;
}
```

---

## 3. Isar Instance Setup

```dart
// lib/core/database/isar_service.dart
class IsarService {
  late Isar _isar;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [
        NoteModelSchema,
        TaskModelSchema,
        TaskCategoryModelSchema,
        ReminderModelSchema,
        AlarmModelSchema,
        TransactionModelSchema,
        TransactionCategoryModelSchema,
        SavingsGoalModelSchema,
        AppSettingsModelSchema,
      ],
      directory: dir.path,
      name: 'endless_db',
    );
  }

  Isar get instance => _isar;
}
```

---

## 4. Key Query Examples

```dart
// Get all pinned, non-archived notes sorted by updatedAt
final pinnedNotes = await isar.noteModels
    .filter()
    .isPinnedEqualTo(true)
    .isArchivedEqualTo(false)
    .sortByUpdatedAtDesc()
    .findAll();

// Full-text search across notes
final results = await isar.noteModels
    .filter()
    .titleContains(query, caseSensitive: false)
    .or()
    .bodyContains(query, caseSensitive: false)
    .findAll();

// Tasks by category, not done, sorted by priority desc then dueDate
final tasks = await isar.taskModels
    .filter()
    .categoryIdEqualTo(categoryId)
    .isDoneEqualTo(false)
    .sortByPriorityDesc()
    .thenByDueDate()
    .findAll();

// Transactions for a date range
final transactions = await isar.transactionModels
    .filter()
    .dateBetween(startDate, endDate)
    .sortByDateDesc()
    .findAll();

// Monthly total by category (expense only)
final expenses = await isar.transactionModels
    .filter()
    .typeEqualTo('expense')
    .categoryIdEqualTo(categoryId)
    .dateBetween(firstDayOfMonth, lastDayOfMonth)
    .findAll();
final total = expenses.fold(0.0, (sum, t) => sum + t.amount);

// Upcoming reminders (next 24 hours, not completed)
final upcoming = await isar.reminderModels
    .filter()
    .isCompletedEqualTo(false)
    .scheduledAtBetween(DateTime.now(), DateTime.now().add(Duration(hours: 24)))
    .sortByScheduledAt()
    .findAll();
```

---

## 5. Write Transaction Pattern

Always use Isar transactions for writes to ensure atomicity:

```dart
// Single write
await isar.writeTxn(() async {
  await isar.noteModels.put(note);
});

// Multiple writes (atomic)
await isar.writeTxn(() async {
  await isar.taskModels.put(task);
  await isar.reminderModels.put(linkedReminder);
});

// Delete
await isar.writeTxn(() async {
  await isar.noteModels.delete(noteId);
});
```

---

## 6. Data Seeding (First Launch)

On first launch, seed default categories:

```dart
Future<void> seedDefaultData(Isar isar) async {
  final settings = await isar.appSettingsModels.get(1);
  if (settings?.hasCompletedOnboarding == true) return;

  await isar.writeTxn(() async {
    // Seed task categories
    await isar.taskCategoryModels.putAll([
      TaskCategoryModel()..name = 'Personal'..colorIndex = 1,
      TaskCategoryModel()..name = 'Work'..colorIndex = 2,
      TaskCategoryModel()..name = 'Shopping'..colorIndex = 3,
      TaskCategoryModel()..name = 'Health'..colorIndex = 4,
    ]);

    // Seed transaction categories
    await isar.transactionCategoryModels.putAll([
      TransactionCategoryModel()..name = 'Food & Drink'..iconName = 'cup'..colorIndex = 1,
      TransactionCategoryModel()..name = 'Transport'..iconName = 'car'..colorIndex = 2,
      TransactionCategoryModel()..name = 'Shopping'..iconName = 'bag'..colorIndex = 3,
      TransactionCategoryModel()..name = 'Entertainment'..iconName = 'music'..colorIndex = 4,
      TransactionCategoryModel()..name = 'Bills & Utilities'..iconName = 'flash'..colorIndex = 5,
      TransactionCategoryModel()..name = 'Health'..iconName = 'health'..colorIndex = 6,
      TransactionCategoryModel()..name = 'Education'..iconName = 'book'..colorIndex = 7,
      TransactionCategoryModel()..name = 'Rent'..iconName = 'home'..colorIndex = 8,
      TransactionCategoryModel()..name = 'Other'..iconName = 'more'..colorIndex = 0,
      // Income
      TransactionCategoryModel()..name = 'Salary'..iconName = 'wallet'..colorIndex = 9,
      TransactionCategoryModel()..name = 'Freelance'..iconName = 'briefcase'..colorIndex = 9,
      TransactionCategoryModel()..name = 'Gift'..iconName = 'gift'..colorIndex = 9,
    ]);

    // Create default settings
    await isar.appSettingsModels.put(
      AppSettingsModel()
        ..id = 1
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now(),
    );
  });
}
```

---

## 7. Migration Strategy

Isar handles schema migrations automatically for additive changes (new fields with defaults). For breaking changes:

1. Bump schema version in `Isar.open()` with `schemaVersion: 2`
2. Provide a `MigrationCallback` to transform old data
3. Test migration on a copy of production data before release
4. Keep previous schema classes until migration is confirmed stable

```dart
_isar = await Isar.open(
  schemas,
  directory: dir.path,
  name: 'endless_db',
  // migration handled automatically for additive changes
);
```

---

*Document: 02_database_design.md | Phase 3 — Technical Planning*
