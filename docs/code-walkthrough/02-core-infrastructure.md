# 02 — Core Infrastructure

In a Spring Boot project, before you write controllers and services for a
feature, you usually set up the boring-but-load-bearing stuff: a
`application.yml`, a `DataSourceConfig`, a `WebMvcConfigurer`, a logging
appender, some `@ConfigurationProperties` for theme colors, a couple of
`@Component`s for cross-cutting concerns. That code does not implement any
business rule by itself — it is the chassis everything else bolts onto.

The `lib/core/` folder in this Flutter app is exactly that chassis. It owns:

- **Design tokens** — colors, sizes, strings (the equivalent of a
  `messages.properties` plus a Tailwind config).
- **The theme** — how Material widgets render globally.
- **The database** — Isar boot, file location, and the Riverpod handles other
  layers use to read/write.
- **Service providers** — the Riverpod `Provider` objects that expose
  long-lived singletons. This is the file most analogous to a Spring
  `@Configuration` class.
- **Platform services** — `NotificationService` and `AlarmService` wrap
  Android/iOS native APIs that the rest of the app must not touch directly.
- **A logger** — `AppLogger`, a singleton with a ring buffer, a broadcast
  stream, and rotating file output.
- **Exception types** — small marker classes the data and domain layers throw
  so the UI can pattern-match.
- **Date utilities** — pure helpers, no state.

If you remember one thing from this chapter: nothing in `core/` knows about
notes, tasks, alarms, reminders, or money as *business concepts*. It knows
about them only as *Isar schemas to register*. Feature folders import from
`core/`; `core/` imports back from features only inside `IsarService`, and
only to list the schemas the database engine needs to open.

This chapter walks each file. Excerpts are kept to 5–15 lines; the prose
explains the surrounding shape, the Spring analogy where useful, and the
native-platform handshakes (manifest entries, channels, permissions) that
matter when these services bind to Android or iOS.

---

## Map of core/

| Path | Kind | Role |
| --- | --- | --- |
| `constants/app_colors.dart` | top-level `const` | Color palette, gradients, note-card swatches. |
| `constants/app_sizes.dart` | top-level `const` | Spacing, radii, padding, component heights, icon sizes. |
| `constants/app_strings.dart` | top-level `const` | Hard-coded UI strings (no i18n yet). |
| `theme/app_theme.dart` | factory function | `buildDarkTheme()` returns a `ThemeData`. |
| `database/isar_service.dart` | class | Opens the Isar instance and lists schemas. |
| `database/database_provider.dart` | Riverpod providers | `isarServiceProvider`, `isarProvider`. |
| `services/service_providers.dart` | Riverpod providers | `notificationServiceProvider`, `alarmServiceProvider`. |
| `services/notification_service.dart` | class | Wraps `flutter_local_notifications` + timezone. |
| `services/alarm_service.dart` | class | Wraps the `alarm` package (full-screen ringer). |
| `services/app_logger.dart` | singleton + provider | Ring buffer, broadcast stream, file rotation. |
| `errors/app_exceptions.dart` | classes | Marker exceptions for repos to throw. |
| `utils/date_utils.dart` | top-level functions | Pure date formatting and grouping. |

The mental model:

```
                +-----------------------------+
                |  service_providers.dart     |   (the @Configuration)
                +--------------+--------------+
                               |
       +-----------------------+-----------------------+
       |                       |                       |
       v                       v                       v
NotificationService      AlarmService            IsarService
(local_notifications)   (alarm package)          (Isar, on-disk)
       |                       |                       |
       v                       v                       v
   Android channel       AlarmManager / iOS       <app_documents>
   + iOS settings        background sched.        /default.isar
```

Everything in `core/` is constructed once at app start (`main.dart`) and
overridden into the Riverpod container, so feature code only ever sees the
`Provider<T>` handles.

---

## Design tokens (constants/)

These three files exist for the same reason Spring teams keep a
`Constants.java` or a `messages.properties`: avoid typos, get a single place
to change a color or a label, and make grep meaningful. There is nothing
clever about them.

### `app_colors.dart`

```dart
// Dark theme (primary)
const kBgPrimary = Color(0xFF0A0A0F);
const kBgSecondary = Color(0xFF12121A);
const kBgTertiary = Color(0xFF1A1A26);

// Accent palette
const kAccentPurple = Color(0xFF7C3AED);
const kAccentPink = Color(0xFFEC4899);
const kAccentBlue = Color(0xFF3B82F6);
const kAccentGreen = Color(0xFF10B981);
const kAccentOrange = Color(0xFFF59E0B);
```

Dart conventions worth noting:

- `const` at top level means *compile-time constant*. The `Color` constructor
  is `const`, so these literals are baked into the binary; widgets that use
  them never allocate.
- The `k` prefix is a Flutter community convention for "constant declared
  outside a class". The Spring analogue is `public static final` on an
  interface — same vibe, less ceremony.
