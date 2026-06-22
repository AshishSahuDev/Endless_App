# 06 — Screen: Alarms

This chapter walks through the **Alarms** feature end-to-end: the user picks a
time, optionally a repeat pattern and a sound, and the app rings at that time
even if the phone is locked. Unlike Reminders (chapter 05) which merely shows a
notification banner you can swipe away, an alarm **plays audio** through the
`AlarmService` (covered in chapter 02) and behaves like a real clock alarm —
full-screen activity, wake-lock, sound asset.

The data path is identical to Reminders (Isar local DB, Clean Architecture
layers, Riverpod `AsyncNotifierProvider`), so this chapter focuses on the
delta: how scheduling and stopping audio is woven into every mutation.

## File map

| Layer | File | Role | Spring analogy |
|-------|------|------|----------------|
| Domain | `domain/entities/alarm_entity.dart` | Pure POJO, immutable, no framework imports | `@Entity` POJO without JPA annotations |
| Domain | `domain/repositories/alarm_repository.dart` | Abstract contract for persistence | `interface AlarmRepository` (Spring Data style) |
| Domain | `domain/use_cases/create_alarm_use_case.dart` | Persist + schedule audio | `@Service` method `createAlarm()` |
| Domain | `domain/use_cases/delete_alarm_use_case.dart` | Stop audio + delete row | `@Service` method `deleteAlarm()` |
| Domain | `domain/use_cases/toggle_alarm_use_case.dart` | Flip enabled flag + (re)schedule or stop | `@Service` method `toggleAlarm()` |
| Data | `data/models/alarm_model.dart` | Isar-annotated row + mapping to entity | `@Entity` JPA class + mapper |
| Data | `data/datasources/alarm_local_datasource.dart` | Raw DB calls, wraps Isar errors | `JpaRepository` impl wrapping `EntityManager` |
| Data | `data/repositories/alarm_repository_impl.dart` | Implements domain contract via datasource | Concrete `AlarmRepositoryImpl` bean |
| Presentation | `presentation/providers/alarms_provider.dart` | Riverpod `AsyncNotifier`, the UI's state holder | `@RestController` + reactive `Flux<List<Alarm>>` |
| Presentation | `presentation/screens/alarms_screen.dart` | The widget tree the user sees | Thymeleaf template / React page |

The data flow on a mutation:

```
AlarmsScreen (widget)
   -> ref.read(alarmsProvider.notifier).create(alarm)
       -> CreateAlarmUseCase(repo, alarmService)(alarm)
           -> repo.createAlarm(alarm)
               -> AlarmLocalDatasource.putAlarm(model)
                   -> Isar.writeTxn(...)
           -> alarmService.scheduleAlarm(created)   <-- native plugin
       -> ref.invalidateSelf() (triggers rebuild)
```

---

## Layer 1 — Domain

The domain layer holds the **pure business shape** of an alarm and the
operations the app can perform on one. It has zero imports from Flutter, Isar,
or any other framework — exactly like a Spring `domain` package that depends
only on `java.time` and your own classes.

### `alarm_entity.dart` — the entity

```dart
class AlarmEntity {
  final int id;
  final String label;
  final int hour;
  final int minute;
  final bool isEnabled;
  // Repeat bitmask: bit 0 = Mon, bit 1 = Tue ... bit 6 = Sun. 0 = once only.
  final int repeatDays;
  final String soundAsset;
  final DateTime createdAt;

  const AlarmEntity({
    required this.id,
    this.label = '',
    required this.hour,
    required this.minute,
    this.isEnabled = true,
    this.repeatDays = 0,
    this.soundAsset = 'assets/sounds/alarm_default.mp3',
    required this.createdAt,
  });
```

Every field is `final`, the constructor is `const` — this is an **immutable
value object**, the Dart equivalent of a Java `record`. You never mutate an
`AlarmEntity` in place; if you want a different value, you call `copyWith`:

```dart
AlarmEntity copyWith({
  int? id,
  String? label,
  int? hour,
  int? minute,
  bool? isEnabled,
  int? repeatDays,
  String? soundAsset,
  DateTime? createdAt,
}) {
  return AlarmEntity(
    id: id ?? this.id,
    label: label ?? this.label,
    ...
  );
}
```

