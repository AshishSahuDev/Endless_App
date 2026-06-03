# API & Data Contracts
**Project:** Endless App | **Version:** 1.0 | **Date:** 2026-06-03 | **Author:** Ashish Sahu

---

## 1. Overview

This document defines the internal contracts between Clean Architecture layers:
- **Entities** — pure Dart domain objects (no Isar, no Flutter)
- **Repository Interfaces** — abstract contracts the domain layer depends on
- **Use Cases** — single-responsibility business logic classes
- **Providers** — Riverpod provider definitions per feature
- **Custom Exceptions** — typed error handling

---

## 2. Domain Entities

```dart
// lib/features/notes/domain/entities/note.dart
class Note {
  final int id;
  final String title;
  final String body;
  final String richTextDelta;
  final int colorIndex;
  final bool isPinned;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Note({
    required this.id, required this.title, required this.body,
    this.richTextDelta = '', this.colorIndex = 0,
    this.isPinned = false, this.isArchived = false,
    required this.createdAt, required this.updatedAt,
  });

  Note copyWith({String? title, String? body, int? colorIndex,
    bool? isPinned, bool? isArchived}) => Note(
    id: id, title: title ?? this.title, body: body ?? this.body,
    richTextDelta: richTextDelta, colorIndex: colorIndex ?? this.colorIndex,
    isPinned: isPinned ?? this.isPinned, isArchived: isArchived ?? this.isArchived,
    createdAt: createdAt, updatedAt: DateTime.now(),
  );
}

// lib/features/tasks/domain/entities/task.dart
class Task {
  final int id;
  final String title;
  final bool isDone;
  final int priority;     // 0=Low, 1=Medium, 2=High
  final DateTime? dueDate;
  final int categoryId;
  final DateTime createdAt;
  final DateTime? completedAt;

  const Task({required this.id, required this.title, this.isDone = false,
    this.priority = 1, this.dueDate, required this.categoryId,
    required this.createdAt, this.completedAt});

  Task copyWith({String? title, bool? isDone, int? priority,
    DateTime? dueDate, int? categoryId}) => Task(
    id: id, title: title ?? this.title, isDone: isDone ?? this.isDone,
    priority: priority ?? this.priority, dueDate: dueDate ?? this.dueDate,
    categoryId: categoryId ?? this.categoryId, createdAt: createdAt,
    completedAt: isDone == true ? DateTime.now() : completedAt,
  );
}

// lib/features/money/domain/entities/transaction.dart
class Transaction {
  final int id;
  final String type;        // 'income' | 'expense'
  final double amount;
  final int categoryId;
  final String note;
  final DateTime date;
  final DateTime createdAt;

  const Transaction({required this.id, required this.type,
    required this.amount, required this.categoryId,
    this.note = '', required this.date, required this.createdAt});

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';
}

// lib/features/money/domain/entities/savings_goal.dart
class SavingsGoal {
  final int id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime? deadline;
  final bool isAchieved;

  const SavingsGoal({required this.id, required this.name,
    required this.targetAmount, this.currentAmount = 0,
    this.deadline, this.isAchieved = false});

  double get progressPercent =>
      targetAmount > 0 ? (currentAmount / targetAmount * 100).clamp(0, 100) : 0;
  bool get isComplete => currentAmount >= targetAmount;
}
```

---

## 3. Repository Interfaces