- Hex literals are `0xAARRGGBB`. `0xFF` is fully opaque; `0x1A` (used in
  `kGlassBg = Color(0x1AFFFFFF)`) is ~10% white — a glass overlay.

The file also declares two `LinearGradient`s:

```dart
const kGradientPurplePink = LinearGradient(
  colors: [kAccentPurple, kAccentPink],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);
```

These are `const` because every constructor on the path
(`LinearGradient`, `Alignment`, `Color`) is `const`. The result: every
gradient-decorated widget in the app shares one heap object.

`kNoteColors` is a `const List<Color>` used by the color-picker on the note
editor. The order is meaningful — `kNoteColors[0]` is the default
"no-tint" background.

### `app_sizes.dart`

```dart
const kSpaceXS = 4.0;
const kSpaceSM = 8.0;
const kSpaceMD = 16.0;
const kSpaceLG = 24.0;
const kSpaceXL = 32.0;
const kSpaceXXL = 48.0;
```

Flutter sizes are logical pixels (density-independent, same idea as Android
`dp`), and the framework wants `double`s — that is why every value ends in
`.0` instead of being declared as `int`. The constants come in three
families:

- **Spacing/radius** (`kSpace*`, `kRadius*`) — a t-shirt scale that the rest
  of the app uses for `Padding`, `SizedBox`, and `BorderRadius.circular()`.
- **Component sizes** (`kBottomNavHeight`, `kFabSize`, `kAppBarHeight`,
  `kNoteCardMinHeight`) — fixed dimensions for known structural pieces.
- **Icon sizes** (`kIconSM`, `kIconMD`, `kIconLG`) — passed to the
  `Icon(..., size: kIconMD)` widget.

Centralising these means a "make everything tighter" PR is a one-line diff,
not a global find-and-replace.

### `app_strings.dart`

```dart
const kAppName = 'Endless';
const kNavNotes = 'Notes';
const kNavTasks = 'Tasks';
const kNavReminders = 'Reminders';
const kNavAlarms = 'Alarms';
const kNavMoney = 'Money';

const kNewNote = 'New Note';
const kEditNote = 'Edit Note';
const kNoteEmpty = 'No notes yet.\nTap + to create one.';
```

These are the user-facing strings. There is no localisation layer wired up
yet — when there is, this file becomes the source of message keys and the
values move into `.arb` files (Flutter's equivalent of
`messages.properties`). Until then, treat this file as the i18n staging
ground: anything user-visible should already be defined here so that
swapping in `AppLocalizations.of(context).newNote` later is a mechanical
change.

---

## Theme (theme/app_theme.dart)

A `ThemeData` is Flutter's `WebMvcConfigurer` for visuals. It is read from
the nearest `Theme.of(context)`, which Material widgets call internally to
pick fonts, colors, and shapes. The app installs one at the root of the
widget tree.

```dart
ThemeData buildDarkTheme() {
  final base = ThemeData(brightness: Brightness.dark);
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: kBgPrimary,
    fontFamily: GoogleFonts.sora().fontFamily,
    colorScheme: const ColorScheme.dark(
      primary: kAccentPurple,
      secondary: kAccentPink,
      surface: kBgSecondary,
      error: Color(0xFFEF4444),
    ),
```

A few things worth flagging:

- `buildDarkTheme()` is a top-level function. It is not a `const`
  expression because `GoogleFonts.sora()` does network/disk work the first
  time it is called. The function exists so the call site in `main.dart`
  reads as `theme: buildDarkTheme()` rather than as a 40-line literal.
- `GoogleFonts.sora()` returns a `TextStyle` whose font family is "Sora",
  resolved at runtime. The Google Fonts package downloads the TTF on first
  use and caches it in app storage. To force bundling at build time, the
  `pubspec.yaml` can declare the fonts under `flutter.fonts`. This project
  uses the network-cached form.
- `ColorScheme.dark(...)` is the typed bag of semantic colors Material 3
  reads from (primary, secondary, surface, error, plus on-* variants). Most
  widgets pick from this rather than from `colors.dart` directly.
- `useMaterial3: true` opts into Material 3 (M3) defaults — different
  `FilledButton` shapes, dynamic color readiness, the M3 component set.

The bottom half of the function sets per-widget overrides:

```dart
appBarTheme: AppBarTheme(
  backgroundColor: kBgPrimary,
  elevation: 0,
  iconTheme: const IconThemeData(color: kTextPrimary),
  titleTextStyle: GoogleFonts.sora(
    color: kTextPrimary,
    fontSize: 20,
    fontWeight: FontWeight.w700,
  ),
),
floatingActionButtonTheme: const FloatingActionButtonThemeData(
  backgroundColor: kAccentPurple,
  foregroundColor: Colors.white,
),
```

`AppBarTheme`, `FloatingActionButtonThemeData`, `SnackBarThemeData`,
`DialogThemeData` — each is a typed defaults bag that the corresponding
widget reads when the caller does not pass an explicit override. This is
the same pattern as Spring's `WebMvcConfigurer.addInterceptors` — global
defaults that an individual handler can override.