The pattern `id ?? this.id` is Dart's null-coalescing operator: if the caller
passed `null` (or omitted the field), keep the current value. This is how
`CreateAlarmUseCase` stamps the freshly-generated database id onto the entity
without mutating it.

Two computed getters live on the entity to keep formatting logic out of the
widget tree:

```dart
String get timeString {
  final h = hour % 12 == 0 ? 12 : hour % 12;
  final m = minute.toString().padLeft(2, '0');
  final period = hour < 12 ? 'AM' : 'PM';
  return '$h:$m $period';
}

String get repeatLabel {
  if (repeatDays == 0) return 'Once';
  if (repeatDays == 0x7F) return 'Every day';
  if (repeatDays == 0x1F) return 'Weekdays';
  if (repeatDays == 0x60) return 'Weekends';
  const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  final active = <String>[];
  for (int i = 0; i < 7; i++) {
    if (repeatDays & (1 << i) != 0) active.add(days[i]);
  }
  return active.join(' · ');
}
```

`repeatDays` is a 7-bit bitmask stored as an `int` — bit 0 = Monday, bit 6 =
Sunday. `0x7F` (binary `1111111`) means every day is on; `0x1F` (`0011111`) =
Mon-Fri; `0x60` (`1100000`) = Sat-Sun. Storing seven booleans in one
column is a tiny win in Isar, but the real reason is that it makes the
scheduling math trivial later — the `AlarmService` can iterate
`for (i in 0..6) if (mask & (1<<i)) scheduleFor(weekday=i+1)`.

In Spring you'd probably do this with a `Set<DayOfWeek>` and a custom converter
to a `TINYINT` column; the bitmask saves a join table.

### `alarm_repository.dart` — the contract

```dart
import '../entities/alarm_entity.dart';

abstract interface class AlarmRepository {
  Future<List<AlarmEntity>> getAllAlarms();
  Future<AlarmEntity?> getAlarmById(int id);
  Future<int> createAlarm(AlarmEntity alarm);
  Future<void> updateAlarm(AlarmEntity alarm);
  Future<void> deleteAlarm(int id);
  Future<void> toggleEnabled(int id);
}
```

`abstract interface class` is Dart 3 syntax for "interface only, no mixing
in" — exactly a Java `interface`. The use cases depend on this type, never on
the concrete `AlarmRepositoryImpl` from the data layer. That dependency-flip is
why we can swap Isar for SQLite (or an in-memory fake in tests) without
touching domain code, just like wiring a mock `JpaRepository` in a Spring unit
test.

Note `createAlarm` returns `Future<int>`: Isar autogenerates ids on insert and
hands the new id back. The use case will then call `copyWith(id: ...)` to stamp
it onto the entity before scheduling.

### Use case: `create_alarm_use_case.dart`

```dart
class CreateAlarmUseCase {
  final AlarmRepository _repository;
  final AlarmService _alarmService;
  const CreateAlarmUseCase(this._repository, this._alarmService);

  Future<int> call(AlarmEntity alarm) async {
    final id = await _repository.createAlarm(alarm);
    final created = alarm.copyWith(id: id);
    AppLogger.I.action('alarm', 'create',
        data: {'id': id, 'hour': alarm.hour, 'minute': alarm.minute, 'enabled': alarm.isEnabled});
    if (created.isEnabled) {
      try {
        await _alarmService.scheduleAlarm(created);
      } catch (e, s) {
        AppLogger.I.error('alarm', 'scheduleAlarm failed',
            error: e, stack: s, data: {'id': id});
        rethrow;
      }
    }
    return id;
  }
}
```

A few things worth pointing out:

1. **Two dependencies**, both injected via the constructor — repository (DB)
   and `AlarmService` (native scheduling/audio). Constructor injection, same
   as Spring `@RequiredArgsConstructor`.
2. **`call` operator**: declaring a method named `call` lets you invoke the
   instance like a function — `CreateAlarmUseCase(...)(alarm)` instead of
   `.execute(alarm)`. It's the Dart equivalent of Java's `Function<T,R>`. The
   provider layer takes advantage of this on line 34 of
   `alarms_provider.dart`.
