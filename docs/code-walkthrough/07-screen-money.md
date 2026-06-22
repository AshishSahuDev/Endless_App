# 07 — Screen: Money

The Money feature is the largest in the app. It tracks income and expenses, computes monthly summaries, draws a category pie chart and a daily spending bar chart, and manages savings goals with progress bars and deadlines. It is the most complete example of Clean Architecture in this codebase — every layer (domain, data, presentation) is fully populated, and it is also the only feature that fans state out across multiple Riverpod providers that invalidate each other.

This chapter walks through the feature top-to-bottom: domain entities first, then data models and Isar datasources, then the Riverpod providers, the screen, and finally the widgets that render transactions, goals, and the two charts. The last section traces what happens when a user adds a single $20 coffee expense and the pie chart updates without anyone calling `setState`.

If you read `00-how-flutter-works.md`, you already know the mental model: widgets are immutable description-trees, Riverpod is Spring's `ApplicationContext` with reactive bindings, and Isar is a local NoSQL store with code-generated query methods (the `.g.dart` files). Treat repository interfaces like `@Repository` interfaces, use cases like thin `@Service` methods, and providers like `@Bean` definitions with explicit dependency edges.

## File map

| Path (under `app/lib/features/money/`)                          | Layer        | Role                                                        |
| --------------------------------------------------------------- | ------------ | ----------------------------------------------------------- |
| `domain/entities/transaction.dart`                              | Domain       | `MoneyTransaction` value object                             |
| `domain/entities/savings_goal.dart`                             | Domain       | `SavingsGoal` value object with progress getter             |
| `domain/entities/category.dart`                                 | Domain       | `MoneyCategory` (slug + icon + color)                       |
| `domain/entities/monthly_summary.dart`                          | Domain       | Aggregate: totals + per-category + per-day maps             |
| `domain/repositories/transaction_repository.dart`               | Domain       | Abstract interface — port for Isar                          |
| `domain/repositories/savings_goal_repository.dart`              | Domain       | Abstract interface — port for Isar                          |
| `domain/use_cases/add_transaction_use_case.dart`                | Domain       | Validates and adds a transaction                            |
| `domain/use_cases/delete_transaction_use_case.dart`             | Domain       | Deletes a transaction by id                                 |
| `domain/use_cases/get_monthly_summary_use_case.dart`            | Domain       | Computes `MonthlySummary` from raw transactions             |
| `data/models/transaction_model.dart`                            | Data         | Isar collection for transactions                            |
| `data/models/savings_goal_model.dart`                           | Data         | Isar collection for goals                                   |
| `data/models/category_model.dart`                               | Data         | Isar collection (only used for custom categories)           |
| `data/seed/category_seed.dart`                                  | Data         | Hard-coded default categories (no DB)                       |
| `data/datasources/transaction_local_datasource.dart`            | Data         | Isar CRUD for transactions                                  |
| `data/datasources/savings_goal_local_datasource.dart`           | Data         | Isar CRUD for goals                                         |
| `data/repositories/transaction_repository_impl.dart`            | Data         | Maps `TransactionModel` <-> `MoneyTransaction`              |
| `data/repositories/savings_goal_repository_impl.dart`           | Data         | Maps `SavingsGoalModel` <-> `SavingsGoal`                   |
| `presentation/providers/money_provider.dart`                    | Presentation | All Riverpod wiring — repos, notifiers, selected month      |
| `presentation/screens/money_screen.dart`                        | Presentation | Tabbed screen: Transactions / Goals                         |
| `presentation/widgets/summary_card.dart`                        | Presentation | Gradient card with balance + month nav                      |
| `presentation/widgets/transaction_card.dart`                    | Presentation | Swipe-to-delete row                                         |
| `presentation/widgets/savings_goal_card.dart`                   | Presentation | Goal row with progress bar                                  |
| `presentation/widgets/add_transaction_sheet.dart`               | Presentation | Bottom sheet for new transaction                            |
| `presentation/widgets/savings_goal_sheet.dart`                  | Presentation | Bottom sheets for create goal + add funds                   |
| `presentation/widgets/category_pie_chart.dart`                  | Presentation | Touch-interactive donut chart                               |
| `presentation/widgets/expense_bar_chart.dart`                   | Presentation | Daily bars across the selected month                        |

## Layer 1 — Domain

Domain code has zero Flutter, zero Isar, zero Riverpod imports. It is plain Dart, the same way a Spring `domain` package would have no JPA annotations. The only library reference allowed is `flutter/material.dart` for `IconData`/`Color` inside `MoneyCategory` — those are arguably presentation concerns leaking into a domain enum, but the team chose pragmatism (one source of truth for category metadata) over purity. Keep that trade-off in mind when you see similar leaks in other features.

### Transactions

`MoneyTransaction` is the central value object. Every transaction is either an expense or an income, references a category by slug (a stable string key like `food` or `salary`), and stores both a logical `date` (when the money moved) and a bookkeeping `createdAt` (when the row was inserted).

```dart
class MoneyTransaction {
  final int id;
  final double amount;
  final bool isExpense;
  final String categorySlug;
  final String? note;
  final DateTime date;
  final DateTime createdAt;

  const MoneyTransaction({
    required this.id,
    required this.amount,
    required this.isExpense,
    required this.categorySlug,
    this.note,
    required this.date,
    required this.createdAt,
  });
```

A few things to notice. All fields are `final`, so the object is immutable — just like a Java record or a Lombok `@Value` class. The constructor uses Dart's named-required syntax (`required this.amount`), which gives you the same compile-time guarantees as a Java builder that requires certain fields. `note` is the only nullable field (`String?`), modelling the fact that a user may not attach a memo.

Because the object is immutable, there is a `copyWith` method:

```dart
MoneyTransaction copyWith({
  int? id,
  double? amount,
  bool? isExpense,
  String? categorySlug,
  String? note,
  DateTime? date,
  DateTime? createdAt,
}) {
  return MoneyTransaction(
    id: id ?? this.id,
    amount: amount ?? this.amount,
    isExpense: isExpense ?? this.isExpense,
    categorySlug: categorySlug ?? this.categorySlug,
    note: note ?? this.note,
    date: date ?? this.date,
    createdAt: createdAt ?? this.createdAt,
  );
}
```

`copyWith` is the idiomatic Dart way to express "give me a copy with one field changed" — equivalent to Java records' `withX` accessors. The `??` operator returns the left side if non-null, otherwise the right. So `id ?? this.id` means "use the new id if the caller passed one, otherwise reuse the current id." It is structurally identical to:

```java
public MoneyTransaction withAmount(double amount) {
  return new MoneyTransaction(this.id, amount, this.isExpense, ...);
}
```

The use case for `copyWith` in this feature is mostly internal (e.g. updating a saved amount), but it is also the standard pattern across the codebase, so you'll see it everywhere.

#### `TransactionRepository`

This is the port — the abstract contract the domain depends on. In Java this would be an interface annotated `@Repository`; in Dart it's an `abstract interface class`.

```dart
abstract interface class TransactionRepository {
  Future<List<MoneyTransaction>> getAllTransactions();
  Future<List<MoneyTransaction>> getByMonth(int year, int month);
  Future<List<MoneyTransaction>> getRecent(int limit);
  Future<int> addTransaction(MoneyTransaction tx);
  Future<void> deleteTransaction(int id);
}
```

`abstract interface class` is a Dart 3 declaration that marks the class as pure-interface — implementers must override everything and nothing can `extend` it (only `implement` it). It is the cleanest way to declare a port in Dart. Every signature returns `Future<...>` because the Isar implementation is asynchronous (disk I/O) — a Java equivalent would return `CompletableFuture` everywhere.

The interface stays naive: no caching, no batching, no observers — just five plain methods. All cleverness lives one level up in use cases or one level down in datasources.

#### Use cases

There are three use cases (`AddTransactionUseCase`, `DeleteTransactionUseCase`, `GetMonthlySummaryUseCase`). Think of them as the moral equivalent of `@Service` methods, minus the boilerplate. Each use case takes the repository in its constructor and exposes a `call` method, which makes the instance callable like a function: `addTransactionUseCase(tx)` instead of `addTransactionUseCase.call(tx)`. This is a Dart idiom — any class with a `call` method becomes a "callable object."

