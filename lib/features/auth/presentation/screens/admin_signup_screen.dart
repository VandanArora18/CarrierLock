import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/gold_button.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/validators.dart';
import '../providers/auth_provider.dart';

/// Admin signup screen.
class AdminSignupScreen extends ConsumerStatefulWidget {
  const AdminSignupScreen({super.key});

  @override
  ConsumerState<AdminSignupScreen> createState() => _AdminSignupScreenState();
}

class _AdminSignupScreenState extends ConsumerState<AdminSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).signUp(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          role: 'admin',
          phone: _phoneController.text.trim().isNotEmpty
              ? _phoneController.text.trim()
              : null,
        );

    if (success && mounted) {
      context.go(AppRoutes.adminFleetSelection);
    }
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
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: hPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: sh * 0.02),
                IconButton(
                  onPressed: () => context.go(AppRoutes.adminLogin),
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: AppColors.textPrimary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                SizedBox(height: sh * 0.03),
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
                        Text('Create Admin Account',
                            style: AppTextStyles.screenTitle),
                        const SizedBox(height: 2),
                        Text('Set up your fleet management',
                            style: AppTextStyles.label),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: sh * 0.04),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('FULL NAME', style: AppTextStyles.sectionLabel),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        style: AppTextStyles.inputText,
                        decoration: const InputDecoration(
                          hintText: 'Enter your full name',
                          prefixIcon:
                              Icon(Icons.person_outline_rounded, size: 18),
                        ),
                        validator: Validators.name,
                      ),
                      SizedBox(height: sh * 0.02),
                      Text('EMAIL', style: AppTextStyles.sectionLabel),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: AppTextStyles.inputText,
                        decoration: const InputDecoration(
                          hintText: 'admin@company.com',
                          prefixIcon: Icon(Icons.email_outlined, size: 18),
                        ),
                        validator: Validators.email,
                      ),
                      SizedBox(height: sh * 0.02),
                      Text('PASSWORD', style: AppTextStyles.sectionLabel),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: AppTextStyles.inputText,
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          prefixIcon:
                              const Icon(Icons.lock_outline_rounded, size: 18),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 18,
                              color: AppColors.textDimmer,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: Validators.password,
                      ),
                      SizedBox(height: sh * 0.02),
                      Text('PHONE NUMBER (OPTIONAL)',
                          style: AppTextStyles.sectionLabel),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: AppTextStyles.inputText,
                        decoration: const InputDecoration(
                          hintText: '9876543210',
                          prefixIcon: Icon(Icons.phone_outlined, size: 18),
                        ),
                        validator: Validators.phone,
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
                  label: 'Create Admin Account',
                  icon: Icons.check_rounded,
                  isLoading: authState.isLoading,
                  onPressed: _handleSignup,
                ),
                SizedBox(height: sh * 0.025),
                Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.borderFaint)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or', style: AppTextStyles.caption),
                    ),
                    Expanded(child: Divider(color: AppColors.borderFaint)),
                  ],
                ),
                SizedBox(height: sh * 0.025),
                GoldButton(
                  label: 'Continue with Google',
                  icon: Icons.g_mobiledata_rounded,
                  outlined: true,
                  onPressed: () async {
                    final success = await ref.read(authProvider.notifier).signInWithGoogle(role: 'admin');
                    if (success && mounted) {
                      context.go(AppRoutes.adminFleetSelection);
                    }
                  },
                ),
                SizedBox(height: sh * 0.03),
                Center(
                  child: GestureDetector(
                    onTap: () => context.go(AppRoutes.adminLogin),
                    child: RichText(
                      text: TextSpan(
                        text: 'Already have an account? ',
                        style: AppTextStyles.label.copyWith(fontSize: 11),
                        children: [
                          TextSpan(
                              text: 'Sign in',
                              style: AppTextStyles.link.copyWith(fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: sh * 0.04),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