3. **Persist first, schedule second**: the row goes into Isar before the
   native alarm is registered. If scheduling fails we still have a record in
   the DB.
4. **`scheduleAlarm` is wrapped in `try/catch`** — the native plugin can throw
   on weird Android OEMs (Xiaomi battery savers, missing exact-alarm
   permission), so we log with full context and `rethrow` so the UI layer can
   show an error. The DB row stays — the user can disable and re-enable to
   retry, or our background recovery code can rescheduling on next launch.
5. The structured `AppLogger` call (`AppLogger.I.action(...)`) is the project's
   audit trail, equivalent to a Spring AOP `@Loggable` aspect.

### Use case: `delete_alarm_use_case.dart`

```dart
class DeleteAlarmUseCase {
  final AlarmRepository _repository;
  final AlarmService _alarmService;
  const DeleteAlarmUseCase(this._repository, this._alarmService);

  Future<void> call(int id) async {
    await _alarmService.stopAlarm(id);
    await _repository.deleteAlarm(id);
  }
}
```

Order matters in reverse: **stop the native alarm first**, then delete the
row. If we deleted the row first and `stopAlarm` failed, we'd be left with a
zombie alarm that fires with no DB record to look it up — the worst possible
state. Stop-first means even if the DB delete fails, the user isn't woken up.

This use case does **not** wrap `stopAlarm` in `try/catch` — a deletion is
user-initiated and rare; if the native side throws we'd rather propagate so
the provider sees an `AsyncError` and can show a snackbar.

### Use case: `toggle_alarm_use_case.dart`

```dart
class ToggleAlarmUseCase {
  final AlarmRepository _repository;
  final AlarmService _alarmService;
  const ToggleAlarmUseCase(this._repository, this._alarmService);

  Future<void> call(int id) async {
    await _repository.toggleEnabled(id);
    final alarm = await _repository.getAlarmById(id);
    if (alarm == null) return;
    if (alarm.isEnabled) {
      await _alarmService.scheduleAlarm(alarm);
    } else {
      await _alarmService.stopAlarm(id);
    }
  }
}
```

Toggle is read-modify-write at the DB layer (`toggleEnabled` flips the boolean
inside a write transaction), then a fresh read to find out which side of the
toggle we landed on, then a single side-effecting call to the native service.
The `if (alarm == null) return;` is defensive: another tab could have deleted
the row between the toggle and the read. In Spring you might do this in a
single `@Transactional` method that returns the new state.

---

## Layer 2 — Data

### `alarm_model.dart` — Isar's view of an alarm

```dart
import 'package:isar/isar.dart';
import '../../domain/entities/alarm_entity.dart';

part 'alarm_model.g.dart';

@collection
class AlarmModel {
  Id id = Isar.autoIncrement;

  late String label;
  late int hour;
  late int minute;
  bool isEnabled = true;
  int repeatDays = 0;
  String soundAsset = 'assets/sounds/alarm_default.mp3';
  late DateTime createdAt;
```

This is the **persistence model**, deliberately separate from `AlarmEntity`.

- `@collection` is Isar's `@Entity` — code generation hits this class to build
  type adapters and indexes; the generated code lives in `alarm_model.g.dart`,
  declared with `part 'alarm_model.g.dart';` (Dart's `part`/`part of` mechanism
  is how generated code joins the same library without an explicit import).
- `Id id = Isar.autoIncrement;` — `Id` is Isar's alias for `int` plus a hint
  that this is the primary key. `Isar.autoIncrement` is a sentinel value that
  tells Isar "assign me one on insert".
- `late` means "non-nullable but I'll set it before first read" — it's how you
  avoid having to give a meaningless default to required fields. If you try
  to read a `late` field before assigning it, you get a `LateInitializationError`
  at runtime. Spring uses `@NotNull` annotations + Bean Validation for the
  same purpose at a different layer.

Two static-ish mappers convert between persistence and domain shapes:

