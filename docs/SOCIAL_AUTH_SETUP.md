# Social Authentication Setup Guide

This guide explains how to configure Google, Facebook, and Apple Sign-In for the Tether app.

## Overview

The app now supports multiple authentication methods:
- **Biometric Authentication** (Face ID/Touch ID/Fingerprint) - Default, anonymous sign-in
- **Google Sign-In** - OAuth 2.0
- **Facebook Login** - OAuth 2.0
- **Apple Sign-In** - OAuth 2.0 (iOS only)

### Internal User ID Strategy

- **deviceId**: A stable UUID generated on first app launch, stored locally. This is the PRIMARY identifier used for all user data in Firestore.
- **uid**: Firebase Authentication UID, which may change when users link different social providers
- **authProviders**: Array tracking which authentication methods the user has linked (e.g., `['biometric', 'google', 'facebook']`)

This design allows users to:
1. Start with biometric auth (anonymous Firebase user)
2. Later link their Google/Facebook/Apple account to the SAME device ID
3. Sign in from any linked provider and access the same user data

---

## 1. Google Sign-In Configuration

### Firebase Console Setup

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `tether-app-prod-ee05c`
3. Navigate to **Authentication** → **Sign-in method**
4. Click on **Google** provider
5. Toggle **Enable**
6. Set the support email (your email)
7. Click **Save**

### iOS Configuration

1. Download the updated `GoogleService-Info.plist` from Firebase Console
2. Add these keys to `ios/Runner/Info.plist`:

```xml
<!-- Google Sign-In URL Scheme -->
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <!-- Replace with your REVERSED_CLIENT_ID from GoogleService-Info.plist -->
      <string>com.googleusercontent.apps.2475995227-ns4d1lbualimq373tr7b0injqiun3ht7</string>
    </array>
  </dict>
</array>
```

3. Find `REVERSED_CLIENT_ID` in your `GoogleService-Info.plist`
4. Replace `YOUR-REVERSED-CLIENT-ID` with the actual value

### Android Configuration

1. Add SHA-1 and SHA-256 fingerprints to Firebase Console:

```bash
# Debug keystore (for development)
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# Release keystore (for production)
keytool -list -v -keystore /path/to/your/release.keystore -alias your-alias
```

2. Add these fingerprints in Firebase Console:
   - Project Settings → General → Your apps → Android → Add fingerprint

3. Download the updated `google-services.json`
4. Replace `android/app/google-services.json`

---

## 2. Facebook Login Configuration

### Create Facebook App

