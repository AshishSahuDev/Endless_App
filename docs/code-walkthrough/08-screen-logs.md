# 08 — Screen: Diagnostic Logs

This chapter walks through `logs_screen.dart`, the single-file UI that renders
the in-memory ring buffer maintained by `AppLogger`. It is a producer/consumer
story: chapter 02 built the producer (a singleton service emitting `LogEntry`
values onto a broadcast `Stream`); here we wire a Flutter screen to that stream
and paint each entry. Along the way we will see Dart 3 records, Riverpod
`StateProvider`, `StreamSubscription` lifecycle, and the `mounted` guard
pattern that has no direct analog in server-side Spring code.

---

## How it relates to AppLogger

Recall from chapter 02 that `AppLogger` is a process-wide singleton accessed
through `AppLogger.I`. Conceptually it has two surfaces:

| Surface              | Type                     | Purpose                                  |
| -------------------- | ------------------------ | ---------------------------------------- |
| `AppLogger.I.buffer` | `List<LogEntry>` (last N) | Snapshot read on demand                  |
| `AppLogger.I.stream` | `Stream<LogEntry>`        | Push notification of every new entry     |
| `AppLogger.I.exportAsText()` | `Future<String>`  | Concatenate buffer for clipboard / file  |
| `AppLogger.I.clear()`        | `Future<void>`    | Drop buffer + on-disk rotated file       |

For a Spring developer, `stream` is essentially a **hot `Flux<LogEntry>`** from
Project Reactor. It is a broadcast stream, meaning every subscriber sees every
new event independently, and it does not replay missed events to late
subscribers — you get whatever was emitted *after* you subscribed. The
`buffer` is the bridge that compensates for that: when the Logs screen opens,
it pulls the existing snapshot from `buffer`, and from that moment on it lets
the stream wake it up whenever a new entry is appended.

The screen never asks `AppLogger` *what* changed. It just calls `setState(() {})`
on every event — a deliberately cheap "something happened, repaint me" signal.
The `build()` method then re-reads `buffer` and applies the current filter.
This is the same idea as a Spring controller method that recomputes its view
model from scratch on every request, except the trigger here is a stream tick
rather than an HTTP call.

---

## File: logs_screen.dart

The file is short — about 240 lines — and contains four declarations:

1. A top-level `_filterProvider` (Riverpod state).
2. `LogsScreen` / `_LogsScreenState` — the stateful widget pair.
3. `_FilterBar` — the horizontal chip row.
4. `_LogTile` — one row in the list.

The leading underscores on the last three are Dart's file-level privacy
marker. Anything starting with `_` is invisible to other libraries, the same
way `package-private` works in Java, but scoped to the source file rather
than the package directory. Only `LogsScreen` (no underscore) is exported.

### `_filterProvider` (top-level StateProvider)

```dart
final _filterProvider = StateProvider<LogLevel?>((_) => null);
```

A `StateProvider<T>` is the simplest Riverpod primitive — it holds a single
mutable value of type `T` and notifies listeners when it is reassigned.
Here `T` is `LogLevel?`, meaning "either a specific log level or null
meaning no filter". The initial value is `null` (show all).

Why declare it at the **top level** of the file instead of as a field on
`_LogsScreenState`?

- Providers are looked up by **identity**, not by name. The same Dart object
  reference must be used from both the screen and `_FilterBar`. A `final`
  top-level variable is the idiomatic way to give two widgets a shared
  handle to the same provider.
- Riverpod providers are conceptually closer to Spring bean definitions
  than to local fields: they describe *how to build* a piece of state,
  and the framework owns the actual instance inside a `ProviderContainer`
  (analogous to the `ApplicationContext`).
- Co-locating it in the same file as its only consumers keeps it private
  (`_` prefix) and avoids polluting the wider app's provider namespace.

Reads happen via `ref.watch(_filterProvider)` (rebuilds the widget when
the value changes) and writes via
`ref.read(_filterProvider.notifier).state = newValue`.

### `_LogsScreenState` — initState / dispose

```dart
class _LogsScreenState extends ConsumerState<LogsScreen> {
  late final StreamSubscription<LogEntry> _sub;

  @override
  void initState() {
    super.initState();
    _sub = AppLogger.I.stream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
```