```dart
AlarmEntity toEntity() => AlarmEntity(
      id: id,
      label: label,
      hour: hour,
      minute: minute,
      isEnabled: isEnabled,
      repeatDays: repeatDays,
      soundAsset: soundAsset,
      createdAt: createdAt,
    );

static AlarmModel fromEntity(AlarmEntity a) => AlarmModel()
  ..id = a.id
  ..label = a.label
  ..hour = a.hour
  ..minute = a.minute
  ..isEnabled = a.isEnabled
  ..repeatDays = a.repeatDays
  ..soundAsset = a.soundAsset
  ..createdAt = a.createdAt;
```

The `..` operator is Dart's **cascade**: `obj..a = 1..b = 2` returns `obj`
after setting both fields. It's how you do builder-style construction on
classes whose constructors aren't designed for it — useful here because `Id`
is mutable (Isar will overwrite it on first insert) and we want the same
pattern for all fields.

Two-class split (entity vs. model) is the same reason Spring projects often
have `User` (domain) and `UserJpaEntity` (data) — the domain class should not
care that Isar exists.

### `alarm_local_datasource.dart` — the raw DB calls

```dart
class AlarmLocalDatasource {
  final Isar _isar;
  AlarmLocalDatasource(this._isar);

  Future<List<AlarmModel>> getAllAlarms() async {
    try {
      return _isar.alarmModels.where().sortByCreatedAt().findAll();
    } on IsarError catch (e) {
      throw DatabaseException('Failed to load alarms', cause: e);
    }
  }
```

This is the thinnest possible wrapper around Isar:

- `_isar.alarmModels` is a generated accessor (one per `@collection` class)
  — equivalent to `entityManager.createQuery("from AlarmModel", AlarmModel.class)`.
- `.where().sortByCreatedAt().findAll()` is Isar's fluent query DSL; the
  generator built `sortByCreatedAt` from our `createdAt` field name. Very
  similar to Spring Data method-name queries (`findAllByOrderByCreatedAt`).
- Every operation is wrapped in `try / on IsarError catch` and rethrown as the
  project's own `DatabaseException`. This isolates the rest of the app from
  Isar-specific exception types — exactly what a Spring app does by translating
  `JpaSystemException` to a custom domain exception in a `@ControllerAdvice`.

Write operations go through `Isar.writeTxn`:

```dart
Future<int> putAlarm(AlarmModel model) async {
  try {
    return _isar.writeTxn(() => _isar.alarmModels.put(model));
  } on IsarError catch (e) {
    throw DatabaseException('Failed to save alarm', cause: e);
  }
}

Future<void> deleteAlarm(int id) async {
  try {
    await _isar.writeTxn(() => _isar.alarmModels.delete(id));
  } on IsarError catch (e) {
    throw DatabaseException('Failed to delete alarm', cause: e);
  }
}
```

`writeTxn` is Isar's transaction wrapper — any write must happen inside one.
Think of it as `@Transactional` but explicit: there is no proxy doing it for
you, you call `writeTxn(() => ...)`. `put` upserts: insert if id is
`Isar.autoIncrement`, update otherwise.

### `alarm_repository_impl.dart` — implementing the domain interface

```dart
class AlarmRepositoryImpl implements AlarmRepository {
  final AlarmLocalDatasource _datasource;
  AlarmRepositoryImpl(this._datasource);

  @override
  Future<List<AlarmEntity>> getAllAlarms() async {
    final models = await _datasource.getAllAlarms();
    return models.map((m) => m.toEntity()).toList();
  }
```

Almost every method here is "delegate to datasource + map model↔entity". The
one that does real work is `toggleEnabled`:

```dart
@override
Future<void> toggleEnabled(int id) async {
  final model = await _datasource.getAlarmById(id);
  if (model == null) return;
  model.isEnabled = !model.isEnabled;
  await _datasource.putAlarm(model);
}
```

This is **not** atomic across reads — there's a window between `getAlarmById`
and `putAlarm` where someone else could write. For a single-user mobile app
this is fine (no concurrent writers in practice), but in a Spring/JPA world
you'd wrap it in `@Transactional` and let the database serialize. Isar's
`writeTxn` only protects the put, not the read-then-put, so a real production
system with collaborators would need an optimistic-locking column.