---

## Database (database/)

### `isar_service.dart`

Isar is an embedded NoSQL database written in Rust. For a Spring developer
the closest mental model is "an embedded Mongo with code-generated
typed collections". It opens a single binary file in the app's documents
directory and exposes typed `IsarCollection<T>` handles for CRUD and
queries.

```dart
class IsarService {
  late final Isar _isar;

  Isar get isar => _isar;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [
        NoteModelSchema,
        TaskModelSchema,
        ReminderModelSchema,
        AlarmModelSchema,
        TransactionModelSchema,
        CategoryModelSchema,
        SavingsGoalModelSchema,
      ],
      directory: dir.path,
    );
  }
```

Line by line:

- `late final Isar _isar;` — Dart's "I promise to assign this exactly once,
  before anyone reads it." Equivalent to a `@Lazy @Bean` field that is
  guaranteed to be initialised by the time it is first dereferenced. The
  `late` keyword lets the field be non-nullable without an initialiser.
- `getApplicationDocumentsDirectory()` comes from the `path_provider`
  package. It returns the platform-specific writable documents folder:
  on Android it is the app-private `getFilesDir()` parent under
  `/data/data/<package>/app_flutter`; on iOS it is the app sandbox
  `Documents/` folder visible to iCloud backup. Either way it is per-app
  and persists across app updates.
- `Isar.open([...schemas...], directory: dir.path)` does the actual file
  open. The `*Schema` symbols are generated by `build_runner` from the
  `@collection`-annotated model classes living in each feature's
  `data/models/` folder. If you add a new collection, you must list its
  schema here, otherwise queries on it fail at runtime.
