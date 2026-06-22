# 05 — Screen: Reminders

The reminders feature lets a user create a titled note tied to a future `DateTime`, optionally recurring, and have the OS fire a notification at that moment. It is the cleanest end-to-end vertical slice in the app: a single screen, a single entity, three use cases, an Isar collection, and a tight integration with `NotificationService`. If you understand this chapter, every other feature (tasks, journal, habits) is just a variation on the same layered shape.

This walkthrough follows the Clean Architecture layout you saw in chapter 00: `domain` (pure Dart, no Flutter), `data` (Isar + mapping), `presentation` (Riverpod + widgets). Think of it as `service` / `repository` / `controller` in a Spring service, except the controller is also the view because Flutter has no HTTP boundary here.

---

## File map

| Layer        | Path                                                                                                | Role                                                              |
|--------------|-----------------------------------------------------------------------------------------------------|-------------------------------------------------------------------|
| Domain       | `features/reminders/domain/entities/reminder.dart`                                                  | Immutable POJO-style entity, no framework deps                    |
| Domain       | `features/reminders/domain/repositories/reminder_repository.dart`                                   | Repository interface (Spring-style port)                          |
| Domain       | `features/reminders/domain/use_cases/create_reminder_use_case.dart`                                 | Validation + persist + schedule notification                      |
| Domain       | `features/reminders/domain/use_cases/delete_reminder_use_case.dart`                                 | Cancel notification + delete row                                  |
| Domain       | `features/reminders/domain/use_cases/snooze_reminder_use_case.dart`                                 | Push reminder forward, reschedule with try/catch                  |
| Data         | `features/reminders/data/models/reminder_model.dart`                                                | Isar `@collection` entity + `toEntity`/`fromEntity` mappers       |
| Data         | `features/reminders/data/datasources/reminder_local_datasource.dart`                                | Thin wrapper around Isar queries, wraps `IsarError`                |
| Data         | `features/reminders/data/repositories/reminder_repository_impl.dart`                                | Implements the domain port, maps models <-> entities              |
| Presentation | `features/reminders/presentation/providers/reminders_provider.dart`                                 | Riverpod `AsyncNotifier`, exposes CRUD + snooze to widgets        |
| Presentation | `features/reminders/presentation/screens/reminders_screen.dart`                                     | `ConsumerWidget` list + bottom-sheet add form                     |

The generated file `reminder_model.g.dart` is produced by `build_runner` and intentionally skipped here — treat it like a JPA-generated metamodel class.

---

## Layer 1 — Domain

The domain layer in this feature has zero imports from `package:flutter`, `package:isar`, or `package:flutter_riverpod`. It depends only on `core/services/notification_service.dart` (an abstract Dart class), `core/services/app_logger.dart`, and `core/errors/app_exceptions.dart`. If you yanked this folder into a pure-Dart server project, it would still compile. That is the litmus test for "clean".

### Entity: `Reminder`

```dart
enum RecurringInterval { none, daily, weekly, monthly }

class Reminder {
  final int id;
  final String title;
  final String? note;
  final DateTime reminderAt;
  final RecurringInterval recurring;
  final bool isTriggered;
  final DateTime createdAt;

  const Reminder({
    required this.id,
    required this.title,
    this.note,
    required this.reminderAt,
    this.recurring = RecurringInterval.none,
    this.isTriggered = false,
    required this.createdAt,
  });
```

Spring analogue: a Java record or a Lombok `@Value` class. Every field is `final`, the constructor is `const` (compile-time constant when args are constant), and mutation only happens through `copyWith`.

```dart
  Reminder copyWith({
    int? id,
    String? title,
    String? note,
    DateTime? reminderAt,
    RecurringInterval? recurring,
    bool? isTriggered,
    DateTime? createdAt,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      ...
    );
  }
```

`copyWith` is the Dart idiom for "give me a new instance with these fields overridden". Each parameter is nullable so the caller can omit it; the `??` operator means "if null, use the current value". This is the equivalent of `toBuilder()` in Lombok or the `with` keyword on Java records.

```dart
  bool get isUpcoming => !isTriggered && reminderAt.isAfter(DateTime.now());
  bool get isPast => reminderAt.isBefore(DateTime.now()) && !isTriggered;
}
```

