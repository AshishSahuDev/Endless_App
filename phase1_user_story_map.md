================================================================================
                    ENDLESS APP — USER STORY MAP
                    Version: 1.0  |  Date: 2026-06-03
                    Owner: Ashish Sahu
================================================================================

--------------------------------------------------------------------------------
1. DOCUMENT CONTROL
--------------------------------------------------------------------------------

Document Title  : User Story Map
Project         : Endless Mobile App
Version         : 1.0
Date            : 2026-06-03
Author          : Ashish Sahu
Status          : Approved
Phase           : Phase 1 — Discovery

HOW TO READ THIS MAP:
  BACKBONE    → The main user activities (what users do at the highest level)
  WALKING     → The user tasks (how they accomplish each activity)
  SKELETON    → User stories (specific features, written in "As a user..." form)
  RELEASE     → MVP (v1.0) or Future (v2.0+)
  PRIORITY    → Critical / High / Medium / Low
  SPRINT      → Which development sprint this belongs to


--------------------------------------------------------------------------------
2. USER STORY MAP
--------------------------------------------------------------------------------

================================================================================
EPIC 1: ONBOARDING
================================================================================

BACKBONE: User opens the app for the first time

  WALKING: Welcome + setup
  ┌─────────────────────────────────────────────────────────────────────────┐
  │ US-001  As a new user, I want to see a beautiful onboarding screen      │
  │         so I understand what the app offers.                            │
  │         Priority: High | Release: v1.0 | Sprint: 1                      │
  ├─────────────────────────────────────────────────────────────────────────┤
  │ US-002  As a new user, I want to choose my preferred theme (dark/light)  │
  │         during onboarding so the app looks right from the start.        │
  │         Priority: Medium | Release: v1.0 | Sprint: 1                    │
  ├─────────────────────────────────────────────────────────────────────────┤
  │ US-003  As a new user, I want to set my monthly income amount           │
  │         so the money manager can calculate my budget baseline.          │
  │         Priority: Medium | Release: v1.0 | Sprint: 4                    │
  ├─────────────────────────────────────────────────────────────────────────┤
  │ US-004  As a returning user, I want the app to open directly to my      │
  │         home dashboard so I don't see onboarding again.                 │
  │         Priority: Critical | Release: v1.0 | Sprint: 1                  │
  └─────────────────────────────────────────────────────────────────────────┘


================================================================================
EPIC 2: NAVIGATION
================================================================================

BACKBONE: User navigates between the 5 modules

  WALKING: Bottom navigation bar
  ┌─────────────────────────────────────────────────────────────────────────┐
  │ US-010  As a user, I want a bottom navigation bar with icons for all    │
  │         5 modules so I can switch between them instantly.               │
  │         Priority: Critical | Release: v1.0 | Sprint: 1                  │
  ├─────────────────────────────────────────────────────────────────────────┤
  │ US-011  As a user, I want the active tab to have an animated pill        │
  │         indicator so I know which module I'm in.                        │
  │         Priority: High | Release: v1.0 | Sprint: 6 (polish)             │
  ├─────────────────────────────────────────────────────────────────────────┤
  │ US-012  As a user, I want a floating action button (FAB) on each screen │
  │         to quickly add a note, task, alarm, reminder, or transaction.   │
  │         Priority: Critical | Release: v1.0 | Sprint: 1                  │
  └─────────────────────────────────────────────────────────────────────────┘


================================================================================
EPIC 3: NOTES MODULE
================================================================================