- The file lives at `<documents>/default.isar` (Isar's default name). To
  inspect it on a connected Android device:
  `adb shell run-as <package> ls files/...` — same as inspecting an
  Android Room DB.
- `close()` is wired but rarely called — Isar shuts down cleanly when the
  process dies.

### `database_provider.dart`

```dart
final isarServiceProvider = Provider<IsarService>((ref) {
  throw UnimplementedError('Override isarServiceProvider in main.dart');
});

final isarProvider = Provider<Isar>((ref) {
  return ref.watch(isarServiceProvider).isar;
});
```

Two Riverpod providers, and a pattern you will see repeated for every
async-init singleton in this codebase:

1. **The "stub" provider.** `isarServiceProvider`'s body throws. This is
   intentional. Riverpod cannot `await` inside a `Provider` body, but
   `IsarService.init()` is async — so the container is taught the *type*
   here and the actual instance is supplied in `main.dart` via
   `ProviderScope(overrides: [isarServiceProvider.overrideWithValue(svc)])`
   after `await svc.init()`. If you forget the override, the thrown
   `UnimplementedError` tells you exactly which provider you missed.
2. **The "derived" provider.** `isarProvider` reads the service and exposes
   the raw `Isar` instance. Repositories depend on this one because they do
   not care about the wrapper — they just want collections.

The Spring analogue:

```java
@Configuration
class DataConfig {
  @Bean Isar isar(IsarService svc) { return svc.isar(); }
  @Bean IsarService isarService() {
      // initialized in main(), not here
      throw new IllegalStateException("override at app boot");
  }
}
```

Except Riverpod composes via `ref.watch`, not constructor injection. If
`isarServiceProvider` is later overridden again (in tests, with a fake),
every reader of `isarProvider` automatically picks up the new value.

---

## Service providers (services/service_providers.dart)

```dart
final notificationServiceProvider = Provider<NotificationService>((ref) {
  throw UnimplementedError('Override notificationServiceProvider in main.dart');
});

final alarmServiceProvider = Provider<AlarmService>((ref) {
  throw UnimplementedError('Override alarmServiceProvider in main.dart');
});
```

Same pattern as `database_provider.dart`, same reason: both services need
an async `init()` that touches platform channels, so the real instance is
constructed in `main.dart` and pushed in as a `ProviderScope` override.

Mentally, `service_providers.dart` plus `database_provider.dart` plus the
`appLoggerProvider` at the bottom of `app_logger.dart` together form the
project's `@Configuration` class. There is no central place that lists every
provider — they live next to the type they expose, and `main.dart` knows
which ones need overrides.

If you grep for `overrideWithValue(` in `main.dart` you find:

- `isarServiceProvider`
- `notificationServiceProvider`
- `alarmServiceProvider`

…and nothing else. Everything else (repositories, view-models, the logger)
is constructed synchronously inside its own provider body, so no override
is needed.

---

## NotificationService

`flutter_local_notifications` is the de-facto plugin for showing system
notifications without a server push. It is a `MethodChannel` shim over
`NotificationManager` on Android and `UNUserNotificationCenter` on iOS.
This service hides all that and exposes four methods: `init`,
`requestPermission`, `scheduleReminder`, `cancel`.

### Imports and constants

```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

class NotificationService {
  static const _channelId = 'endless_reminders';
  static const _channelName = 'Reminders';
  static const _channelDesc = 'Endless app reminders and alerts';

  final _plugin = FlutterLocalNotificationsPlugin();
```

- **Two timezone imports.** `tz` is the API (`TZDateTime`, `local`),
  `tz_data` is the static IANA tzdata blob (Africa/Lagos, Europe/Berlin,
  etc.) that must be loaded into memory before any conversion. Without
  `initializeTimeZones()` the call to `tz.local` throws
  `LocationNotFoundException`.
- **Channel constants.** Android 8 (Oreo) introduced *notification
  channels* — user-controllable buckets for sound/vibration/importance.
  Every notification must declare which channel it belongs to, and the
  channel must be registered once at app start. iOS has no equivalent;
  these constants are Android-only in effect.

### init()

```dart
Future<void> init() async {
  tz_data.initializeTimeZones();

  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  await _plugin.initialize(
    const InitializationSettings(android: androidSettings, iOS: iosSettings),
    onDidReceiveNotificationResponse: _onNotificationTap,
  );
```

Step by step:

1. **Timezone init.** Loads the full IANA database. Cheap, ~250 KB of
   bundled assets — done once per process.
2. **Android init settings.** The string `'@mipmap/ic_launcher'` is a
   reference to the launcher icon resource declared in
   `android/app/src/main/res/mipmap-*/ic_launcher.png`. Notifications must
   use a small icon; reusing the launcher is acceptable but not ideal (a
   monochrome silhouette is better — Android tints it on the status bar).
3. **iOS (`Darwin`) init settings.** The three booleans pop the
   alert/badge/sound permission dialog on first launch *if it has not
   been shown yet*. iOS only shows it once — after that you must send the
   user to Settings.
4. **`onDidReceiveNotificationResponse`.** Top-level callback fired when
   the user taps a delivered notification while the app is in the
   foreground or coming back from background (not from a cold start —
   that goes through `getNotificationAppLaunchDetails`).

Then the Android-specific channel registration:

```dart
await _plugin
    .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
    ?.createNotificationChannel(const AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    ));
```

`resolvePlatformSpecificImplementation<T>()` is the plugin's "give me the
typed Android-only API surface, or null on iOS". The `?.` null-aware call
makes the chain a no-op on iOS. `Importance.high` means
"heads-up notification" — pops over the current screen for a few
seconds. The channel is created once; subsequent calls with the same id
are idempotent. **The user can change the importance later in system
settings, and the app cannot override that** — this is the whole point of
channels.

### requestPermission()

```dart
Future<bool> requestPermission() async {
  final android = _plugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  final granted = await android?.requestNotificationsPermission();
  return granted ?? false;
}
```

Android 13 (Tiramisu) added the `POST_NOTIFICATIONS` runtime permission.
On older Android the call returns `true` immediately. On iOS this method
is a no-op because the alert permission was already requested in `init()`
via `DarwinInitializationSettings`. The `?? false` collapses the
`bool?` from a missing platform impl to a concrete `false`.

The `AndroidManifest.xml` must declare:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
```

…otherwise `requestNotificationsPermission()` returns false on Android 13+
and `zonedSchedule` silently falls back to inexact timing on Android 12+.

### scheduleReminder()

```dart
Future<void> scheduleReminder({
  required int id,
  required String title,
  required String? body,
  required DateTime scheduledAt,
}) async {
  final tzDate = tz.TZDateTime.from(scheduledAt, tz.local);
  await _plugin.zonedSchedule(
    id,
    title,
    body,
    tzDate,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId, _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        fullScreenIntent: false,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true, presentBadge: true, presentSound: true,
      ),
    ),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
  );
}
```

The interesting decisions:

- **`tz.TZDateTime.from(scheduledAt, tz.local)`.** Converts a naive
  `DateTime` (which Dart treats as local-clock but does not encode the
  zone) into a zoned `TZDateTime` the plugin can hand to
  `AlarmManager.setExactAndAllowWhileIdle()`. Without this you get
  "notification fires an hour early when the user crosses a DST boundary"
  bugs.
- **`AndroidScheduleMode.exactAllowWhileIdle`.** Equivalent to Android's
  `setExactAndAllowWhileIdle` — fires even in Doze mode (deep sleep after
  the screen has been off for a while). The OS still rate-limits these to
  ~once every 9 minutes per app, but for reminders that is fine. The
  *exact* part requires `SCHEDULE_EXACT_ALARM` in the manifest.
- **`fullScreenIntent: false`.** This is a reminder, not an alarm; we do
  not want it to take over the lock screen. Compare with `AlarmService`
  below which sets `androidFullScreenIntent: true` for exactly the
  opposite reason.
- **`UILocalNotificationDateInterpretation.absoluteTime`.** iOS-only
  flag — interpret the scheduled date as wall-clock-at-that-zone, not as
  "X seconds from now". Pairs with the `TZDateTime`.
- **`id` is `int`, not String.** The notification id is the cancellation
  key. The repository layer reuses the entity's primary key (an
  auto-increment Isar id) so that cancelling a reminder by Isar id is
  identical to cancelling by notification id.

### scheduleRecurring() — note the simplification

```dart
Future<void> scheduleRecurring({
  required int id,
  required String title,
  required String? body,
  required DateTime firstAt,
  required Duration interval,
}) async {
  // Cancel any existing notification with this id before rescheduling
  await cancel(id);
  await scheduleReminder(id: id, title: title, body: body, scheduledAt: firstAt);
}
```

The interval parameter is currently ignored — only the first occurrence is
scheduled. True recurring notifications (daily/weekly) would use
`_plugin.zonedSchedule(..., matchDateTimeComponents: ...)` or
`periodicallyShow`. The reminder feature's repo handles "recurring" at the
domain level by rescheduling the next occurrence after each fire.

### cancel / cancelAll / tap callback

```dart
Future<void> cancel(int id) => _plugin.cancel(id);
Future<void> cancelAll() => _plugin.cancelAll();