Three Dart/Flutter idioms are bundled here. Take them one at a time.

**`late final StreamSubscription<LogEntry> _sub`.**
`late` means "I promise to assign this exactly once before anyone reads it,
so don't make me write `?` everywhere". `final` means "once assigned, the
reference cannot be reassigned" (the subscription itself is still mutable
internally — `cancel()` works fine). Together they are Dart's way of
expressing what Java would write as `private final StreamSubscription<...> sub;`
initialised in a constructor body.

**`AppLogger.I.stream.listen(...)`.**
`listen` is the `Stream` API's subscribe method. It returns a
`StreamSubscription<T>` handle, which is the resource you must close to stop
receiving events. In Reactor terms this is `flux.subscribe(...)` returning a
`Disposable`. The callback ignores its argument (`(_) => ...`) because we
don't care *what* changed — we only need the "something happened" signal.

**`if (mounted) setState(() {});`.**
This is the single most important lifecycle pattern in Flutter and it does
not exist in Spring. A `State` object can be *disposed* (the widget
removed from the tree) at any moment, including in between a stream event
being scheduled and its callback firing. Calling `setState` on a disposed
state throws. `mounted` is a boolean on `State` that flips to `false`
inside `dispose()`. Every async callback that touches widget state must
check it first. Java has no equivalent because servlet requests don't get
"unmounted" mid-flight — the closest mental model is "the HTTP connection
might have been closed by the client before your async work completed",
except in Flutter it is the *entire UI subtree* that may have vanished.

**`dispose()`** cancels the subscription. Forgetting this is the Flutter
equivalent of forgetting to call `disposable.dispose()` on a Reactor
subscription: the stream keeps a strong reference to the now-orphaned
`State` object, which keeps a reference to its `BuildContext`, which keeps
the whole element tree alive — a memory leak that the Flutter inspector
will eventually flag as a "leaked widget".

### `_copyAll` and `_clear` — the await + mounted pattern

```dart
Future<void> _copyAll() async {
  final text = await AppLogger.I.exportAsText();
  await Clipboard.setData(ClipboardData(text: text));
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Logs copied to clipboard')),
  );
}

Future<void> _clear() async {
  await AppLogger.I.clear();
  if (mounted) setState(() {});
}
```

Both methods follow the same shape: **do async work, then check `mounted`,
then touch the UI**. The reason is that `await` yields control back to the
Flutter event loop, and during that yield the user may have navigated away.
After the await resumes, `this.context` could refer to a `State` that no
longer has a `BuildContext` in the tree. Using it would throw.

`_copyAll` returns early with `return;` because there is nothing more to
do — the clipboard write already succeeded; we just can't show the snackbar.
`_clear` uses the positive form because the entire point of the call is to
trigger a rebuild. Both styles are idiomatic; pick whichever reads better
locally.

Note `Clipboard.setData` is from `package:flutter/services.dart` — it is
Flutter's thin wrapper over the platform clipboard MethodChannel. For a
Spring developer, think of it like a small RPC call into native iOS or
Android code. Like every platform call, it is asynchronous.

`ScaffoldMessenger.of(context)` is the "inherited widget lookup" pattern:
walk up the widget tree from the current `BuildContext` until you find the
nearest ancestor `ScaffoldMessenger`, then call `showSnackBar` on it. This
is closer to a JNDI lookup than a DI injection — the resolution is
positional in the tree, not by type from a global registry.

### `build()` — filter logic, empty state, footer

```dart
@override
Widget build(BuildContext context) {
  final filter = ref.watch(_filterProvider);
  final entries = AppLogger.I.buffer.reversed
      .where((e) => filter == null || e.level == filter)
      .toList();
  ...
}
```

Three things happen in those four lines.

1. `ref.watch(_filterProvider)` returns the current `LogLevel?` *and*
   subscribes this widget to future changes. When the user taps a chip in
   `_FilterBar` and the state changes, `build()` re-runs automatically.
2. `buffer.reversed` returns an `Iterable<LogEntry>` walking the list in
   reverse without allocating a new list — newest entries first.
3. `.where(predicate).toList()` is Dart's equivalent of Java's
   `stream().filter(...).collect(toList())`. The lambda uses the
   short-circuit `filter == null || e.level == filter` so the "All" case
   skips the level check entirely.

