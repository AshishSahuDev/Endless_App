# Definition of Done (DoD)
**Project:** Endless App | **Version:** 1.0 | **Date:** 2026-06-03 | **Author:** Ashish Sahu

---

## Overview

The Definition of Done ensures consistent quality across all work. Every piece of work must pass its DoD before being marked complete. There are three levels:

1. **Story-level DoD** — applies to every user story
2. **Sprint-level DoD** — applies to completing a sprint
3. **Release-level DoD** — applies to v1.0 release readiness

---

## Level 1 — Story-Level DoD

Every user story is DONE only when ALL of the following are true:

### Functionality
- [ ] Feature works exactly as described in the user story acceptance criteria
- [ ] Feature works in dark mode AND light mode
- [ ] Feature works on Android emulator API 26 (minimum target) and API 34 (latest)
- [ ] No hardcoded strings — all user-visible text uses constants or localization keys
- [ ] No hardcoded colors — all colors reference the AppTheme constants

### Code Quality
- [ ] Code follows the naming conventions in `03_coding_standards.md`
- [ ] No unused imports, variables, or dead code
- [ ] `flutter analyze` runs with zero warnings or errors
- [ ] No `print()` statements left in production code (use debugPrint() wrapped in kDebugMode)
- [ ] All public methods and classes have a brief doc comment if behavior is non-obvious

### Architecture
- [ ] Feature is implemented in the correct Clean Architecture layer (no business logic in widgets)
- [ ] Data access goes through Repository interface (no direct Isar calls from UI)
- [ ] Riverpod providers are used for state (no setState in feature screens)
- [ ] New Isar models have corresponding domain entities with `toEntity()`/`fromModel()` mappers

### UI & UX
- [ ] Screen handles empty state (shows empty state illustration/message, not a blank screen)
- [ ] Screen handles loading state (shows shimmer or progress indicator, not blank)
- [ ] Screen handles error state (shows error message with retry option)
- [ ] All interactive elements have minimum 44×44dp touch target
- [ ] Keyboard dismisses properly on all input screens (tap outside = dismiss)
- [ ] Back navigation works correctly (hardware back button on Android)

### Testing
- [ ] At least one widget test written for the main screen of the feature
- [ ] Critical business logic (use cases) has unit tests
- [ ] Manually tested: happy path, empty state, error state

---

## Level 2 — Sprint-Level DoD

A sprint is DONE only when ALL of the following are true:

### Completion
- [ ] All user stories in the sprint have passed Story-Level DoD
- [ ] No story is left "in progress" or "almost done" — it's either done or moved to next sprint
- [ ] Sprint demo recorded (screen recording of all features working on emulator)

### Quality
- [ ] `flutter test` passes with zero failures
- [ ] `flutter analyze` passes with zero warnings across the entire project
- [ ] No known critical bugs (severity: crash or data loss) left unresolved
- [ ] All screens reviewed side-by-side in dark mode and light mode

### Performance
- [ ] New screens open within 300ms (no jank on initial render)
- [ ] List screens scroll at 60fps (check with Flutter DevTools overlay)
- [ ] No new memory leaks introduced (verified in DevTools Memory tab)

### Git
- [ ] All sprint work committed on a feature branch (`feature/sprint-X-featurename`)
- [ ] Feature branch merged to `develop` via PR
- [ ] `develop` branch builds and runs cleanly after merge
- [ ] Commit messages follow Conventional Commits format

### Documentation
- [ ] CHANGELOG.md entry added for sprint features
- [ ] Any new third-party package added is documented in `02_project_structure.md` with reason

---

## Level 3 — Release-Level DoD (v1.0)

The app is ready for Google Play Store submission only when ALL of the following are true:

### All Features Complete
- [ ] All 5 modules functional: Notes, Tasks, Reminders, Alarms, Money Manager
- [ ] Onboarding flow works end-to-end
- [ ] Dark and light mode work across ALL screens
- [ ] App lock (PIN + biometric) functional
- [ ] All Sprint 1–7 DoD checklists passed

### Performance Benchmarks
- [ ] Cold start < 2 seconds on Redmi Note 10-equivalent emulator (API 30)
- [ ] 60fps confirmed in Flutter DevTools across all main screens
- [ ] No dropped frames in any standard user flow
- [ ] Memory usage stays below 150MB during normal use

### Reliability
- [ ] Alarm fires reliably in 10/10 background tests on Android API 26 and API 34
- [ ] Zero data loss in 50 create/edit/delete operations per module
- [ ] App handles crash gracefully (no uncaught exceptions in release build)
- [ ] App auto-saves note/task on interruption (phone call, home button press)

### Compatibility
- [ ] Tested on Android API 26 emulator (minimum target)
- [ ] Tested on Android API 34 emulator (latest)
- [ ] Tested at screen sizes: 5.5" (normal), 6.7" (large)
- [ ] Tested in portrait AND landscape orientation (or landscape locked with clear notice)

### Release Build
- [ ] Release APK/App Bundle builds without errors (`flutter build appbundle --release`)
- [ ] App Bundle size < 50MB
- [ ] ProGuard/R8 minification enabled and tested (no class-not-found crashes)
- [ ] Release signing configured with a keystore (NOT debug keystore)
- [ ] `minSdkVersion = 26`, `targetSdkVersion = 34` confirmed in build.gradle

### Play Store Assets
- [ ] App icon (512×512 PNG, no transparency)
- [ ] Feature graphic (1024×500 PNG)
- [ ] At least 8 screenshots (phone: portrait, all major screens)
- [ ] Short description written (80 chars max)
- [ ] Full description written (4000 chars max)
- [ ] Privacy policy URL provided (required for apps that use permissions)
- [ ] Content rating questionnaire completed in Play Console

### Legal & Privacy
- [ ] Privacy policy published (can be a simple page on Netlify)
- [ ] No analytics or tracking SDKs in v1.0 (zero data leaves device)
- [ ] All open-source package licenses acknowledged

### Final Checks
- [ ] App reviewed by at least 1 real Gen-Z user for UX feedback
- [ ] All feedback actioned or consciously deferred to v2
- [ ] GitHub repo README updated with live Play Store link
- [ ] Activity Log updated with release entry

---

*Document: 04_definition_of_done.md | Phase 4 — Project Planning*
