import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_auth/local_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
// import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';  // Disabled
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalAuthentication _localAuth = LocalAuthentication();
  final GoogleSignIn _googleSignIn = GoogleSignIn();

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

  // ==================== SOCIAL AUTHENTICATION METHODS ====================

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      // Trigger the Google Sign In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        return false;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      try {
        final UserCredential userCredential = await _auth.signInWithCredential(credential);
        _user = userCredential.user;
      } catch (e) {
        // Handle Pigeon type cast error - auth still works, just internal error
        if (e.toString().contains('PigeonUserDetails') ||
            e.toString().contains('type cast')) {
          debugPrint('Ignoring internal Firebase type cast error, checking auth state...');
          // Wait a moment for auth state to update
          await Future.delayed(const Duration(milliseconds: 500));
          _user = _auth.currentUser;

          if (_user == null) {
            debugPrint('User is null after sign in, authentication failed');
            return false;
          }
        } else {
          rethrow;
        }
      }

      // Link to existing device or create new one
      await _linkOrCreateUser('google',
        email: _user?.email,
        displayName: _user?.displayName,
        photoUrl: _user?.photoURL,
      );

      _isAuthenticated = true;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      return false;
    }
  }

  /// Sign in with Facebook - DISABLED
  Future<bool> signInWithFacebook() async {
    debugPrint('Facebook sign-in is currently disabled');
    return false;
    // try {
    //   // Trigger the Facebook Sign In flow
    //   final LoginResult result = await FacebookAuth.instance.login();
    //
    //   if (result.status != LoginStatus.success) {
    //     debugPrint('Facebook login failed: ${result.status}');
    //     return false;
    //   }
    //
    //   // Create a credential from the access token
    //   final OAuthCredential credential = FacebookAuthProvider.credential(
    //     result.accessToken!.tokenString,
    //   );
    //
    //   // Sign in to Firebase with the Facebook credential
    //   final UserCredential userCredential = await _auth.signInWithCredential(credential);
    //   _user = userCredential.user;
    //
    //   // Get additional user data from Facebook
    //   final userData = await FacebookAuth.instance.getUserData();
    //
    //   // Link to existing device or create new one
    //   await _linkOrCreateUser('facebook',
    //     email: userData['email'] as String?,
    //     displayName: userData['name'] as String?,
    //     photoUrl: userData['picture']?['data']?['url'] as String?,
    //   );
    //
    //   _isAuthenticated = true;
    //   notifyListeners();
    //   return true;
    // } catch (e) {
    //   debugPrint('Error signing in with Facebook: $e');
    //   return false;
    // }
  }

  /// Sign in with Apple (iOS only)
  Future<bool> signInWithApple() async {
    try {
      // Check if running on iOS
      if (!Platform.isIOS) {
        debugPrint('Apple Sign In is only available on iOS');
        return false;
      }

      // Request credential for the currently signed in Apple account
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Create an OAuthCredential from the credential returned by Apple
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Sign in to Firebase with the Apple credential
      final UserCredential userCredential = await _auth.signInWithCredential(oauthCredential);
      _user = userCredential.user;

      // Construct display name from Apple credentials
      String? displayName;
      if (appleCredential.givenName != null || appleCredential.familyName != null) {
        displayName = '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'.trim();
      }

      // Link to existing device or create new one
      await _linkOrCreateUser('apple',
        email: appleCredential.email ?? _user?.email,
        displayName: displayName ?? _user?.displayName,
        photoUrl: _user?.photoURL,
      );

      _isAuthenticated = true;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error signing in with Apple: $e');
      return false;
    }
  }

  /// Link social auth to existing device or create new user
  Future<void> _linkOrCreateUser(String provider, {
    String? email,
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      // Load or generate device ID
      await _loadDeviceId();
      if (_deviceId == null) {
        await _generateDeviceId();
      }

      // Check if user document exists for this device
      final userDoc = await _firestore.collection('users').doc(_deviceId).get();

      if (userDoc.exists) {
        // Update existing user with new provider and profile info
        final currentProviders = List<String>.from(userDoc.data()?['authProviders'] ?? []);
        if (!currentProviders.contains(provider)) {
          currentProviders.add(provider);
        }

        await _firestore.collection('users').doc(_deviceId).update({
          'uid': _user!.uid,
          'authProviders': currentProviders,
          'email': email ?? userDoc.data()?['email'],
          'displayName': displayName ?? userDoc.data()?['displayName'],
          'photoUrl': photoUrl ?? userDoc.data()?['photoUrl'],
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Create new user document
        await _firestore.collection('users').doc(_deviceId).set({
          'uid': _user!.uid,
          'deviceId': _deviceId,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
          'authProviders': [provider],
          'email': email,
          'displayName': displayName,
          'photoUrl': photoUrl,
          'gracePeriodHours': 24,
          'preferredLanguage': 'en',
          'isPremium': false,
          'alerted': false,
        });
      }
    } catch (e) {
      debugPrint('Error linking or creating user: $e');
      rethrow;
    }
  }

  /// Get list of linked authentication providers for current user
  Future<List<String>> getLinkedProviders() async {
    try {
      if (_deviceId != null) {
        final doc = await _firestore.collection('users').doc(_deviceId).get();
        if (doc.exists) {
          return List<String>.from(doc.data()?['authProviders'] ?? ['biometric']);
        }
      }
      return ['biometric'];
    } catch (e) {
      debugPrint('Error getting linked providers: $e');
      return ['biometric'];
    }
  }

  /// Unlink a specific authentication provider
  Future<bool> unlinkProvider(String provider) async {
    try {
      if (_deviceId == null) return false;

      final doc = await _firestore.collection('users').doc(_deviceId).get();
      if (!doc.exists) return false;

      final currentProviders = List<String>.from(doc.data()?['authProviders'] ?? []);

      // Don't allow unlinking if it's the only provider
      if (currentProviders.length <= 1) {
        debugPrint('Cannot unlink the only authentication provider');
        return false;
      }

      currentProviders.remove(provider);

      await _firestore.collection('users').doc(_deviceId).update({
        'authProviders': currentProviders,
      });

      // Also unlink from Firebase Auth if applicable
      final user = _auth.currentUser;
      if (user != null) {
        for (final providerData in user.providerData) {
          if ((provider == 'google' && providerData.providerId == 'google.com') ||
              (provider == 'facebook' && providerData.providerId == 'facebook.com') ||
              (provider == 'apple' && providerData.providerId == 'apple.com')) {
            await user.unlink(providerData.providerId);
          }
        }
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error unlinking provider: $e');
      return false;
    }
  }
}
