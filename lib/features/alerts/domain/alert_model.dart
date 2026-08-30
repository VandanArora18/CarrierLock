import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Alert notification model.
class AlertModel extends Equatable {
  final String alertId;
  final String type;
  final String severity; // 'info' | 'warning' | 'critical'
  final String fleetId;
  final String? driverId;
  final String? adminId;
  final String? deviceId;
  final String title;
  final String body;
  final bool read;
  final DateTime createdAt;
  final String targetRole; // 'driver' | 'admin' | 'both'

  const AlertModel({
    required this.alertId,
    required this.type,
    required this.severity,
    required this.fleetId,
    this.driverId,
    this.adminId,
    this.deviceId,
    required this.title,
    required this.body,
    this.read = false,
    required this.createdAt,
    this.targetRole = 'both',
  });

  bool get isCritical => severity == 'critical';
  bool get isWarning => severity == 'warning';
  bool get isInfo => severity == 'info';

  factory AlertModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AlertModel(
      alertId: doc.id,
      type: data['type'] ?? '',
      severity: data['severity'] ?? 'info',
      fleetId: data['fleetId'] ?? '',
      driverId: data['driverId'],
      adminId: data['adminId'],
      deviceId: data['deviceId'],
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      read: data['read'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      targetRole: data['targetRole'] ?? 'both',
    );
  }

  AlertModel copyWith({bool? read}) {
    return AlertModel(
      alertId: alertId,
      type: type,
      severity: severity,
      fleetId: fleetId,
      driverId: driverId,
      adminId: adminId,
      deviceId: deviceId,
      title: title,
      body: body,
      read: read ?? this.read,
      createdAt: createdAt,
      targetRole: targetRole,
    );
  }

  @override
  List<Object?> get props => [alertId, type, severity, read];
}
