# 04 — Screen: Tasks

The Tasks feature is the most "interactive" screen in the app — it has create, read, update, delete, complete-toggle, drag-to-reorder, swipe-to-delete, an active/completed tab split, and a phone-vs-tablet adaptive layout. It is also the cleanest example of Clean Architecture in the codebase: every gesture flows from `Widget -> Notifier -> UseCase -> Repository -> Datasource -> Isar` and back.

If you read chapter `00-how-flutter-works.md`, you already have the mental model: widgets are immutable view-models, Riverpod is the DI container, and Isar is the local NoSQL DB. This chapter walks the entire vertical slice and ends with a step-by-step trace of a single drag-to-reorder gesture so you can see every layer fire in order.

## File map

| Layer | File | Spring analogy |
|---|---|---|
| Domain entity | `domain/entities/task.dart` | JPA-free POJO / record |
| Repository port | `domain/repositories/task_repository.dart` | `interface TaskRepository` |
| Use case | `domain/use_cases/create_task_use_case.dart` | `@Service` method |
| Use case | `domain/use_cases/update_task_use_case.dart` | `@Service` method |
| Use case | `domain/use_cases/delete_task_use_case.dart` | `@Service` method |
| Use case | `domain/use_cases/toggle_complete_use_case.dart` | `@Service` method |
| Use case | `domain/use_cases/reorder_tasks_use_case.dart` | `@Service` method |
| Persistence model | `data/models/task_model.dart` | `@Entity` (Isar collection) |
| Datasource | `data/datasources/task_local_datasource.dart` | `JpaRepository` impl |
| Repository impl | `data/repositories/task_repository_impl.dart` | `@Repository` bean |
| DI / state | `presentation/providers/tasks_provider.dart` | `@Component` + `@Service` wiring |
| Screen | `presentation/screens/tasks_screen.dart` | `@Controller` + view |
| List item | `presentation/widgets/task_card.dart` | partial / fragment |
| Form sheet | `presentation/widgets/task_bottom_sheet.dart` | modal form view |
| Tiny widget | `presentation/widgets/priority_badge.dart` | reusable view component |

All paths are relative to `MobileApp/app/lib/features/tasks/`.

A quick reminder on the layers if you've forgotten:

- **Domain** is pure Dart. No Flutter, no Isar, no JSON. If you imported the Dart SDK only, this layer would compile. It defines what a `Task` is and what operations are allowed.
- **Data** is the storage adapter. It depends on Isar and translates between Isar's mutable `TaskModel` and the domain's immutable `Task`.
- **Presentation** is the UI plus Riverpod providers. Widgets only know about domain entities; they never see a `TaskModel`.

This is identical to a Spring app where your controllers return DTOs that map from `@Entity` classes via a mapper layer — except in Dart we hand-roll the mappers (`toEntity` / `fromEntity`) because Dart doesn't have MapStruct.

---

## Layer 1 — Domain

The domain layer is roughly 80 lines across 7 files. It defines:

1. The `Task` entity and its `Priority` enum.
2. The `TaskRepository` interface (an abstract port).
3. Five use-case classes, one per write operation.

### `domain/entities/task.dart`

```dart
enum Priority { low, medium, high }

class Task {
  final int id;
  final String title;
  final String? note;
  final bool isCompleted;
  final Priority priority;
  final DateTime? dueDate;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
```

Everything is `final` — Dart's equivalent of declaring every record component immutable. Compare this to a Java record:

```java
public record Task(int id, String title, String note, boolean isCompleted,
                   Priority priority, LocalDateTime dueDate, int sortOrder,
                   LocalDateTime createdAt, LocalDateTime updatedAt) {}
```

The difference is that Dart's `class` syntax lets us add behavior (computed getters, validation, `copyWith`) without ceremony. Records in Java/Kotlin can do the same but the syntax is heavier.

```dart
  Task copyWith({
    int? id,
    String? title,
    String? note,
    bool? isCompleted,
    Priority? priority,
    DateTime? dueDate,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      ...
    );
  }
```

`copyWith` is the Dart idiom for "give me a new immutable copy with these fields changed". Kotlin gives you this for free via `data class` `.copy(...)`. In Dart you write it manually (or generate it with `freezed`). The trick with the `?` and `??`: every parameter is optional and nullable. Inside, `id ?? this.id` means "if the caller passed `id`, use it; otherwise keep `this.id`". This works fine for non-nullable fields but has a known wart for nullable ones — you can't distinguish "user passed `null`" from "user passed nothing". For `Task` that's irrelevant because all the optional fields (`note`, `dueDate`) are already nullable in semantics — passing `null` to clear them is what you want.

```dart
  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    return dueDate!.isBefore(DateTime.now());
  }
```

A computed getter — no parentheses at call site, called as `task.isOverdue`. The `!` after `dueDate` is the null-assertion operator: we just guarded with `dueDate == null`, so we promise the compiler it's not null. Dart's flow analysis isn't smart enough to figure that out across the `||` boundary on a non-local field, hence the bang.

In Java this would be:

```java
public boolean isOverdue() {
    if (dueDate == null || isCompleted) return false;
    return dueDate.isBefore(LocalDateTime.now());
}
```

### `domain/repositories/task_repository.dart`

```dart
import '../entities/task.dart';

abstract interface class TaskRepository {
  Future<List<Task>> getAllTasks();
  Future<List<Task>> getActiveTasks();
  Future<List<Task>> getCompletedTasks();
  Future<Task?> getTaskById(int id);
  Future<int> createTask(Task task);
  Future<void> updateTask(Task task);
  Future<void> deleteTask(int id);
  Future<void> toggleComplete(int id);
  Future<void> reorder(int fromIndex, int toIndex);
}
```

This is the **port** in ports-and-adapters terminology. Dart's `abstract interface class` is functionally identical to a Java `interface` — no implementation allowed, only signatures. The `abstract interface` modifier (introduced in Dart 3) bans both instantiation and implementation extension, the same way `interface` does in Java.

Note what's NOT here:

- No SQL.
- No Isar import.
- No JSON.
- No knowledge of "where data lives".

The domain dictates *what* you can do with tasks. The data layer chooses *how*. If we ever swap Isar for SQLite or a REST API, this interface stays.