void _onNotificationTap(NotificationResponse response) {
  // Navigation handled by the app shell when foregrounded
}
```

`cancel` removes both pending (scheduled-but-not-fired) and delivered
notifications for that id. `_onNotificationTap` is intentionally empty —
the app does not deep-link from a notification payload; tapping just
brings the app to foreground, and the user lands on whatever screen they
were on. If deep linking is added later, this is the seam.

---

## AlarmService

`NotificationService` is for gentle "ping, you should look at this".
`AlarmService` is for "this is an alarm clock and it must wake the user up
even if the phone is silent and the app is killed". The two services use
*different* native plumbing — `flutter_local_notifications` and the `alarm`
package — because Android treats them as different beasts.

```dart
import 'package:alarm/alarm.dart';
import '../../features/alarms/domain/entities/alarm_entity.dart';

class AlarmService {
  Future<void> init() async {
    await Alarm.init(showDebugLogs: false);
  }
```

`Alarm.init()` boots the package's foreground service and registers the
background isolate that wakes up at ring time to play the audio. On
Android this is a foreground service with a sticky notification (required
by Android 14 to keep playing audio with the screen off). On iOS it
schedules a high-priority local notification plus a background audio
session — the only mechanism iOS allows for "ring at a specific time even
if the app is suspended".

### scheduleAlarm()

```dart
Future<void> scheduleAlarm(AlarmEntity alarm) async {
  final now = DateTime.now();
  var ringAt = DateTime(now.year, now.month, now.day, alarm.hour, alarm.minute);

  // If time already passed today, schedule for tomorrow
  if (ringAt.isBefore(now)) {
    ringAt = ringAt.add(const Duration(days: 1));
  }

  await Alarm.set(
    alarmSettings: AlarmSettings(
      id: alarm.id,
      dateTime: ringAt,
      assetAudioPath: alarm.soundAsset,
      loopAudio: true,
      vibrate: true,
      warningNotificationOnKill: true,
      androidFullScreenIntent: true,
      notificationSettings: NotificationSettings(
        title: alarm.label.isEmpty ? 'Alarm' : alarm.label,
        body: 'Tap to dismiss',
        stopButton: 'Stop',
        icon: 'mipmap/ic_launcher',
      ),
    ),
  );
}
```

Walking through:

- **Time math.** `AlarmEntity` carries `hour` and `minute` as plain ints
  (the user picked "7:30 AM"). The service composes a real `DateTime`
  using today's date, and if today's slot already passed, rolls to
  tomorrow. There is no repeat handling here — repeat is done by the
  alarms repository, which re-schedules after the alarm fires.
- **`assetAudioPath: alarm.soundAsset`.** Path inside the bundled assets,
  e.g. `assets/sounds/classic.mp3`. Declared in `pubspec.yaml` under
  `flutter.assets`. The `alarm` package handles loading and decoding.
- **`loopAudio: true`.** Loop the file until the user dismisses. For
  a 5-second ringtone this is mandatory.
- **`vibrate: true`.** Vibrate in parallel with audio. On Android requires
  the `VIBRATE` permission in the manifest (usually included by default).
- **`warningNotificationOnKill: true`.** If the user swipes the app away
  from recents, the package posts a warning notification reminding them
  alarms will not fire. Pure Android-ism — iOS does not allow detecting a
  task swipe.
- **`androidFullScreenIntent: true`.** This is the key bit. Causes the
  alarm notification to launch a full-screen activity even on the lock
  screen, which is how the OS distinguishes a "real" alarm from a
  reminder. Requires `USE_FULL_SCREEN_INTENT` in the manifest, and on
  Android 14+ requires the app to be a "calendar/alarm app" or the user
  to grant it manually in settings.
- **`stopButton: 'Stop'`.** Adds an inline action button on the
  notification so the user can stop without entering the app.

### Control surface

```dart
Future<void> stopAlarm(int id) => Alarm.stop(id);
Future<void> stopAll() => Alarm.stopAll();
Future<bool> isRinging(int id) => Alarm.isRinging(id);
```

`Alarm.isRinging(id)` is polled by the alarm-ringing screen to know
whether to keep showing the dismiss UI or pop itself off the navigation
stack. There is no callback equivalent — the package exposes a
`Alarm.ringStream` you could subscribe to, but this app uses the polling
form.

---

## AppLogger

In a Spring app you would reach for SLF4J + Logback, get a `RollingFileAppender`,
an in-memory ring appender for the actuator, and call it a day. Dart has
nothing built in beyond `dart:developer.log` (which writes to the IDE
console). `AppLogger` is the project's hand-rolled equivalent: an
in-memory ring buffer for the in-app log viewer, a broadcast stream so
the viewer can update live, and a rotating file on disk for export.

### Levels and the entry type

```dart
enum LogLevel { debug, info, warn, error, action }

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String tag;
  final String message;
  final Map<String, Object?>? data;
  final String? error;
  final String? stack;

