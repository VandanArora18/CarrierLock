import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Fleet model — a group of admins and drivers.
class FleetModel extends Equatable {
  final String fleetId;
  final String name;
  final String? description;
  final List<String> adminIds;
  final List<String> driverIds;
  final String createdBy;
  final DateTime? createdAt;
  final String status; // 'active' | 'pending'

  const FleetModel({
    required this.fleetId,
    required this.name,
    this.description,
    this.adminIds = const [],
    this.driverIds = const [],
    required this.createdBy,
    this.createdAt,
    this.status = 'active',
  });

  int get totalDrivers => driverIds.length;
  int get totalAdmins => adminIds.length;
  bool get isActive => status == 'active';

  factory FleetModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FleetModel(
      fleetId: doc.id,
      name: data['name'] ?? '',
      description: data['description'],
      adminIds: List<String>.from(data['adminIds'] ?? []),
      driverIds: List<String>.from(data['driverIds'] ?? []),
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      status: data['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fleetId': fleetId,
      'name': name,
      if (description != null) 'description': description,
      'adminIds': adminIds,
      'driverIds': driverIds,
      'createdBy': createdBy,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'status': status,
    };
  }

  FleetModel copyWith({
    String? name,
    String? description,
    List<String>? adminIds,
    List<String>? driverIds,
    String? status,
  }) {
    return FleetModel(
      fleetId: fleetId,
      name: name ?? this.name,
      description: description ?? this.description,
      adminIds: adminIds ?? this.adminIds,
      driverIds: driverIds ?? this.driverIds,
      createdBy: createdBy,
      createdAt: createdAt,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [fleetId, name, status, adminIds, driverIds];
}
