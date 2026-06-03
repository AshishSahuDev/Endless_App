# Flutter Setup Guide (Linux — Ubuntu)
**Project:** Endless App | **Version:** 1.0 | **Date:** 2026-06-03 | **Author:** Ashish Sahu

---

## Prerequisites Check

```bash
# Verify your Ubuntu version
lsb_release -a

# Check available disk space (need at least 5GB free)
df -h ~

# Check Java (need JDK 17+ for Android Gradle)
java -version
# If missing: sudo apt install openjdk-17-jdk
```

---

## Step 1 — Install Flutter SDK

```bash
# Create development directory
mkdir -p ~/development && cd ~/development

# Download latest Flutter stable
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.0-stable.tar.xz

# Extract
tar xf flutter_linux_3.24.0-stable.tar.xz

# Add Flutter to PATH (add to ~/.bashrc)
echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> ~/.bashrc
source ~/.bashrc

# Verify installation
flutter --version
# Expected: Flutter 3.x.x • channel stable
```

---

## Step 2 — Install Android Studio + SDK

```bash
# Option A: Install via snap (easiest)
sudo snap install android-studio --classic

# Launch Android Studio and complete setup wizard:
# 1. Choose "Standard" installation
# 2. Accept all Android SDK licenses
# SDK will install to: ~/Android/Sdk

# Add Android tools to PATH
echo 'export ANDROID_HOME=$HOME/Android/Sdk' >> ~/.bashrc
echo 'export PATH=$PATH:$ANDROID_HOME/emulator' >> ~/.bashrc
echo 'export PATH=$PATH:$ANDROID_HOME/tools' >> ~/.bashrc
echo 'export PATH=$PATH:$ANDROID_HOME/tools/bin' >> ~/.bashrc
echo 'export PATH=$PATH:$ANDROID_HOME/platform-tools' >> ~/.bashrc
source ~/.bashrc

# Accept Android licenses (important!)
flutter doctor --android-licenses
# Press 'y' for all prompts
```

---

## Step 3 — Create Android Virtual Device (Emulator)

```bash
# In Android Studio: Tools → Device Manager → Create Device
# Hardware: Pixel 6  (good balance, 6.4", API 34)
# System image: API 34 (Android 14, x86_64)
# Name: Pixel_6_API_34

# Also create a second AVD for minimum target testing:
# Hardware: Pixel 3a  
# System image: API 26 (Android 8.0)
# Name: Pixel_3a_API_26

# Start emulator from command line:
emulator -avd Pixel_6_API_34 &

# Verify device is detected:
flutter devices
# Expected: sdk gphone x86 64 (emulator-5554)
```

---

## Step 4 — Install VS Code + Extensions

```bash
# Install VS Code (if not already installed)
sudo snap install code --classic

# Install Flutter extension from command line:
code --install-extension dart-code.flutter

# This automatically installs the Dart extension too.
# Verify in VS Code: Extensions sidebar → search "Flutter" → should show installed
```

**Recommended VS Code settings** (`settings.json`):
```json
{
  "editor.formatOnSave": true,
  "editor.rulers": [100],
  "dart.lineLength": 100,
  "dart.previewFlutterUiGuides": true,
  "[dart]": {
    "editor.defaultFormatter": "Dart-Code.dart-code",
    "editor.formatOnSave": true,
    "editor.selectionHighlight": false,
    "editor.suggest.snippetsPreventQuickSuggestions": false,
    "editor.suggestSelection": "first",
    "editor.tabCompletion": "onlySnippets",
    "editor.wordBasedSuggestions": "off"
  }
}
```

---

## Step 5 — Run `flutter doctor`

```bash
flutter doctor -v
```

**Expected output (all green):**
```
[✓] Flutter (Channel stable, 3.24.0)
[✓] Android toolchain - develop for Android devices
[✓] Android Studio (version 2024.x)
[✓] VS Code (version 1.x)
[✓] Connected device (1 available)
[✓] Network resources
```

**Common issues and fixes:**

| Issue | Fix |
|---|---|
| `Android license status unknown` | Run `flutter doctor --android-licenses` |
| `Unable to locate Android SDK` | Set `ANDROID_HOME` in `~/.bashrc` |
| `cmdline-tools component is missing` | Android Studio → SDK Manager → SDK Tools → Android SDK Command-line Tools ✓ |
| `java.lang.UnsupportedClassVersionError` | Install JDK 17: `sudo apt install openjdk-17-jdk` |
| `No connected device` | Start emulator first: `emulator -avd Pixel_6_API_34 &` |

---

## Step 6 — Create the Endless Project

```bash
cd ~/development

# Create Flutter project
flutter create endless \
  --org com.ashishsahu \
  --project-name endless \
  --platforms android,ios \
  --description "Endless — Notes, Tasks, Reminders, Alarms & Money Manager"

cd endless

# Run on emulator to verify everything works
flutter run
# Should see the default Flutter counter app
```

---

## Step 7 — Configure Android Permissions

Add to `android/app/src/main/AndroidManifest.xml` inside `<manifest>`:

```xml
<!-- Exact alarm scheduling (Android 12+) -->
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>

<!-- Wake device for alarms -->
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>

<!-- Foreground service for alarm reliability -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK"/>

<!-- Notifications -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

<!-- Biometric -->
<uses-permission android:name="android.permission.USE_BIOMETRIC"/>
<uses-permission android:name="android.permission.USE_FINGERPRINT"/>

<!-- Vibration -->
<uses-permission android:name="android.permission.VIBRATE"/>

<!-- Ignore battery optimization dialog -->
<uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS"/>
```

---

## Step 8 — Enable Physical Device (Optional)

```bash
# On Android phone: Settings → About Phone → tap "Build number" 7 times
# Then: Settings → Developer Options → enable "USB Debugging"

# Connect phone via USB, then:
adb devices
# Should show your device serial number

flutter devices
# Should show your physical device
```

---

## Step 9 — Verify Setup Complete

```bash
flutter doctor
# All green ✓

flutter devices
# At least one emulator/device shown

cd endless && flutter run
# App launches on emulator
```

You're ready to start development. Proceed to `02_project_structure.md`.

---

*Document: 01_flutter_setup_guide.md | Phase 6 — Dev Environment Setup*