Every method returns `Future<T>` — the Dart `CompletableFuture<T>`. Dart never blocks the UI thread, so DB calls are always async even when Isar can technically resolve them synchronously.

`createTask` returns `Future<int>` — the new Isar-assigned id. `reorder(fromIndex, toIndex)` takes two list positions, mirroring Flutter's `ReorderableListView` callback signature. This is a small leak of UI concerns into the domain port, but it's a pragmatic choice: encoding the same gesture as "list of new (id, sortOrder) pairs" would just push the index math up into the notifier with no benefit.

### Use cases

Each write operation has its own class. They're tiny and deliberately so. Take `CreateTaskUseCase`:

```dart
class CreateTaskUseCase {
  final TaskRepository _repository;
  const CreateTaskUseCase(this._repository);

  Future<int> call(Task task) async {
    if (task.title.trim().isEmpty) {
      throw const ValidationException('Task title cannot be empty');
    }
    return _repository.createTask(task);
  }
}
```

Three things to notice:

1. **`const` constructor.** Because the only field is `final` (the repository) and the body is trivial, Dart lets us mark the constructor `const`. This isn't a perf optimization that matters; it's a habit that signals "this class is a stateless function holder".
2. **`call` method.** Dart has a magic method `call` that lets any object be invoked like a function. So elsewhere in the codebase we write `CreateTaskUseCase(repo)(task)` — the second pair of parens hits `call`. It reads like a function reference. Java doesn't have this; the closest analogy is `Function.apply()` in Scala or implementing `Function<Task, Future<Integer>>` in Java 8+.
3. **Validation lives here.** Empty title is rejected before we touch the DB. This is where you'd add "title length max", "due date not in past for new tasks", etc. — the equivalent of `@Service` validation logic in Spring, distinct from `@Valid` bean validation (which would live closer to the entity).

The other use cases are simpler — they don't validate, they just delegate. Here's `ToggleCompleteUseCase`:

```dart
class ToggleCompleteUseCase {
  final TaskRepository _repository;
  const ToggleCompleteUseCase(this._repository);

  Future<void> call(int id) => _repository.toggleComplete(id);
}
```

The `=>` is shorthand for `{ return _repository.toggleComplete(id); }`. A common Spring developer reaction is "why even have a use case if it does nothing?" The answers are:

- **Stable seam for future validation.** When the product manager says "deleting a task with subtasks needs confirmation", you have one place to add the rule. No widget code changes.
- **Testability.** A unit test for `ToggleCompleteUseCase` is a one-liner mock. A unit test for "tap the checkbox in `TaskCard`" requires booting a widget tree.
- **Discoverability.** Listing the `use_cases/` directory tells a new developer exactly what business operations exist for tasks.

`ReorderTasksUseCase`, `UpdateTaskUseCase`, and `DeleteTaskUseCase` follow the same one-liner pattern.

---

## Layer 2 — Data

The data layer has three files:

1. `task_model.dart` — the Isar persistence model.
2. `task_local_datasource.dart` — the thin wrapper that owns Isar queries and write transactions.
3. `task_repository_impl.dart` — the implementation of `TaskRepository` that adapts models to entities.

### `data/models/task_model.dart`

```dart
import 'package:isar/isar.dart';
import '../../domain/entities/task.dart';

part 'task_model.g.dart';

@collection
class TaskModel {
  Id id = Isar.autoIncrement;

  late String title;
  String? note;
  bool isCompleted = false;

  // 0=low, 1=medium, 2=high — stored as int for Isar compatibility
  int priorityIndex = 1;

  @Index()
  DateTime? dueDate;

  @Index()
  int sortOrder = 0;
```

`@collection` is Isar's equivalent of `@Entity` in JPA — it tells the Isar codegen to treat this class as a storable schema. The `part 'task_model.g.dart';` line wires in the generated CRUD/query code. The `.g.dart` file is created by `build_runner` and is git-ignored except in this repo (check `.gitignore` to confirm). We skip reading it because it's mechanical.

Key differences from a JPA entity:

- **Fields are mutable.** Isar requires non-final fields. Compare to JPA where you also need mutable fields plus a no-args constructor. Domain code never sees this mutability — the `toEntity()` mapper produces an immutable `Task`.
- **`Id id = Isar.autoIncrement;`** is the equivalent of `@Id @GeneratedValue` in JPA. `Id` is just `int` with a typedef so the codegen can find it.
- **`late`** means "I will assign this before any read, trust me". It's a runtime promise — if you read before assigning, you get a `LateInitializationError`. Used here because `title`, `createdAt`, and `updatedAt` will be set by `fromEntity`, never by Isar from defaults.
- **`@Index()`** is Isar's compound-friendly index. Tasks are sorted by `sortOrder` constantly, so indexing it speeds up the `sortBySortOrder()` query.
- **`priorityIndex` is an int, not the enum.** Isar 3 doesn't support enums natively; we serialize via `Priority.values.indexOf(...)`.

```dart
  Task toEntity() => Task(
        id: id,
        title: title,
        note: note,
        isCompleted: isCompleted,
        priority: Priority.values[priorityIndex.clamp(0, 2)],
        dueDate: dueDate,
        sortOrder: sortOrder,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  static TaskModel fromEntity(Task task) => TaskModel()
    ..id = task.id
    ..title = task.title
    ..note = task.note
    ...
```

`toEntity` is `model -> domain`. `fromEntity` is `domain -> model`. The `.clamp(0, 2)` on `priorityIndex` is a defensive guard — if the stored int is somehow corrupted to 3, we fall back to high instead of crashing on an index-out-of-range.

The `..` cascade operator in `fromEntity` is Dart-specific. `TaskModel()..id = task.id..title = task.title` is equivalent to:

```java
TaskModel m = new TaskModel();
m.id = task.id;
m.title = task.title;
return m;
```

But chained, returning the receiver of the first `..`. Read it as "do these side effects on the freshly built object and return that object".

### `data/datasources/task_local_datasource.dart`

This is the thinnest possible wrapper around Isar — every public method is one query plus error translation. Spring developers can think of it as a custom `@Repository` whose role is to keep ORM-specific exceptions from leaking up.