`AddTransactionUseCase` is the only one with validation logic:

```dart
class AddTransactionUseCase {
  final TransactionRepository _repository;
  const AddTransactionUseCase(this._repository);

  Future<int> call(MoneyTransaction tx) async {
    if (tx.amount <= 0) throw const ValidationException('Amount must be greater than 0');
    if (tx.categorySlug.isEmpty) throw const ValidationException('Please select a category');
    return _repository.addTransaction(tx);
  }
}
```

Two guards, then forward to the repository. `ValidationException` is one of the typed exceptions defined in `core/errors/app_exceptions.dart` — it's the domain's way of saying "the caller did something wrong" without coupling to UI. When the bottom sheet later catches it, it shows a snackbar; the domain doesn't need to know that.

`DeleteTransactionUseCase` is even simpler:

```dart
class DeleteTransactionUseCase {
  final TransactionRepository _repository;
  const DeleteTransactionUseCase(this._repository);

  Future<void> call(int id) => _repository.deleteTransaction(id);
}
```

There is essentially no logic here — it's a one-line passthrough. The reason it exists at all is consistency: every domain action is a use case, so callers always go through a uniform door. If tomorrow you need to add "soft delete" or "audit log" logic, you have a single place to put it. This is the same argument for wrapping a JPA call in a `@Service` method even when it does nothing extra today.

`GetMonthlySummaryUseCase` is the one with the most logic:

```dart
Future<MonthlySummary> call(int year, int month) async {
  final txns = await _repository.getByMonth(year, month);
  double income = 0;
  double expense = 0;
  for (final t in txns) {
    if (t.isExpense) {
      expense += t.amount;
    } else {
      income += t.amount;
    }
  }
  return MonthlySummary(
    year: year,
    month: month,
    totalIncome: income,
    totalExpense: expense,
    transactions: txns,
  );
}
```

It loads all transactions for a month, then walks them once to compute totals. The raw list is also embedded in the summary so downstream widgets (the pie chart, the bar chart) can derive per-category and per-day breakdowns without round-tripping to the repository again. The summary's `expenseByCategory` and `dailyExpenses` getters (covered next) handle that derivation lazily.

Why fold totals here instead of inside `MonthlySummary`? Pragmatism. Totals require a single pass, and doing them once at construction is cheaper than recomputing them on every getter call. The pie/bar breakdowns, on the other hand, are only used when the user is looking at charts, so they live as getters.

### Savings Goals

`SavingsGoal` mirrors `MoneyTransaction` structurally — immutable fields, `copyWith`, no behaviour beyond two derived getters:

```dart
class SavingsGoal {
  final int id;
  final String name;
  final double targetAmount;
  final double savedAmount;
  final DateTime? deadline;
  final DateTime createdAt;

  const SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    this.savedAmount = 0,
    this.deadline,
    required this.createdAt,
  });
```

`savedAmount` defaults to `0` so a new goal can be constructed with just a name and target. `deadline` is nullable because deadlines are optional — a savings goal with no deadline is perfectly valid.

The two derived getters are short and worth showing:

```dart
double get progress => targetAmount <= 0 ? 0 : (savedAmount / targetAmount).clamp(0, 1);
bool get isCompleted => savedAmount >= targetAmount;
```

`progress` returns a 0..1 ratio for progress bars. Notice the explicit `targetAmount <= 0` guard — if the user somehow created a goal with target 0, dividing would produce NaN/infinity and crash the LinearProgressIndicator. `clamp(0, 1)` then ensures the ratio never escapes the legal range even if a buggy add-funds path pushed saved past target. Both guards are cheap insurance.

`isCompleted` is just a boolean for "are we done?" — used by the card widget to flip border color from purple to green and show a check icon.

#### `SavingsGoalRepository`

```dart
abstract interface class SavingsGoalRepository {
  Future<List<SavingsGoal>> getAllGoals();
  Future<int> createGoal(SavingsGoal goal);
  Future<void> updateGoal(SavingsGoal goal);
  Future<void> deleteGoal(int id);
  Future<void> addToSavings(int id, double amount);
}
```

`addToSavings(id, amount)` is the only non-CRUD method. The reasoning: adding funds is a load-modify-save operation that must happen atomically inside the data layer. Exposing it as `updateGoal(g.copyWith(savedAmount: g.savedAmount + n))` would have a race condition (two adds from two screens could clobber each other). Pushing it into the repo lets the data layer wrap it in an Isar write transaction. You'll see the implementation does exactly that.

There are no separate use case files for savings goals — the notifier in `money_provider.dart` calls the repository directly. This is a deliberate simplification: the savings operations have no validation logic worth extracting (the bottom sheet does input checks), so the use case layer would be five identical passthroughs. The team chose to skip them rather than add ceremony. You will see this pattern again in other features — use cases are added only where they earn their keep.

### Categories (entity + seed)

`MoneyCategory` is the lightest domain entity in the app:

```dart
class MoneyCategory {
  final String slug;       // unique key: 'food', 'salary', etc.
  final String name;
  final IconData icon;
  final Color color;
  final bool isExpense;

  const MoneyCategory({
    required this.slug,
    required this.name,
    required this.icon,
    required this.color,
    required this.isExpense,
  });
}
```

Categories are referenced by `slug` — a short, URL-safe string like `food` or `salary`. The reason for slugs (rather than auto-generated ids) is portability: if a user uninstalls and reinstalls the app, the new install ships with the same default slugs, so old transactions still map to the right category. An auto-incremented int would not survive that.

#### `category_seed.dart`

The seed file defines the default categories as plain `const` lists. There is no DB row for these — they live entirely in code:

```dart
const List<MoneyCategory> kDefaultExpenseCategories = [
  MoneyCategory(slug: 'food',          name: 'Food',         icon: Iconsax.cup,         color: Color(0xFFF59E0B), isExpense: true),
  MoneyCategory(slug: 'transport',     name: 'Transport',    icon: Iconsax.car,         color: Color(0xFF3B82F6), isExpense: true),
  MoneyCategory(slug: 'shopping',      name: 'Shopping',     icon: Iconsax.bag_2,       color: Color(0xFFEC4899), isExpense: true),
  MoneyCategory(slug: 'bills',         name: 'Bills',        icon: Iconsax.receipt_2,   color: Color(0xFFEF4444), isExpense: true),
  ...
];
```