BACKBONE: User manages their notes

  WALKING: Create a note
  ┌─────────────────────────────────────────────────────────────────────────┐
  │ US-020  As a user, I want to create a new note with a title and body    │
  │         so I can capture thoughts quickly.                              │
  │         Priority: Critical | Release: v1.0 | Sprint: 1                  │
  ├─────────────────────────────────────────────────────────────────────────┤
  │ US-021  As a user, I want to format note text (bold, italic, bullets)   │
  │         so I can structure my notes clearly.                            │
  │         Priority: High | Release: v1.0 | Sprint: 1                      │
  ├─────────────────────────────────────────────────────────────────────────┤
  │ US-022  As a user, I want to assign a color to a note so I can          │
  │         visually distinguish different types of notes.                  │
  │         Priority: High | Release: v1.0 | Sprint: 1                      │
  ├─────────────────────────────────────────────────────────────────────────┤
  │ US-023  As a user, I want to add emojis to notes so I can express tone  │
  │         and make notes visually recognizable.                           │
  │         Priority: Medium | Release: v1.0 | Sprint: 1                    │
  └─────────────────────────────────────────────────────────────────────────┘

  WALKING: Organize notes
  ┌─────────────────────────────────────────────────────────────────────────┐
  │ US-024  As a user, I want to pin a note to the top of the list so        │
  │         my most important notes are always visible first.               │
  │         Priority: High | Release: v1.0 | Sprint: 1                      │
  ├─────────────────────────────────────────────────────────────────────────┤
  │ US-025  As a user, I want to archive a note so it's hidden from the     │
  │         main view but not deleted.                                      │
  │         Priority: Medium | Release: v1.0 | Sprint: 1                    │
  ├─────────────────────────────────────────────────────────────────────────┤
  │ US-026  As a user, I want to search through all my notes by keyword     │
  │         so I can find specific information instantly.                   │
  │         Priority: High | Release: v1.0 | Sprint: 1                      │
  └─────────────────────────────────────────────────────────────────────────┘

  WALKING: Edit & delete notes
  ┌─────────────────────────────────────────────────────────────────────────┐
  │ US-027  As a user, I want to edit an existing note so I can update      │
  │         or correct its content.                                         │
  │         Priority: Critical | Release: v1.0 | Sprint: 1                  │
  ├─────────────────────────────────────────────────────────────────────────┤
  │ US-028  As a user, I want to delete a note with a confirmation dialog   │
  │         so I don't accidentally lose important notes.                   │
  │         Priority: Critical | Release: v1.0 | Sprint: 1                  │
  └─────────────────────────────────────────────────────────────────────────┘


================================================================================
EPIC 4: TASKS / LISTS MODULE
================================================================================

BACKBONE: User manages to-do items and checklists

  WALKING: Create tasks
  ┌─────────────────────────────────────────────────────────────────────────┐
  │ US-030  As a user, I want to create a task with a title so I can        │
  │         track what I need to do.                                        │
  │         Priority: Critical | Release: v1.0 | Sprint: 2                  │
  ├─────────────────────────────────────────────────────────────────────────┤
  │ US-031  As a user, I want to set a due date on a task so I know         │
  │         when it needs to be done.                                       │
  │         Priority: High | Release: v1.0 | Sprint: 2                      │
  ├─────────────────────────────────────────────────────────────────────────┤
  │ US-032  As a user, I want to set a priority (High/Medium/Low) on each   │
  │         task so I know what to work on first.                           │
  │         Priority: High | Release: v1.0 | Sprint: 2                      │
  ├─────────────────────────────────────────────────────────────────────────┤
  │ US-033  As a user, I want to assign tasks to categories (Work,          │
  │         Personal, Shopping, etc.) so I can organize by context.        │
  │         Priority: High | Release: v1.0 | Sprint: 2                      │
  └─────────────────────────────────────────────────────────────────────────┘

  WALKING: Complete & manage tasks
  ┌─────────────────────────────────────────────────────────────────────────┐
  │ US-034  As a user, I want to swipe a task to mark it as complete so     │
  │         completion feels satisfying and fast.                           │
  │         Priority: High | Release: v1.0 | Sprint: 2                      │
  ├─────────────────────────────────────────────────────────────────────────┤
  │ US-035  As a user, I want to see an animation when I complete a task    │
  │         (checkmark burst) so the interaction feels rewarding.           │
  │         Priority: Medium | Release: v1.0 | Sprint: 6 (polish)           │
  ├─────────────────────────────────────────────────────────────────────────┤
  │ US-036  As a user, I want to filter tasks by All / Active / Completed   │
  │         so I can focus on what's pending or review done work.           │
  │         Priority: High | Release: v1.0 | Sprint: 2                      │
  ├─────────────────────────────────────────────────────────────────────────┤
  │ US-037  As a user, I want to drag and drop tasks to reorder them so     │
  │         I can manually prioritize my list.                              │
  │         Priority: Medium | Release: v1.0 | Sprint: 2                    │
  └─────────────────────────────────────────────────────────────────────────┘


