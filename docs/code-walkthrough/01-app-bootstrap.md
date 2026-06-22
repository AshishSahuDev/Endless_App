# 01 — App Bootstrap & Shell

This chapter walks through what happens between the moment the user taps the Endless icon on their launcher and the moment they see a usable home screen with five bottom tabs. In Spring Boot terms, this is the equivalent of `SpringApplication.run(...)` plus your `@PostConstruct` initializers plus the first request hitting a controller — except in Flutter all of that runs in a single Dart isolate on the user's phone, with no servlet container and no application server. We will read `main.dart`, `app.dart`, the splash screen, the onboarding screen, and the `HomeShell` (the bottom-nav scaffold), line by meaningful line.

If a term like `ProviderScope`, `StatefulWidget`, `Future`, or `Isar` looks unfamiliar, jump back to `00-how-flutter-works.md` — this chapter assumes that material.

## The boot timeline

Here is the sequence the user actually experiences, with each numbered step expanded later in the chapter:

1. **User taps the Endless icon.** Android (or iOS) spawns the app process and the Flutter engine begins loading.
2. **`main()` runs.** Dart's entry point is invoked. This is the analogue of `public static void main(String[] args)`.
3. **`runZonedGuarded` wraps the whole boot** in a Dart zone, so any async error that escapes a `try/catch` gets logged instead of killing the process silently.
4. **`WidgetsFlutterBinding.ensureInitialized()`** wires up the Flutter engine to the Dart side — necessary before any platform channel (file I/O, plugins) can be used. Think `ServletContext` initialization.
5. **Global error handlers are installed.** `FlutterError.onError` and `PlatformDispatcher.instance.onError` catch framework-level and platform-level uncaught errors, like a global `@ControllerAdvice` for the UI thread.
6. **Singleton services are constructed and initialized**: `IsarService` (the embedded NoSQL DB), `NotificationService` (local notifications plugin), and `AlarmService` (alarm/cron-like wakeups). Each `init()` is wrapped in `_guard` so one failing service does not poison the others. This is the `@PostConstruct` phase.
7. **`runApp(...)`** mounts the widget tree, with a `ProviderScope` at the root. The `ProviderScope` is your Spring `ApplicationContext`; the three `overrideWithValue` calls inject the already-initialized service singletons into Riverpod's DI graph.
8. **`EndlessApp` builds**, returning a `MaterialApp` with the dark theme and `SplashScreen` as its `home`.
9. **`SplashScreen` shows the logo, waits ~2.4 seconds**, then reads a `SharedPreferences` flag (`has_seen_onboarding`) and either pushes the `OnboardingScreen` or the `HomeShell` with a fade transition.
10. **`HomeShell` renders the bottom-nav scaffold**, with an `IndexedStack` of five feature screens preserved in memory. The default tab is Notes.

That is the complete boot. Now the files.

## File: `main.dart`

The entry point. Path: `app/lib/main.dart`. Two functions are exported (`main` and `_bootstrap`) plus one private helper (`_guard`). Total weight: about 75 lines, but every one matters.

### Imports

```dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/database/database_provider.dart';
import 'core/database/isar_service.dart';
import 'core/services/app_logger.dart';
import 'core/services/notification_service.dart';
import 'core/services/alarm_service.dart';
import 'core/services/service_providers.dart';
import 'app.dart';
```

`dart:async` brings in `runZonedGuarded` and `Future`. `package:flutter/foundation.dart` exposes `PlatformDispatcher` and some debug constants. `flutter_riverpod` is the DI container — the same role `org.springframework.context.ApplicationContext` plays for you. The remaining `core/...` imports are this project's hand-written services and the Riverpod provider declarations for them. The relative path syntax (`core/...`) is Dart's equivalent of importing inside the same Maven module.

### `main()` — wrap everything in a zone

```dart
Future<void> main() async {
  await runZonedGuarded(_bootstrap, (error, stack) {
    AppLogger.I.error('zone', 'uncaught zone error', error: error, stack: stack);
  });
}
```

A Dart `Future<void>` is the same idea as `CompletableFuture<Void>`. `async` lets us `await` inside.

`runZonedGuarded` is the Dart equivalent of running your whole app inside a `try/catch` plus an `UncaughtExceptionHandler`, except it also captures errors from `Future`s and microtasks that were not awaited. Anything that throws inside `_bootstrap` — even an async error nobody is listening for — lands in this callback. We log it via `AppLogger.I` (the singleton instance accessor, like `LoggerFactory.getLogger(...)`) and let the process continue. There is no `System.exit` here; on mobile, killing the process strands the user, so we log and pray.