The body is a `Column` with three slices, top to bottom:

```dart
body: Column(
  children: [
    _FilterBar(active: filter),
    if (entries.isEmpty)
      const Expanded(
        child: Center(
          child: Text('No log entries', style: TextStyle(color: kTextHint)),
        ),
      )
    else
      Expanded(
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: entries.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (_, i) => _LogTile(entry: entries[i]),
        ),
      ),
    Container(...footer...),
  ],
),
```

The `if`/`else` inside the children list is **collection-if**, a Dart
language feature that lets you conditionally include elements in any
collection literal without ternary gymnastics. It is roughly equivalent to
JSX's `{condition && <X/>}` pattern, but type-checked: each branch must
evaluate to the collection's element type (here, `Widget`).

`Expanded` is the Flutter layout primitive that says "stretch to fill the
remaining space along the parent's main axis". Inside a `Column` that
means take all leftover vertical space. Without it, `ListView` (which is
infinitely scrollable in principle) would not know how tall to be and
Flutter would throw a layout error.

`ListView.separated` is the lazy, virtualised list constructor — only
visible tiles are built, much like Android's `RecyclerView`. The
`separatorBuilder` inserts a 6-pixel gap between items.

The footer is a thin status bar:

```dart
Container(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
  color: kBgSecondary,
  child: Row(
    children: [
      Text('${entries.length} entries (buffer: ${AppLogger.I.buffer.length}/500)',
          style: const TextStyle(color: kTextHint, fontSize: 11)),
      const Spacer(),
      if (AppLogger.I.currentFile != null)
        Text(
          'file: ${AppLogger.I.currentFile!.path.split('/').last}',
          style: const TextStyle(color: kTextHint, fontSize: 11),
        ),
    ],
  ),
),
```

`Spacer()` is the flex equivalent of `<div style="flex:1"/>` — it eats all
the slack so the file name pin-pins to the right. The `!` after
`AppLogger.I.currentFile` is the **null-assertion operator**: we just
checked it is non-null above, but Dart's flow analysis cannot prove that
across a method boundary (`currentFile` is a getter), so we tell the
compiler "trust me". If the assertion is wrong at runtime, you get a
`Null check operator used on a null value` — Dart's equivalent of an NPE.

### `_FilterBar` — chips, record tuples, selection styling

```dart
class _FilterBar extends ConsumerWidget {
  final LogLevel? active;
  const _FilterBar({required this.active});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levels = <(String, LogLevel?)>[
      ('All', null),
      ('Action', LogLevel.action),
      ('Info', LogLevel.info),
      ('Warn', LogLevel.warn),
      ('Error', LogLevel.error),
      ('Debug', LogLevel.debug),
    ];
    ...
  }
}
```

This is the bar of pill-shaped chips above the list. It is a
`ConsumerWidget` — a stateless widget with a `WidgetRef` injected into
`build()`, which lets it read and write providers without holding its
own `State`. The selected level comes in via the `active` field rather
than via `ref.watch`, because the parent already watched it; we are
passing the value down to avoid two widgets subscribing to the same
provider unnecessarily.

The interesting type is `<(String, LogLevel?)>`. That is a **Dart 3
record**, a brand-new language feature (think `java.lang.Record` but
structural, not nominal). The pieces:

- `(String, LogLevel?)` declares an **anonymous tuple type** with two
  positional fields: a `String` and a nullable `LogLevel`.
- `('All', null)` constructs an instance of that type.
- Fields are accessed by their 1-based position: `l.$1` is the `String`,
  `l.$2` is the `LogLevel?`.

This is genuinely new syntax — there is no equivalent in pre-Java-14 code,
and even Java records require you to declare a named class first. Dart's
records are closer to Python tuples or TypeScript `[string, LogLevel?]`
tuple types. They are value types: equality and hashCode are
component-wise, so two records with the same fields are `==`.

A purist might define a small `_LevelOption` class with `name` and `level`
fields. The record is a lightweight alternative when the structure is
local and obvious — you save the boilerplate but pay with positional
access (`$1`, `$2`) instead of named fields. For a six-element fixed
list inside one function, the trade is fine.

The chip rendering:

