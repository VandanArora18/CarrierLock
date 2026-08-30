import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/gold_button.dart';
import '../../../../core/router/app_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Driver settings profile and sign out.
class DriverSettingsScreen extends ConsumerWidget {
  const DriverSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
        final baseUser = ref.watch(currentUserProvider);
        if (baseUser == null) {
          return const Scaffold(backgroundColor: AppColors.base, body: Center(child: CircularProgressIndicator(color: AppColors.gold)));
        }

        final sw = MediaQuery.of(context).size.width;
        final hPad = sw * 0.044;

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(baseUser.uid).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Scaffold(backgroundColor: AppColors.base, body: Center(child: CircularProgressIndicator(color: AppColors.gold)));
            }
            final user = UserModel.fromFirestore(snapshot.data!);

            final isAdmin = user.isAdmin == true;
            final primaryColor = isAdmin ? AppColors.teal : AppColors.gold;
            final primaryDim = isAdmin ? AppColors.tealDim : AppColors.goldDim;
            final primaryBorder = isAdmin ? AppColors.tealBorder : AppColors.goldBorder;

            return Scaffold(
              backgroundColor: AppColors.base,
              appBar: AppBar(
                title: const Text('Settings'),
              ),
              body: ListView(
                padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 16),
                children: [
                  // Profile summary
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primaryDim,
                          border: Border.all(color: primaryBorder),
                        ),
                        child: Center(
                          child: Text(
                            user.name.isNotEmpty == true
                                ? user.name[0].toUpperCase()
                                : (isAdmin ? 'A' : 'D'),
                            style: AppTextStyles.screenTitle
                                .copyWith(color: primaryColor, fontSize: 24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.name.isNotEmpty == true ? user.name : (isAdmin ? 'Admin Name' : 'Driver Name'),
                                style:
                                    AppTextStyles.screenTitle.copyWith(fontSize: 18)),
                            const SizedBox(height: 4),
                            Text(user.email.isNotEmpty == true ? user.email : 'user@company.com',
                                style: AppTextStyles.label),
                            if (user.fleetId != null) ...[
                              const SizedBox(height: 4),
                              FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance.collection('fleets').doc(user.fleetId).get(),
                                builder: (ctx, snap) {
                                  final joinCode = snap.data?.data() != null 
                                      ? (snap.data!.data() as Map<String, dynamic>)['joinCode'] as String?
                                      : null;
                                  return Text('Fleet Code: ${joinCode ?? '...'}', 
                                      style: AppTextStyles.label.copyWith(color: primaryColor, fontWeight: FontWeight.w600));
                                }
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
          const SizedBox(height: 32),

          Text('ACCOUNT', style: AppTextStyles.sectionLabel),
          const SizedBox(height: 8),
          _SettingsTile(
              icon: Icons.person_outline_rounded,
              title: 'Edit Profile',
              onTap: () {}),
          _SettingsTile(
              icon: Icons.security_rounded,
              title: 'Security & Password',
              onTap: () {}),

          const SizedBox(height: 24),

          Text('APP', style: AppTextStyles.sectionLabel),
          const SizedBox(height: 8),
          _SettingsTile(
              icon: Icons.notifications_outlined,
              title: 'Notification Preferences',
              onTap: () {}),
          _SettingsTile(
              icon: Icons.info_outline_rounded,
              title: 'About CarrierLock',
              onTap: () {}),

          const SizedBox(height: 40),

          GoldButton(
            label: 'Sign Out',
            outlined: true,
            icon: Icons.logout_rounded,
            onPressed: () async {
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) {
                context.go(AppRoutes.splash);
              }
            },
          ),
        ],
      ),
            );
          },
        );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SettingsTile(
      {required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.textSecondary, size: 22),
      title: Text(title, style: AppTextStyles.body),
      trailing: const Icon(Icons.arrow_forward_ios_rounded,
          color: AppColors.textDimmer, size: 14),
      onTap: onTap,
    );
  }
}