```dart
class TaskLocalDatasource {
  final Isar _isar;
  TaskLocalDatasource(this._isar);

  Future<List<TaskModel>> getAllTasks() async {
    try {
      return _isar.taskModels.where().sortBySortOrder().findAll();
    } on IsarError catch (e) {
      throw DatabaseException('Failed to load tasks', cause: e);
    }
  }
```

Two things worth absorbing:

- **`_isar.taskModels`** is a generated accessor — Isar's codegen produces one per `@collection` class. `taskModels` is the inferred plural of `TaskModel`. It's the entry point to a typed query builder.
- **Error translation.** `IsarError` is caught and rethrown as our own `DatabaseException`. This is the same pattern as Spring's `@Repository` translating SQLExceptions into the unified DataAccessException hierarchy. The rest of the app handles one exception type, not the platform's.

```dart
  Future<List<TaskModel>> getActiveTasks() async {
    try {
      return _isar.taskModels
          .filter()
          .isCompletedEqualTo(false)
          .sortBySortOrder()
          .findAll();
    } on IsarError catch (e) {
      throw DatabaseException('Failed to load active tasks', cause: e);
    }
  }
```

The query builder is type-safe — `isCompletedEqualTo(false)` only exists because Isar's codegen saw `bool isCompleted` on the model. Misspell the field and the call won't compile. It's the same ergonomics as QueryDSL or jOOQ.

The completed query uses `.sortByUpdatedAtDesc()` instead — completed tasks are ordered by most-recently-checked-off, which is what users expect.

```dart
  Future<int> putTask(TaskModel model) async {
    try {
      return _isar.writeTxn(() => _isar.taskModels.put(model));
    } on IsarError catch (e) {
      throw DatabaseException('Failed to save task', cause: e);
    }
  }
```

`writeTxn` is Isar's transactional wrapper. Every write must be inside one — this is enforced at runtime. The closure passed in runs atomically; if it throws, the transaction rolls back. Reads don't need this wrapper.

`put` is Isar's upsert: if the model's `id` is `Isar.autoIncrement` (= 0), it inserts and returns the new id; if the id matches an existing row, it updates. This is why `TaskRepositoryImpl.updateTask` and `createTask` can both call the same `putTask` method.

```dart
  Future<void> reorderTasks(List<TaskModel> tasks) async {
    try {
      await _isar.writeTxn(() => _isar.taskModels.putAll(tasks));
    } on IsarError catch (e) {
      throw DatabaseException('Failed to reorder tasks', cause: e);
    }
  }
```

`putAll` is a bulk upsert in a single transaction. The repository above will assign new `sortOrder` values to every task in the active list and pass the whole list here — one transaction, no torn writes.

### `data/repositories/task_repository_impl.dart`

This is the adapter that implements the domain port. Read it as: every method translates between `TaskModel` (data) and `Task` (domain) and delegates the storage to the datasource.

```dart
class TaskRepositoryImpl implements TaskRepository {
  final TaskLocalDatasource _datasource;
  TaskRepositoryImpl(this._datasource);

  @override
  Future<List<Task>> getAllTasks() async {
    final models = await _datasource.getAllTasks();
    return models.map((m) => m.toEntity()).toList();
  }
```

`models.map(...)` returns a lazy `Iterable<Task>`; `.toList()` materializes it. Note `@override` — Dart enforces it when implementing an interface method, same as Java.

```dart
  @override
  Future<int> createTask(Task task) {
    final model = TaskModel.fromEntity(task);
    return _datasource.putTask(model);
  }

  @override
  Future<void> updateTask(Task task) async {
    final model = TaskModel.fromEntity(task);
    await _datasource.putTask(model);
  }
```

Both go through `fromEntity -> putTask`. The difference: `createTask` returns the `Future<int>` directly so the caller learns the new id, while `updateTask` discards it (the id was already known).

The interesting method is `toggleComplete`:

```dart
  @override
  Future<void> toggleComplete(int id) async {
    final model = await _datasource.getTaskById(id);
    if (model == null) return;
    model.isCompleted = !model.isCompleted;
    model.updatedAt = DateTime.now();
    await _datasource.putTask(model);
  }
```

We read, mutate the mutable model in memory, write. The domain never sees the mutation because the entity is reconstructed when next loaded. Spring developers will recognize this as the JPA "managed entity" pattern, except the "managed" status doesn't auto-flush — we explicitly `put` to persist.

Finally, `reorder`:

```dart
  @override
  Future<void> reorder(int fromIndex, int toIndex) async {
    final models = await _datasource.getActiveTasks();
    if (fromIndex < 0 || toIndex < 0 ||
        fromIndex >= models.length || toIndex >= models.length) {
      return;
    }

    final item = models.removeAt(fromIndex);
    models.insert(toIndex, item);

    final now = DateTime.now();
    for (int i = 0; i < models.length; i++) {
      models[i].sortOrder = i;
      models[i].updatedAt = now;
    }
    await _datasource.reorderTasks(models);
  }
```

The reorder algorithm is "rewrite all sortOrders":

1. Load every active task ordered by `sortOrder`.
2. Bounds-check the indices and silently bail on garbage input (safer than throwing — the UI might re-fire from a stale state).
3. Remove the dragged item from the list, then re-insert it at the destination index.
4. Walk the resulting list and reassign `sortOrder = i` for every task. This guarantees `sortOrder` stays a dense, monotonically increasing sequence starting at 0.
5. Bulk-write the whole list in one transaction.

Why rewrite *all* sortOrders instead of being clever with fractional indices? Because with at most a few dozen tasks per user, "bulk rewrite" is simpler, race-free, and impossible to corrupt. Fractional indices (Figma-style) only matter at high scale or with concurrent editors — neither applies here.

---

## Layer 3 — Presentation

The presentation layer has five files: one provider file (3 providers + 1 notifier), one screen file (with multiple internal widgets), and three widget files.

### `presentation/providers/tasks_provider.dart`

Three providers:

```dart
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final isar = ref.watch(isarProvider);
  final datasource = TaskLocalDatasource(isar);
  return TaskRepositoryImpl(datasource);
});

// Tab state: 0 = active, 1 = completed
final taskTabProvider = StateProvider<int>((ref) => 0);

final tasksProvider = AsyncNotifierProvider<TasksNotifier, List<Task>>(TasksNotifier.new);
```

Riverpod recap, mapped to Spring:

