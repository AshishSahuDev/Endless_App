# Code Walkthrough — Endless Mobile App

This folder explains the **entire codebase line by line**, organized so you can review what you actually care about without reading dead weight.

## Read this first

**[`00-how-flutter-works.md`](./00-how-flutter-works.md)** — How a Flutter app actually works on a phone, written for a Java/Spring Boot developer. Read this once before any of the screen docs. It explains:
- What runs first when you tap the icon (Dart's `main()` vs Java's `public static void main`)
- Widgets, state, and the build cycle (think: reactive Thymeleaf views)
- Riverpod (the DI container — Flutter's `@Component` + `@Autowired`)
- Clean Architecture layers we use (Domain / Data / Presentation)
- Isar (embedded NoSQL DB — think H2 + JPA but no SQL)
- Dart syntax cheatsheet for Java devs

## Per-area docs

| File | Covers |
|------|--------|
| `01-app-bootstrap.md` | `main.dart`, `app.dart`, `splash_screen.dart`, `onboarding_screen.dart`, `home_shell.dart` — the entry point through to the bottom nav |
| `02-core-infrastructure.md` | Constants, theme, Isar setup, services (alarm, notification, logger), shared error types |
| `03-screen-notes.md` | Notes feature — entity → model → datasource → repository → use cases → provider → list screen → editor screen → widgets |
| `04-screen-tasks.md` | Tasks feature (same layered walkthrough) |
| `05-screen-reminders.md` | Reminders feature |
| `06-screen-alarms.md` | Alarms feature |
| `07-screen-money.md` | Money feature (transactions + savings goals + charts) |
| `08-screen-logs.md` | Diagnostic logs screen |

## How each per-area doc is laid out

Same skeleton every time, top → bottom of the layer cake:

1. **What this screen does** — 3-line plain-English summary
2. **All files involved** — full list with absolute paths
3. **Layer 1: Domain** — pure business logic (entity, repository interface, use cases)
4. **Layer 2: Data** — how it's stored (model, datasource, repository impl)
5. **Layer 3: Presentation** — UI (provider, screen, widgets)
6. **Trace a real user action** — e.g. "user taps `+` on tasks screen" — follow the call chain through every layer

This way you can review by layer (read all the domain code first, then all the data code) or by feature (read everything that runs when a button is tapped).