```dart
// lib/features/notes/domain/repositories/note_repository.dart
abstract class NoteRepository {
  Future<List<Note>> getAllNotes();
  Future<List<Note>> getPinnedNotes();
  Future<List<Note>> getArchivedNotes();
  Future<List<Note>> searchNotes(String query);
  Future<Note?> getNoteById(int id);
  Future<int> createNote(Note note);
  Future<void> updateNote(Note note);
  Future<void> deleteNote(int id);
  Future<void> togglePin(int id);
  Future<void> toggleArchive(int id);
  Stream<List<Note>> watchAllNotes(); // live updates
}

// lib/features/tasks/domain/repositories/task_repository.dart
abstract class TaskRepository {
  Future<List<Task>> getAllTasks({bool includeDone = false});
  Future<List<Task>> getTasksByCategory(int categoryId);
  Future<List<Task>> getTasksByPriority(int priority);
  Future<List<Task>> getOverdueTasks();
  Future<int> createTask(Task task);
  Future<void> updateTask(Task task);
  Future<void> deleteTask(int id);
  Future<void> completeTask(int id);
  Future<void> reorderTasks(List<int> orderedIds);
  Stream<List<Task>> watchTasks();
}

// lib/features/money/domain/repositories/transaction_repository.dart
abstract class TransactionRepository {
  Future<List<Transaction>> getTransactions({
    DateTime? from, DateTime? to, String? type, int? categoryId});
  Future<double> getTotalByType(String type, DateTime from, DateTime to);
  Future<Map<int, double>> getTotalByCategoryForMonth(DateTime month);
  Future<int> createTransaction(Transaction transaction);
  Future<void> updateTransaction(Transaction transaction);
  Future<void> deleteTransaction(int id);
  Stream<List<Transaction>> watchTransactions();
}

// lib/features/money/domain/repositories/savings_goal_repository.dart
abstract class SavingsGoalRepository {
  Future<List<SavingsGoal>> getAllGoals();
  Future<SavingsGoal?> getGoalById(int id);
  Future<int> createGoal(SavingsGoal goal);
  Future<void> updateGoal(SavingsGoal goal);
  Future<void> deleteGoal(int id);
  Future<void> addDeposit(int goalId, double amount);
  Stream<List<SavingsGoal>> watchGoals();
}

// lib/features/alarms/domain/repositories/alarm_repository.dart
abstract class AlarmRepository {
  Future<List<AlarmEntity>> getAllAlarms();
  Future<int> createAlarm(AlarmEntity alarm);
  Future<void> updateAlarm(AlarmEntity alarm);
  Future<void> deleteAlarm(int id);
  Future<void> toggleAlarm(int id, bool isEnabled);
  Future<void> scheduleAlarm(AlarmEntity alarm);
  Future<void> cancelAlarm(int id);
}
```

---

## 4. Use Cases

```dart
// lib/features/notes/domain/use_cases/create_note_use_case.dart
class CreateNoteUseCase {
  final NoteRepository _repository;
  CreateNoteUseCase(this._repository);

  Future<int> execute({required String title, required String body,
    int colorIndex = 0}) async {
    if (title.trim().isEmpty && body.trim().isEmpty) {
      throw ValidationException('Note cannot be empty');
    }
    final note = Note(
      id: 0, title: title.trim(), body: body.trim(),
      colorIndex: colorIndex, createdAt: DateTime.now(), updatedAt: DateTime.now(),
    );
    return await _repository.createNote(note);
  }
}

// lib/features/notes/domain/use_cases/search_notes_use_case.dart
class SearchNotesUseCase {
  final NoteRepository _repository;
  SearchNotesUseCase(this._repository);
  Future<List<Note>> execute(String query) async {
    if (query.trim().length < 2) return [];
    return await _repository.searchNotes(query.trim());
  }
}

// lib/features/money/domain/use_cases/add_transaction_use_case.dart
class AddTransactionUseCase {
  final TransactionRepository _transactionRepo;
  final TransactionCategoryRepository _categoryRepo;
  AddTransactionUseCase(this._transactionRepo, this._categoryRepo);

  Future<void> execute({required String type, required double amount,
    required int categoryId, String note = '', required DateTime date}) async {
    if (amount <= 0) throw ValidationException('Amount must be greater than 0');
    if (!['income', 'expense'].contains(type)) {
      throw ValidationException('Invalid transaction type');
    }
    final category = await _categoryRepo.getCategoryById(categoryId);
    if (category == null) throw ValidationException('Invalid category');

    final transaction = Transaction(
      id: 0, type: type, amount: amount, categoryId: categoryId,
      note: note, date: date, createdAt: DateTime.now(),
    );
    await _transactionRepo.createTransaction(transaction);

    // Check budget alerts after adding expense
    if (type == 'expense' && category.budgetLimit > 0) {
      await _checkBudgetAlert(categoryId, category.budgetLimit, date);
    }
  }

  Future<void> _checkBudgetAlert(int categoryId, double limit, DateTime date) async {
    final firstDay = DateTime(date.year, date.month, 1);
    final lastDay = DateTime(date.year, date.month + 1, 0);
    final spent = await _transactionRepo.getTotalByType('expense', firstDay, lastDay);
    final percent = spent / limit;
    if (percent >= 1.0) {
      // trigger 100% alert notification
    } else if (percent >= 0.8) {
      // trigger 80% warning notification
    }
  }
}

// lib/features/money/domain/use_cases/get_monthly_summary_use_case.dart
class GetMonthlySummaryUseCase {
  final TransactionRepository _repository;
  GetMonthlySummaryUseCase(this._repository);

  Future<MonthlySummary> execute(DateTime month) async {
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    final income = await _repository.getTotalByType('income', first, last);
    final expense = await _repository.getTotalByType('expense', first, last);
    final byCategory = await _repository.getTotalByCategoryForMonth(month);
    return MonthlySummary(income: income, expense: expense,
        balance: income - expense, byCategory: byCategory);
  }
}

class MonthlySummary {
  final double income;
  final double expense;
  final double balance;
  final Map<int, double> byCategory;
  const MonthlySummary({required this.income, required this.expense,
    required this.balance, required this.byCategory});
}
```

