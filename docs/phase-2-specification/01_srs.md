# Software Requirements Specification (SRS)
## Endless — Personal Productivity & Finance App

---

| Field        | Value                              |
|--------------|------------------------------------|
| Document     | Software Requirements Specification |
| Version      | 1.0                                |
| Date         | 2026-06-03                         |
| Author       | Ashish Sahu                        |
| Status       | Approved                           |
| Phase        | Phase 2 — Specification            |

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Overall Description](#2-overall-description)
3. [Functional Requirements](#3-functional-requirements)
4. [Non-Functional Requirements](#4-non-functional-requirements)
5. [External Interface Requirements](#5-external-interface-requirements)
6. [Constraints and Assumptions](#6-constraints-and-assumptions)

---

## 1. Introduction

### 1.1 Purpose

This Software Requirements Specification (SRS) defines the complete, verifiable requirements for the Endless mobile application version 1.0. It serves as the authoritative technical reference for design, implementation, and testing decisions. All functional and non-functional requirements documented here derive from the Business Requirements Document (BRD) and User Story Map approved in Phase 1.

### 1.2 Scope

Endless is a cross-platform mobile application built with Flutter that consolidates five productivity and finance management functions into a single offline-first experience:

- **Notes** — rich-text note creation and organisation
- **Tasks** — to-do management with priorities and categories
- **Reminders** — time-based notifications linked to notes or tasks
- **Alarms** — standalone alarm clock with background wake capability
- **Money Manager** — personal income/expense tracking with charts and budget alerts

The application targets Android 8.0 (API 26) and iOS 14.0 and above. All data is stored locally on the device using the Isar embedded database. There is no backend server or cloud sync in version 1.0.

### 1.3 Definitions, Acronyms, and Abbreviations

| Term           | Definition                                                                                       |
|----------------|--------------------------------------------------------------------------------------------------|
| SRS            | Software Requirements Specification — this document                                              |
| FRD            | Functional Requirements Document — detailed behaviour spec per feature                           |
| UI             | User Interface — the visual layer the user sees and touches                                      |
| UX             | User Experience — the overall quality of interaction and feeling                                 |
| CRUD           | Create, Read, Update, Delete — the four standard data operations                                 |
| API            | Application Programming Interface — in this project refers to internal data contracts (no REST) |
| MVVM           | Model-View-ViewModel — presentation pattern used in each feature module                          |
| Isar           | Isar Database — an embedded, high-performance NoSQL database for Flutter                         |
| Riverpod       | State management and dependency injection library for Flutter/Dart                               |
| FAB            | Floating Action Button — the primary action button overlaid on a screen                          |
| Clean Arch     | Clean Architecture — layered architecture separating Presentation, Domain, and Data              |
| Notifier       | Riverpod class that exposes and mutates state                                                    |
| AsyncNotifier  | Riverpod Notifier subclass for asynchronous state operations                                     |
| Entity         | A pure Dart domain object with no framework dependencies                                         |
| Use Case       | A single-responsibility class in the Domain layer that encapsulates one business operation       |
| GoRouter       | Declarative routing package for Flutter                                                          |
| AVD            | Android Virtual Device — the Android emulator                                                    |
| DOD            | Definition of Done — checklist criteria for a completed work item                                |

### 1.4 References

- `docs/phase-0-initiation/01_project_requirements.md`
- `docs/phase-0-initiation/02_project_charter.md`
- `docs/phase-0-initiation/03_feasibility_study.md`
- `docs/phase-1-discovery/01_brd.md`
- `docs/phase-1-discovery/02_user_personas.md`
- `docs/phase-1-discovery/03_user_story_map.md`

---

## 2. Overall Description

### 2.1 Product Perspective

Endless is a standalone mobile application. It does not communicate with any external server. It replaces a collection of separate apps — a notes app, a to-do app, an alarm app, a reminder app, and a budgeting app — by providing all five functions in one cohesive, aesthetically unified experience. The application persists all data locally on the user's device via Isar and uses the operating system's notification and alarm APIs for scheduled events.

### 2.2 Product Functions

At the highest level the system provides:

1. **Note Management** — create, organise, search, and archive freeform notes with colour coding and pinning.
2. **Task Management** — manage to-do items with priorities, due dates, categories, and swipe/drag interactions.
3. **Reminder System** — schedule one-time or recurring push notifications optionally linked to existing notes or tasks.
4. **Alarm System** — operate as a full-featured alarm clock with background wake, snooze, and repeat schedules.
5. **Money Management** — track personal income and expenses, set category budgets, visualise spending with charts, and manage savings goals.
6. **Cross-cutting** — global search, theme switching (dark/light), currency selection, optional biometric app lock, and a unified onboarding flow.

### 2.3 User Classes and Characteristics

| User Class            | Age Range | Technical Level | Primary Use                                    |
|-----------------------|-----------|-----------------|------------------------------------------------|
| College Student       | 18–22     | High            | Notes + Tasks + Alarms; basic budget tracking  |
| Young Professional    | 22–27     | High–Medium     | Tasks + Reminders + Money Manager              |
| Freelancer            | 22–30     | High–Medium     | All 5 modules; income/expense tracking         |
| Casual User           | 16–20     | Medium          | Notes + Alarms primarily                       |

All user classes are expected to interact with a touchscreen smartphone and are comfortable with gesture-based navigation (swipe, drag, long-press). No user is expected to read a manual before using the app.

### 2.4 Operating Environment

| Platform | Minimum Version | Target Version | Notes                               |
|----------|-----------------|----------------|-------------------------------------|
| Android  | 8.0 (API 26)    | 14 (API 34)    | Must work on Android 8+ devices     |
| iOS      | 14.0            | 17.x           | Background alarm requires entitlement |
| Flutter  | 3.x (stable)    | Latest stable  | Dart 3.x null-safety required       |

### 2.5 Design and Implementation Constraints

- **Offline-first:** The application must function fully without an internet connection. No feature may require network access in v1.0.
- **Single codebase:** The entire application is implemented in Dart/Flutter. No native Kotlin, Swift, or platform-specific code is written directly by the developer, except for configuration files (AndroidManifest, Info.plist).
- **Local data only:** All user data is stored exclusively on the user's device via Isar. No data is transmitted to any server.
- **Solo developer:** All design, development, and testing is performed by a single developer. Automation and code generation (Isar, Riverpod annotations) must be used wherever practical.
- **No paid APIs:** No external paid APIs or SDKs may be integrated in v1.0.
- **Build target:** Android APK/AAB for Google Play; iOS IPA for App Store (iOS testing requires access to a macOS machine or CI service).

### 2.6 Assumptions and Dependencies

- The developer's Ubuntu Linux machine has Flutter SDK 3.x, Android Studio, and the Android SDK installed.
- A physical Android device or Android emulator (Pixel 6, API 34) is available for testing.
- The `alarm` Flutter package supports background wake-lock on both Android and iOS within the constraints of those platforms.
- The `flutter_local_notifications` package delivers notifications reliably on Android 8+ and iOS 14+.
- Google Fonts (Sora, Plus Jakarta Sans, Space Grotesk) are bundled in the app binary to avoid requiring internet access at runtime.

---

## 3. Functional Requirements

Requirements are numbered SRS-F-001 onwards. Priority levels: **Critical** (must ship in v1.0), **High** (should ship in v1.0), **Medium** (nice to have in v1.0).

---

### 3.1 Onboarding & Navigation

**SRS-F-001** [Critical]
The system shall display an onboarding screen sequence of three slides on the first app launch, presenting the app name, tagline, and a summary of each major feature.

**SRS-F-002** [Critical]
The system shall not show the onboarding sequence on subsequent app launches after the user has completed it.

**SRS-F-003** [High]
The system shall allow the user to choose a preferred theme (dark or light) during the onboarding flow, defaulting to dark if no choice is made.

**SRS-F-004** [Medium]
The system shall allow the user to enter an optional monthly income amount during onboarding for use as the Money Manager's budget baseline.

**SRS-F-005** [Critical]
The system shall display a persistent bottom navigation bar with five tabs: Notes, Tasks, Reminders, Alarms, and Money.

**SRS-F-006** [Critical]
The system shall display a Floating Action Button (FAB) on each module's primary list screen; tapping the FAB shall open the creation flow for that module.

**SRS-F-007** [High]
The system shall animate the active tab indicator as a sliding pill underneath the active icon.

---

### 3.2 Notes Module

**SRS-F-010** [Critical]
The system shall allow the user to create a new note containing a title (optional) and body text.

**SRS-F-011** [Critical]
The system shall allow the user to edit any existing note's title and body text.

**SRS-F-012** [Critical]
The system shall allow the user to delete a note, with a confirmation snackbar offering an undo action for five seconds.

**SRS-F-013** [Critical]
The system shall persist all notes to local storage and make them available immediately on the next app launch without requiring any user action.

**SRS-F-014** [High]
The system shall allow the user to assign one of at least eight background colour options to each note.

**SRS-F-015** [High]
The system shall allow the user to pin a note; pinned notes shall be displayed at the top of the notes list above unpinned notes.

**SRS-F-016** [High]
The system shall allow the user to archive a note; archived notes shall be removed from the main notes list and visible only in a dedicated Archive view.

**SRS-F-017** [High]
The system shall allow the user to search notes by keyword; the search shall match against note titles and body text and display results in real time as the user types.

**SRS-F-018** [Medium]
The system shall support basic rich-text formatting in the note body: **bold**, *italic*, and `code` inline spans.

**SRS-F-019** [High]
The system shall display the notes list in a grid layout by default with an option to switch to a single-column list layout.

**SRS-F-020** [High]
The system shall display the last-modified timestamp on each note card in the notes list.

**SRS-F-021** [High]
The system shall allow the user to unarchive a note from the Archive view, returning it to the main notes list.

---

### 3.3 Tasks Module

**SRS-F-030** [Critical]
The system shall allow the user to create a task with a title (required) and optional description, priority level, due date, and category.

**SRS-F-031** [Critical]
The system shall allow the user to mark a task as complete; completed tasks shall be visually distinguished (strikethrough text, reduced opacity) and moved to a completed section.

**SRS-F-032** [Critical]
The system shall allow the user to edit any existing task's title, description, priority, due date, and category.

**SRS-F-033** [Critical]
The system shall allow the user to delete a task with an undo snackbar offered for five seconds.

**SRS-F-034** [High]
The system shall support three priority levels: High, Medium, and Low, each represented by a distinct colour indicator (red, orange, green respectively).

**SRS-F-035** [High]
The system shall allow the user to assign a due date to a task; tasks with a past due date shall be highlighted with a visual overdue indicator.

**SRS-F-036** [High]
The system shall allow the user to create, rename, and delete task categories, each with a user-chosen colour.

**SRS-F-037** [High]
The system shall allow the user to swipe a task card to the right to mark it as complete.

**SRS-F-038** [High]
The system shall allow the user to drag and drop tasks to reorder them within the active tasks list.

**SRS-F-039** [High]
The system shall allow the user to filter the task list by: All, Active, Completed, or by a specific Category.

**SRS-F-040** [Medium]
The system shall display a count badge on the Tasks tab icon showing the number of incomplete tasks, updated in real time.

**SRS-F-041** [High]
The system shall record the timestamp when a task is completed.

---

### 3.4 Reminders Module

**SRS-F-050** [Critical]
The system shall allow the user to create a reminder with a title, date, and time.

**SRS-F-051** [Critical]
The system shall deliver a push notification to the device at the scheduled date and time of each enabled reminder.

**SRS-F-052** [High]
The system shall support recurring reminders with the following recurrence options: Daily, Weekly, Monthly.

**SRS-F-053** [High]
The system shall allow the user to link a reminder to an existing note or task; the notification shall include the linked item's title.

**SRS-F-054** [High]
The system shall allow the user to snooze a reminder notification; the default snooze duration shall be ten minutes and shall be user-configurable in settings.

**SRS-F-055** [High]
The system shall display all upcoming reminders in chronological order on the Reminders list screen.

**SRS-F-056** [High]
The system shall allow the user to enable or disable individual reminders without deleting them.

**SRS-F-057** [Medium]
The system shall display a "Passed" visual indicator on reminders whose scheduled time has elapsed and have not been snoozed or dismissed.

**SRS-F-058** [High]
The system shall allow the user to edit or delete any existing reminder.

---

### 3.5 Alarms Module

**SRS-F-060** [Critical]
The system shall allow the user to set multiple independent alarms, each with an hour and minute time.

**SRS-F-061** [Critical]
The system shall wake the device screen and play an alarm sound at the scheduled time, even when the application is in the background or the device screen is off.

**SRS-F-062** [Critical]
The system shall display an active alarm screen when an alarm fires, covering the lock screen if the device is locked.

**SRS-F-063** [Critical]
The system shall provide Snooze and Dismiss actions on the active alarm screen; snooze shall re-trigger the alarm after the configured snooze duration (default five minutes).

**SRS-F-064** [High]
The system shall allow the user to assign a text label to each alarm.

**SRS-F-065** [High]
The system shall provide at least five built-in alarm sounds for the user to choose from.

**SRS-F-066** [High]
The system shall allow the user to configure a repeat schedule for each alarm using any combination of days of the week (Sunday through Saturday).

**SRS-F-067** [Critical]
The system shall allow the user to enable or disable each alarm independently using a toggle switch on the alarm list screen.

**SRS-F-068** [High]
The system shall allow the user to configure the snooze duration per alarm (options: 5, 10, 15, 20 minutes).

**SRS-F-069** [High]
The system shall display a friendly time-until-alarm label (e.g., "Rings in 6 hours 30 minutes") beneath each enabled alarm in the list.

**SRS-F-070** [High]
The system shall allow the user to delete an alarm.

---

### 3.6 Money Manager Module

**SRS-F-080** [Critical]
The system shall allow the user to create a transaction with the following fields: type (Income or Expense), amount, category, optional note/description, and date.

**SRS-F-081** [Critical]
The system shall display the current month's total income, total expenses, and net balance on the Money Manager dashboard.

**SRS-F-082** [Critical]
The system shall persist all transactions to local storage and make them available across app restarts.

**SRS-F-083** [High]
The system shall provide default expense categories: Food, Transport, Shopping, Entertainment, Health, Utilities, Education, and Other. The user shall be able to add custom categories.

**SRS-F-084** [High]
The system shall allow the user to set a monthly budget limit per expense category.

**SRS-F-085** [High]
The system shall display an in-app alert notification when spending in a category reaches 80% of its budget limit.

**SRS-F-086** [High]
The system shall display an in-app alert notification when spending in a category reaches 100% of its budget limit.

**SRS-F-087** [High]
The system shall display three chart types on the Charts screen:
  - Pie chart showing expense breakdown by category for the selected period.
  - Bar chart showing daily or weekly spending for the selected period.
  - Line chart showing income vs. expense trend over the selected period.

**SRS-F-088** [High]
The system shall allow the user to filter charts and transaction history by: Current Month, Last 3 Months, Last 6 Months, and Current Year.

**SRS-F-089** [High]
The system shall allow the user to create savings goals with a name, target amount, current amount, and optional deadline date.

**SRS-F-090** [High]
The system shall display a progress bar for each savings goal showing the percentage of the target amount achieved.

**SRS-F-091** [Medium]
The system shall trigger a confetti animation and congratulatory message when a savings goal is marked as achieved (current amount reaches or exceeds target amount).

**SRS-F-092** [High]
The system shall display a searchable, filterable transaction history list showing all past transactions in reverse-chronological order.

**SRS-F-093** [High]
The system shall allow the user to edit or delete any existing transaction.

**SRS-F-094** [High]
The system shall allow the user to search the transaction history by note/description text.

---

### 3.7 Settings & Global Features

**SRS-F-100** [High]
The system shall provide a Settings screen accessible from any module screen via an icon in the top app bar.

**SRS-F-101** [High]
The system shall allow the user to toggle between dark and light theme; the change shall apply immediately across the entire application without restart.

**SRS-F-102** [High]
The system shall allow the user to select a preferred currency symbol from a list of at least 10 common currencies; the selected symbol shall be displayed on all monetary values throughout the app.

**SRS-F-103** [Medium]
The system shall allow the user to enable an app lock using biometric authentication (fingerprint or face recognition) or a four-digit PIN; the lock shall activate when the app moves to the background.

**SRS-F-104** [High]
The system shall provide a global search bar accessible from the home dashboard that searches across notes (title + body) and tasks (title) simultaneously.

**SRS-F-105** [High]
The system shall auto-save note content as the user types, with no explicit save button required.

---

## 4. Non-Functional Requirements

---

### 4.1 Performance

**SRS-NF-001** [Critical]
The application shall reach the home dashboard from cold start (process not in memory) within 2 seconds on a mid-range Android device (Snapdragon 665 class, 4 GB RAM).

**SRS-NF-002** [Critical]
All UI animations and transitions shall maintain a frame rate of 60 frames per second on the target device class. The application shall not exhibit dropped frames exceeding 5% during standard navigation.

**SRS-NF-003** [High]
The notes list shall render and scroll smoothly with up to 500 notes stored in the database without visible lag.

**SRS-NF-004** [High]
The transaction history shall load and scroll smoothly with up to 2,000 transactions stored in the database.

**SRS-NF-005** [High]
Search results in the notes and transaction search features shall appear within 300 milliseconds of the user ceasing to type.

---

### 4.2 Reliability

**SRS-NF-006** [Critical]
Alarm firing must be reliable: the system shall wake the device and play the alarm sound within ±30 seconds of the scheduled time, even when the application process has been killed by the OS.

**SRS-NF-007** [Critical]
The system shall auto-save note edits to the database within one second of the user pausing typing, such that no note content is lost on unexpected app termination.

**SRS-NF-008** [High]
The system shall not lose any transaction, task, or reminder data on normal app closure, crash, or OS-initiated process kill.

**SRS-NF-009** [High]
Reminder notifications shall be re-scheduled automatically after device reboot.

---

### 4.3 Security

**SRS-NF-010** [High]
All user data shall be stored exclusively on the user's device within the application's sandboxed storage. No data shall be transmitted to any external server or third-party service.

**SRS-NF-011** [Medium]
When app lock is enabled, the application shall require biometric or PIN authentication before displaying any content on foreground resume from background.

**SRS-NF-012** [Medium]
PIN attempts shall be limited to five consecutive failures before a thirty-second lockout period is imposed.

---

### 4.4 Usability

**SRS-NF-013** [Critical]
A new user shall be able to complete any core action (create a note, add a task, set an alarm, log a transaction) within ten taps or less from the home screen.

**SRS-NF-014** [High]
All interactive elements (buttons, list items, toggles) shall have a minimum touch target size of 44×44 points to comply with platform accessibility guidelines.

**SRS-NF-015** [High]
All text and icon combinations shall meet WCAG 2.1 AA contrast ratio requirements (minimum 4.5:1 for normal text, 3:1 for large text) in both dark and light themes.

**SRS-NF-016** [High]
All interactive elements shall have semantic accessibility labels for screen reader support.

---

### 4.5 Compatibility

**SRS-NF-017** [Critical]
The application shall install and run correctly on Android 8.0 (API level 26) and all subsequent versions up to the latest Android release.

**SRS-NF-018** [Critical]
The application shall install and run correctly on iOS 14.0 and all subsequent versions up to the latest iOS release.

**SRS-NF-019** [High]
The application layout shall adapt correctly to the following screen size ranges: 5.0 to 7.0 inches diagonal, both 16:9 and 19.5:9 (tall) aspect ratios.

---

### 4.6 Portability

**SRS-NF-020** [Critical]
The application shall be implemented as a single Flutter codebase that compiles to native Android (Kotlin/Gradle) and iOS (Swift/Xcode) without platform-specific feature code written by the developer.

**SRS-NF-021** [High]
The Isar database schema shall be designed to support future migration without data loss when schema changes are introduced in future versions.

---

### 4.7 Maintainability

**SRS-NF-022** [High]
The codebase shall follow Clean Architecture with clear separation of Presentation, Domain, and Data layers; no direct database access shall exist in presentation layer code.

**SRS-NF-023** [High]
Each feature module (notes, tasks, reminders, alarms, money) shall be independently structured so that changes to one module do not require changes in another module's code.

---

## 5. External Interface Requirements

### 5.1 User Interfaces

- The application is a mobile touchscreen application. The entire user interface is rendered by the Flutter engine.
- Primary navigation is via a bottom navigation bar with five tabs.
- Content creation is via bottom sheets and full-screen editor pages.
- The default theme is dark (deep dark background #0A0A0F, card surface #12121A) with glassmorphism card styling and purple/pink/blue accent colours.
- A light theme is available and toggled in settings or onboarding.
- Font families are Sora and Plus Jakarta Sans for UI text, Space Grotesk for numeric/monetary values.

### 5.2 Hardware Interfaces

- **Touch input:** The app relies entirely on capacitive touchscreen input. Gestures used include: tap, long-press, swipe (left, right, up), drag-and-drop, and pinch-to-dismiss (modals).
- **Biometric sensor:** When app lock is enabled, the device fingerprint reader or face recognition camera is accessed via the `local_auth` Flutter package.
- **Speakers/Vibration:** The alarm module accesses the device speaker for alarm sounds and the vibration motor for haptic feedback via the `alarm` Flutter package.
- **Real-time clock:** The device RTC is used for scheduling alarms and reminders at precise times.

### 5.3 Software Interfaces

- **Android OS:** Minimum API 26. Requires the following system permissions:
  - `RECEIVE_BOOT_COMPLETED` — re-schedule alarms after reboot
  - `VIBRATE` — alarm vibration
  - `USE_EXACT_ALARM` / `SCHEDULE_EXACT_ALARM` — precise alarm timing (Android 12+)
  - `POST_NOTIFICATIONS` — push notifications (Android 13+)
  - `USE_BIOMETRIC` / `USE_FINGERPRINT` — app lock
  - `WAKE_LOCK` — alarm background wake
  - `FOREGROUND_SERVICE` — alarm foreground service
- **iOS:** Minimum iOS 14.0. Requires the following Info.plist entries:
  - `NSFaceIDUsageDescription`
  - `UIBackgroundModes: fetch, remote-notification` (for alarm)
  - `NSUserNotificationUsageDescription`

### 5.4 Communications Interfaces

There are no network or communications interfaces in version 1.0. The application does not make HTTP requests, use sockets, or communicate with any external system. All data remains on the local device.

---

## 6. Constraints and Assumptions

### 6.1 Constraints

1. No macOS machine is available to the developer; iOS testing and App Store submission require a macOS-based CI/CD pipeline or remote Mac access.
2. The `alarm` package behaviour on iOS is subject to Apple's background execution restrictions; alarm reliability on iOS may be slightly degraded compared to Android.
3. Google Play's background alarm policy (exact alarms permission) requires justification in the store listing on Android 12+.
4. All selected third-party packages must be available on pub.dev under MIT or Apache 2.0 licences.
5. The app binary size must remain under 50 MB after release build optimisation to ensure acceptable download experience on mobile data.

### 6.2 Assumptions

1. The target user's device has sufficient storage for the application (approximately 30 MB) and the Isar database.
2. The user has granted notification permissions on first launch; the app gracefully degrades if permissions are denied (reminders/alarms show in-app only).
3. The user's device system clock is accurate; no NTP synchronisation is performed.
4. All monetary values are stored as 64-bit doubles with two decimal places. Currency conversion is not performed.