The `k` prefix is a Flutter convention for top-level constants (the language has no `const` keyword for top-level identifiers that means "compile-time constant exported globally" without confusion, so the community adopted `kFoo` from the Dart team's own style guide). Treat them as `public static final` fields.

The `Iconsax.cup` references come from the `iconsax` package, which provides a large set of pre-styled outline icons. The colors are raw ARGB hex values (`0xFFF59E0B` = opaque amber).

There is also a fallback helper:

```dart
MoneyCategory categoryBySlug(String slug) =>
    allCategories.firstWhere((c) => c.slug == slug,
        orElse: () => const MoneyCategory(
              slug: 'other_exp',
              name: 'Other',
              icon: Iconsax.more_circle,
              color: Color(0xFF6B7280),
              isExpense: true,
            ));
```

`firstWhere` is the Dart equivalent of Java's `stream().filter(...).findFirst()`, except the `orElse` is required if you don't want it to throw. The returned fallback is "Other Expense" — used whenever a transaction references a slug that doesn't exist (corrupted DB, schema migration mismatch, user-deleted custom category). Defensive coding: the chart widgets never crash if a transaction has a bad slug, they just bucket it into "Other."

#### `CategoryModel`

```dart
@collection
class CategoryModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String slug;

  late String name;
  late String iconCodePoint; // MaterialIconData codePoint as hex string
  late int colorValue;       // ARGB int
  bool isExpense = true;
}
```

This collection exists for *user-created* custom categories — a feature the UI does not yet expose. The codebase reserves the table now so a future "create custom category" flow can ship without a schema migration. The icon is stored as a code point hex string (so the user can pick from any icon font) and the color as a raw ARGB int. There is no `toEntity()`/`fromEntity()` here because nothing reads or writes the table yet. Note this for later — it's the kind of "scaffold without callers" that a code reviewer should question.

### MonthlySummary

This is an aggregate — a domain value that exists only as the result of a use case. It is not stored anywhere.

```dart
class MonthlySummary {
  final int year;
  final int month;
  final double totalIncome;
  final double totalExpense;
  final List<MoneyTransaction> transactions;

  const MonthlySummary({
    required this.year,
    required this.month,
    required this.totalIncome,
    required this.totalExpense,
    required this.transactions,
  });

  double get balance => totalIncome - totalExpense;
```

Pre-computed totals (`totalIncome`, `totalExpense`) sit alongside the raw transaction list. The `balance` getter is a one-liner because the totals are already there.

The two interesting getters are the per-category and per-day folds used by the charts:

```dart
Map<String, double> get expenseByCategory {
  final map = <String, double>{};
  for (final t in transactions) {
    if (t.isExpense) {
      map[t.categorySlug] = (map[t.categorySlug] ?? 0) + t.amount;
    }
  }
  return map;
}
```

A plain group-by-and-sum, written with a for-loop because Dart's `groupBy` isn't in the core library and the team avoids extra deps for trivial folds. The `??` pattern (`map[k] ?? 0`) handles the "first time seeing this key" case the same way Java's `getOrDefault(k, 0)` would.

`dailyExpenses` does the same thing keyed by `t.date.day` (1..31):

```dart
Map<int, double> get dailyExpenses {
  final map = <int, double>{};
  for (final t in transactions) {
    if (t.isExpense) {
      map[t.date.day] = (map[t.date.day] ?? 0) + t.amount;
    }
  }
  return map;
}
```

Income transactions are filtered out — both charts only care about spending. The bar chart will later turn the missing day-keys into zero-height bars.

Because both getters re-fold on every access, the calling widget should be careful not to invoke them inside `build` more times than necessary. In practice each chart calls each getter once per build, which is fine for the small (≤ ~1000 rows) monthly data sets this app handles.

## Layer 2 — Data

Data layer translates between Isar collections and domain entities. Every file here imports `package:isar/isar.dart` and either a domain entity or another data file. Nothing here imports Flutter or Riverpod — the data layer is testable in plain Dart.

### Transactions

#### `TransactionModel` (Isar)

```dart
import 'package:isar/isar.dart';
import '../../domain/entities/transaction.dart';

part 'transaction_model.g.dart';

@collection
class TransactionModel {
  Id id = Isar.autoIncrement;

  late double amount;
  bool isExpense = true;

  @Index()
  late String categorySlug;

  String? note;

  @Index()
  late DateTime date;

  late DateTime createdAt;
```

`@collection` is Isar's `@Entity`. `Id` is a typedef for `int` that tells Isar this is the primary key. `Isar.autoIncrement` is a sentinel that means "let the DB assign an id."

The two `@Index()` annotations matter: `categorySlug` is indexed because we never query by it directly (yet), but the index keeps the door open; `date` is indexed because `getByMonth` filters by a date range. Without that index, monthly queries would degrade to full table scans as the user accumulates years of data.

`late` is Dart's "I promise to assign this before reading it." It's used here because Isar populates the fields after construction (via reflection in `.g.dart`), and Dart can't statically verify that.

`part 'transaction_model.g.dart';` pulls in the generated extension that gives Isar its query methods (`isar.transactionModels.where().sortByDateDesc().findAll()` etc.). You never edit the `.g.dart` file by hand — it is regenerated by `dart run build_runner build`.

The mapping methods are mirror images:

```dart
MoneyTransaction toEntity() => MoneyTransaction(
      id: id,
      amount: amount,
      isExpense: isExpense,
      categorySlug: categorySlug,
      note: note,
      date: date,
      createdAt: createdAt,
    );

static TransactionModel fromEntity(MoneyTransaction tx) => TransactionModel()
  ..id = tx.id
  ..amount = tx.amount
  ..isExpense = tx.isExpense
  ..categorySlug = tx.categorySlug
  ..note = tx.note
  ..date = tx.date
  ..createdAt = tx.createdAt;
```

The `..` cascade operator is Dart's "fluent assignment without writing return." Each `..field = value` returns the same `TransactionModel` instance, so the whole expression evaluates to the populated model. Java would write `var m = new TransactionModel(); m.setAmount(...); ...; return m;`.

#### `TransactionLocalDatasource`

The datasource owns the actual Isar calls. Every method is wrapped in a try/catch that converts low-level `IsarError` into the app's typed `DatabaseException`. This is the boundary where infrastructure errors become domain-visible errors — same pattern as a Spring `@Repository` translating SQLExceptions.

```dart
Future<List<TransactionModel>> getByMonth(int year, int month) async {
  try {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1).subtract(const Duration(microseconds: 1));
    return _isar.transactionModels
        .filter()
        .dateBetween(start, end)
        .sortByDateDesc()
        .findAll();
  } on IsarError catch (e) {
    throw DatabaseException('Failed to load monthly transactions', cause: e);
  }
}
```

The date math is worth a second look: `start` is the first instant of the month, and `end` is the first instant of the *next* month minus one microsecond — exclusive upper bound, made inclusive. Without the microsecond trick, a transaction created at `2026-07-01 00:00:00` would slip into the June query. `dateBetween` is inclusive on both ends, which is why the trick is needed.

`filter().dateBetween(...).sortByDateDesc().findAll()` is Isar's fluent query API. Each segment is method-generated from the model — `dateBetween` exists because of the `late DateTime date` field, `sortByDateDesc` exists because of the index. You get full type safety: a typo becomes a compile error.

Writes use `_isar.writeTxn`, Isar's transactional wrapper:

```dart
Future<int> putTransaction(TransactionModel model) async {
  try {
    return _isar.writeTxn(() => _isar.transactionModels.put(model));
  } on IsarError catch (e) {
    throw DatabaseException('Failed to save transaction', cause: e);
  }
}
```

`writeTxn` takes a callback, opens a transaction, runs the callback, and commits — equivalent to Spring's `@Transactional`. `put` is an upsert: if `model.id` is `autoIncrement`, it inserts and returns the new id; if `model.id` is set, it updates.

#### `TransactionRepositoryImpl`

The repository implementation is a thin adapter between domain entities and data models:

```dart
class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionLocalDatasource _datasource;
  TransactionRepositoryImpl(this._datasource);

  @override
  Future<List<MoneyTransaction>> getByMonth(int year, int month) async {
    final models = await _datasource.getByMonth(year, month);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<int> addTransaction(MoneyTransaction tx) {
    return _datasource.putTransaction(TransactionModel.fromEntity(tx));
  }
```

Pure plumbing — call the datasource, map results, return. No logic, no caching, no logging. Logging happens one level up in the notifier; caching happens nowhere (Riverpod gives us per-month memoization for free via `selectedMonthProvider` keying the query). This level is intentionally boring; the moment something interesting happens here is the moment a code reviewer should ask "should this be a use case instead?"

### Savings Goals

#### `SavingsGoalModel`

Same shape as `TransactionModel`, no indices because the table is small (a typical user has < 10 goals):

```dart
@collection
class SavingsGoalModel {
  Id id = Isar.autoIncrement;

  late String name;
  late double targetAmount;
  double savedAmount = 0;
  DateTime? deadline;
  late DateTime createdAt;
```

Same `toEntity` / `fromEntity` pair as before, so I won't repeat the code.

#### `SavingsGoalLocalDatasource`

The interesting method is `getGoalById`, which is needed to support the atomic "add to savings" flow:

```dart
Future<SavingsGoalModel?> getGoalById(int id) async {
  try {
    return _isar.savingsGoalModels.get(id);
  } on IsarError catch (e) {
    throw DatabaseException('Failed to get goal', cause: e);
  }
}
```

Returns nullable `SavingsGoalModel?` — `null` when the id doesn't exist. The repository uses this for its load-modify-save:

```dart
@override
Future<void> addToSavings(int id, double amount) async {
  final model = await _datasource.getGoalById(id);
  if (model == null) return;
  model.savedAmount = (model.savedAmount + amount).clamp(0, model.targetAmount);
  await _datasource.putGoal(model);
}
```

`clamp(0, targetAmount)` prevents over-funding past the target — even if the user enters a number larger than the remaining amount, the saved value caps at the target. The whole operation is two Isar calls: a `get` and a `put`. Each is its own transaction internally; the gap between them is the race window mentioned earlier. For a single-user offline app this is acceptable. If multiple writers were possible, you'd wrap both calls in a single `writeTxn`.

### Categories

There is no `CategoryDatasource` or `CategoryRepository` because nothing currently reads/writes the `CategoryModel` table. The model exists as a placeholder. Default categories are pulled from the static lists in `category_seed.dart` directly inside widgets that need them (the add-transaction sheet imports `kDefaultExpenseCategories` and `kDefaultIncomeCategories` straight from the seed). This is a deliberate shortcut — adding a full domain + data + presentation stack for a feature with zero runtime data would be ceremony for its own sake.

### MonthlySummary

No data-layer code at all. Summaries are computed fresh on each provider read from the underlying `MoneyTransaction` list. There is no persistent cache. The compute cost is `O(n)` over a single month's transactions; for typical users this is microseconds.

## Layer 3 — Presentation

This is the Riverpod-and-widgets layer. Read this section with `00-how-flutter-works.md` open to chapter on Riverpod if anything feels unfamiliar.

### `providers/money_provider.dart`

This is the dependency-injection wiring for the whole feature. Roughly: two repositories (singletons, scoped to the running app), one `StateProvider<SelectedMonth>` for the currently-displayed month, one `FutureProvider<MonthlySummary>` for the precomputed totals, and two `AsyncNotifierProvider`s — one for transactions, one for savings goals.

In Spring terms: every `Provider<X>` is a `@Bean` definition. The lambda is the bean factory; `ref.watch(otherProvider)` is `@Autowired` (or `applicationContext.getBean(...)`). `ref.invalidate` is the difference: Riverpod can reactively rebuild a bean's downstream consumers when its dependency changes. Spring has no equivalent — you'd hand-roll it with events or message bus.

#### Repository providers

```dart
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return TransactionRepositoryImpl(TransactionLocalDatasource(isar));
});

final savingsGoalRepositoryProvider = Provider<SavingsGoalRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return SavingsGoalRepositoryImpl(SavingsGoalLocalDatasource(isar));
});
```

Both depend on `isarProvider` (defined in `core/database/database_provider.dart` — that's the singleton Isar instance opened at startup). Building the datasource and repo is a one-shot `new`-and-wire. Because `Provider` caches its return value forever, you get a true singleton without writing `@Singleton`.

The return type is the abstract interface (`TransactionRepository`), not the impl. Consumers can never accidentally reach for an impl-specific method — exactly like injecting an interface in Spring.

#### `SelectedMonth` state

```dart
class SelectedMonth {
  final int year;
  final int month;
  const SelectedMonth(this.year, this.month);
}

final selectedMonthProvider = StateProvider<SelectedMonth>((ref) {
  final now = DateTime.now();
  return SelectedMonth(now.year, now.month);
});
```

A `StateProvider` is the simplest stateful provider: it holds one mutable value and notifies listeners on change. The initial value is computed once (current year/month). The summary card writes to this provider when the user taps the month-navigation arrows; everything that depends on it rebuilds automatically.

There is no `equals` on `SelectedMonth` — Dart compares by identity by default. Two `SelectedMonth(2026, 6)` instances are *not* equal under `==`. This sounds like a bug but isn't, because the only place writing is `_MonthNav._shift`, which always creates a new instance with different `m` or `y` — so listeners do see a change. If a future caller writes "the same" month back to the provider, listeners would still fire a rebuild. Cheap, harmless, and slightly wasteful — fine for this scale.

#### `monthlySummaryProvider`

```dart
final monthlySummaryProvider = FutureProvider<MonthlySummary>((ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  final sel = ref.watch(selectedMonthProvider);
  return GetMonthlySummaryUseCase(repo)(sel.year, sel.month);
});
```

`FutureProvider` exposes an `AsyncValue<MonthlySummary>` to widgets — that's the `loading / data / error` discriminated union you see callers consume with `.when(...)`. The provider re-runs whenever any watched dependency changes. So:

- If the user navigates from June to July, `selectedMonthProvider` changes, `ref.watch` notices, and Riverpod re-invokes the lambda, which fires off a new `getMonthlySummary` call.
- If somebody calls `ref.invalidate(monthlySummaryProvider)`, the cached result is dropped and the lambda re-runs with the *same* dependencies, refetching from disk. This is exactly what the transaction notifier does after adding a row.

The call `GetMonthlySummaryUseCase(repo)(...)` is a callable-class invocation: construct the use case with `repo`, then call its `call` method with `(year, month)`. Dart lets you drop `.call`.

#### `TransactionsNotifier`

```dart
final transactionsProvider =
    AsyncNotifierProvider<TransactionsNotifier, List<MoneyTransaction>>(
        TransactionsNotifier.new);

class TransactionsNotifier extends AsyncNotifier<List<MoneyTransaction>> {
  late TransactionRepository _repository;

  @override
  Future<List<MoneyTransaction>> build() async {
    _repository = ref.watch(transactionRepositoryProvider);
    final sel = ref.watch(selectedMonthProvider);
    return _repository.getByMonth(sel.year, sel.month);
  }
```

`AsyncNotifier` is the Riverpod base class for stateful providers that load asynchronously. `build` is the equivalent of `@PostConstruct` — Riverpod calls it the first time anyone reads the provider, and again whenever a watched dependency changes. It must return the initial state.

Note that the notifier and `monthlySummaryProvider` both load from the same data twice — one returns the raw list, the other returns aggregates. They could be unified, but separating them gives the transactions tab a stable list-shaped state while the summary widget consumes a different async shape (the totals). The trade-off is one extra Isar query per month load; the upside is each widget rebuilds at its own rhythm without coupling.

`_repository` is captured into a `late final`-ish field so the mutating methods (`add`, `delete`) can reach it without going through `ref` again.

Now the actions:

```dart
Future<void> add(MoneyTransaction tx) async {
  try {
    await AddTransactionUseCase(_repository)(tx);
    AppLogger.I.action('money', 'addTx',
        data: {'type': tx.isExpense ? 'expense' : 'income', 'amount': tx.amount, 'cat': tx.categorySlug});
    ref.invalidateSelf();
    ref.invalidate(monthlySummaryProvider);
  } catch (e, s) {
    AppLogger.I.error('money', 'addTx failed', error: e, stack: s);
    rethrow;
  }
}
```

Three things happen in the happy path:
1. Call the use case (which validates, then writes to disk).
2. Log a structured `action` event so the in-app log viewer can replay user actions during debugging.
3. Invalidate the two providers that depend on the underlying data — `transactionsProvider` itself (so the list rebuilds with the new row) and `monthlySummaryProvider` (so totals + charts refresh).

The catch block logs the error with full stack trace and rethrows. Rethrowing matters: the bottom sheet can catch it and show a snackbar; if we swallowed it here, the UI would think the save succeeded. `e, s` is Dart's syntax for "exception and stacktrace" — equivalent to Java catching `Exception e` and calling `e.getStackTrace()`.

`delete` is similar but uses optimistic local update instead of a full reload:

```dart
Future<void> delete(int id) async {
  try {
    await DeleteTransactionUseCase(_repository)(id);
    AppLogger.I.action('money', 'deleteTx', data: {'id': id});
    state = AsyncData(state.valueOrNull?.where((t) => t.id != id).toList() ?? []);
    ref.invalidate(monthlySummaryProvider);
  } catch (e, s) {
    AppLogger.I.error('money', 'deleteTx failed', error: e, stack: s, data: {'id': id});
    rethrow;
  }
}
```

Instead of invalidating self (which would trigger a full Isar reload), `delete` patches the existing state by filtering out the deleted id. This is a small UX win: list animations stay smooth because Flutter sees a removed item rather than a wholesale list swap.

The summary still gets invalidated because totals must shrink. Note the asymmetry — `add` invalidates self, `delete` patches self. There is no deep reason; `add` could also have patched state by inserting the new id at the front of the list. The author chose simplicity for `add` (refetch the whole month so server-side sorting is correct) and patch-in-place for `delete` (no risk of reordering).

#### `SavingsGoalsNotifier`

Same shape:

```dart
class SavingsGoalsNotifier extends AsyncNotifier<List<SavingsGoal>> {
  late SavingsGoalRepository _repository;

  @override
  Future<List<SavingsGoal>> build() async {
    _repository = ref.watch(savingsGoalRepositoryProvider);
    return _repository.getAllGoals();
  }

  Future<void> create(SavingsGoal goal) async {
    try {
      await _repository.createGoal(goal);
      AppLogger.I.action('goals', 'create',
          data: {'target': goal.targetAmount, 'hasDeadline': goal.deadline != null});
      ref.invalidateSelf();
    } catch (e, s) {
      AppLogger.I.error('goals', 'create failed', error: e, stack: s);
      rethrow;
    }
  }
```

`create` calls the repo directly (no use case — see the earlier note), logs structured data, and invalidates self. Goals do not feed into the monthly summary, so no cross-provider invalidation is needed.

```dart
Future<void> addToSavings(int id, double amount) async {
  try {
    await _repository.addToSavings(id, amount);
    AppLogger.I.action('goals', 'addFunds', data: {'id': id, 'amount': amount});
    ref.invalidateSelf();
  } catch (e, s) {
    AppLogger.I.error('goals', 'addFunds failed', error: e, stack: s, data: {'id': id});
    rethrow;
  }
}
```

`addToSavings` is the one that uses the repo's atomic load-modify-save under the hood. From the notifier's perspective it's just "call the method, log, invalidate." Delete uses the same optimistic-patch trick as the transaction notifier:

```dart
Future<void> delete(int id) async {
  try {
    await _repository.deleteGoal(id);
    AppLogger.I.action('goals', 'delete', data: {'id': id});
    state = AsyncData(state.valueOrNull?.where((g) => g.id != id).toList() ?? []);
  } catch (e, s) {
    AppLogger.I.error('goals', 'delete failed', error: e, stack: s, data: {'id': id});
    rethrow;
  }
}
```

The pattern across the three notifier methods is consistent: every mutation is wrapped in try/catch, both `action` (success) and `error` (failure) paths go through the same logger, and every error rethrows so the caller can react. This is the only feature in the app that uses logging this thoroughly — money-related bugs are the kind that lose user trust permanently, so the team chose verbose logging here even though it duplicates some structure.

### `screens/money_screen.dart`

The screen is a two-tab layout (Transactions / Goals) with a fixed header, a gradient summary card on top, and a floating action button at the bottom. Tabs are switched with a `TabController`; the FAB action depends on the active tab.

```dart
class _MoneyScreenState extends ConsumerState<MoneyScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
  }
```

`SingleTickerProviderStateMixin` is required because `TabController` needs a `vsync` (a ticker source for its swipe animation). It's the Flutter convention for stateful widgets that own one animation controller. The mixin gives the state object `this` as a valid `vsync`.

The `addListener` line is interesting: it forces a `setState` on every tab change so that the FAB's `onPressed` (which closes over `_tabCtrl.index`) is evaluated against the latest index. Without this, switching tabs while the FAB stays on screen would call the wrong action. There are cleaner ways (e.g. reading `_tabCtrl.index` directly inside `onPressed`, which already happens), but the explicit `setState` also lets the rest of the build re-evaluate — useful if some indicator needs to change with the tab.

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: kBgPrimary,
    body: SafeArea(
      child: Column(
        children: [
          _Header(),
          const SizedBox(height: 4),
          const SummaryCard(),
          const SizedBox(height: 12),
          _TabBar(controller: _tabCtrl),
          const SizedBox(height: 4),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: const [
                _TransactionsTab(),
                _SavingsTab(),
              ],
            ),
          ),
        ],
      ),
    ),
