import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/alert_model.dart';

/// Alerts repository — stream and manage alerts.
class AlertsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream alerts for a driver.
  Stream<List<AlertModel>> watchDriverAlerts(String driverId) {
    return _firestore
        .collection('alerts')
        .where('driverId', isEqualTo: driverId)
        .where('targetRole', whereIn: ['driver', 'both'])
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AlertModel.fromFirestore(doc)).toList());
  }

  /// Stream alerts for an admin's fleet.
  Stream<List<AlertModel>> watchAdminAlerts(String fleetId) {
    return _firestore
        .collection('alerts')
        .where('fleetId', isEqualTo: fleetId)
        .where('targetRole', whereIn: ['admin', 'both'])
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AlertModel.fromFirestore(doc)).toList());
  }

  /// Mark an alert as read.
  Future<void> markAsRead(String alertId) async {
    await _firestore.collection('alerts').doc(alertId).update({
      'read': true,
    });
  }

  /// Mark all alerts as read for a user.
  Future<void> markAllAsRead(String userId, String role) async {
    final field = role == 'driver' ? 'driverId' : 'adminId';
    final query = await _firestore
        .collection('alerts')
        .where(field, isEqualTo: userId)
        .where('read', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in query.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  /// Get unread alert count.
  Stream<int> watchUnreadCount(String userId, String role) {
    final field = role == 'driver' ? 'driverId' : 'fleetId';
    final targetRoles =
        role == 'driver' ? ['driver', 'both'] : ['admin', 'both'];

    return _firestore
        .collection('alerts')
        .where(field, isEqualTo: userId)
        .where('targetRole', whereIn: targetRoles)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}

/// Provider for AlertsRepository.
final alertsRepositoryProvider = Provider<AlertsRepository>((ref) {
  return AlertsRepository();
});
