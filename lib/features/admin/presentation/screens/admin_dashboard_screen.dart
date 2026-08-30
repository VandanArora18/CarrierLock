import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/carrierlock_card.dart';
import '../../../../core/widgets/bottom_nav_pill.dart';
import '../../../../core/widgets/live_pulse.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/greeting_utils.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Admin dashboard screen — overview of fleets, pending requests, and live map.
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  StreamSubscription? _requestsSubscription;
  final int _navIndex = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupPushNotifications();
      final user = ref.read(currentUserProvider);
      if (user?.fleetId != null) {
        _requestsSubscription = FirebaseFirestore.instance
            .collection('unlock_requests')
            .where('fleetId', isEqualTo: user!.fleetId)
            .where('status', isEqualTo: 'pending')
            .snapshots()
            .listen((snapshot) {
          for (final change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              _showLocalNotification(
                title: '🔐 New unlock request',
                body: 'Driver requesting access to ${change.doc.data()!['deviceId']}',
              );
            }
          }
          if (mounted) setState(() {});
        });
      }
    });
  }

  Future<void> _setupPushNotifications() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    final token = await messaging.getToken();
    if (token != null) {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'fcmToken': token});
      }
    }
  }

  void _showLocalNotification({required String title, required String body}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$title - $body'),
        backgroundColor: AppColors.teal,
        duration: const Duration(seconds: 4),
      ));
    }
  }

  @override
  void dispose() {
    _requestsSubscription?.cancel();
    super.dispose();
  }

  final List<NavItem> _navItems = const [
    NavItem(icon: Icons.dashboard_rounded, label: 'DASHBOARD'),
    NavItem(icon: Icons.swap_horiz_rounded, label: 'FLEET'),
    NavItem(icon: Icons.history_rounded, label: 'HISTORY'),
    NavItem(icon: Icons.notifications_rounded, label: 'ALERTS'),
  ];

  void _onNavTap(int index) {
    switch (index) {
      case 0:
        break; // Already on dashboard
      case 1:
        _showFleetInfoSheet();
        break;
      case 2:
        context.push(AppRoutes.adminHistory);
        break;
      case 3:
        context.push(AppRoutes.adminAlerts);
        break;
    }
  }

  void _showFleetInfoSheet() {
    final user = ref.read(currentUserProvider);
    if (user?.fleetId == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('fleets')
            .doc(user!.fleetId)
            .snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() as Map<String, dynamic>?;
          final name = data?['name'] ?? 'Loading...';
          final desc = data?['description'] ?? '';
          String joinCode = data?['joinCode'] ?? '';

          // Auto-generate and save joinCode if fleet doesn't have one
          if (data != null && joinCode.isEmpty) {
            joinCode = (1000 + Random().nextInt(9000)).toString();
            FirebaseFirestore.instance
                .collection('fleets')
                .doc(user!.fleetId)
                .update({'joinCode': joinCode});
          }
          return Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.tealDim,
                        border: Border.all(color: AppColors.tealBorder),
                      ),
                      child: const Icon(Icons.business_rounded,
                          color: AppColors.teal, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: AppTextStyles.screenTitle
                                  .copyWith(fontSize: 18)),
                          if (desc.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(desc, style: AppTextStyles.label),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Driver Join Code section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.tealDim,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.tealBorder),
                  ),
                  child: Column(
                    children: [
                      Text('DRIVER JOIN CODE', style: AppTextStyles.sectionLabel),
                      const SizedBox(height: 8),
                      Text(
                        joinCode,
                        style: AppTextStyles.screenTitle.copyWith(
                          color: AppColors.teal,
                          fontSize: 36,
                          letterSpacing: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Share this code with drivers to join',
                          style: AppTextStyles.caption),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.swap_horiz_rounded,
                        color: AppColors.teal),
                    label: Text('Switch Fleet',
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.teal)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.tealBorder),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.go(AppRoutes.adminFleetSelection);
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    final hPad = sw * 0.044;
    final user = ref.watch(currentUserProvider);
    final userName = user?.name ?? 'Admin';

    return Scaffold(
      backgroundColor: AppColors.base,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: 90),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: sh * 0.02),

                    // Header row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(GreetingUtils.getGreeting(),
                                      style: AppTextStyles.greetSub
                                          .copyWith(color: AppColors.teal))
                                  .animate()
                                  .fadeIn(duration: 400.ms),
                              const SizedBox(height: 2),
                              Text(
                                userName,
                                style: AppTextStyles.greetName,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              )
                                  .animate()
                                  .fadeIn(delay: 100.ms, duration: 400.ms),
                            ],
                          ),
                        ),
                        // Settings & Avatar
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.settings_outlined, color: AppColors.textSecondary),
                              onPressed: () => context.push(AppRoutes.driverSettings),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: null, // Removed sign out from avatar
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.tealDim,
                                  border: Border.all(color: AppColors.tealBorder),
                                ),
                                child: Center(
                                  child: Text(
                                    userName.isNotEmpty
                                        ? userName[0].toUpperCase()
                                        : 'A',
                                    style: AppTextStyles.fleetId.copyWith(
                                        fontSize: 14, color: AppColors.teal),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    SizedBox(height: sh * 0.03),

                    // Quick Stats — Real-time from Firestore
                    if (user?.fleetId != null)
                      StreamBuilder<QuerySnapshot>(
                        // Use only 2-field query (no composite index needed),
                        // then filter carrierStatus client-side
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .where('fleetId', isEqualTo: user!.fleetId)
                            .snapshots(),
                        builder: (context, driverSnap) {
                          if (driverSnap.hasError) {
                            print('Users stream error: ${driverSnap.error}');
                          }
                          // Client-side filter: role == driver && carrierStatus == unlocked
                          final allUserDocs = driverSnap.data?.docs ?? [];
                          
                          print('--- DEBUG ---');
                          print('Total user docs for fleet ${user.fleetId}: ${allUserDocs.length}');
                          
                          final activeDrivers = allUserDocs.where((doc) {
                            final d = doc.data() as Map<String, dynamic>;
                            final cs = d['carrierStatus']?.toString().toLowerCase();
                            return cs == 'unlocked';
                          }).length;
                          
                          final hardLocked = allUserDocs.where((doc) {
                            final d = doc.data() as Map<String, dynamic>;
                            return d['isHardLocked'] == true || d['carrierStatus'] == 'hard_locked';
                          }).length;

                          return StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('unlock_requests')
                                .where('fleetId', isEqualTo: user.fleetId)
                                .snapshots(),
                            builder: (context, reqSnap) {
                              if (reqSnap.hasError) {
                                print('Req stream error: ${reqSnap.error}');
                              }
                                  
                              final pendingCount = (reqSnap.data?.docs ?? []).where((doc) {
                                return (doc.data() as Map<String, dynamic>)['status'] == 'pending';
                              }).length;

                              return Row(
                                children: [
                                      Expanded(
                                        child: _StatCard(
                                          label: 'Pending Requests',
                                          value: '$pendingCount',
                                          icon: Icons.access_time_rounded,
                                          color: AppColors.gold,
                                          onTap: () => context.push(AppRoutes.adminPendingRequests),
                                        ),
                                      ),
                                      SizedBox(width: sw * 0.03),
                                      Expanded(
                                        child: _StatCard(
                                          label: 'Active Drivers',
                                          value: '$activeDrivers',
                                          icon: Icons.local_shipping_rounded,
                                          color: AppColors.teal,
                                          onTap: () => context.push(AppRoutes.adminActiveDrivers),
                                        ),
                                      ),
                                      SizedBox(width: sw * 0.03),
                                      Expanded(
                                        child: _StatCard(
                                          label: 'Hard Locked',
                                          value: '$hardLocked',
                                          icon: Icons.lock_rounded,
                                          color: AppColors.red,
                                          onTap: () => context.push(AppRoutes.adminHardLocked),
                                        ),
                                      ),
                                    ],
                                  ).animate().fadeIn(delay: 300.ms, duration: 400.ms);
                            },
                          );
                        },
                      )
                    else
                      Row(
                        children: [
                          Expanded(child: _StatCard(label: 'Pending Requests', value: '0', icon: Icons.access_time_rounded, color: AppColors.gold)),
                          SizedBox(width: sw * 0.03),
                          Expanded(child: _StatCard(label: 'Active Drivers', value: '0', icon: Icons.local_shipping_rounded, color: AppColors.teal)),
                          SizedBox(width: sw * 0.03),
                          Expanded(child: _StatCard(label: 'Hard Locked', value: '0', icon: Icons.lock_rounded, color: AppColors.red)),
                        ],
                      ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

                    SizedBox(height: sh * 0.04),

                    // Action Required Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('ACTION REQUIRED',
                            style: AppTextStyles.sectionLabel),
                        TextButton(
                          onPressed: () {},
                          child: Text('See All', style: AppTextStyles.link),
                        ),
                      ],
                    ).animate().fadeIn(delay: 400.ms),

                    // Pending Requests List
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('unlock_requests')
                          .where('fleetId', isEqualTo: user?.fleetId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                           return const Center(child: CircularProgressIndicator(color: AppColors.gold));
                        }
                        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
                           return Center(child: Text('No pending requests', style: AppTextStyles.label));
                        }
                        
                        // Client-side sort and limit
                        final allDocs = snapshot.data!.docs.toList();
                        final docs = allDocs.where((doc) {
                          final d = doc.data() as Map<String, dynamic>;
                          return d['status'] == 'pending';
                        }).toList();
                        
                        if (docs.isEmpty) {
                           return Center(child: Text('No pending requests', style: AppTextStyles.label));
                        }

                        docs.sort((a, b) {
                          final aData = a.data() as Map<String, dynamic>;
                          final bData = b.data() as Map<String, dynamic>;
                          final tsA = aData['createdAt'] as Timestamp?;
                          final tsB = bData['createdAt'] as Timestamp?;
                          if (tsA == null || tsB == null) return 0;
                          return tsB.compareTo(tsA);
                        });
                        final limitedDocs = docs.take(5).toList();

                        return Column(
                          children: limitedDocs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final reqId = doc.id;
                            final deviceId = data['deviceId'] ?? 'Unknown';
                            final driverName = data['driverName'] ?? 'Driver';
                            
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: CarrierLockCard(
                                type: CardType.gold,
                                padding: const EdgeInsets.all(16),
                                onTap: () => context.push(AppRoutes.adminRequestDetail,
                                    extra: {'requestId': reqId}),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: AppColors.goldDim,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: AppColors.goldBorder.withOpacity(0.3)),
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
                                              style: AppTextStyles.body
                                                  .copyWith(fontWeight: FontWeight.w700)),
                                          const SizedBox(height: 2),
                                          Text('$driverName • DEV: $deviceId',
                                              style: AppTextStyles.caption),
                                        ],
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => context.push(AppRoutes.adminRequestDetail, extra: {'requestId': reqId}),
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
                          }).toList(),
                        );
                      },
                    )
                        .animate()
                        .fadeIn(delay: 500.ms)
                        .slideY(begin: 0.1, end: 0),

                    SizedBox(height: sh * 0.035),

                    // ─── ACTION REQUIRED — Driver Login Approvals ──────────
                    if (user?.fleetId != null)
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('pending_driver_auth')
                            .where('fleetId', isEqualTo: user!.fleetId)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox.shrink();
                          final allDocs = snapshot.data?.docs ?? [];
                          final docsList = allDocs.where((doc) {
                            final d = doc.data() as Map<String, dynamic>;
                            return d['status'] == 'awaiting_approval';
                          }).toList();
                          
                          if (docsList.isEmpty) return const SizedBox.shrink();
                          
                          docsList.sort((a, b) {
                            final tsA = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                            final tsB = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                            if (tsA == null || tsB == null) return 0;
                            return tsB.compareTo(tsA);
                          });
                          
                          final docs = docsList;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.red,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('ACTION REQUIRED',
                                      style: AppTextStyles.sectionLabel
                                          .copyWith(color: AppColors.red)),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.redDim,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: AppColors.redBorder),
                                    ),
                                    child: Text('${docs.length}',
                                        style: AppTextStyles.caption
                                            .copyWith(color: AppColors.red)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ...docs.map((doc) {
                                final data =
                                    doc.data() as Map<String, dynamic>;
                                final driverName =
                                    data['driverName'] ?? 'Unknown Driver';
                                final phone = data['phone'] ?? '';
                                final approvalCode =
                                    data['approvalCode'] ?? '';
                                final pendingId = doc.id;
                                final driverUid =
                                    data['driverUid'] ?? '';

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.redDim,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                        color: AppColors.redBorder),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 42,
                                            height: 42,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: AppColors.surface2,
                                              border: Border.all(
                                                  color: AppColors.redBorder),
                                            ),
                                            child: Center(
                                              child: Text(
                                                driverName.isNotEmpty
                                                    ? driverName[0]
                                                        .toUpperCase()
                                                    : '?',
                                                style: TextStyle(
                                                  color: AppColors.red,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(driverName,
                                                    style: AppTextStyles.body
                                                        .copyWith(
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold)),
                                                const SizedBox(height: 2),
                                                Text(phone,
                                                    style: AppTextStyles
                                                        .caption),
                                                Text(
                                                    'Wants to join your fleet',
                                                    style: AppTextStyles.label
                                                        .copyWith(
                                                            color: AppColors
                                                                .textDimmer)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      Row(
                                        children: [
                                          // REJECT
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              icon: const Icon(
                                                  Icons.close_rounded,
                                                  size: 16,
                                                  color: AppColors.red),
                                              label: Text('Reject',
                                                  style: AppTextStyles.body
                                                      .copyWith(
                                                          color:
                                                              AppColors.red,
                                                          fontSize: 13)),
                                              style:
                                                  OutlinedButton.styleFrom(
                                                side: const BorderSide(
                                                    color: AppColors.redBorder),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 10),
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10)),
                                              ),
                                              onPressed: () async {
                                                await FirebaseFirestore
                                                    .instance
                                                    .collection(
                                                        'pending_driver_auth')
                                                    .doc(pendingId)
                                                    .update(
                                                        {'status': 'rejected'});
                                                if (driverUid.isNotEmpty) {
                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection('users')
                                                      .doc(driverUid)
                                                      .update({
                                                    'approvalStatus':
                                                        'rejected'
                                                  });
                                                }
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          // APPROVE
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              icon: const Icon(
                                                  Icons.check_rounded,
                                                  size: 16,
                                                  color: AppColors.base),
                                              label: Text('Approve',
                                                  style: AppTextStyles.body
                                                      .copyWith(
                                                          color: AppColors.base,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 13)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    AppColors.teal,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 10),
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10)),
                                              ),
                                              onPressed: () async {
                                                // Update pending auth → approved, expose approvalCode
                                                await FirebaseFirestore
                                                    .instance
                                                    .collection(
                                                        'pending_driver_auth')
                                                    .doc(pendingId)
                                                    .update({
                                                  'status': 'approved',
                                                });
                                                // Show admin the code to verbally/visually share
                                                if (mounted) {
                                                  showDialog(
                                                    context: context,
                                                    builder: (ctx) => AlertDialog(
                                                      backgroundColor:
                                                          AppColors.surface1,
                                                      title: Text(
                                                          'Share This Code',
                                                          style: AppTextStyles
                                                              .screenTitle),
                                                      content: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                              'Tell $driverName to enter:',
                                                              style: AppTextStyles
                                                                  .label),
                                                          const SizedBox(
                                                              height: 16),
                                                          Text(
                                                            approvalCode,
                                                            style: TextStyle(
                                                              color: AppColors
                                                                  .teal,
                                                              fontSize: 48,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w900,
                                                              letterSpacing: 12,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              height: 8),
                                                          Text(
                                                              'Driver enters this code to complete login',
                                                              style: AppTextStyles
                                                                  .caption,
                                                              textAlign:
                                                                  TextAlign
                                                                      .center),
                                                        ],
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                  ctx),
                                                          child: Text('Done',
                                                              style: AppTextStyles
                                                                  .link),
                                                        )
                                                      ],
                                                    ),
                                                  );
                                                }
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              const SizedBox(height: 8),
                            ],
                          );
                        },
                      ).animate().fadeIn(delay: 350.ms),

                    // Live Fleet Overview
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text('LIVE FLEET STATUS',
                                style: AppTextStyles.sectionLabel),
                            const SizedBox(width: 8),
                            const LivePulse(size: 14),
                          ],
                        ),
                        TextButton(
                          onPressed: () =>
                              context.push(AppRoutes.adminAllDrivers),
                          child: Text('View Map', style: AppTextStyles.link),
                        ),
                      ],
                    ).animate().fadeIn(delay: 600.ms),

                    // Placeholder Map Card
                    CarrierLockCard(
                      type: CardType.standard,
                      onTap: () => context.push(AppRoutes.adminAllDrivers),
                      padding: const EdgeInsets.all(0),
                      child: Container(
                        height: 180,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: AppColors.surface2,
                        ),
                        child: Stack(
                          children: [
                            const Center(
                              child: Icon(Icons.map_outlined,
                                  size: 48, color: AppColors.borderFaint),
                            ),
                            Positioned(
                              bottom: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.base.withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(20),
                                  border:
                                      Border.all(color: AppColors.borderMid),
                                ),
                                child: StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('users')
                                      .where('fleetId', isEqualTo: ref.read(currentUserProvider)?.fleetId)
                                      .snapshots(),
                                  builder: (context, snap) {
                                    final allDocs = snap.data?.docs ?? [];
                                    final count = allDocs.where((doc) {
                                      final d = doc.data() as Map<String, dynamic>;
                                      final role = d['role']?.toString().toLowerCase();
                                      final cs = d['carrierStatus']?.toString().toLowerCase();
                                      return cs == 'unlocked';
                                    }).length;
                                    return Text('$count Active Drivers',
                                        style: AppTextStyles.label);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 700.ms)
                        .slideY(begin: 0.1, end: 0),
                  ],
                ),
              ),
            ),
          ),

          // Bottom nav
          BottomNavPill(
            currentIndex: _navIndex,
            items: _navItems,
            onTap: _onNavTap,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CarrierLockCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(value,
              style: AppTextStyles.statNumber
                  .copyWith(fontSize: 24, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
              maxLines: 2),
        ],
      ),
    );
  }
}
