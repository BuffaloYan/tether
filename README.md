# Tether - Safety Check-in App

A cross-platform (iOS & Android) safety app designed for individuals in high-risk environments. Uses biometric authentication and AI-powered gesture recognition to ensure secure check-ins, with automated alerts to emergency contacts if check-ins are missed.

## Features

### Core Features (Free)
- **Biometric Authentication**: Passwordless login using Face ID or fingerprint
- **AI-Powered Check-ins**: Face + thumbs-up gesture verification (prevents coercion)
- **Dead Man's Switch**: Automated alerts if user fails to check in within 24/48 hours
- **Emergency Contacts**: Add up to 3 emergency contacts (SMS + Email)
- **Location Tracking**: GPS coordinates included in all alerts
- **Bilingual Support**: English and Spanish

### Premium Features
- **Voice Activation Mode**: Hands-free emergency alerts via "tether listen" / "tether alert" commands
- **Works when app is backgrounded** (not fully closed for better battery life)

## Tech Stack

- **Frontend**: Flutter (cross-platform)
- **Backend**: Firebase (Authentication, Firestore, Cloud Functions)
- **AI/ML**: MediaPipe (face + gesture detection)
- **Voice**: Speech-to-Text (iOS Speech Framework, Android Google STT)
- **Notifications**: Twilio (SMS), SendGrid (Email)

## Prerequisites

