import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/alert_item.dart';
import '../../../../core/constants/app_constants.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Driver alerts feed screen.
class DriverAlertsScreen extends ConsumerWidget {
  const DriverAlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sw = MediaQuery.of(context).size.width;
    final hPad = sw * 0.044;
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return const Scaffold(
        backgroundColor: AppColors.base,
        body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.base,
      appBar: AppBar(
        title: const Text('Alerts'),
        actions: [
          TextButton(
            onPressed: () async {
              // Mark all alerts as cleared for this driver
              final snapshot = await FirebaseFirestore.instance
                  .collection('alerts')
                  .where('driverId', isEqualTo: user.uid)
                  .get();
                  
              final batch = FirebaseFirestore.instance.batch();
              for (var doc in snapshot.docs) {
                batch.update(doc.reference, {'cleared': true});
              }
              await batch.commit();
            },
            child: Text('Mark all read', style: AppTextStyles.link),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('alerts')
            .where('driverId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.gold));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading alerts', style: AppTextStyles.body));
          }

          final docs = snapshot.data?.docs ?? [];
          var driverAlerts = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['cleared'] == true) return false;
            final target = data['targetRole'] ?? 'both';
            return target == 'driver' || target == 'both';
          }).toList();

          // Sort locally to avoid needing a Firestore composite index
          driverAlerts.sort((a, b) {
            final ad = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
            final bd = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
            final aDate = ad?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bDate = bd?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bDate.compareTo(aDate);
          });

          if (driverAlerts.isEmpty) {
            return Center(
              child: Text(
                'No recent alerts',
                style: AppTextStyles.body.copyWith(color: AppColors.textDimmer),
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 16),
            itemCount: driverAlerts.length,
            itemBuilder: (context, index) {
              final data = driverAlerts[index].data() as Map<String, dynamic>;
              final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

              return AlertItem(
                title: data['title'] ?? 'Alert',
                body: data['body'] ?? '',
                severity: data['severity'] ?? 'info',
                createdAt: createdAt,
                read: data['read'] ?? false,
                onTap: () {
                  if (data['read'] != true) {
                    FirebaseFirestore.instance
                        .collection('alerts')
                        .doc(driverAlerts[index].id)
                        .update({'read': true});
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