================================================================================
EPIC 5: REMINDERS MODULE
================================================================================

BACKBONE: User sets up reminders for future events

  WALKING: Create a reminder
  ┌─────────────────────────────────────────────────────────────────────────┐
  │ US-040  As a user, I want to create a one-time reminder with a          │
  │         date, time, and custom message so I'm notified at the right     │
  │         moment.                                                         │
  │         Priority: Critical | Release: v1.0 | Sprint: 3                  │
  ├─────────────────────────────────────────────────────────────────────────┤
  │ US-041  As a user, I want to set a recurring reminder (daily, weekly)   │
  │         so I don't have to re-create the same reminder every time.      │
  │         Priority: High | Release: v1.0 | Sprint: 3                      │
  ├─────────────────────────────────────────────────────────────────────────┤
  │ US-042  As a user, I want to link a reminder to a specific note or task │
  │         so I have context when the notification arrives.                │
  │         Priority: Medium | Release: v1.0 | Sprint: 3                    │
  └─────────────────────────────────────────────────────────────────────────┘

  WALKING: Receive & act on reminder
  ┌─────────────────────────────────────────────────────────────────────────┐
  │ US-043  As a user, I want to receive a push notification for my         │
  │         reminder so I'm alerted even when the app is closed.            │
  │         Priority: Critical | Release: v1.0 | Sprint: 3                  │
  ├─────────────────────────────────────────────────────────────────────────┤
  │ US-044  As a user, I want to snooze a reminder for 10/30 minutes        │
  │         so I can delay it when I'm busy.                                │
  │         Priority: Medium | Release: v1.0 | Sprint: 3                    │
  └─────────────────────────────────────────────────────────────────────────┘


================================================================================
EPIC 6: ALARM MODULE
================================================================================

BACKBONE: User sets reliable wake-up or timed alarms

  WALKING: Set up alarms
  ┌─────────────────────────────────────────────────────────────────────────┐
  │ US-050  As a user, I want to create a new alarm with time, label, and   │
  │         repeat days so I can set up my morning routine.                 │
  │         Priority: Critical | Release: v1.0 | Sprint: 3                  │
  ├─────────────────────────────────────────────────────────────────────────┤
  │ US-051  As a user, I want to enable/disable individual alarms with a    │
  │         toggle so I can turn off weekend alarms without deleting them.  │
  │         Priority: Critical | Release: v1.0 | Sprint: 3                  │
  ├─────────────────────────────────────────────────────────────────────────┤
  │ US-052  As a user, I want to choose an alarm sound from multiple        │
  │         options so I can pick something that actually wakes me up.      │
  │         Priority: High | Release: v1.0 | Sprint: 3                      │
  └─────────────────────────────────────────────────────────────────────────┘

  WALKING: Alarm fires
  ┌─────────────────────────────────────────────────────────────────────────┐
  │ US-053  As a user, I want my alarm to ring even when the app is closed  │
  │         or the phone is on silent so I always wake up.                  │
  │         Priority: Critical | Release: v1.0 | Sprint: 3                  │
  ├─────────────────────────────────────────────────────────────────────────┤
  │ US-054  As a user, I want to snooze the alarm with a configurable       │
  │         snooze duration (5/10/15 min) so I have control.               │
  │         Priority: High | Release: v1.0 | Sprint: 3                      │
  ├─────────────────────────────────────────────────────────────────────────┤
  │ US-055  As a user, I want to dismiss the alarm from the lock screen     │
  │         so I don't have to unlock my phone to turn it off.             │
  │         Priority: High | Release: v1.0 | Sprint: 3                      │
  └─────────────────────────────────────────────────────────────────────────┘


