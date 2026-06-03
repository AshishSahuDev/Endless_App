# Wireframes (ASCII — 8 Key Screens)
**Project:** Endless App | **Version:** 1.0 | **Date:** 2026-06-03 | **Author:** Ashish Sahu

Screen size reference: 390×844pt (iPhone 14 / equivalent Android)
`[ ]` = button/card  `___` = text field  `###` = image/chart area

---

## WF-01 — Home Dashboard

```
┌────────────────────────────────────┐
│ ≡  Endless               🔔  👤   │  ← Navbar
├────────────────────────────────────┤
│                                    │
│  Good morning, Ashish ☀️           │  ← Greeting
│  Tuesday, June 3                   │
│                                    │
│ ┌──────┐ ┌──────┐ ┌──────┐ ┌─────┐│  ← Quick Stats
│ │ 📝   │ │ ✅   │ │ 🔔   │ │ 💰  ││
│ │  12  │ │  5   │ │  3   │ │+2.4K││
│ │Notes │ │Tasks │ │ Rem. │ │ Bal.││
│ └──────┘ └──────┘ └──────┘ └─────┘│
│                                    │
│  ── Modules ──────────────────     │
│ ┌──────────────┐ ┌───────────────┐ │  ← Module cards
│ │ 📝  Notes    │ │ ✅  Tasks     │ │
│ │  12 notes    │ │  5 pending    │ │
│ └──────────────┘ └───────────────┘ │
│ ┌──────────────┐ ┌───────────────┐ │
│ │ 🔔 Reminders │ │ ⏰  Alarms    │ │
│ │  3 upcoming  │ │  2 active     │ │
│ └──────────────┘ └───────────────┘ │
│ ┌─────────────────────────────────┐│
│ │ 💰  Money Manager               ││
│ │  Balance: ₹12,400 this month    ││
│ └─────────────────────────────────┘│
│                                    │
│  ── Recent Activity ───────────    │
│  📝 "Meeting notes" edited  2m ago │
│  ✅ "Buy groceries" done   10m ago │
│  💰 -₹250 Food & Drink    12m ago  │
│                                    │
├────────────────────────────────────┤
│  🏠    ✅    ⏰    🔔    💰         │  ← Bottom Nav
└────────────────────────────────────┘
```

---

## WF-02 — Notes List

```
┌────────────────────────────────────┐
│  Notes                    🔍  ⋮   │  ← Navbar
├────────────────────────────────────┤
│ 🔍 Search notes...                 │  ← Search bar
├────────────────────────────────────┤
│ [All] [📌 Pinned] [Archive] [🎨]   │  ← Filter chips
├────────────────────────────────────┤
│                                    │
│ ┌──────────────┐ ┌───────────────┐ │  ← Note grid
│ │ 📌           │ │               │ │    (2 col)
│ │ Meeting Notes│ │  Goa Trip 🏖  │ │
│ │ Today's sync │ │  Plan the     │ │
│ │ discussed... │ │  budget and   │ │
│ │  Jun 3  📝   │ │  packing list │ │
│ └──────────────┘ │  Jun 1        │ │
│ ┌──────────────┐ └───────────────┘ │
│ │ 🟡           │ ┌───────────────┐ │
│ │ Buy list     │ │ 🟣            │ │
│ │ • Milk       │ │ Project ideas │ │
│ │ • Eggs       │ │ 1. Dark mode  │ │
│ │ • Bread      │ │ 2. Charts     │ │
│ │  Jun 2       │ │  May 30       │ │
│ └──────────────┘ └───────────────┘ │
│                                    │
│ ┌──────────────┐ ┌───────────────┐ │
│ │              │ │               │ │
│ │  React Notes │ │  Workout log  │ │
│ │  ...         │ │  ...          │ │
│ └──────────────┘ └───────────────┘ │
│                                    │
├────────────────────────────────────┤
│  🏠    ✅    ⏰    🔔    💰  [+]   │  ← FAB bottom-right
└────────────────────────────────────┘
```

---

## WF-03 — Note Editor

