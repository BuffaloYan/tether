import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/contact.dart';
import '../models/location.dart';
import '../models/user.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _usersCollection => _firestore.collection('users');

  /// Create or update user document
  Future<bool> createOrUpdateUser(UserData user) async {
    try {
      await _usersCollection.doc(user.deviceId).set(user.toJson(), SetOptions(merge: true));
      debugPrint('User document created/updated: ${user.deviceId}');
      return true;
    } catch (e) {
      debugPrint('Error creating/updating user: $e');
      return false;
    }
  }

  /// Get user document
  Future<UserData?> getUser(String deviceId) async {
    try {
      final doc = await _usersCollection.doc(deviceId).get();
      if (doc.exists) {
        return UserData.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user: $e');
      return null;
    }
  }

  /// Update last check-in timestamp
  Future<bool> updateCheckIn(String deviceId, {LocationData? location}) async {
    try {
      final updateData = {
        'lastCheckIn': FieldValue.serverTimestamp(),
        'alertStatus': 'ok',
      };

      // Add location data if provided
      if (location != null) {
        updateData['lastLocation'] = location.toJson();
      }

      await _usersCollection.doc(deviceId).update(updateData);
      debugPrint('Check-in updated for device: $deviceId');
      return true;
    } catch (e) {
      debugPrint('Error updating check-in: $e');
      return false;
    }
  }

  /// Add check-in to history (optional feature)
  Future<bool> addCheckInHistory(String deviceId, LocationData? location) async {
    try {
      await _usersCollection
          .doc(deviceId)
          .collection('checkInHistory')
          .add({
        'timestamp': FieldValue.serverTimestamp(),
        'location': location?.toJson(),
      });
      debugPrint('Check-in added to history');
      return true;
    } catch (e) {
      debugPrint('Error adding check-in history: $e');
      return false;
    }
  }

  /// Get check-in history
  Future<List<Map<String, dynamic>>> getCheckInHistory(String deviceId, {int limit = 10}) async {
    try {
      final querySnapshot = await _usersCollection
          .doc(deviceId)
          .collection('checkInHistory')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('Error getting check-in history: $e');
      return [];
    }
  }

  /// Add emergency contact
  Future<bool> addContact(String deviceId, Contact contact) async {
    try {
      // Check if max contacts limit reached
      final contacts = await getContacts(deviceId);
      if (contacts.length >= 3) {
        debugPrint('Maximum contacts limit (3) reached');
        return false;
      }

      // Check if priority is already taken
      final priorityTaken = contacts.any((c) => c.priority == contact.priority);
      if (priorityTaken) {
        debugPrint('Priority ${contact.priority} already assigned');
        return false;
      }

      await _usersCollection
          .doc(deviceId)
          .collection('contacts')
          .doc(contact.id)
          .set(contact.toJson());

      debugPrint('Contact added: ${contact.name}');
      return true;
    } catch (e) {
      debugPrint('Error adding contact: $e');
      return false;
    }
  }

  /// Update emergency contact
  Future<bool> updateContact(String deviceId, Contact contact) async {
    try {
      // Check if priority change conflicts with existing contacts
      final contacts = await getContacts(deviceId);
      final priorityTaken = contacts.any((c) =>
        c.priority == contact.priority && c.id != contact.id
      );

      if (priorityTaken) {
        debugPrint('Priority ${contact.priority} already assigned to another contact');
        return false;
      }

      await _usersCollection
          .doc(deviceId)
          .collection('contacts')
          .doc(contact.id)
          .set(contact.toJson());

      debugPrint('Contact updated: ${contact.name}');
      return true;
    } catch (e) {
      debugPrint('Error updating contact: $e');
      return false;
    }
  }

  /// Delete emergency contact
  Future<bool> deleteContact(String deviceId, String contactId) async {
    try {
      await _usersCollection
          .doc(deviceId)
          .collection('contacts')
          .doc(contactId)
          .delete();

      debugPrint('Contact deleted: $contactId');
      return true;
    } catch (e) {
      debugPrint('Error deleting contact: $e');
      return false;
    }
  }

  /// Get all emergency contacts
  Future<List<Contact>> getContacts(String deviceId) async {
    try {
      final querySnapshot = await _usersCollection
          .doc(deviceId)
          .collection('contacts')
          .orderBy('priority')
          .get();

      return querySnapshot.docs
          .map((doc) => Contact.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting contacts: $e');
      return [];
    }
  }

  /// Get contacts stream for real-time updates
  Stream<List<Contact>> getContactsStream(String deviceId) {
    return _usersCollection
        .doc(deviceId)
        .collection('contacts')
        .orderBy('priority')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Contact.fromJson(doc.data()))
            .toList());
  }

  /// Update grace period
  Future<bool> updateGracePeriod(String deviceId, int gracePeriodHours) async {
    try {
      await _usersCollection.doc(deviceId).update({
        'gracePeriodHours': gracePeriodHours,
      });
      debugPrint('Grace period updated to $gracePeriodHours hours');
      return true;
    } catch (e) {
      debugPrint('Error updating grace period: $e');
      return false;
    }
  }

  /// Update alert status
  Future<bool> updateAlertStatus(String deviceId, String status) async {
    try {
      await _usersCollection.doc(deviceId).update({
        'alertStatus': status,
      });
      debugPrint('Alert status updated to: $status');
      return true;
    } catch (e) {
      debugPrint('Error updating alert status: $e');
      return false;
    }
  }

  /// Pause/resume alerts
  Future<bool> setAlertsPaused(String deviceId, bool paused) async {
    try {
      await _usersCollection.doc(deviceId).update({
        'alertsPaused': paused,
      });
      debugPrint('Alerts ${paused ? 'paused' : 'resumed'}');
      return true;
    } catch (e) {
      debugPrint('Error setting alerts paused status: $e');
      return false;
    }
  }

  /// Update language preference
  Future<bool> updateLanguage(String deviceId, String languageCode) async {
    try {
      await _usersCollection.doc(deviceId).update({
        'language': languageCode,
      });
      debugPrint('Language updated to: $languageCode');
      return true;
    } catch (e) {
      debugPrint('Error updating language: $e');
      return false;
    }
  }

  /// Trigger immediate alert (for testing or emergency)
  Future<bool> triggerImmediateAlert(String deviceId, {LocationData? location}) async {
    try {
      final updateData = {
        'alertStatus': 'triggered',
        'alertTriggeredAt': FieldValue.serverTimestamp(),
      };

      if (location != null) {
        updateData['lastLocation'] = location.toJson();
      }

      await _usersCollection.doc(deviceId).update(updateData);
      debugPrint('Immediate alert triggered');
      return true;
    } catch (e) {
      debugPrint('Error triggering immediate alert: $e');
      return false;
    }
  }

  /// Get user stream for real-time updates
  Stream<UserData?> getUserStream(String deviceId) {
    return _usersCollection.doc(deviceId).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return UserData.fromJson(snapshot.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  /// Delete user account and all associated data
  Future<bool> deleteUserAccount(String deviceId) async {
    try {
      // Delete contacts subcollection
      final contactsSnapshot = await _usersCollection
          .doc(deviceId)
          .collection('contacts')
          .get();

      for (var doc in contactsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete check-in history subcollection
      final historySnapshot = await _usersCollection
          .doc(deviceId)
          .collection('checkInHistory')
          .get();

      for (var doc in historySnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete user document
      await _usersCollection.doc(deviceId).delete();

      debugPrint('User account deleted: $deviceId');
      return true;
    } catch (e) {
      debugPrint('Error deleting user account: $e');
      return false;
    }
  }

  /// Get time until next required check-in
  Future<Duration?> getTimeUntilNextCheckIn(String deviceId) async {
    try {
      final userData = await getUser(deviceId);
      if (userData == null || userData.lastCheckIn == null) {
        return null;
      }

      final gracePeriod = Duration(hours: userData.gracePeriodHours);
      final nextCheckIn = userData.lastCheckIn!.add(gracePeriod);
      final remaining = nextCheckIn.difference(DateTime.now());

      return remaining.isNegative ? Duration.zero : remaining;
    } catch (e) {
      debugPrint('Error calculating time until next check-in: $e');
      return null;
    }
  }

  /// Check if user is overdue for check-in
  Future<bool> isOverdue(String deviceId) async {
    final remaining = await getTimeUntilNextCheckIn(deviceId);
    return remaining == Duration.zero;
  }
}
