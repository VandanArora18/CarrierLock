import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../domain/location_model.dart';

/// Location repository — GPS tracking with Geolocator + Geocoding.
class LocationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check and request location permissions.
  Future<bool> checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  /// Get current position.
  Future<LocationModel> getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );

    String? placeName;
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final pm = placemarks.first;
        placeName = [
          pm.locality,
          pm.subAdministrativeArea,
          pm.administrativeArea
        ].where((s) => s != null && s.isNotEmpty).join(', ');
      }
    } catch (_) {}

    return LocationModel(
      lat: position.latitude,
      lng: position.longitude,
      placeName: placeName,
      updatedAt: DateTime.now(),
      speed: position.speed,
      heading: position.heading,
      accuracy: position.accuracy,
    );
  }

  /// Start a position stream for live tracking.
  Stream<LocationModel> watchPosition() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).asyncMap((position) async {
      String? placeName;
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final pm = placemarks.first;
          placeName = [pm.locality, pm.subAdministrativeArea]
              .where((s) => s != null && s.isNotEmpty)
              .join(', ');
        }
      } catch (_) {}

      return LocationModel(
        lat: position.latitude,
        lng: position.longitude,
        placeName: placeName,
        updatedAt: DateTime.now(),
        speed: position.speed,
        heading: position.heading,
        accuracy: position.accuracy,
      );
    });
  }

  /// Update driver location in Firestore.
  Future<void> updateDriverLocation(
    String uid,
    LocationModel location,
  ) async {
    await _firestore.collection('users').doc(uid).update({
      'currentLocation': {
        'lat': location.lat,
        'lng': location.lng,
        'placeName': location.placeName,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    });
  }
}

/// Provider for LocationRepository.
final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return LocationRepository();
});