The `@override` annotation is the same as Java's — compile-time check that we
actually implement an interface method.

---

## Layer 3 — Presentation

### `alarms_provider.dart` — Riverpod glue

This is the file the UI talks to. Two providers live here:

```dart
final alarmRepositoryProvider = Provider<AlarmRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return AlarmRepositoryImpl(AlarmLocalDatasource(isar));
});

final alarmsProvider =
    AsyncNotifierProvider<AlarmsNotifier, List<AlarmEntity>>(AlarmsNotifier.new);
```

`alarmRepositoryProvider` builds the repository graph lazily on first request:
it `ref.watch`es the global `isarProvider` (the singleton Isar instance from
`core/database/database_provider.dart`), constructs the datasource, hands it
to the repository impl. This is the closest thing Riverpod has to a
`@Configuration` class — except it's per-feature instead of central.

`alarmsProvider` is an `AsyncNotifierProvider`: it exposes
`AsyncValue<List<AlarmEntity>>` (loading / data / error) to widgets and holds
a long-lived `AlarmsNotifier` for mutations. Think of it as a Spring
`@RestController` that streams `Flux<List<Alarm>>` to the view layer, with
the notifier methods being the POST/PUT/DELETE endpoints.

The notifier itself:

```dart
class AlarmsNotifier extends AsyncNotifier<List<AlarmEntity>> {
  late AlarmRepository _repository;
  late AlarmService _alarmService;

  @override
  Future<List<AlarmEntity>> build() async {
    _repository = ref.watch(alarmRepositoryProvider);
    _alarmService = ref.watch(alarmServiceProvider);
    return _repository.getAllAlarms();
  }
```

`build()` runs once on construction and any time the notifier is invalidated.
It pulls its dependencies from Riverpod (the closest thing Flutter has to
`@Autowired`) and returns the initial list. While that future is pending,
widgets watching the provider see `AsyncValue.loading`; on success they get
`AsyncValue.data(list)`; on throw, `AsyncValue.error(...)`.

Mutations:

```dart
Future<void> create(AlarmEntity alarm) async {
  await CreateAlarmUseCase(_repository, _alarmService)(alarm);
  ref.invalidateSelf();
}

Future<void> save(AlarmEntity alarm) async {
  await _alarmService.stopAlarm(alarm.id);
  await _repository.updateAlarm(alarm);
  if (alarm.isEnabled) {
    await _alarmService.scheduleAlarm(alarm);
  }
  ref.invalidateSelf();
}

Future<void> delete(int id) async {
  await DeleteAlarmUseCase(_repository, _alarmService)(id);
  state = AsyncData(state.valueOrNull?.where((a) => a.id != id).toList() ?? []);
}

Future<void> toggle(int id) async {
  await ToggleAlarmUseCase(_repository, _alarmService)(id);
  ref.invalidateSelf();
}
```

A few things to notice:

- `create` and `toggle` delegate to use cases, then `ref.invalidateSelf()`
  re-runs `build()` and re-reads from the DB. Simple, slightly wasteful, but
  correct.
- `save` (used for edits) doesn't use a use case — it inlines the logic
  because edit-flow has its own ordering: **stop any existing scheduled
  alarm**, update the row, schedule again if still enabled. Without the stop,
  changing 07:00→08:00 would leave the old 07:00 still firing.
- `delete` does an **optimistic update** instead of `invalidateSelf` — it
  rewrites `state` directly with the row removed, so the deleted card
  disappears immediately instead of waiting for a reload. The use case still
  runs the real DB delete + native stop in the background. If the use case
  throws, the exception propagates up to the `_confirmDelete` caller but the
  UI is already out of sync; a more cautious implementation would re-invalidate
  on error.
- `state = AsyncData(...)` is the Riverpod equivalent of
  `this.list = newList; notifyListeners();` — `AsyncNotifier` exposes a
  settable `state` and rebuilds all watching widgets when it changes.

### `alarms_screen.dart` — the UI

