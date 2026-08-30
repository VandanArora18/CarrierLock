import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/notification_service.dart';

/// Confirmation screen for admin hard-locking a driver's device.
class AdminHardLockConfirmScreen extends StatefulWidget {
  final String driverId;
  final String driverName;
  final String fleetId;

  const AdminHardLockConfirmScreen({
    super.key,
    required this.driverId,
    required this.driverName,
    required this.fleetId,
  });

  @override
  State<AdminHardLockConfirmScreen> createState() => _AdminHardLockConfirmScreenState();
}

class _AdminHardLockConfirmScreenState extends State<AdminHardLockConfirmScreen> {
  bool _isLoading = false;

  Future<void> _confirmHardLock() async {
    setState(() => _isLoading = true);

    try {
      // Try to get driver's last known background location from Firestore
      final driverDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.driverId)
          .get();
      final driverData = driverDoc.data() as Map<String, dynamic>?;
      final lastLocation = driverData?['lastLocation'] as Map<String, dynamic>?;

      // Use driver's stored location for lock location
      final lockLat = lastLocation?['latitude']?.toDouble();
      final lockLng = lastLocation?['longitude']?.toDouble();
      String? lockPlaceName;
      if (lockLat != null && lockLng != null) {
        lockPlaceName = await LocationService().getPlaceName(lockLat, lockLng);
      }

      // Find the device belonging to this driver
      final deviceQuery = await FirebaseFirestore.instance
          .collection('devices')
          .where('driverId', isEqualTo: widget.driverId)
          .limit(1)
          .get();

      // Update user carrierStatus to locked and store lock location
      final updateData = <String, dynamic>{
        'carrierStatus': 'locked',
        if (lockLat != null) 'lockLat': lockLat,
        if (lockLng != null) 'lockLng': lockLng,
        if (lockPlaceName != null) 'lockPlaceName': lockPlaceName,
      };
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.driverId)
            .update(updateData);
      } catch (e) {
        print('Error updating user: $e');
        throw Exception('User Update Failed: $e');
      }

      // Close active carrier_history record
      try {
        final historyQuery = await FirebaseFirestore.instance
            .collection('carrier_history')
            .where('driverId', isEqualTo: widget.driverId)
            .where('fleetId', isEqualTo: widget.fleetId)
            .where('status', isEqualTo: 'active')
            .limit(1)
            .get();
        if (historyQuery.docs.isNotEmpty) {
          await historyQuery.docs.first.reference.update({
            'status': 'completed',
            'lockedAt': FieldValue.serverTimestamp(),
            'lockedBy': 'admin',
            'lockLat': lockLat,
            'lockLng': lockLng,
            if (lockPlaceName != null) 'lockPlaceName': lockPlaceName,
          });
        }
      } catch (e) {
        print('Ignored carrier_history update error: $e');
      }

      // Hard-lock the device
      try {
        if (deviceQuery.docs.isNotEmpty) {
          await deviceQuery.docs.first.reference.update({
            'status': 'hard_locked',
            'isHardLocked': true,
            'lockedAt': FieldValue.serverTimestamp(),
            'driverName': widget.driverName,
            if (lockLat != null) 'lockLat': lockLat,
            if (lockLng != null) 'lockLng': lockLng,
          });
        } else {
          await FirebaseFirestore.instance.collection('devices').add({
            'deviceId': 'Unknown Device',
            'status': 'hard_locked',
            'isHardLocked': true,
            'driverId': widget.driverId,
            'driverName': widget.driverName,
            'fleetId': widget.fleetId,
            'lockedAt': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
        
        // Also update the driver's profile in users collection
        await FirebaseFirestore.instance.collection('users').doc(widget.driverId).update({
          'carrierStatus': 'hard_locked',
          'isHardLocked': true,
        });

      } catch (e) {
        print('Error updating device: $e');
        throw Exception('Device Update Failed: $e');
      }

      // Add alert for the driver
      try {
        await FirebaseFirestore.instance.collection('alerts').add({
          'driverId': widget.driverId,
          'fleetId': widget.fleetId,
          'title': 'Hard Locked by Admin',
          'body': 'Your device has been hard-locked by the admin.',
          'severity': 'critical',
          'targetRole': 'driver',
          'createdAt': FieldValue.serverTimestamp(),
          'read': false,
          'cleared': false,
        });
      } catch (e) {
        print('Error adding alert: $e');
        throw Exception('Alert Add Failed: $e');
      }

      // Send push notification to driver
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(widget.driverId).get();
        final token = doc.data()?['fcmToken'];
        if (token != null) {
          await NotificationService.sendPushNotification(
            targetToken: token as String,
            title: '🚨 Hard Locked',
            body: 'Your device has been hard-locked by your fleet admin.',
          );
        }
      } catch (e) {
        print('Error sending push: $e');
      }

      if (mounted) {
        // Pop both this screen and the driver detail screen
        context.pop();
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.driverName} has been hard locked'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.base,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Warning icon
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.redDim,
                  border: Border.all(color: AppColors.redBorder, width: 2),
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.red,
                  size: 44,
                ),
              ),
              const SizedBox(height: 28),

              Text(
                'Hard Lock Device?',
                style: AppTextStyles.screenTitle.copyWith(
                  fontSize: 26,
                  color: AppColors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.redDim,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.redBorder),
                ),
                child: Text(
                  'Are you sure you want to hard lock\n${widget.driverName}\'s device?\n\nThe driver will be immediately locked out and unable to use the carrier.',
                  style: AppTextStyles.body.copyWith(height: 1.6),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 40),

              // Confirm button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _confirmHardLock,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Confirm Hard Lock',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 14),

              // Deny button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : () => context.pop(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.borderFaint),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Deny',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