### `_bootstrap()` — service init phase

```dart
Future<void> _bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppLogger.I.init();
  AppLogger.I.info('app', 'boot start');
```

`WidgetsFlutterBinding.ensureInitialized()` initializes the engine binding so the Dart code can talk to the platform (call plugins, schedule frames, read files). It must run before any plugin call. Conceptually, it is your `SpringApplication` constructor: nothing useful runs without it.

Then we initialize the logger first — because everything that follows wants to log. `AppLogger.I.init()` likely opens a file sink or rolling log on disk; once it returns, the logger is hot. Compare to configuring `Logback` before any other bean is created.

### Global error handlers

```dart
FlutterError.onError = (details) {
  AppLogger.I.error(
    'flutter',
    'FlutterError: ${details.exceptionAsString()}',
    error: details.exception,
    stack: details.stack,
    data: {'library': details.library, 'context': details.context?.toString()},
  );
  FlutterError.presentError(details);
};
```

`FlutterError.onError` is a static field of type `void Function(FlutterErrorDetails)`. The framework calls it whenever a widget throws inside `build()`, layout, paint, or any internal framework callback. Think `@ControllerAdvice` but for the UI render pipeline. We log structured fields (`library`, `context`) and then forward to `FlutterError.presentError`, which prints the red error screen in debug builds and is a no-op in release. We deliberately do *not* swallow the error — we want the framework's default behavior plus our log entry.

```dart
PlatformDispatcher.instance.onError = (error, stack) {
  AppLogger.I.error('platform', 'PlatformDispatcher error',
      error: error, stack: stack);
  return true;
};
```

`PlatformDispatcher.onError` catches uncaught async errors at the very edge of the Dart isolate — errors that escape every `Future` chain and every zone. The `return true` tells the engine "we handled it, do not crash." This is the last line of defense, below the zone, below the framework. Three nets, in order: `try/catch` -> `FlutterError.onError` for sync render errors -> `PlatformDispatcher.onError` plus `runZonedGuarded` for async escapes.

### Service initialization

```dart
final isarService = IsarService();
await _guard('isar.init', () => isarService.init());

final notificationService = NotificationService();
await _guard('notifications.init', () => notificationService.init());

final alarmService = AlarmService();
await _guard('alarm.init', () => alarmService.init());

AppLogger.I.info('app', 'boot complete');
```

Three plain Dart objects are constructed (`new` is implicit). Each `init()` is an `async` method that may open the Isar database file, register native channel handlers, or request OS permissions. They run sequentially because each one is `await`ed; if you wanted parallel init you would collect the futures and `Future.wait` them. Sequential is fine here — boot is already fast and the order is intentional: DB before anything that might want to read settings, notifications before alarms (because alarms may schedule notifications).

In Spring terms: these are three `@Component` singletons whose `@PostConstruct` methods are being called in dependency order. The reason this is hand-rolled rather than driven by Riverpod is that Riverpod providers are lazy — a provider's factory runs on first read, not on app start. We need these warmed up *before* any UI screen tries to read them.

### `_guard` — per-service failure isolation

```dart
Future<void> _guard(String tag, Future<void> Function() fn) async {
  try {
    await fn();
    AppLogger.I.info(tag, 'ok');
  } catch (e, s) {
    AppLogger.I.error(tag, 'init failed', error: e, stack: s);
  }
}
```

`Future<void> Function()` is Dart's way of declaring `Supplier<Future<Void>>` — a zero-arg function returning a future. The helper logs success or failure but never rethrows. If `IsarService.init()` throws, the app still launches; downstream code that depends on Isar will see a half-initialized service and presumably surface an empty list rather than a crashed app. That tradeoff is deliberate for a personal productivity app: a degraded notes screen beats a launcher icon that bounces.

### `runApp` — mount the tree

```dart
runApp(
  ProviderScope(
    overrides: [
      isarServiceProvider.overrideWithValue(isarService),
      notificationServiceProvider.overrideWithValue(notificationService),
      alarmServiceProvider.overrideWithValue(alarmService),
    ],
    child: const EndlessApp(),
  ),
);
```