```

A `Scaffold` is Flutter's page chrome — like a base `JFrame` layout that includes app bar, body, FAB, drawer slots. `SafeArea` insets around notches/cutouts. `Column` lays children vertically; `Expanded` makes the `TabBarView` fill the remaining vertical space.

The FAB picks its action based on the tab index:

```dart
floatingActionButton: FloatingActionButton(
  onPressed: () => _tabCtrl.index == 0
      ? showAddTransactionSheet(context)
      : showCreateGoalSheet(context),
  backgroundColor: kAccentPurple,
  child: const Icon(Icons.add_rounded, color: Colors.white),
),
```

Each tab is a `ConsumerWidget` that watches the relevant provider. `_TransactionsTab` is the more involved of the two:

```dart
class _TransactionsTab extends ConsumerWidget {
  const _TransactionsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(transactionsProvider);
    final summaryAsync = ref.watch(monthlySummaryProvider);

    return txAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: kAccentPurple)),
      error: (e, _) => Center(
          child: Text('Error: $e',
              style: const TextStyle(color: kTextSecondary))),
      data: (txList) {
        if (txList.isEmpty) {
          return const _EmptyState(
            icon: Icons.receipt_long_rounded,
            message: 'No transactions this month',
            sub: 'Tap + to add income or an expense',
          );
        }

        final MonthlySummary? summary = summaryAsync.valueOrNull;
        final hasExpenses = summary != null && summary.totalExpense > 0;

        return ListView.builder(
          padding: const EdgeInsets.only(top: 4, bottom: 100),
          // +1 for charts header when there are expenses
          itemCount: txList.length + (hasExpenses ? 1 : 0),
          itemBuilder: (_, i) {
            if (hasExpenses && i == 0) {
              return _ChartsSection(summary: summary);
            }
            final tx = txList[hasExpenses ? i - 1 : i];
            return TransactionCard(
              transaction: tx,
              onDelete: () =>
                  ref.read(transactionsProvider.notifier).delete(tx.id),
            );
          },
        );
      },
    );
  }
}
```

A few patterns to learn from this widget:

- `ref.watch(transactionsProvider)` gives an `AsyncValue<List<MoneyTransaction>>` — the same `loading/data/error` triplet you'd see in a Spring reactive WebClient.
- `.when(loading:, error:, data:)` is a pattern-match-ish exhaustive switch that returns a widget for each state. There is no path that "forgets" a state.
- The widget also watches the summary, but uses `valueOrNull` (no error handling needed because the summary error case is handled inside the gradient card itself). If the summary hasn't loaded yet, charts are hidden — the user sees only the list.
- The `itemCount` arithmetic is the classic ListView trick: prepend a "header" by adding 1 to the count and special-casing index 0. Inside `itemBuilder`, the row index is offset accordingly.
- `onDelete` calls `ref.read(transactionsProvider.notifier).delete(...)`. Note `read`, not `watch` — inside callbacks you never want to subscribe, just fire-and-forget.

The `.notifier` accessor on an `AsyncNotifierProvider` returns the underlying `TransactionsNotifier` instance. That's how a button reaches into the bean to invoke `delete(id)`.

`_SavingsTab` is structurally identical — watch goals provider, dispatch `.when`, render an empty state or a `ListView`. The only difference is the per-card delete flow goes through a confirmation dialog because deleting a goal is more painful to undo than deleting a transaction:

```dart
void _confirmDelete(
    BuildContext context, WidgetRef ref, SavingsGoal goal) {
  showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: kBgSecondary,
      title: const Text('Delete goal?',
          style: TextStyle(color: kTextPrimary)),
      content: Text('Delete "${goal.name}"? This cannot be undone.',
          style: const TextStyle(color: kTextSecondary)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel',
              style: TextStyle(color: kTextSecondary)),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            ref.read(savingsGoalsProvider.notifier).delete(goal.id);
          },
          child: const Text('Delete',
              style: TextStyle(color: Colors.redAccent)),
        ),
      ],
    ),
  );
}
```

`showDialog` returns a `Future<bool?>` — `Navigator.pop(ctx, value)` resolves the future with that value, `Navigator.pop(ctx)` resolves it with null. In this implementation the return value isn't actually awaited (the delete is fired inside the Delete button's onPressed), which is slightly redundant. Functionally fine.

### `widgets/summary_card.dart`

The gradient card at the top of the screen. It watches both the summary provider and the selected month, displays balance/income/expenses in a chip layout, and exposes month-navigation arrows.

```dart
class SummaryCard extends ConsumerWidget {
  const SummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(monthlySummaryProvider);
    final sel = ref.watch(selectedMonthProvider);
```

The body switches on `summaryAsync.when(loading, error, data)`. The loading path renders a `_CardSkeleton` (gray placeholder blocks); the error path renders a one-liner; the data path renders the full chip layout.

The month-nav buttons mutate `selectedMonthProvider`:

```dart
void _shift(WidgetRef ref, int delta) {
  final sel = ref.read(selectedMonthProvider);
  var m = sel.month + delta;
  var y = sel.year;
  if (m < 1) {
    m = 12;
    y--;
  }
  if (m > 12) {
    m = 1;
    y++;
  }
  ref.read(selectedMonthProvider.notifier).state = SelectedMonth(y, m);
}
```

Adding to `selectedMonthProvider.state` triggers the chain: month changes -> `monthlySummaryProvider` re-runs (because it watches `selectedMonthProvider`) -> `transactionsProvider` re-runs (same reason) -> both lists and totals reload. The card itself rebuilds because it also watches `selectedMonthProvider`. Notice the use of `read` for mutation — never `watch`, which would cause the callback to re-subscribe.

The `_fmt` formatter compresses big numbers to `1.2K` / `1.5M` so the gradient card stays readable even with large balances. Same helper repeats inside the transaction card and the chart widgets — DRY would suggest extracting it, but it's three lines and lives independently per widget. Acceptable.

### `widgets/transaction_card.dart`

Each row is a swipe-to-delete card. The `Dismissible` widget is Flutter's idiomatic gesture wrapper for "drag the row sideways to delete":

```dart
return Dismissible(
  key: ValueKey(transaction.id),
  direction: DismissDirection.endToStart,
  background: Container(
    alignment: Alignment.centerRight,
    padding: const EdgeInsets.only(right: 20),
    decoration: BoxDecoration(
      color: Colors.red.shade900,
      borderRadius: BorderRadius.circular(14),
    ),
    child: const Icon(Icons.delete_rounded, color: Colors.white),
  ),
  confirmDismiss: (_) async {
    return await showDialog<bool>(...) ?? false;
  },
  onDismissed: (_) => onDelete(),
```

Three callbacks worth understanding:
- `key: ValueKey(transaction.id)` — Flutter requires a stable key on every dismissible so it can track which item moved during the animation. Reusing the transaction id is the natural choice.
- `confirmDismiss` runs *before* the dismiss completes — if it returns `false`, the row springs back. This is where the confirmation dialog lives.
- `onDismissed` runs after the dismiss animation ends and only if `confirmDismiss` returned true. It's the right place to fire the actual delete.

The body of the card is a horizontal row: colored category icon on the left, name + (note or date) in the middle, signed amount on the right. The icon comes from `categoryBySlug(transaction.categorySlug)` — the same fallback-protected lookup we saw in the seed file.

```dart
Text(
  '${isExpense ? '-' : '+'}₹${_fmtAmount(transaction.amount)}',
  style: TextStyle(
    color: isExpense
        ? const Color(0xFFF87171)
        : const Color(0xFF34D399),
    fontSize: 15,
    fontWeight: FontWeight.w600,
  ),
),
```

Red for expense, green for income, sign character on the front. The `₹` symbol is hard-coded — there is no locale switching in this app yet. If the team ever needs multi-currency support, every formatter in the feature will need to grow a parameter.

### `widgets/savings_goal_card.dart`

The card for a savings goal is mostly a vertical layout: name + delete icon row, saved/target row, progress bar, percentage + deadline row, "Add Funds" button.

The progress visualization is a stock `LinearProgressIndicator` with the `value` bound to `goal.progress` (the 0..1 ratio from the domain entity):

```dart
ClipRRect(
  borderRadius: BorderRadius.circular(4),
  child: LinearProgressIndicator(
    value: goal.progress,
    minHeight: 6,
    backgroundColor: kBgTertiary,
    valueColor: AlwaysStoppedAnimation(
        completed ? kAccentGreen : kAccentPurple),
  ),
),
```

Because the domain getter clamps the ratio to `[0, 1]` and guards division-by-zero, this widget never gets a bad value. The color swaps to green when the goal is complete, matching the border:

```dart
border: Border.all(
  color: completed ? kAccentGreen.withAlpha(80) : kGlassBorder,
  width: completed ? 1.5 : 0.5,
),
```

The deadline label is computed via:

```dart
static String _deadlineLabel(DateTime d) {
  final diff = d.difference(DateTime.now()).inDays;
  if (diff < 0) return 'Overdue';
  if (diff == 0) return 'Due today';
  if (diff == 1) return 'Due tomorrow';
  return 'Due in $diff days';
}
```

Plain integer-diff math, no `intl` dependency. The "Add Funds" button is hidden when the goal is completed — the user has nothing meaningful to add.

### `widgets/add_transaction_sheet.dart`

The "new transaction" bottom sheet. It's a `ConsumerStatefulWidget` because it has its own form state (amount text controller, selected category slug, selected date, expense/income toggle) but also needs to dispatch to the notifier on save.

Form state setup:

```dart
class _AddTransactionSheetState extends ConsumerState<_AddTransactionSheet> {
  bool _isExpense = true;
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String? _selectedSlug;
  DateTime _date = DateTime.now();

  List<MoneyCategory> get _categories =>
      _isExpense ? kDefaultExpenseCategories : kDefaultIncomeCategories;
```

The toggle, the slug, and the date are managed with `setState`. The text controllers (`TextEditingController`) are the Flutter equivalent of a `JTextField`'s backing model — they hold the current text value and notify the field when programmatically changed. Always remember to `dispose()` them in the state's dispose method to avoid leaking listeners:

```dart
@override
void dispose() {
  _amountCtrl.dispose();
  _noteCtrl.dispose();
  super.dispose();
}
```

The amount field restricts input to digits and one decimal point via an input formatter:

```dart
TextField(
  controller: _amountCtrl,
  keyboardType:
      const TextInputType.numberWithOptions(decimal: true),
  inputFormatters: [
    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
  ],
  ...
),
```

The regex `^\d+\.?\d{0,2}` accepts "one or more digits, optionally a dot, optionally up to two more digits." Combined with the numeric keyboard, this is enough to keep input clean without manual parsing.

When the user toggles between Expense and Income, the category list flips and the default slug resets:

```dart
_TypeTab(
  label: 'Expense',
  selected: _isExpense,
  color: const Color(0xFFF87171),
  onTap: () {
    setState(() {
      _isExpense = true;
      _selectedSlug = kDefaultExpenseCategories.first.slug;
    });
  },
),
```

Without resetting `_selectedSlug`, an "expense food" slug would survive a switch to Income, leaving the chip grid with no selection highlighted.

Saving:

```dart
void _save() {
  final raw = double.tryParse(_amountCtrl.text.trim());
  if (raw == null || raw <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Enter a valid amount')),
    );
    return;
  }
  final note = _noteCtrl.text.trim();
  final tx = MoneyTransaction(
    id: 0,
    amount: raw,
    isExpense: _isExpense,
    categorySlug: _selectedSlug ?? (_isExpense ? 'other_exp' : 'other_inc'),
    note: note.isEmpty ? null : note,
    date: _date,
    createdAt: DateTime.now(),
  );
  ref.read(transactionsProvider.notifier).add(tx);
  Navigator.of(context).pop();
}
```

A few notes:
- `double.tryParse` returns `null` on bad input instead of throwing — Dart's standard "parse-or-fail-soft" helper.
- `id: 0` is the sentinel that tells Isar's `put` to auto-assign an id.
- The slug fallback (`other_exp` / `other_inc`) handles a paranoid case — `_selectedSlug` is set in `initState` so it's never null in practice, but the type system insists on something.
- The notifier's `add` is fire-and-forget; the sheet closes immediately. If the save fails (validation in the use case, disk error), the rethrow surfaces in the notifier's logs and the snackbar from the optimistic close would be wrong. In production this is the kind of UX detail you might tighten: `await` the save, show a snackbar on failure, close on success. The current code prioritizes responsiveness.

### `widgets/savings_goal_sheet.dart`

Two bottom sheets in one file: `_CreateGoalSheet` (new goal) and `_AddFundsSheet` (top up an existing goal). The shapes mirror the transaction sheet.

Create goal save:

```dart
void _save() {
  final name = _nameCtrl.text.trim();
  final target = double.tryParse(_targetCtrl.text.trim());
  if (name.isEmpty || target == null || target <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Enter a name and valid target amount')),
    );
    return;
  }
  final goal = SavingsGoal(
    id: 0,
    name: name,
    targetAmount: target,
    deadline: _deadline,
    createdAt: DateTime.now(),
  );
  ref.read(savingsGoalsProvider.notifier).create(goal);
  Navigator.of(context).pop();
}
```

Add funds is structurally similar:

```dart
void _save() {
  final amount = double.tryParse(_amountCtrl.text.trim());
  if (amount == null || amount <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Enter a valid amount')),
    );
    return;
  }
  ref
      .read(savingsGoalsProvider.notifier)
      .addToSavings(widget.goal.id, amount);
  Navigator.of(context).pop();
}
```

The "remaining" hint above the input is computed inline from the goal entity — the sheet receives the goal as a constructor parameter, so we don't even need to watch a provider for it. Once the user submits and the notifier patches state, the sheet has already closed.

### `widgets/category_pie_chart.dart`

The donut chart uses the `fl_chart` package — a popular charting library that integrates well with Flutter's render layer. The data input is `Map<String, double> expenseByCategory` plus the `totalExpense` total.

The first thing the build method does is the div-by-zero guard:

```dart
if (widget.expenseByCategory.isEmpty || widget.totalExpense <= 0) {
  return const SizedBox.shrink();
}
```

`SizedBox.shrink()` is "render nothing, take no space." If either the per-category map is empty or the total is zero or negative, the chart bails out cleanly. Without this guard, the next line — `amount / widget.totalExpense * 100` for the percentage label — would produce NaN/infinity, which `fl_chart` doesn't render gracefully.

Entries are sorted by amount descending so the largest slice draws first:

```dart
final entries = widget.expenseByCategory.entries.toList()
  ..sort((a, b) => b.value.compareTo(a.value));

