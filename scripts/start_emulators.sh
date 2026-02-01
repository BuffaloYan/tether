#!/bin/bash

echo "Starting Firebase Emulators for testing..."
echo ""
echo "Firestore: http://localhost:8080"
echo "Auth: http://localhost:9099"
echo "Emulator UI: http://localhost:4000"
echo ""
echo "Press Ctrl+C to stop emulators"
echo ""

firebase emulators:start --only firestore,auth
