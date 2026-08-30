import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Admin alerts feed screen — real-time from Firestore.
class AdminAlertsScreen extends ConsumerWidget {
  const AdminAlertsScreen({super.key});

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'critical': return AppColors.red;
      case 'warning': return AppColors.amber;
      default: return AppColors.teal;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sw = MediaQuery.of(context).size.width;
    final hPad = sw * 0.044;
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.base,
      appBar: AppBar(
        title: const Text('Fleet Alerts'),
        actions: [
          if (user?.fleetId != null)
            TextButton(
              onPressed: () async {
                // Mark all alerts as read
                final query = await FirebaseFirestore.instance
                    .collection('alerts')
                    .where('fleetId', isEqualTo: user!.fleetId)
                    .where('read', isEqualTo: false)
                    .get();
                final batch = FirebaseFirestore.instance.batch();
                for (final doc in query.docs) {
                  batch.update(doc.reference, {'read': true});
                }
                await batch.commit();
              },
              child: Text('Mark all read', style: AppTextStyles.link),
            ),
        ],
      ),
      body: user?.fleetId == null
          ? Center(child: Text('No fleet selected', style: AppTextStyles.label))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('alerts')
                  .where('fleetId', isEqualTo: user!.fleetId)
                  .orderBy('createdAt', descending: true)
                  .limit(50)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: AppColors.teal));
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SelectableText(
                        'Database Error: ${snapshot.error}\n\n(You likely need to click the link in your console logs to create a Firestore index)',
                        style: const TextStyle(color: AppColors.red),
                      ),
                    ),
                  );
                }
                final allDocs = snapshot.data?.docs ?? [];
                final docs = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final isRead = data['read'] == true;
                  final type = data['type'] ?? '';
                  return !isRead && type == 'carrier_locked_by_driver';
                }).toList();

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.notifications_none_rounded,
                            size: 56, color: AppColors.borderFaint),
                        const SizedBox(height: 16),
                        Text('No alerts', style: AppTextStyles.screenTitle),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final title = data['title'] ?? 'Alert';
                    final body = data['body'] ?? data['message'] ?? '';
                    final severity = data['severity'] ?? 'info';
                    final read = data['read'] ?? false;
                    final ts = data['createdAt'];
                    DateTime? dt;
                    if (ts is Timestamp) dt = ts.toDate();
                    final color = _severityColor(severity);

                    return GestureDetector(
                      onTap: () {
                        // Mark as read on tap
                        FirebaseFirestore.instance
                            .collection('alerts')
                            .doc(docs[index].id)
                            .update({'read': true});
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: read ? AppColors.cardSurface : color.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: read ? AppColors.borderFaint : color.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(top: 6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: read ? AppColors.textDimmer : color,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(title,
                                          style: AppTextStyles.body.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: read ? AppColors.textSecondary : AppTextStyles.body.color,
                                          )),
                                      if (dt != null)
                                        Text(_timeAgo(dt), style: AppTextStyles.caption),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(body, style: AppTextStyles.label),
                                ],
                              ),
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