`runApp` is the Flutter equivalent of `SpringApplication.run(...)` returning control to the framework. It takes a single root widget and tells the engine "this is your tree." Inside that root we place `ProviderScope`, the Riverpod container. The `overrides` list is how we inject our already-built instances into the DI graph: instead of letting `isarServiceProvider` build a fresh `IsarService` lazily, we say "when anyone reads this provider, return *this specific instance*." That is the same pattern as registering a `@Bean` programmatically in a `@Configuration` class to replace the default auto-wired one — you are pre-supplying the singleton.

`child: const EndlessApp()` is the actual UI. `const` matters: it makes the widget instance compile-time-constant, so Flutter can skip rebuilding it on parent rebuilds. Treat `const` constructors as a free perf win whenever the widget has no varying inputs.

## File: `app.dart`

The root widget. Tiny but load-bearing.

```dart
import 'package:flutter/material.dart';

import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/presentation/screens/splash_screen.dart';

class EndlessApp extends StatelessWidget {
  const EndlessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      theme: buildDarkTheme(),
      home: const SplashScreen(),
    );
  }
}
```

`EndlessApp` extends `StatelessWidget` — a widget that has no mutable state of its own. Spring analogy: it is a `@Configuration` class. It does not hold runtime data; it just declares structure.

`super.key` forwards the optional `Key` parameter to the superclass. Keys are how Flutter tells two same-typed widgets apart across rebuilds; you can usually ignore them for top-level widgets.

`MaterialApp` is the Material Design top-level wrapper. It owns the `Navigator` (route stack), default text styles, theming, and the localization plumbing. Conceptually it is your `DispatcherServlet` plus your `WebMvcConfigurer` plus your default `Locale` resolver, fused into one widget.

- `title: kAppName` — the title shown in the OS task switcher. `kAppName` is a `const String` defined in `app_strings.dart`. The leading `k` is a Flutter community convention for top-level constants.
- `debugShowCheckedModeBanner: false` — removes the red "DEBUG" ribbon in dev builds.
- `theme: buildDarkTheme()` — the design system entrypoint; covered in a later chapter.
- `home: const SplashScreen()` — the very first route, equivalent to your default mapping at `/`. Using `home` (rather than a `routes` map or `onGenerateRoute`) means this app does not use named-route declarative routing here; navigation is imperative via `Navigator.push(...)`.

That is the entire root. No global error boundary widget, no auth gate, no theme provider — just a `MaterialApp` pointing at the splash. The boot-time wiring already happened in `main.dart`.

## File: `splash_screen.dart`

The first screen the user sees. Two responsibilities: render the logo with an entrance animation, and decide where to go next.

### Class declaration

```dart
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}
```

`StatefulWidget` is the second of the two base widget types you met in chapter 00. Where `StatelessWidget` is pure (rebuild produces the same UI from the same inputs), `StatefulWidget` is paired with a `State<T>` object that survives rebuilds and can hold mutable fields like timers, controllers, and counters.

The Spring analogy is imperfect but: `StatelessWidget` is a `@RequestScope` bean (recreated cheaply), `StatefulWidget` is a `@Component`-with-internal-state — the framework keeps the `State` alive across rebuild cycles as long as the widget stays in the tree at the same position.

### `_SplashScreenState.initState`

```dart
class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }
```

`initState` is the lifecycle hook called exactly once when the `State` is first inserted into the tree. It is the `@PostConstruct` of the widget world. We kick off `_navigate()` here and deliberately do not `await` it — `initState` cannot be `async`, and we want the screen to render its logo *now* while the timer ticks in the background.

### `_navigate`

```dart
Future<void> _navigate() async {
  await Future.delayed(const Duration(milliseconds: 2400));
  if (!mounted) return;

  final prefs = await SharedPreferences.getInstance();
  final seen = prefs.getBool('has_seen_onboarding') ?? false;

  if (!mounted) return;
  Navigator.of(context).pushReplacement(
    PageRouteBuilder(
      pageBuilder: (_, __, ___) =>
          seen ? const HomeShell() : const OnboardingScreen(),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 500),
    ),
  );
}
```

Step by step:

- `await Future.delayed(...)` — pause this coroutine for 2.4 seconds without blocking the UI thread. Compare to `Thread.sleep` except non-blocking; the event loop keeps running, animations keep playing.
- `if (!mounted) return;` — the `mounted` flag is `true` while this `State` is still attached to the tree. If the user backgrounded the app and the OS killed the screen, awaiting code resuming would otherwise touch a dead `context` and throw. This idiom appears before every post-await `context` use. It is the Flutter analogue of checking `if (!response.isCommitted())` before writing — except for the widget tree.
- `SharedPreferences.getInstance()` — a plugin that wraps Android `SharedPreferences` / iOS `NSUserDefaults`. Roughly a key-value store backed by a property file. Returns a singleton future.
- `prefs.getBool('has_seen_onboarding') ?? false` — `??` is Dart's null-coalescing operator (same as Java's `Optional.orElse`). First launch returns `null`, which becomes `false`.
- `Navigator.of(context).pushReplacement(...)` — the imperative navigation API. `pushReplacement` swaps the current route out of the stack so the user cannot hit Back and land on the splash again. Think `response.sendRedirect()` but for an in-process route stack.
- `PageRouteBuilder` constructs a route with a custom transition. The `pageBuilder` returns the destination widget — `HomeShell` if onboarding was already done, otherwise `OnboardingScreen`. `transitionsBuilder` wraps the destination in a `FadeTransition` driven by the route's animation. Net effect: 500 ms fade from splash to next screen.

### `build()` — the visible UI

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: kBgPrimary,
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo box
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [kAccentPurple, kAccentPink],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              ...
```

`Scaffold` is the Material page skeleton — it knows how to lay out an app bar, body, FAB, bottom nav, and drawer. Even when (as here) you only use `body`, you want it because it handles status-bar insets and theming.

`Center` + `Column(mainAxisSize: MainAxisSize.min)` centers a vertical stack that shrinks to fit its children. The trio of children is logo, app name, tagline, separated by `SizedBox(height: ...)` spacers — Flutter's idiom for explicit gaps, because there is no CSS margin.

The `Container` builds the rounded 96x96 logo tile with a purple-to-pink gradient and a glow shadow. `kAccentPurple`, `kAccentPink`, `kTextPrimary`, etc., are top-level color constants from `app_colors.dart`. The trailing `.withAlpha(100)` returns a copy of the color with that alpha — Dart objects are largely immutable, so colors clone-on-modify.

### Entrance animations via `flutter_animate`

```dart
)
    .animate()
    .fadeIn(duration: 600.ms, curve: Curves.easeOut)
    .scale(
      begin: const Offset(0.75, 0.75),
      end: const Offset(1.0, 1.0),
      duration: 700.ms,
      curve: Curves.elasticOut,
    ),
```

`.animate()` is an extension method from the `flutter_animate` package. It wraps the preceding widget in an animation controller and lets you chain effects fluently. Here the logo fades in over 600 ms while scaling from 0.75 to 1.0 with an elastic curve. `600.ms` is an `int` extension that produces a `Duration`. The app name and tagline use the same pattern with staggered `delay:` values (350 ms, 600 ms) so they cascade in.

There is no explicit `AnimationController` to manage — `flutter_animate` owns it internally and disposes on widget unmount. This is what "declarative animation" looks like in Flutter: you describe the timeline, the package builds the imperative controller.

## File: `onboarding_screen.dart`

A three-slide intro carousel shown on first launch. Imports include `iconsax` (icon pack), `flutter_animate`, and `shared_preferences`.

### Slide data

```dart
class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  static const _slides = [
    _Slide(
      icon: Iconsax.note_text,
      gradient: [Color(0xFF4C1D95), Color(0xFF7C3AED)],
      title: 'Capture Everything',
      subtitle:
          'Color-coded notes, pinned ideas, and powerful search ...',
    ),
    ...
  ];
```

`_ctrl` is a `PageController`, the equivalent of a horizontal pager controller. It is owned by this `State` and disposed in `dispose()`. `_page` tracks the current slide.

`_slides` is `static const` — a compile-time-constant list of `_Slide` records. `_Slide` is a small private value class declared at the bottom of the file. Spring devs: think of this as `private static final List<Slide> SLIDES = List.of(...)`, except more terse because Dart allows top-level `const` literal lists.

### Navigation actions

```dart
void _next() {
  if (_page < _slides.length - 1) {
    _ctrl.nextPage(
        duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
  } else {
    _finish();
  }
}

void _skip() => _finish();

Future<void> _finish() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('has_seen_onboarding', true);
  if (!mounted) return;
  Navigator.of(context).pushReplacement(
    PageRouteBuilder(
      pageBuilder: (_, __, ___) => const HomeShell(),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 400),
    ),
  );
}
```

`_next` either advances the `PageView` or calls `_finish`. `_skip` is a single-expression arrow function. `_finish` flips the `has_seen_onboarding` preference so the splash will route directly to `HomeShell` on every subsequent launch, then `pushReplacement`s to `HomeShell` with a fade.

`if (!mounted) return;` appears again after the `await prefs.setBool(...)` — same reason as in the splash.

### `dispose`

```dart
@override
void dispose() {
  _ctrl.dispose();
  super.dispose();
}
```

`State.dispose` is the analogue of `@PreDestroy`. Anything holding native resources — animation controllers, page controllers, stream subscriptions, focus nodes — must be disposed here. Forgetting to dispose a `PageController` will leak it; the framework prints a noisy assertion in debug.

### `build`

```dart
final slide = _slides[_page];
final isLast = _page == _slides.length - 1;