final sections = entries.asMap().entries.map((e) {
  final idx = e.key;
  final slug = e.value.key;
  final amount = e.value.value;
  final cat = categoryBySlug(slug);
  final isTouched = idx == _touched;
  final pct = (amount / widget.totalExpense * 100);

  return PieChartSectionData(
    value: amount,
    color: cat.color,
    radius: isTouched ? 52 : 44,
    title: isTouched ? '${pct.toStringAsFixed(0)}%' : '',
    titleStyle: const TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontWeight: FontWeight.w700,
    ),
    badgeWidget: null,
  );
}).toList();
```

`entries.asMap()` turns the list into a `Map<int, MapEntry<String, double>>` indexed by position — that gives each section a stable integer index for the touch handler to compare against `_touched`. The touched section pops out by 8 pixels and shows its percent label.

Touch handling lives inside `PieTouchData`:

```dart
pieTouchData: PieTouchData(
  touchCallback: (event, response) {
    setState(() {
      if (!event.isInterestedForInteractions ||
          response == null ||
          response.touchedSection == null) {
        _touched = -1;
        return;
      }
      _touched = response
          .touchedSection!.touchedSectionIndex;
    });
  },
),
```

`fl_chart` fires this callback for every gesture event — entering, moving across slices, leaving. The widget tracks the currently-highlighted index in `_touched`. `setState(() {...})` triggers a rebuild that resizes the touched slice and shows its label.

Around the donut, an `Expanded` column lists each category with a colored dot, name, and percentage:

```dart
Expanded(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: entries.map((e) {
      final cat = categoryBySlug(e.key);
      final pct =
          (e.value / widget.totalExpense * 100)
              .toStringAsFixed(0);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Container(width: 8, height: 8, decoration: ...),
            const SizedBox(width: 6),
            Expanded(child: Text(cat.name, ...)),
            Text('$pct%', ...),
          ],
        ),
      );
    }).toList(),
  ),
),
```

Because the same div-by-zero guard runs at the top, the `e.value / widget.totalExpense` here is also safe.

### `widgets/expense_bar_chart.dart`

The bar chart shows one bar per day in the selected month. The horizontal axis is fixed-width (28-31 bars depending on the month), so wider months use thinner bars.

Just like the pie chart, the bar chart guards against empty / zero-peak data:

```dart
final daysInMonth =
    DateTime(summary.year, summary.month + 1, 0).day;
