import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/gold_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/location_provider.dart';
import '../providers/otp_provider.dart';

class DriverUnlockOtpScreen extends ConsumerStatefulWidget {
  const DriverUnlockOtpScreen({super.key});

  @override
  ConsumerState<DriverUnlockOtpScreen> createState() =>
      _DriverUnlockOtpScreenState();
}

class _DriverUnlockOtpScreenState extends ConsumerState<DriverUnlockOtpScreen> {
  bool _isLoading = false;
  Timer? _countdownTimer;
  int _secondsLeft = 300; // 5 minutes
  
  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleUnlock(String reqId, String fullOTP, String deviceId) async {
    setState(() => _isLoading = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        // Send to OTP provider
        await ref.read(otpProvider.notifier).submitOTP(
          enteredOTP: fullOTP,
          reqId: reqId,
          deviceId: deviceId,
          driverId: user.uid,
          fleetId: user.fleetId ?? '',
        );

        final state = ref.read(otpProvider);
        if (state == OTPFlowState.success) {
          if (mounted) {
            context.pop(); // Go back to dashboard on success
          }
        } else if (state == OTPFlowState.error || state == OTPFlowState.wrongOTP) {
          final errStr = ref.read(otpProvider.notifier).lastError ?? 'Unknown';
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: $errStr'),
                backgroundColor: AppColors.red,
                duration: const Duration(seconds: 15),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred.'), backgroundColor: AppColors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildOTPBox(String digit, {bool isTeal = false, bool isFilled = false}) {
    return Container(
      width: 45,
      height: 55,
      decoration: BoxDecoration(
        color: isTeal ? AppColors.tealDim : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isTeal ? AppColors.tealBorder : Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Center(
        child: Text(
          digit,
          style: AppTextStyles.otpDigit.copyWith(
            fontSize: 24,
            color: isFilled ? (isTeal ? AppColors.teal : AppColors.gold) : Colors.transparent,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    
    final notifier = ref.read(otpProvider.notifier);
    final reqId = notifier.currentReqId;
    final half1 = notifier.currentHalf1;

    if (reqId == null || half1 == null || half1.length != 3) {
      return Scaffold(
        backgroundColor: AppColors.base,
        appBar: AppBar(title: const Text('Unlock Carrier')),
        body: Center(
          child: Text('Invalid request state. Please try again.', style: AppTextStyles.body),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.base,
      appBar: AppBar(
        title: const Text('Unlock Carrier'),
      ),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('unlock_requests').doc(reqId).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: CircularProgressIndicator(color: AppColors.gold));
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;
            final status = data['status'] as String;
            final half2ForDriver = data['half2ForDriver'] as String?;

            final isApproved = status == 'half2_sent' && half2ForDriver != null && half2ForDriver.length == 3;
            final isDenied = status == 'denied';

            final minutes = _secondsLeft ~/ 60;
            final seconds = _secondsLeft % 60;
            final timeStr = '${minutes.toString().padLeft(2, "0")}:${seconds.toString().padLeft(2, "0")}';

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: sw * 0.06),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: sh * 0.05),
                  Icon(
                    isApproved ? Icons.check_circle_rounded : (isDenied ? Icons.cancel_rounded : Icons.lock_clock_rounded),
                    size: 64, 
                    color: isApproved ? AppColors.green : (isDenied ? AppColors.red : AppColors.gold),
                  ),
                  SizedBox(height: sh * 0.03),
                  Text(
                    isApproved ? 'Admin Approved' : (isDenied ? 'Request Denied' : 'Waiting for Admin'),
                    style: AppTextStyles.screenTitle.copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isApproved 
                      ? 'The admin has sent the unlock code.'
                      : (isDenied ? 'The admin has denied this request.' : 'Please wait for your fleet admin to approve your request.'),
                    style: AppTextStyles.body.copyWith(color: AppColors.textDimmer),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: sh * 0.06),
                  
                  // OTP Boxes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Half 1 - Gold (Driver's half)
                      _buildOTPBox(half1[0], isFilled: true),
                      _buildOTPBox(half1[1], isFilled: true),
                      _buildOTPBox(half1[2], isFilled: true),
                      
                      const SizedBox(width: 10), // Small gap between halves
                      
                      // Half 2 - Teal (Admin's half)
                      _buildOTPBox(isApproved ? half2ForDriver[0] : '', isTeal: true, isFilled: isApproved),
                      _buildOTPBox(isApproved ? half2ForDriver[1] : '', isTeal: true, isFilled: isApproved),
                      _buildOTPBox(isApproved ? half2ForDriver[2] : '', isTeal: true, isFilled: isApproved),
                    ],
                  ),
                  
                  SizedBox(height: sh * 0.04),
                  
                  if (!isApproved && !isDenied)
                    Column(
                      children: [
                        const CircularProgressIndicator(color: AppColors.gold),
                        const SizedBox(height: 16),
                        Text(
                          'Expires in: $timeStr',
                          style: AppTextStyles.caption.copyWith(color: AppColors.gold),
                        ),
                      ],
                    ),

                  const Spacer(),
                  if (isDenied)
                    GoldButton(
                      label: 'Go Back',
                      icon: Icons.arrow_back_rounded,
                      onPressed: () => context.pop(),
                    )
                  else
                    GoldButton(
                      label: 'Unlock Carrier',
                      icon: Icons.vpn_key_rounded,
                      isLoading: _isLoading,
                      // ONLY ACTIVE IF APPROVED
                      onPressed: isApproved ? () {
                        _handleUnlock(reqId, half1 + half2ForDriver, data['deviceId'] ?? '');
                      } : null, // Disabled until approved
                    ),
                  SizedBox(height: sh * 0.05),
                ],
              ),
            );
          }
        ),
      ),
    );
  }
}
