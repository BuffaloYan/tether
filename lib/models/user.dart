import 'contact.dart';
import 'location.dart';

class UserData {
  final String deviceId;  // Stable internal UUID - never changes
  final String uid;       // Firebase Auth UID - can change if user links different providers
  final DateTime createdAt;
  final DateTime? lastCheckIn;
  final LocationData? lastLocation;
  final int gracePeriodHours;
  final String preferredLanguage;
  final bool isPremium;
  final bool alerted;
  final List<Contact> contacts;
  final List<String> authProviders; // Track which providers are linked (biometric, google, facebook, apple)
  final String? email;  // Email from social login (if available)
  final String? displayName;  // Display name from social login (if available)
  final String? photoUrl;  // Profile photo URL from social login (if available)

  UserData({
    required this.deviceId,
    required this.uid,
    required this.createdAt,
    this.lastCheckIn,
    this.lastLocation,
    this.gracePeriodHours = 24,
    this.preferredLanguage = 'en',
    this.isPremium = false,
    this.alerted = false,
    this.contacts = const [],
    this.authProviders = const ['biometric'], // Default to biometric
    this.email,
    this.displayName,
    this.photoUrl,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      deviceId: json['deviceId'] as String,
      uid: json['uid'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastCheckIn: json['lastCheckIn'] != null
          ? DateTime.parse(json['lastCheckIn'] as String)
          : null,
      lastLocation: json['lastLocation'] != null
          ? LocationData.fromJson(json['lastLocation'] as Map<String, dynamic>)
          : null,
      gracePeriodHours: json['gracePeriodHours'] as int? ?? 24,
      preferredLanguage: json['preferredLanguage'] as String? ?? 'en',
      isPremium: json['isPremium'] as bool? ?? false,
      alerted: json['alerted'] as bool? ?? false,
      contacts: (json['contacts'] as List<dynamic>?)
              ?.map((c) => Contact.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      authProviders: (json['authProviders'] as List<dynamic>?)
              ?.map((p) => p as String)
              .toList() ??
          ['biometric'],
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'uid': uid,
      'createdAt': createdAt.toIso8601String(),
      'lastCheckIn': lastCheckIn?.toIso8601String(),
      'lastLocation': lastLocation?.toJson(),
      'gracePeriodHours': gracePeriodHours,
      'preferredLanguage': preferredLanguage,
      'isPremium': isPremium,
      'alerted': alerted,
      'contacts': contacts.map((c) => c.toJson()).toList(),
      'authProviders': authProviders,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
    };
  }

  /// Check if user needs to check in soon
  bool get needsCheckInSoon {
    if (lastCheckIn == null) return true;

    final hoursSinceCheckIn = DateTime.now().difference(lastCheckIn!).inHours;
    final warningThreshold = (gracePeriodHours * 0.8).round(); // Warn at 80%
    return hoursSinceCheckIn >= warningThreshold;
  }

  /// Check if grace period has passed
  bool get gracePeriodPassed {
    if (lastCheckIn == null) return true;

    final hoursSinceCheckIn = DateTime.now().difference(lastCheckIn!).inHours;
    return hoursSinceCheckIn >= gracePeriodHours;
  }

  /// Get time remaining until check-in required
  Duration? get timeUntilCheckInRequired {
    if (lastCheckIn == null) return null;

    final deadline = lastCheckIn!.add(Duration(hours: gracePeriodHours));
    final remaining = deadline.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  UserData copyWith({
    String? deviceId,
    String? uid,
    DateTime? createdAt,
    DateTime? lastCheckIn,
    LocationData? lastLocation,
    int? gracePeriodHours,
    String? preferredLanguage,
    bool? isPremium,
    bool? alerted,
    List<Contact>? contacts,
    List<String>? authProviders,
    String? email,
    String? displayName,
    String? photoUrl,
  }) {
    return UserData(
      deviceId: deviceId ?? this.deviceId,
      uid: uid ?? this.uid,
      createdAt: createdAt ?? this.createdAt,
      lastCheckIn: lastCheckIn ?? this.lastCheckIn,
      lastLocation: lastLocation ?? this.lastLocation,
      gracePeriodHours: gracePeriodHours ?? this.gracePeriodHours,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      isPremium: isPremium ?? this.isPremium,
      alerted: alerted ?? this.alerted,
      contacts: contacts ?? this.contacts,
      authProviders: authProviders ?? this.authProviders,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
