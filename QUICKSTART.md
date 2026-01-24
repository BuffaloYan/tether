# Tether - Quick Start (5 Minutes)

Get the app running on your device in 5 minutes (assuming Flutter is already installed).

## Prerequisites

- Flutter installed (`flutter doctor` should show no critical errors)
- A physical iOS or Android device (biometrics don't work on simulators)

## Quick Setup

### 1. Install Dependencies

```bash
cd tether_app
flutter pub get
```

### 2. Firebase Setup (For Testing Only)

For initial development, you can skip Firebase setup temporarily. The app will run but won't save data or send alerts.

To properly set up Firebase, see [SETUP_GUIDE.md](SETUP_GUIDE.md).

### 3. Run the App

**On iOS (requires macOS + Xcode):**
```bash
flutter run -d ios
```

**On Android:**
```bash
flutter run -d android
```

## What You'll See

1. **Login Screen**: Tap "Login with Biometrics"
2. **Biometric Prompt**: Use Face ID / Fingerprint (on physical device)
3. **Home Screen**: 3 tabs - Home, Contacts, Settings

## Current Status (Phase 1 Complete ✅)

**Working:**
- ✅ Biometric login
- ✅ Basic navigation (3 screens)
- ✅ Location services (ready to use)
- ✅ Bilingual support (English/Spanish)
- ✅ Cloud Functions (alert logic ready)

**Not Yet Implemented (Phase 2):**
- ❌ Camera + AI gesture detection
- ❌ Emergency contacts CRUD
- ❌ Actual check-in functionality
- ❌ Voice activation (Phase 4)

## Next Steps for Development

See the [Development Roadmap in README.md](README.md#development-roadmap) for what to build next.

The most important next step is **Phase 2: Core Check-in Feature** - implementing the camera and MediaPipe gesture detection.

## Need Full Setup?

For production deployment with Firebase, Twilio, and SendGrid, follow the complete [SETUP_GUIDE.md](SETUP_GUIDE.md).

---

**Just want to see it work?** Run `flutter run` and enjoy exploring the UI! The core logic is there, just waiting for the camera/AI integration.