| Riverpod | Spring |
|---|---|
| `Provider<T>` | `@Bean` (singleton, immutable) |
| `StateProvider<T>` | stateful bean holding one value |
| `AsyncNotifierProvider` | `@Service` exposing observable state |
| `ref.watch(...)` | dependency injection that *also subscribes* the caller to rebuilds |
| `ref.read(...)` | one-shot fetch, no subscription |

`taskRepositoryProvider` is the wiring: pull in Isar (the singleton `Isar` instance is exposed by `isarProvider` in `core/database/`), wrap it in the datasource, wrap that in the repository impl. In Spring you'd let `@Autowired` do this; in Riverpod you assemble explicitly. The win: zero reflection, full compile-time type-safety, and trivial overriding in tests.

`taskTabProvider` is a one-int state holder — 0 means active tab, 1 means completed. It's read by the app bar (to highlight the chip) and by `TasksNotifier.build` (to choose which query to run). Changes to it trigger a rebuild of both consumers.

`tasksProvider` is the heavy hitter. `AsyncNotifierProvider` is the Riverpod construct for "a piece of async state plus methods to mutate it". It looks like this:

```dart
class TasksNotifier extends AsyncNotifier<List<Task>> {
  late TaskRepository _repository;

  @override
  Future<List<Task>> build() async {
    _repository = ref.watch(taskRepositoryProvider);
    final tab = ref.watch(taskTabProvider);
    return tab == 0 ? _repository.getActiveTasks() : _repository.getCompletedTasks();
  }
```

`build()` is the equivalent of `@PostConstruct` *plus* the source of truth for state. Riverpod calls it the first time anyone watches `tasksProvider`, and re-calls it whenever a dependency declared via `ref.watch` changes. So:

