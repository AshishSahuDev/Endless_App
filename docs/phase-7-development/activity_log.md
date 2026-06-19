# Phase 7 — Development Activity Log
**Project:** Endless App | **Developer:** Ashish Sahu | **Started:** 2026-06-18

---

## Sprint Summary

| Sprint | Feature | Status | Commit | Date |
|---|---|---|---|---|
| Sprint 1 | Notes | ✅ Complete | Initial commit | 2026-06-18 |
| Sprint 2 | Tasks (Android 8+ · tablet) | ✅ Complete | feat(sprint2) | 2026-06-18 |
| Sprint 3 | Reminders + Alarms | ✅ Complete | feat(sprint3) | 2026-06-18 |
| Sprint 4 | Money Manager | ✅ Complete | feat(sprint4) | 2026-06-18 |
| Sprint 5 | Charts | ✅ Complete | feat(sprint5) | 2026-06-19 |
| Sprint 6 | UI Polish | ✅ Complete | feat(sprint6) | 2026-06-19 |
| Sprint 7 | QA + Release | ✅ Complete | feat(sprint7) | 2026-06-19 |

---

## Session Log

### 2026-06-18 — Session 1

**Sprint 1 — Notes**
- Clean Architecture scaffold: domain entities, repositories, use cases
- NoteModel (Isar) + build_runner codegen
- Riverpod providers: `notesProvider` (AsyncNotifier), `noteSearchResultsProvider`
- NoteEditorScreen with auto-save, color picker, pin toggle
- Notes list: glass cards, color backgrounds, search overlay, swipe-to-delete
- Fix: `AsyncNotifierBase.update` conflict → renamed method to `save`
- Fix: `Iconsax.pin` doesn't exist → used `Icons.push_pin`

**Sprint 2 — Tasks (Android 8+ · Tablet)**
- `minSdk = 26` in `build.gradle.kts` (Android 8.0 support)
- Task entity with Priority enum (low/medium/high), sortOrder, isOverdue getter
- TaskModel Isar collection, repository impl, use cases (CRUD + reorder)
- TasksScreen: 600dp tablet breakpoint → phone = single column tabs, tablet = side-by-side panels
- ReorderableListView with `onReorderItem` (Flutter 3.41+ API — no manual index adjustment needed)
- Fix: `int?` → `int` type annotation for tab variable
- Fix: `const AppBar` with non-const children removed

**Sprint 3 — Reminders + Alarms**
- AndroidManifest: POST_NOTIFICATIONS, SCHEDULE_EXACT_ALARM, WAKE_LOCK, RECEIVE_BOOT_COMPLETED
- NotificationService: channel creation on init for Android 8+; `uiLocalNotificationDateInterpretation` required param added
- AlarmService: rewritten for alarm v4.1.1 async API (`Alarm.getAlarms()`, `Alarm.stopAll()`, `Alarm.isRinging(id)`, `ringStream` is a StreamController not ValueNotifier)
- Reminder entity: RecurringInterval enum, `isUpcoming`/`isPast` getters
- AlarmEntity: bitmask `repeatDays`, `timeString` (12h AM/PM), `repeatLabel` computed getters
- RemindersScreen + AlarmsScreen with full CRUD UI
- Fix: `Switch.activeColor` deprecated → `activeThumbColor`
- Fix: `NotificationDetails` made const via static const channel strings

**Sprint 4 — Money Manager**
- Domain: MoneyTransaction, MonthlySummary (balance + expenseByCategory), SavingsGoal entities
- Repository interfaces + use cases (AddTransaction, DeleteTransaction, GetMonthlySummary)
- Data: TransactionModel + SavingsGoalModel Isar collections with codegen
- TransactionLocalDatasource + SavingsGoalLocalDatasource
- Slug-based category seed (`kDefaultExpenseCategories`, `kDefaultIncomeCategories`) — never stored in DB for stability across reinstalls
- Providers: `selectedMonthProvider` (month navigation), `monthlySummaryProvider` (FutureProvider), TransactionsNotifier, SavingsGoalsNotifier
- Fix: `_SelectedMonth` made public → `SelectedMonth` so widgets can construct it
- UI widgets:
  - `SummaryCard`: gradient card (purple→pink), month nav arrows, income/expense chips, skeleton loader
  - `TransactionCard`: dismissible swipe-to-delete, category icon+color, amount with +/- sign
  - `AddTransactionSheet`: amount field, expense/income toggle, category grid picker, note, date picker
  - `SavingsGoalCard`: progress bar, deadline label, add-funds button
  - `savings_goal_sheet.dart`: CreateGoalSheet + AddFundsSheet
  - `MoneyScreen`: TabBar (Transactions | Goals), FAB switches action based on active tab

