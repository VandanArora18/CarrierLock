import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/gold_button.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/validators.dart';
import '../providers/auth_provider.dart';

/// Admin login screen.
class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    final hPad = sw * 0.06;

    return Scaffold(
      backgroundColor: AppColors.base,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: sh - MediaQuery.of(context).padding.top,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: sh * 0.02),
                  IconButton(
                    onPressed: () => context.go(AppRoutes.splash),
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: AppColors.textPrimary),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  SizedBox(height: sh * 0.04),
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.tealDim,
                          border: Border.all(color: AppColors.tealBorder),
                        ),
                        child: const Icon(Icons.admin_panel_settings_rounded,
                            color: AppColors.teal, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Admin Login', style: AppTextStyles.screenTitle),
                          const SizedBox(height: 2),
                          Text('Fleet management console',
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
                        Text('NAME', style: AppTextStyles.sectionLabel),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          keyboardType: TextInputType.name,
                          style: AppTextStyles.inputText,
                          decoration: const InputDecoration(
                            hintText: 'John Doe',
                            prefixIcon: Icon(Icons.person_outline_rounded, size: 18),
                          ),
                          onChanged: (_) => setState(() {}),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                        SizedBox(height: sh * 0.025),
                        Text('PHONE NUMBER', style: AppTextStyles.sectionLabel),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: AppTextStyles.inputText,
                          decoration: const InputDecoration(
                            hintText: '+1 234 567 8900',
                            prefixIcon: Icon(Icons.phone_outlined, size: 18),
                          ),
                          onChanged: (_) => setState(() {}),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: sh * 0.03),
                  if (authState.error != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.redDim,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.redBorder),
                      ),
                      child: Text(authState.error!, style: AppTextStyles.error),
                    ),
                  GoldButton(
                    label: 'Continue with Google',
                    icon: Icons.g_mobiledata_rounded,
                    outlined: false,
                    isLoading: authState.isLoading,
                    onPressed: (_nameController.text.trim().isNotEmpty && _phoneController.text.trim().isNotEmpty)
                        ? () async {
                            final success = await ref.read(authProvider.notifier).signInWithGoogle(role: 'admin');
                            if (success && mounted) {
                              context.go(AppRoutes.adminFleetSelection);
                            }
                          }
                        : null,
                  ),
                  SizedBox(height: sh * 0.03),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
