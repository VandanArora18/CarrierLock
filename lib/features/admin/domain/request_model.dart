import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Admin-facing unlock request model.
class RequestModel extends Equatable {
  final String requestId;
  final String driverId;
  final String? driverName;
  final String? adminId;
  final String deviceId;
  final String fleetId;
  final String status;
  final String half1;
  final String? half2;
  final bool half2Revealed;
  final int attempts;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final double? driverLat;
  final double? driverLng;
  final String? driverPlaceName;

  const RequestModel({
    required this.requestId,
    required this.driverId,
    this.driverName,
    this.adminId,
    required this.deviceId,
    required this.fleetId,
    required this.status,
    required this.half1,
    this.half2,
    this.half2Revealed = false,
    this.attempts = 0,
    this.createdAt,
    this.expiresAt,
    this.driverLat,
    this.driverLng,
    this.driverPlaceName,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';

  factory RequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final location = data['driverLocation'] as Map<String, dynamic>?;

    return RequestModel(
      requestId: doc.id,
      driverId: data['driverId'] ?? '',
      driverName: data['driverName'],
      adminId: data['adminId'],
      deviceId: data['deviceId'] ?? '',
      fleetId: data['fleetId'] ?? '',
      status: data['status'] ?? 'pending',
      half1: data['half1'] ?? '',
      half2: data['half2'],
      half2Revealed: data['half2Revealed'] ?? false,
      attempts: data['attempts'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      driverLat: location?['lat']?.toDouble(),
      driverLng: location?['lng']?.toDouble(),
      driverPlaceName: location?['placeName'],
    );
  }

  @override
  List<Object?> get props => [requestId, status, attempts];
}