**Sprint 5 — Charts**
- `MonthlySummary.dailyExpenses` getter added (Map<int,double> keyed by day-of-month)
- `ExpenseBarChart`: fl_chart `BarChart` — daily spending bars with purple→pink gradient, day labels at 1/10/20/last, tooltip on tap; hidden for months with no expenses
- `CategoryPieChart`: fl_chart donut `PieChart` — tap section to reveal %, total expense in center, color-dot legend beside chart
- `MoneyScreen` Transactions tab: charts scrolled as first `ListView` item when month has expenses; both charts stacked above transaction list

---

## Known Issues / Blockers

- AVD emulator not set up (android-36 system image not downloaded) — UI not yet tested on device

---

**Sprint 6 — UI Polish**
- `SplashScreen`: animated logo (elastic scale-in + glow shadow), app name slides up, tagline fades in; checks SharedPreferences → routes to OnboardingScreen or HomeShell
- `OnboardingScreen`: 3-slide PageView (Notes · Tasks · Money), gradient icon circles with glow, staggered text animations, animated dot indicators, Next/Get Started CTA; saves `has_seen_onboarding` on finish
- `HomeShell` extracted from `app.dart` → `core/navigation/home_shell.dart` (public) to avoid circular import with onboarding screens
- Google Fonts Sora applied via `buildDarkTheme()` as default `fontFamily`; removed broken Sora font asset declaration from pubspec (files were absent)
- Note cards: staggered `fadeIn + slideY` via `flutter_animate` (40ms delay per card)
- Bottom nav: `AnimatedContainer` pill highlight on active tab (200ms transition)
- Haptic: `lightImpact()` on nav tap, `mediumImpact()` on task checkbox toggle

---

**Sprint 7 — QA + Release**
- **56 tests, 0 failures** across 7 test files:
  - 5 domain unit test files: Note, Task, MonthlySummary, SavingsGoal, AlarmEntity
  - 1 widget test file: SavingsGoalCard (7 tests covering render, callbacks, completion state)
  - 1 smoke test
- Android release signing: `build.gradle.kts` updated with Kotlin DSL Properties-based keystore config; falls back to debug signing when `key.properties` absent (CI-safe)
- `android/key.properties.example` template added; `key.properties` already gitignored
- Release checklist document: `docs/phase-7-development/release_checklist.md`
  - keytool commands for keystore generation
  - Play Store submission checklist (screenshots, content rating, privacy policy, data safety form)
  - Post-submission monitoring guidance
- README Phase 7 updated to ✅ Complete

---

---

**Phase 8 — Release**
- **Keystore**: `endless-release.jks` generated via keytool (CN=Ashish Sahu, OU=Dev, O=Endless App); stored at `android/keystore/` (gitignored); `android/key.properties` created with credentials
- **Release signing**: `build.gradle.kts` updated to load `key.properties` via `rootProject.file()` with debug fallback for CI
- **Adaptive launcher icon**: white "E" vector foreground (`ic_launcher_foreground.xml`) on purple (#7C3AED) background; `ic_launcher.xml` + `ic_launcher_round.xml` in `mipmap-anydpi-v26/` for API 26+
- **Dark native splash**: `splash_background: #0A0A0F` in `colors.xml`; `launch_background.xml` references color resource (no white flash); `LaunchTheme` parent → `Theme.Black.NoTitleBar`
- **CHANGELOG.md**: v1.0.0 documented with full feature list, technical stack, and platform support
- **Git tag**: `v1.0.0` pushed to `origin` — commit `7972f93`
- GitHub: https://github.com/AshishSahuDev/Endless_App

---

## Project Status

**Phase 8 — Release: COMPLETE**
App is production-ready. All code is clean (`flutter analyze`: 0 issues), 56 tests pass, keystore configured, adaptive icon and dark splash implemented, v1.0.0 tagged on GitHub.

Next step: `flutter build appbundle --release` → upload AAB to Google Play Console.
