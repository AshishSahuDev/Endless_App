================================================================================
                    ENDLESS APP — PROJECT REQUIREMENTS PROMPT
                    Version: 1.0  |  Date: 2026-06-03
                    Owner: Ashish Sahu
================================================================================

--------------------------------------------------------------------------------
SECTION 1: WHO AM I / CONTEXT
--------------------------------------------------------------------------------

Developer     : Ashish Sahu
Background    : Java Full Stack Developer
Experience    : Backend (Java/Spring Boot), Frontend (Web)
Goal          : Build a cross-platform mobile application from scratch
                following complete MNC-level pre-development process
Working Dir   : /home/ashish/Documents/Endless/MobileApp
Platform      : Linux (Ubuntu)


--------------------------------------------------------------------------------
SECTION 2: WHAT IS THIS APP?
--------------------------------------------------------------------------------

App Name      : Endless
App Type      : Personal Productivity + Finance Management Mobile App
Platforms     : Android + iOS (Cross-Platform, single codebase)
Target Users  : Gen-Z and Gen-Alpha (ages 16–30)
               - College students
               - Young working professionals
               - Freelancers
               - Anyone who wants to organize their life + track money


--------------------------------------------------------------------------------
SECTION 3: WHAT PROBLEM DOES IT SOLVE?
--------------------------------------------------------------------------------

Problem Statement:
  Young people struggle to manage their daily life in one place.
  They use 4-5 different apps for notes, reminders, alarms, and budgeting.
  There is no single beautiful, modern app that combines all these needs.

Solution:
  "Endless" — One app. Everything you need.
  Notes + Tasks + Reminders + Alarms + Money Management
  All in one place. Beautiful. Fast. Works offline.


--------------------------------------------------------------------------------
SECTION 4: CORE FEATURES REQUIRED (What I Want)
--------------------------------------------------------------------------------

FEATURE 1 — NOTES
  - Create, edit, delete notes
  - Color-coded notes (multiple color themes)
  - Add emoji to notes
  - Pin important notes to top
  - Archive old notes
  - Search through notes
  - Rich text (bold, italic, bullet points)

FEATURE 2 — LISTS / TASKS
  - Create to-do lists / checklists
  - Mark tasks as done (swipe gesture)
  - Set priority levels: High / Medium / Low (color coded)
  - Set due dates on tasks
  - Organize tasks into categories (Work, Personal, Shopping, etc.)
  - Reorder tasks by drag & drop
  - Filter tasks: All / Active / Completed

FEATURE 3 — REMINDERS
  - Set one-time reminders
  - Set recurring reminders (daily, weekly, custom)
  - Link reminders to specific notes or tasks
  - Custom reminder message
  - Push notification delivery
  - Snooze reminder option

FEATURE 4 — ALARM
  - Set multiple alarms
  - Custom alarm label / name
  - Choose alarm sound (multiple options)
  - Snooze with configurable snooze duration
  - Dismiss alarm
  - Repeat alarm: specific days of week
  - Enable / Disable alarm toggle
  - Works reliably in background (even when app is closed)

FEATURE 5 — MONEY MANAGER (Spending Tracker)
  - Add income entries (salary, freelance, gift, other)
  - Add expense entries with categories:
      Food & Drink, Transport, Shopping, Entertainment,
      Bills & Utilities, Health, Education, Rent, Other
  - Set monthly budget limit per category
  - Budget alert when 80% of budget is used
  - Budget alert when 100% (limit exceeded)
  - View total income vs total expenses (balance)
  - Visual charts:
      - Pie chart: spending by category
      - Bar chart: daily/weekly/monthly spending trend
      - Line graph: savings over time
  - Time filters: Daily / Weekly / Monthly / Yearly view
  - Savings goal tracker:
      - Set a savings goal with target amount
      - Track progress toward goal
      - Celebrate when goal is reached (animation)
  - Transaction history with search & filter
  - Export report as PDF (future feature)


--------------------------------------------------------------------------------
SECTION 5: NON-FUNCTIONAL REQUIREMENTS (Quality Standards)
--------------------------------------------------------------------------------

PERFORMANCE
  - App cold start: under 2 seconds
  - Smooth animations: 60fps minimum, 120fps target
  - All core features work fully OFFLINE (no internet required)
  - Local data sync instantly (no loading spinners for local operations)

