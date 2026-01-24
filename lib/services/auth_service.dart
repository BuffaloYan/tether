import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_auth/local_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalAuthentication _localAuth = LocalAuthentication();

  User? _user;
  String? _deviceId;
  bool _isAuthenticated = false;

  bool get isAuthenticated => _isAuthenticated;
  User? get user => _user;
  String? get deviceId => _deviceId;

  AuthService() {
    _init();
  }

  Future<void> _init() async {
    // Check if user was previously authenticated
    _user = _auth.currentUser;
    if (_user != null) {
      await _loadDeviceId();
      _isAuthenticated = true;
      notifyListeners();
    }
  }

  /// Check if device supports biometric authentication
  Future<bool> canAuthenticateWithBiometrics() async {
    try {
      final bool canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();
      return canAuthenticate;
    } catch (e) {
      debugPrint('Error checking biometric support: $e');
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('Error getting available biometrics: $e');
      return [];
    }
  }

  /// Authenticate with biometrics
  Future<bool> authenticateWithBiometrics() async {
    try {
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access Tether',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (didAuthenticate) {
        await _signInOrCreateUser();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error during biometric authentication: $e');
      return false;
    }
  }

  /// Sign in or create anonymous user
  Future<void> _signInOrCreateUser() async {
    try {
      // Check if user already exists
      if (_auth.currentUser != null) {
        _user = _auth.currentUser;
        await _loadDeviceId();
      } else {
        // Create anonymous user
        final UserCredential credential = await _auth.signInAnonymously();
        _user = credential.user;

        // Generate device ID
        await _generateDeviceId();

        // Create user document in Firestore
        if (_user != null && _deviceId != null) {
          await _firestore.collection('users').doc(_deviceId).set({
            'uid': _user!.uid,
            'createdAt': FieldValue.serverTimestamp(),
            'deviceId': _deviceId,
            'gracePeriodHours': 24,
            'preferredLanguage': 'en',
            'isPremium': false,
            'alerted': false,
          });
        }
      }

      _isAuthenticated = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error signing in: $e');
      rethrow;
    }
  }

  /// Generate and store device ID
  Future<void> _generateDeviceId() async {
    const uuid = Uuid();
    _deviceId = uuid.v4();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('device_id', _deviceId!);
  }

  /// Load device ID from storage
  Future<void> _loadDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    _deviceId = prefs.getString('device_id');
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  /// Update user's preferred language
  Future<void> updateLanguage(String languageCode) async {
    if (_deviceId != null) {
      await _firestore.collection('users').doc(_deviceId).update({
        'preferredLanguage': languageCode,
      });
      notifyListeners();
    }
  }

  /// Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData() async {
    if (_deviceId != null) {
      final doc = await _firestore.collection('users').doc(_deviceId).get();
      return doc.data();
    }
    return null;
  }
}
