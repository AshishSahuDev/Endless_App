# Endless App

> **One app. Everything you need.**  
> Notes · Tasks · Reminders · Alarms · Money Manager

A cross-platform mobile application (Android + iOS) built with Flutter, targeting Gen-Z and Gen-Alpha users. Replaces 5 separate apps with one beautifully designed, offline-first solution.

---

## Quick Links

| Item | Detail |
|---|---|
| **Platform** | Android 8.0+ · iOS 14.0+ |
| **Framework** | Flutter 3.x + Dart |
| **Architecture** | Clean Architecture + MVVM |
| **State** | Riverpod |
| **Database** | Isar (local, offline-first) |
| **Developer** | Ashish Sahu — its.sahuashish@gmail.com |

---

## Project Status

| Phase | Name | Status |
|---|---|---|
| Phase 0 | Initiation | ✅ Complete |
| Phase 1 | Discovery | ✅ Complete |
| Phase 2 | Specification (SRS + FRD) | 🔜 Next |
| Phase 3 | Technical Planning | ⬜ Pending |
| Phase 4 | Project Planning | ⬜ Pending |
| Phase 5 | Design | ⬜ Pending |
| Phase 6 | Dev Environment Setup | ⬜ Pending |
| Phase 7 | Development (7 Sprints) | ⬜ Pending |
| Phase 8 | Release | ⬜ Pending |

---

## Repository Structure

```
Endless_App/
│
├── README.md                          ← You are here
│
├── docs/
│   ├── phase-0-initiation/
│   │   ├── 01_project_requirements.md ← Full app requirements & tech decisions
│   │   ├── 02_project_charter.md      ← Scope, objectives, timeline, sign-off
│   │   └── 03_feasibility_study.md    ← GO/NO-GO across 5 dimensions
│   │
│   ├── phase-1-discovery/
│   │   ├── 01_brd.md                  ← 15 Business Requirements
│   │   ├── 02_user_personas.md        ← 3 Personas: Riya, Arjun, Zara
│   │   └── 03_user_story_map.md       ← 64 User Stories across 9 Epics
│   │
│   ├── phase-2-specification/         ← SRS + FRD (coming soon)
│   ├── phase-3-technical-planning/    ← TAD + DB Design + API Contracts (coming soon)
│   ├── phase-4-project-planning/      ← WBS + Sprint Plan + Risk Register (coming soon)
│   ├── phase-5-design/                ← Design System + Wireframes + Mockups (coming soon)
│   └── phase-6-dev-setup/             ← Flutter setup + folder structure + CI/CD (coming soon)
│
└── app/                               ← Flutter source code (starts Phase 7)
```

---

## Core Features

| # | Feature | Description |
|---|---|---|
| 1 | **Notes** | Color-coded, rich text, pin, archive, search |
| 2 | **Tasks** | Checklist, priorities, due dates, drag-drop reorder |
| 3 | **Reminders** | One-time + recurring, push notifications, snooze |
| 4 | **Alarm** | Multiple alarms, background wake, label, repeat by day |
| 5 | **Money Manager** | Income/expense tracking, budgets, charts, savings goals |

---

## Target Users

| Persona | Profile | Primary Need |
|---|---|---|
| Riya | College student, 20, Pune | Alarms + Notes + Basic budgeting |
| Arjun | Software engineer, 25, Bengaluru | Money clarity + Finance charts |
| Zara | Freelancer/designer, 23, Mumbai | Task deadlines + Irregular income tracking |

---

## Design Vision

- **Dark mode first** — `#0A0A0F` background, feels premium on OLED
- **Accent palette** — Electric purple `#7C3AED`, hot pink `#EC4899`, electric blue `#3B82F6`
- **Typography** — Sora / Plus Jakarta Sans + Space Grotesk for numbers
- **Effects** — Glassmorphism cards, gradient buttons, fluid 60fps animations
- **Offline-first** — All data stored locally on device, zero server dependency

---

*Pre-development documentation maintained by Ashish Sahu*
