import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Screen showing hard-locked devices — real-time from Firestore.
class AdminHardLockedScreen extends ConsumerWidget {
  const AdminHardLockedScreen({super.key});

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
      appBar: AppBar(
        title: const Text('Hard Locked'),
        actions: [],
      ),
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
                      child: CircularProgressIndicator(color: AppColors.red));
                }
                
                final allDocs = snapshot.data?.docs ?? [];
                final docs = allDocs.where((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  return d['isHardLocked'] == true || d['carrierStatus'] == 'hard_locked';
                }).toList();

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_open_rounded,
                            size: 56, color: AppColors.borderFaint),
                        const SizedBox(height: 16),
                        Text('No hard locked devices',
                            style: AppTextStyles.screenTitle),
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
                    final driverName = data['name'] ?? 'Unknown Driver';
                    final phone = data['phone'] ?? 'No phone';
                    final ts = data['lockedAt'];
                    DateTime? dt;
                    if (ts is Timestamp) dt = ts.toDate();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.redDim,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.redBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.redDim,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.lock_rounded,
                                color: AppColors.red, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  driverName,
                                  style: AppTextStyles.bodyLarge.copyWith(fontSize: 16, color: AppColors.red),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  phone,
                                  style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
                                ),
                                if (dt != null) ...[
                                  const SizedBox(height: 3),
                                  Text(_timeAgo(dt),
                                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () async {
                              final driverId = docs[index].id;
                              await docs[index].reference.update({
                                'isHardLocked': false,
                                'carrierStatus': 'locked',
                              });
                              
                              final deviceQuery = await FirebaseFirestore.instance
                                  .collection('devices')
                                  .where('driverId', isEqualTo: driverId)
                                  .limit(1)
                                  .get();
                              if (deviceQuery.docs.isNotEmpty) {
                                await deviceQuery.docs.first.reference.update({
                                  'isHardLocked': false,
                                  'status': 'locked',
                                });
                              }
                            },
                            icon: const Icon(Icons.lock_open_rounded, color: AppColors.white, size: 16),
                            label: const Text('Unlock', style: TextStyle(color: AppColors.white)),
                            style: TextButton.styleFrom(
                              backgroundColor: AppColors.red,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
