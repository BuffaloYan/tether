import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import '../../lib/services/firestore_service.dart';
import '../../lib/models/user.dart' as app_user;

class EmulatorHelper {
  static const String projectId = 'tether-app-prod-ee05c';
  static const String firestoreHost = 'localhost';
  static const int firestorePort = 8080;
  static const String authHost = 'localhost';
  static const int authPort = 9099;

  static bool _configured = false;

  /// Configure Firebase to use emulators
  static Future<void> useEmulators() async {
    if (_configured) return;

    await Firebase.initializeApp();

    FirebaseFirestore.instance.useFirestoreEmulator(
      firestoreHost,
      firestorePort,
    );

    await FirebaseAuth.instance.useAuthEmulator(authHost, authPort);

    _configured = true;
  }

  /// Clear all Firestore data via REST API
  static Future<void> clearFirestore() async {
    final url = 'http://$firestoreHost:$firestorePort/emulator/v1/projects/$projectId/databases/(default)/documents';
    await http.delete(Uri.parse(url));
  }

  /// Clear all Auth users via REST API
  static Future<void> clearAuth() async {
    final url = 'http://$authHost:$authPort/emulator/v1/projects/$projectId/accounts';
    await http.delete(Uri.parse(url));
  }

  /// Full reset - clear both Firestore and Auth
  static Future<void> resetAll() async {
    await clearFirestore();
    await clearAuth();
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
      gracePeriodHours: 24,
      alertsPaused: false,
      alertStatus: 'ok',
      language: 'en',
    );

    await firestoreService.createOrUpdateUser(userData);

    return testDeviceId;
  }
}