Before you begin, ensure you have the following installed:

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (>=3.0.0)
- [Node.js](https://nodejs.org/) (v18+) - for Firebase Cloud Functions
- [Firebase CLI](https://firebase.google.com/docs/cli) - `npm install -g firebase-tools`
- [Xcode](https://developer.apple.com/xcode/) (for iOS development)
- [Android Studio](https://developer.android.com/studio) (for Android development)

## Getting Started

### 1. Clone and Setup

```bash
cd tether_app
flutter pub get
```

### 2. Firebase Setup

1. Create a Firebase project at [https://console.firebase.google.com/](https://console.firebase.google.com/)

2. Add iOS and Android apps to your Firebase project

3. Download configuration files:
   - **iOS**: Download `GoogleService-Info.plist` and place it in `ios/Runner/`
   - **Android**: Download `google-services.json` and place it in `android/app/`

4. Enable Firebase services:
   - **Authentication**: Enable Anonymous authentication
   - **Firestore**: Create database (start in test mode for development)
   - **Cloud Functions**: Enable billing (required for scheduled functions)

5. Configure Firebase Functions:

```bash
cd functions
npm install
firebase login
firebase use --add  # Select your Firebase project
```

6. Set up environment variables for Cloud Functions:

```bash
# Twilio (SMS)
firebase functions:config:set twilio.account_sid="YOUR_TWILIO_SID"
firebase functions:config:set twilio.auth_token="YOUR_TWILIO_TOKEN"
firebase functions:config:set twilio.phone_number="YOUR_TWILIO_PHONE"

# SendGrid (Email)
firebase functions:config:set sendgrid.api_key="YOUR_SENDGRID_KEY"
```

7. Deploy Cloud Functions:

```bash
firebase deploy --only functions
```

### 3. Third-Party Service Setup

#### Twilio (SMS Alerts)
1. Sign up at [https://www.twilio.com/](https://www.twilio.com/)
2. Get a phone number
3. Copy Account SID, Auth Token, and Phone Number
4. Add to Firebase config (see step 2.6 above)

#### SendGrid (Email Alerts)
1. Sign up at [https://sendgrid.com/](https://sendgrid.com/)
2. Create an API key
3. Verify your sender email (e.g., `alerts@tether.app`)
4. Add to Firebase config (see step 2.6 above)

#### Picovoice (Voice Activation - Optional/Premium)
1. Sign up at [https://picovoice.ai/](https://picovoice.ai/)
2. Get an Access Key
3. Add to `.env` file (see `.env.example`)

### 4. Platform-Specific Configuration

#### iOS

Edit `ios/Runner/Info.plist` and add:

```xml
<!-- Camera permission -->
<key>NSCameraUsageDescription</key>
<string>We need camera access to verify your check-in with face and gesture recognition</string>

<!-- Face ID permission -->
<key>NSFaceIDUsageDescription</key>
<string>We use Face ID to securely authenticate you</string>

<!-- Location permission -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to include it in emergency alerts</string>

<!-- Microphone permission (for voice activation) -->
<key>NSMicrophoneUsageDescription</key>
<string>We need microphone access for voice-activated emergency alerts</string>

<!-- Speech recognition permission -->
<key>NSSpeechRecognitionUsageDescription</key>
<string>We use speech recognition for voice commands like "tether alert"</string>

<!-- Background modes (for voice activation) -->
<key>UIBackgroundModes</key>
<array>
  <string>audio</string>
  <string>processing</string>
</array>
```

#### Android

Edit `android/app/src/main/AndroidManifest.xml` and add:

```xml
<!-- Permissions -->
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.USE_BIOMETRIC" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />

<!-- Inside <application> tag -->
<application>
  <!-- ... existing code ... -->

  <!-- Foreground Service for voice activation -->
  <service
      android:name=".VoiceActivationService"
      android:foregroundServiceType="microphone"
      android:exported="false" />
</application>
```

### 5. Run the App

```bash
# iOS
flutter run -d ios

# Android
flutter run -d android

# Or use your IDE (VS Code, Android Studio)
```

## Project Structure

```
tether_app/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── models/
│   │   ├── user.dart            # User data model
│   │   ├── contact.dart         # Emergency contact model
│   │   └── location.dart        # Location data model
│   ├── screens/
│   │   ├── login_screen.dart    # Biometric login
│   │   ├── home_screen.dart     # Main navigation
│   │   ├── checkin_screen.dart  # Face + gesture check-in
│   │   ├── contacts_screen.dart # Emergency contacts management
│   │   └── settings_screen.dart # App settings
│   ├── services/
│   │   ├── auth_service.dart          # Authentication
│   │   ├── location_service.dart      # GPS & geocoding
│   │   ├── camera_service.dart        # Camera handling (TBD)
│   │   ├── gesture_detection_service.dart # AI gesture detection (TBD)
│   │   ├── voice_service.dart         # Voice activation (TBD)
│   │   └── firestore_service.dart     # Database operations (TBD)
│   ├── widgets/                  # Reusable UI components
│   └── l10n/
│       ├── app_en.arb           # English strings
│       └── app_es.arb           # Spanish strings
├── functions/
│   ├── src/
│   │   ├── index.ts             # Cloud Functions entry point
│   │   ├── alerts.ts            # Alert logic (Twilio/SendGrid)
│   │   └── templates/
│   │       ├── alert_en.ts      # English alert templates
│   │       └── alert_es.ts      # Spanish alert templates
│   ├── package.json
│   └── tsconfig.json
├── android/                     # Android-specific code
├── ios/                        # iOS-specific code
├── pubspec.yaml                # Flutter dependencies
└── README.md                   # This file
```

## Development Roadmap

### Phase 1: Foundation ✅ (Completed)
- [x] Initialize Flutter project
- [x] Configure Firebase
- [x] Implement biometric authentication
- [x] Set up location services
- [x] Build basic UI scaffolding
- [x] Set up English + Spanish localization
- [x] Create Cloud Functions for alerts

### Phase 2: Core Check-in Feature (Next)
- [ ] Implement camera service
- [ ] Integrate MediaPipe for face detection
- [ ] Integrate MediaPipe for thumbs-up gesture recognition
- [ ] Build check-in screen UI
- [ ] Store check-in timestamp + location in Firestore
- [ ] Implement emergency contacts CRUD

### Phase 3: Dead Man's Switch
- [ ] Test scheduled Cloud Function (hourly check-in monitoring)
- [ ] Implement alert escalation logic
- [ ] Add grace period settings
- [ ] Add "pause alerts" feature (for vacations)

### Phase 4: Voice Activation (Premium)
- [ ] Implement wake word detection (Porcupine)
- [ ] Build voice command processing
- [ ] Create background service (foreground notification)
- [ ] Integrate in-app purchases (RevenueCat)
- [ ] Add premium paywall UI

### Phase 5: Polish & Launch
- [ ] End-to-end testing (50+ check-in trials)
- [ ] Battery drain testing (24-hour tests)
- [ ] Security audit
- [ ] Accessibility improvements (VoiceOver, TalkBack)
- [ ] App Store submission (screenshots, descriptions)
- [ ] Privacy policy & terms of service

## Testing

### Manual Testing Checklist

**Check-in Flow:**
- [ ] Face detected with thumbs up → Success
- [ ] Face only (no thumbs up) → Failure
- [ ] Thumbs up only (no face) → Failure
- [ ] Low light conditions → Success with retry
- [ ] User wearing glasses/mask → Success

**Dead Man's Switch:**
- [ ] Set grace period to 1 hour (for testing)
- [ ] Wait 61 minutes without check-in
- [ ] Verify alerts sent to all contacts
- [ ] Check Twilio logs for SMS delivery
- [ ] Check SendGrid for email delivery

**Voice Activation:**
- [ ] Say "tether listen" → App starts listening
- [ ] Say "tether alert" → Immediate alert sent
- [ ] Say "tether check in" → Timestamp updated
- [ ] Background app, say "tether listen" → Wake app
- [ ] Noisy environment → Reliable wake word detection

### Automated Tests

```bash
# Run unit tests
flutter test

# Run integration tests (requires emulator/device)
flutter drive --target=test_driver/app.dart

# Cloud Functions tests
cd functions && npm test
```

## Deployment

### Deploy Cloud Functions

```bash
cd functions
npm run build
firebase deploy --only functions
```

### Build Release Apps

#### iOS (App Store)

```bash
flutter build ios --release
# Open Xcode and submit via Xcode Organizer
```

#### Android (Google Play)

```bash
flutter build appbundle --release
# Upload AAB file to Google Play Console
```

## Privacy & Security

### Data Stored Locally (On-Device)
- Biometric templates (iOS Secure Enclave / Android Keystore)
- Device ID (for anonymous authentication)
- User preferences

### Data Stored in Cloud (Firestore)
- Device ID (anonymized)
- Last check-in timestamp
- Last known GPS location (snapshot only, not continuous tracking)
- Emergency contacts (names, phone numbers, emails)
- Grace period preference
- Preferred language

### Data NOT Stored
- Photos or videos from camera
- Audio recordings from voice commands
- Continuous location history
- Biometric data (stays on device only)

### Security Measures
- All biometric processing on-device
- Camera feed destroyed immediately after check-in
- Voice audio buffer < 3 seconds (discarded immediately)
- Firestore rules: Users can only read/write their own data
- SSL/TLS for all network requests
- Optional: AES-256 encryption for contact info at rest

## Legal Considerations (Minneapolis Context)

### User Warnings in App
- "Do not interfere with law enforcement during use"
- "This app is a safety tool, not legal protection"
- Link to legal aid resources (ACLU, immigrant rights orgs)

### Data Residency
- Firebase US-only data centers
- Clearly stated in privacy policy

### Compliance
- GDPR/CCPA compliant (data deletion requests supported)
- Privacy policy and terms of service required before launch

## Cost Estimates

### Monthly Operating Costs (for 1,000 active users)
- Firebase (Spark/Blaze Plan): $25-50/month
- Twilio SMS: $7.50 per 1,000 alerts ($0.0075/SMS)
- SendGrid: Free tier (100 emails/day) or $15/month
- **Total**: ~$50-100/month

### Revenue (Premium Model)
- Premium subscription: $2.99/month or $29.99/year
- 10% conversion rate: $299/month from 1,000 users
- **Break-even**: ~500 active users

## Contributing

This is a private project developed for safety purposes. If you'd like to contribute:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is proprietary software. All rights reserved.

## Support

For support, please email support@tether.app or open an issue in this repository.

## Acknowledgments

- Built with [Flutter](https://flutter.dev/)
- Powered by [Firebase](https://firebase.google.com/)
- Face/gesture detection by [MediaPipe](https://google.github.io/mediapipe/)
- SMS by [Twilio](https://www.twilio.com/)
- Email by [SendGrid](https://sendgrid.com/)
- Wake word detection by [Picovoice](https://picovoice.ai/)

---

**Disclaimer**: This app is designed as a safety tool and should not be relied upon as the sole means of protection. Always follow local laws and cooperate with lawful authorities.