```dart
children: levels.map((l) {
  final selected = l.$2 == active;
  return Padding(
    padding: const EdgeInsets.only(right: 8),
    child: GestureDetector(
      onTap: () =>
          ref.read(_filterProvider.notifier).state = l.$2,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? kAccentPurple.withAlpha(60) : kBgSecondary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? kAccentPurple : kGlassBorder,
            width: 0.5,
          ),
        ),
        child: Text(
          l.$1,
          style: TextStyle(
            color: selected ? kAccentPurple : kTextSecondary,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    ),
  );
}).toList(),
```

`levels.map((l) => ...).toList()` is the standard transform-to-widget-list
pattern; Flutter's children parameters take a `List<Widget>`, not an
iterable, so the `.toList()` is required.

`selected = l.$2 == active` reuses record equality: when `l.$2` is `null`
and `active` is `null`, this is `true` — Dart's `==` is null-safe on the
left operand because `null == null` is true and `null == x` is false.

`GestureDetector` wraps the chip and turns taps into the write
`ref.read(_filterProvider.notifier).state = l.$2`. The `.notifier` getter
returns the underlying `StateController`, whose `state` setter triggers
the notification. We use `ref.read` here (one-shot read) rather than
`ref.watch` (subscribe) because we are inside an event handler, not a
build method — we want the current value, not a subscription.

The selection styling is pure conditional decoration: tinted background,
coloured border, bold purple text when selected; muted defaults otherwise.
The 60-alpha tint over the dark background gives the chip a glow-on-select
effect without a separate sprite.

### `_LogTile` — color-by-level, optional data / error display

```dart
Color get _levelColor => switch (entry.level) {
      LogLevel.debug => kTextHint,
      LogLevel.info => kAccentBlue,
      LogLevel.action => kAccentGreen,
      LogLevel.warn => kAccentOrange,
      LogLevel.error => kAccentPink,
    };
```

A **switch expression** (Dart 3) — every arm yields a value, and the whole
expression returns one. This is exhaustive: because `LogLevel` is an enum,
the compiler checks every case is handled, the same way Java's
`switch ... ->` expressions do since JDK 14. Adding a new level would
force a compile-time update here.

The expression body (`=>`) is shorthand for `{ return ...; }`. Combined
with a getter (`Color get _levelColor`) we get a zero-argument computed
property — same as a Kotlin `val _levelColor: Color get() = ...`.

The body of the tile:

```dart
return Container(
  padding: const EdgeInsets.all(10),
  decoration: BoxDecoration(
    color: kBgSecondary,
    borderRadius: BorderRadius.circular(8),
    border: Border(left: BorderSide(color: _levelColor, width: 3)),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        Text(entry.levelName, style: TextStyle(color: _levelColor, ...)),
        const SizedBox(width: 8),
        Text(entry.tag, ...),
        const Spacer(),
        Text(_hhmmss(entry.timestamp), ...),
      ]),
      const SizedBox(height: 4),
      Text(entry.message, ...),
      if (entry.data != null && entry.data!.isNotEmpty) ...[
        const SizedBox(height: 2),
        Text(entry.data.toString(), ...),
      ],
      if (entry.error != null) ...[
        const SizedBox(height: 2),
        Text(entry.error!, ...),
      ],
    ],
  ),
);
```

The card has a single coloured stripe on its left edge — that's the
`Border(left: BorderSide(...))` trick. It is visually quieter than tinting
the entire background and lets the level still pop at a glance.

Inside, a `Column` stacks:

- A header `Row` of `[level name] [tag] -spacer- [hh:mm:ss]`.
- The message line.
- Optionally, a monospace dump of `entry.data` (a `Map<String, dynamic>?`)
  if it is present and non-empty.
- Optionally, the error message in pink.

The `...[ ... ]` syntax inside the children list is the **spread
operator** combined with collection-if. `if (cond) ...[a, b]` means "if
cond, splice in elements a and b". Without the spread, the `if` would
have to wrap a single widget; the spread lets one condition gate multiple
widgets, including the `SizedBox` spacer above them. Java has no direct
equivalent — you would build a list and conditionally add items.

`entry.data!` and `entry.error!` are again null assertions, safe here
because the surrounding `if` already proved them non-null but Dart's flow
analysis loses that proof when crossing the `...[ ]` boundary in some
versions. The bang is the cheapest way to satisfy the type checker.