The widget is a `ConsumerWidget`, the Riverpod variant that has a
`WidgetRef ref` parameter in `build`. The top of the build method shows the
canonical pattern for consuming an async provider:

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final alarmsAsync = ref.watch(alarmsProvider);
  return Scaffold(
    backgroundColor: kBgPrimary,
    appBar: AppBar(...),
    body: alarmsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(...)),
      error: (_, __) => const Center(child: Text(kError, ...)),
      data: (alarms) {
        if (alarms.isEmpty) { return ...empty state... }
        return ListView.builder(
          itemCount: alarms.length,
          itemBuilder: (_, i) => _AlarmCard(alarm: alarms[i]),
        );
      },
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: () => _showAlarmSheet(context),
      ...
    ),
  );
}
```

`alarmsAsync.when(loading:, error:, data:)` is the sealed-class match: every
state must have a branch, so you can never forget the loading spinner. It's
the same defensive pattern Java 21 sealed-class switches enforce.

`ListView.builder` is the lazy list — equivalent to a virtualized table, it
only constructs `_AlarmCard` widgets that are currently on screen.

`FloatingActionButton.onPressed` calls `_showAlarmSheet(context)`, a
module-level helper that pops a `showModalBottomSheet` with a
`_AlarmSheet` widget (the new/edit form).

The alarm row:

```dart
class _AlarmCard extends ConsumerWidget {
  final AlarmEntity alarm;
  const _AlarmCard({required this.alarm});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      ...
      child: Row(
        children: [
          Expanded(child: Column(...time + label + repeat...)),
          Column(children: [
            Switch(
              value: alarm.isEnabled,
              onChanged: (_) => ref.read(alarmsProvider.notifier).toggle(alarm.id),
              ...
            ),
            GestureDetector(
              onTap: () => _confirmDelete(context, ref),
              child: Padding(...Icon(Iconsax.trash)...),
            ),
          ]),
        ],
      ),
    );
  }
```

The toggle uses **`ref.read` not `ref.watch`** in callbacks: `watch` would
subscribe and rebuild on changes, which doesn't make sense for a one-shot
button press; `read` is fire-and-forget. The notifier's `toggle` method then
runs the full Clean Architecture path: use case → repo → datasource → Isar,
plus the native `scheduleAlarm` / `stopAlarm` call.

The delete confirmation is a stock `AlertDialog`:

```dart
void _confirmDelete(BuildContext context, WidgetRef ref) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: kBgSecondary,
      title: const Text('Delete alarm?', ...),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', ...)),
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            ref.read(alarmsProvider.notifier).delete(alarm.id);
          },
          child: Text('Delete', ...),
        ),
      ],
    ),
  );
}
```

`Navigator.pop(ctx)` is "close this dialog" — equivalent to closing a modal in
a web app. We pop **before** calling delete so the dialog goes away
immediately, and the optimistic update in `AlarmsNotifier.delete` then yanks
the card.

### The add/edit sheet — `_AlarmSheet`

This is a `ConsumerStatefulWidget` because the form has local state
(`_time`, `_repeatDays`, `_sound`, `_labelCtrl`) that must survive across
rebuilds while the user fiddles with the form. State widgets have an
`initState()` (like a Spring `@PostConstruct`) and a `dispose()` (like
`@PreDestroy`):

```dart
@override
void initState() {
  super.initState();
  final a = widget.existing;
  _labelCtrl = TextEditingController(text: a?.label ?? '');
  _time = a != null
      ? TimeOfDay(hour: a.hour, minute: a.minute)
      : TimeOfDay.now();
  _repeatDays = a?.repeatDays ?? 0;
  _sound = a?.soundAsset ?? _sounds[0].$2;
}

