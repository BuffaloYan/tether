import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Helper class for Firebase operations in E2E tests
/// Provides methods to set up and tear down test data
class FirebaseHelper {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Clear all test data from Firestore and Auth
  Future<void> clearAllData() async {
    try {
      // Sign out current user
      await _auth.signOut();

      // Clear Firestore data (contacts collection)
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final contactsRef = _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('contacts');

        final snapshot = await contactsRef.get();
        for (final doc in snapshot.docs) {
          await doc.reference.delete();
        }
      }
    } catch (e) {
      print('Error clearing data: $e');
    }
  }

  /// Create a test user with email and password
  Future<UserCredential> createTestUser({
    required String email,
    required String password,
  }) async {
    try {
      // First, make sure we're signed out
      if (_auth.currentUser != null) {
        await _auth.signOut();
      }

      // Try to create a new user
      try {
        return await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        // If user already exists, sign in instead
        if (e.code == 'email-already-in-use') {
          try {
            return await _auth.signInWithEmailAndPassword(
              email: email,
              password: password,
            );
          } catch (signInError) {
            // If sign in also fails, the password might be wrong or account is in bad state
            // In emulator, we can't recover from this, so rethrow
            print('Error signing in with existing user: $signInError');
            rethrow;
          }
        }
        // For other errors, rethrow
        rethrow;
      }
    } catch (e) {
      print('Error creating test user: $e');
      rethrow;
    }
  }

  /// Delete test user
  Future<void> deleteTestUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.delete();
      }
    } catch (e) {
      print('Error deleting test user: $e');
    }
  }

  /// Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Check if user is signed in
  bool isUserSignedIn() {
    return _auth.currentUser != null;
  }
}
