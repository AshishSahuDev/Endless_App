# Release Checklist — Endless v1.0.0
**Version:** 1.0.0+1 | **Target:** Android 8.0+ (API 26+)

---

## Pre-Release Verification

### Code Quality
- [x] `flutter analyze` → 0 issues
- [x] `flutter test` → 56/56 tests pass
- [x] All 7 sprints committed and pushed to GitHub

### Tests Coverage
| File | Tests | Area |
|---|---|---|
| `test/domain/note_entity_test.dart` | 9 | Note.isEmpty, copyWith |
| `test/domain/task_entity_test.dart` | 8 | Task.isOverdue, copyWith, Priority |
| `test/domain/monthly_summary_test.dart` | 8 | balance, expenseByCategory, dailyExpenses |
| `test/domain/savings_goal_test.dart` | 8 | progress, isCompleted, copyWith |
| `test/domain/alarm_entity_test.dart` | 13 | timeString, repeatLabel, copyWith |
| `test/widget/savings_goal_card_test.dart` | 7 | SavingsGoalCard rendering + callbacks |
| `test/widget_test.dart` | 1 | Smoke test |

---

## Android Release Signing

### First-Time Setup (one-off)
```bash
# 1. Generate keystore (run once, store securely)
keytool -genkey -v \
  -keystore android/keystore/endless-release.jks \
  -alias endless \
  -keyalg RSA -keysize 2048 \
  -validity 10000

# 2. Create android/key.properties (NOT committed to git)
# Copy android/key.properties.example → android/key.properties
# Fill in storePassword, keyPassword, keyAlias, storeFile

# 3. Build signed APK
flutter build apk --release

# OR build App Bundle for Play Store
flutter build appbundle --release
```

### Output Locations
```
build/app/outputs/flutter-apk/app-release.apk       ← APK
build/app/outputs/bundle/release/app-release.aab     ← App Bundle
```

---

## Play Store Submission Checklist

### App Details
- [ ] App name: **Endless**
- [ ] Package ID: `com.ashishsahu.endless`
- [ ] Version: `1.0.0` (versionCode: 1)
- [ ] Short description (80 chars max)
- [ ] Full description
- [ ] Screenshots: phone + 7" tablet (min 2 each)
- [ ] Feature graphic (1024×500 px)
- [ ] App icon: 512×512 px (PNG, no alpha — use adaptive icon)

### Content Rating
- [ ] Complete IARC questionnaire in Play Console
- [ ] Expected rating: Everyone

### Privacy & Permissions
- [ ] Privacy policy URL (required for POST_NOTIFICATIONS permission)
- [ ] Permissions justified: notifications, exact alarm, wake lock, boot receiver
- [ ] Data safety form: all data stored locally, no data sent to servers

### Testing Track
- [ ] Upload AAB to Internal Testing track first
- [ ] Test on: Android 8 (API 26), Android 12 (API 31), Android 14 (API 34)
- [ ] Tablet test: 7" and 10" layouts

---

## Post-Submission
- [ ] Monitor crash-free rate in Play Console (target: >99%)
- [ ] Respond to user reviews within 48 hours
- [ ] Sprint 5 chart animations work on real device (not emulator-tested yet)

---

## Known Limitations (v1.0)
- UI not device-tested (AVD emulator requires android-36 system image download)
- No iOS build (requires Mac + Xcode)
- Charts (Sprint 5) rely on fl_chart 0.68.0 — upgrade to 1.x in v1.1
- No cloud sync (by design: offline-first)