DESIGN & UI
  - Gen-Z / Gen-Alpha aesthetic (see Section 7 for details)
  - Dark mode as default
  - Light mode available (toggle)
  - Responsive across all screen sizes
  - Accessibility: minimum AA contrast ratio

COMPATIBILITY
  - Android: version 8.0 (API level 26) and above
  - iOS: version 14.0 and above
  - Tablet support: basic (stretch goal)

SECURITY
  - All data stored locally on device (privacy first)
  - Optional app lock: PIN or Biometric (fingerprint / face)
  - No sensitive data sent to any server (local-first)

RELIABILITY
  - Alarms must fire even when app is in background or closed
  - Reminders must deliver push notifications reliably
  - No data loss on app crash (auto-save)


--------------------------------------------------------------------------------
SECTION 6: WHAT WE DECIDED & WHY (Tech Stack Decisions)
--------------------------------------------------------------------------------

DECISION 1: CROSS-PLATFORM FRAMEWORK
  Options Considered:
    a) Native Android (Kotlin) — only Android, best performance
    b) React Native — cross-platform, JavaScript, large ecosystem
    c) Flutter — cross-platform, Dart, best UI/animation control
    d) Ionic — web-based, weakest performance

  CHOSEN: Flutter
  Reason:
    - App must run on BOTH Android and iOS from one codebase
    - Flutter has the best animation and UI customization capability
    - Flutter renders its own UI (not native components) = pixel-perfect
      on both platforms, ideal for custom Gen-Z design
    - Flutter supports 60/120fps animations natively
    - Google-backed, strong long-term support
    - Glassmorphism, gradients, blur effects are easy to implement
    - Dart is easy to learn, especially with Java background

DECISION 2: PROGRAMMING LANGUAGE
  CHOSEN: Dart (Flutter's language)
  Reason:
    - Dart is very similar to Java in syntax (easy transition)
    - Strongly typed (less runtime errors)
    - Null-safe (modern language feature)
    - Compiled to native ARM code (fast performance)

DECISION 3: STATE MANAGEMENT
  Options Considered:
    a) setState — too simple for this app size
    b) Provider — simple but limited
    c) Bloc — powerful but verbose
    d) Riverpod — modern, type-safe, flexible

  CHOSEN: Riverpod
  Reason:
    - Best balance of simplicity and power
    - Compile-time safe (errors caught early)
    - Works well with Clean Architecture
    - Better testability than Provider

DECISION 4: LOCAL DATABASE
  Options Considered:
    a) SQLite (sqflite) — relational, needs SQL queries
    b) Hive — fast NoSQL, key-value
    c) Isar — fastest NoSQL for Flutter, typed, no SQL needed

  CHOSEN: Isar
  Reason:
    - Significantly faster than sqflite for read/write
    - Type-safe queries (no raw SQL strings)
    - Built for Flutter, easy integration with Riverpod
    - Supports complex queries needed for money manager filters
    - Free and open source

DECISION 5: NOTIFICATIONS & ALARMS
  CHOSEN:
    - flutter_local_notifications → for reminders & alerts
    - alarm package → for actual alarm clock functionality
  Reason:
    - These are the most reliable packages for their specific purpose
    - alarm package handles background wake-locks correctly on both platforms

DECISION 6: UI LIBRARIES
  CHOSEN:
    - flutter_animate → smooth micro-animations
    - lottie → complex animation files (celebration, onboarding)
    - fl_chart → beautiful charts for money manager
    - google_fonts → modern typography (Sora / Plus Jakarta Sans)
    - glassmorphism → glass-effect cards
    - iconsax → Gen-Z style icon pack

DECISION 7: ARCHITECTURE PATTERN
  CHOSEN: Clean Architecture + MVVM
  Reason:
    - Separation of concerns (UI, Logic, Data are independent)
    - Easy to test each layer
    - Easy to add features without breaking existing ones
    - Industry standard in MNC companies
    - Scales well as app grows