================================================================================
EPIC 7: MONEY MANAGER MODULE
================================================================================

BACKBONE: User tracks income, expenses, and savings

  WALKING: Log transactions
  ┌─────────────────────────────────────────────────────────────────────────┐
  │ US-060  As a user, I want to add an expense entry with amount,          │
  │         category, and optional note in under 10 seconds.               │
  │         Priority: Critical | Release: v1.0 | Sprint: 4                  │
  ├─────────────────────────────────────────────────────────────────────────┤
  │ US-061  As a user, I want to add an income entry (salary, freelance,    │
  │         gift) so I can track total inflows.                             │
  │         Priority: Critical | Release: v1.0 | Sprint: 4                  │
  ├─────────────────────────────────────────────────────────────────────────┤
  │ US-062  As a user, I want to choose from preset expense categories      │
  │         (Food, Transport, Shopping, Bills, Health, Education, Rent,     │
  │         Entertainment, Other) so I don't have to type categories.      │
  │         Priority: Critical | Release: v1.0 | Sprint: 4                  │
  ├─────────────────────────────────────────────────────────────────────────┤
  │ US-063  As a user, I want to edit or delete a transaction I logged      │
  │         incorrectly so my records stay accurate.                        │
  │         Priority: High | Release: v1.0 | Sprint: 4                      │
  └─────────────────────────────────────────────────────────────────────────┘

  WALKING: Set and track budget
  ┌─────────────────────────────────────────────────────────────────────────┐
  │ US-064  As a user, I want to set a monthly spending limit per category  │
  │         so I know when I'm overspending.                                │
  │         Priority: High | Release: v1.0 | Sprint: 4                      │
  ├─────────────────────────────────────────────────────────────────────────┤
  │ US-065  As a user, I want to receive an alert when I reach 80% of a    │
  │         category budget so I can slow down before hitting the limit.   │
  │         Priority: High | Release: v1.0 | Sprint: 4                      │
  ├─────────────────────────────────────────────────────────────────────────┤
  │ US-066  As a user, I want to see a budget progress bar per category     │
  │         so I can visually track how much of each budget I've used.     │
  │         Priority: High | Release: v1.0 | Sprint: 4                      │
  └─────────────────────────────────────────────────────────────────────────┘

  WALKING: View charts and insights
  ┌─────────────────────────────────────────────────────────────────────────┐
  │ US-067  As a user, I want to see a pie chart of spending by category   │
  │         so I instantly know where my money goes.                        │
  │         Priority: High | Release: v1.0 | Sprint: 5                      │
  ├─────────────────────────────────────────────────────────────────────────┤
  │ US-068  As a user, I want to see a bar chart of daily/weekly/monthly    │
  │         spending trends so I can spot high-spend periods.               │
  │         Priority: High | Release: v1.0 | Sprint: 5                      │
  ├─────────────────────────────────────────────────────────────────────────┤
  │ US-069  As a user, I want to see a line graph of my savings over time   │
  │         so I can track whether I'm saving more or less each month.     │
  │         Priority: Medium | Release: v1.0 | Sprint: 5                    │
  ├─────────────────────────────────────────────────────────────────────────┤
  │ US-070  As a user, I want to filter all views by Daily / Weekly /       │
  │         Monthly / Yearly so I can zoom in or out on my data.           │
  │         Priority: High | Release: v1.0 | Sprint: 5                      │
  ├─────────────────────────────────────────────────────────────────────────┤
  │ US-071  As a user, I want to see total income vs total expenses at the  │
  │         top of the money manager so I know my current balance.         │
  │         Priority: Critical | Release: v1.0 | Sprint: 4                  │
  └─────────────────────────────────────────────────────────────────────────┘

  WALKING: Savings goals
  ┌─────────────────────────────────────────────────────────────────────────┐
  │ US-072  As a user, I want to create a savings goal with a name, target  │
  │         amount, and optional deadline so I can plan my savings.         │
  │         Priority: High | Release: v1.0 | Sprint: 5                      │
  ├─────────────────────────────────────────────────────────────────────────┤
  │ US-073  As a user, I want to mark savings deposits toward a goal so I   │
  │         can track progress over time.                                   │
  │         Priority: High | Release: v1.0 | Sprint: 5                      │
  ├─────────────────────────────────────────────────────────────────────────┤
  │ US-074  As a user, I want to see a celebration animation (confetti)     │
  │         when I reach my savings goal so the achievement feels special.  │
  │         Priority: Medium | Release: v1.0 | Sprint: 6 (polish)           │
  └─────────────────────────────────────────────────────────────────────────┘

  WALKING: Transaction history
  ┌─────────────────────────────────────────────────────────────────────────┐
  │ US-075  As a user, I want to view all transactions in a scrollable list │
  │         sorted by date so I can review my history.                     │
  │         Priority: Critical | Release: v1.0 | Sprint: 4                  │
  ├─────────────────────────────────────────────────────────────────────────┤
  │ US-076  As a user, I want to search and filter transactions by          │
  │         category, date range, or amount so I can find specific entries. │
  │         Priority: High | Release: v1.0 | Sprint: 5                      │
  └─────────────────────────────────────────────────────────────────────────┘


