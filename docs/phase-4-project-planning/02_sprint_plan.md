# Sprint Plan — 7 Sprints × 2 Weeks
**Project:** Endless App | **Version:** 1.0 | **Date:** 2026-06-03 | **Author:** Ashish Sahu

---

## Sprint Overview

| Sprint | Feature | Duration | Stories | Hours |
|---|---|---|---|---|
| Sprint 1 | Onboarding + Notes | Weeks 1–2 | US-001,002,004,010,011,012,020–028 | 20h |
| Sprint 2 | Tasks / Lists | Weeks 3–4 | US-030–037 | 16h |
| Sprint 3 | Alarms + Reminders | Weeks 5–6 | US-040–044, US-050–055 | 18h |
| Sprint 4 | Money Manager Core | Weeks 7–8 | US-060–066, US-071, US-075, US-081 | 20h |
| Sprint 5 | Money Manager Charts + Goals | Weeks 9–10 | US-067–070, US-072–074, US-076 | 18h |
| Sprint 6 | UI Polish + Security | Weeks 11–12 | US-002,011,035,074,080,082,083 | 16h |
| Sprint 7 | QA + Testing + Release Prep | Weeks 13–14 | All regression | 20h |

---

## Sprint 1 — Onboarding + Notes

**Goal:** Working app skeleton + full Notes feature on Android emulator

**Week 1 (Dev Setup + Onboarding):**
- Day 1–2: Install Flutter, set up project scaffold, configure pubspec.yaml, run hello world
- Day 3: Set up IsarService, AppSettingsModel, seed logic
- Day 4: Build 3-screen onboarding (splash → welcome slides → theme pick)
- Day 5: Build bottom navigation bar with animated pill; home dashboard skeleton

**Week 2 (Notes Feature):**
- Day 6–7: NoteModel, NoteRepository (Isar impl), all use cases, Riverpod providers
- Day 8: Notes list screen — grid layout, color cards, pin badge, empty state
- Day 9: Note editor screen — title/body fields, color picker, pin toggle, FAB save
- Day 10: Archive view, search screen, swipe-to-delete gesture

**Definition of Done:**
- [ ] Can create, edit, delete, pin, archive, and search notes
- [ ] Color-coded note cards display correctly in dark mode
- [ ] Notes persist after app restart (Isar confirmed)
- [ ] No crashes on Android emulator API 34
- [ ] All screens visible in both dark and light theme

**Risks:**
- Flutter learning curve may slow Day 1–2 — mitigation: follow flutter.dev codelabs first
- Rich text editor (Quill delta) complexity — fallback: plain text in Sprint 1, rich text in Sprint 6 polish

---

## Sprint 2 — Tasks / Lists

**Goal:** Full Tasks module with categories, priorities, and swipe gestures

**Week 3 (Tasks Core):**
- Day 1–2: TaskModel, TaskCategoryModel, Isar setup, seed default categories
- Day 3: TaskRepository, use cases (create, complete, delete, reorder)
- Day 4: Riverpod providers, task list screen with filter tabs (All/Active/Completed)
- Day 5: Task card UI — priority color dot, due date chip, checkbox

**Week 4 (Tasks UX):**
- Day 6: Create task bottom sheet — title, priority selector, due date picker, category picker
- Day 7: Swipe-to-complete gesture (flutter_slidable) with haptic feedback
- Day 8: Drag-and-drop reorder (drag_and_drop_lists package)
- Day 9: Category management screen — create, rename, delete custom categories
- Day 10: Filter by category, overdue task highlighting, empty states

**Definition of Done:**
- [ ] Can create tasks with title, priority, due date, category
- [ ] Swipe right to complete, swipe left to delete
- [ ] Drag and drop reordering works smoothly
- [ ] Filter tabs show correct counts
- [ ] Completed tasks auto-hide after 30 days (logic tested)

**Risks:**
- Drag-and-drop library may have compatibility issues — test early on Day 8
- Complex filter/sort logic — keep queries simple, optimize in Sprint 7

---

## Sprint 3 — Alarms + Reminders

**Goal:** Reliable alarms (fires in background) + push notification reminders

**Week 5 (Alarms):**
- Day 1: AlarmModel, Isar setup, alarm package integration
- Day 2: Alarm list screen — time display, label, toggle switch, days chips
- Day 3: Create/edit alarm screen — time picker, label, sound selector, repeat days
- Day 4: Wire up `alarm` package — schedule, cancel, update
- Day 5: Active alarm screen — full-screen dismiss + snooze; test on physical device

**Week 6 (Reminders):**
- Day 6: ReminderModel, flutter_local_notifications setup (Android channels + iOS permissions)
- Day 7: Reminder list screen + create/edit screen
- Day 8: One-time reminder scheduling, snooze on notification action
- Day 9: Recurring reminder logic (daily, weekly, bi-weekly, monthly re-scheduling)
- Day 10: Link reminder to note/task (deep link tapping notification opens linked item)

**Definition of Done:**
- [ ] Alarm fires with sound on Android emulator when app is backgrounded
- [ ] Alarm fires when app is completely closed (test via recent apps → swipe away)
- [ ] Enable/disable toggle persists correctly
- [ ] Push notification appears for reminders at correct scheduled time
- [ ] Recurring reminders re-schedule themselves after firing

**Risks:**
- **HIGH RISK:** Android background alarm behavior — request `SCHEDULE_EXACT_ALARM` permission + battery optimization exemption; test on API 26 (minimum target)
- iOS alarm testing requires Mac/MacInCloud — defer to Sprint 7 if needed

---

## Sprint 4 — Money Manager Core

