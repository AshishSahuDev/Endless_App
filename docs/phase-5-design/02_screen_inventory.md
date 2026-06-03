# Screen Inventory & UI Specifications
**Project:** Endless App | **Version:** 1.0 | **Date:** 2026-06-03 | **Author:** Ashish Sahu

Total screens: **28**

---

## Global Elements (All Screens)

- **Status bar:** dark icons on light mode, light icons on dark mode
- **Bottom Nav:** fixed, visible on all main feature screens (hidden on full-screen editors)
- **FAB:** present on all list screens, context-sensitive icon and action

---

## 1. Launch & Onboarding

### S-01 — Splash Screen
- **Route:** `/splash`
- **Purpose:** App initialization, theme + settings load, redirect to onboarding or home
- **Components:** Full-screen gradient bg, centered Endless logo with pulse animation
- **Duration:** 1.5s max, then auto-navigate
- **Navigation:** → S-02 (first launch) | → S-07 (returning user) | → S-03 (app lock enabled)

### S-02 — Onboarding Slides (3 slides)
- **Route:** `/onboarding`
- **Purpose:** Introduce 5 features + collect theme preference
- **Components:**
  - Slide 1: Lottie animation (notes), "Capture everything" headline, subtitle
  - Slide 2: Lottie animation (money), "Master your money" headline
  - Slide 3: Theme selector (dark/light toggle), "Get started" CTA button
- **Progress:** Dot indicators at bottom
- **Navigation:** Swipe between slides | "Skip" text button top-right | → S-07 on complete

### S-03 — App Lock Screen
- **Route:** `/lock`
- **Purpose:** PIN or biometric authentication gate
- **Components:** App logo, "Welcome back" text, 6-dot PIN display, numpad (0-9 + backspace), or biometric prompt auto-trigger
- **Error state:** Shake animation + "Incorrect PIN" text
- **Navigation:** Correct PIN/biometric → S-07

---

## 2. Navigation

### S-04 — Home Dashboard
- **Route:** `/home`
- **Purpose:** At-a-glance overview of all 5 modules
- **Components:**
  - Greeting header: "Good morning, Ashish ☀️" (time-based)
  - Quick stats row: pinned notes count, pending tasks, upcoming reminders, this month's balance
  - 5 module shortcut cards (glassmorphism, icon + count + module name)
  - Recent activity list (last 3 actions across all modules)
- **Navigation:** Tap any module card → respective module screen

---

## 3. Notes Module

### S-05 — Notes List
- **Route:** `/notes`
- **Purpose:** Browse all notes (grid or list view)
- **Components:**
  - Search bar (sticky top)
  - View toggle button (grid/list)
  - Filter chips row: All / Pinned / Archived / [Color filters]
  - Note cards (color-coded, title, body preview, pin badge, date)
  - Empty state: illustration + "Tap + to create your first note"
  - FAB: `+` → S-06
- **Interactions:** Long-press card → multi-select mode (pin, archive, delete, color-change)
- **Navigation:** Tap card → S-06 (edit) | FAB → S-06 (create)

### S-06 — Note Editor
- **Route:** `/notes/editor` (push, hides bottom nav)
- **Purpose:** Create or edit a note
- **Components:**
  - Back arrow (auto-save on exit)
  - Color picker row (8 color circles, top of screen)
  - Title field (large, 24sp, no label)
  - Rich text body (bold B, italic I, underline U, bullet list toolbar)
  - Bottom toolbar: pin toggle, archive button, delete button, char count
- **Auto-save:** Every 2 seconds while typing
- **Navigation:** Back → S-05 | Delete (confirm dialog) → S-05

---

## 4. Tasks Module

### S-07 — Task List
- **Route:** `/tasks`
- **Purpose:** View and manage all tasks
- **Components:**
  - Category filter horizontal scroll (All, Work, Personal, Shopping…)
  - Filter tabs: All / Active / Completed (show counts)
  - Task cards: checkbox, title, priority dot (red/amber/green), due date chip, category tag
  - Swipe right → complete (green checkmark animation)
  - Swipe left → delete (red trash icon, confirm)
  - Drag handle on right → drag to reorder
  - FAB: `+` → S-08
