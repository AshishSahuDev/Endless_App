================================================================================
                        ENDLESS APP — PROJECT CHARTER
                        Version: 1.0  |  Date: 2026-06-03
                        Owner: Ashish Sahu
================================================================================

--------------------------------------------------------------------------------
1. PROJECT IDENTIFICATION
--------------------------------------------------------------------------------

Project Name      : Endless
Project Code      : ENDLESS-MOB-v1
Version           : 1.0
Date              : 2026-06-03
Project Owner     : Ashish Sahu
Contact           : its.sahuashish@gmail.com
GitHub            : https://github.com/AshishSahuDev/Endless_App
Status            : Approved — Phase 0 Complete


--------------------------------------------------------------------------------
2. EXECUTIVE SUMMARY
--------------------------------------------------------------------------------

"Endless" is a cross-platform mobile application built with Flutter, targeting
Gen-Z and Gen-Alpha users (ages 16–30). The app consolidates five daily
productivity and financial tools — Notes, Tasks, Reminders, Alarms, and a
Money Manager — into a single, beautifully designed, offline-first application.

The project follows a full MNC-level pre-development process across 8 phases,
from requirements gathering through App Store release. Development will be done
by Ashish Sahu (solo developer) using industry-standard tools and architecture.


--------------------------------------------------------------------------------
3. PROBLEM STATEMENT
--------------------------------------------------------------------------------

Young users (Gen-Z / Gen-Alpha) currently manage their daily life across 4–5
separate apps:
  - Notes apps (Google Keep, Notion)
  - Task managers (Todoist, TickTick)
  - Alarm/reminder apps (built-in clock)
  - Finance apps (Walnut, Money Manager)

There is no single, beautifully designed app that unifies all these needs with
a modern aesthetic that resonates with this demographic.

Endless solves this by delivering one app that does everything — locally, fast,
and with a premium feel.


--------------------------------------------------------------------------------
4. PROJECT OBJECTIVES (SMART Goals)
--------------------------------------------------------------------------------

OBJ-1  SPECIFIC    : Build a Flutter mobile app with 5 core feature modules
       MEASURABLE  : All 5 features fully functional and tested
       ACHIEVABLE  : Yes — developer has Java/Spring Boot background; Dart is similar
       RELEVANT    : Directly serves target audience need
       TIME-BOUND  : Feature-complete by Sprint 7 (14 weeks from dev start)

OBJ-2  Performance : App cold start < 2 seconds on mid-range Android device

OBJ-3  Quality     : Zero critical bugs at release; 4.5+ star target rating

OBJ-4  Reach       : Published on Google Play Store + Apple App Store (v1.0)

OBJ-5  UX          : User can create a note in < 5s, log an expense in < 10s


--------------------------------------------------------------------------------
5. PROJECT SCOPE
--------------------------------------------------------------------------------

IN SCOPE (Version 1.0)
  ✅ Notes module (create, edit, delete, color, pin, archive, search, rich text)
  ✅ Tasks / Lists module (checklist, priority, due dates, categories, drag-drop)
  ✅ Reminders module (one-time + recurring, push notifications, snooze)
  ✅ Alarm module (multiple alarms, background wake, repeat by day)
  ✅ Money Manager (income/expense, category budgets, 3 chart types, savings goals)
  ✅ Dark mode (default) + Light mode toggle
  ✅ Offline-first (all data stored locally on device)
  ✅ Optional app lock (PIN / Biometric)
  ✅ Android 8.0+ and iOS 14.0+ support

OUT OF SCOPE (Version 1.0)
  ❌ Cloud sync / backup
  ❌ Multi-device sync
  ❌ Collaboration / sharing
  ❌ AI-powered insights
  ❌ Bank account integration
  ❌ Web version
  ❌ Home screen widgets (stretch goal)
  ❌ PDF export (stretch goal)


--------------------------------------------------------------------------------
6. DELIVERABLES
--------------------------------------------------------------------------------

PHASE 0 — INITIATION
  ✅ Project Requirements Prompt
  ✅ Project Charter (this document)
  ✅ Feasibility Study

PHASE 1 — DISCOVERY
  [ ] Business Requirements Document (BRD)
  [ ] User Personas (3 personas)
  [ ] User Story Map

PHASE 2 — SPECIFICATION
  [ ] Software Requirements Specification (SRS)
  [ ] Functional Requirements Document (FRD)

PHASE 3 — TECHNICAL PLANNING
  [ ] Technical Architecture Document (TAD)
  [ ] Database Design Document (ERD + Schema)
  [ ] API / Data Contract Design

PHASE 4 — PROJECT PLANNING
  [ ] Work Breakdown Structure (WBS)
  [ ] Sprint Plan (7 sprints × 2 weeks)
  [ ] Risk Register
  [ ] Definition of Done (DoD)

PHASE 5 — DESIGN
  [ ] Design System / Style Guide
  [ ] Wireframes (low fidelity)
  [ ] High-Fidelity Mockups
  [ ] Interactive Prototype

PHASE 6 — DEV ENVIRONMENT
  [ ] Flutter installation + tools guide
  [ ] Project scaffold + folder structure
  [ ] Git repo setup + branching strategy
  [ ] Coding standards document
  [ ] CI/CD setup