return Scaffold(
  backgroundColor: kBgPrimary,
  body: SafeArea(
    child: Column(
      children: [
        Align(
          alignment: Alignment.topRight,
          child: TextButton(
            onPressed: isLast ? null : _skip,
            ...
```

`SafeArea` inset-pads the body so content does not slide under the notch or status bar. The `Column` has four logical regions: skip button, pager, dot indicators, CTA button.

`onPressed: isLast ? null : _skip` — passing `null` to a button's `onPressed` disables the button. This is Flutter's standard idiom for conditional enabling, equivalent to `setDisabled(true)` in Swing.

#### PageView

```dart
Expanded(
  child: PageView.builder(
    controller: _ctrl,
    itemCount: _slides.length,
    onPageChanged: (i) => setState(() => _page = i),
    itemBuilder: (_, i) => _SlidePage(slide: _slides[i]),
  ),
),
```

`Expanded` makes the `PageView` consume all remaining vertical space in the `Column`. `PageView.builder` is the lazy variant: the `itemBuilder` callback is invoked only for visible and adjacent pages, like `RecyclerView.Adapter.onCreateViewHolder`. `onPageChanged` is the swipe listener; we call `setState` so the dot indicators and CTA label refresh.

#### Dot indicators

```dart
Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: List.generate(_slides.length, (i) {
    final isActive = i == _page;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 6,
      height: 6,
      decoration: BoxDecoration(
        color: isActive ? slide.gradient.last : kTextHint,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }),
),
```

`AnimatedContainer` is one of Flutter's "implicit animation" widgets: when any of its properties (width, color, decoration) changes between rebuilds, it tweens to the new value over `duration`. No controller needed. This is how the active dot expands from 6 px to 24 px when you swipe — `setState` triggers a rebuild with new widths, `AnimatedContainer` animates the diff.

#### CTA button

```dart
FilledButton(
  onPressed: _next,
  style: FilledButton.styleFrom(
    backgroundColor: slide.gradient.last,
    ...
  ),
  child: Text(
    isLast ? 'Get Started' : 'Next',
    ...
```

The CTA label and color both depend on `slide` and `isLast`, all derived from `_page`. Click `Next` to advance the pager; click `Get Started` on the last slide to fire `_finish`.

### `_SlidePage` and `_Slide`

```dart
class _SlidePage extends StatelessWidget {
  final _Slide slide;
  const _SlidePage({required this.slide});
  ...
}

class _Slide {
  final IconData icon;
  final List<Color> gradient;
  final String title;
  final String subtitle;
  const _Slide({
    required this.icon,
    required this.gradient,
    required this.title,
    required this.subtitle,
  });
}
```

`_SlidePage` is the per-slide visual: a gradient icon circle, title, subtitle, all with cascading `flutter_animate` entrances. Because it is a `StatelessWidget`, the animations replay every time `PageView.builder` rebuilds it on swipe — that is intentional.

`_Slide` is a small immutable data carrier with a `const` constructor and `final` fields. It is the Dart shape of a Java `record` minus generated `equals`/`hashCode`. The leading underscore makes both classes library-private; they cannot be imported from outside this file.

## File: `home_shell.dart`

The top-level navigation scaffold. Five tabs, one `IndexedStack`, and a hand-rolled bottom bar (no `BottomNavigationBar` widget — they chose custom for finer styling control).

### Class declaration

```dart
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}
```

Note `ConsumerStatefulWidget` rather than `StatefulWidget`. The `Consumer*` variants come from Riverpod and give the `build` method access to a `ref` object — the DI handle. It is the equivalent of a bean that has `@Autowired ApplicationContext` injected. This shell does not yet read any providers in `build()`, but the type is in place so future tabs can.

### Tab state

```dart
class _HomeShellState extends ConsumerState<HomeShell> {
  int _currentIndex = 0;

  static const _screens = [
    NotesListScreen(),
    TasksScreen(),
    RemindersScreen(),
    AlarmsScreen(),
    MoneyScreen(),
  ];

  static const _tabNames = ['notes', 'tasks', 'reminders', 'alarms', 'money'];
```

`_currentIndex` is the selected tab. The five screen widgets are instantiated once as `static const` — they are compile-time constants because each constructor is `const`. This is critical: because they are the same identity across every rebuild, Flutter keeps their underlying `State` objects alive and their scroll positions, text-field contents, and provider subscriptions are all preserved when the user switches tabs and switches back.

`_tabNames` is a parallel array used only for analytics logging in `_onNavTap`.

### Tab switch handler

```dart
void _onNavTap(int i) {
  if (i == _currentIndex) return;
  HapticFeedback.lightImpact();
  AppLogger.I.action('nav', 'tabSwitch',
      data: {'from': _tabNames[_currentIndex], 'to': _tabNames[i]});
  setState(() => _currentIndex = i);
}
```

Guard against double-tap (no-op if the tab is already active), trigger a haptic blip on the device, log the navigation event with structured fields, then `setState` to update the index. `setState` schedules a rebuild of this widget; the `IndexedStack` rerenders with a new `index`.

`HapticFeedback` is a static API from `package:flutter/services.dart` that goes over a platform channel to the native `Vibrator` (Android) or `UIImpactFeedbackGenerator` (iOS).

### `build` — Scaffold + IndexedStack

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: kBgPrimary,
    body: IndexedStack(index: _currentIndex, children: _screens),
    bottomNavigationBar: _BottomNav(
      currentIndex: _currentIndex,
      onTap: _onNavTap,
    ),
  );
}
```

`IndexedStack` is the key widget. It lays out *all* its children, sized to the largest, then paints only the one at `index`. Crucially, the off-screen children remain in the widget tree, so their `State` objects, their subscribed Riverpod providers, and any pending `Future`s stay alive.

Compare to a TabPane in JavaFX where switching tabs would dispose the previous tab's controller: `IndexedStack` is the opposite. The tradeoff is memory — five feature screens live in memory simultaneously — versus instant tab switching with preserved scroll positions. For a five-tab personal app this is the right call.

The `bottomNavigationBar` slot of `Scaffold` is wired to `_BottomNav`, our custom widget. `Scaffold` knows how to leave room for it above the gesture bar and how to draw the safe-area inset.

### `_BottomNav` — the custom tab bar

```dart
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  static const _items = [
    (icon: Iconsax.note_text, label: kNavNotes),
    (icon: Iconsax.task_square, label: kNavTasks),
    (icon: Iconsax.notification, label: kNavReminders),
    (icon: Iconsax.clock, label: kNavAlarms),
    (icon: Iconsax.money_recive, label: kNavMoney),
  ];
```

`_BottomNav` is stateless because it takes the active index and the tap callback as constructor parameters from `_HomeShellState`. `ValueChanged<int>` is a typedef for `void Function(int)` — a standard Flutter shorthand.

`_items` uses Dart 3 **records**: `(icon: ..., label: ...)` is a positional/named-field record literal, similar to a Java `record` but anonymous. Each item exposes `.icon` and `.label`. Lightweight tuples with named fields — handy for tiny config arrays that do not deserve a class.

### Rendering each tab item

```dart
return Container(
  height: kBottomNavHeight,
  decoration: const BoxDecoration(
    color: kBgSecondary,
    border: Border(top: BorderSide(color: kGlassBorder, width: 0.5)),
  ),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    children: List.generate(_items.length, (i) {
      final item = _items[i];
      final isActive = i == currentIndex;
      return GestureDetector(
        onTap: () => onTap(i),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 60,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive
                      ? kAccentPurple.withAlpha(30)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  item.icon,
                  size: kIconMD,
                  color: isActive ? kAccentPurple : kTextHint,
                ),
              ),
              const SizedBox(height: 2),
              Text(item.label, ...),
            ],
          ),
        ),
      );
    }),
  ),
);
```

The bar is a `Container` with a top border (the thin glass line above the tabs). Inside, a `Row` distributes five `GestureDetector`s with `spaceAround`. Each detector:

- `behavior: HitTestBehavior.opaque` — make the whole 60-px-wide column tappable, even on transparent pixels. Default would only fire on non-transparent children.
- `AnimatedContainer` — the active tab's icon sits inside a pill-shaped purple-tinted background. When the active index changes, the background fades in/out over 200 ms because `AnimatedContainer` tweens its `color`.
- `Icon` + `Text` — the icon and label both tint to `kAccentPurple` when active or `kTextHint` when inactive. Because `Text` and `Icon` are not implicitly animated, the color flip is instantaneous; the pill background carries the animated feel.

That is the complete shell. No nested navigators, no per-tab back-stacks — each tab manages its own pushes via the root `Navigator` provided by `MaterialApp`.

## Trace: cold start to home screen

Putting it all together as if you were watching with a profiler. Assume the user has launched the app before (so onboarding is done), running a debug build on a mid-range Android phone:

- **t = 0 ms** — User taps the launcher icon. Android creates a new process and loads `libflutter.so`. The Dart VM spins up its isolate.
- **t = ~150 ms** — `main()` enters. `runZonedGuarded` installs the zone and calls `_bootstrap`. The widget tree does not exist yet; nothing is on screen but the platform splash (the Android adaptive icon).
- **t = ~155 ms** — `WidgetsFlutterBinding.ensureInitialized()` returns. Platform channels are now usable.
- **t = ~160 ms** — `AppLogger.I.init()` opens a log file. First log line: `boot start`.
- **t = ~160 ms** — `FlutterError.onError` and `PlatformDispatcher.instance.onError` are assigned. From this instant on, no uncaught error can escape silently.
- **t = ~165 ms** — `IsarService()` is constructed; `init()` opens the Isar database file. On a phone with the DB already created, this is typically 30–80 ms because it mmaps the file and reads the schema header.
- **t = ~230 ms** — `NotificationService.init()` registers Android notification channels and asks the OS for the current permission state (no UI prompt at this stage).
- **t = ~250 ms** — `AlarmService.init()` wires up `android_alarm_manager_plus` or similar, registers callbacks. Fast.
- **t = ~260 ms** — `runApp(ProviderScope(overrides: [...], child: EndlessApp()))` returns control to the Flutter engine. The engine schedules the first frame.
- **t = ~270 ms** — `EndlessApp.build` runs, returning the `MaterialApp`. `MaterialApp.build` runs, returning a `Navigator` whose first route is `SplashScreen`. `SplashScreen.createState()` runs, then `_SplashScreenState.initState()` runs, kicking off the 2.4-second timer and the `SharedPreferences` read.
- **t = ~290 ms** — First frame paints. The user sees the dark background and the logo. `flutter_animate` begins the fade-in + elastic-scale on the logo, then 350 ms later the "Endless" wordmark, then 600 ms later the tagline.
- **t = ~2700 ms** — Splash's `Future.delayed(2400ms)` resolves. `mounted` is true. `SharedPreferences.getInstance()` returns its cached singleton (fast on second access; ~10–30 ms on first).
- **t = ~2730 ms** — `prefs.getBool('has_seen_onboarding')` returns `true`. `Navigator.pushReplacement` swaps the route. The fade transition runs for 500 ms.
- **t = ~2730 ms** — `HomeShell` is constructed for the first time. Because `_screens` is a `static const` list of five widgets, instantiating `HomeShell` does not yet build the five feature screens — Flutter only builds widgets when their parent's `build` runs and includes them.
- **t = ~2740 ms** — `_HomeShellState.build` runs. `IndexedStack` mounts all five children (`NotesListScreen`, `TasksScreen`, etc.) into the element tree. Each one's `State` is created; each one's `initState` runs; each one's Riverpod `ref.watch(...)` calls fire and start streaming from Isar. This is *not free* — it is the cost of the IndexedStack strategy. Expect this to take 50–200 ms depending on how many providers fan out.
- **t = ~3230 ms** — The fade transition completes. The user sees the Notes tab populated with their notes (or an empty state on first run), the bottom bar with the Notes icon highlighted in purple, and the other four tabs already loaded but invisible behind the stack.

From cold tap to interactive home: a hair over three seconds, of which 2.4 are the deliberate splash dwell. Without the splash dwell, cold start would be closer to ~600 ms.

That is the shell. The next chapter picks up at the feature layer, starting with how the Notes tab actually loads its data from Isar through Riverpod into the UI.