**Goal:** Log transactions, view balance, set budgets, receive alerts

**Week 7 (Transactions):**
- Day 1: TransactionModel, TransactionCategoryModel, seed default 12 categories
- Day 2–3: TransactionRepository, use cases (add, edit, delete, monthly totals, by-category totals)
- Day 4: Money dashboard screen — income card, expense card, balance card with count-up animation
- Day 5: Add transaction bottom sheet — numpad/amount field, category grid, type toggle (income/expense), date picker

**Week 8 (Budget + History):**
- Day 6: Transaction history list — sorted by date, grouped by day, swipe to edit/delete
- Day 7: Search + filter transactions (by category, date range, type)
- Day 8: Budget setup screen — set monthly limit per category, progress bar
- Day 9: Budget alert system — calculate 80%/100% thresholds, trigger push notification
- Day 10: Currency setting (symbol + code); monthly income setup in onboarding

**Definition of Done:**
- [ ] Can add income and expense in under 10 seconds
- [ ] Balance updates instantly after adding transaction
- [ ] Budget progress bars show correct percentages
- [ ] Push notification fires when 80% budget reached (test manually)
- [ ] Transaction history shows correct grouped-by-day list

**Risks:**
- Numpad input UX — use custom numpad widget for clean feel, not system keyboard
- Date range queries on Isar — test performance with 1000+ mock transactions

---

## Sprint 5 — Money Manager Charts + Savings Goals

**Goal:** Beautiful fl_chart visualizations + savings goal tracking with celebration

**Week 9 (Charts):**
- Day 1–2: fl_chart integration, data transformation helpers (transactions → chart data)
- Day 3: Pie chart screen — category breakdown, gradient slice colors, tap for detail
- Day 4: Bar chart — configurable time period (daily/weekly/monthly), animated entry
- Day 5: Line chart — savings trend over 6 months, smooth curved line

**Week 10 (Goals + Time Filters):**
- Day 6: Time filter tabs (Daily/Weekly/Monthly/Yearly) wired to all chart types
- Day 7: SavingsGoalModel, repository, use cases (create, deposit, delete)
- Day 8: Savings goals list screen — goal cards with circular progress indicator
- Day 9: Create goal screen + deposit bottom sheet + progress tracking
- Day 10: Goal achieved: Lottie confetti animation + "You did it!" celebration screen

**Definition of Done:**
- [ ] Pie chart shows correct category percentages with real data
- [ ] Bar chart updates when time filter changes
- [ ] Savings goal progress updates after each deposit
- [ ] Confetti Lottie animation plays when goal is reached
- [ ] All charts run at 60fps (verified in Flutter DevTools)

**Risks:**
- Lottie animation file size — use compressed JSON, not full video
- fl_chart learning curve — refer to fl_chart.dev examples

---

## Sprint 6 — UI Polish + Animations + Security

**Goal:** App feels premium — glassmorphism, micro-animations, app lock

**Week 11 (Animations + Theme):**
- Day 1: Page transitions — flutter_animate slide+fade on route changes
- Day 2: Task complete animation — checkmark SVG burst + particle effect
- Day 3: Glassmorphism cards — apply to all feature module cards consistently
- Day 4: FAB morphing — expand into bottom sheet with animated transition
- Day 5: Dark/light theme toggle in Settings; animated sun/moon icon

**Week 12 (Security + Final Polish):**
- Day 6: Bottom nav animated pill indicator (smooth slide between tabs)
- Day 7: Budget exceeded shake animation + red warning overlay
- Day 8: Staggered list entrance animations across all list screens
- Day 9: PIN setup screen — 6-digit PIN, confirm PIN, store bcrypt hash
- Day 10: Biometric unlock (local_auth) — fingerprint/face on supported devices

**Definition of Done:**
- [ ] Page transitions are smooth (no jank) in Flutter DevTools
- [ ] Dark and light themes are pixel-perfect across all screens
- [ ] App lock (PIN) prevents access until correct PIN entered
- [ ] Biometric works on emulator with enrolled fingerprint
- [ ] All animations complete in <500ms, no dropped frames

**Risks:**
- Biometric on emulator needs manual fingerprint enrollment (adb -e emu finger touch 1)
- Over-animating can hurt UX — review with fresh eyes before finalizing

---

## Sprint 7 — QA, Testing, Bug Fixes, Release Prep

**Goal:** Zero critical bugs, performance validated, ready for Play Store

**Week 13 (Testing):**
- Day 1–2: Write widget tests for Notes (list, editor), Tasks (list, swipe)
- Day 3: Write integration tests (create note → find in list, add expense → balance updates)
- Day 4: Test alarm background behavior on Android API 26, 30, 34 emulators
- Day 5: Full manual regression test across all 5 modules (test matrix)

**Week 14 (Fix + Optimize):**
- Day 6: Fix all bugs found in Week 13
- Day 7: Flutter DevTools — profile for jank, memory leaks; fix >16ms frames
- Day 8: Cold start time test — target <2s; lazy-load non-critical features if needed
- Day 9: APK size analysis — `flutter build appbundle --release`; target <50MB
- Day 10: Final review — check all success criteria from Project Charter

**Definition of Done:**
- [ ] All Sprint 1–6 DoD criteria still passing (regression check)
- [ ] Zero crashes in 2-hour manual test session
- [ ] Cold start <2s on Redmi Note 10 equivalent emulator
- [ ] APK size <50MB
- [ ] Flutter DevTools: no frames >16ms in typical usage flow

---

*Document: 02_sprint_plan.md | Phase 4 — Project Planning*