`get` declares a computed property — read-only, no parameters, syntactically just a field. Used by `_ReminderCard` in the screen to colour past-due reminders red. Note this entity has no `id == 0 means new` ceremony, but in practice the screen passes `id: 0` to `create` and Isar's `autoIncrement` overwrites it (we'll see this when we get to the data layer).

### Repository interface

```dart
abstract interface class ReminderRepository {
  Future<List<Reminder>> getAllReminders();
  Future<List<Reminder>> getUpcomingReminders();
  Future<Reminder?> getReminderById(int id);
  Future<int> createReminder(Reminder reminder);
  Future<void> updateReminder(Reminder reminder);
  Future<void> deleteReminder(int id);
  Future<void> markTriggered(int id);
  Future<void> snooze(int id, Duration duration);
}
```

`abstract interface class` is a Dart 3 modifier combo that means "this class can only be implemented, never extended or constructed". Same purpose as a Java `interface` — you cannot accidentally inherit state, only a contract.

This is the Spring-style port. The use cases below depend on this abstraction; the `data` layer provides the adapter. Notice it returns domain `Reminder` objects, not `ReminderModel` — the data layer is responsible for unwrapping Isar models before they leak upward. The repository has no opinion about Isar, SharedPreferences, or HTTP; it could be swapped for a fake in tests without touching the use cases.

Every method returns a `Future` because Isar writes are async. `markTriggered` is exposed for the notification-tap handler (chapter 02) to call when the user dismisses the notification.

### Use case: `CreateReminderUseCase`

A use case in this codebase is a single-method class with one job. The convention is to name the method `call`, which lets Dart treat the class as a callable — `useCase(reminder)` instead of `useCase.execute(reminder)`. Spring devs: think of it as a `@Service` bean with one public method, except DI is explicit through the constructor and there is no proxy magic.

```dart
class CreateReminderUseCase {
  final ReminderRepository _repository;
  final NotificationService _notifications;
  const CreateReminderUseCase(this._repository, this._notifications);

  Future<int> call(Reminder reminder) async {
    if (reminder.title.trim().isEmpty) {
      throw const ValidationException('Reminder title cannot be empty');
    }
    if (reminder.reminderAt.isBefore(DateTime.now())) {
      throw const ValidationException('Reminder time must be in the future');
    }
    final id = await _repository.createReminder(reminder);
    await _notifications.scheduleReminder(
      id: id,
      title: reminder.title,
      body: reminder.note,
      scheduledAt: reminder.reminderAt,
    );
    return id;
  }
}
```

What is happening:

1. Validate domain invariants. `ValidationException` is a custom subclass from `core/errors/app_exceptions.dart`; it bubbles up to the bottom sheet which catches it and shows a `SnackBar`.
2. Persist via the repository. Isar returns the auto-incremented `int` id.
3. Hand that id to `NotificationService.scheduleReminder` so the notification id matches the reminder id one-to-one. This matters because cancellation, snooze rescheduling, and tap-routing all key on the same int.

Spring analogue: `@Transactional public int create(Reminder r)` that also publishes a domain event to the scheduler. The two operations are not actually transactional here — if the notification schedule fails after the DB write, the reminder still exists in Isar. In practice `NotificationService` is a thin wrapper around `flutter_local_notifications` and failures are rare, but be aware: if you ever see "reminder saved but no notification fired" in the wild, this is the seam.

### Use case: `DeleteReminderUseCase`

```dart
class DeleteReminderUseCase {
  final ReminderRepository _repository;
  final NotificationService _notifications;
  const DeleteReminderUseCase(this._repository, this._notifications);

  Future<void> call(int id) async {
    await _notifications.cancel(id);
    await _repository.deleteReminder(id);
  }
}
```

The order matters: cancel the scheduled OS notification first, then delete the row. If the OS-side cancel fails (e.g. permission revoked), the await throws and the DB row survives — better than the inverse, where you'd leave an orphan notification pointing at a non-existent reminder. There is no try/catch here because the caller (the notifier) is fine with the exception propagating.

### Use case: `SnoozeReminderUseCase`

This is the most interesting one because it is the only use case in the feature that wraps notification scheduling in a try/catch and logs when state is unexpected.