final daily = summary.dailyExpenses;

if (daily.isEmpty) return const SizedBox.shrink();

final peak = daily.values.reduce((a, b) => a > b ? a : b);
if (peak <= 0) return const SizedBox.shrink();
final maxY = (peak * 1.25).ceilToDouble();
```

Three guards:
- `daily.isEmpty` — no expenses recorded for the month, skip the chart entirely.
- `peak <= 0` — every entry is zero, which shouldn't happen with the income-filtering in `dailyExpenses` but is checked anyway.
- `maxY = (peak * 1.25).ceilToDouble()` — the y-axis tops out 25% above the highest bar so the largest bar doesn't touch the top edge.

`DateTime(year, month + 1, 0)` is the Dart trick for "last day of month": day 0 of month N+1 is day "last" of month N. So `DateTime(2026, 7, 0).day` is `30` (June has 30 days).

Bar groups are generated one per day:

```dart
final groups = List.generate(daysInMonth, (i) {
  final day = i + 1;
  final amount = daily[day] ?? 0.0;
  return BarChartGroupData(
    x: i,
    barRods: [
      BarChartRodData(
        toY: amount,
        gradient: amount > 0
            ? const LinearGradient(
                colors: [kAccentPurple, kAccentPink],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              )
            : null,
        color: amount > 0 ? null : Colors.transparent,
        width: _barWidth(daysInMonth),
        borderRadius: BorderRadius.circular(3),
      ),
    ],
  );
});
```

Days with no spending render a transparent zero-height rod — they take a slot on the axis but draw nothing. Days with spending render a vertical purple-to-pink gradient bar. Bar width is dynamic:

```dart
static double _barWidth(int days) {
  if (days <= 15) return 12;
  if (days <= 20) return 9;
  return 6;
}
```

For most months this returns 6 (28-31 bars in a row).

The bottom axis only labels a few days to avoid clutter — 1, 10, 20, the last day, and "today" if the chart is showing the current month:

```dart
bottomTitles: AxisTitles(
  sideTitles: SideTitles(
    showTitles: true,
    reservedSize: 20,
    getTitlesWidget: (value, _) {
      final day = value.toInt() + 1;
      final isToday = isCurrentMonth &&
          day == today.day;
      final show = day == 1 ||
          day == 10 ||
          day == 20 ||
          day == daysInMonth ||
          isToday;
      if (!show) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          '$day',
          style: TextStyle(
            color: isToday
                ? kAccentPurple
                : kTextHint,
            fontSize: 10,
            fontWeight: isToday
                ? FontWeight.w700
                : FontWeight.normal,
          ),
        ),
      );
    },
  ),
),
```

Today's label is highlighted in purple bold — a small touch that grounds the user in time when looking at the current month.

Tooltips are filtered to skip zero-height bars:

```dart
barTouchData: BarTouchData(
  touchTooltipData: BarTouchTooltipData(
    getTooltipColor: (_) => kBgTertiary,
    tooltipPadding: const EdgeInsets.symmetric(
        horizontal: 8, vertical: 4),
    getTooltipItem: (group, _, rod, __) {
      if (rod.toY == 0) return null;
      return BarTooltipItem(
        '₹${_fmt(rod.toY)}',
        const TextStyle(...),
      );
    },
  ),
),
```

Returning `null` from `getTooltipItem` suppresses the tooltip for that bar. So tapping an empty day shows nothing; tapping a day with spending shows `₹250`-style amount.

## Trace: add a $20 coffee expense and watch pie chart update

Let's walk an end-to-end click. The user is on the Money screen, looking at the current month (say July 2026), and decides to log a coffee. Here is the entire sequence from tap to render.

**Step 1 — User taps the floating action button.**

The FAB's `onPressed` is:

```dart
() => _tabCtrl.index == 0
    ? showAddTransactionSheet(context)
    : showCreateGoalSheet(context),