- The first time the screen mounts, `build()` runs, sees `tab == 0`, returns active tasks. State becomes `AsyncData(activeTasks)`.
- User taps the "Completed" chip, which calls `ref.read(taskTabProvider.notifier).state = 1`. That changes `taskTabProvider`. Because `build()` declared `ref.watch(taskTabProvider)`, Riverpod re-runs `build()`. While the new future is pending, state is `AsyncLoading` (technically a refresh, but UI sees `loading: ...` if it doesn't handle `previous`). When done, state becomes `AsyncData(completedTasks)`.

`_repository` is cached in an instance field so the methods below don't have to call `ref.read` every time. This is safe because if the repository provider itself changes (it never does in this app), `build()` re-runs and the field is reassigned.

Now the mutation methods. They share a pattern: **try the use case, log, then invalidate state**. Watch the structure of `create`:

```dart
  Future<void> create(Task task) async {
    try {
      final tasks = state.valueOrNull ?? [];
      final taskWithOrder = task.copyWith(sortOrder: tasks.length);
      await CreateTaskUseCase(_repository)(taskWithOrder);
      AppLogger.I.action('tasks', 'create',
          data: {'priority': task.priority.name, 'hasDue': task.dueDate != null});
      ref.invalidateSelf();
    } catch (e, s) {
      AppLogger.I.error('tasks', 'create failed', error: e, stack: s);
      rethrow;
    }
  }
```

Step by step:

1. `state.valueOrNull ?? []` — read the current list of tasks if available, else empty. New task's `sortOrder` is `tasks.length`, i.e., appended to the bottom.
2. `await CreateTaskUseCase(_repository)(taskWithOrder)` — that double-paren idiom again: build the use case, then invoke its `call` method.
3. Log a structured event via `AppLogger.I` (the singleton logger). The `action` log level is for user-initiated mutations. The `data` map is whatever structured payload you want indexed.
4. `ref.invalidateSelf()` — tells Riverpod "throw away my current state and re-run `build()`". The screen will reload from Isar.
5. If anything throws, log the error with full stack, then `rethrow`. Rethrow re-throws the original exception (preserving its stack) so the UI layer can show a toast/snackbar if it wants. The `catch (e, s)` syntax destructures the exception and stack trace — Dart's standard idiom.

The same shape repeats in `save` and `toggleComplete`. They all end with `ref.invalidateSelf()` because the simplest correct behavior is "re-read from DB".

`delete` is the exception:

```dart
  Future<void> delete(int id) async {
    try {
      await DeleteTaskUseCase(_repository)(id);
      AppLogger.I.action('tasks', 'delete', data: {'id': id});
      state = AsyncData(state.valueOrNull?.where((t) => t.id != id).toList() ?? []);
    } catch (e, s) {
      ...
      rethrow;
    }
  }
```

Instead of invalidating, it patches the in-memory list — drops the task with the matching id. Why? Because delete is the only operation where the new state is trivially derivable without a DB round-trip. Skipping the DB read avoids a UI flicker (loading spinner) on swipe-to-delete. The trade-off is: if anything else has changed in the DB concurrently, we won't pick it up. For a single-user local app, that's acceptable.

The real star is `reorder`:

```dart
  Future<void> reorder(int from, int to) async {
    final tasks = List<Task>.from(state.valueOrNull ?? []);
    if (from < 0 || to < 0 || from >= tasks.length || to >= tasks.length) return;
    final item = tasks.removeAt(from);
    tasks.insert(to, item);
    state = AsyncData(tasks);
    try {
      await ReorderTasksUseCase(_repository)(from, to);
      AppLogger.I.action('tasks', 'reorder', data: {'from': from, 'to': to});
    } catch (e, s) {
      AppLogger.I.error('tasks', 'reorder failed',
          error: e, stack: s, data: {'from': from, 'to': to});
      ref.invalidateSelf();
      rethrow;
    }
  }
```

This is **optimistic UI** done right. Walk it:

1. **Snapshot the current list.** `List<Task>.from(...)` creates a fresh, mutable copy. We need mutable because we'll splice in place; we need fresh so we don't accidentally mutate the immutable list Riverpod is exposing.
2. **Bounds check, bail silently.** Same as the repository — defensive coding against stale gesture events.
3. **Splice locally.** Remove the dragged task, re-insert at the destination.
4. **Optimistically commit to state.** `state = AsyncData(tasks)`. The UI rebuilds *immediately* with the new order — no waiting for Isar. This is what makes drag feel responsive.
5. **Then** call the use case. The DB write happens in the background.
6. **If the DB write fails, revert.** `ref.invalidateSelf()` discards the optimistic state and re-runs `build()`, which pulls the *actual* (pre-drag) state from Isar. The user sees the drag snap back, plus we rethrow so a snackbar can show.

Compare to a Spring REST controller doing optimistic UI: you'd return the new state immediately, queue the DB write to a separate thread, and rollback on the client if it fails. Same idea, but Riverpod gives you `state = ...` as a one-liner instead of needing WebSockets or a polling endpoint.

The phrase **"reorder revert via `invalidateSelf`"** in this chapter's outline points at this: invalidation is our rollback mechanism. There's no separate undo state; we trust Isar to be the source of truth and reload from it whenever something goes wrong.

### `presentation/screens/tasks_screen.dart`

The screen file is ~300 lines and has four internal widgets:

- `TasksScreen` — the public widget; just picks phone vs tablet layout.
- `_TasksPhoneLayout` — `Scaffold` with app bar (with tab chips), `_TasksList` body, FAB.
- `_TasksTabletLayout` — `Row` of two `Scaffold`s side by side (active | completed).
- `_TasksAppBar` + `_TabChip` — header with chips that drive `taskTabProvider`.
- `_TasksList` — the actual list, which is either a `ListView.builder` (completed) or a `ReorderableListView.builder` (active).

The root entry point:

```dart
class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= _kTabletBreakpoint;

    return isTablet ? const _TasksTabletLayout() : const _TasksPhoneLayout();
  }
}
```

`MediaQuery.of(context).size.width` returns the logical pixel width. The breakpoint `600.0` is the same one Material uses internally for "compact" vs "medium" windows.

Two layouts, one feature. This pattern — `isTablet ? Tablet() : Phone()` — is the Flutter equivalent of CSS media queries. The two layout widgets are entirely independent classes; they don't share a base class. That's idiomatic Flutter: composition over inheritance, and "branch once at the root, then keep the trees clean".

The phone layout:

```dart
class _TasksPhoneLayout extends StatelessWidget {
  const _TasksPhoneLayout();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgPrimary,
      appBar: const _TasksAppBar(showTabBar: true),
      body: const _TasksList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(context),
        backgroundColor: kAccentPurple,
        child: const Icon(Iconsax.add, color: Colors.white),
      ),
    );
  }
}
```

`Scaffold` is Material's page chrome — it gives you slots for app bar, body, FAB, drawer, bottom nav, etc. Read it like an HTML template: every slot is optional.

The FAB calls `_showAddSheet`, a top-level helper (defined at the bottom of the file) that pops up the task editor bottom sheet.

The tablet layout splits the screen with a `Row`:

```dart
class _TasksTabletLayout extends StatelessWidget {
  const _TasksTabletLayout();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgPrimary,
      body: SafeArea(
        child: Row(
          children: [
            // Left panel — Active
            Expanded(
              child: Scaffold(
                ...
                body: const _TasksList(forceTab: 0),
              ),
            ),
            Container(width: 1, color: kGlassBorder),
            // Right panel — Completed
            Expanded(
              child: Scaffold(
                ...
                body: const _TasksList(forceTab: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

Two `Expanded` children inside a `Row` means "split the row 50/50". The thin `Container` with `width: 1` is a vertical divider. Each panel is its own `Scaffold` so it gets its own app bar.

Notice `_TasksList(forceTab: 0)` and `_TasksList(forceTab: 1)`. The `forceTab` parameter exists specifically for the tablet case — both lists show simultaneously, so we can't drive them off the single `taskTabProvider`. The list checks: "if `forceTab` is set, use it and filter locally; otherwise read from the provider".

The app bar with tab chips:

```dart
class _TasksAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final bool showTabBar;
  const _TasksAppBar({this.showTabBar = false});

  @override
  Size get preferredSize =>
      Size.fromHeight(showTabBar ? kAppBarHeight + 48 : kAppBarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(taskTabProvider);
    return AppBar(
      ...
      bottom: showTabBar
          ? PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Padding(
                ...
                child: Row(
                  children: [
                    _TabChip(label: 'Active', index: 0, currentTab: currentTab),
                    const SizedBox(width: kSpaceSM),
                    _TabChip(label: 'Completed', index: 1, currentTab: currentTab),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}
```

`PreferredSizeWidget` is Flutter's "I have a fixed height even though I'm a widget" contract. Required because `Scaffold.appBar` expects a known height for layout. `preferredSize` returns the height; the rest is just composition.

The chips themselves:

```dart
class _TabChip extends ConsumerWidget {
  ...
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = index == currentTab;
    return GestureDetector(
      onTap: () => ref.read(taskTabProvider.notifier).state = index,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        ...
      ),
    );
  }
}
```

`ref.read(taskTabProvider.notifier).state = index` is the canonical Riverpod write to a `StateProvider`. `.notifier` gets the controller; `.state = ...` sets the value. This triggers everything watching `taskTabProvider` to rebuild — including `TasksNotifier.build()`, which re-runs and fetches the new list.

`AnimatedContainer` is Flutter's "tween me automatically" container. Any property that changes (color, padding, border radius) is interpolated over the given duration. Replaces the equivalent of CSS transitions.

The list:

```dart
class _TasksList extends ConsumerWidget {
  final int? forceTab;
  const _TasksList({this.forceTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int tab = forceTab ?? ref.watch(taskTabProvider);
    final tasksAsync = ref.watch(tasksProvider);

    return tasksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: kAccentPurple)),
      error: (err, stack) {
        AppLogger.I.error('tasks', 'load failed', error: err, stack: stack);
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              '$kError\n${err.toString()}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: kTextSecondary),
            ),
          ),
        );
      },
      data: (allTasks) {
        ...
      },
    );
  }
