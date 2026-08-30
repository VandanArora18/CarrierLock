import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<Position>? _positionStream;

  /// Checks and requests location permissions
  Future<bool> requestPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  /// Get current one-time location
  Future<Position?> getCurrentLocation() async {
    if (await requestPermission()) {
      return await Geolocator.getCurrentPosition();
    }
    return null;
  }

  /// Start background tracking and push to Firestore
  void startTracking({required String driverId}) async {
    if (!await requestPermission()) return;

    final locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 50, // update every 50 meters
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {
      _updateFirestoreLocation(driverId, position);
    });
  }

  void stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
  }

  Future<void> _updateFirestoreLocation(String driverId, Position position) async {
    try {
      await _firestore.collection('users').doc(driverId).update({
        'lastLocation': {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'heading': position.heading,
          'speed': position.speed,
        },
        'locationUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Ignored for now
    }
  }

  Future<String?> getPlaceName(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final street = place.street ?? '';
        final locality = place.locality ?? '';
        final state = place.administrativeArea ?? '';
        final parts = [street, locality, state].where((p) => p.isNotEmpty).toList();
        if (parts.isNotEmpty) {
          return parts.join(', ');
        }
      }
    } catch (e) {
      // Ignored
    }
    return null;
  }
}
