# Firebase Console Setup Instructions

This document provides step-by-step instructions for configuring authentication providers in Firebase Console for the Tether app.

## Project Information

- **Firebase Project ID**: `tether-app-prod-ee05c`
- **iOS Bundle ID**: `com.wy.tether.app`
- **Android Package Name**: `com.wy.tether.app`
- **Firebase Console**: https://console.firebase.google.com/project/tether-app-prod-ee05c

## 1. Enable Google Sign-In

### Steps:

1. Go to [Firebase Console](https://console.firebase.google.com/project/tether-app-prod-ee05c)
2. Navigate to **Authentication** → **Sign-in method**
3. Click on **Google** provider
4. Toggle **Enable**
5. Set the **support email** (use your email address)
6. Click **Save**

### Android SHA Fingerprints (Already Configured):

The following SHA fingerprints need to be added to Firebase Console for Android Google Sign-In to work:

**Debug Keystore** (for development):
```
SHA1: 74:00:E0:CB:4C:65:6C:B4:83:B7:AB:65:A9:9D:B4:95:86:7E:06:10
SHA256: C9:B7:E5:4F:86:FD:41:AE:DB:54:9C:EB:34:62:71:E6:51:3E:23:25:A4:1C:9E:38:1D:F9:C6:06:23:66:FD:53
```

**To add fingerprints:**
1. Go to Project Settings → General
2. Scroll to "Your apps" → Android app
3. Click "Add fingerprint"
4. Paste the SHA-1 and SHA-256 values above

**For production**, you'll need to generate a release keystore and add those fingerprints as well.

### iOS Configuration (Already Done):

The iOS configuration is already complete:
- `GoogleService-Info.plist` contains the correct configuration
- `Info.plist` has the REVERSED_CLIENT_ID URL scheme configured
- REVERSED_CLIENT_ID: `com.googleusercontent.apps.2475995227-ns4d1lbualimq373tr7b0injqiun3ht7`

---

## 2. Enable Facebook Login

### Step 1: Create Facebook App

1. Go to [Facebook Developers](https://developers.facebook.com/)
2. Click **My Apps** → **Create App**
3. Select **Consumer** as the app type
4. Fill in the app details:
   - **App Name**: Tether
   - **App Contact Email**: Your email
5. Click **Create App**

### Step 2: Add Facebook Login Product

1. In your Facebook App Dashboard, click **Add Product**
2. Find **Facebook Login** and click **Set Up**
3. Select **iOS** and **Android** as platforms

### Step 3: Configure OAuth Redirect URI

1. In Firebase Console, go to **Authentication** → **Sign-in method**
2. Click on **Facebook** provider
3. Toggle **Enable**
4. Copy the **OAuth redirect URI** shown (it will look like: `https://tether-app-prod-ee05c.firebaseapp.com/__/auth/handler`)
5. In Facebook App Dashboard, go to **Facebook Login** → **Settings**
6. Paste the OAuth redirect URI into **Valid OAuth Redirect URIs**
7. Click **Save Changes**

### Step 4: Get Facebook App Credentials

1. In Facebook App Dashboard, go to **Settings** → **Basic**
2. Copy the **App ID** and **App Secret**
3. In Firebase Console, paste these values:
   - **App ID**: [Your Facebook App ID]
   - **App Secret**: [Your Facebook App Secret]
4. Click **Save** in Firebase Console

### Step 5: Update iOS Configuration

Edit `ios/Runner/Info.plist` and replace `YOUR-APP-ID` with your actual Facebook App ID:

```xml
<!-- Facebook Configuration -->
<key>FacebookAppID</key>
<string>YOUR-APP-ID</string>
```

Also update the URL scheme:
```xml
<string>fbYOUR-APP-ID</string>
```

### Step 6: Update Android Configuration

Edit `android/app/src/main/res/values/strings.xml` and replace the placeholders:

```xml
<string name="facebook_app_id">YOUR-APP-ID</string>
<string name="fb_login_protocol_scheme">fbYOUR-APP-ID</string>
<string name="facebook_client_token">YOUR-CLIENT-TOKEN</string>
```

**To get the Client Token:**
1. Facebook App Dashboard → **Settings** → **Advanced**
2. Scroll to **Security** section
3. Copy the **Client Token**

### Step 7: Configure Android Package

1. In Facebook App Dashboard, go to **Settings** → **Basic**
2. Scroll to **Android** section (click **Add Platform** if not present)
3. Enter:
   - **Package Name**: `com.wy.tether.app`
   - **Default Activity Class**: `com.wy.tether.app.MainActivity`
   - **Key Hashes**: Generate using the command below

**Generate Key Hash for Android:**
```bash
keytool -exportcert -alias androiddebugkey -keystore ~/.android/debug.keystore | openssl sha1 -binary | openssl base64
# Password: android
```

4. Click **Save Changes**

### Step 8: Configure iOS Bundle ID

1. In Facebook App Dashboard, go to **Settings** → **Basic**
2. Scroll to **iOS** section (click **Add Platform** if not present)
3. Enter:
   - **Bundle ID**: `com.wy.tether.app`
4. Click **Save Changes**

---

## 3. Enable Apple Sign-In (iOS Only)

### Step 1: Apple Developer Portal

1. Go to [Apple Developer](https://developer.apple.com/account/)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Click **Identifiers** → Select your App ID (`com.wy.tether.app`)
4. Scroll to **Sign In with Apple** capability
5. Check the box to enable it
6. Click **Save**

### Step 2: Firebase Console Setup

1. In Firebase Console, go to **Authentication** → **Sign-in method**
2. Click on **Apple** provider
3. Toggle **Enable**
4. Click **Save**

**Note**: For web authentication, you would need to configure a Service ID, but for native iOS app, the basic setup above is sufficient.

### Step 3: Xcode Configuration (Already Done)

The following files have been configured:
- `ios/Runner/Runner.entitlements` - Contains Sign In with Apple capability
- You'll need to add this file to your Xcode project:
  1. Open `ios/Runner.xcworkspace` in Xcode
  2. Right-click on **Runner** folder → **Add Files to "Runner"**
  3. Select `Runner.entitlements`
  4. Make sure "Copy items if needed" is unchecked
  5. Click **Add**

Alternatively, Xcode should automatically create entitlements when you add the capability:
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select the **Runner** target
3. Go to **Signing & Capabilities** tab
4. Click **+ Capability**
5. Add **Sign In with Apple**

---

## 4. Testing Checklist

Before testing, ensure all the following are configured:

### Google Sign-In:
- [ ] Google provider enabled in Firebase Console
- [ ] Support email set in Firebase Console
- [ ] SHA-1 and SHA-256 fingerprints added for Android
- [ ] `GoogleService-Info.plist` and `google-services.json` up to date

### Facebook Login:
- [ ] Facebook app created at developers.facebook.com
- [ ] Facebook Login product added to the app
- [ ] OAuth redirect URI added to Facebook app settings
- [ ] Facebook provider enabled in Firebase Console with App ID and Secret
- [ ] `YOUR-APP-ID` replaced in `ios/Runner/Info.plist`
- [ ] `YOUR-APP-ID` and `YOUR-CLIENT-TOKEN` replaced in `android/app/src/main/res/values/strings.xml`
- [ ] Android package name and key hash added to Facebook app
- [ ] iOS bundle ID added to Facebook app

### Apple Sign-In:
- [ ] Sign In with Apple capability enabled for App ID in Apple Developer Portal
- [ ] Apple provider enabled in Firebase Console
- [ ] `Runner.entitlements` added to Xcode project
- [ ] Sign In with Apple capability added in Xcode

---

## 5. Test the Authentication Flows

### Testing on iOS Simulator:
- **Google Sign-In**: Should work
- **Facebook Login**: Should work
- **Apple Sign-In**: Requires physical device (will NOT work in simulator)
- **Biometric Auth**: Requires physical device (will NOT work in simulator)

### Testing on Android Emulator:
- **Google Sign-In**: Should work if SHA fingerprints are added
- **Facebook Login**: Should work
- **Apple Sign-In**: Not available on Android
- **Biometric Auth**: Can be tested in emulator with virtual fingerprint

### Testing on Physical Devices:
- All authentication methods should work on physical devices
- Make sure to test on both iOS and Android if possible
- Verify that the same user data appears regardless of sign-in method

---

## 6. Common Issues and Solutions

### Google Sign-In Error: "Developer Error"
- **Solution**: Make sure SHA-1 fingerprint is added to Firebase Console for Android
- Download updated `google-services.json` after adding fingerprints

### Facebook Login Error: "Invalid OAuth redirect URI"
- **Solution**: Ensure the Firebase OAuth redirect URI is added to Facebook app's Valid OAuth Redirect URIs

### Facebook Login Error: "App not setup"
- **Solution**:
  - Make sure Facebook app is in development or live mode
  - Add yourself as a test user if in development mode
  - Check that Android package name and iOS bundle ID are correctly configured

### Apple Sign-In Error: "Invalid client"
- **Solution**:
  - Ensure Sign In with Apple capability is enabled in Apple Developer Portal
  - Check that Bundle ID matches in both Xcode and Apple Developer Portal
  - Make sure the capability is added in Xcode's Signing & Capabilities tab

---

## 7. Production Deployment

Before releasing to production:

1. **Google**:
   - Generate production release keystore for Android
   - Add production SHA-1/SHA-256 to Firebase Console
   - Download updated `google-services.json`

2. **Facebook**:
   - Switch Facebook app to **Live** mode
   - Generate and add production key hash for Android
   - Remove test users/developers

3. **Apple**:
   - Test on physical iOS devices
   - Ensure production provisioning profile includes Sign In with Apple capability

4. **Firebase**:
   - Review authentication usage and quota limits
   - Set up monitoring for authentication errors
   - Test all authentication flows on production builds

---

## Next Steps

1. Follow the instructions above to configure each provider in Firebase Console
2. Update the placeholder values in the configuration files
3. Test each authentication method
4. Verify that user data persists across different sign-in methods
5. Implement provider management screen (optional - allows users to link/unlink providers)

For detailed implementation information, see [SOCIAL_AUTH_SETUP.md](SOCIAL_AUTH_SETUP.md).
