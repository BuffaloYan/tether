#!/bin/bash

# Script to run integration tests on the contacts E2E testing worktree
# This script ensures tests run on a proper device/emulator, not in VM mode

set -e

echo "Starting integration test runner..."
echo ""

# Check if emulators are running
echo "Checking for Firebase emulators..."
if ! lsof -i :8088 > /dev/null 2>&1; then
    echo "ERROR: Firebase Firestore emulator is not running on port 8088"
    echo "Please start the emulators with: firebase emulators:start --only firestore,auth"
    exit 1
fi

if ! lsof -i :9099 > /dev/null 2>&1; then
    echo "ERROR: Firebase Auth emulator is not running on port 9099"
    echo "Please start the emulators with: firebase emulators:start --only firestore,auth"
    exit 1
fi

echo "✓ Firebase emulators are running"
echo ""

# Check for available devices
echo "Checking for available devices..."
flutter devices

echo ""
echo "Please select a device to run tests on:"
echo "1) Android Emulator (if available)"
echo "2) iOS Simulator (if available)"
echo "3) macOS Desktop"
echo ""
read -p "Enter choice (1-3): " choice

case $choice in
    1)
        DEVICE="emulator-5554"
        echo "Running tests on Android Emulator..."
        ;;
    2)
        DEVICE=$(flutter devices | grep "iPhone" | head -1 | awk '{print $4}')
        echo "Running tests on iOS Simulator..."
        ;;
    3)
        DEVICE="macos"
        echo "Running tests on macOS Desktop..."
        ;;
    *)
        echo "Invalid choice. Defaulting to macOS Desktop"
        DEVICE="macos"
        ;;
esac

echo ""
echo "Running integration tests on device: $DEVICE"
echo ""

# Run the integration tests
flutter test integration_test/contacts_e2e_test.dart -d "$DEVICE"

echo ""
echo "✓ Tests completed"
