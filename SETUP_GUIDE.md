# Tether - Complete Setup Guide

This guide will walk you through setting up the Tether app from scratch.

## Prerequisites Installation

### 1. Install Flutter

**macOS:**
```bash
cd ~/development
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

# Add to ~/.zshrc or ~/.bash_profile
echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> ~/.zshrc

# Verify installation
flutter doctor
```

**Windows/Linux:** Follow [official Flutter installation guide](https://flutter.dev/docs/get-started/install)

### 2. Install Firebase CLI

```bash
npm install -g firebase-tools
firebase login
```

### 3. Install Xcode (macOS only, for iOS development)

1. Download from Mac App Store
2. Install Command Line Tools:
```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```

### 4. Install Android Studio

1. Download from [https://developer.android.com/studio](https://developer.android.com/studio)
2. Install Android SDK through Android Studio
3. Accept Android licenses:
```bash
flutter doctor --android-licenses
```

## Project Setup

### Step 1: Initialize Flutter Project

First, ensure Flutter is in your PATH. If you followed the prerequisites, add it to your current shell session:

```bash
export PATH="$PATH:$HOME/development/flutter/bin"
```

Then initialize the project:

```bash
cd tether_app
# Install Flutter dependencies
flutter pub get

# Initialize iOS and Android platforms (creates Runner.xcworkspace and other platform files)
flutter create --platforms=ios,android .
```

**Note:** The `flutter create` command will generate the necessary iOS and Android configuration files, including `Runner.xcworkspace` for iOS.

### Step 2: Firebase Project Setup

#### 2.1 Create Firebase Project

1. Go to [https://console.firebase.google.com/](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name: `tether-app-prod` (or your choice)
4. Disable Google Analytics (optional)
5. Click "Create project"

#### 2.2 Add iOS App

1. In Firebase Console, click "Add app" → iOS
2. iOS bundle ID: `com.wy.tether.app` (or your choice)
3. App nickname: `Tether iOS`
4. Download `GoogleService-Info.plist`
5. Move it to `ios/Runner/` directory:
```bash
mv ~/Downloads/GoogleService-Info.plist ios/Runner/
```

#### 2.3 Add Android App

1. In Firebase Console, click "Add app" → Android
2. Android package name: `com.wy.tether.app`
3. App nickname: `Tether Android`
4. Download `google-services.json`
5. Move it to `android/app/` directory:
```bash
mv ~/Downloads/google-services.json android/app/
```

#### 2.4 Enable Firebase Services

In Firebase Console:

1. **Authentication**:
   - Go to Authentication → Sign-in method
   - Enable "Anonymous" authentication
   - Click "Save"

2. **Firestore Database**:
   - Go to Firestore Database
   - Click "Create database"
   - Start in **test mode** (we'll add security rules later)
   - Choose location: `us-central1` (or nearest to Minneapolis)

3. **Cloud Functions**:
   - Go to Functions
   - Click "Get started"
   - Upgrade to Blaze (pay-as-you-go) plan (required for scheduled functions)

#### 2.5 Deploy Security Rules

```bash
firebase deploy --only firestore:rules
firebase deploy --only storage:rules
```

### Step 3: Third-Party Services Setup

#### 3.1 Twilio (SMS Alerts)

1. Sign up at [https://www.twilio.com/try-twilio](https://www.twilio.com/try-twilio)
2. Verify your email and phone
3. Get a Twilio phone number:
   - Dashboard → Phone Numbers → Buy a Number
   - Choose a US number (Minneapolis area code: 612, 651, 763)
4. Note your credentials:
   - Account SID
   - Auth Token
   - Phone Number

#### 3.2 SendGrid (Email Alerts)

1. Sign up at [https://signup.sendgrid.com/](https://signup.sendgrid.com/)
2. Complete account setup
3. Create API Key:
   - Settings → API Keys → Create API Key
   - Name: `Tether Alerts`
   - Permissions: Full Access
   - Copy and save the API key (shown only once!)
4. Verify sender email:
   - Settings → Sender Authentication
   - Single Sender Verification
   - Add `alerts@yourdomain.com` (or use personal email for testing)
   - Verify via email link

#### 3.3 Configure Firebase Functions

```bash
# Navigate to functions directory
cd functions

# Install dependencies
npm install

# Create .env file with your credentials

# IMPORTANT: The .env file is for local development and testing
# For production deployment, set these as environment variables in Firebase Console:
# Functions → Select your function → Environment variables tab
```

### Step 4: Deploy Cloud Functions

```bash
# Build TypeScript
cd functions
npm run build

# Deploy functions
firebase deploy --only functions

# Check deployment
firebase functions:log
```

### Step 5: Build iOS Project (First Time)

Before configuring iOS in Xcode, you need to run the Flutter build to install CocoaPods dependencies and set up the project properly:

```bash
# From the tether_app directory
flutter build ios --no-codesign
```

This will:
- Install CocoaPods (if not already installed)
- Run `pod install` automatically
- Generate all necessary iOS build files
- Set up the workspace properly

**Note:** You may see warnings about codesigning - this is normal for the first build. You'll configure signing in Xcode in the next step.

### Step 6: iOS Configuration in Xcode

**IMPORTANT:** Only do this step AFTER running the Flutter build above.

#### 6.1 Update Bundle Identifier

1. Open `ios/Runner.xcworkspace` in Xcode (the workspace file now exists!)
2. Select Runner → General
3. Change Bundle Identifier to match Firebase: `com.wy.tether.app`

#### 6.2 Add Capabilities

1. In Xcode, select Runner → Signing & Capabilities
2. Click "+ Capability"
3. Add:
   - Background Modes (select: Audio, Background fetch)
   - Push Notifications

#### 6.3 Configure Info.plist

Already configured in the project. Verify by opening `ios/Runner/Info.plist` and checking for:
- NSCameraUsageDescription
- NSFaceIDUsageDescription
- NSLocationWhenInUseUsageDescription
- NSMicrophoneUsageDescription
- NSSpeechRecognitionUsageDescription

### Step 7: Android Configuration

#### 7.1 Update Package Name

Edit `android/app/build.gradle`:

```gradle
android {
    defaultConfig {
        applicationId "com.wy.tether.app"  // Match Firebase
        // ...
    }
}
```

#### 7.2 Verify Permissions

Check `android/app/src/main/AndroidManifest.xml` for required permissions (already added).

### Step 8: Test the App

#### 8.1 Run on iOS Simulator

```bash
flutter run -d "iPhone 15 Pro"
```

**Note:** Biometric authentication won't work on simulator. You'll need a physical device for full testing.

#### 8.2 Run on Android Emulator

```bash
# List devices
flutter devices

# Run on emulator
flutter run -d emulator-5554
```

#### 8.3 Run on Physical Device

**iOS:**
```bash
# Connect iPhone via USB
flutter run -d "Your iPhone Name"
```

**Android:**
```bash
# Enable USB debugging on phone
# Connect via USB
flutter run -d <device-id>
```

### Step 9: Verify Everything Works

1. **Login Screen**:
   - [ ] App opens to login screen
   - [ ] Biometric prompt appears (on physical device)
   - [ ] After authentication, navigates to home

2. **Firestore**:
   - [ ] Check Firebase Console → Firestore
   - [ ] New user document created in `users` collection
   - [ ] Device ID matches your device

3. **Cloud Functions**:
   - [ ] Check Firebase Console → Functions
   - [ ] `checkMissedCheckIns` function deployed
   - [ ] No errors in logs

## Development Workflow

### Hot Reload

While running the app:
- Press `r` to hot reload
- Press `R` to hot restart
- Press `q` to quit

### Run Tests

```bash
# Unit tests
flutter test

# Integration tests
flutter drive --target=test_driver/app.dart
```

### Check for Issues

```bash
flutter doctor -v
flutter analyze
```

### Update Dependencies

```bash
flutter pub upgrade
```

## Troubleshooting

### "Flutter command not found"

Add Flutter to PATH:
```bash
export PATH="$PATH:$HOME/development/flutter/bin"
```

### "CocoaPods not installed" (iOS)

**Note:** You usually don't need to manually install CocoaPods or run `pod install`. Flutter handles this automatically when you run `flutter build ios`.

However, if you need to manually install CocoaPods:

```bash
sudo gem install cocoapods
```

Then let Flutter handle the pod installation by running:

```bash
flutter build ios --no-codesign
```

**Do NOT run `pod install` manually** - let Flutter manage it.

### "Execution failed for task ':app:processDebugGoogleServices'" (Android)

Make sure `google-services.json` is in `android/app/` directory.

### Firebase Functions not deploying

```bash
# Check if you're in the right project
firebase use --add

# Re-login
firebase logout
firebase login
```

### "Missing GoogleService-Info.plist" (iOS)

Download again from Firebase Console → Project Settings → Your apps → iOS app

## Next Steps

Once basic setup is complete, you're ready to start Phase 2 development:

1. **Implement Camera Service** (for face + gesture detection)
2. **Integrate MediaPipe** (AI models)
3. **Build Check-in Screen UI**
4. **Test Emergency Alerts** (with test contacts)

See [README.md](README.md) for the full development roadmap.

## Getting Help

- Flutter docs: [https://flutter.dev/docs](https://flutter.dev/docs)
- Firebase docs: [https://firebase.google.com/docs](https://firebase.google.com/docs)
- Stack Overflow: Tag questions with `flutter`, `firebase`
- Discord: Flutter Community Discord

---

**Need help?** Open an issue or email support@tether.app
