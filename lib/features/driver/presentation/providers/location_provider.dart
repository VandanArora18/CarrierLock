import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/services/location_service.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

class LocationState {
  final Position? currentPosition;
  final bool isTracking;
  final String? error;

  LocationState({this.currentPosition, this.isTracking = false, this.error});

  LocationState copyWith({Position? currentPosition, bool? isTracking, String? error}) {
    return LocationState(
      currentPosition: currentPosition ?? this.currentPosition,
      isTracking: isTracking ?? this.isTracking,
      error: error ?? this.error,
    );
  }
}

class LocationNotifier extends StateNotifier<LocationState> {
  LocationNotifier(this._locationService) : super(LocationState());

  final LocationService _locationService;

  Future<void> requestLocation() async {
    try {
      final position = await _locationService.getCurrentLocation();
      if (position != null) {
        state = state.copyWith(currentPosition: position, error: null);
      } else {
        state = state.copyWith(error: 'Location permission denied or service disabled');
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void startTracking(String driverId) {
    _locationService.startTracking(driverId: driverId);
    state = state.copyWith(isTracking: true);
  }

  void stopTracking() {
    _locationService.stopTracking();
    state = state.copyWith(isTracking: false);
  }
}

final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  final service = ref.watch(locationServiceProvider);
  return LocationNotifier(service);
});
