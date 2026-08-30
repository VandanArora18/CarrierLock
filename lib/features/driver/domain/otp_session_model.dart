import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// OTP unlock request session model.
class OtpSessionModel extends Equatable {
  final String requestId;
  final String driverId;
  final String? adminId;
  final String deviceId;
  final String fleetId;
  final String status; // pending|approved|denied|completed|failed|expired
  final String? otpHash;
  final String half1;
  final String? half2;
  final bool half2Revealed;
  final int attempts;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final DateTime? completedAt;
  final double? driverLat;
  final double? driverLng;
  final String? driverPlaceName;

  const OtpSessionModel({
    required this.requestId,
    required this.driverId,
    this.adminId,
    required this.deviceId,
    required this.fleetId,
    required this.status,
    this.otpHash,
    required this.half1,
    this.half2,
    this.half2Revealed = false,
    this.attempts = 0,
    this.createdAt,
    this.expiresAt,
    this.completedAt,
    this.driverLat,
    this.driverLng,
    this.driverPlaceName,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isDenied => status == 'denied';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isExpired {
    if (status == 'expired') return true;
    if (expiresAt != null && DateTime.now().isAfter(expiresAt!)) return true;
    return false;
  }

  int get remainingAttempts => 3 - attempts;
  bool get isHardLocked => attempts >= 3;

  factory OtpSessionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final location = data['driverLocation'] as Map<String, dynamic>?;

    return OtpSessionModel(
      requestId: doc.id,
      driverId: data['driverId'] ?? '',
      adminId: data['adminId'],
      deviceId: data['deviceId'] ?? '',
      fleetId: data['fleetId'] ?? '',
      status: data['status'] ?? 'pending',
      otpHash: data['otpHash'],
      half1: data['half1'] ?? '',
      half2: data['half2'],
      half2Revealed: data['half2Revealed'] ?? false,
      attempts: data['attempts'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      driverLat: location?['lat']?.toDouble(),
      driverLng: location?['lng']?.toDouble(),
      driverPlaceName: location?['placeName'],
    );
  }

  OtpSessionModel copyWith({
    String? status,
    String? adminId,
    String? half2,
    bool? half2Revealed,
    int? attempts,
    DateTime? completedAt,
  }) {
    return OtpSessionModel(
      requestId: requestId,
      driverId: driverId,
      adminId: adminId ?? this.adminId,
      deviceId: deviceId,
      fleetId: fleetId,
      status: status ?? this.status,
      otpHash: otpHash,
      half1: half1,
      half2: half2 ?? this.half2,
      half2Revealed: half2Revealed ?? this.half2Revealed,
      attempts: attempts ?? this.attempts,
      createdAt: createdAt,
      expiresAt: expiresAt,
      completedAt: completedAt ?? this.completedAt,
      driverLat: driverLat,
      driverLng: driverLng,
      driverPlaceName: driverPlaceName,
    );
  }

  @override
  List<Object?> get props => [requestId, status, attempts, half2Revealed];
}
