# Work Breakdown Structure (WBS)
**Project:** Endless App | **Version:** 1.0 | **Date:** 2026-06-03 | **Author:** Ashish Sahu

---

## WBS Overview

| Level | Item | Hours |
|---|---|---|
| 1.0 | Phase 0 — Initiation | 4h ✅ |
| 2.0 | Phase 1 — Discovery | 8h ✅ |
| 3.0 | Phase 2 — Specification | 10h ✅ |
| 4.0 | Phase 3 — Technical Planning | 10h ✅ |
| 5.0 | Phase 4 — Project Planning | 6h ✅ |
| 6.0 | Phase 5 — Design | 14h ✅ |
| 7.0 | Phase 6 — Dev Environment Setup | 8h |
| 8.0 | Phase 7 — Development (7 Sprints) | 128h |
| 9.0 | Phase 8 — Release | 10h |
| | **TOTAL** | **198h** |

---

## Detailed WBS

### 1.0 Phase 0 — Initiation (4h) ✅
- 1.1 Write Project Requirements Prompt — 1h
- 1.2 Write Project Charter — 1.5h
- 1.3 Write Feasibility Study — 1.5h

### 2.0 Phase 1 — Discovery (8h) ✅
- 2.1 Write BRD (15 Business Requirements) — 2h
- 2.2 Write User Personas (3 personas) — 3h
- 2.3 Write User Story Map (64 stories) — 3h

### 3.0 Phase 2 — Specification (10h) ✅
- 3.1 Write SRS (System Requirements Specification) — 5h
- 3.2 Write FRD (Functional Requirements Document) — 5h

### 4.0 Phase 3 — Technical Planning (10h) ✅
- 4.1 Write Technical Architecture Document — 4h
- 4.2 Write Database Design (Isar schemas + queries) — 3h
- 4.3 Write API Contracts (entities, repos, use cases) — 3h

### 5.0 Phase 4 — Project Planning (6h) ✅
- 5.1 Write Work Breakdown Structure (this doc) — 1h
- 5.2 Write Sprint Plan (7 sprints) — 2h
- 5.3 Write Risk Register (15+ risks) — 1.5h
- 5.4 Write Definition of Done — 1.5h

### 6.0 Phase 5 — Design (14h) ✅
- 6.1 Write Design System & Style Guide — 5h
- 6.2 Write Screen Inventory (all screens) — 4h
- 6.3 Write Wireframes (8 key screens, ASCII) — 5h

### 7.0 Phase 6 — Dev Environment Setup (8h)
- 7.1 Install Flutter SDK on Ubuntu — 1h
- 7.2 Set up Android Studio + AVD emulator — 1h
- 7.3 Configure VS Code (Flutter + Dart extensions) — 0.5h
- 7.4 Create Flutter project scaffold — 1h
- 7.5 Set up folder structure (Clean Architecture) — 1h
- 7.6 Configure pubspec.yaml (all dependencies) — 0.5h
- 7.7 Set up Riverpod + Isar boilerplate — 1.5h
- 7.8 Set up GoRouter navigation — 0.5h
- 7.9 Set up dark/light theme (AppTheme class) — 1h

### 8.0 Phase 7 — Development (128h)

#### 8.1 Sprint 1 — Onboarding + Notes (20h)
- 8.1.1 Onboarding screens (3 slides + theme selection) — 3h
- 8.1.2 Home dashboard skeleton — 2h
- 8.1.3 Bottom navigation bar with animated pill — 2h
- 8.1.4 Notes: NoteModel + IsarService setup — 1h
- 8.1.5 Notes: Repository implementation — 2h
- 8.1.6 Notes: Use cases (create, update, delete, pin, archive) — 2h
- 8.1.7 Notes: Riverpod providers — 1h
- 8.1.8 Notes: List screen (grid/list view, color cards, pin badge) — 3h
- 8.1.9 Notes: Editor screen (rich text, color picker, FAB save) — 3h
- 8.1.10 Notes: Search screen — 1h

#### 8.2 Sprint 2 — Tasks (16h)
- 8.2.1 TaskModel + CategoryModel + IsarService — 1h
- 8.2.2 Tasks: Repository + use cases — 2h
- 8.2.3 Tasks: Riverpod providers — 1h
- 8.2.4 Tasks: List screen (filter tabs: All/Active/Done) — 3h
- 8.2.5 Tasks: Task card (priority color, due date, swipe-complete) — 3h
- 8.2.6 Tasks: Create/edit bottom sheet — 2h
- 8.2.7 Tasks: Category management screen — 2h
- 8.2.8 Tasks: Drag-and-drop reorder — 2h

