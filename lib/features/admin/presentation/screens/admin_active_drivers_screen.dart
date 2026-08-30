import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/carrierlock_card.dart';
import '../../../../core/router/app_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Screen listing only ACTIVE (carrier-unlocked) drivers in the fleet.
class AdminActiveDriversScreen extends ConsumerWidget {
  const AdminActiveDriversScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sw = MediaQuery.of(context).size.width;
    final hPad = sw * 0.044;
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.base,
      appBar: AppBar(title: const Text('Active Drivers')),
      body: user?.fleetId == null
          ? Center(child: Text('No fleet selected', style: AppTextStyles.label))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('fleetId', isEqualTo: user!.fleetId)
                  .where('role', isEqualTo: 'driver')
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
                        Text('No active drivers now',
                            style: AppTextStyles.screenTitle),
                        const SizedBox(height: 8),
                        Text(
                          'Drivers will appear here when\ntheir carrier is unlocked.',
                          style: AppTextStyles.label,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final allDocs = snapshot.data!.docs;
                // Filter client-side: only drivers with carrier unlocked
                final docs = allDocs.where((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  final role = d['role']?.toString().toLowerCase();
                  final cs = d['carrierStatus']?.toString().toLowerCase();
                  return cs == 'unlocked';
                }).toList();

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.local_shipping_outlined,
                            size: 56, color: AppColors.borderFaint),
                        const SizedBox(height: 16),
                        Text('No active drivers now',
                            style: AppTextStyles.screenTitle),
                        const SizedBox(height: 8),
                        Text(
                          'Drivers will appear here when\ntheir carrier is unlocked.',
                          style: AppTextStyles.label,
                          textAlign: TextAlign.center,
                        ),
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
                    final uid = docs[index].id;
                    final placeName = (data['currentLocation'] as Map<String, dynamic>?)?['placeName'];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CarrierLockCard(
                        type: CardType.standard,
                        onTap: () => context.push(
                          AppRoutes.adminDriverDetail,
                          extra: {'driverId': uid},
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.tealDim,
                                border: Border.all(color: AppColors.tealBorder),
                              ),
                              child: Center(
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: const TextStyle(
                                    color: AppColors.teal,
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
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.teal,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Active',
                                        style: AppTextStyles.label.copyWith(
                                          color: AppColors.teal,
                                        ),
                                      ),
                                      if (placeName != null) ...[
                                        const SizedBox(width: 8),
                                        Text('·', style: AppTextStyles.label),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            placeName,
                                            style: AppTextStyles.caption
                                                .copyWith(color: AppColors.textSecondary),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
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