```

Tab 0 is active (Transactions). `showAddTransactionSheet(context)` is called — that's a top-level function in `add_transaction_sheet.dart` that wraps `showModalBottomSheet`. Flutter pushes a new modal route onto the navigator, the bottom sheet animates up from the screen edge.

**Step 2 — User fills the sheet.**

- Toggle stays on Expense (default).
- User types `20.00` into the amount field. `FilteringTextInputFormatter` ensures only valid characters reach the controller.
- User taps the Food chip. `setState` fires; `_selectedSlug = 'food'`.
- User leaves the date as Today, the note empty.
- User taps "Save Transaction."

**Step 3 — `_save` builds and dispatches.**

```dart
void _save() {
  final raw = double.tryParse(_amountCtrl.text.trim());  // 20.0
  if (raw == null || raw <= 0) { ... }
  final note = _noteCtrl.text.trim();                     // ''
  final tx = MoneyTransaction(
    id: 0,
    amount: 20.0,
    isExpense: true,
    categorySlug: 'food',
    note: null,                  // empty string -> null
    date: DateTime.now(),
    createdAt: DateTime.now(),
  );
  ref.read(transactionsProvider.notifier).add(tx);
  Navigator.of(context).pop();
}
```

Two interactions with the framework:
- `ref.read(transactionsProvider.notifier).add(tx)` reaches into the bean container, grabs the singleton `TransactionsNotifier`, and calls its `add` method.
- `Navigator.of(context).pop()` closes the bottom sheet immediately. The save proceeds asynchronously.

**Step 4 — Notifier validates, writes, logs, invalidates.**

Inside `TransactionsNotifier.add`:

```dart
Future<void> add(MoneyTransaction tx) async {
  try {
    await AddTransactionUseCase(_repository)(tx);
    AppLogger.I.action('money', 'addTx',
        data: {'type': 'expense', 'amount': 20.0, 'cat': 'food'});
    ref.invalidateSelf();
    ref.invalidate(monthlySummaryProvider);
  } catch (e, s) {
    AppLogger.I.error('money', 'addTx failed', error: e, stack: s);
    rethrow;
  }
}
```

`AddTransactionUseCase(_repository)(tx)` constructs the callable use case and invokes it with the transaction:

```dart
Future<int> call(MoneyTransaction tx) async {
  if (tx.amount <= 0) throw const ValidationException(...);   // 20 > 0, passes
  if (tx.categorySlug.isEmpty) throw const ValidationException(...);  // 'food' non-empty, passes
  return _repository.addTransaction(tx);
}
```

Validations pass. The repository forwards to the datasource:

```dart
@override
Future<int> addTransaction(MoneyTransaction tx) {
  return _datasource.putTransaction(TransactionModel.fromEntity(tx));
}
```

`fromEntity` builds a fresh `TransactionModel` with `id = 0` (the autoIncrement sentinel). The datasource opens an Isar write transaction:

```dart
Future<int> putTransaction(TransactionModel model) async {
  try {
    return _isar.writeTxn(() => _isar.transactionModels.put(model));
  } on IsarError catch (e) {
    throw DatabaseException('Failed to save transaction', cause: e);
  }
}
```

Isar assigns id (say `42`), commits, returns. The use case returns `42`. Back in the notifier:

- `AppLogger.I.action(...)` writes a structured event into the in-app log buffer. If the user opens the log viewer, they'll see this row.
- `ref.invalidateSelf()` drops the cached `List<MoneyTransaction>` for the current month. Riverpod schedules a rebuild.
- `ref.invalidate(monthlySummaryProvider)` drops the cached `MonthlySummary`. Riverpod schedules a rebuild for that too.

**Step 5 — Riverpod re-runs both providers.**

In the next frame, Riverpod sees both providers are invalidated and re-invokes their builders:

```dart
// transactionsProvider's notifier.build()
_repository = ref.watch(transactionRepositoryProvider);
final sel = ref.watch(selectedMonthProvider);  // July 2026
return _repository.getByMonth(sel.year, sel.month);
```

That hits Isar:

```dart
return _isar.transactionModels
    .filter()
    .dateBetween(start, end)
    .sortByDateDesc()
    .findAll();