---

## 5. Riverpod Provider Contracts

```dart
// lib/features/notes/presentation/providers/notes_provider.dart

@riverpod
class NotesNotifier extends _$NotesNotifier {
  @override
  Future<List<Note>> build() async {
    final repo = ref.watch(noteRepositoryProvider);
    return repo.getAllNotes();
  }

  Future<void> create(String title, String body, {int colorIndex = 0}) async {
    final useCase = ref.read(createNoteUseCaseProvider);
    await useCase.execute(title: title, body: body, colorIndex: colorIndex);
    ref.invalidateSelf(); // refresh list
  }

  Future<void> togglePin(int id) async {
    await ref.read(noteRepositoryProvider).togglePin(id);
    ref.invalidateSelf();
  }

  Future<void> delete(int id) async {
    await ref.read(noteRepositoryProvider).deleteNote(id);
    ref.invalidateSelf();
  }
}

// Providers list (one per feature, similar pattern)
// notesNotifierProvider        → AsyncNotifier<List<Note>>
// tasksNotifierProvider        → AsyncNotifier<List<Task>>
// remindersNotifierProvider    → AsyncNotifier<List<Reminder>>
// alarmsNotifierProvider       → AsyncNotifier<List<AlarmEntity>>
// transactionsNotifierProvider → AsyncNotifier<List<Transaction>>
// monthlySummaryProvider       → AsyncNotifier<MonthlySummary>
// savingsGoalsProvider         → AsyncNotifier<List<SavingsGoal>>
// appSettingsProvider          → AsyncNotifier<AppSettings>
// themeProvider                → StateProvider<ThemeMode>
```

---

## 6. Custom Exception Classes

```dart
// lib/core/errors/app_exceptions.dart

/// Base exception for all app errors
abstract class AppException implements Exception {
  final String message;
  const AppException(this.message);
  @override
  String toString() => '$runtimeType: $message';
}

/// Thrown when user input fails validation
class ValidationException extends AppException {
  const ValidationException(super.message);
}

/// Thrown when a database operation fails
class DatabaseException extends AppException {
  final Object? cause;
  const DatabaseException(super.message, {this.cause});
}

/// Thrown when alarm scheduling fails
class AlarmException extends AppException {
  const AlarmException(super.message);
}

/// Thrown when push notification scheduling fails
class NotificationException extends AppException {
  const NotificationException(super.message);
}

/// Thrown when biometric/pin authentication fails
class AuthException extends AppException {
  const AuthException(super.message);
}

/// Thrown when a requested resource is not found
class NotFoundException extends AppException {
  const NotFoundException(super.message);
}
```

---

## 7. Result Type Pattern (Optional — for explicit error handling)

```dart
// lib/core/utils/result.dart
sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends Result<T> {
  final AppException exception;
  const Failure(this.exception);
}

// Usage in use case:
Future<Result<int>> execute(...) async {
  try {
    final id = await _repository.createNote(note);
    return Success(id);
  } on DatabaseException catch (e) {
    return Failure(e);
  }
}

// Usage in provider:
final result = await useCase.execute(...);
switch (result) {
  case Success(:final data): // handle success
  case Failure(:final exception): // show error snackbar
}
```

---

*Document: 03_api_contracts.md | Phase 3 — Technical Planning*