DECISION 8: VERSION CONTROL STRATEGY
  CHOSEN: Git + GitFlow branching
    main      → stable, production-ready code
    develop   → active development integration
    feature/* → individual feature branches
    hotfix/*  → urgent bug fixes
  Reason: Industry standard, safe, organized


--------------------------------------------------------------------------------
SECTION 7: UI / UX VISION (Gen-Z & Gen-Alpha Design)
--------------------------------------------------------------------------------

DESIGN PHILOSOPHY:
  - Dark mode first (feels premium, saves battery on OLED)
  - Feels like a luxury app, not a utility app
  - Every interaction has a satisfying animation
  - Colors feel alive, not flat

COLOR PALETTE:
  Primary Background : #0A0A0F (near black, deep space)
  Secondary BG       : #12121A (card backgrounds)
  Accent Purple      : #7C3AED (vibrant violet)
  Accent Pink        : #EC4899 (hot pink)
  Accent Blue        : #3B82F6 (electric blue)
  Accent Green       : #10B981 (emerald - for income/success)
  Accent Red         : #EF4444 (for expenses/alerts)
  Text Primary       : #FFFFFF
  Text Secondary     : #94A3B8
  Glass overlay      : rgba(255, 255, 255, 0.05)

TYPOGRAPHY:
  Primary Font : "Sora" or "Plus Jakarta Sans"
  Heading      : Bold, large, high contrast
  Body         : Medium weight, comfortable line height
  Numbers      : "Space Grotesk" (great for financial figures)

UI COMPONENTS STYLE:
  - Cards: Glassmorphism (frosted glass with blur + border glow)
  - Buttons: Gradient fill (purple → pink or blue → purple)
  - Navigation: Bottom tab bar with animated pill indicator
  - Inputs: Floating label with glow on focus
  - Charts: Gradient fills, smooth curved lines
  - Lists: Swipe-to-action with haptic feedback

ANIMATIONS:
  - Page transitions: Smooth slide + fade
  - List items: Staggered entrance animation
  - Task complete: Satisfying checkmark animation + particle burst
  - Budget exceeded: Warning shake animation
  - Savings goal reached: Confetti celebration
  - FAB: Morphing expand animation
  - Numbers (money): Rolling count-up animation


--------------------------------------------------------------------------------
SECTION 8: PRE-DEVELOPMENT PROCESS WE WILL FOLLOW
--------------------------------------------------------------------------------

PHASE 0 — INITIATION
  [x] Project Requirements Prompt (this file)
  [ ] Project Charter
  [ ] Feasibility Study

PHASE 1 — DISCOVERY
  [ ] Business Requirements Document (BRD)
  [ ] User Personas
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
  [ ] Sprint Plan (7 sprints x 2 weeks)
  [ ] Risk Register
  [ ] Definition of Done (DoD)

PHASE 5 — DESIGN
  [ ] Design System / Style Guide
  [ ] Wireframes (low fidelity)
  [ ] High-Fidelity Mockups (Figma)
  [ ] Interactive Prototype

PHASE 6 — DEV ENVIRONMENT SETUP
  [ ] Flutter + Tools installation guide
  [ ] Project scaffold + folder structure
  [ ] Git repository setup
  [ ] Coding standards document
  [ ] CI/CD setup

PHASE 7 — DEVELOPMENT (Sprints)
  [ ] Sprint 1: Setup + Notes feature
  [ ] Sprint 2: Tasks + Lists feature
  [ ] Sprint 3: Alarm + Reminders
  [ ] Sprint 4: Money Manager (basic)
  [ ] Sprint 5: Money Manager (charts + goals)
  [ ] Sprint 6: UI polish + animations
  [ ] Sprint 7: Testing + QA + bug fixes

PHASE 8 — RELEASE
  [ ] Google Play Store submission
  [ ] Apple App Store submission
  [ ] Release notes


--------------------------------------------------------------------------------
SECTION 9: WHAT SUCCESS LOOKS LIKE
--------------------------------------------------------------------------------

The app is successful when:
  1. A user can create a note in under 5 seconds
  2. A user can log an expense in under 10 seconds
  3. All alarms fire reliably even when phone is on DND
  4. The app feels as polished as Notion or Monzo
  5. A user says "this is the only app I need"
  6. App store rating target: 4.5+ stars
  7. Load time under 2 seconds on a mid-range phone


--------------------------------------------------------------------------------
SECTION 10: OUT OF SCOPE (Version 1.0)
--------------------------------------------------------------------------------

The following are NOT included in version 1.0:
  - Cloud sync / backup (future version)
  - Multi-device sync (future version)
  - Collaboration / sharing with others (future version)
  - AI-powered spending insights (future version)
  - Bank account integration (future version)
  - Web version (future version)
  - Widgets (home screen widgets) — stretch goal
  - PDF export for money reports — stretch goal


================================================================================
END OF DOCUMENT
Next Step: Create Project Charter
================================================================================