```dart
class SnoozeReminderUseCase {
  final ReminderRepository _repository;
  final NotificationService _notifications;
  const SnoozeReminderUseCase(this._repository, this._notifications);

  Future<void> call(int id, {Duration duration = const Duration(minutes: 10)}) async {
    await _repository.snooze(id, duration);
    final reminder = await _repository.getReminderById(id);
    if (reminder == null) {
      AppLogger.I.warn('reminder', 'snooze: reminder missing after snooze write',
          data: {'id': id});
      return;
    }
```

Step by step:

1. `_repository.snooze(id, duration)` mutates the row: pushes `reminderAt` forward by `duration` (default 10 minutes) and resets `isTriggered = false`.
2. Re-read the row to get the fresh `reminderAt`. If somebody deleted the row between the two awaits (the Dart event loop is single-threaded but `await` yields), `getReminderById` returns `null`.
3. The `null` branch is the defensive `warn` — not an error because it can happen legitimately, but worth a structured log entry. `AppLogger.I` is the singleton logger covered in chapter 02; the `data` map is structured context that ends up in the in-app log viewer.

```dart
    AppLogger.I.action('reminder', 'snooze',
        data: {'id': id, 'minutes': duration.inMinutes});
    try {
      await _notifications.scheduleReminder(
        id: id,
        title: reminder.title,
        body: reminder.note,
        scheduledAt: reminder.reminderAt,
      );
    } catch (e, s) {
      AppLogger.I.error('reminder', 'snooze scheduleReminder failed',
          error: e, stack: s, data: {'id': id});
      rethrow;
    }
  }
}
```

The try/catch only wraps the OS-side schedule call. The intent: if scheduling fails (a permission was revoked mid-session, a platform channel error, an exact-alarm denial on Android 12+), log it with stack trace, then re-throw so the UI can surface the failure. The DB write already succeeded, so the user's data is safe; we just lose the OS-side reminder until the next edit.

Two log levels here are deliberate:

- `action` for the happy path — fire-and-forget observability for what the user did.
- `error` with `error:` and `stack:` for the catch — captured stack frames so the in-app log viewer can show where it blew up.

The `warn` for the missing-reminder case is the third level. Spring devs: think SLF4J's `INFO`/`WARN`/`ERROR` — the discipline is the same, just less ceremony.

---

## Layer 2 — Data

The data layer's job is to translate between Isar's mutable, annotated model class and the domain's immutable entity. It also catches Isar-specific errors and rewraps them as the app's `DatabaseException` so the upper layers never import `package:isar`.

### Model: `ReminderModel`

```dart
import 'package:isar/isar.dart';
import '../../domain/entities/reminder.dart';

part 'reminder_model.g.dart';

@collection
class ReminderModel {
  Id id = Isar.autoIncrement;

  late String title;
  String? note;

  @Index()
  late DateTime reminderAt;

  // 0=none, 1=daily, 2=weekly, 3=monthly
  int recurringIndex = 0;

  bool isTriggered = false;
  late DateTime createdAt;
```

A few Dart/Isar-isms:

- `part 'reminder_model.g.dart'` pulls in the generated file as if its contents were declared inline in this file. The generated code contains the binary serializer, query builders (`isar.reminderModels.filter()...`), and the type adapter Isar's runtime needs. You never edit it; `dart run build_runner build` regenerates it.
- `@collection` is the Isar equivalent of JPA's `@Entity`. The class becomes a table in the on-device file.
- `Id id = Isar.autoIncrement` — `Id` is just `typedef Id = int`; the value `Isar.autoIncrement` is the sentinel "give me a new id on write". JPA analogue: `@GeneratedValue(strategy = IDENTITY)`.
- `late` means "I promise to assign before first read; do not require an initial value at declaration". Useful for non-nullable fields that Isar will hydrate during deserialization.
- `@Index()` on `reminderAt` is the standard "index this column" hint, used by `getUpcomingReminders`.
- `recurringIndex` stores the enum as an `int`. Isar supports enums natively, but storing the index is migration-safe — if the enum gets a new value later, old rows still deserialize. The comment in the source documents the mapping.

The mappers:

```dart
  Reminder toEntity() => Reminder(
        id: id,
        title: title,
        note: note,
        reminderAt: reminderAt,
        recurring: RecurringInterval.values[recurringIndex.clamp(0, 3)],
        isTriggered: isTriggered,
        createdAt: createdAt,
      );

  static ReminderModel fromEntity(Reminder r) => ReminderModel()
    ..id = r.id
    ..title = r.title
    ..note = r.note
    ..reminderAt = r.reminderAt
    ..recurringIndex = r.recurring.index
    ..isTriggered = r.isTriggered
    ..createdAt = r.createdAt;
}
```

`toEntity` is the inbound (DB -> domain) direction. The `clamp(0, 3)` on `recurringIndex` is defensive — if a corrupted row has `recurringIndex = 99`, you'd get a `RangeError` indexing into the enum's `values` list, so we pin it to a valid range. `none` is the implicit default.

`fromEntity` uses Dart's cascade operator `..`. Each `..field = value` returns the receiver, so you can chain mutations on the freshly-constructed `ReminderModel()`. Equivalent to a Java builder where every setter returns `this`. Note `id = r.id` — when the entity has `id: 0` (i.e. a brand new reminder from the bottom sheet), Isar treats `0` as "assign next auto-increment". Existing reminders carry their real id through.

### Datasource: `ReminderLocalDatasource`

```dart
class ReminderLocalDatasource {
  final Isar _isar;
  ReminderLocalDatasource(this._isar);

  Future<List<ReminderModel>> getAllReminders() async {
    try {
      return _isar.reminderModels.where().sortByReminderAt().findAll();
    } on IsarError catch (e) {
      throw DatabaseException('Failed to load reminders', cause: e);
    }
  }
```

This is a thin layer on top of Isar's query API. `_isar.reminderModels` is the generated accessor for the `ReminderModel` collection — added to `IsarCollections` by build_runner. `.where()` opens a query, `.sortByReminderAt()` is a generated sort method (one is produced per indexed/non-indexed field), and `.findAll()` executes and returns `Future<List<ReminderModel>>`.

The `on IsarError catch (e)` is Dart's typed catch. It only fires for `IsarError` and subclasses; anything else (e.g. an `OutOfMemoryError`) propagates untouched. The wrapping into `DatabaseException` keeps the upper layers framework-agnostic — the use cases catch only domain-level exceptions.

```dart
  Future<List<ReminderModel>> getUpcomingReminders() async {
    try {
      return _isar.reminderModels
          .filter()
          .isTriggeredEqualTo(false)
          .reminderAtGreaterThan(DateTime.now())
          .sortByReminderAt()
          .findAll();
    } on IsarError catch (e) {
      throw DatabaseException('Failed to load upcoming reminders', cause: e);
    }
  }
```

The fluent query builder is fully generated. `isTriggeredEqualTo` and `reminderAtGreaterThan` come from the generated code because the model has fields named `isTriggered` (bool) and `reminderAt` (DateTime). Spring JPA's Querydsl is the closest analogue — strongly typed predicates built from field metadata. If you rename a field, you also have to regenerate.

```dart
  Future<int> putReminder(ReminderModel model) async {
    try {
      return _isar.writeTxn(() => _isar.reminderModels.put(model));
    } on IsarError catch (e) {
      throw DatabaseException('Failed to save reminder', cause: e);
    }
  }

  Future<void> deleteReminder(int id) async {
    try {
      await _isar.writeTxn(() => _isar.reminderModels.delete(id));
    } on IsarError catch (e) {
      throw DatabaseException('Failed to delete reminder', cause: e);
    }
  }
}
```

All writes go through `_isar.writeTxn(...)`. This is a single-writer transaction — Isar serializes writes through one queue. It is the closest equivalent to wrapping a method in `@Transactional` on Spring. `put` is upsert: insert if id is `autoIncrement` or new, update otherwise.

### Repository implementation

```dart
class ReminderRepositoryImpl implements ReminderRepository {
  final ReminderLocalDatasource _datasource;
  ReminderRepositoryImpl(this._datasource);

  @override
  Future<List<Reminder>> getAllReminders() async {
    final models = await _datasource.getAllReminders();
    return models.map((m) => m.toEntity()).toList();
  }
```

`implements` is the Dart keyword you'd use when you want to satisfy an interface contract without inheriting its implementation. For our `abstract interface class`, it's the only legal option.