  const LogEntry({
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
    this.data,
    this.error,
    this.stack,
  });
```

`LogLevel` is standard except for `action` — a separate level used for
user-initiated events (button taps, navigations). Splitting actions from
info lets the in-app viewer offer a "show only user actions" filter that
behaves like a thin analytics view.

`LogEntry` is immutable (all `final`, `const` constructor). The `data` map
holds arbitrary key-value context — Spring developers can think of this
as MDC contents.

```dart
String get levelName => switch (level) {
      LogLevel.debug => 'DEBUG',
      LogLevel.info => 'INFO',
      LogLevel.warn => 'WARN',
      LogLevel.error => 'ERROR',
      LogLevel.action => 'ACTION',
    };
```

Dart's exhaustive `switch` expression — the compiler errors if a new
`LogLevel` value is added without a branch. Same compile-time safety as a
Java sealed class + pattern match.

`toJson()` and `toLine()` serialise the entry to JSON (for export) and to
a human-readable line (for file + IDE console). The line format is
ISO-8601 timestamp, padded level, tag, message, optional JSON-encoded
data, optional `| err=...`, optional stack on a new line. Stable enough
for `grep` and `awk` after export.

### The singleton

```dart
class AppLogger {
  AppLogger._();
  static final AppLogger I = AppLogger._();

  static const int _bufferLimit = 500;
  static const int _rotateBytes = 1024 * 1024; // 1 MB

  final Queue<LogEntry> _buffer = Queue();
  final StreamController<LogEntry> _controller = StreamController.broadcast();

  File? _file;
  bool _initialized = false;

