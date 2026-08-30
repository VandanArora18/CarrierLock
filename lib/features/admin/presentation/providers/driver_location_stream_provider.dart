import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DriverLocationData {
  final double latitude;
  final double longitude;
  final double speed;
  final DateTime updatedAt;

  DriverLocationData({
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.updatedAt,
  });

  factory DriverLocationData.fromMap(Map<String, dynamic> map, Timestamp? updatedAt) {
    return DriverLocationData(
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      speed: map['speed']?.toDouble() ?? 0.0,
      updatedAt: updatedAt?.toDate() ?? DateTime.now(),
    );
  }
}

final driverLocationStreamProvider = StreamProvider.family<DriverLocationData?, String>((ref, driverId) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(driverId)
      .snapshots()
      .map((snapshot) {
    if (!snapshot.exists) return null;
    final data = snapshot.data();
    if (data == null || !data.containsKey('lastLocation') || data['lastLocation'] == null) {
      return null;
    }
    return DriverLocationData.fromMap(
      data['lastLocation'] as Map<String, dynamic>,
      data['locationUpdatedAt'] as Timestamp?,
    );
  });
});
