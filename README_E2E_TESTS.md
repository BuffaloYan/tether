# E2E Testing Guide

## Prerequisites

1. **Start Firebase Emulators** (in a separate terminal):
   ```bash
   firebase emulators:start --only firestore,auth
   ```

   Make sure emulators are running on:
   - Firestore: `127.0.0.1:8088`
   - Auth: `127.0.0.1:9099`

2. **Start Android Emulator or iOS Simulator**:
   ```bash
   # Check available devices
   flutter devices

   # Start Android emulator (if not running)
   flutter emulators --launch <emulator_name>
   ```

## Running E2E Tests

### The Problem with `flutter test`

**DO NOT USE** `flutter test integration_test/contacts_e2e_test.dart -d <device>`

This command internally runs tests with `-p vm` which doesn't support Firebase platform channels, causing errors like:
```
type 'List<Object?>' is not a subtype of type 'PigeonUserDetails?' in type cast
```

### Current Workaround: Manual Testing

Until Flutter properly supports integration tests on devices without VM mode, use this manual approach:

1. **Build and install the app**:
   ```bash
   flutter run -d emulator-5554 integration_test/contacts_e2e_test.dart --release
   ```

2. **Watch the tests execute** on the device

3. **Check terminal output** for test results

### Alternative: Use Android Studio / VS Code

1. Open the project in Android Studio or VS Code
2. Right-click on `integration_test/contacts_e2e_test.dart`
3. Select "Run" (not "Debug")
4. Select the target device

## Test Configuration

- **Firebase Emulator Config**: [emulator_helper.dart](integration_test/helpers/emulator_helper.dart)
  - Firestore: `127.0.0.1:8088`
  - Auth: `127.0.0.1:9099`

- **Main App**: Modified to support `skipFirebaseInit` parameter for testing

- **Android Manifest**: Configured to allow cleartext HTTP traffic for emulator connections

## Troubleshooting

### Connection Refused Errors
- Ensure Firebase emulators are running
- Verify emulators are on correct ports (`lsof -i :8088` and `lsof -i :9099`)
- Check that emulators are listening on `127.0.0.1`, not `localhost`

### Email Already in Use
- Tests use unique timestamp-based emails to avoid conflicts
- Each test gets a fresh user account

### Type Cast Errors
- This indicates tests are running in VM mode
- Make sure you're using `flutter run` or IDE run, not `flutter test`

## Known Limitations

- Firebase emulator data is NOT automatically cleared between tests
- Tests use unique email addresses per test to work around this
- Full emulator reset requires restarting Firebase emulators