Each method delegates to the datasource and then maps `ReminderModel` to `Reminder`. `models.map(...)` returns an `Iterable`; `.toList()` materialises it — `Iterable` in Dart is lazy, similar to a Java `Stream` before `collect(...)`.

```dart
  @override
  Future<int> createReminder(Reminder reminder) {
    return _datasource.putReminder(ReminderModel.fromEntity(reminder));
  }

  @override
  Future<void> updateReminder(Reminder reminder) async {
    await _datasource.putReminder(ReminderModel.fromEntity(reminder));
  }
```

Both create and update funnel through `putReminder` (Isar's upsert). The difference is purely semantic at this layer — `create` returns the new id, `update` discards it.

```dart
  @override
  Future<void> markTriggered(int id) async {
    final model = await _datasource.getReminderById(id);
    if (model == null) return;
    model.isTriggered = true;
    await _datasource.putReminder(model);
  }

  @override
  Future<void> snooze(int id, Duration duration) async {
    final model = await _datasource.getReminderById(id);
    if (model == null) return;
    model.reminderAt = DateTime.now().add(duration);
    model.isTriggered = false;
    await _datasource.putReminder(model);
  }
}
```

Both follow a load-mutate-save pattern. `model == null` means the row vanished — in the snooze case the use case will pick this up and log a `warn`. Note that `snooze` always anchors the new `reminderAt` to `DateTime.now() + duration` rather than `existing.reminderAt + duration`; that's intentional: if a notification fires at 9am and the user snoozes at 9:05am, they want it back at 9:15am, not 9:10am.

---

## Layer 3 — Presentation

Two files: the Riverpod notifier (state + commands) and the screen (widgets + form).

### Providers

```dart
final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return ReminderRepositoryImpl(ReminderLocalDatasource(isar));
});

final remindersProvider =
    AsyncNotifierProvider<RemindersNotifier, List<Reminder>>(RemindersNotifier.new);
```

Two providers wired into Riverpod's container (chapter 00 covered Riverpod basics):

- `reminderRepositoryProvider` is a plain `Provider<T>`. It watches `isarProvider` from `core/database/database_provider.dart` and builds the repository on demand. If `isarProvider` ever rebuilds (e.g. test override), this rebuilds too — Spring's `@RefreshScope` is the closest analogue, but in Riverpod it's the default.
- `remindersProvider` is an `AsyncNotifierProvider`. The notifier exposes both state (`AsyncValue<List<Reminder>>`) and methods (`create`, `delete`, `snooze`, `edit`). `AsyncNotifier` is built for async-initialised state where you also want command methods.

```dart
class RemindersNotifier extends AsyncNotifier<List<Reminder>> {
  late ReminderRepository _repository;
  late NotificationService _notifications;

  @override
  Future<List<Reminder>> build() async {
    _repository = ref.watch(reminderRepositoryProvider);
    _notifications = ref.watch(notificationServiceProvider);
    return _repository.getAllReminders();
  }
```

`build()` is the async initializer. Riverpod calls it once on first read, awaits its `Future`, and stores the result in `state` as `AsyncData(list)`. While the future is pending, `state` is `AsyncLoading()`; if it throws, `AsyncError(e, st)`. This is the three-state model the screen consumes via `when(loading:, error:, data:)`.

`ref.watch` inside `build` sets up reactive dependencies — if `isarProvider` invalidates, this notifier rebuilds. The `late` fields are populated here so the command methods below can use them without re-reading `ref`.

```dart
  Future<void> create(Reminder reminder) async {
    await CreateReminderUseCase(_repository, _notifications)(reminder);
    ref.invalidateSelf();
  }

  Future<void> delete(int id) async {
    await DeleteReminderUseCase(_repository, _notifications)(id);
    state = AsyncData(state.valueOrNull?.where((r) => r.id != id).toList() ?? []);
  }
```

Two patterns for state refresh, both valid:

- `create` and `snooze` use `ref.invalidateSelf()`, which throws away the current state and re-runs `build()`. Net effect: another `getAllReminders()` query against Isar. Simple, always correct, but a tiny bit wasteful — the new row will be visible after the next disk read.
- `delete` mutates state in place by filtering out the deleted id. No disk round-trip. This is fine because the delete is idempotent and we already know the new list locally.

Spring analogue: invalidating a `@Cacheable` region vs. evicting a single key. Pick based on how cheap the re-read is.

```dart
  Future<void> snooze(int id) async {
    await SnoozeReminderUseCase(_repository, _notifications)(id);
    ref.invalidateSelf();
  }

  Future<void> edit(Reminder reminder) async {
    await _notifications.cancel(reminder.id);
    await _repository.updateReminder(reminder);
    await _notifications.scheduleReminder(
      id: reminder.id,
      title: reminder.title,
      body: reminder.note,
      scheduledAt: reminder.reminderAt,
    );
    ref.invalidateSelf();
  }
}
```

`edit` is inlined here rather than extracted into a use case. It mirrors the "cancel-then-reschedule" pattern from delete + create. If this grew validation logic (e.g. don't allow editing past reminders), it'd be lifted into an `UpdateReminderUseCase`. Right now the calling screen has no edit UI, so the method is wired but unused — keep an eye out for that when reading the codebase, it's not dead code, just unbuilt UI.

Note that `create`, `delete`, `snooze` go through use case classes that get constructed on every invocation. That's intentional and cheap — use cases are stateless, hold only references, and there's no reflection or proxy cost. Spring would put `@Service` on them and inject; Riverpod treats them as plain objects.

### Screen: `RemindersScreen`

The screen is a `ConsumerWidget` — Riverpod's read-only widget base. It has a `build(BuildContext, WidgetRef)` instead of just `build(BuildContext)`, where `ref` is your container handle.

```dart
class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(remindersProvider);
    return Scaffold(
      backgroundColor: kBgPrimary,
      appBar: AppBar(
        backgroundColor: kBgPrimary,
        elevation: 0,
        title: const Text(kNavReminders, ...),
      ),
      body: remindersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(...)),
        error: (_, __) => const Center(child: Text(kError, ...)),
        data: (reminders) { ... },
      ),
```

`ref.watch(remindersProvider)` subscribes this widget to the provider — when state changes, `build` reruns. The returned type is `AsyncValue<List<Reminder>>` and `.when(...)` is the exhaustive pattern-match: loading, error, data. This is the canonical Riverpod screen shape. Spring/JS equivalents: React Query's `{ isLoading, error, data }` triplet.

The empty-state branch:

```dart
        data: (reminders) {
          if (reminders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Iconsax.notification, size: 64, color: kTextHint),
                  SizedBox(height: kSpaceMD),
                  Text('No reminders yet.\nTap + to add one.',
                       textAlign: TextAlign.center, ...),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(...),
            itemCount: reminders.length,
            itemBuilder: (_, i) => _ReminderCard(reminder: reminders[i]),
          );
        },
      ),
```

`ListView.builder` is the lazy list — only the visible items get built. It's the same idea as a `RecyclerView` on Android or a virtualised list in React.

The FAB:

```dart
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showReminderSheet(context),
        backgroundColor: kAccentPurple,
        child: const Icon(Iconsax.add, color: Colors.white),
      ),
    );
  }
}
```

`_showReminderSheet` is a top-level helper that opens a modal bottom sheet wrapping `_AddReminderSheet` (the form).

#### The reminder card

`_ReminderCard` is also a `ConsumerWidget` because the swipe actions call into `remindersProvider.notifier`. The interesting bits:

```dart
class _ReminderCard extends ConsumerWidget {
  final Reminder reminder;
  const _ReminderCard({required this.reminder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPast = reminder.isPast;
    final isTriggered = reminder.isTriggered;
    ...
```

`isPast` and `isTriggered` drive the visual state: a red border for past-due, a struck-through title for fired, the accent purple for upcoming. Then the snooze button:

```dart
              if (!isTriggered)
                GestureDetector(
                  onTap: () => ref.read(remindersProvider.notifier).snooze(reminder.id),
                  child: Container(
                    ...
                    child: const Text(
                      '+10m',
                      style: TextStyle(color: kAccentBlue, fontSize: 11, ...),
                    ),
                  ),
                ),
```

`ref.read(...)` (not `watch`) is used inside callbacks. `read` does a one-shot lookup without subscribing — the snooze action doesn't want to rebuild when state changes, it just wants to fire the method. The `.notifier` property gives you the `RemindersNotifier` instance instead of its state.

The delete confirmation:

```dart
  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        ...
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', ...)),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(remindersProvider.notifier).delete(reminder.id);
            },
            child: Text('Delete', style: TextStyle(color: Colors.red.shade400)),
          ),
        ],
      ),
    );
  }
```

`showDialog` pushes a route onto the navigator. The `Navigator.pop(ctx)` closes the dialog before calling `delete`, so the UI feels snappy: the dialog disappears, then the row removal animates as state changes.

#### The add sheet

`_AddReminderSheet` is a `ConsumerStatefulWidget` — like `ConsumerWidget` but with mutable local state for the form controllers. Two `TextEditingController`s, two pickers (`DateTime?` and `TimeOfDay?`), and a `RecurringInterval`:

```dart
class _AddReminderSheetState extends ConsumerState<_AddReminderSheet> {
  final _titleCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  RecurringInterval _recurring = RecurringInterval.none;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }
```

`dispose` is the lifecycle hook — disposing controllers is mandatory or you leak the underlying ChangeNotifier. Same idea as releasing an `EditText` listener in Android.

Save flow:

```dart
  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a date and time')),
      );
      return;
    }

    final at = DateTime(
      _selectedDate!.year, _selectedDate!.month, _selectedDate!.day,
      _selectedTime!.hour, _selectedTime!.minute,
    );

    if (at.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a future time')),
      );
      return;
    }
```

UI-level validation happens here for fast feedback. Note the same "future time" check exists in `CreateReminderUseCase` as `ValidationException` — that's intentional defense in depth: the use case is the canonical guard, the UI is just being polite.

```dart
    try {
      await ref.read(remindersProvider.notifier).create(Reminder(
            id: 0,
            title: _titleCtrl.text.trim(),
            note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
            reminderAt: at,
            recurring: _recurring,
            createdAt: DateTime.now(),
          ));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }
```

`id: 0` is the "new row" sentinel — the data layer translates that into Isar's auto-increment. `mounted` is the `State`-class flag that becomes false after dispose; checking it before calling `Navigator.pop` or `ScaffoldMessenger.of(context)` prevents "called setState on disposed widget" errors when the user has navigated away mid-await.

The catch swallows any exception (validation or otherwise) and shows it as a snackbar. That's where `ValidationException` messages from the use case end up.

---

## How reminders integrate with NotificationService

Chapter 02 covered `NotificationService` in detail; here's the contract this feature depends on:

```dart
// core/services/notification_service.dart (abstract)
Future<void> scheduleReminder({
  required int id,
  required String title,
  String? body,
  required DateTime scheduledAt,
});
Future<void> cancel(int id);
```

Key invariants the reminders feature relies on:

1. **Id namespace is shared with Isar.** `scheduleReminder(id: 42, ...)` and `cancel(42)` operate on the same OS notification slot that corresponds to `ReminderModel(id: 42)`. Because Isar returns the id from `put`, we pass it directly to `scheduleReminder` — no separate notification id, no mapping table.
2. **`cancel` is idempotent.** `DeleteReminderUseCase` always calls it before deleting the row, even if the reminder already fired and the notification slot is empty.
3. **`scheduleReminder` schedules an exact alarm.** On Android 12+ this requires the `SCHEDULE_EXACT_ALARM` permission; the app requests it during onboarding. If revoked, the snooze use case's try/catch will log an error and re-throw, which the screen turns into a snackbar.
4. **Tap routing back into the app calls `repository.markTriggered(id)`.** That's set up in `NotificationService.init` via the `onDidReceiveNotificationResponse` handler — see chapter 02. The reminder feature provides `markTriggered` on the repository specifically for that callback to use without going through the notifier.

The fact that this feature only touches the abstract `NotificationService` (never `flutter_local_notifications` directly) is why the domain layer stays portable. If you swapped in `awesome_notifications` or a custom platform channel implementation, the use cases would not change.

---

## Trace: create a reminder and snooze it

Putting it all together, here's the timeline from FAB tap to notification fire.

**Step 1 — User taps FAB.**

`FloatingActionButton.onPressed` invokes `_showReminderSheet(context)`. `showModalBottomSheet` pushes `_AddReminderSheet` onto the navigator stack. The user types "Standup", picks tomorrow 9:00am, leaves recurring as `none`, and taps "Set Reminder".

**Step 2 — `_save` runs.**

UI validation passes. The composed `DateTime at` is in the future. The sheet calls:

```dart
await ref.read(remindersProvider.notifier).create(Reminder(
  id: 0, title: 'Standup', note: null,
  reminderAt: at, recurring: RecurringInterval.none,
  createdAt: DateTime.now(),
));
```

**Step 3 — `RemindersNotifier.create` dispatches to the use case.**

```dart
await CreateReminderUseCase(_repository, _notifications)(reminder);
ref.invalidateSelf();
```

A throwaway `CreateReminderUseCase` is instantiated with the cached `_repository` and `_notifications` refs, then invoked as a function via its `call` method.

**Step 4 — Use case validates, persists, schedules.**

Title isn't empty, `reminderAt` is after now. `_repository.createReminder(reminder)` -> `_datasource.putReminder(ReminderModel.fromEntity(reminder))` -> `_isar.writeTxn(() => _isar.reminderModels.put(model))`. Isar assigns id `42` (let's say). The use case then calls `_notifications.scheduleReminder(id: 42, title: 'Standup', body: null, scheduledAt: at)`. The OS now holds a pending exact alarm for id `42`.

**Step 5 — Notifier invalidates.**

`ref.invalidateSelf()` causes `build()` to re-run. It calls `_repository.getAllReminders()` -> `_datasource.getAllReminders()` -> `_isar.reminderModels.where().sortByReminderAt().findAll()`. The list now contains the new row. Riverpod publishes `AsyncData(newList)`.

**Step 6 — Screen rebuilds.**

`ref.watch(remindersProvider)` in `RemindersScreen.build` fires a rebuild. `remindersAsync.when` falls into `data:`, the empty-state branch is bypassed, and `ListView.builder` paints a `_ReminderCard` for the new reminder. The bottom sheet closes from the `Navigator.pop(context)` in `_save`.

**Step 7 — User taps the `+10m` snooze chip.**

In `_ReminderCard`, the `GestureDetector` calls `ref.read(remindersProvider.notifier).snooze(42)`.

**Step 8 — `RemindersNotifier.snooze` dispatches.**

```dart
await SnoozeReminderUseCase(_repository, _notifications)(42);
ref.invalidateSelf();
```

**Step 9 — Snooze use case runs.**

1. `_repository.snooze(42, Duration(minutes: 10))` -> repo loads the model, sets `reminderAt = DateTime.now() + 10m`, sets `isTriggered = false`, puts it back.
2. `_repository.getReminderById(42)` returns the freshly-updated `Reminder`. (If the row were missing, the warn path logs and returns early.)
3. `AppLogger.I.action('reminder', 'snooze', data: {'id': 42, 'minutes': 10})` records the user action.
4. Inside try/catch: `_notifications.scheduleReminder(id: 42, title: 'Standup', body: null, scheduledAt: <now+10m>)`. The OS-level scheduler replaces the existing pending alarm for id `42` with the new one (replacement-by-id is part of the `flutter_local_notifications` contract).
5. If scheduling throws (permission revoked, platform-channel error), `AppLogger.I.error` captures the failure with stack and re-throws. The notifier's await propagates the exception up — currently uncaught at the card level, so it surfaces as a Riverpod error state on the next watch.

**Step 10 — Notifier invalidates, screen rebuilds.**

`build()` re-runs, fetches the list again (now with `reminderAt` shifted ten minutes later), the card's `isPast` getter returns false again, the red border disappears.

**Step 11 — Ten minutes later, the OS fires the notification.**

`flutter_local_notifications` invokes the registered tap callback in `NotificationService`. That handler calls `ReminderRepository.markTriggered(42)` (via its own provider lookup), which loads the model, sets `isTriggered = true`, and writes it back. The next time the reminders screen is opened, `ref.watch(remindersProvider)` reads the updated row and renders the card in its struck-through "triggered" state.

That's the full loop: widget -> provider -> use case -> repository -> Isar; and in parallel, use case -> NotificationService -> OS -> callback -> repository. Every layer talks only to the layer immediately below it (or to a clearly-defined cross-cutting service), which is what makes this slice testable: swap the repository in tests with a fake, swap `NotificationService` with a recorder, drive the notifier from a `ProviderContainer`, assert on emitted state.
