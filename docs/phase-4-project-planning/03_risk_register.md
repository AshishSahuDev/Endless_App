# Risk Register
**Project:** Endless App | **Version:** 1.0 | **Date:** 2026-06-03 | **Author:** Ashish Sahu

**Risk Score = Probability × Impact** (H=3, M=2, L=1) | Score ≥5 = HIGH PRIORITY

---

## Risk Register Table

| ID | Category | Risk | Prob | Impact | Score | Status |
|---|---|---|---|---|---|---|
| R-01 | Technical | Alarm fails in background on Android | H | H | 9 | 🔴 Monitor |
| R-02 | Technical | Alarm fails on iOS (background restriction) | M | H | 6 | 🔴 Monitor |
| R-03 | External | Apple App Store rejection | L | H | 3 | 🟡 Watch |
| R-04 | Technical | Flutter learning curve delays Sprint 1 | H | M | 6 | 🔴 Monitor |
| R-05 | Project | Scope creep (adding features mid-dev) | H | M | 6 | 🔴 Monitor |
| R-06 | Resource | Solo developer burnout | M | H | 6 | 🔴 Monitor |
| R-07 | Technical | No Mac for iOS build/test | H | M | 6 | 🔴 Monitor |
| R-08 | External | Play Store policy violation | L | H | 3 | 🟡 Watch |
| R-09 | Technical | Isar schema migration breaks existing data | L | H | 3 | 🟡 Watch |
| R-10 | Technical | Package deprecation (alarm, Isar) | L | M | 2 | 🟢 Accept |
| R-11 | Technical | Android battery optimization kills alarms | H | H | 9 | 🔴 Monitor |
| R-12 | Technical | APK size exceeds 50MB limit | M | M | 4 | 🟡 Watch |
| R-13 | Design | UI doesn't meet Gen-Z aesthetic bar | M | H | 6 | 🔴 Monitor |
| R-14 | Technical | fl_chart performance issues with large data | L | M | 2 | 🟢 Accept |
| R-15 | Technical | Drag-and-drop package incompatibility | M | M | 4 | 🟡 Watch |
| R-16 | Project | Timeline slip due to real-life interruptions | H | M | 6 | 🔴 Monitor |
| R-17 | Technical | Biometric auth not available on test device | M | L | 2 | 🟢 Accept |
| R-18 | Technical | Dart null safety errors in third-party packages | L | L | 1 | 🟢 Accept |

---

## Detailed Risk Analysis

### R-01 — Alarm Fails in Background on Android (Score: 9 — CRITICAL)

**Description:** Android's battery optimization (Doze mode, App Standby) kills background processes, preventing alarms from firing when the app is closed.

**Root Cause:** Android restricts exact alarms in API 31+ requiring `SCHEDULE_EXACT_ALARM` permission. OEM battery savers (MIUI, EMUI, ColorOS) are even more aggressive.

**Mitigation:**
- Request `SCHEDULE_EXACT_ALARM` permission at alarm creation time
- Show a one-time dialog guiding users to disable battery optimization for Endless
- Use `android:usesCleartextTraffic` + `alarm` package's foreground service mode
- Test on API 26, 30, 34 emulators AND a physical Redmi device (common OEM)

**Contingency:** If reliable firing cannot be achieved, add a visible warning in the alarm UI: "For best results, disable battery optimization for Endless in Settings."

---

### R-02 — Alarm Fails on iOS (Score: 6 — HIGH)

**Description:** iOS restricts background audio and process execution. Exact alarm behavior is not natively supported.

**Mitigation:**
- The `alarm` package uses `AVAudioSession` to play silent audio, keeping the app active
- Request `NSBackgroundModes: audio` in Info.plist
- Test on real iOS device via MacInCloud before App Store submission

**Contingency:** If iOS alarm is unreliable, v1.0 ships Android-only. iOS becomes v1.1 target.

---

### R-04 — Flutter Learning Curve (Score: 6 — HIGH)

**Description:** Ashish has Java/Spring Boot expertise but Flutter/Dart is new. Widget tree paradigm, Riverpod, and Isar all have non-trivial learning curves.

**Mitigation:**
- Complete flutter.dev codelabs (Intro to Flutter) before Sprint 1
- Study Riverpod docs and examples during Phases 5–6 (pre-dev phases)
- Build a "throwaway" mini-app during Phase 6 setup to practice
- Dart syntax is ~90% similar to Java — primary new concept is declarative UI

**Contingency:** Sprint 1 extended by 3–5 days if needed. Scope of Sprint 1 reduced to Notes-only (drop rich text editor to Sprint 6).

---

### R-05 — Scope Creep (Score: 6 — HIGH)

**Description:** New feature ideas will arise during development ("let me just add X quickly"). Each addition delays Sprint completion.

**Mitigation:**
- Strict v1.0 scope freeze from Phase 3 onwards
- Maintain a v2 backlog document for all new ideas
- Sprint planning reviews scope at the start of each sprint

**Contingency:** Any new idea goes into v2 backlog. No exceptions during Sprints 1–7.

---

### R-06 — Solo Developer Burnout (Score: 6 — HIGH)

**Description:** Solo development with no code review, no team support. Fatigue and loss of motivation can halt progress indefinitely.

**Mitigation:**
- Time-box working sessions: max 3 hours/day on weekdays, 4 hours on weekends
- Celebrate sprint completions (deploy to physical device, show to friends)
- Sprint 6 (polish) is intentionally fun — visual work to re-energize
- Keep a "progress journal" — seeing sprint checkboxes tick boosts motivation

**Contingency:** If stuck for >1 week, simplify the blocked feature or skip to next sprint and return later.

---

### R-11 — Android Battery Optimization (Score: 9 — CRITICAL)

**Description:** Samsung, Xiaomi, and other OEMs run aggressive battery killers that terminate all background processes. This affects BOTH alarms AND reminder notifications.

**Mitigation:**
- On first alarm creation, show a guided dialog: "To ensure your alarms work reliably, please allow Endless to run in the background."
- Deep-link to the exact battery settings page using `Intent.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`
- Add a troubleshooting tip in Settings → Alarms

**Contingency:** Provide an in-app guide with manufacturer-specific steps (Samsung: "Protected apps"; MIUI: "Autostart").

---

### R-13 — UI Doesn't Meet Gen-Z Aesthetic (Score: 6 — HIGH)

**Description:** The target demographic is highly design-sensitive. A generic or poorly executed UI leads to immediate uninstall and bad reviews.

**Mitigation:**
- Follow the Design System document precisely (colors, typography, spacing, animations)
- Review all screens against reference apps (Monzo, Notion, Linear) before each sprint demo
- Sprint 6 is dedicated to UI polish — do NOT skip it
- Show to a real Gen-Z user (friend/colleague) at Sprint 3 checkpoint for feedback

**Contingency:** Hire a freelance UI reviewer for ₹500–1000 for a 1-hour review session before release.

---

*Document: 03_risk_register.md | Phase 4 — Project Planning*
