import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/otp_service.dart';
import 'dart:async';

enum OTPFlowState {
  idle, requesting, waitingForAdmin, adminApproved,
  submitting, success, wrongOTP, warning, hardLocked, expired, error,
}

class OTPNotifier extends StateNotifier<OTPFlowState> {
  OTPNotifier() : super(OTPFlowState.idle);

  final _otpService = OTPService();
  String? currentReqId;
  String? currentHalf1;
  String? lastError;

  Future<void> requestOTP({
    required String driverId,
    required String deviceId,
    required String fleetId,
    required String driverName,
    required String phone,
    required Map<String, dynamic> driverLocation,
  }) async {
    state = OTPFlowState.requesting;
    lastError = null;
    try {
      final res = await _otpService.requestOTP(
        driverId: driverId, deviceId: deviceId,
        fleetId: fleetId, driverName: driverName, phone: phone, driverLocation: driverLocation,
      );
      currentReqId = res.reqId;
      currentHalf1 = res.half1;
      state = OTPFlowState.waitingForAdmin;
    } on OTPException catch (e) {
      lastError = e.message;
      state = e.message == 'hard_locked' ? OTPFlowState.hardLocked : OTPFlowState.error;
    } catch (e) {
      lastError = e.toString();
      state = OTPFlowState.error;
    }
  }

  Future<void> submitOTP({
    required String enteredOTP, required String reqId,
    required String deviceId, required String driverId, required String fleetId,
  }) async {
    state = OTPFlowState.submitting;
    try {
      final result = await _otpService.verifyOTP(
        reqId: reqId, enteredOTP: enteredOTP,
        deviceId: deviceId, driverId: driverId, fleetId: fleetId,
      );
      switch (result.status) {
        case OTPVerifyStatus.success:      state = OTPFlowState.success; break;
        case OTPVerifyStatus.wrongOTP:     state = OTPFlowState.wrongOTP; break;
        case OTPVerifyStatus.wrongOTPWarning: state = OTPFlowState.warning; break;
        case OTPVerifyStatus.hardLocked:   state = OTPFlowState.hardLocked; break;
        case OTPVerifyStatus.expired:
          lastError = 'This OTP has expired. Please request a new one.';
          state = OTPFlowState.expired;
          break;
        case OTPVerifyStatus.invalid:
          lastError = 'This request is no longer valid (it may have already been used).';
          state = OTPFlowState.error;
          break;
      }
    } catch (e) {
      lastError = e.toString();
      state = OTPFlowState.error;
    }
  }

  Future<void> approveRequestPart1({
    required String reqId, required String adminPart1, required String adminId,
  }) async {
    await _otpService.approveRequestPart1(
      reqId: reqId, adminPart1: adminPart1, adminId: adminId,
    );
  }

  Future<void> approveRequestPart2({
    required String reqId, required String adminPart2, required String adminId,
    required String fleetId, required String driverId, required String deviceId,
  }) async {
    await _otpService.approveRequestPart2(
      reqId: reqId, adminPart2: adminPart2, adminId: adminId,
      fleetId: fleetId, driverId: driverId, deviceId: deviceId,
    );
  }

  Future<void> denyRequest({
    required String reqId, required String adminId,
    required String fleetId, required String driverId, required String deviceId,
  }) async {
    await _otpService.denyRequest(
      reqId: reqId, adminId: adminId,
      fleetId: fleetId, driverId: driverId, deviceId: deviceId,
    );
  }

  Future<void> resetDevice({
    required String deviceId, required String fleetId,
    required String driverId, required String adminId,
  }) async {
    await _otpService.resetDevice(
      deviceId: deviceId, fleetId: fleetId, driverId: driverId, adminId: adminId,
    );
    state = OTPFlowState.idle;
  }
}

final otpProvider = StateNotifierProvider<OTPNotifier, OTPFlowState>((ref) {
  return OTPNotifier();
});
