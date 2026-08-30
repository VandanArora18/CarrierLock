import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Screen listing completed lock/unlock history for the fleet.
class AdminHistoryScreen extends ConsumerWidget {
  const AdminHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sw = MediaQuery.of(context).size.width;
    final hPad = sw * 0.044;
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.base,
      appBar: AppBar(title: const Text('History')),
      body: user?.fleetId == null
          ? Center(child: Text('No fleet selected', style: AppTextStyles.label))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('carrier_history')
                  .where('fleetId', isEqualTo: user!.fleetId)
                  .where('status', isEqualTo: 'completed')
                  .orderBy('lockedAt', descending: true)
                  .limit(50)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.teal));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.history_rounded, size: 56, color: AppColors.borderFaint),
                        const SizedBox(height: 16),
                        Text('No history yet', style: AppTextStyles.screenTitle),
                        const SizedBox(height: 8),
                        Text('Completed lock/unlock sessions will appear here.',
                            style: AppTextStyles.label, textAlign: TextAlign.center),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data!.docs;
                final dateFormat = DateFormat('MMM dd, yyyy - hh:mm a');

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final driverName = data['driverName'] ?? 'Unknown Driver';
                    final ts = data['lockedAt'] as Timestamp?;
                    final lockedAtStr = ts != null ? dateFormat.format(ts.toDate()) : 'Unknown Date';

                    return GestureDetector(
                      onTap: () {
                        context.push(
                          AppRoutes.adminHistoryDetail,
                          extra: {'historyDoc': docs[index]},
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cardSurface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.borderFaint),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.surface2,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.local_shipping_rounded, color: AppColors.teal),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(driverName, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Text(lockedAtStr, style: AppTextStyles.caption),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: AppColors.borderFaint),
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