```

`AsyncValue<T>.when(loading:, error:, data:)` is the idiomatic three-state pattern matcher. Same idea as a Spring controller dealing with `Mono<T>` and switching on success/error/empty.

Inside the `data:` branch:

```dart
      data: (allTasks) {
        final tasks = forceTab == null
            ? allTasks
            : allTasks.where((t) => forceTab == 0 ? !t.isCompleted : t.isCompleted).toList();

        if (tasks.isEmpty) return _buildEmpty(tab);

        if (tab == 1 || forceTab == 1) {
          return ListView.builder(
            ...
            itemBuilder: (_, i) => TaskCard(
              task: tasks[i],
              onTap: () => _showEditSheet(context, tasks[i]),
            ),
          );
        }

        // Active tasks — drag-to-reorder
        return ReorderableListView.builder(
          ...
          onReorderItem: (from, to) {
            ref.read(tasksProvider.notifier).reorder(from, to);
          },
          proxyDecorator: (child, index, animation) => Material(
            color: Colors.transparent,
            child: child,
          ),
          itemBuilder: (_, i) => TaskCard(
            key: ValueKey(tasks[i].id),
            task: tasks[i],
            onTap: () => _showEditSheet(context, tasks[i]),
          ),
        );
      },
```

Flow:

1. If `forceTab` is set (tablet case), filter the in-memory list by completion. Otherwise the provider has already filtered.
2. Empty list -> friendly empty-state widget.
3. Completed tab uses a plain `ListView.builder` — no reorder, no drag handles.
4. Active tab uses `ReorderableListView.builder`, the magic Flutter widget that handles long-press-and-drag for free.

About `ReorderableListView`:

- `onReorderItem: (from, to) => ...` fires when the user lifts their finger after a drag. `from` is the original index, `to` is the new index. We pass straight through to the notifier.
- `proxyDecorator` controls how the dragged item looks while in flight. The default wraps it in an opaque `Material` which clashes with our dark glass theme; we override with a transparent `Material` so the drop shadow remains but the card stays visually consistent.
- `key: ValueKey(tasks[i].id)` on the item is **required**. Flutter needs a stable identity per row to animate the drag without re-creating widgets. Without keys, the framework would think you'd just swapped two anonymous list slots, losing animation continuity and possibly desyncing internal state inside `TaskCard` (gesture controllers, `Slidable` state, etc.).

The empty state is a centered icon + text:

```dart
  Widget _buildEmpty(int tab) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            tab == 0 ? Iconsax.task_square : Iconsax.tick_circle,
            size: 64,
            color: kTextHint,
          ),
          ...
        ],
      ),
    );
  }
```

`mainAxisSize: MainAxisSize.min` says "be as tall as my children require, no more". Without it, a `Column` inside a `Center` would expand vertically.

Finally, the two helper top-level functions:

```dart
void _showAddSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const TaskBottomSheet(),
  );
}

void _showEditSheet(BuildContext context, Task task) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => TaskBottomSheet(existing: task),
  );
}
```

`showModalBottomSheet` is Flutter's built-in modal that slides up from the bottom. `isScrollControlled: true` allows the sheet to take more than half the screen — needed because we have a keyboard above the title input. `backgroundColor: Colors.transparent` lets the sheet draw its own rounded corners and dark fill.

`builder: (_) => TaskBottomSheet(existing: task)` reuses the same sheet widget for both create and edit — `existing` being `null` flips it into create mode.

### `presentation/widgets/task_card.dart`

The single row in the task list. Combines:

- A `Slidable` outer wrapper for swipe-to-delete.
- A checkbox tap target for completion.
- The title + note + priority + due date column.
- A drag handle icon (only when not completed).

```dart
class TaskCard extends ConsumerWidget {
  final Task task;
  final VoidCallback? onTap;

  const TaskCard({super.key, required this.task, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Slidable(
      key: ValueKey(task.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => ref.read(tasksProvider.notifier).delete(task.id),
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
            icon: Iconsax.trash,
            label: 'Delete',
            ...
          ),
        ],
      ),
```

`Slidable` is from the `flutter_slidable` package — swipe-to-reveal-actions, like iOS Mail. The `endActionPane` shows actions on left-swipe (in LTR locales). One action: delete, which calls `ref.read(tasksProvider.notifier).delete(task.id)`. Notice we use `ref.read` here — we don't want this card to rebuild every time the task list changes; we only call into the notifier on user action.

The checkbox:

```dart
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  ref.read(tasksProvider.notifier).toggleComplete(task.id);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: task.isCompleted ? kAccentPurple : Colors.transparent,
                    border: Border.all(
                      color: task.isCompleted ? kAccentPurple : kTextHint,
                      width: 1.5,
                    ),
                  ),
                  child: task.isCompleted
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
              ),