================================================================================
EPIC 8: SETTINGS & SECURITY
================================================================================

BACKBONE: User customizes app behavior

  WALKING: Theme & preferences
  ┌─────────────────────────────────────────────────────────────────────────┐
  │ US-080  As a user, I want to toggle between dark and light mode so the  │
  │         app looks right in any lighting environment.                    │
  │         Priority: High | Release: v1.0 | Sprint: 6 (polish)             │
  ├─────────────────────────────────────────────────────────────────────────┤
  │ US-081  As a user, I want to set my currency symbol (₹ default) so     │
  │         financial figures display correctly.                            │
  │         Priority: Medium | Release: v1.0 | Sprint: 4                    │
  └─────────────────────────────────────────────────────────────────────────┘

  WALKING: Security
  ┌─────────────────────────────────────────────────────────────────────────┐
  │ US-082  As a user, I want to optionally set a PIN to lock the app       │
  │         so my notes and finances are private.                           │
  │         Priority: Medium | Release: v1.0 | Sprint: 6 (polish)           │
  ├─────────────────────────────────────────────────────────────────────────┤
  │ US-083  As a user, I want to unlock the app with fingerprint / face     │
  │         recognition (if PIN is set) so I can open it quickly.          │
  │         Priority: Medium | Release: v1.0 | Sprint: 6 (polish)           │
  └─────────────────────────────────────────────────────────────────────────┘