- **Navigation:** Tap task → S-08 (edit) | FAB → S-08 (create)

### S-08 — Create / Edit Task (Bottom Sheet)
- **Route:** Bottom sheet overlay
- **Purpose:** Add or modify a task
- **Components:**
  - Title input (full width)
  - Priority selector: 3 pill buttons (Low/Medium/High with colors)
  - Due date picker (calendar picker)
  - Category dropdown
  - Linked reminder toggle (opens reminder creation)
  - Save button (gradient, full width)

### S-09 — Category Management
- **Route:** `/tasks/categories`
- **Purpose:** Create and manage task categories
- **Components:**
  - List of categories (name, color dot, task count)
  - Swipe to delete (only non-default categories)
  - FAB → create new category (bottom sheet: name + color picker)

---

## 5. Reminders Module

### S-10 — Reminders List
- **Route:** `/reminders`
- **Purpose:** View all upcoming and past reminders
- **Components:**
  - Section headers: "Upcoming", "Completed"
  - Reminder cards: title, message preview, date/time, recurring badge, linked item badge
  - Swipe left → delete
  - FAB → S-11

### S-11 — Create / Edit Reminder (Bottom Sheet)
- **Route:** Bottom sheet overlay
- **Purpose:** Schedule a reminder
- **Components:**
  - Title + message inputs
  - Date + time pickers
  - Recurring toggle → shows recurrence options (Daily/Weekly/Bi-weekly/Monthly)
  - Weekly: day-of-week selector (7 pill buttons)
  - Link to note/task toggle → search + select field
  - Save button

---

## 6. Alarms Module

### S-12 — Alarm List
- **Route:** `/alarms`
- **Purpose:** Manage all set alarms
- **Components:**
  - Alarm cards: large time display (Space Grotesk), label, repeat days chips, toggle switch
  - Enabled alarm: bright, purple accent
  - Disabled alarm: dimmed, gray
  - Swipe left → delete (with confirm)
  - FAB → S-13

### S-13 — Create / Edit Alarm
- **Route:** `/alarms/editor` (push)
- **Purpose:** Set up a new alarm
- **Components:**
  - Large time picker (drum scroll or digital input)
  - Label text field
  - Sound selector (horizontal scroll of 5 options with preview button)
  - Snooze duration: 3 options (5min / 10min / 15min) as pill toggles
  - Repeat days: 7 day-of-week pill buttons (Sun Mon Tue Wed Thu Fri Sat)
  - Save button (gradient, bottom)

### S-14 — Active Alarm (Full-Screen)
- **Route:** Shown over lock screen
- **Purpose:** In-your-face alarm notification
- **Components:**
  - Large animated time display (pulsing)
  - Alarm label
  - Sound waveform animation
  - "Snooze" button (ghost, secondary position)
  - "Dismiss" button (gradient, large, primary position)
- **Haptic:** Vibration pattern fires alongside sound

---

## 7. Money Manager Module

### S-15 — Money Dashboard
- **Route:** `/money`
- **Purpose:** Financial overview at a glance
- **Components:**
  - Header cards (3, horizontal scroll):
    - Income card (green gradient): total this month
    - Expense card (red gradient): total this month
    - Balance card (purple gradient): income minus expense
  - Count-up animation on all numbers
  - Budget overview: top 3 categories with progress bars + % used
  - Recent transactions list (last 5)
  - "View all" link
  - FAB → S-16

### S-16 — Add Transaction (Bottom Sheet)
- **Route:** Bottom sheet overlay
- **Purpose:** Log income or expense quickly
- **Components:**
  - Type toggle: Income / Expense (segmented pill)
  - Amount display (large, Space Grotesk) + custom numpad
  - Category grid (2×5, icons + names, tap to select)
  - Note field (optional, single line)
  - Date field (defaults to today, tappable)
  - "Save" button (gradient, full width)

