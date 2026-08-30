import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/gold_button.dart';
import '../../../../core/widgets/carrierlock_card.dart';
import '../../../../core/router/app_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class AdminFleetSelectionScreen extends ConsumerWidget {
  const AdminFleetSelectionScreen({super.key});

  Future<void> _selectFleet(BuildContext context, WidgetRef ref, String fleetId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.teal)),
    );

    try {
      // Update user document
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'fleetId': fleetId,
      });
      // Refresh auth state so the app knows the new fleetId
      await ref.read(authProvider.notifier).checkAuthState();
      
      // Pop loading
      if (context.mounted) Navigator.pop(context);
      
      // Navigate to dashboard
      if (context.mounted) context.go(AppRoutes.adminDashboard);
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting fleet: $e')),
        );
      }
    }
  }

  Future<void> _deleteFleet(BuildContext context, String fleetId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface2,
        title: Text('Delete Fleet?', style: AppTextStyles.screenTitle),
        content: Text(
          'Are you sure you want to delete this fleet? This action cannot be undone.',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance.collection('fleets').doc(fleetId).delete();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting fleet: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final sw = MediaQuery.of(context).size.width;
    final hPad = sw * 0.044;

    if (user == null) {
      return const Scaffold(backgroundColor: AppColors.base);
    }

    return Scaffold(
      backgroundColor: AppColors.base,
      appBar: AppBar(
        title: const Text('Select Fleet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) context.go(AppRoutes.splash);
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('YOUR FLEETS', style: AppTextStyles.sectionLabel),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('fleets')
                    .where('adminIds', arrayContains: user.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.teal),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}', style: AppTextStyles.body),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.business_rounded, size: 64, color: AppColors.textSecondary),
                          const SizedBox(height: 16),
                          Text('No fleets found', style: AppTextStyles.screenTitle),
                          const SizedBox(height: 8),
                          Text(
                            'You do not manage any fleets yet.\nCreate one to get started.',
                            style: AppTextStyles.body,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final fleetName = data['name'] ?? 'Unnamed Fleet';
                      final fleetId = doc.id;
                      String joinCode = data['joinCode'] ?? '';

                      // Auto-generate and save if missing (for old fleets)
                      if (joinCode.isEmpty) {
                        joinCode = (1000 + Random().nextInt(9000)).toString();
                        FirebaseFirestore.instance
                            .collection('fleets')
                            .doc(fleetId)
                            .update({'joinCode': joinCode});
                      }

                      return CarrierLockCard(
                        type: CardType.teal,
                        onTap: () => _selectFleet(context, ref, fleetId),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(fleetName, style: AppTextStyles.screenTitle),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.tealDim,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: AppColors.tealBorder),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.tag_rounded, size: 12, color: AppColors.teal),
                                              const SizedBox(width: 4),
                                              Text(
                                                joinCode,
                                                style: AppTextStyles.fleetId.copyWith(
                                                  color: AppColors.teal,
                                                  fontSize: 14,
                                                  letterSpacing: 4,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                                    onPressed: () => _deleteFleet(context, fleetId),
                                  ),
                                  const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.teal, size: 16),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            GoldButton(
              label: 'Create New Fleet',
              icon: Icons.add_business_rounded,
              onPressed: () => context.push(AppRoutes.adminCreateFleet),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
