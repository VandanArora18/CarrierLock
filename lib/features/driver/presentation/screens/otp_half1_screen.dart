import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/otp_box.dart';
import '../../../../core/widgets/gold_button.dart';
import '../../../../core/widgets/carrierlock_card.dart';
import '../../../../core/router/app_router.dart';
import '../providers/otp_provider.dart';
import 'dart:async';
import '../../../../core/services/otp_service.dart';

class OtpHalf1Screen extends ConsumerStatefulWidget {
  final String requestId;
  final String half1; // legacy name, now part1 (3 digits)
  final String expiresAt;
  final String driverId;

  const OtpHalf1Screen({
    super.key,
    required this.requestId,
    required this.half1,
    required this.expiresAt,
    required this.driverId,
  });

  @override
  ConsumerState<OtpHalf1Screen> createState() => _OtpHalf1ScreenState();
}

class _OtpHalf1ScreenState extends ConsumerState<OtpHalf1Screen> with WidgetsBindingObserver {
  late Timer _countdownTimer;
  late Timer _expiryChecker;
  int _secondsRemaining = 300;
  bool _isExpired = false;
  bool _hasPingedReceivedPart1 = false;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _secondsRemaining--;
        if (_secondsRemaining <= 0) {
          timer.cancel();
          _handleExpiry();
        }
      });
    });

    _expiryChecker = Timer.periodic(const Duration(seconds: 30), (_) {
      OTPService().expireStaleOTPs(widget.driverId);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      OTPService().expireStaleOTPs(widget.driverId);
    }
  }

  void _handleExpiry() {
    FirebaseFirestore.instance.collection('unlock_requests').doc(widget.requestId).update({'status': 'expired'});
    if (mounted) setState(() => _isExpired = true);
  }

  String get _formattedTime {
    final m = _secondsRemaining ~/ 60;
    final s = _secondsRemaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    _expiryChecker.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _pingReceivedPart1() async {
    if (_hasPingedReceivedPart1) return;
    _hasPingedReceivedPart1 = true;
    try {
      await FirebaseFirestore.instance.collection('unlock_requests').doc(widget.requestId).update({
        'driverReceivedPart1': true,
      });
    } catch (e) {
      print('Failed to ping driverReceivedPart1: $e');
      _hasPingedReceivedPart1 = false;
    }
  }

  void _verifyOtp(String fullOTP, String deviceId, String fleetId) async {
    setState(() => _isVerifying = true);
    await ref.read(otpProvider.notifier).submitOTP(
      enteredOTP: fullOTP,
      reqId: widget.requestId,
      deviceId: deviceId,
      driverId: widget.driverId,
      fleetId: fleetId,
    );
    final state = ref.read(otpProvider);
    if (mounted) {
      setState(() => _isVerifying = false);
      if (state == OTPFlowState.success) {
        context.pushReplacement(AppRoutes.carrierUnlocked, extra: {'deviceId': deviceId});
      } else if (state == OTPFlowState.wrongOTP) {
        context.pushReplacement(AppRoutes.otpWrongAttempt, extra: {
          'requestId': widget.requestId,
          'attempts': 1,
          'half1': widget.half1,
          'half2': '',
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ref.read(otpProvider.notifier).lastError ?? 'Failed to verify OTP'), backgroundColor: AppColors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    final hPad = sw * 0.06;

    return Scaffold(
      backgroundColor: AppColors.base,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('unlock_requests').doc(widget.requestId).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.gold));
            
            final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
            if (data.isEmpty) {
              return Center(child: Text('Request not found', style: AppTextStyles.body));
            }

            if (data['status'] == 'expired') {
              if (!_isExpired) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _isExpired = true);
                });
              }
            }

            final part1 = (data['part1'] as String?)?.isNotEmpty == true ? data['part1'] as String : (widget.half1.isNotEmpty ? widget.half1 : '123'); // 3 digits
            final adminApprovedPart1 = data['adminApprovedPart1'] == true;
            final approvedPart1 = (data['approvedPart1'] as String?)?.trim().isNotEmpty == true ? data['approvedPart1'] as String : '456';
            final part3 = (data['part3'] as String?)?.trim().isNotEmpty == true ? data['part3'] as String : '78';
            
            final adminApprovedPart2 = data['adminApprovedPart2'] == true;
            final approvedPart2 = (data['approvedPart2'] as String?)?.trim().isNotEmpty == true ? data['approvedPart2'] as String : '90';

            final deviceId = data['deviceId'] as String? ?? 'Unknown';
            final fleetId = data['fleetId'] as String? ?? 'Unknown';

            if (adminApprovedPart1 && !_hasPingedReceivedPart1 && !_isExpired) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _pingReceivedPart1();
              });
            }

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: sh * 0.02),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
                      Text('OTP Progress', style: AppTextStyles.screenTitle),
                    ],
                  ),
                  SizedBox(height: sh * 0.02),

                  // Info card
                  CarrierLockCard(
                    type: CardType.standard,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.surface2,
                              border: Border.all(color: AppColors.borderFaint),
                            ),
                            child: const Icon(Icons.info_outline_rounded, color: AppColors.textSecondary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _isExpired
                                  ? 'This request has expired. Please request a new OTP.'
                                  : adminApprovedPart2 
                                      ? 'OTP Complete! Enter all 10 digits on the physical carrier lock.'
                                      : adminApprovedPart1
                                          ? 'Waiting for Admin to approve the final 2 digits.'
                                          : 'Waiting for Admin approval to reveal the next parts.',
                              style: AppTextStyles.body.copyWith(
                                color: _isExpired ? AppColors.red : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: sh * 0.02),

                  // Timer display
                  Center(
                    child: Text(
                      _formattedTime,
                      style: AppTextStyles.heroTitle.copyWith(
                        color: _secondsRemaining < 60 ? AppColors.red : AppColors.gold,
                        fontSize: 24,
                      ),
                    ),
                  ),

                  SizedBox(height: sh * 0.02),

                  // OTP Digits Display
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Part 1 (Always visible)
                          Text('DRIVER PART 1 (3 Digits)', style: AppTextStyles.sectionLabel),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(3, (i) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: OtpBox(digit: part1.length > i ? part1[i] : ' ', state: OtpBoxState.driverFilled),
                            )),
                          ),
                          SizedBox(height: sh * 0.03),

                          // Admin Part 1 (Visible if approved)
                          if (adminApprovedPart1) ...[
                            Text('ADMIN PART 1 (3 Digits)', style: AppTextStyles.sectionLabel.copyWith(color: AppColors.teal)),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(3, (i) => Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: OtpBox(digit: approvedPart1.length > i ? approvedPart1[i] : ' ', state: OtpBoxState.adminFilled),
                              )),
                            ).animate().fadeIn(duration: 300.ms),
                            SizedBox(height: sh * 0.03),
                            
                            // Driver Part 2 (Visible immediately after Admin Part 1)
                            Text('DRIVER PART 2 (2 Digits)', style: AppTextStyles.sectionLabel),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(2, (i) => Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: OtpBox(digit: part3.length > i ? part3[i] : ' ', state: OtpBoxState.driverFilled),
                              )),
                            ).animate().fadeIn(duration: 400.ms),
                            SizedBox(height: sh * 0.03),
                          ],

                          // Admin Part 2 (Visible if approved)
                          if (adminApprovedPart2) ...[
                            Text('ADMIN PART 2 (2 Digits)', style: AppTextStyles.sectionLabel.copyWith(color: AppColors.teal)),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(2, (i) => Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: OtpBox(digit: approvedPart2.length > i ? approvedPart2[i] : ' ', state: OtpBoxState.adminFilled),
                              )),
                            ).animate().fadeIn(duration: 500.ms),
                            SizedBox(height: sh * 0.04),

                            GoldButton(
                              label: 'Verify & Unlock',
                              icon: Icons.check_circle_outline,
                              isLoading: _isVerifying,
                              onPressed: () {
                                final full = '$part1$approvedPart1$part3$approvedPart2';
                                _verifyOtp(full, deviceId, fleetId);
                              },
                            ).animate().fadeIn(delay: 600.ms),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        ),
      ),
    );
  }
}