`_hhmmss` is a tiny formatter — Dart has no built-in `DateTimeFormatter`
without pulling in `package:intl`, so a hand-rolled
`padLeft(2, '0')` triple is the pragmatic choice for an internal screen.

---

## How a new log entry appears on screen

To make the pieces concrete, here is the full path a log call takes from
somewhere deep in the app to a coloured pixel on the diagnostic screen.
Assume the user is currently looking at `LogsScreen` with the filter set
to "All".

1. **Producer side.** Some controller, repository, or background task
   calls `AppLogger.I.info('NetSync', 'Pulled 17 jobs')`. Inside
   `AppLogger` (chapter 02), this builds a `LogEntry` value, appends it to
   the bounded `buffer` (dropping the oldest if length > 500), and pushes
   it onto the broadcast `StreamController`. It also schedules an async
   write to the rotating log file, but that path does not involve the UI.

2. **Stream tick.** The `StreamController` synchronously delivers the new
   `LogEntry` to every active subscriber. `_LogsScreenState._sub` is one
   of them — its `listen` callback runs on the same microtask.

3. **Mounted guard.** The callback checks `if (mounted)`. If the user has
   navigated away in the meantime (the `State` was disposed), we bail out
   silently — the subscription should be cancelled by `dispose()`, but
   timing windows around microtask delivery make the guard cheap insurance.

4. **`setState(() {})`.** With no body, this is a pure "mark dirty" call.
   Flutter schedules the `_LogsScreenState` for rebuild on the next frame.
   The empty closure is intentional — there is no local state to mutate;
   the buffer lives in `AppLogger`, and `build()` will re-read it.

5. **Frame begins.** On the next vsync tick, Flutter calls `build()`.
   It reads `ref.watch(_filterProvider)` (still `null` — "All"), pulls
   `AppLogger.I.buffer.reversed`, filters (no-op because filter is null),
   and materialises a `List<LogEntry>` whose first element is the new
   entry from step 1.

6. **List diff.** `ListView.separated` is asked for `entries.length`
   items. Flutter's element-tree reconciler walks the existing tiles, sees
   that the list grew by one at the top, builds one new `_LogTile`, and
   reuses the rest. Old tiles whose `entry` field reference is unchanged
   are reused at zero cost; the new tile renders fresh.

7. **`_LogTile.build`.** For the new entry, the switch expression
   evaluates `_levelColor` (e.g. `kAccentBlue` for `LogLevel.info`).
   The header row renders `INFO  NetSync  ...  14:03:22`. The body
   shows `Pulled 17 jobs`. If `entry.data` had been present we would also
   see a monospace JSON-ish line under it.

8. **Footer rebuild.** The `Container` at the bottom of the `Column` was
   inside the same `build` invocation, so the counter "N entries
   (buffer: M/500)" updates in the same frame. If the buffer was at 500
   and a new entry pushed an old one out, you can watch the count cap at
   500 while still seeing fresh data flow at the top.

9. **No tear-down.** The user did not interact, so nothing else happens
   until the next stream event or the next chip tap. The
   `StreamSubscription` stays open. The provider state stays the same.
   The widget tree settles. The screen idles.

If at step 1 the user had switched the filter to "Error" by tapping that
chip, the chain would be slightly different. The chip tap writes to
`_filterProvider`, which causes `build()` to re-run with `filter ==
LogLevel.error`. Subsequent stream ticks for non-error entries would
still wake `build()` via `setState`, but the `.where` clause would drop
the new entry, so the visible list would not grow. The footer counter
would, however, still update — because the unfiltered buffer length is
displayed there.

That round trip — push to stream, mounted-guarded `setState`, re-read
buffer, filter, rebuild list, repaint — is the entire mental model for
this screen. There is no controller, no view-model, no diffing logic to
maintain. The buffer is the source of truth; the stream is the
invalidation signal; `build` is a pure function of (buffer, filter).

In Spring terms: imagine a controller that, on every event from a hot
`Flux`, re-renders a Thymeleaf template against a fresh snapshot of an
in-memory `Deque<LogEntry>`, served over Server-Sent Events. That is
roughly what `LogsScreen` does — except Flutter does the SSE-style push
in-process, and the "template" is the widget tree.
