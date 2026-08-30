import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/gold_button.dart';
import '../../../../core/router/app_router.dart';
import '../../domain/user_model.dart';

/// OTP verification screen — 6-digit pin entry
class DriverPhoneOtpScreen extends ConsumerStatefulWidget {
  final String verificationId;
  final String phone;
  final String name;
  final String fleetId;

  const DriverPhoneOtpScreen({
    super.key,
    required this.verificationId,
    required this.phone,
    required this.name,
    required this.fleetId,
  });

  @override
  ConsumerState<DriverPhoneOtpScreen> createState() =>
      _DriverPhoneOtpScreenState();
}

class _DriverPhoneOtpScreenState extends ConsumerState<DriverPhoneOtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  Future<void> _verifyOtp() async {
    final code = _otpCode;
    if (code.length < 6) {
      setState(() => _errorMessage = 'Enter the complete 6-digit OTP');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Verify with Firebase Phone Auth
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: code,
      );
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final firebaseUser = userCredential.user!;

      // Generate a user record if they don't exist
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (!doc.exists) {
        // Create new driver in approved state
        final newUser = UserModel(
          uid: firebaseUser.uid,
          name: widget.name,
          email: firebaseUser.email ?? '',
          phone: widget.phone,
          role: 'driver',
          fleetId: widget.fleetId,
          isOnline: true,
        );
        await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .set({
          ...newUser.toFirestore(),
          'approvalStatus': 'approved',
        });

        // Add driver to fleet
        await FirebaseFirestore.instance
            .collection('fleets')
            .doc(widget.fleetId)
            .update({
          'driverIds': FieldValue.arrayUnion([firebaseUser.uid]),
        });
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .update({
          'isOnline': true,
          'lastLoginAt': FieldValue.serverTimestamp(),
          'fleetId': widget.fleetId,
          'approvalStatus': 'approved',
        });
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      // Go directly to driver dashboard (homepage)
      context.go(AppRoutes.driverHome);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.code == 'invalid-verification-code'
            ? 'Incorrect OTP. Please try again.'
            : e.message ?? 'Verification failed';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString().replaceAll('Exception: ', '')}';
        _isLoading = false;
      });
    }
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 46,
      height: 56,
      child: TextFormField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.gold,
        ),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.borderMid, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.gold, width: 2),
          ),
          filled: true,
          fillColor: AppColors.surface1,
        ),
        onChanged: (val) {
          if (val.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          }
          if (val.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    final hPad = sw * 0.06;
    final maskedPhone = widget.phone.length > 4
        ? '******${widget.phone.substring(widget.phone.length - 4)}'
        : widget.phone;

    return Scaffold(
      backgroundColor: AppColors.base,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: sh * 0.02),
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_rounded,
                    color: AppColors.textPrimary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              SizedBox(height: sh * 0.05),
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.goldDim,
                    border: Border.all(color: AppColors.goldBorder, width: 2),
                  ),
                  child: const Icon(Icons.sms_outlined,
                      color: AppColors.gold, size: 30),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text('Enter OTP',
                    style:
                        AppTextStyles.screenTitle.copyWith(fontSize: 26)),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'We sent a 6-digit code to\n$maskedPhone',
                  style: AppTextStyles.label,
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: sh * 0.06),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) => _buildOtpBox(i)),
              ),
              SizedBox(height: sh * 0.035),
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.redDim,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.redBorder),
                  ),
                  child: Text(_errorMessage!, style: AppTextStyles.error),
                ),
              GoldButton(
                label: 'Verify & Login',
                icon: Icons.verified_rounded,
                isLoading: _isLoading,
                onPressed: _otpCode.length == 6 ? _verifyOtp : null,
              ),
              SizedBox(height: sh * 0.03),
              Center(
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: Text("Didn't receive code? Go back",
                      style: AppTextStyles.link.copyWith(fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
