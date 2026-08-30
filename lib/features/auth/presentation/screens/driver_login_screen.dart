import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/gold_button.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/location_service.dart';
import '../providers/auth_provider.dart';
import '../../data/auth_repository.dart';

/// Unified Driver login — Name + Fleet Code + Phone number → OTP
class DriverLoginScreen extends ConsumerStatefulWidget {
  const DriverLoginScreen({super.key});

  @override
  ConsumerState<DriverLoginScreen> createState() => _DriverLoginScreenState();
}

class _DriverLoginScreenState extends ConsumerState<DriverLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _fleetCodeController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _fleetCodeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      // 0. Enforce Location Permissions before allowing login
      final locationService = LocationService();
      final hasPermission = await locationService.requestPermission();
      if (!hasPermission) {
        setState(() {
          _errorMessage = 'Location permissions and GPS must be enabled to log in as a Driver.';
          _isLoading = false;
        });
        return;
      }

      // 1. Sign in with Google First (to get permissions)
      final name = _nameController.text.trim();
      final userModel = await ref.read(authRepositoryProvider).signInWithGoogle(role: 'driver');

      // 2. Validate fleet join code
      final joinCode = _fleetCodeController.text.trim();
      final fleetQuery = await FirebaseFirestore.instance
          .collection('fleets')
          .where('joinCode', isEqualTo: joinCode)
          .limit(1)
          .get();

      if (fleetQuery.docs.isEmpty) {
        // If invalid, sign them back out
        await ref.read(authRepositoryProvider).signOut();
        setState(() {
          _errorMessage = 'This fleet id does not exist';
          _isLoading = false;
        });
        return;
      }

      final fleetId = fleetQuery.docs.first.id;

      // 3. Update user document with entered name, fleetId, and auto-approve
      await FirebaseFirestore.instance.collection('users').doc(userModel.uid).update({
        'name': name,
        'fleetId': fleetId,
        'phone': _phoneController.text.trim(),
        'approvalStatus': 'approved',
        if (userModel.role != 'admin') 'role': 'driver',
      });

      // Add driver to fleet's driverIds array
      await FirebaseFirestore.instance.collection('fleets').doc(fleetId).update({
        'driverIds': FieldValue.arrayUnion([userModel.uid]),
      });

      // Reload user profile to catch the updated name and fleetId
      await ref.read(authProvider.notifier).reloadUser();

      if (!mounted) return;
      setState(() => _isLoading = false);

      // 3. Navigate to Home
      context.go(AppRoutes.driverHome);

    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString().replaceAll('Exception: ', '')}';
        _isLoading = false;
      });
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
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: hPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: sh * 0.02),

                // Back
                IconButton(
                  onPressed: () => context.go(AppRoutes.splash),
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: AppColors.textPrimary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),

                SizedBox(height: sh * 0.04),

                // Header
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.goldDim,
                        border: Border.all(color: AppColors.goldBorder),
                      ),
                      child: const Icon(Icons.local_shipping_rounded,
                          color: AppColors.gold, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Driver Login', style: AppTextStyles.screenTitle),
                        const SizedBox(height: 2),
                        Text('Login with Google',
                            style: AppTextStyles.label),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: sh * 0.05),

                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // Name
                      Text('YOUR NAME', style: AppTextStyles.sectionLabel),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        style: AppTextStyles.inputText,
                        decoration: const InputDecoration(
                          hintText: 'Full name',
                          prefixIcon: Icon(Icons.person_outline_rounded, size: 18),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Enter your name' : null,
                      ),

                      SizedBox(height: sh * 0.025),

                      // Fleet Code
                      Text('FLEET JOIN CODE', style: AppTextStyles.sectionLabel),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _fleetCodeController,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        textAlign: TextAlign.center,
                        style: AppTextStyles.inputText.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 10,
                        ),
                        decoration: InputDecoration(
                          hintText: '• • • •',
                          hintStyle: AppTextStyles.inputText.copyWith(
                            letterSpacing: 10,
                            color: AppColors.textDimmer,
                          ),
                          counterText: '',
                          prefixIcon: const Icon(Icons.tag_rounded, size: 18),
                          helperText: 'Ask your fleet admin for this code',
                          helperStyle: AppTextStyles.caption,
                        ),
                        validator: (v) => (v == null || v.length != 4)
                            ? 'Enter the 4-digit fleet code' : null,
                      ),

                      SizedBox(height: sh * 0.025),

                      // Phone Number
                      Text('YOUR PHONE NUMBER', style: AppTextStyles.sectionLabel),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: AppTextStyles.inputText,
                        decoration: const InputDecoration(
                          hintText: 'e.g. +1 234 567 8900',
                          prefixIcon: Icon(Icons.phone_rounded, size: 18),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Enter your phone number' : null,
                      ),

                      // We removed email and password fields
                    ],
                  ),
                ),

                SizedBox(height: sh * 0.035),

                // Error
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

                // Google Login button
                GoldButton(
                  label: 'Continue with Google',
                  icon: Icons.g_mobiledata_rounded,
                  outlined: true,
                  isLoading: _isLoading,
                  onPressed: _handleGoogleLogin,
                ),

                SizedBox(height: sh * 0.03),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
