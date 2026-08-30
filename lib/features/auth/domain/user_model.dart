import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// User model — represents both drivers and admins.
class UserModel extends Equatable {
  final String uid;
  final String name;
  final String email;
  final String? phone;
  final String role; // 'driver' | 'admin'
  final String? fleetId;
  final String? deviceId;
  final String? fcmToken;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;
  final double? lat;
  final double? lng;
  final String? placeName;
  final DateTime? locationUpdatedAt;
  final bool isOnline;

  // New Dashboard Tracking Fields
  final String? carrierStatus; // 'locked' | 'unlocked'
  final DateTime? carrierUnlockedAt;
  final double? unlockLat;
  final double? unlockLng;
  final Map<String, dynamic>? fleetStats;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.fleetId,
    this.deviceId,
    this.fcmToken,
    this.createdAt,
    this.lastLoginAt,
    this.lat,
    this.lng,
    this.placeName,
    this.locationUpdatedAt,
    this.isOnline = false,
    this.carrierStatus = 'locked',
    this.carrierUnlockedAt,
    this.unlockLat,
    this.unlockLng,
    this.fleetStats,
  });

  bool get isDriver => role == 'driver';
  bool get isAdmin => role == 'admin';

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final location = data['currentLocation'] as Map<String, dynamic>?;

    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      role: data['role'] ?? 'driver',
      fleetId: data['fleetId'],
      deviceId: data['deviceId'],
      fcmToken: data['fcmToken'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
      lat: location?['lat']?.toDouble(),
      lng: location?['lng']?.toDouble(),
      placeName: location?['placeName'],
      locationUpdatedAt: (location?['updatedAt'] as Timestamp?)?.toDate(),
      isOnline: data['isOnline'] ?? false,
      carrierStatus: data['carrierStatus'] ?? 'locked',
      carrierUnlockedAt: (data['carrierUnlockedAt'] as Timestamp?)?.toDate(),
      unlockLat: data['unlockLat']?.toDouble(),
      unlockLng: data['unlockLng']?.toDouble(),
      fleetStats: data['fleetStats'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      if (phone != null) 'phone': phone,
      'role': role,
      if (fleetId != null) 'fleetId': fleetId,
      if (deviceId != null) 'deviceId': deviceId,
      if (fcmToken != null) 'fcmToken': fcmToken,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
      if (lat != null && lng != null)
        'currentLocation': {
          'lat': lat,
          'lng': lng,
          'placeName': placeName,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      'isOnline': isOnline,
      'carrierStatus': carrierStatus,
      if (carrierUnlockedAt != null)
        'carrierUnlockedAt': Timestamp.fromDate(carrierUnlockedAt!),
      if (unlockLat != null) 'unlockLat': unlockLat,
      if (unlockLng != null) 'unlockLng': unlockLng,
      if (fleetStats != null) 'fleetStats': fleetStats,
    };
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? fleetId,
    String? deviceId,
    String? fcmToken,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    double? lat,
    double? lng,
    String? placeName,
    DateTime? locationUpdatedAt,
    bool? isOnline,
    String? carrierStatus,
    DateTime? carrierUnlockedAt,
    double? unlockLat,
    double? unlockLng,
    Map<String, dynamic>? fleetStats,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      fleetId: fleetId ?? this.fleetId,
      deviceId: deviceId ?? this.deviceId,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      placeName: placeName ?? this.placeName,
      locationUpdatedAt: locationUpdatedAt ?? this.locationUpdatedAt,
      isOnline: isOnline ?? this.isOnline,
      carrierStatus: carrierStatus ?? this.carrierStatus,
      carrierUnlockedAt: carrierUnlockedAt ?? this.carrierUnlockedAt,
      unlockLat: unlockLat ?? this.unlockLat,
      unlockLng: unlockLng ?? this.unlockLng,
      fleetStats: fleetStats ?? this.fleetStats,
    );
  }

  @override
  List<Object?> get props => [uid, name, email, role, fleetId, isOnline];
}
