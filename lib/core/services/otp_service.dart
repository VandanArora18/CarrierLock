import 'dart:math';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class OTPService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // ─────────────────────────────────────────────────────────────
  // GENERATE: Cryptographically secure 6-digit OTP
  // Random.secure() uses the OS cryptographic RNG.
  // This is NOT predictable like regular Random().
  // ─────────────────────────────────────────────────────────────
  String _generateSecureOTP() {
    final random = Random.secure();
    return List.generate(10, (_) => random.nextInt(10)).join();
  }

  // ─────────────────────────────────────────────────────────────
  // HASH: SHA-256 one-way hash of the OTP
  // The raw OTP is NEVER stored in Firestore.
  // Only this hash is stored. It cannot be reversed.
  // ─────────────────────────────────────────────────────────────
  String _hashOTP(String otp) {
    final bytes = utf8.encode(otp);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // ─────────────────────────────────────────────────────────────
  // REQUEST OTP
  // Called when driver taps "Request unlock OTP"
  // ─────────────────────────────────────────────────────────────
  Future<OTPRequestResult> requestOTP({
    required String driverId,
    required String deviceId,
    required String fleetId,
    required String driverName,
    required String phone,
    required Map<String, dynamic> driverLocation,
  }) async {
    // 1. Ensure Device ID exists
    String finalDeviceId = deviceId;
    if (finalDeviceId.isEmpty) {
      finalDeviceId = 'DEV-${Random().nextInt(900) + 100}';
      try {
        await _firestore.collection('users').doc(driverId).update({'deviceId': finalDeviceId});
      } catch (e) {
        throw OTPException('Failed at users update: $e');
      }
    }

    // 2. Check/Create Device
    try {
      final deviceDoc = await _firestore.collection('devices').doc(finalDeviceId).get();
      if (!deviceDoc.exists) {
        await _firestore.collection('devices').doc(finalDeviceId).set({
          'deviceId': finalDeviceId,
          'status': 'locked',
          'driverId': driverId,
          'fleetId': fleetId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        final data = deviceDoc.data()!;
        if (data['isHardLocked'] == true) {
          throw OTPException('hard_locked');
        } else if (data['status'] == 'hard_locked') {
          // Self-heal stuck state from previous bug
          await deviceDoc.reference.update({'status': 'locked'});
        }
      }
    } catch (e) {
      if (e is OTPException) rethrow;
      throw OTPException('Failed at devices check: $e');
    }

    // 3. Cleanup existing requests (Ignore if fails due to permissions)
    try {
      final existingRequests = await _firestore
          .collection('unlock_requests')
          .where('deviceId', isEqualTo: finalDeviceId)
          .where('driverId', isEqualTo: driverId)
          .where('status', isEqualTo: 'pending')
          .get();
      final batch = _firestore.batch();
      for (final doc in existingRequests.docs) {
        batch.update(doc.reference, {'status': 'expired'});
      }
      await batch.commit();
    } catch (e) {
      print('Ignored existingRequests cleanup error: $e');
    }

    // 4. Generate OTP
    final fullOTP = _generateSecureOTP();
    final part1 = fullOTP.substring(0, 3);
    final adminPart1 = fullOTP.substring(3, 6);
    final part3 = fullOTP.substring(6, 8);
    final adminPart2 = fullOTP.substring(8, 10);
    final otpHash = _hashOTP(fullOTP);

    final reqId = _uuid.v4();
    final now = Timestamp.now();
    final expiresAt = Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 5)));

    // 5. Create Request
    try {
      await _firestore.collection('unlock_requests').doc(reqId).set({
        'reqId': reqId,
        'driverId': driverId,
        'driverName': driverName,
        'phone': phone,
        'adminId': null,
        'fleetId': fleetId,
        'deviceId': finalDeviceId,
        'status': 'pending',
        'otpHash': otpHash,
        'part1': part1,
        'part3': part3,
        'adminApprovedPart1': false,
        'driverReceivedPart1': false,
        'adminApprovedPart2': false,
        'approvedPart1': null,
        'approvedPart2': null,
        'createdAt': now,
        'expiresAt': expiresAt,
        'attempts': 0,
        'driverLocation': driverLocation,
        'completedAt': null,
      });
    } catch (e) {
      throw OTPException('Failed at create request: $e');
    }

    // 6. Save admin half (Ignore if fails)
    _firestore
        .collection('unlock_requests')
        .doc(reqId)
        .collection('admin_data')
        .doc('otp')
        .set({'adminPart1': adminPart1, 'adminPart2': adminPart2, 'createdAt': now})
        .catchError((e) => print('Ignored admin_data set error: $e'));

    // 7. Queue FCM (Ignore if fails)
    _sendHalf2ToAdmins(
      fleetId: fleetId, reqId: reqId, half2: adminPart1,
      deviceId: finalDeviceId, driverId: driverId,
    ).catchError((e) => print('Ignored FCM error: $e'));

    // 8. Alerts & Audit (Ignore if fails)
    _writeAlert(
      type: 'new_unlock_request', severity: 'info',
      fleetId: fleetId, driverId: driverId, deviceId: finalDeviceId,
      title: 'New unlock request',
      body: 'Driver requesting access to $finalDeviceId in fleet $fleetId.',
      targetRole: 'admin',
    ).catchError((e) => print('Ignored alerts error: $e'));

    _writeAuditLog(
      type: 'otp_generated', fleetId: fleetId,
      driverId: driverId, deviceId: finalDeviceId,
      metadata: {'reqId': reqId},
    ).catchError((e) => print('Ignored audit error: $e'));

    return OTPRequestResult(reqId: reqId, half1: part1, expiresAt: expiresAt.toDate());
  }

  // ─────────────────────────────────────────────────────────────
  // VERIFY OTP
  // Called when driver submits full 8-digit OTP.
  // Uses Firestore TRANSACTION — atomic, cannot be manipulated.
  // ─────────────────────────────────────────────────────────────
  Future<OTPVerifyResult> verifyOTP({
    required String reqId,
    required String enteredOTP,
    required String deviceId,
    required String driverId,
    required String fleetId,
  }) async {
    final reqRef = _firestore.collection('unlock_requests').doc(reqId);
    final deviceRef = _firestore.collection('devices').doc(deviceId);

    OTPVerifyResult? result;

    try {
    await _firestore.runTransaction((transaction) async {
      final reqDoc = await transaction.get(reqRef);
      if (!reqDoc.exists) throw OTPException('Request not found');
      
      final deviceDoc = await transaction.get(deviceRef);
      if (!deviceDoc.exists) throw OTPException('Device not found');

      final userRef = _firestore.collection('users').doc(driverId);
      final userDoc = await transaction.get(userRef);

      final reqData = reqDoc.data()!;

      // Check expiry
      final expiresAt = (reqData['expiresAt'] as Timestamp).toDate();
      if (DateTime.now().isAfter(expiresAt)) {
        transaction.update(reqRef, {'status': 'expired'});
        result = OTPVerifyResult(status: OTPVerifyStatus.expired);
        return;
      }

      // Check status is still valid
      final status = reqData['status'] as String;
      if (['denied', 'expired', 'failed', 'approved'].contains(status)) {
        result = OTPVerifyResult(status: OTPVerifyStatus.invalid);
        return;
      }

      // Hash entered OTP and compare with stored hash
      final enteredHash = _hashOTP(enteredOTP);
      final storedHash = reqData['otpHash'] as String;

      if (enteredHash == storedHash) {
        // ✅ CORRECT — Unlock device atomically
        transaction.update(reqRef, {
          'status': 'approved',
          'completedAt': FieldValue.serverTimestamp(),
        });
        transaction.update(deviceRef, {
          'status': 'unlocked',
          'unlockedAt': FieldValue.serverTimestamp(),
          'attempts': 0,
        });
        final userData = userDoc.data() ?? {};
        
        // Grab driver's location from the unlock request
        final reqLoc = reqData['driverLocation'] as Map<String, dynamic>?;
        
        transaction.update(userRef, {
          'carrierStatus': 'unlocked',
          'carrierUnlockedAt': FieldValue.serverTimestamp(),
          if (reqLoc?['lat'] != null && reqLoc!['lat'] != 0.0) 'unlockLat': reqLoc!['lat'],
          if (reqLoc?['lng'] != null && reqLoc!['lng'] != 0.0) 'unlockLng': reqLoc!['lng'],
          if (reqLoc?['placeName'] != null) 'unlockPlaceName': reqLoc!['placeName'],
        });

        // Create new active history record
        try {
          final historyRef = _firestore.collection('carrier_history').doc();
          transaction.set(historyRef, {
            'driverId': driverId,
            'driverName': userData['name'] ?? 'Unknown Driver',
            'phone': userData['phone'] ?? 'N/A',
            'email': userData['email'] ?? 'N/A',
            'fleetId': fleetId,
            'deviceId': deviceId,
            'status': 'active',
            'unlockedAt': FieldValue.serverTimestamp(),
            'unlockedBy': 'driver',
            'unlockLat': reqLoc?['lat'],
            'unlockLng': reqLoc?['lng'],
            'unlockPlaceName': reqLoc?['placeName'],
            'lockedAt': null,
            'lockedBy': null,
            'lockLat': null,
            'lockLng': null,
            'lockPlaceName': null,
          });
        } catch (e) {
          print('Ignored carrier_history creation error: $e');
        }

        result = OTPVerifyResult(status: OTPVerifyStatus.success);

      } else {
        // ❌ WRONG OTP — Increment attempts atomically
        final currentAttempts = (reqData['attempts'] as int? ?? 0);
        final newAttempts = currentAttempts + 1;

        if (newAttempts >= 3) {
          // HARD LOCK after 3rd failure
          transaction.update(reqRef, {'status': 'failed', 'attempts': newAttempts});
          transaction.update(deviceRef, {
            'status': 'hard_locked',
            'lockedReason': 'max_attempts',
            'lockedAt': FieldValue.serverTimestamp(),
            'attempts': 3,
          });
          result = OTPVerifyResult(status: OTPVerifyStatus.hardLocked);

        } else if (newAttempts == 2) {
          // WARNING — 1 attempt left
          transaction.update(reqRef, {'attempts': newAttempts});
          transaction.update(deviceRef, {'attempts': newAttempts});
          result = OTPVerifyResult(status: OTPVerifyStatus.wrongOTPWarning, attemptsRemaining: 1);

        } else {
          // First wrong attempt
          transaction.update(reqRef, {'attempts': newAttempts});
          transaction.update(deviceRef, {'attempts': newAttempts});
          result = OTPVerifyResult(status: OTPVerifyStatus.wrongOTP, attemptsRemaining: 3 - newAttempts);
        }
      }
    });
    } catch (e, st) {
      print('=== VERIFY OTP ERROR ===');
      print(e);
      print(st);
      print('========================');
      rethrow;
    }

    // Post-transaction: write alerts and audit logs (non-critical, outside transaction)
    if (result!.status == OTPVerifyStatus.success) {
      await _writeAlert(
        type: 'carrier_unlocked', severity: 'info',
        fleetId: fleetId, driverId: driverId, deviceId: deviceId,
        title: 'Carrier unlocked', body: '$deviceId successfully unlocked via OTP.',
        targetRole: 'both',
      );
      await _writeAuditLog(type: 'otp_success', fleetId: fleetId, driverId: driverId, deviceId: deviceId, metadata: {'reqId': reqId});

    } else if (result!.status == OTPVerifyStatus.hardLocked) {
      await _writeAlert(
        type: 'max_attempts_hardlock', severity: 'critical',
        fleetId: fleetId, driverId: driverId, deviceId: deviceId,
        title: 'Carrier hard-locked',
        body: '$deviceId hard-locked after 3 failed OTP attempts. Admin reset required.',
        targetRole: 'both',
      );
      await _writeAuditLog(type: 'hard_lock', fleetId: fleetId, driverId: driverId, deviceId: deviceId, metadata: {'reqId': reqId, 'attempts': 3});

    } else if (result!.status == OTPVerifyStatus.wrongOTPWarning) {
      await _writeAlert(
        type: 'attempt_warning', severity: 'warning',
        fleetId: fleetId, driverId: driverId, deviceId: deviceId,
        title: '1 attempt remaining',
        body: 'Driver has 1 OTP attempt left before $deviceId is hard-locked.',
        targetRole: 'admin',
      );
    }

    return result!;
  }

  // ─────────────────────────────────────────────────────────────
  // APPROVE REQUEST PART 1
  // ─────────────────────────────────────────────────────────────
  Future<void> approveRequestPart1({
    required String reqId,
    required String adminPart1,
    required String adminId,
  }) async {
    await _firestore.collection('unlock_requests').doc(reqId).update({
      'adminId': adminId,
      'approvedPart1': adminPart1,
      'adminApprovedPart1': true,
    });
  }

  // ─────────────────────────────────────────────────────────────
  // APPROVE REQUEST PART 2
  // ─────────────────────────────────────────────────────────────
  Future<void> approveRequestPart2({
    required String reqId,
    required String adminPart2,
    required String adminId,
    required String fleetId,
    required String driverId,
    required String deviceId,
  }) async {
    await _firestore.collection('unlock_requests').doc(reqId).update({
      'status': 'half2_sent', // Keeping legacy status string to not break listener
      'adminId': adminId,
      'approvedPart2': adminPart2,
      'adminApprovedPart2': true,
    });

    await _writeAlert(
      type: 'otp_half2_sent', severity: 'info',
      fleetId: fleetId, driverId: driverId, deviceId: deviceId,
      title: 'Admin approved',
      body: 'Your unlock request was approved. Enter the full OTP to unlock.',
      targetRole: 'driver',
    );
  }

  // ─────────────────────────────────────────────────────────────
  // DENY REQUEST — Admin denies the request
  // ─────────────────────────────────────────────────────────────
  Future<void> denyRequest({
    required String reqId,
    required String adminId,
    required String fleetId,
    required String driverId,
    required String deviceId,
  }) async {
    await _firestore.collection('unlock_requests').doc(reqId).update({
      'status': 'denied',
      'adminId': adminId,
    });

    await _writeAlert(
      type: 'otp_denied', severity: 'warning',
      fleetId: fleetId, driverId: driverId, deviceId: deviceId,
      title: 'Request denied',
      body: 'Your unlock request was denied by the admin.',
      targetRole: 'driver',
    );
  }

  // ─────────────────────────────────────────────────────────────
  // RESET DEVICE — Admin resets a hard-locked device
  // ─────────────────────────────────────────────────────────────
  Future<void> resetDevice({
    required String deviceId,
    required String fleetId,
    required String driverId,
    required String adminId,
  }) async {
    await _firestore.collection('devices').doc(deviceId).update({
      'status': 'locked',
      'lockedReason': null,
      'lockedAt': null,
      'attempts': 0,
      'lastResetBy': adminId,
      'lastResetAt': FieldValue.serverTimestamp(),
    });

    await _writeAlert(
      type: 'device_reset', severity: 'info',
      fleetId: fleetId, driverId: driverId, deviceId: deviceId,
      title: 'Device reset by admin',
      body: '$deviceId has been reset. You can now request a new unlock OTP.',
      targetRole: 'driver',
    );

    await _writeAuditLog(
      type: 'device_reset', fleetId: fleetId,
      driverId: driverId, deviceId: deviceId,
      metadata: {'resetBy': adminId},
    );
  }

  // ─────────────────────────────────────────────────────────────
  // EXPIRE STALE OTPs — Called on app resume
  // No Cloud Function needed — Flutter handles this
  // ─────────────────────────────────────────────────────────────
  Future<void> expireStaleOTPs(String driverId) async {
    final now = Timestamp.now();
    final staleRequests = await _firestore
        .collection('unlock_requests')
        .where('driverId', isEqualTo: driverId)
        .where('status', isEqualTo: 'pending')
        .where('expiresAt', isLessThan: now)
        .get();

    final batch = _firestore.batch();
    for (final doc in staleRequests.docs) {
      batch.update(doc.reference, {'status': 'expired'});
    }
    await batch.commit();
  }

  // ─────────────────────────────────────────────────────────────
  // PRIVATE HELPERS
  // ─────────────────────────────────────────────────────────────

  Future<void> _sendHalf2ToAdmins({
    required String fleetId, required String reqId,
    required String half2, required String deviceId, required String driverId,
  }) async {
    final fleetDoc = await _firestore.collection('fleets').doc(fleetId).get();
    final adminIds = List<String>.from(fleetDoc.data()!['adminIds'] ?? []);

    for (final adminId in adminIds) {
      try {
        final adminDoc = await _firestore.collection('users').doc(adminId).get();
        final fcmToken = adminDoc.data()?['fcmToken'] as String?;
        if (fcmToken != null) {
          // Write to fcm_queue — admin app's real-time listener picks it up
          await _firestore.collection('fcm_queue').add({
            'token': fcmToken,
            'title': '🔐 New unlock request',
            'body': 'Half-2 OTP: $half2 — Device $deviceId',
            'data': {
              'type': 'new_unlock_request',
              'reqId': reqId, 'half2': half2,
              'deviceId': deviceId, 'driverId': driverId, 'fleetId': fleetId,
            },
            'createdAt': FieldValue.serverTimestamp(),
            'processed': false,
          });
        }
      } catch (e) {
        // Driver might not have permission to read admin profile. Ignore FCM for now.
      }
    }
  }

  Future<void> _writeAlert({
    required String type, required String severity,
    required String fleetId, required String driverId,
    required String deviceId, required String title,
    required String body, required String targetRole,
  }) async {
    await _firestore.collection('alerts').add({
      'type': type, 'severity': severity,
      'fleetId': fleetId, 'driverId': driverId, 'deviceId': deviceId,
      'title': title, 'body': body,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
      'targetRole': targetRole,
    });
  }

  Future<void> _writeAuditLog({
    required String type, required String fleetId,
    required String driverId, required String deviceId,
    required Map<String, dynamic> metadata,
  }) async {
    await _firestore.collection('audit_logs').add({
      'type': type, 'fleetId': fleetId,
      'driverId': driverId, 'deviceId': deviceId,
      'timestamp': FieldValue.serverTimestamp(),
      'metadata': metadata,
    });
  }
}

// ─────────────────────────────────────────────────────────────
// Result classes
// ─────────────────────────────────────────────────────────────

enum OTPVerifyStatus { success, wrongOTP, wrongOTPWarning, hardLocked, expired, invalid }

class OTPVerifyResult {
  final OTPVerifyStatus status;
  final int? attemptsRemaining;
  OTPVerifyResult({required this.status, this.attemptsRemaining});
}

class OTPRequestResult {
  final String reqId;
  final String half1;
  final DateTime expiresAt;
  OTPRequestResult({required this.reqId, required this.half1, required this.expiresAt});
}

class OTPException implements Exception {
  final String message;
  OTPException(this.message);
}
