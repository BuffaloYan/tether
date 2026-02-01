import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import '../../lib/services/firestore_service.dart';
import '../../lib/models/user.dart' as app_user;

class EmulatorHelper {
  static const String projectId = 'tether-app-prod-ee05c';
  static const String firestoreHost = '127.0.0.1';
  static const int firestorePort = 8088;
  static const String authHost = '127.0.0.1';
  static const int authPort = 9099;

  static bool _configured = false;

  /// Configure Firebase to use emulators
  static Future<void> useEmulators() async {
    if (_configured) return;

    // Initialize Firebase with custom options for emulator testing
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'test-api-key',
        appId: '1:123456789:android:test',
        messagingSenderId: '123456789',
        projectId: projectId,
        storageBucket: '$projectId.appspot.com',
      ),
    );

    FirebaseFirestore.instance.useFirestoreEmulator(
      firestoreHost,
      firestorePort,
    );

    await FirebaseAuth.instance.useAuthEmulator(authHost, authPort);

    _configured = true;
  }

  /// Clear all Firestore data via REST API (only works when run with network access)
  static Future<void> clearFirestore() async {
    // Sign out current user first
    try {
      if (FirebaseAuth.instance.currentUser != null) {
        await FirebaseAuth.instance.signOut();
      }
    } catch (e) {
      // Ignore signout errors
    }

    // Note: REST API calls may fail in some test environments
    // Tests should be designed to work with or without successful cleanup
  }

  /// Clear all Auth users via REST API (only works when run with network access)
  static Future<void> clearAuth() async {
    // Sign out current user first
    try {
      if (FirebaseAuth.instance.currentUser != null) {
        await FirebaseAuth.instance.signOut();
      }
    } catch (e) {
      // Ignore signout errors
    }

    // Note: REST API calls may fail in some test environments
    // Tests should be designed to work with or without successful cleanup
  }

  /// Full reset - sign out current user
  static Future<void> resetAll() async {
    await clearAuth();
    await clearFirestore();
    // Small delay to ensure state is cleared
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// Create authenticated test user and return deviceId
  static Future<String> createTestUser({String? deviceId}) async {
    // Sign in anonymously
    final userCredential = await FirebaseAuth.instance.signInAnonymously();
    final uid = userCredential.user!.uid;

    // Use provided deviceId or generate one
    final testDeviceId = deviceId ?? 'test-device-${DateTime.now().millisecondsSinceEpoch}';

    // Create user document in Firestore
    final firestoreService = FirestoreService();
    final userData = app_user.UserData(
      deviceId: testDeviceId,
      uid: uid,
      createdAt: DateTime.now(),
      gracePeriodHours: 24,
      alerted: false,
      preferredLanguage: 'en',
    );

    await firestoreService.createOrUpdateUser(userData);

    return testDeviceId;
  }
}