================================================================================
EPIC 9: FUTURE FEATURES (v2.0+)
================================================================================

  WALKING: Cloud & sync (v2)
  ┌─────────────────────────────────────────────────────────────────────────┐
  │ US-090  As a user, I want to back up my data to the cloud so I don't    │
  │         lose everything if I change phones.                             │
  │         Priority: — | Release: v2.0                                     │
  ├─────────────────────────────────────────────────────────────────────────┤
  │ US-091  As a user, I want to sync data across my Android and iOS        │
  │         devices so I have the same information everywhere.              │
  │         Priority: — | Release: v2.0                                     │
  └─────────────────────────────────────────────────────────────────────────┘

  WALKING: AI insights (v2)
  ┌─────────────────────────────────────────────────────────────────────────┐
  │ US-092  As a user, I want AI-powered spending insights ("You spend 40%  │
  │         more on food delivery on weekends") so I can change habits.    │
  │         Priority: — | Release: v2.0                                     │
  └─────────────────────────────────────────────────────────────────────────┘

  WALKING: Export (v2)
  ┌─────────────────────────────────────────────────────────────────────────┐
  │ US-093  As a user, I want to export my monthly money report as PDF so   │
  │         I can share it with my CA or save it for tax purposes.         │
  │         Priority: — | Release: v2.0                                     │
  └─────────────────────────────────────────────────────────────────────────┘

  WALKING: Widgets (v2)
  ┌─────────────────────────────────────────────────────────────────────────┐
  │ US-094  As a user, I want a home screen widget showing today's tasks    │
  │         and balance so I don't have to open the app.                   │
  │         Priority: — | Release: v2.0                                     │
  └─────────────────────────────────────────────────────────────────────────┘


--------------------------------------------------------------------------------
3. SPRINT ALLOCATION SUMMARY
--------------------------------------------------------------------------------

SPRINT  | STORIES                          | EPICS
--------|----------------------------------|-------------------------------
Sprint 1| US-001,004,010,011,012           | Onboarding, Navigation
        | US-020–028                       | Notes (full)
--------|----------------------------------|-------------------------------
Sprint 2| US-030–037                       | Tasks / Lists (full)
--------|----------------------------------|-------------------------------
Sprint 3| US-040–044, US-050–055           | Reminders + Alarms (full)
--------|----------------------------------|-------------------------------
Sprint 4| US-060–066, US-071, US-075       | Money Manager — core
        | US-081                           | Settings — currency
--------|----------------------------------|-------------------------------
Sprint 5| US-067–070, US-072–074, US-076   | Money Manager — charts + goals
--------|----------------------------------|-------------------------------
Sprint 6| US-011,035,074,080,082,083       | UI Polish + Animations + Security
        | US-002                           | Theme toggle (onboarding)
--------|----------------------------------|-------------------------------
Sprint 7| All US-* regression testing      | QA + Bug Fixes + Performance
        | Performance tuning               |
--------|----------------------------------|-------------------------------


--------------------------------------------------------------------------------
4. STORY COUNT SUMMARY
--------------------------------------------------------------------------------

  Epic                  | v1.0 Stories | v2 Stories | Total
  ----------------------|--------------|------------|-------
  Onboarding            | 4            | 0          | 4
  Navigation            | 3            | 0          | 3
  Notes                 | 9            | 0          | 9
  Tasks/Lists           | 8            | 0          | 8
  Reminders             | 5            | 0          | 5
  Alarms                | 6            | 0          | 6
  Money Manager         | 17           | 3          | 20
  Settings & Security   | 4            | 0          | 4
  Future (v2)           | 0            | 5          | 5
  ----------------------|--------------|------------|-------
  TOTAL                 | 56           | 8          | 64

  Critical Priority : 18 stories (must-have for launch)
  High Priority     : 27 stories (important for good UX)
  Medium Priority   : 11 stories (polish / delight features)


--------------------------------------------------------------------------------
5. ACCEPTANCE CRITERIA EXAMPLES (for key stories)
--------------------------------------------------------------------------------

US-020 — Create a note
  GIVEN I am on the Notes screen
  WHEN I tap the FAB (+) button
  THEN a new note editor opens
  AND I can type a title and body
  WHEN I tap the back button or save
  THEN the note is saved and appears in the notes list
  AND the entire flow completes in under 5 seconds

US-053 — Alarm fires in background
  GIVEN I have set an alarm for a specific time
  AND the Endless app is closed (not in recent apps)
  WHEN the alarm time arrives
  THEN the alarm sound plays at full volume
  AND an alarm screen appears on the lock screen
  AND this behavior works on Android 10+ with battery optimization

US-060 — Add expense in under 10 seconds
  GIVEN I am on the Money Manager screen
  WHEN I tap the FAB button
  THEN an expense entry sheet opens
  AND I can enter amount, select category, and confirm
  WHEN I tap Save
  THEN the transaction appears in the list
  AND the total balance updates instantly
  AND the entire flow is completable in under 10 seconds

US-074 — Savings goal celebration
  GIVEN I have a savings goal with target amount ₹10,000
  WHEN the total amount saved reaches or exceeds ₹10,000
  THEN a confetti animation plays on screen
  AND a congratulations message is displayed
  AND the goal is marked as "Achieved" ✅

================================================================================
END OF DOCUMENT
Next Step: Phase 2 — SRS (Software Requirements Specification) + FRD
================================================================================