1. Go to [Facebook Developers](https://developers.facebook.com/)
2. Create a new app or use existing one
3. Add **Facebook Login** product
4. Configure OAuth redirect URLs

### Firebase Console Setup

1. In Firebase Console, go to **Authentication** → **Sign-in method**
2. Click on **Facebook** provider
3. Toggle **Enable**
4. You'll need:
   - **App ID**: From Facebook App Dashboard
   - **App Secret**: From Facebook App Dashboard → Settings → Basic

5. Copy the **OAuth redirect URI** from Firebase
6. Add this URI to Facebook App:
   - Facebook App Dashboard → Products → Facebook Login → Settings → Valid OAuth Redirect URIs

### iOS Configuration

Add to `ios/Runner/Info.plist`:

```xml
<!-- Facebook Configuration -->
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>fbYOUR-APP-ID</string>
    </array>
  </dict>
</array>
<key>FacebookAppID</key>
<string>YOUR-APP-ID</string>
<key>FacebookDisplayName</key>
<string>Tether</string>
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>fbapi</string>
  <string>fb-messenger-share-api</string>
</array>
```

### Android Configuration

Add to `android/app/src/main/res/values/strings.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="facebook_app_id">YOUR-APP-ID</string>
    <string name="fb_login_protocol_scheme">fbYOUR-APP-ID</string>
    <string name="facebook_client_token">YOUR-CLIENT-TOKEN</string>
</resources>
```

Add to `android/app/src/main/AndroidManifest.xml` inside `<application>`:

```xml
<meta-data
    android:name="com.facebook.sdk.ApplicationId"
    android:value="@string/facebook_app_id"/>

<meta-data
    android:name="com.facebook.sdk.ClientToken"
    android:value="@string/facebook_client_token"/>
```

---

## 3. Apple Sign-In Configuration (iOS only)

### Apple Developer Portal

1. Go to [Apple Developer](https://developer.apple.com/account/)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Select your App ID (or create one)
4. Enable **Sign In with Apple** capability
5. Configure the Service ID for web authentication (if needed)

### Firebase Console Setup

1. In Firebase Console, go to **Authentication** → **Sign-in method**
2. Click on **Apple** provider
3. Toggle **Enable**
4. You'll need:
   - **Service ID** (optional, for web)
   - **Team ID**: From Apple Developer Account
   - **Key ID**: From Apple Developer Keys
   - **Private Key**: Download from Apple Developer

### iOS Configuration

1. In Xcode, open `ios/Runner.xcworkspace`
2. Select the **Runner** target
3. Go to **Signing & Capabilities**
4. Click **+ Capability**
5. Add **Sign In with Apple**

Add to `ios/Runner/Info.plist`:

```xml
<!-- No additional configuration needed for Apple Sign In -->
<!-- The capability in Xcode handles everything -->
```

---

## 4. Testing Social Authentication

### Development Testing

1. **Google Sign-In**:
   - Use your own Google account
   - Make sure SHA-1 fingerprint is added for Android
   - Make sure REVERSED_CLIENT_ID is configured for iOS

2. **Facebook Login**:
   - Add test users in Facebook App Dashboard → Roles → Test Users
   - Or add your Facebook account as a developer/tester

3. **Apple Sign-In**:
   - Requires physical iOS device (won't work in simulator)
   - Test with your Apple ID

### Verification Checklist

- [ ] User can sign in with biometrics
- [ ] User can sign in with Google
- [ ] User can sign in with Facebook
- [ ] User can sign in with Apple (iOS only)
- [ ] After social login, user sees same data as biometric login
- [ ] User can link multiple providers to same account
- [ ] User data persists across different sign-in methods
- [ ] Device ID remains constant regardless of auth provider

---

## 5. Security Considerations

### Device ID Security
- Device ID is stored in SharedPreferences (Android) or UserDefaults (iOS)
- If user uninstalls app, device ID is lost and a new one is generated
- Consider adding account recovery mechanism in future

### Provider Linking
- Users can link multiple auth providers to same device ID
- Users cannot unlink their last remaining auth provider
- Firebase Auth handles token refresh automatically

### Privacy
- Minimal data is collected from social providers:
  - Email (if available)
  - Display name (if available)
  - Profile photo URL (if available)
- All data is stored in Firestore under the device ID

---

## 6. Troubleshooting

### Google Sign-In Issues

**Error: "Developer Error" on Android**
- Solution: Add SHA-1 and SHA-256 fingerprints to Firebase Console
- Make sure `google-services.json` is up to date

**Error: "DEVELOPER_ERROR" or "SIGN_IN_FAILED"**
- Solution: Check that REVERSED_CLIENT_ID matches GoogleService-Info.plist

### Facebook Login Issues

**Error: "Invalid OAuth redirect URI"**
- Solution: Add the Firebase OAuth redirect URI to Facebook App settings

**Error: "App not setup"**
- Solution: Make sure Facebook App is in development or live mode
- Add test users if in development mode

### Apple Sign-In Issues

**Error: "Invalid client"**
- Solution: Ensure Sign In with Apple capability is enabled in Xcode
- Check that Bundle ID matches in Apple Developer Portal

**Won't work in Simulator**
- Expected: Apple Sign-In requires a physical device
- Use Google or Facebook for simulator testing

---

## 7. Production Deployment

Before releasing to production:

1. **Google**:
   - Add production SHA-1/SHA-256 fingerprints
   - Update `google-services.json` and `GoogleService-Info.plist`

2. **Facebook**:
   - Switch Facebook App to **Live** mode
   - Add production package name/bundle ID
   - Remove test redirect URIs

3. **Apple**:
   - Ensure production Bundle ID is configured
   - Test on physical devices before release

4. **Firebase**:
   - Review Firebase Authentication usage limits
   - Set up monitoring for auth errors
   - Configure email templates for password reset (if adding email/password later)

---

## Implementation Summary

### Files Modified

- `lib/models/user.dart` - Added authProviders, email, displayName, photoUrl fields
- `lib/services/auth_service.dart` - Added social sign-in methods
- `lib/screens/login_screen.dart` - Added social login buttons
- `pubspec.yaml` - Added social auth packages

### Database Schema

Firestore collection: `users/{deviceId}`

```json
{
  "deviceId": "uuid-v4-string",
  "uid": "firebase-auth-uid",
  "authProviders": ["biometric", "google", "facebook"],
  "email": "user@example.com",
  "displayName": "John Doe",
  "photoUrl": "https://...",
  "createdAt": "timestamp",
  "lastLoginAt": "timestamp",
  "gracePeriodHours": 24,
  "preferredLanguage": "en",
  "isPremium": false,
  "alerted": false,
  "contacts": []
}
```

### Next Steps

1. Configure each provider in Firebase Console
2. Test authentication flows
3. Add provider management screen (allow users to link/unlink providers)
4. Consider adding email/password authentication as backup
5. Implement account recovery flow
