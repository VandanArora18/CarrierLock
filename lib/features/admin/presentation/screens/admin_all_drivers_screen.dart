import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/carrierlock_card.dart';
import '../../../../core/router/app_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Screen listing all drivers in a fleet — real-time from Firestore.
class AdminAllDriversScreen extends ConsumerWidget {
  const AdminAllDriversScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sw = MediaQuery.of(context).size.width;
    final hPad = sw * 0.044;
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.base,
      appBar: AppBar(title: const Text('Unlocked Drivers')),
      body: user?.fleetId == null
          ? Center(child: Text('No fleet selected', style: AppTextStyles.label))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('fleetId', isEqualTo: user!.fleetId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: AppColors.teal));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.local_shipping_outlined,
                            size: 56, color: AppColors.borderFaint),
                        const SizedBox(height: 16),
                        Text('No drivers yet', style: AppTextStyles.screenTitle),
                        const SizedBox(height: 8),
                        Text(
                          'Drivers will appear here once they\njoin using your fleet join code.',
                          style: AppTextStyles.label,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final allDocs = snapshot.data!.docs;
                final docs = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['carrierStatus'] == 'unlocked';
                }).toList();

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_outline_rounded,
                            size: 56, color: AppColors.borderFaint),
                        const SizedBox(height: 16),
                        Text('No unlocked drivers', style: AppTextStyles.screenTitle),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding:
                      EdgeInsets.symmetric(horizontal: hPad, vertical: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final name = data['name'] ?? 'Unknown';
                    final isOnline = data['isOnline'] ?? false;
                    final deviceId = data['deviceId'] ?? '';
                    final uid = docs[index].id;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CarrierLockCard(
                        type: CardType.standard,
                        onTap: () => context.push(
                          AppRoutes.adminDriverLiveMap,
                          extra: {'driverId': uid, 'driverName': name},
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.surface2,
                                border: Border.all(color: AppColors.borderFaint),
                              ),
                              child: Center(
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name,
                                      style: AppTextStyles.body.copyWith(
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isOnline
                                              ? AppColors.green
                                              : AppColors.textDimmer,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        isOnline ? 'Active' : 'Offline',
                                        style: AppTextStyles.label.copyWith(
                                          color: isOnline
                                              ? AppColors.textSecondary
                                              : AppColors.textDimmer,
                                        ),
                                      ),
                                      if (deviceId.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        Text('·', style: AppTextStyles.label),
                                        const SizedBox(width: 8),
                                        Text(deviceId,
                                            style: AppTextStyles.caption
                                                .copyWith(
                                                    color: AppColors.teal)),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded,
                                size: 16, color: AppColors.textDimmer),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