### S-17 — Transaction History
- **Route:** `/money/history`
- **Purpose:** Full transaction log
- **Components:**
  - Search bar
  - Filter bar: Type (All/Income/Expense) + Category dropdown + Date range
  - Transactions grouped by date (section headers: "Today", "Yesterday", "Jun 1")
  - Transaction row: category icon, name, note, amount (green=income, red=expense)
  - Swipe right → edit (S-16 prefilled) | Swipe left → delete (confirm)

### S-18 — Budget Setup
- **Route:** `/money/budgets`
- **Purpose:** Set monthly spending limits per category
- **Components:**
  - Category list (expense categories only)
  - Each row: icon, category name, current budget (editable inline), progress bar
  - "No limit" toggle per category
  - "Reset all budgets" option in overflow menu

### S-19 — Charts Screen
- **Route:** `/money/charts`
- **Purpose:** Visual spending analysis
- **Components:**
  - Time filter tabs: Daily / Weekly / Monthly / Yearly
  - Chart type tabs: Pie / Bar / Line (segmented)
  - Chart area (full-width, gradient fills, animated)
  - Pie: category legend below with amounts
  - Bar: X-axis labels, Y-axis amounts, tap bar for day detail
  - Line: savings trend, smooth curve, data point markers
  - Summary stats below chart: highest spend day, avg daily spend, etc.

### S-20 — Savings Goals List
- **Route:** `/money/goals`
- **Purpose:** Overview of all savings goals
- **Components:**
  - Goal cards: name, circular progress ring (gradient), current/target amounts, days remaining
  - Achieved goals: green checkmark, "Achieved" badge
  - FAB → S-21 (create goal)
  - Tap card → S-21 (view/edit + deposit)

### S-21 — Goal Detail / Deposit
- **Route:** `/money/goals/detail`
- **Purpose:** View goal progress, add deposits
- **Components:**
  - Goal name + target
  - Large circular progress ring (animated)
  - Amount saved / target amount / remaining
  - Progress percentage
  - "Add Deposit" button → amount input sheet
  - Deposit history list
  - Edit / Delete options in overflow menu

### S-22 — Goal Achieved Celebration
- **Route:** Overlay (shown when goal is reached)
- **Purpose:** Celebrate savings milestone
- **Components:**
  - Full-screen confetti (Lottie animation)
  - "You did it! 🎉" headline
  - Goal name + amount
  - "Keep going" / "Set new goal" buttons
  - Auto-dismiss after 5 seconds

---

## 8. Settings Module

### S-23 — Settings Main
- **Route:** `/settings`
- **Purpose:** App preferences hub
- **Components:**
  - Sections: Appearance / Finance / Security / About
  - Appearance: Theme toggle (dark/light), animated toggle switch
  - Finance: Monthly income (editable), Currency symbol
  - Security: App lock toggle → S-24 if enabling
  - About: App version, GitHub link, Privacy policy

### S-24 — App Lock Setup
- **Route:** `/settings/lock`
- **Purpose:** Enable and configure app lock
- **Components:**
  - Lock type selector: PIN / Biometric / Both
  - PIN: 6-dot display + numpad → confirm PIN step
  - Biometric: system biometric prompt to confirm
  - Success → back to Settings with lock enabled

---

## 9. Utility Screens

### S-25 — Search (Global)
- **Route:** `/search`
- **Purpose:** Search across notes and tasks simultaneously
- **Components:**
  - Full-width search input (auto-focused)
  - Results grouped by type: Notes (N results), Tasks (N results)
  - Empty results: "No results for 'X'" illustration
  - Tap result → navigates to that item

### S-26 — Empty State (Reusable Component)
- **Not a route** — reusable widget
- **Components:** SVG illustration, heading, subtext, optional CTA button

### S-27 — Error State (Reusable Component)
- **Not a route** — reusable widget
- **Components:** Error icon, "Something went wrong" text, "Try again" button

### S-28 — Confirmation Dialog (Reusable Component)
- **Not a route** — reusable widget
- **Usage:** Delete note, delete task, delete alarm, delete transaction
- **Components:** Title, body text, "Cancel" (ghost), "Delete/Confirm" (red gradient)

---

*Document: 02_screen_inventory.md | Phase 5 — Design*
