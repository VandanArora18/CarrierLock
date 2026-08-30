import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/fleet_model.dart';
import '../../auth/domain/user_model.dart';

/// Fleet CRUD repository.
class FleetRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new fleet.
  Future<FleetModel> createFleet({
    required String name,
    String? description,
    required String adminUid,
  }) async {
    // Generate fleet ID: FLT-XXXX
    final fleetNum = DateTime.now().millisecondsSinceEpoch % 10000;
    final fleetId = 'FLT-${fleetNum.toString().padLeft(4, '0')}';

    final fleet = FleetModel(
      fleetId: fleetId,
      name: name,
      description: description,
      adminIds: [adminUid],
      driverIds: [],
      createdBy: adminUid,
      status: 'active',
    );

    await _firestore.collection('fleets').doc(fleetId).set(fleet.toFirestore());

    // Update admin's fleetId
    await _firestore.collection('users').doc(adminUid).update({
      'fleetId': fleetId,
    });

    return fleet;
  }

  /// Get a fleet by ID.
  Future<FleetModel?> getFleet(String fleetId) async {
    final doc = await _firestore.collection('fleets').doc(fleetId).get();
    if (!doc.exists) return null;
    return FleetModel.fromFirestore(doc);
  }

  /// Stream a fleet.
  Stream<FleetModel> watchFleet(String fleetId) {
    return _firestore
        .collection('fleets')
        .doc(fleetId)
        .snapshots()
        .map((doc) => FleetModel.fromFirestore(doc));
  }

  /// Get all fleets for an admin.
  Future<List<FleetModel>> getAdminFleets(String adminUid) async {
    final query = await _firestore
        .collection('fleets')
        .where('adminIds', arrayContains: adminUid)
        .get();

    return query.docs.map((doc) => FleetModel.fromFirestore(doc)).toList();
  }

  /// Stream all fleets for an admin.
  Stream<List<FleetModel>> watchAdminFleets(String adminUid) {
    return _firestore
        .collection('fleets')
        .where('adminIds', arrayContains: adminUid)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => FleetModel.fromFirestore(doc)).toList());
  }

  /// Get all drivers in a fleet.
  Future<List<UserModel>> getFleetDrivers(String fleetId) async {
    final query = await _firestore
        .collection('users')
        .where('fleetId', isEqualTo: fleetId)
        .where('role', isEqualTo: 'driver')
        .get();

    return query.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
  }

  /// Stream all drivers in a fleet.
  Stream<List<UserModel>> watchFleetDrivers(String fleetId) {
    return _firestore
        .collection('users')
        .where('fleetId', isEqualTo: fleetId)
        .where('role', isEqualTo: 'driver')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList());
  }

  /// Add a driver to a fleet.
  Future<void> addDriverToFleet(String fleetId, String driverUid) async {
    await _firestore.collection('fleets').doc(fleetId).update({
      'driverIds': FieldValue.arrayUnion([driverUid]),
    });
    await _firestore.collection('users').doc(driverUid).update({
      'fleetId': fleetId,
    });
  }

  /// Remove a driver from a fleet.
  Future<void> removeDriverFromFleet(String fleetId, String driverUid) async {
    await _firestore.collection('fleets').doc(fleetId).update({
      'driverIds': FieldValue.arrayRemove([driverUid]),
    });
    await _firestore.collection('users').doc(driverUid).update({
      'fleetId': FieldValue.delete(),
    });
  }
}

/// Provider for FleetRepository.
final fleetRepositoryProvider = Provider<FleetRepository>((ref) {
  return FleetRepository();
});
