# Changelog — Endless App

All notable changes to this project will be documented in this file.

---

## [1.0.0] — 2026-06-19

### First public release

#### Features
- **Notes** — Color-coded notes, pin, archive, full-text search, swipe-to-delete
- **Tasks** — Priority levels (Low / Medium / High), due dates, overdue detection,
  drag-to-reorder, swipe-to-delete; tablet layout (side-by-side Active / Completed panels)
- **Reminders** — One-time and recurring (daily / weekly / monthly) push notifications,
  snooze support, upcoming / past grouping
- **Alarms** — Multiple alarms, repeat by day-of-week bitmask, 12-hour display,
  background wake, fires on locked screen
- **Money Manager** — Income & expense tracking, 14 slug-based categories (no DB
  dependency), monthly navigation, savings goals with progress bar and deadline
- **Charts** — Daily spending bar chart (fl_chart) with purple→pink gradient bars;
  expense category donut chart with touch-to-reveal percentage and legend
- **Onboarding** — 3-slide animated PageView (Notes · Tasks · Money), SharedPreferences
  gate so it only shows once, elastic logo splash screen
- **Haptic feedback** — Light impact on nav tap, medium on task checkbox toggle
- **Sora typography** — Google Fonts Sora applied theme-wide
- **Staggered animations** — Note cards fade + slide in via flutter_animate

#### Technical
- Clean Architecture (Domain → Data → Presentation) across all 5 features
- Riverpod state management (AsyncNotifier, StateProvider, FutureProvider)
- Isar NoSQL local database — fully offline-first, no backend
- Android 8.0+ (API 26) minimum; tablet breakpoint at 600 dp
- Adaptive launcher icon (Android 8+): purple background + white "E" vector
- Dark native splash screen (no white flash on app start)
- Release keystore configured via `android/key.properties` (gitignored)
- 56 automated tests: 5 domain unit test suites + 1 widget test suite

#### Platform
- Android 8.0+ (API 26–36+)
- Flutter 3.44.1 · Dart 3.x