```

The new row (id 42, amount 20, slug 'food', date today) is included because today is in July 2026 and the index makes the query fast. Result: `List<MoneyTransaction>` with N+1 entries, sorted by date desc.

In parallel, `monthlySummaryProvider`:

```dart
final repo = ref.watch(transactionRepositoryProvider);
final sel = ref.watch(selectedMonthProvider);
return GetMonthlySummaryUseCase(repo)(sel.year, sel.month);
```

That fires the same `getByMonth` call (a second round-trip — see the earlier note about duplicate queries), folds totals, returns a new `MonthlySummary` with `totalExpense += 20.0`.

**Step 6 — Widgets rebuild.**

Three widgets subscribe to the changed providers:

- `SummaryCard` watches `monthlySummaryProvider`. Its `.when(data:)` callback receives the new summary. Balance text rebuilds with the new value (income unchanged, expense +20, so balance −20).
- `_TransactionsTab` watches `transactionsProvider` (for the list) and `monthlySummaryProvider` (for the charts header). Its `.when(data:)` receives the new list (length N+1), it computes `hasExpenses = true`, and rebuilds the `ListView.builder` with N+2 items (N+1 transactions + 1 charts header).
- The charts section inside `_TransactionsTab` receives the new `MonthlySummary` and rebuilds `_ChartsSection`, which contains `ExpenseBarChart` and `CategoryPieChart`.

**Step 7 — Charts redraw.**

`CategoryPieChart` receives the updated `summary.expenseByCategory` map. If 'food' was already a category in the user's expenses, that slice grows by 20. If it wasn't, a new pink-amber slice appears. The widget's stateful `_touched` is preserved (the chart was never disposed), so any prior highlight stays.

`ExpenseBarChart` receives `summary.dailyExpenses`. Today's bar grows by 20. `maxY` is recomputed (`peak * 1.25`), so if today is now the new peak day, the entire chart re-scales. The today-label in the bottom axis stays purple.

The list itself shows the new transaction card at the top (because `sortByDateDesc` puts the latest first). The user sees:
- Summary card: balance dropped by 20.
- Chart section: pie has an updated Food slice, bar has a taller bar for today.
- List: a new "Food − ₹20" row at index 1 (after the chart section at index 0).

**Step 8 — User taps and holds the Food slice.**

The donut's `touchCallback` fires with `response.touchedSection.touchedSectionIndex = 0` (assuming Food is the largest). `setState` flips `_touched` to 0. The build method re-runs: the Food section's `radius` jumps from 44 to 52 and its `title` becomes the percentage. The user sees the slice pop out with the percent overlaid.

**Total state mutations from one tap:** one Isar write, one log record, two provider invalidations, three widget rebuilds.

**Total without manual `setState` outside the sheet:** the chart, the summary card, and the list all update reactively. The only `setState` in the entire chain is the one inside the bottom sheet (to flip toggle / category chip selections) — and the sheet is already gone by the time everything else rebuilds.

That is the Riverpod-Flutter loop in its full form: a single action invalidates providers, the framework re-runs every watcher, and widgets diff against the previous tree. You do not "tell" the chart to update; you change the data it depends on, and the chart updates itself. The whole thing happens within one to two frames (≤ 33 ms on a 60-Hz device) for typical monthly data sets.

If you want to confirm the chain by hand, set a breakpoint in `TransactionsNotifier.add` and another in `CategoryPieChart.build`. Trigger a save. You'll hit `add` first, then `build` exactly once on the charts widget after both providers settle. Toggle off the `ref.invalidate(monthlySummaryProvider)` line and you'll see the list update but the charts and balance staying stale — that's how you prove the invalidation matters.

This concludes the Money feature walkthrough. The next chapter covers the Mindset feature, which is structurally simpler but introduces a new pattern: a single notifier owning multiple sub-collections inside one Isar database.
