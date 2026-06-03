# Git Workflow & Branching Strategy
**Project:** Endless App | **Version:** 1.0 | **Date:** 2026-06-03 | **Author:** Ashish Sahu

---

## 1. Branch Strategy (GitFlow)

```
main ──────────────────────────────────────────── (stable, tagged releases)
   \                                         ↗
    develop ──────────────────────────────── (active integration)
       \        ↗         \         ↗
        feature/...    feature/...
```

| Branch | Purpose | Merges into |
|---|---|---|
| `main` | Production-ready code only. Tagged with version. | — |
| `develop` | Integration branch. All features merge here first. | `main` at release |
| `feature/*` | One feature per branch. Short-lived. | `develop` |
| `hotfix/*` | Urgent production bug fixes. | `main` AND `develop` |
| `release/*` | Release preparation (version bump, final testing) | `main` AND `develop` |

---

## 2. Branch Naming

```bash
feature/sprint1-notes-crud
feature/sprint1-notes-search
feature/sprint2-tasks-list
feature/sprint2-tasks-swipe-complete
feature/sprint3-alarms-background
feature/sprint4-money-dashboard
feature/sprint5-charts-pie
feature/sprint6-glassmorphism-polish
hotfix/alarm-not-firing-api31
release/v1.0.0
```

---

## 3. Daily Workflow (Solo Developer)

### Starting a new feature

```bash
# Always branch from develop (not main)
git checkout develop
git pull origin develop          # get latest

# Create feature branch
git checkout -b feature/sprint1-notes-crud

# Start coding...
```

### During development

```bash
# Commit frequently (every logical chunk — don't wait for "done")
git add lib/features/notes/domain/entities/note.dart
git add lib/features/notes/domain/repositories/note_repository.dart
git commit -m "feat(notes): add Note entity and repository interface"

# Next chunk
git add lib/features/notes/data/models/note_model.dart
git commit -m "feat(notes): add NoteModel Isar collection schema"
```

### Completing a feature

```bash
# Run tests before merging
flutter test
flutter analyze  # must pass with zero warnings

# Merge into develop
git checkout develop
git merge --no-ff feature/sprint1-notes-crud
# --no-ff preserves the branch history (visible in git log)

# Push develop
git push origin develop

# Delete feature branch (keep repo clean)
git branch -d feature/sprint1-notes-crud
```

---

## 4. Sprint Completion → Develop

At the end of each sprint, verify `develop` is stable:

```bash
git checkout develop

# Run full test suite
flutter test

# Run on emulator
flutter run

# If all good — tag the sprint milestone
git tag sprint-1-complete
git push origin develop --tags
```

---

## 5. Release Process (v1.0.0)

```bash
# 1. Create release branch from develop
git checkout develop
git checkout -b release/v1.0.0

# 2. Version bump in pubspec.yaml: version: 1.0.0+1
# Run final tests + fix any last bugs on this branch

# 3. Merge into main
git checkout main
git merge --no-ff release/v1.0.0
git tag -a v1.0.0 -m "Endless v1.0.0 — Initial release"
git push origin main --tags

# 4. Merge back into develop (catch any release fixes)
git checkout develop
git merge --no-ff release/v1.0.0
git push origin develop

# 5. Delete release branch
git branch -d release/v1.0.0
```

---

## 6. Hotfix Process

```bash
# Branch from main (not develop — we need to fix production now)
git checkout main
git checkout -b hotfix/alarm-not-firing-api31

# Make the fix...
git commit -m "fix(alarms): add SCHEDULE_EXACT_ALARM permission for API 31+"

# Merge into BOTH main AND develop
git checkout main
git merge --no-ff hotfix/alarm-not-firing-api31
git tag -a v1.0.1 -m "Endless v1.0.1 — Hotfix: alarm reliability on API 31+"

git checkout develop
git merge --no-ff hotfix/alarm-not-firing-api31

# Cleanup
git branch -d hotfix/alarm-not-firing-api31
git push origin main develop --tags
```

---

## 7. .gitignore

```gitignore
# Flutter/Dart
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
build/
*.g.dart          # comment this out if you want generated files tracked
*.freezed.dart

# Android
android/.gradle/
android/app/google-services.json
android/local.properties
*.keystore         # NEVER commit signing keystore
*.jks

# iOS
ios/Pods/
ios/.symlinks/

# IDE
.idea/
.vscode/settings.json
*.swp
*.lock

# Secrets
.env
secrets.dart
google-services.json
GoogleService-Info.plist
```

> ⚠️ **IMPORTANT:** Never commit `.keystore` or `GoogleService-Info.plist` — these contain signing credentials. Store them securely (encrypted, local only).

---

## 8. Git Config Setup

```bash
# Set identity (run once)
git config --global user.name "Ashish Sahu"
git config --global user.email "its.sahuashish@gmail.com"

# Default branch name
git config --global init.defaultBranch main

# Better diff output
git config --global core.pager "less -FX"

# Alias for clean log view
git config --global alias.lg "log --oneline --decorate --graph --all"
# Usage: git lg
```

---

## 9. Useful Git Commands Cheatsheet

```bash
# See current status
git status

# See visual branch graph
git lg   # (alias set above)

# Undo last commit (keep changes staged)
git reset --soft HEAD~1

# Discard all uncommitted changes (CAREFUL)
git checkout -- .

# Stash work-in-progress
git stash
git stash pop   # restore

# See what changed in last commit
git show

# Find which commit introduced a bug
git bisect start
git bisect bad          # current commit is broken
git bisect good v0.9.0  # this commit was fine
# Git will binary-search through history
```

---

## 10. GitHub Repository Setup

```bash
# Initial push (once repo exists at github.com)
cd ~/development/endless
git remote add origin https://github.com/AshishSahuDev/Endless_App.git
git push -u origin develop
git push -u origin main
```

**Repo settings to configure on GitHub:**
- Default branch: `develop` (not main — we develop on develop)
- Branch protection on `main`: require PR + at least 1 approval (self-review)
- Add project description and topics: `flutter`, `dart`, `android`, `ios`, `productivity`, `finance`

---

*Document: 04_git_workflow.md | Phase 6 — Dev Environment Setup*