PHASE 7 — DEVELOPMENT (7 Sprints × 2 weeks = 14 weeks)
  [ ] Sprint 1 : Project setup + Notes feature
  [ ] Sprint 2 : Tasks + Lists feature
  [ ] Sprint 3 : Alarms + Reminders
  [ ] Sprint 4 : Money Manager (basic — transactions + balance)
  [ ] Sprint 5 : Money Manager (charts + savings goals)
  [ ] Sprint 6 : UI polish + animations + app lock
  [ ] Sprint 7 : Testing, QA, bug fixes, performance tuning

PHASE 8 — RELEASE
  [ ] Google Play Store submission
  [ ] Apple App Store submission
  [ ] Release notes v1.0


--------------------------------------------------------------------------------
7. TECH STACK SUMMARY
--------------------------------------------------------------------------------

Layer               | Technology        | Justification
--------------------|-------------------|------------------------------------------
Framework           | Flutter           | Best UI control, 120fps, single codebase
Language            | Dart              | Java-like syntax, null-safe, native ARM
State Management    | Riverpod          | Type-safe, testable, Clean Architecture
Local Database      | Isar              | Fastest Flutter NoSQL, type-safe queries
Notifications       | flutter_local_    | Industry standard for push/reminders
                    | notifications     |
Alarm               | alarm package     | Reliable background wake-lock
Charts              | fl_chart          | Beautiful, customizable charts
Animations          | flutter_animate   | Micro-animations made easy
                    | + lottie          | Complex celebration animations
Typography          | google_fonts      | Sora / Plus Jakarta Sans
Icons               | iconsax           | Gen-Z style icon set
Glass effects       | glassmorphism pkg | Frosted glass cards
Architecture        | Clean Arch + MVVM | Scalable, testable, MNC standard
Version Control     | Git + GitFlow     | Feature branches, safe merges


--------------------------------------------------------------------------------
8. PROJECT TIMELINE (HIGH LEVEL)
--------------------------------------------------------------------------------

Milestone                        | Estimated Duration
---------------------------------|-------------------
Phase 0 — Initiation             | Week 1         ✅ Done
Phase 1 — Discovery              | Week 1–2
Phase 2 — Specification          | Week 2–3
Phase 3 — Technical Planning     | Week 3–4
Phase 4 — Project Planning       | Week 4
Phase 5 — Design                 | Week 4–6
Phase 6 — Dev Environment Setup  | Week 6
Phase 7 — Development (7 Sprints)| Week 7–21 (14 weeks)
Phase 8 — Release                | Week 22
---------------------------------|-------------------
TOTAL ESTIMATED DURATION         | ~22 weeks (~5.5 months)


--------------------------------------------------------------------------------
9. RESOURCES
--------------------------------------------------------------------------------

HUMAN RESOURCES
  Developer     : Ashish Sahu (solo, full-stack)
  Estimated Time: 2–4 hours/day (evenings + weekends)

TOOLS & COST
  Flutter SDK       : Free (Google open source)
  Dart              : Free (bundled with Flutter)
  VS Code / Android Studio : Free
  Git + GitHub      : Free (AshishSahuDev account)
  Isar Database     : Free + open source
  All Flutter packages : Free (pub.dev)
  Google Play Store : $25 one-time developer fee
  Apple App Store   : $99/year developer fee
  Firebase (future) : Free tier available

  TOTAL COST (v1.0): ~$25–$124 (Play Store + optional App Store)


--------------------------------------------------------------------------------
10. RISKS (HIGH LEVEL — detail in Risk Register, Phase 4)
--------------------------------------------------------------------------------

RISK-1  Alarm reliability on iOS
  Probability : Medium | Impact: High
  Mitigation  : Use alarm package; test on real device early

RISK-2  Background process killed by Android battery optimization
  Probability : Medium | Impact: High
  Mitigation  : Request battery optimization exemption; use WorkManager

RISK-3  App Store rejection (Apple)
  Probability : Low | Impact: High
  Mitigation  : Follow Apple HIG; review guidelines before submission

RISK-4  Scope creep (adding features mid-development)
  Probability : High | Impact: Medium
  Mitigation  : Strict v1.0 scope freeze; park new ideas in v2 backlog

RISK-5  Developer time constraints (solo developer)
  Probability : Medium | Impact: Medium
  Mitigation  : Time-box sprints; MVP features first; polish later


--------------------------------------------------------------------------------
11. SUCCESS CRITERIA
--------------------------------------------------------------------------------

The project is considered successful when ALL of the following are true:

  ✓ All 5 feature modules are fully functional
  ✓ App cold start < 2 seconds on Redmi Note 10 (benchmark device)
  ✓ All alarms fire reliably in background on Android + iOS
  ✓ App published on Google Play Store (minimum)
  ✓ Zero data loss on app crash (auto-save verified)
  ✓ App rated 4.5+ stars by first 10 users (internal testers)
  ✓ UI matches design system (Gen-Z aesthetic approved)


--------------------------------------------------------------------------------
12. APPROVAL & SIGN-OFF
--------------------------------------------------------------------------------

Project Owner : Ashish Sahu
Date          : 2026-06-03
Status        : APPROVED — Proceed to Phase 1

================================================================================
END OF DOCUMENT
Next Step: Feasibility Study → then Phase 1 (BRD, User Personas, User Story Map)
================================================================================