  Stream<LogEntry> get stream => _controller.stream;
  List<LogEntry> get buffer => List.unmodifiable(_buffer);
  File? get currentFile => _file;
```

Patterns to recognise:

- **`AppLogger._()` + `static final I = ...`** — Dart's idiomatic
  singleton. The private constructor blocks external instantiation; `I` is
  the single instance. This is exactly `@Component` + default scope in
  Spring: one bean per ApplicationContext. **`AppLogger.I` is the
  singleton bean.**
- **`Queue<LogEntry>` ring buffer.** A `Queue` is a doubly-linked list in
  Dart. The class adds to the tail and evicts from the head when length
  exceeds 500 — classic bounded queue, O(1) on both ends.
- **`StreamController.broadcast()`.** Multi-subscriber stream. The
  in-app log viewer subscribes; if no one is listening, events are
  dropped (broadcast streams do not buffer for late subscribers). The
  ring buffer covers history; the stream covers live updates.
- **`List.unmodifiable(_buffer)`.** Returns an unmodifiable *view*, not a
  copy. Callers cannot mutate the buffer, but they still see new entries
  appended on the next read. For a UI viewer rebuilding on stream events
  this is exactly the right contract.
- **`_file: File?`** — nullable because `init()` can fail (no permissions,
  no disk). The logger must still work in memory in that case.

### init()

```dart
Future<void> init() async {
  if (_initialized) return;
  try {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/logs');
    if (!await dir.exists()) await dir.create(recursive: true);
    _file = File('${dir.path}/app.log');
    if (!await _file!.exists()) await _file!.create();
    _initialized = true;
    info('logger', 'logger ready', data: {'path': _file!.path});
  } catch (e, s) {
    // Logging must never crash the app — fall back to in-memory only.
    dev.log('AppLogger init failed: $e', stackTrace: s, name: 'logger');
  }
}
```

- Idempotent (`if (_initialized) return`) — safe to call twice.
- Creates `<documents>/logs/` and `app.log` if missing.
- Whole body is in a `try/catch` so that a failure to mkdir or create the
  file (e.g. read-only storage on some flaky devices) leaves
  `_file == null` and the logger keeps appending to the ring buffer only.
- Catches with `(e, s)` — Dart's two-arg catch gives you both the
  exception and the stack trace.

### Public log methods

```dart
void debug(String tag, String message, {Map<String, Object?>? data}) =>
    _log(LogLevel.debug, tag, message, data: data);

void info(String tag, String message, {Map<String, Object?>? data}) =>
    _log(LogLevel.info, tag, message, data: data);

void warn(String tag, String message, {Map<String, Object?>? data}) =>
    _log(LogLevel.warn, tag, message, data: data);

void error(
  String tag,
  String message, {
  Object? error,
  StackTrace? stack,
  Map<String, Object?>? data,
}) =>
    _log(LogLevel.error, tag, message,
        data: data, error: error?.toString(), stack: stack?.toString());

void action(String tag, String name, {Map<String, Object?>? data}) =>
    _log(LogLevel.action, tag, name, data: data);
```

Thin convenience wrappers over `_log`. The `=>` syntax is Dart's
expression-bodied function. The `tag` is conventionally the feature or
class name (`'notes'`, `'NotesRepository'`) — same role as SLF4J's logger
name.

### The hot path: `_log`

```dart
void _log(
  LogLevel level,
  String tag,
  String message, {
  Map<String, Object?>? data,
  String? error,
  String? stack,
}) {
  final entry = LogEntry(
    timestamp: DateTime.now(),
    level: level,
    tag: tag,
    message: message,
    data: data,
    error: error,
    stack: stack,
  );

  _buffer.addLast(entry);
  while (_buffer.length > _bufferLimit) {
    _buffer.removeFirst();
  }
  if (!_controller.isClosed) _controller.add(entry);

  if (kDebugMode) {
    dev.log(entry.toLine(), name: tag, level: _devLevel(level));
  }

  // Fire-and-forget file write — never await in callers.
  unawaited(_appendToFile(entry));
}
```

This method is called from everywhere in the app, so it must be cheap and
never throw. The steps:

1. Build the immutable `LogEntry`.
2. Append to the ring buffer; evict head while overflowing.
3. Push to the broadcast stream if the controller is open (the controller
   is never closed in this app, but the guard makes the call safe during
   teardown).
4. In debug builds (`kDebugMode` is a compile-time constant Flutter sets),
   also echo to `dart:developer.log`. This is what shows up in the IDE
   logcat panel with proper level coloring. In release builds this branch
   is dead-code-eliminated.
5. **Fire-and-forget file write.** `unawaited(...)` tells the analyzer
   "I am intentionally not awaiting this `Future`." The semantic effect:
   the file write happens on the event loop's next turn while the caller
   returns immediately. Without `unawaited`, `_log` would have to be
   `async`, every call site would have to be `await
   logger.info(...)`, and a slow disk would block every UI interaction.
   The trade-off is that if the app crashes between the `_log` call and
   the actual write, the last few lines are lost. For a usage logger,
   that is acceptable.

### File rotation

```dart
Future<void> _appendToFile(LogEntry entry) async {
  final f = _file;
  if (f == null) return;
  try {
    await f.writeAsString('${entry.toLine()}\n',
        mode: FileMode.append, flush: false);
    // Rotate if file grew past the limit.
    final len = await f.length();
    if (len > _rotateBytes) await _rotate();
  } catch (_) {
    // Swallow — logger failures must never break the app.
  }
}

Future<void> _rotate() async {
  final f = _file;
  if (f == null) return;
  try {
    final rotated = File('${f.path}.1');
    if (await rotated.exists()) await rotated.delete();
    await f.rename(rotated.path);
    _file = File(f.path);
    await _file!.create();
  } catch (_) {/* ignore */}
}
```

- **Append mode, no flush.** `FileMode.append` opens for append-only;
  `flush: false` skips fsync, leaving the OS page cache to do the right
  thing. Logback's behavior with `immediateFlush=false`.
- **Rotation policy.** When `app.log` exceeds 1 MB, rename it to
  `app.log.1` (deleting any previous rotation) and create a fresh
  `app.log`. So the on-disk total is bounded at ~2 MB. There is no
  hour/day-based rotation; size-only.
- **Every error path is swallowed.** This is intentional and stated in
  the comment: the logger is allowed to lose data, but is *never* allowed
  to crash the app it is observing.

### Export and clear

```dart
Future<String> exportAsText() async {
  final f = _file;
  if (f == null || !await f.exists()) {
    return _buffer.map((e) => e.toLine()).join('\n');
  }
  return f.readAsString();
}

Future<void> clear() async {
  _buffer.clear();
  final f = _file;
  if (f != null && await f.exists()) {
    await f.writeAsString('');
  }
  final rotated = File('${f?.path}.1');
  if (await rotated.exists()) await rotated.delete();
  info('logger', 'logs cleared');
}
```

`exportAsText` is what the in-app log viewer's "share" button calls. It
prefers the file (full history up to 2 MB) and falls back to the
in-memory buffer when no file exists. `clear` empties both the buffer
and the on-disk files, then logs a "cleared" entry so the next time you
open the viewer you see when the wipe happened.

### Riverpod handle

```dart
final appLoggerProvider = Provider<AppLogger>((ref) => AppLogger.I);
```

Even though `AppLogger.I` is a true Dart singleton, the project exposes
it through a `Provider` so:

- View-models and repositories `ref.watch(appLoggerProvider)` instead of
  importing the static field. Same DI ergonomics as the rest of the app.
- Tests can `overrideWithValue(...)` with a fake logger.

No async init is needed at the provider level because `AppLogger.init()`
is called from `main.dart` before the `ProviderScope` is built; once
initialised, `AppLogger.I` is just a value.

---

## App exceptions

```dart
class DatabaseException implements Exception {
  final String message;
  final Object? cause;
  const DatabaseException(this.message, {this.cause});
  @override
  String toString() => 'DatabaseException: $message';
}

class ValidationException implements Exception {
  final String message;
  const ValidationException(this.message);
  @override
  String toString() => 'ValidationException: $message';
}

class AlarmException implements Exception {
  final String message;
  final Object? cause;
  const AlarmException(this.message, {this.cause});
  @override
  String toString() => 'AlarmException: $message';
}

class PermissionException implements Exception {
  final String message;
  const PermissionException(this.message);
  @override
  String toString() => 'PermissionException: $message';
}
```

Four small marker classes. Notes:

- **`implements Exception`, not `extends`.** Dart's `Exception` is an
  abstract interface, not a base class. `implements` is the idiomatic
  way.
- **`const` constructors.** Allows `throw const DatabaseException('boom')`
  with no allocation. Useful in hot paths and pattern-matching `catch`
  clauses.
- **`cause`** on `DatabaseException` and `AlarmException` captures the
  underlying platform error (the `IsarError`, the `PlatformException`) so
  the logger can include it in `data: {'cause': '$e'}` without the UI
  having to know about it.

There is no global exception handler in this app — exceptions are caught
at the view-model boundary, mapped to an error state on a `StateNotifier`,
and the UI shows `kError` ("Something went wrong. Please try again."). The
catch sites use `on DatabaseException catch (e)` to pattern-match these
types — Spring's `@ControllerAdvice` with `@ExceptionHandler` is the
closest analogue, but without the framework glue.

---

## Date utilities

```dart
import 'package:intl/intl.dart';

String formatDate(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);
  final diff = today.difference(target).inDays;

  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  if (diff < 7) return DateFormat('EEEE').format(date);
  if (date.year == now.year) return DateFormat('d MMM').format(date);
  return DateFormat('d MMM yyyy').format(date);
}
```

Pure, stateless, no side effects. The Spring analogue would be a
`@UtilityClass` (Lombok) or a static helper.

The logic:

- Same calendar day → `Today`.
- One day before today → `Yesterday`.
- Within the last week → weekday name (`Wednesday`).
- Same calendar year → `d MMM` (`14 Mar`).
- Otherwise → `d MMM yyyy` (`14 Mar 2024`).

`DateFormat` patterns come from ICU: `EEEE` = full weekday, `d` = day
of month no leading zero, `MMM` = three-letter month, `yyyy` = four-digit
year. Locale defaults to the device locale.

The truncation to midnight (`DateTime(now.year, now.month, now.day)`) is
load-bearing — without it, `today.difference(target).inDays` would mix
time-of-day into the day count and "an hour ago" could end up labelled
"Yesterday".

```dart
bool isToday(DateTime date) {
  final now = DateTime.now();
  return date.year == now.year && date.month == now.month && date.day == now.day;
}
```

A faster path used in hot loops where `formatDate` would be overkill (the
notes list checks `isToday` per pinned-note header).

```dart
Map<String, List<T>> groupByDate<T>(List<T> items, DateTime Function(T) getDate) {
  final result = <String, List<T>>{};
  for (final item in items) {
    final key = formatDate(getDate(item));
    result.putIfAbsent(key, () => []).add(item);
  }
  return result;
}
```

Generic grouping. The caller supplies a date extractor —
`groupByDate(notes, (n) => n.updatedAt)` returns
`{ 'Today': [...], 'Yesterday': [...], 'Wednesday': [...] }`. The list
order is preserved because Dart's `Map` is insertion-ordered (same as
Java's `LinkedHashMap`, opposite of Java's `HashMap`). The view layer
iterates the entries in order and emits a sticky header per key.

`putIfAbsent` is the standard idiom for "get-or-create-list" — Java's
`computeIfAbsent` with the same semantics.

---

That is the whole chassis. The next chapter starts on the first feature
folder, `features/notes/`, which is the simplest of the five and shows
the Clean Architecture layout in its most reduced form: entity, model,
repository, view-model, screen, widgets. Every feature after that reuses
the same shape — only the domain rules change.