```
┌────────────────────────────────────┐
│  ←          Note        📌  🗑    │  ← Navbar (no bottom nav)
├────────────────────────────────────┤
│  ○ ● ○ ○ ○ ○ ○ ○                  │  ← Color picker (8 dots)
├────────────────────────────────────┤
│                                    │
│  Meeting Notes                     │  ← Title (large, no border)
│  ___________________________________
│                                    │
│  Discussed Q3 targets with the     │  ← Body (rich text)
│  team. Key action items:           │
│                                    │
│  • Ashish: complete dashboard by   │
│    Friday                          │
│  • Riya: design review on Monday   │
│  • Next meeting: June 10           │
│                                    │
│                                    │
│                                    │
│                                    │
│                                    │
│                                    │
├────────────────────────────────────┤
│  B  I  U  •  ─────────  📌  🗄    │  ← Rich text toolbar
│  Jun 3, 2026  ·  128 chars         │  ← Metadata
└────────────────────────────────────┘
```

---

## WF-04 — Task List

```
┌────────────────────────────────────┐
│  Tasks                        ⋮   │
├────────────────────────────────────┤
│ [All][Work][Personal][Shopping][+] │  ← Category filter (scroll)
├────────────────────────────────────┤
│ [ All 12 ] [ Active 8 ] [ Done 4 ] │  ← Filter tabs
├────────────────────────────────────┤
│  ── Today ──────────────────────   │
│                                    │
│  ⣿ ☐  Submit project report    ⋮  │  ← High priority (red dot)
│       🔴 High · Due: Today         │
│                                    │
│  ⣿ ☐  Call dentist             ⋮  │  ← Medium priority
│       🟡 Med · No due date         │
│                                    │
│  ⣿ ☑  Buy groceries               │  ← Completed (strikethrough)
│       ✅ Done · Jun 2              │
│                                    │
│  ── Upcoming ───────────────────   │
│                                    │
│  ⣿ ☐  Flutter tutorial         ⋮  │
│       🟢 Low · Due: Jun 7          │
│                                    │
│  ⣿ ☐  Monthly report           ⋮  │
│       🔴 High · Due: Jun 10        │
│                                    │
│  ⣿ ☐  Team retrospective       ⋮  │
│       🟡 Med · Due: Jun 12         │
│                                    │
├────────────────────────────────────┤
│  🏠    ✅    ⏰    🔔    💰  [+]   │
└────────────────────────────────────┘
```

---

## WF-05 — Money Manager Dashboard

```
┌────────────────────────────────────┐
│  Money                        ⋮   │
├────────────────────────────────────┤
│                                    │
│  ← Jun 2026 →                     │  ← Month selector
│                                    │
│ ┌───────────┐┌───────────┐┌──────┐ │  ← Summary cards
│ │  Income   ││  Expense  ││ Bal. │ │
│ │           ││           ││      │ │
│ │ ₹45,000   ││ ₹28,400   ││16.6K │ │
│ │ ↑12% prev ││ ↓5% prev  ││  🟢  │ │
│ └───────────┘└───────────┘└──────┘ │
│                                    │
│  ── Budget Overview ─────────────  │
│                                    │
│  🍔 Food & Drink                   │
│  ████████████░░░░  ₹2,400/₹3,000  │  ← Progress bar 80%
│                                    │
│  🚗 Transport                      │
│  ██████░░░░░░░░░░  ₹900/₹2,000    │
│                                    │
│  🎮 Entertainment      ⚠️ OVER    │
│  ████████████████  ₹1,200/₹1,000  │  ← Red = over budget
│                                    │
│  ── Recent Transactions ─────────  │
│                                    │
│  🍔 Zomato         -₹350  Jun 3   │
│  💰 Salary      +₹45,000  Jun 1   │
│  🚗 Uber            -₹85  May 31  │
│              [View all →]          │
│                                    │
├────────────────────────────────────┤
│  🏠    ✅    ⏰    🔔    💰  [+]   │
└────────────────────────────────────┘
```

---

## WF-06 — Add Transaction (Bottom Sheet)