#### 8.3 Sprint 3 — Alarms + Reminders (18h)
- 8.3.1 AlarmModel + Is Setup — 1h
- 8.3.2 Alarm: Repository + alarm package integration — 3h
- 8.3.3 Alarm: List screen (toggle, label, time display) — 2h
- 8.3.4 Alarm: Create/edit screen (time picker, sound, repeat days) — 3h
- 8.3.5 Alarm: Active alarm screen (dismiss, snooze) — 2h
- 8.3.6 Alarm: Background service (Android foreground service) — 2h
- 8.3.7 Reminders: ReminderModel + flutter_local_notifications setup — 2h
- 8.3.8 Reminders: List + create/edit screen — 2h
- 8.3.9 Reminders: Recurring scheduling logic — 1h

#### 8.4 Sprint 4 — Money Manager Core (20h)
- 8.4.1 TransactionModel + CategoryModel + IsarService — 1h
- 8.4.2 Money: Repository + use cases (add, edit, delete, totals) — 3h
- 8.4.3 Money: Seed default categories on first launch — 1h
- 8.4.4 Money: Dashboard screen (income/expense/balance cards) — 3h
- 8.4.5 Money: Add transaction bottom sheet (amount, category, date, note) — 3h
- 8.4.6 Money: Transaction history list (search + filter) — 3h
- 8.4.7 Money: Budget setup per category — 2h
- 8.4.8 Money: Budget alert notifications (80% + 100%) — 2h
- 8.4.9 Money: Currency setting — 1h
- 8.4.10 Money: Count-up animation for balance numbers — 1h

#### 8.5 Sprint 5 — Money Manager Charts + Goals (18h)
- 8.5.1 Charts: fl_chart setup + data transformation — 2h
- 8.5.2 Charts: Pie chart (spending by category, gradient fills) — 3h
- 8.5.3 Charts: Bar chart (daily/weekly/monthly trend) — 3h
- 8.5.4 Charts: Line graph (savings over time) — 3h
- 8.5.5 Charts: Time filter tabs (Daily/Weekly/Monthly/Yearly) — 1h
- 8.5.6 Savings Goals: SavingsGoalModel + repository — 1h
- 8.5.7 Savings Goals: List screen + create screen — 2h
- 8.5.8 Savings Goals: Progress bar + deposit tracking — 2h
- 8.5.9 Savings Goals: Goal achieved celebration (Lottie confetti) — 1h

#### 8.6 Sprint 6 — UI Polish + Animations + Security (16h)
- 8.6.1 Global animations: flutter_animate page transitions — 2h
- 8.6.2 Task complete animation (checkmark burst + particle) — 2h
- 8.6.3 Glassmorphism cards across all modules — 2h
- 8.6.4 Dark/light theme toggle (settings + onboarding) — 1h
- 8.6.5 Bottom nav animated pill indicator — 1h
- 8.6.6 FAB morphing animation (expand to form) — 2h
- 8.6.7 Budget exceeded shake animation — 1h
- 8.6.8 App lock: PIN setup screen — 2h
- 8.6.9 App lock: Biometric authentication (local_auth) — 2h
- 8.6.10 Staggered list entrance animations — 1h

#### 8.7 Sprint 7 — QA + Testing + Bug Fixes (20h)
- 8.7.1 Widget tests for all critical screens — 4h
- 8.7.2 Integration tests: create note → verify in list — 2h
- 8.7.3 Integration tests: add expense → verify balance updates — 2h
- 8.7.4 Integration tests: set alarm → verify fires on emulator — 2h
- 8.7.5 Manual test: full user flows on Android emulator (API 26, 30, 34) — 4h
- 8.7.6 Performance profiling: Flutter DevTools (60fps check) — 2h
- 8.7.7 Cold start time measurement + optimization — 1h
- 8.7.8 APK size analysis + optimization (tree-shake, compress assets) — 1h
- 8.7.9 Bug fixes from testing — 2h

### 9.0 Phase 8 — Release (10h)
- 9.1 Generate release APK / App Bundle — 1h
- 9.2 Create Play Store listing (screenshots, description, icon) — 3h
- 9.3 Submit to Google Play Store (internal testing → production) — 1h
- 9.4 Monitor crash reports for first 48 hours — 2h
- 9.5 Write release notes v1.0 — 1h
- 9.6 Update README + GitHub repo — 1h
- 9.7 Post-launch bug fix patch (if needed) — 1h

---

## Hours Summary

| Phase | Hours | Status |
|---|---|---|
| 0 — Initiation | 4h | ✅ Done |
| 1 — Discovery | 8h | ✅ Done |
| 2 — Specification | 10h | ✅ Done |
| 3 — Technical Planning | 10h | ✅ Done |
| 4 — Project Planning | 6h | ✅ Done |
| 5 — Design | 14h | ✅ Done |
| 6 — Dev Setup | 8h | 🔜 Next |
| 7 — Development | 128h | ⬜ |
| 8 — Release | 10h | ⬜ |
| **TOTAL** | **198h** | |

At 2–3 hours/day: ~66–99 days = **~14–20 weeks** from dev start

---

*Document: 01_wbs.md | Phase 4 — Project Planning*
