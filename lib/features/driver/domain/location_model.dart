import 'package:equatable/equatable.dart';

/// GPS location data point.
class LocationModel extends Equatable {
  final double lat;
  final double lng;
  final String? placeName;
  final DateTime? updatedAt;
  final double? speed;
  final double? heading;
  final double? accuracy;

  const LocationModel({
    required this.lat,
    required this.lng,
    this.placeName,
    this.updatedAt,
    this.speed,
    this.heading,
    this.accuracy,
  });

  factory LocationModel.fromMap(Map<String, dynamic> data) {
    return LocationModel(
      lat: (data['lat'] ?? 0).toDouble(),
      lng: (data['lng'] ?? 0).toDouble(),
      placeName: data['placeName'],
      updatedAt: data['updatedAt'] != null
          ? DateTime.tryParse(data['updatedAt'].toString())
          : null,
      speed: data['speed']?.toDouble(),
      heading: data['heading']?.toDouble(),
      accuracy: data['accuracy']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lat': lat,
      'lng': lng,
      if (placeName != null) 'placeName': placeName,
      'updatedAt':
          updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      if (speed != null) 'speed': speed,
      if (heading != null) 'heading': heading,
      if (accuracy != null) 'accuracy': accuracy,
    };
  }

  @override
  List<Object?> get props => [lat, lng, placeName];
}