@override
void dispose() {
  _labelCtrl.dispose();
  super.dispose();
}
```

`widget.existing` is `null` for "new alarm" and non-null for "edit existing".
`_sounds[0].$2` accesses the second element of a Dart **record** — `_sounds`
is declared as a list of `(String, String)` records pairing a display name
with the asset path:

```dart
static const _sounds = [
  ('Default', 'assets/sounds/alarm_default.mp3'),
  ('Gentle', 'assets/sounds/alarm_gentle.mp3'),
  ...
];
```

Records are Dart's lightweight tuples — `.$1` is the first field, `.$2` is
the second. No Java equivalent before Java 14.

The day picker is built with `List.generate` and bitmask arithmetic:

```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: List.generate(7, (i) {
    final isOn = _repeatDays & (1 << i) != 0;
    return GestureDetector(
      onTap: () => setState(() => _repeatDays ^= (1 << i)),
      child: AnimatedContainer(
        ...
        decoration: BoxDecoration(
          color: isOn ? kAccentPurple : kBgTertiary,
          shape: BoxShape.circle,
        ),
        child: Center(child: Text(_dayLabels[i], ...)),
      ),
    );
  }),
);
```

Each circle XORs its bit into `_repeatDays` on tap (`^= (1 << i)`), which
flips that day on or off. `setState(() => ...)` is the imperative trigger
that re-runs `build()` — without it, the state changes but Flutter never
re-renders.

Save:

```dart
Future<void> _save() async {
  final now = DateTime.now();
  final alarm = AlarmEntity(
    id: widget.existing?.id ?? 0,
    label: _labelCtrl.text.trim(),
    hour: _time.hour,
    minute: _time.minute,
    repeatDays: _repeatDays,
    soundAsset: _sound,
    createdAt: widget.existing?.createdAt ?? now,
  );

  if (widget.existing == null) {
    await ref.read(alarmsProvider.notifier).create(alarm);
  } else {
    await ref.read(alarmsProvider.notifier).save(alarm);
  }
  if (mounted) Navigator.pop(context);
}
```

`id: 0` is the sentinel "no id yet" — `AlarmModel.fromEntity` will copy that
into `model.id`, but Isar treats any id-on-an-unknown-row as a request to
auto-increment. `if (mounted) Navigator.pop(context)` is the Flutter idiom
for "only close the sheet if this widget is still attached to the tree" —
the user could have backgrounded the app during the await, and trying to use
`context` on a disposed widget throws.

---

## How alarms integrate with AlarmService

The audio scheduling — the only thing that makes an alarm an alarm and not
just a row in a database — lives in `core/services/alarm_service.dart`,
covered in detail in **chapter 02 — Core Services**. Quick recap of the
contract this feature relies on:

```dart
abstract class AlarmService {
  Future<void> scheduleAlarm(AlarmEntity alarm);
  Future<void> stopAlarm(int id);
}
```

Internally it wraps the `alarm` package (a Flutter plugin that hooks into
Android's `AlarmManager` / iOS `UNUserNotificationCenter` + a foreground
service) and translates an `AlarmEntity` into one or more native scheduled
events:

- A "once" alarm (`repeatDays == 0`) becomes a single fire-time computed as
  "next occurrence of `hour:minute`".
- A repeating alarm becomes one entry per active weekday bit, each rescheduled
  for next week after it fires.
- The `soundAsset` path is read by the foreground service when the alarm
  fires; it spawns a full-screen activity, holds a wake-lock, and plays the
  audio until the user taps "Dismiss" in the notification.

The feature layer never touches any of that — it just calls
`scheduleAlarm(entity)` and `stopAlarm(id)`. Chapter 02 explains how the
service registers a callback that the native side invokes through a
`MethodChannel` when an alarm actually rings.

The `alarmServiceProvider` (declared in
`core/services/service_providers.dart`) is the Riverpod singleton that
`AlarmsNotifier.build()` watches, so the whole feature gets the same instance
as every other piece of the app.

---

## Trace: set alarm for 7:00 AM and toggle off

End-to-end walk-through of a single user journey:

**1. User taps the `+` FAB.**

`alarms_screen.dart` line 56: `onPressed: () => _showAlarmSheet(context)`.
Flutter pushes a modal bottom sheet containing a fresh
`_AlarmSheet(existing: null)` widget.

**2. The sheet's `initState` runs.**

`_time = TimeOfDay.now()` (let's say 14:32), `_repeatDays = 0`, default sound,
empty label.

**3. User taps the big clock display.**

`_pickTime` runs:

```dart
final picked = await showTimePicker(context: context, initialTime: _time, ...);
if (picked != null) setState(() => _time = picked);
```

User picks 07:00. `setState` triggers a rebuild and the big number reads
`07:00`.

**4. User leaves repeat empty (Once), default sound, taps "Set Alarm".**

`_save()` runs. It builds an entity:

```dart
AlarmEntity(
  id: 0,                                 // sentinel, Isar will autogen
  label: '',
  hour: 7, minute: 0,
  repeatDays: 0,
  soundAsset: 'assets/sounds/alarm_default.mp3',
  createdAt: DateTime.now(),
)
```

then calls `ref.read(alarmsProvider.notifier).create(alarm)`.

**5. `AlarmsNotifier.create` calls the use case.**

```dart
await CreateAlarmUseCase(_repository, _alarmService)(alarm);
ref.invalidateSelf();
```

`CreateAlarmUseCase.call`:

- `final id = await _repository.createAlarm(alarm);` — repo calls
  `AlarmLocalDatasource.putAlarm(AlarmModel.fromEntity(alarm))`. Datasource
  opens `Isar.writeTxn`, puts the model, returns the new id (say, `17`).
- `final created = alarm.copyWith(id: 17);`
- `AppLogger.I.action('alarm', 'create', data: {id: 17, hour: 7, minute: 0, enabled: true})`
- `created.isEnabled` is `true`, so it enters the `try` block:
- `await _alarmService.scheduleAlarm(created);` — `AlarmService` computes
  "next 07:00" (tomorrow if it's past 07:00 today, otherwise today), tells
  the native plugin to register an exact alarm with id 17 and the default
  sound asset.
- Returns id 17 to the notifier.

**6. `ref.invalidateSelf()` re-runs `build()`.**

The notifier reads `_repository.getAllAlarms()` again, which now includes
the new row. The widget tree subscribed to `alarmsProvider` rebuilds. The
new card slides into the `ListView.builder`.

**7. `_save` calls `Navigator.pop(context)`** — sheet closes.

The user sees a card: `7:00 AM  ·  Once`, with a purple toggle in the on state.

**8. Later, user taps the toggle to disable.**

`alarms_screen.dart` `_AlarmCard`:

```dart
Switch(
  value: alarm.isEnabled,
  onChanged: (_) => ref.read(alarmsProvider.notifier).toggle(alarm.id),
  ...
)
```

`onChanged(false)` fires — note we ignore the new value, the notifier
re-derives it.

**9. `AlarmsNotifier.toggle(17)`** runs the use case:

```dart
await _repository.toggleEnabled(17);
final alarm = await _repository.getAlarmById(17);
if (alarm == null) return;
if (alarm.isEnabled) {
  await _alarmService.scheduleAlarm(alarm);
} else {
  await _alarmService.stopAlarm(17);
}
```

- `toggleEnabled(17)`: repo asks datasource for the model, flips
  `isEnabled` from `true` to `false`, puts it back inside a `writeTxn`.
- `getAlarmById(17)`: returns the just-updated entity, `isEnabled == false`.
- Since `false`, we hit `_alarmService.stopAlarm(17)` — native plugin
  cancels the registered alarm. The phone will **not** ring at 07:00.

**10. `ref.invalidateSelf()`** re-runs `build()`, the card rebuilds in the
disabled style:

```dart
color: alarm.isEnabled ? kBgSecondary : kBgTertiary,
...
Text(alarm.timeString, style: TextStyle(
  color: alarm.isEnabled ? kTextPrimary : kTextHint,
  ...
)),
```

The card is now dimmer, the time text is `kTextHint` grey, the switch sits in
its off track. No audio will play.

---

That's the entire alarms feature. The shape mirrors Reminders, with one
critical difference: every domain operation **pairs** a database change with
a native-side scheduling call, and the order matters. Create persists then
schedules; delete stops then deletes; toggle write-flips then either
schedules or stops based on the new value; save (edit) stops then writes then
re-schedules if enabled. Get the order wrong and you either get zombie
alarms ringing with no DB row, or DB rows with no native registration that
silently never fire.

Next chapter (07) covers the **Tasks** feature, where the wrinkle is not
audio but priority-and-status state machines.