```
┌────────────────────────────────────┐
│  (App content blurred behind)      │
│                                    │
│                                    │
│                                    │
├────────────────────────────────────┤  ← Bottom sheet
│         ──── (drag handle)         │
│                                    │
│   [ 💸 Expense ]  [ 💰 Income  ]   │  ← Type toggle
│                                    │
│         ₹  0                       │  ← Amount display
│         ─────────────────          │    (large, centered)
│                                    │
│  ┌─────────────────────────────┐   │
│  │ Category                    │   │  ← Category grid
│  │ 🍔    🚗    🛒    🎬    🏥  │   │
│  │Food  Trans Shop  Ent. Health │   │
│  │ 🔌    📚    🏠    🎁    ⋮   │   │
│  │Bills  Edu  Rent  Other More  │   │
│  └─────────────────────────────┘   │
│                                    │
│  📝 Add a note (optional)___       │  ← Note input
│                                    │
│  📅 Today, June 3                  │  ← Date (tappable)
│                                    │
│  ┌─────────────────────────────┐   │
│  │  1  │  2  │  3  │ ← del    │   │  ← Numpad
│  │  4  │  5  │  6  │          │   │
│  │  7  │  8  │  9  │   SAVE   │   │
│  │  .  │  0  │  ↵  │          │   │
│  └─────────────────────────────┘   │
└────────────────────────────────────┘
```

---

## WF-07 — Charts Screen

```
┌────────────────────────────────────┐
│  Analytics                    ⋮   │
├────────────────────────────────────┤
│ [Daily] [Weekly] [Monthly] [Yearly]│  ← Time filter
├────────────────────────────────────┤
│  [🥧 Pie] [📊 Bar] [📈 Line]       │  ← Chart type
├────────────────────────────────────┤
│                                    │
│         ╭───────╮                  │  ← Pie chart
│       ╭─┤ 34%   ├─╮               │
│      ╱  │ Food  │  ╲              │
│     │ ╭─╯       ╰─╮ │             │
│     │ │  28% Trans  │ │            │
│      ╲  ╰─────────╯  ╱            │
│       ╰──────────────╯            │
│                                    │
│  Legend:                           │
│  🔴 Food & Drink    ₹2,400  34%   │
│  🟠 Transport       ₹1,980  28%   │
│  🟣 Entertainment   ₹1,200  17%   │
│  🔵 Shopping        ₹840   12%   │
│  ⚫ Other           ₹630    9%   │
│                                    │
│  Total spent: ₹7,050               │
│  vs last month: ↓ 12%   🟢        │
│                                    │
├────────────────────────────────────┤
│  🏠    ✅    ⏰    🔔    💰        │
└────────────────────────────────────┘
```

---

## WF-08 — Alarm List

```
┌────────────────────────────────────┐
│  Alarms                       [+] │
├────────────────────────────────────┤
│                                    │
│  Next alarm: 7:00 AM — in 9h 22m  │  ← Countdown info
│                                    │
│ ┌──────────────────────────────┐   │
│ │  7:00 AM              [●  ] │   │  ← Enabled alarm (purple)
│ │  Wake up 💪                  │   │
│ │  Mon  Tue  Wed  Thu  Fri     │   │
│ └──────────────────────────────┘   │
│                                    │
│ ┌──────────────────────────────┐   │
│ │  8:30 AM              [  ●] │   │  ← Disabled alarm (gray)
│ │  Gym session                 │   │
│ │  Mon  Wed  Fri               │   │
│ └──────────────────────────────┘   │
│                                    │
│ ┌──────────────────────────────┐   │
│ │  10:00 AM             [●  ] │   │
│ │  Team standup 🧑‍💻           │   │
│ │  Mon  Tue  Wed  Thu  Fri     │   │
│ └──────────────────────────────┘   │
│                                    │
│ ┌──────────────────────────────┐   │
│ │  11:45 PM             [  ●] │   │
│ │  Sleep reminder 😴           │   │
│ │  Everyday                    │   │
│ └──────────────────────────────┘   │
│                                    │
├────────────────────────────────────┤
│  🏠    ✅    ⏰    🔔    💰        │
└────────────────────────────────────┘
```

---

*Document: 03_wireframes.md | Phase 5 — Design*
