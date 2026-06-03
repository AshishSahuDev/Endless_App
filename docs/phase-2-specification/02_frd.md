# Functional Requirements Document (FRD)
## Endless — Personal Productivity & Finance App

---

| Field    | Value                              |
|----------|------------------------------------|
| Document | Functional Requirements Document   |
| Version  | 1.0                                |
| Date     | 2026-06-03                         |
| Author   | Ashish Sahu                        |
| Status   | Approved                           |
| Phase    | Phase 2 — Specification            |

---

## Table of Contents

1. [Onboarding](#1-onboarding)
2. [Navigation](#2-navigation)
3. [Notes Module](#3-notes-module)
4. [Tasks Module](#4-tasks-module)
5. [Reminders Module](#5-reminders-module)
6. [Alarms Module](#6-alarms-module)
7. [Money Manager Module](#7-money-manager-module)
8. [Settings](#8-settings)
9. [Global Search](#9-global-search)

---

## 1. Onboarding

### 1.1 Feature: First-Launch Onboarding Flow

**Description:**
A three-slide carousel that introduces the app to first-time users, lets them choose their preferred theme, and optionally set their monthly income. On subsequent launches, this flow is skipped entirely.

**Input:**
- User swipe gestures (next slide / skip)
- Theme selection (Dark / Light radio buttons)
- Monthly income text field (numeric, optional)

**Output:**
- `AppSettings` record created in Isar with selected theme, currency (default: USD), and monthly income (default: 0)
- `isOnboardingComplete = true` flag persisted in `AppSettings`
- App navigates to Home Dashboard

**Business Rules:**
- BR-OB-1: The onboarding flow is shown exactly once per device installation.
- BR-OB-2: The user may skip any individual slide or the entire flow; default values are applied.
- BR-OB-3: The monthly income value set here is pre-populated in the Money Manager but can be changed later in Settings.

**Detailed User Flow:**

```
Step 1: App launches for the first time
Step 2: Splash screen animates for 1.5s (logo scale-in, fade-in)
Step 3: Slide 1 displays — "Endless" logo, tagline "One app for everything", 
        and a brief description of all 5 modules
        — User taps "Next" or swipes left
Step 4: Slide 2 displays — Theme selection
        — Two large cards: "Dark Mode" (purple gradient preview) 
          and "Light Mode" (soft gradient preview)
        — Dark Mode is pre-selected
        — User taps preferred theme; card gets a glowing border
        — User taps "Next"
Step 5: Slide 3 displays — "Set your monthly income (optional)"
        — Numeric text field with currency symbol prefix
        — "You can change this anytime in Settings" hint text
        — User types income amount (or skips)
        — User taps "Get Started"
Step 6: AppSettings saved to Isar
Step 7: Slide animates off, Home Dashboard slides in from right
```

**Error Handling:**
- If the user enters a non-numeric value in the income field: field shows red border, error text "Please enter a valid number", "Get Started" button remains disabled.
- If Isar write fails: app shows a system error snackbar "Something went wrong. Please restart the app." and retries once.

**Edge Cases:**
- If the user force-kills the app mid-onboarding: `isOnboardingComplete` is `false`, onboarding shows again on next launch.
- If the user selects a theme then rotates the device: selection is preserved; layout adapts to landscape.

**Data Validation:**
- Monthly income: numeric only, minimum 0, maximum 999,999,999.99, two decimal places allowed.
- Income field is optional; empty input is treated as 0.

---

## 2. Navigation

### 2.1 Feature: Bottom Navigation Bar

**Description:**
A persistent bottom navigation bar with five tabs. Tapping a tab navigates to that module's primary screen. An animated pill indicator slides to the active tab. Each primary screen has a contextual FAB.

**Input:**
- User tap on a tab icon

**Output:**
- Navigation to the selected module's primary screen
- Pill indicator animates from previous tab position to new tab position (300ms ease-in-out)
- FAB morphs to the appropriate action for the new tab

**Business Rules:**
- BR-NAV-1: Tapping the active tab scrolls the module's list to the top (if already at top, no action).
- BR-NAV-2: The back button on Android does not exit the app from a module screen; it navigates to the previously visited tab, then exits on the home/first tab.
- BR-NAV-3: Bottom nav is not shown in full-screen editor screens (note editor, alarm active screen).

**Tab Definitions:**

| Tab Index | Label     | Icon              | FAB Action              |
|-----------|-----------|-------------------|-------------------------|
| 0         | Notes     | note_2 (iconsax)  | Open note creation sheet |
| 1         | Tasks     | task_square       | Open task creation sheet |
| 2         | Reminders | notification      | Open reminder creation sheet |
| 3         | Alarms    | alarm             | Open alarm creation sheet |
| 4         | Money     | wallet_money      | Open add transaction sheet |

**Detailed User Flow (Tab Switch):**
```
Step 1: User is on Notes tab (tab 0)
Step 2: User taps Tasks tab icon
Step 3: Pill indicator slides from position 0 to position 1 (300ms)
Step 4: Tasks screen slides in from right (200ms) — notes screen persists in stack
Step 5: Tasks FAB appears with scale animation
Step 6: Page title changes to "Tasks"
```

---

### 2.2 Feature: Floating Action Button (FAB)

**Description:**
A gradient circular FAB (60×60dp) on each module list screen. The FAB uses a gradient fill (purple-to-pink) and has a morphing animation when switching tabs.

**Input:** User tap

**Output:** Opens the respective creation bottom sheet or editor screen

**Business Rules:**
- BR-FAB-1: The FAB is hidden when the user scrolls down a list (scroll-to-hide behaviour) and re-appears when scrolling up.
- BR-FAB-2: The FAB has a subtle scale-pulse animation when the screen has no items to draw attention.

---

## 3. Notes Module

### 3.1 Feature: Create Note

**Description:**
Opens a full-screen note editor where the user can type a title and body text. The note auto-saves to Isar as the user types.

**Input:**
- Note title (plain text, optional)
- Note body (rich text: bold, italic, inline code)
- Colour selection (1 of 8 colour swatches)
- Pin toggle

**Output:**
- `NoteModel` record created in Isar
- Note appears at the top of the notes list (or at the top of pinned section if pinned)

**Business Rules:**
- BR-NOTE-1: A note with an empty title is valid. The title field shows "Title" as grey placeholder text.
- BR-NOTE-2: A note with no body text is valid. The body field shows "Start writing..." placeholder text.
- BR-NOTE-3: Auto-save triggers one second after the user stops typing (debounced).
- BR-NOTE-4: A note is not created in the database until the user types at least one character in either the title or body field.

**Detailed User Flow:**
```
Step 1: User taps FAB on Notes screen
Step 2: Note editor screen opens with slide-up animation (300ms)
Step 3: Cursor is automatically focused in the title field
Step 4: User types a title; title field expands to two lines if needed
Step 5: User taps the body field or presses Enter after title
Step 6: User types body text
Step 7: One second after user pauses typing: auto-save triggers (subtle "Saved" 
        micro-toast appears bottom-right for 1.5s)
Step 8: User taps the colour palette icon in the bottom toolbar
Step 9: A row of 8 colour swatches slides up from the bottom of the editor
Step 10: User taps a colour; note background transitions to that colour (200ms)
Step 11: User taps back arrow (top-left) or uses OS back gesture
Step 12: If unsaved changes exist: final save triggers
Step 13: Editor closes with slide-down animation; note appears in list
```

**Error Handling:**
- If Isar write fails during auto-save: "Auto-save failed. Changes may be lost." snackbar shown. Retry attempted after 2 seconds.
- If user exits with only whitespace content: note is not saved; no error shown.

**Edge Cases:**
- Copying and pasting very long text (>10,000 chars): app must not freeze; large text stored normally.
- User exits then re-enters the same note: cursor returns to end of body text.
- User creates note while device storage is nearly full: standard OS error propagates, snackbar shown.

**Data Validation:**
- Title: max 200 characters.
- Body: max 50,000 characters.
- Colour index: integer 0–7; defaults to 0 (transparent/default card colour).

---

### 3.2 Feature: Notes List View

**Description:**
The primary Notes screen showing all non-archived notes in a staggered grid layout (2 columns). Pinned notes appear in a horizontally scrollable row at the top.

**Input:** None (passive display); user taps a note card to open editor.

**Output:** Notes list rendered from Isar query

**Business Rules:**
- BR-NOTE-5: Pinned notes display in a horizontal scroll row labelled "Pinned" above the main grid. If there are no pinned notes, this section is hidden.
- BR-NOTE-6: Notes are sorted by `updatedAt` descending (most recently modified first) within each section.
- BR-NOTE-7: Empty state (no notes): show illustration and text "No notes yet. Tap + to create one."

**Detailed User Flow (Archive via long-press):**
```
Step 1: User long-presses a note card for 400ms
Step 2: Note card shows a selection border (purple glow)
Step 3: A context action bar appears at the bottom with icons: Pin, Archive, Delete
Step 4: Multiple notes can be selected by tapping additional cards
Step 5: User taps Archive icon
Step 6: Selected notes slide out of grid with fade animation
Step 7: Snackbar: "1 note archived. Undo?" — undo available for 5 seconds
```

---

### 3.3 Feature: Pin / Unpin Note

**Description:** Toggle a note's pinned status from the editor toolbar or context menu.

**Detailed User Flow:**
```
Step 1: User opens a note in the editor
Step 2: User taps the pin icon in the top-right toolbar
Step 3: Pin icon fills (from outline to solid) with a spring animation
Step 4: Note is saved with isPinned = true
Step 5: On returning to list: note moves to the Pinned section
```

---

### 3.4 Feature: Archive / Unarchive Note

**Archive Flow:** (see long-press context menu above or editor toolbar pin icon equivalent)

**Unarchive Flow:**
```
Step 1: User taps Archive icon (box icon) in top app bar of Notes screen
Step 2: Archive view slides in — list of archived notes
Step 3: User long-presses or swipes a note and selects "Unarchive"
Step 4: Note returns to main list, sorted by updatedAt
```

---

### 3.5 Feature: Note Search

**Description:** Real-time search across note titles and bodies.

**Detailed User Flow:**
```
Step 1: User taps the search icon in the Notes screen app bar
Step 2: Search bar expands with keyboard opening (300ms animation)
Step 3: User types search query
Step 4: Notes list filters in real-time as user types (debounced 300ms)
Step 5: Matching text is highlighted with a yellow background in results
Step 6: User taps a result — opens note editor
Step 7: User clears search or taps back — full list returns
```

**Edge Cases:**
- Search with special characters: treated as literal text.
- Search across archived notes: not included in default search; an "Include archived" toggle is provided.

---

## 4. Tasks Module

### 4.1 Feature: Create Task

**Description:**
A bottom sheet slides up from the bottom of the Tasks screen when the FAB is tapped, providing a compact task creation form.

**Input:**
- Title (required)
- Description (optional, multi-line)
- Priority (High / Medium / Low — pill selector)
- Due date (optional, date picker)
- Category (optional, from existing categories)

**Output:**
- `TaskModel` record created in Isar
- Task appears in the Active tasks list

**Business Rules:**
- BR-TASK-1: Title is required; the "Add Task" button is disabled until title has at least one non-whitespace character.
- BR-TASK-2: Default priority is Medium.
- BR-TASK-3: Tasks with no due date appear below tasks with due dates in the sorted view.
- BR-TASK-4: Tasks with a past due date are flagged as overdue even after the app is reopened.

**Detailed User Flow:**
```
Step 1: User taps FAB on Tasks screen
Step 2: Bottom sheet slides up (300ms ease-out), keyboard opens
Step 3: Title field is auto-focused
Step 4: User types task title
Step 5: User taps priority pill (High/Medium/Low) — pill highlights with colour
Step 6: User taps "Add due date" — inline date picker expands within sheet
Step 7: User selects date; date picker collapses showing formatted date chip
Step 8: User taps "Category" — second sheet or inline category list appears
Step 9: User selects category; category chip appears on form
Step 10: User taps "Add Task" button
Step 11: Bottom sheet dismisses (slide-down, 200ms)
Step 12: New task appears at top of list with slide-in animation
```

**Error Handling:**
- Empty title submitted: button stays disabled; title field border turns red with "Title required" hint.

**Data Validation:**
- Title: max 200 characters, at least 1 non-whitespace character.
- Description: max 1,000 characters.
- Amount: N/A.
- Due date: must be today or a future date (past dates show a warning but are not blocked).
- Category ID: must reference an existing `TaskCategory` record or be null.

---

### 4.2 Feature: Complete Task (Swipe)

**Description:** Swiping a task card to the right reveals a green "Done" background and completes the task.

**Detailed User Flow:**
```
Step 1: User begins swiping a task card to the right
Step 2: Green background with checkmark icon revealed beneath card
Step 3: At 40% swipe threshold: haptic feedback triggers
Step 4: User releases or swipe exceeds 60% of card width
Step 5: Card animates to the right and disappears (200ms)
Step 6: Task moves to "Completed" section with strikethrough title
Step 7: Snackbar: "Task completed. Undo?" for 5 seconds
Step 8: completedAt timestamp recorded
```

---

### 4.3 Feature: Drag-and-Drop Reorder

**Description:** Long-pressing a task activates drag mode; the task can be dragged to a new position in the list.

**Detailed User Flow:**
```
Step 1: User long-presses a task item for 400ms
Step 2: Item lifts with elevation shadow and slight scale-up (1.05x)
Step 3: Other list items compact slightly to show drag target gaps
Step 4: User drags to desired position
Step 5: Dragged item snaps to new position with spring animation
Step 6: Sort order persisted to Isar (manual sort index field updated)
```

---

### 4.4 Feature: Task Categories

**Description:** User-defined colour-coded categories for grouping tasks.

**Create Category Flow:**
```
Step 1: User taps "Manage Categories" in Tasks screen overflow menu
Step 2: Category management screen shows existing categories list
Step 3: User taps "Add Category"
Step 4: Inline form appears: category name text field + colour picker row
Step 5: User types name and taps colour
Step 6: User taps "Save" — category appears in list
```

**Data Validation:**
- Category name: max 30 characters, at least 1 character, must be unique.
- Colour index: 0–11 (12 colour options).

---

### 4.5 Feature: Task Filters

**Description:** Filter chips at the top of the Tasks screen filter the visible task list.

**Filter options:** All | Active | Completed | [Each Category Name]

**Behaviour:**
- Filter chip selection is mutually exclusive.
- When "Completed" filter is active: drag-drop reorder is disabled.
- Filter chip selection is reset to "All" when the user navigates away and returns.

---

## 5. Reminders Module

### 5.1 Feature: Create Reminder

**Description:**
Full screen or bottom sheet form to create a new reminder with date, time, optional recurrence, and optional link to a note or task.

**Input:**
- Title (required)
- Date and time (required, date-time picker)
- Recurrence: None / Daily / Weekly / Monthly
- Link to note or task (optional, search picker)
- Message/body (optional)

**Output:**
- `ReminderModel` record created in Isar
- Notification scheduled via `flutter_local_notifications`

**Business Rules:**
- BR-REM-1: A reminder's scheduled time must be in the future at the time of creation.
- BR-REM-2: For Weekly recurrence, the system repeats the reminder on the same day of the week every 7 days.
- BR-REM-3: For Monthly recurrence, the system repeats on the same date each month; if the date doesn't exist in a month (e.g., Feb 30), the last day of that month is used.
- BR-REM-4: When a reminder is linked to a note/task, the notification deep-links to that item.

**Detailed User Flow:**
```
Step 1: User taps FAB on Reminders screen
Step 2: Creation screen slides up
Step 3: User types reminder title
Step 4: User taps date field — calendar date picker opens
Step 5: User selects date — calendar dismisses
Step 6: User taps time field — time picker opens (clock or spinner)
Step 7: User selects time — time picker dismisses; date/time shown as chip
Step 8: User taps "Repeat" selector — bottom sheet with recurrence options
Step 9: User selects Daily/Weekly/Monthly or None
Step 10: (Optional) User taps "Link to note/task" — search screen opens
Step 11: User searches and selects a note or task
Step 12: User taps "Set Reminder"
Step 13: Notification scheduled; screen closes; reminder appears in list
```

**Error Handling:**
- If selected date-time is in the past: "Please choose a future date and time" shown inline below the date-time row; "Set Reminder" button disabled.
- If notification permission is denied: in-app snackbar "Notification permission required for reminders. Go to Settings?" with Settings deep link.

---

### 5.2 Feature: Snooze Reminder

**Detailed User Flow (from notification):**
```
Step 1: Notification arrives at scheduled time
Step 2: Notification shows two action buttons: "Snooze" and "Dismiss"
Step 3: User taps "Snooze"
Step 4: New notification scheduled for (current time + snooze duration)
Step 5: Original notification dismissed
Step 6: Reminder record in Isar updated: isSnoozed = true, snoozeUntil = new time
```

---

## 6. Alarms Module

### 6.1 Feature: Create / Edit Alarm

**Description:**
Alarm creation screen with a large time picker (drum/spinner or clock face), label input, sound picker, repeat day selector, and snooze duration picker.

**Input:**
- Time (HH:mm, 12h or 24h depending on device locale)
- Label (optional text)
- Sound (1 of 5 built-in sounds)
- Repeat days (multi-select chips: Sun Mon Tue Wed Thu Fri Sat)
- Snooze duration (5 / 10 / 15 / 20 minutes)

**Output:**
- `AlarmModel` record created/updated in Isar
- Alarm scheduled via the `alarm` Flutter package
- Alarm appears in the Alarm list with a "Rings in X hours Y minutes" label

**Business Rules:**
- BR-ALARM-1: A new alarm is enabled by default.
- BR-ALARM-2: If no repeat days are selected, the alarm is one-time and fires once at the next occurrence of the specified time; it auto-disables after firing.
- BR-ALARM-3: If repeat days are selected, the alarm fires on each selected day weekly and remains enabled.
- BR-ALARM-4: Disabling an alarm (toggle off) cancels the scheduled alarm job but does not delete the record.

**Detailed User Flow (Create Alarm):**
```
Step 1: User taps FAB on Alarms screen
Step 2: Alarm creation screen slides up
Step 3: Time picker is displayed prominently — user scrolls to desired time
Step 4: User taps Label field; types a label (e.g., "Wake up")
Step 5: User taps "Sound" row — sound picker sheet opens
Step 6: User taps a sound name — preview plays for 2 seconds
Step 7: User selects sound; sheet closes
Step 8: User taps day chips to select repeat days
Step 9: User taps Snooze row — selects 5/10/15/20 minutes
Step 10: User taps "Save Alarm"
Step 11: Screen closes; alarm appears in list with "Rings in X hours" subtitle
Step 12: System toast confirms: "Alarm set for 7:00 AM"
```

**Error Handling:**
- If the `alarm` package fails to register the alarm (e.g., exact alarm permission denied on Android 12+): snackbar with "Could not set alarm. Please allow 'Alarms & Reminders' permission in Settings."

---

### 6.2 Feature: Active Alarm Screen

**Description:**
Full-screen overlay that appears when an alarm fires, even on the lock screen.

**Input:** User swipes to dismiss or taps Snooze button.

**Output:**
- Dismiss: alarm stops, one-time alarm auto-disables.
- Snooze: alarm reschedules for (now + snooze duration).

**Detailed User Flow:**
```
Step 1: Alarm fires at scheduled time
Step 2: Device wakes from sleep; alarm sound plays
Step 3: Active alarm screen animates in (pulse animation on time display)
Step 4: Screen shows: time, alarm label, Snooze button, Dismiss button
Step 5a: User taps "Dismiss" — sound stops, screen dismisses, one-time alarms disabled
Step 5b: User taps "Snooze" — sound stops, countdown label shows "Snoozed for 5 min",
         screen dismisses, re-fires after snooze duration
```

---

### 6.3 Feature: Enable/Disable Alarm Toggle

**Detailed Flow:**
```
Step 1: User taps toggle on alarm list item
Step 2: Toggle animates to new state (on→off: grey, off→on: purple)
Step 3: If enabling: alarm is re-scheduled using stored time
Step 4: If disabling: alarm job is cancelled
Step 5: "Rings in X hours Y minutes" label updates or disappears accordingly
```

---

## 7. Money Manager Module

### 7.1 Feature: Add Transaction

**Description:**
Bottom sheet with income/expense type selector, amount input, category picker, date, and optional note.

**Input:**
- Type: Income or Expense (tab toggle at top)
- Amount (required, numeric)
- Category (required, from list)
- Date (defaults to today, user can change)
- Note/description (optional text)

**Output:**
- `TransactionModel` record created in Isar
- Dashboard figures updated immediately

**Business Rules:**
- BR-MONEY-1: Amount must be greater than 0.
- BR-MONEY-2: Amount is stored with two decimal precision.
- BR-MONEY-3: After saving an expense transaction, the system checks the expense category's budget limit and triggers an alert if 80% or 100% threshold is crossed.
- BR-MONEY-4: Budget alerts are shown as in-app bottom dialogs, not OS notifications.
- BR-MONEY-5: The "Add" button is disabled until type, amount, and category are all filled.

**Detailed User Flow:**
```
Step 1: User taps FAB on Money screen
Step 2: Bottom sheet slides up with keyboard open on amount field
Step 3: "Expense" tab is selected by default; user can tap "Income" to switch
Step 4: User types amount (e.g., 450.00)
Step 5: User taps Category row — category selector grid opens
Step 6: User taps a category (e.g., Food) — category row shows selected category
Step 7: User taps Date row — inline date picker opens
Step 8: User selects date; date row updates to selected date
Step 9: User types optional note in the Note field
Step 10: User taps "Add Expense" button
Step 11: Bottom sheet dismisses; dashboard updates with new totals
Step 12: If budget threshold crossed: budget alert dialog appears:
         "⚠️ Food — 87% of monthly budget used"
```

**Error Handling:**
- Non-numeric amount: keyboard type prevents this (numeric keyboard), but if pasted: "Invalid amount" inline error.
- Zero amount: "Amount must be greater than zero" inline error.

**Data Validation:**
- Amount: positive number, max 999,999,999.99, two decimal places.
- Category: must exist in `TransactionCategory` table.
- Date: not more than 10 years in the past; not more than 1 year in the future.
- Note: max 200 characters.

---

### 7.2 Feature: Money Manager Dashboard

**Description:**
Overview screen showing current month's financial summary: income, expenses, balance, recent transactions, and budget category progress bars.

**Layout:**
```
[Month Selector row]
[Summary Card: Income | Expenses | Balance]
[Budget Progress section — category bars]
[Recent Transactions — last 5]
[View All Transactions link]
```

**Business Rules:**
- BR-MONEY-6: All figures default to current month. User can navigate to previous months using arrow buttons in the Month Selector row.
- BR-MONEY-7: Balance = total income − total expenses for the selected period.
- BR-MONEY-8: If monthly income is set in settings, it is shown alongside actual income.
- BR-MONEY-9: Budget progress bars fill left-to-right; colour changes: green (<60%), yellow (60–79%), orange (80–99%), red (100%+).

---

### 7.3 Feature: Charts Screen

**Description:**
Three chart types (pie, bar, line) on a tabbed screen with a time period filter at the top.

**Pie Chart:**
- Shows expense breakdown by category for selected period.
- Tapping a pie slice highlights it and shows category name + amount + percentage in a tooltip.

**Bar Chart:**
- Y-axis: amount; X-axis: days of the month (current month) or weeks (last 3/6 months).
- Green bars for income, red bars for expenses, displayed side by side.

**Line Chart:**
- Dual lines: income (green) and expenses (red) over time.
- X-axis: months for 3/6 month view, days for current month.
- Tapping a data point shows exact value tooltip.

**Time Filters:** This Month | Last 3 Months | Last 6 Months | This Year

---

### 7.4 Feature: Savings Goals

**Description:**
A card-based list of user savings goals with progress bars and celebration animation.

**Create Goal Flow:**
```
Step 1: User taps "Add Goal" on Savings Goals screen
Step 2: Bottom sheet opens: Goal name, Target amount, Current amount (optional),
        Deadline date (optional)
Step 3: User fills form and taps "Create Goal"
Step 4: Goal card appears in list with progress bar (0% if no current amount)
```

**Mark Goal Achieved:**
```
Step 1: User opens a goal and taps "Update Progress"
Step 2: User enters new current amount >= target amount
Step 3: System detects goal achieved
Step 4: Confetti animation plays full-screen (Lottie JSON)
Step 5: Goal card shows "Achieved!" badge with checkmark
Step 6: isAchieved flag set true in Isar
```

**Business Rules:**
- Goals are not deleted when achieved; they stay visible in a "Completed Goals" section.
- Current amount cannot be negative.
- Target amount must be > 0.

---

### 7.5 Feature: Transaction History

**Description:**
Scrollable, searchable, and filterable full list of all transactions.

**Filters:**
- Date range: This Month / Last 3 Months / Last 6 Months / All Time / Custom range
- Type: All / Income / Expense
- Category: All / [specific category]

**Search:**
- Real-time search against transaction note/description field.

**Edit/Delete:**
```
Step 1: User taps a transaction item
Step 2: Transaction detail sheet opens showing all fields
Step 3a: User taps Edit — fields become editable inline
Step 3b: User taps Delete — confirmation dialog: "Delete this transaction?"
Step 4b: Confirmed — transaction removed; totals updated
```

---

## 8. Settings

### 8.1 Feature: Theme Toggle

**Input:** Toggle switch
**Output:** App theme changes immediately across all screens (no restart)
**Flow:**
```
Step 1: User opens Settings from any screen's top-right icon
Step 2: Settings screen shows "Appearance" section
Step 3: User taps "Dark Mode" toggle
Step 4: Theme switches instantly — all colours, shadows, icons update
Step 5: Setting persisted to AppSettings in Isar
```

---

### 8.2 Feature: Currency Selection

**Input:** Dropdown/list selection
**Available currencies:** USD $, EUR €, GBP £, INR ₹, JPY ¥, CAD $, AUD $, CHF ₣, CNY ¥, AED د.إ

**Flow:**
```
Step 1: User taps "Currency" row in Settings
Step 2: Bottom sheet with list of currencies opens
Step 3: User taps desired currency — check mark appears
Step 4: Sheet closes; all monetary values in the app update to use new symbol
```

---

### 8.3 Feature: App Lock

**Input:** Toggle enable/disable; biometric or PIN choice

**Flow (Enable Biometric):**
```
Step 1: User taps "App Lock" in Settings
Step 2: Toggle shows "Off" — user taps to enable
Step 3: System biometric prompt appears: "Confirm your identity to enable App Lock"
Step 4: User authenticates successfully
Step 5: Toggle turns on; "Biometric" chip shown
Step 6: isAppLockEnabled = true, lockType = biometric persisted
```

**Flow (App resume with lock active):**
```
Step 1: User sends app to background
Step 2: User returns to app within 30 seconds — no lock prompt (grace period)
Step 3: User returns to app after 30 seconds — lock screen shown
Step 4: Lock screen shows logo + "Tap to authenticate"
Step 5: User authenticates — app content revealed with fade-in
```

**Error Handling:**
- Biometric fails 3 times: fallback to PIN entry.
- PIN fails 5 times: 30-second lockout with countdown.

---

## 9. Global Search

### 9.1 Feature: Global Search from Home Dashboard

**Description:**
A search bar on the Home dashboard tab that searches across notes (title + body) and tasks (title) simultaneously, displaying grouped results.

**Input:** Search query text (minimum 2 characters to trigger search)

**Output:** Grouped results: "Notes" section, "Tasks" section

**Detailed User Flow:**
```
Step 1: User taps search bar at top of Home dashboard
Step 2: Search bar expands, keyboard opens
Step 3: User types query (minimum 2 characters)
Step 4: Results grouped by type appear below with 300ms debounce
Step 5: "Notes (3)" section header with 3 note cards
Step 6: "Tasks (2)" section header with 2 task items
Step 7: User taps a result — navigates to that item's editor/detail screen
Step 8: User taps back — returns to search results (query preserved)
Step 9: User clears query or taps X — returns to home dashboard
```

**Edge Cases:**
- No results: "No results for '[query]'" empty state with a sad illustration.
- Query only in archived notes: archived note results shown with a grey "Archived" badge; tapping navigates to the Archive view with the note.
- Very long query (>100 chars): trimmed to 100 characters silently.

**Data Validation:**
- Minimum 2 characters to trigger search (prevents full-table scan on every keystroke).
- Maximum query length: 100 characters.