```

`HapticFeedback.mediumImpact()` triggers the OS haptic engine — a small buzz when the user toggles a task. The `AnimatedContainer` is the same trick as before: when `task.isCompleted` flips, the container's color, border, and child all change, and Flutter animates them over 200ms.

The body column has the title, optional note, and metadata row. The title styling uses a conditional `decoration: task.isCompleted ? TextDecoration.lineThrough : null` — strikethrough completed tasks.

```dart
                    Row(
                      children: [
                        PriorityBadge(priority: task.priority),
                        if (task.dueDate != null) ...[
                          const SizedBox(width: kSpaceSM),
                          Icon(
                            Iconsax.calendar_1,
                            size: 11,
                            color: task.isOverdue ? const Color(0xFFEF4444) : kTextHint,
                          ),
                          ...
                          Text(
                            du.formatDate(task.dueDate!),
                            style: TextStyle(
                              color: task.isOverdue ? const Color(0xFFEF4444) : kTextHint,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
```

Two Dart syntax features in tight sequence:

- `if (task.dueDate != null) ...[ ... ]` — **collection-if** plus the **spread operator**. The whole bracketed group is conditionally included in the parent `Row`'s children. Equivalent to `someList.addAll(...)` after a conditional check, but inline. There's no Java equivalent that's nearly as clean.
- `task.dueDate!` — null-assertion to unwrap the nullable for `formatDate`. Safe because of the `if` guard.

The drag handle:

```dart
              if (!task.isCompleted)
                const Icon(Icons.drag_handle, color: kTextHint, size: kIconMD),
```

Only shown for active tasks. The icon is purely visual — `ReorderableListView` makes the entire row draggable by long-press, but the icon tells the user "you can drag this".

### `presentation/widgets/task_bottom_sheet.dart`

The form. Used for both create (when `existing == null`) and edit. It's a `ConsumerStatefulWidget` because it needs local state for the text controllers, the selected priority, and the picked due date.

```dart
class _TaskBottomSheetState extends ConsumerState<TaskBottomSheet> {
  late TextEditingController _titleCtrl;
  late TextEditingController _noteCtrl;
  Priority _priority = Priority.medium;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    _titleCtrl = TextEditingController(text: t?.title ?? '');
    _noteCtrl = TextEditingController(text: t?.note ?? '');
    if (t != null) {
      _priority = t.priority;
      _dueDate = t.dueDate;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }
```

Lifecycle 101:

- `initState` runs once when the state object is created (the sheet appears). We seed the text controllers from the existing task if editing, or empty strings if creating.
- `dispose` runs when the sheet is dismissed. We must dispose the text controllers — they own native input streams and leak memory if not released. Flutter's analyzer warns you if you forget.

In Spring terms, this is `@PostConstruct` and `@PreDestroy` on a session-scoped bean. The framework is strict about both ends.

The date picker:

```dart
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: kAccentPurple,
            surface: kBgSecondary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }
```

`showDatePicker` is built-in. It returns `Future<DateTime?>` — null if the user cancelled. The `builder` parameter lets us inject a theme override so the calendar matches our purple/dark aesthetic instead of the default material blue.

`setState(() => _dueDate = picked)` is the StatefulWidget mutation trigger. The closure runs synchronously; afterward Flutter re-runs `build` for this state object only.

The save handler:

```dart
  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;

    final now = DateTime.now();
    if (widget.existing == null) {
      await ref.read(tasksProvider.notifier).create(Task(
            id: 0,
            title: title,
            note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
            priority: _priority,
            dueDate: _dueDate,
            createdAt: now,
            updatedAt: now,
          ));
    } else {
      await ref.read(tasksProvider.notifier).save(widget.existing!.copyWith(
            title: title,
            ...
            updatedAt: now,
          ));
    }
    if (mounted) Navigator.pop(context);
  }
```

Two branches: create with a fresh `Task(id: 0, ...)` (Isar will assign the id during put), or update via `copyWith` on the existing task. After the async write finishes, `Navigator.pop(context)` dismisses the bottom sheet.

`if (mounted)` — this is critical. Between `await` and the next line, the user could have backed out of the sheet, in which case the state object is unmounted and accessing `context` would throw. The `mounted` flag is true while the widget is in the tree.

The body of the sheet is a `Column` with:

- A small drag handle bar at top.
- A title input (autofocused on create).
- A note input.
- A row of three priority chips and a "Due date" pill.
- A primary "Add Task" / "Save Changes" button.

The priority chips are built by mapping over the enum:

```dart
                  children: Priority.values.map((p) {
                    final isSelected = _priority == p;
                    final color = switch (p) {
                      Priority.high => const Color(0xFFEF4444),
                      Priority.medium => kAccentOrange,
                      Priority.low => kAccentGreen,
                    };
                    final label = switch (p) {
                      Priority.high => 'High',
                      Priority.medium => 'Med',
                      Priority.low => 'Low',
                    };
                    return Padding(
                      ...
                      child: GestureDetector(
                        onTap: () => setState(() => _priority = p),
                        child: AnimatedContainer(
                          ...
                        ),
                      ),
                    );
                  }).toList(),
```

Two interesting bits:

- **Dart 3 switch expressions.** `switch (p) { Priority.high => ..., ... }` is an expression, not a statement, like Kotlin's `when` or Java 17's switch expressions. The compiler verifies exhaustiveness.
- **State-only chip selection.** `setState(() => _priority = p)` updates local state. The task isn't actually written until the user taps Save. This keeps the form's state ephemeral and decoupled from the provider.

### `presentation/widgets/priority_badge.dart`

The smallest file in the feature — a self-contained presentational widget. Two parameters: the priority enum value, and a `compact` flag for the badge variant.

```dart
class PriorityBadge extends StatelessWidget {
  final Priority priority;
  final bool compact;

  const PriorityBadge({super.key, required this.priority, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? kSpaceXS : kSpaceSM,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: _color.withAlpha(30),
        borderRadius: BorderRadius.circular(kRadiusRound),
        border: Border.all(color: _color.withAlpha(80), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: _color, shape: BoxShape.circle)),
          if (!compact) ...[
            const SizedBox(width: 4),
            Text(_label, style: TextStyle(color: _color, fontSize: 10, fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }

  Color get _color => switch (priority) {
        Priority.high => const Color(0xFFEF4444),
        Priority.medium => kAccentOrange,
        Priority.low => kAccentGreen,
      };
```

Two computed getters at the bottom (`_color`, `_label`) hide the priority-to-style mapping. Note `_color` uses the same switch-expression pattern as the bottom sheet — duplication, yes, but it's intentional: each widget owns its own color logic, and the badge has a faint background (`withAlpha(30)`) while the bottom sheet has a filled-when-selected style. Centralizing them would mean parameterizing a "colorFor(Priority)" helper, which isn't worth the abstraction for two callers.

Compact mode (used in dense list contexts) hides the label and just shows the colored dot. Non-compact (the default, used in `TaskCard`) shows dot + label.

This widget has zero Riverpod, zero state, zero side effects. It's a pure function of its inputs. The Java analog would be a Thymeleaf fragment that takes a model and renders a span — except this one is type-checked end-to-end.

---

## Trace: drag a task to reorder it

This is where the layered architecture pays off. Let's walk through exactly what happens when the user long-presses a task and drops it three positions down. Suppose the active list has 5 tasks `[A, B, C, D, E]` with `sortOrder = [0, 1, 2, 3, 4]`, and the user drags `A` to where `D` was.

### Step 1 — Gesture detection (Flutter framework)

`ReorderableListView.builder` is internally listening to long-press + drag gestures on each child. The user's long-press triggers the drag start; the framework lifts the row visually using the `proxyDecorator` we configured, leaves a placeholder where the row was, and animates other rows to make space as the finger moves.

No app code runs during the drag itself — Flutter handles all the visual feedback. Our code only runs when the finger lifts.

### Step 2 — `onReorderItem` callback fires

```dart
onReorderItem: (from, to) {
  ref.read(tasksProvider.notifier).reorder(from, to);
},
```

`from = 0`, `to = 3` (the indices in the displayed list, both zero-based). `ref.read` grabs the `TasksNotifier` instance from Riverpod without subscribing — we don't want this callback to rebuild on every state change; it just delegates.

### Step 3 — `TasksNotifier.reorder` runs

```dart
Future<void> reorder(int from, int to) async {
  final tasks = List<Task>.from(state.valueOrNull ?? []);
  if (from < 0 || to < 0 || from >= tasks.length || to >= tasks.length) return;
  final item = tasks.removeAt(from);
  tasks.insert(to, item);
  state = AsyncData(tasks);
  ...
}
```

- Snapshots the current immutable list as a mutable copy: `[A, B, C, D, E]`.
- Bounds check: `0 <= 0 < 5` and `0 <= 3 < 5`, both fine.
- `tasks.removeAt(0)` returns `A` and shortens the list to `[B, C, D, E]`.
- `tasks.insert(3, A)` makes it `[B, C, D, A, E]`.
- `state = AsyncData([B, C, D, A, E])` — **optimistic update**.

### Step 4 — Riverpod broadcasts the new state

Every widget that called `ref.watch(tasksProvider)` is marked for rebuild. In this screen that's `_TasksList`. Flutter schedules a frame.

### Step 5 — Frame rebuild

The `ReorderableListView.builder` is reconstructed with the new list `[B, C, D, A, E]`. Because each `TaskCard` has `key: ValueKey(tasks[i].id)`, Flutter recognizes that:

- The row with key `A` moved from position 0 to position 3.
- B, C, D, E shifted but kept their identities.

Flutter animates the rows into their new positions using its built-in implicit animations. From the user's perspective, the drop happens smoothly and the list immediately reflects the new order. **No DB round-trip has happened yet.**

### Step 6 — Use case runs (async, behind the scenes)

Back in `TasksNotifier.reorder`, the next line awaits the use case:

```dart
try {
  await ReorderTasksUseCase(_repository)(from, to);
  AppLogger.I.action('tasks', 'reorder', data: {'from': from, 'to': to});
} catch (e, s) {
  ...
}
```

`ReorderTasksUseCase.call(0, 3)` is one line: `_repository.reorder(0, 3)`.

### Step 7 — Repository reorder

`TaskRepositoryImpl.reorder(0, 3)`:

```dart
final models = await _datasource.getActiveTasks();
// models = [A(sortOrder=0), B(1), C(2), D(3), E(4)]
if (fromIndex < 0 || ... ) return;
final item = models.removeAt(0);   // item = A
models.insert(3, item);            // [B, C, D, A, E]
final now = DateTime.now();
for (int i = 0; i < models.length; i++) {
  models[i].sortOrder = i;         // B=0, C=1, D=2, A=3, E=4
  models[i].updatedAt = now;
}
await _datasource.reorderTasks(models);
```

Note the repository **reloads from the DB** rather than trusting the indices to map to current state — this protects against the case where the active task list has changed since the gesture started (e.g., a sync from another device, though we don't have that yet). Concretely it asks Isar for the canonical ordered list and applies the splice to that.

Every model gets its `sortOrder` rewritten to its new index. This is the densification step that keeps `sortOrder` clean.

### Step 8 — Datasource transactional write

```dart
Future<void> reorderTasks(List<TaskModel> tasks) async {
  try {
    await _isar.writeTxn(() => _isar.taskModels.putAll(tasks));
  } on IsarError catch (e) {
    throw DatabaseException('Failed to reorder tasks', cause: e);
  }
}
```

One transaction, five upserts. Either all five new sort orders persist or none do. If Isar throws (disk full, schema mismatch), it's translated to `DatabaseException` and bubbles up.

### Step 9a — Happy path

The transaction commits. Control returns up the call chain. `TasksNotifier.reorder` logs the success and finishes. The optimistic state we set in Step 3 is now confirmed by disk.

The user sees nothing happen at this point because the UI already matches the DB. The whole DB write took maybe 10-30 ms on flash storage but the user never waited for it.

### Step 9b — Sad path (the revert)

Suppose Isar throws (unlikely but possible). The catch block fires:

```dart
} catch (e, s) {
  AppLogger.I.error('tasks', 'reorder failed',
      error: e, stack: s, data: {'from': from, 'to': to});
  ref.invalidateSelf();
  rethrow;
}
```

- Log structured error with the gesture's `from`/`to`.
- `ref.invalidateSelf()` discards the optimistic state and re-runs `TasksNotifier.build()`.
- `build()` calls `_repository.getActiveTasks()`, which returns the **pre-drag** order `[A, B, C, D, E]` because the write transaction rolled back.
- Riverpod broadcasts; the list rebuilds; the row snaps back to its original position.
- `rethrow` propagates the exception. A higher-level handler (toast/snackbar) can react if it wants.

This is the "reorder revert via `invalidateSelf`" pattern referenced earlier. The simplicity is the win: there's no per-method undo stack, no manual state shadowing, just "trust Isar and reload".

### Step 10 — Logging

Win or lose, `AppLogger.I` writes a structured event:

- On success: `{"feature": "tasks", "event": "reorder", "data": {"from": 0, "to": 3}}` at info level.
- On failure: same plus error stack at error level.

These logs accumulate in the app's local log file (see `core/services/app_logger.dart`) and can be exported via the diagnostics screen later.

---

That's the full slice. Recap the boundaries one more time:

- **Domain** (`Task`, `TaskRepository`, use cases) — knows nothing about Isar or Flutter. Could be lifted into any Dart project.
- **Data** (`TaskModel`, `TaskLocalDatasource`, `TaskRepositoryImpl`) — knows everything about Isar, hides it. Translates exceptions.
- **Presentation** (`tasksProvider`, `TasksScreen`, `TaskCard`, `TaskBottomSheet`, `PriorityBadge`) — knows only domain entities and use cases. Treats the repository as a black box.
- **Riverpod** wires the layers together and handles state propagation. `ref.watch` is the subscription mechanism; `ref.invalidateSelf` is the rollback.

If you're coming from Spring, the closest analogy is a `@RestController` that calls a `@Service` that calls a `@Repository`. The differences:

- Flutter doesn't have classpath scanning; we wire providers manually in `tasks_provider.dart`.
- State is observable by default — `AsyncNotifier` is to a `@Service` what a server-sent event stream would be to a REST endpoint.
- Optimistic UI is a one-liner (`state = ...`) instead of a WebSocket dance.

The next chapter walks through a different feature with a slightly different shape, and points out where the pattern bends.
