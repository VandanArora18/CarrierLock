import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Screen showing pending unlock requests — real-time from Firestore.
class AdminPendingRequestsScreen extends ConsumerWidget {
  const AdminPendingRequestsScreen({super.key});

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sw = MediaQuery.of(context).size.width;
    final hPad = sw * 0.044;
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.base,
      appBar: AppBar(title: const Text('Pending Requests')),
      body: user?.fleetId == null
          ? Center(child: Text('No fleet selected', style: AppTextStyles.label))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('unlock_requests')
                  .where('fleetId', isEqualTo: user!.fleetId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: AppColors.gold));
                }
                if (snapshot.hasError) {
                  print('Req stream error: ${snapshot.error}');
                }
                
                final allDocs = snapshot.data?.docs ?? [];
                final docs = allDocs.where((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  return d['status'] == 'pending';
                }).toList();

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline_rounded,
                            size: 56, color: AppColors.borderFaint),
                        const SizedBox(height: 16),
                        Text('No pending requests',
                            style: AppTextStyles.screenTitle),
                      ],
                    ),
                  );
                }

                // Client-side sort
                docs.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final tsA = aData['createdAt'] as Timestamp?;
                  final tsB = bData['createdAt'] as Timestamp?;
                  if (tsA == null || tsB == null) return 0;
                  return tsB.compareTo(tsA);
                });

                return ListView.builder(
                  padding:
                      EdgeInsets.symmetric(horizontal: hPad, vertical: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final deviceId = data['deviceId'] ?? 'Unknown Device';
                    final driverName = data['driverName'] ?? 'Unknown Driver';
                    final ts = data['createdAt'];
                    DateTime? dt;
                    if (ts is Timestamp) dt = ts.toDate();

                    return GestureDetector(
                      onTap: () {
                        context.push(AppRoutes.adminRequestDetail, extra: {'requestId': docs[index].id});
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.goldDim,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.goldBorder),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.goldDim,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.vpn_key_rounded,
                                  color: AppColors.gold, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Unlock Request',
                                      style: AppTextStyles.body.copyWith(
                                          fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 3),
                                  Text('$driverName · $deviceId',
                                      style: AppTextStyles.label),
                                  if (dt != null) ...[
                                    const SizedBox(height: 3),
                                    Text(_timeAgo(dt),
                                        style: AppTextStyles.caption),
                                  ],
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => context.push(AppRoutes.adminRequestDetail, extra: {'requestId': docs[index].id}),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.gold,
                                foregroundColor: AppColors.base,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                minimumSize: const Size(0, 32),
                              ),
                              child: const Text('Review', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
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
