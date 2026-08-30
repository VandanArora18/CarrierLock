import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/carrierlock_card.dart';
import '../../../../core/widgets/gold_button.dart';
import '../../../../core/widgets/fleet_tag.dart';
import '../../../../core/widgets/bottom_nav_pill.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/greeting_utils.dart';
import '../../../../core/utils/date_utils.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/otp_provider.dart';
import '../providers/location_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/location_provider.dart';
import '../../../auth/domain/user_model.dart';
import '../../../../core/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Driver home screen — dashboard with greeting, carrier status, and quick actions.
class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen> {
  final int _navIndex = 0;
  bool _isLocatingForOtp = false;
  bool _isLocatingForLock = false;

  final List<NavItem> _navItems = const [
    NavItem(icon: Icons.home_rounded, label: 'HOME'),
    NavItem(icon: Icons.notifications_rounded, label: 'ALERTS'),
    NavItem(icon: Icons.location_on_rounded, label: 'LOCATION'),
    NavItem(icon: Icons.settings_rounded, label: 'SETTINGS'),
  ];

  void _onNavTap(int index) {
    switch (index) {
      case 0:
        break; // Already on home
      case 1:
        context.push(AppRoutes.driverAlerts);
        break;
      case 2:
        context.push(AppRoutes.driverLocation);
        break;
      case 3:
        context.push(AppRoutes.driverSettings);
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupPushNotifications();
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

  Future<void> _notifyAdmins(String fleetId, String title, String body) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('fleetId', isEqualTo: fleetId)
          .where('role', isEqualTo: 'admin')
          .get();
      
      for (var doc in snapshot.docs) {
        final token = doc.data()['fcmToken'];
        if (token != null) {
          await NotificationService.sendPushNotification(
            targetToken: token as String,
            title: title,
            body: body,
          );
        }
      }
    } catch (e) {
      debugPrint('Failed to notify admins: $e');
    }
  }

  Future<void> _handleLockCarrier(String uid, String driverName, String deviceId, double currentLat, double currentLng, String? currentPlaceName, String? fleetId, DateTime? unlockedAt, double? unlockLat, double? unlockLng, Map<String, dynamic>? fleetStats) async {

    // Calculate active time
    int additionalSeconds = 0;
    if (unlockedAt != null) {
      additionalSeconds = DateTime.now().difference(unlockedAt).inSeconds;
    }

    // Calculate distance (Haversine formula)
    double additionalDistanceKm = 0.0;
    if (unlockLat != null && unlockLng != null) {
      const double earthRadiusKm = 6371.0;
      final double dLat = _degreesToRadians(currentLat - unlockLat);
      final double dLng = _degreesToRadians(currentLng - unlockLng);
      final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
          math.cos(_degreesToRadians(unlockLat)) * math.cos(_degreesToRadians(currentLat)) *
          math.sin(dLng / 2) * math.sin(dLng / 2);
      final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
      additionalDistanceKm = earthRadiusKm * c;
    }

    // Update stats map
    final updatedStats = Map<String, dynamic>.from(fleetStats ?? {});
    final currentFleetId = fleetId ?? 'Unknown Fleet';
    
    final currentFleetStats = Map<String, dynamic>.from(updatedStats[currentFleetId] ?? {
      'totalUnlocks': 0,
      'activeTimeSeconds': 0,
      'distanceKm': 0.0,
    });

    currentFleetStats['totalUnlocks'] = (currentFleetStats['totalUnlocks'] as int) + 1;
    currentFleetStats['activeTimeSeconds'] = (currentFleetStats['activeTimeSeconds'] as int) + additionalSeconds;
    currentFleetStats['distanceKm'] = (currentFleetStats['distanceKm'] as double) + additionalDistanceKm;

    updatedStats[currentFleetId] = currentFleetStats;

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'carrierStatus': 'locked',
      'fleetStats': updatedStats,
      'lockLat': currentLat,
      'lockLng': currentLng,
      if (currentPlaceName != null) 'lockPlaceName': currentPlaceName,
    });

    // Close active carrier_history record
    try {
      final historyQuery = await FirebaseFirestore.instance
          .collection('carrier_history')
          .where('driverId', isEqualTo: uid)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();
      if (historyQuery.docs.isNotEmpty) {
        await historyQuery.docs.first.reference.update({
          'status': 'completed',
          'lockedAt': FieldValue.serverTimestamp(),
          'lockedBy': 'driver',
          'lockLat': currentLat,
          'lockLng': currentLng,
          if (currentPlaceName != null) 'lockPlaceName': currentPlaceName,
        });
      }
    } catch (e) {
      print('Ignored carrier_history update error: $e');
    }

    // Add alert
    try {
      final now = DateTime.now();
      final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      await FirebaseFirestore.instance.collection('alerts').add({
        'type': 'carrier_locked_by_driver',
        'severity': 'info',
        'fleetId': currentFleetId,
        'driverId': uid,
        'deviceId': deviceId,
        'title': 'Carrier Locked',
        'body': 'Carrier has been locked by $driverName at $timeStr',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
        'targetRole': 'admin',
      });
    } catch (e) {
      print('Ignored alert creation error: $e');
    }

    if (fleetId != null) {
      final now = DateTime.now();
      final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      await _notifyAdmins(fleetId, '🔒 Carrier Locked', 'Carrier secured by $driverName at $timeStr');
    }
  }

  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180.0;
  }

  void _showStatsScreen(String title, String statKey, Map<String, dynamic> fleetStats) {
    context.push(AppRoutes.driverStats, extra: {
      'title': title,
      'statKey': statKey,
      'fleetStats': fleetStats,
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen to OTP state changes to navigate when successful
    ref.listen<OTPFlowState>(otpProvider, (previous, next) {
      if (next == OTPFlowState.waitingForAdmin) {
        final user = ref.read(currentUserProvider);
        if (user != null) {
          context.push(AppRoutes.otpHalf1, extra: {
            'requestId': ref.read(otpProvider.notifier).currentReqId,
            'half1': ref.read(otpProvider.notifier).currentHalf1,
            'expiresAt': '',
            'driverId': user.uid,
          });
        }
      } else if (next == OTPFlowState.error || next == OTPFlowState.expired) {
        final errorMsg = ref.read(otpProvider.notifier).lastError ?? 'Failed to request OTP';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg, style: const TextStyle(color: AppColors.white)), backgroundColor: AppColors.red),
        );
      } else if (next == OTPFlowState.hardLocked) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Device is Hard Locked!', style: TextStyle(color: AppColors.white)), backgroundColor: AppColors.red),
        );
      }
    });

    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    final hPad = sw * 0.044;
    final baseUser = ref.watch(currentUserProvider);
    final otpState = ref.watch(otpProvider);
    final isRequestingOtp = otpState == OTPFlowState.requesting;

    if (baseUser == null) {
      return const Scaffold(backgroundColor: AppColors.base, body: Center(child: CircularProgressIndicator(color: AppColors.gold)));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(baseUser.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(backgroundColor: AppColors.base, body: Center(child: CircularProgressIndicator(color: AppColors.gold)));
        }

        final user = UserModel.fromFirestore(snapshot.data!);

        final sw = MediaQuery.of(context).size.width;
        final sh = MediaQuery.of(context).size.height;
        final hPad = sw * 0.044;
        
        final greeting = GreetingUtils.getGreeting();
        final userName = user.name.isNotEmpty == true ? user.name : 'Driver';

        final isUnlocked = user.carrierStatus == 'unlocked';

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final isTracking = ref.read(locationProvider).isTracking;
          if (isUnlocked && !isTracking) {
            ref.read(locationProvider.notifier).startTracking(user.uid);
          } else if (!isUnlocked && isTracking) {
            ref.read(locationProvider.notifier).stopTracking();
          }
        });

        final statusColor = isUnlocked ? AppColors.gold : AppColors.green;
        final statusIcon = isUnlocked ? Icons.lock_open_rounded : Icons.lock_outline_rounded;
        final statusText = isUnlocked ? 'Unlocked · Active' : 'Locked · Secure';

        // Calculate totals
        final fleetStats = user.fleetStats ?? {};
        int totalUnlocks = 0;
        int totalActiveSeconds = 0;
        double totalDistanceKm = 0.0;

        for (var fleetData in fleetStats.values) {
          totalUnlocks += (fleetData['totalUnlocks'] ?? 0) as int;
          totalActiveSeconds += (fleetData['activeTimeSeconds'] ?? 0) as int;
          totalDistanceKm += (fleetData['distanceKm'] ?? 0.0) as double;
        }

        String formattedActiveTime = '0h';
        if (totalActiveSeconds > 0) {
          final hours = totalActiveSeconds ~/ 3600;
          final minutes = (totalActiveSeconds % 3600) ~/ 60;
          if (hours > 0) {
            formattedActiveTime = '${hours}h ${minutes > 0 ? '${minutes}m' : ''}';
          } else {
            formattedActiveTime = '${minutes}m';
          }
        }

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

                    // Header row — greeting + avatar
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(greeting, style: AppTextStyles.greetSub)
                                  .animate()
                                  .fadeIn(duration: 400.ms),
                              const SizedBox(height: 2),
                              Text(
                                'Hey, $userName',
                                style: AppTextStyles.greetName,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              )
                                  .animate()
                                  .fadeIn(delay: 100.ms, duration: 400.ms),
                            ],
                          ),
                        ),
                        // Avatar
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.goldDim,
                            border: Border.all(color: AppColors.goldBorder),
                          ),
                          child: Center(
                            child: Text(
                              userName.isNotEmpty
                                  ? userName[0].toUpperCase()
                                  : 'D',
                              style:
                                  AppTextStyles.fleetId.copyWith(fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: sh * 0.015),

                    // Fleet tag
                    if (user.fleetId != null)
                      _FleetJoinCodeDisplay(
                        fleetId: user.fleetId!,
                        builder: (context, code) => FleetTag(fleetId: code),
                      )
                          .animate()
                          .fadeIn(delay: 200.ms, duration: 400.ms),

                    SizedBox(height: sh * 0.025),

                    // Carrier status card
                    CarrierLockCard(
                      type: CardType.standard,
                      breathing: true,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.goldDim,
                                  border:
                                      Border.all(color: AppColors.goldBorder),
                                ),
                                child: const Icon(Icons.lock_outline_rounded,
                                    color: AppColors.gold, size: 16),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Carrier Status',
                                        style: AppTextStyles.body.copyWith(
                                            fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: statusColor,
                                            boxShadow: [
                                              BoxShadow(
                                                  color: statusColor
                                                      .withValues(alpha: 0.5),
                                                  blurRadius: 4)
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(statusText,
                                            style: AppTextStyles.label.copyWith(
                                                color: statusColor)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text('CURRENT FLEET ID', style: AppTextStyles.sectionLabel),
                          const SizedBox(height: 4),
                          user.fleetId == null
                              ? Text('No Fleet', style: AppTextStyles.fleetId.copyWith(fontSize: 16))
                              : _FleetJoinCodeDisplay(
                                  fleetId: user.fleetId!,
                                  builder: (context, code) => Text(
                                    code,
                                    style: AppTextStyles.fleetId.copyWith(
                                        fontSize: 22, letterSpacing: 8),
                                  ),
                                ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 300.ms, duration: 500.ms)
                        .slideY(begin: 0.05, end: 0),

                    if (isUnlocked) ...[
                      SizedBox(height: sh * 0.02),
                      GoldButton(
                        label: 'Lock Carrier',
                        icon: Icons.lock_outline_rounded,
                        outlined: true,
                        isLoading: _isLocatingForLock,
                        onPressed: () async {
                          final bool? confirm = await showDialog<bool>(
                            context: context,
                            barrierColor: AppColors.base.withOpacity(0.85),
                            builder: (ctx) => AlertDialog(
                              backgroundColor: AppColors.surface2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: const BorderSide(color: AppColors.gold, width: 1),
                              ),
                              icon: const Icon(Icons.lock_outline_rounded, color: AppColors.gold, size: 40),
                              title: Text('Lock Carrier', style: AppTextStyles.screenTitle.copyWith(color: AppColors.gold), textAlign: TextAlign.center),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Are you sure you want to lock the carrier?', style: AppTextStyles.body, textAlign: TextAlign.center),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.gold,
                                        foregroundColor: AppColors.base,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                      ),
                                      child: const Text('Approve', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.gold,
                                        foregroundColor: AppColors.red,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                      ),
                                      child: const Text('Deny', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );

                          if (confirm != true) return;

                          setState(() => _isLocatingForLock = true);
                          try {
                            final locService = ref.read(locationServiceProvider);
                            final position = await Geolocator.getLastKnownPosition();
                            
                            String? placeName = user.placeName;
                            // Only fetch new place name if we don't have one
                            if (position != null && placeName == null) {
                              placeName = await locService.getPlaceName(position.latitude, position.longitude);
                            }
                            
                            if (mounted) {
                              setState(() => _isLocatingForLock = false);
                              _handleLockCarrier(
                                user.uid,
                                user.name,
                                user.deviceId ?? '',
                                position?.latitude ?? 0.0,
                                position?.longitude ?? 0.0,
                                placeName ?? user.placeName,
                                user.fleetId,
                                user.carrierUnlockedAt,
                                user.unlockLat,
                                user.unlockLng,
                                user.fleetStats,
                              );
                            }
                          } catch (e) {
                            if (mounted) setState(() => _isLocatingForLock = false);
                          }
                        },
                      ).animate().fadeIn(duration: 300.ms),
                    ],

                    if (!isUnlocked) ...[
                      SizedBox(height: sh * 0.02),
                      GoldButton(
                        label: 'Request Unlock OTP',
                        icon: Icons.key_rounded,
                        isLoading: isRequestingOtp || _isLocatingForOtp,
                        onPressed: () async {
                          setState(() => _isLocatingForOtp = true);
                          try {
                            final locService = ref.read(locationServiceProvider);
                            final position = await Geolocator.getLastKnownPosition();
                            
                            String? placeName = user.placeName;
                            if (position != null && placeName == null) {
                              placeName = await locService.getPlaceName(position.latitude, position.longitude);
                            }

                            if (mounted) {
                              setState(() => _isLocatingForOtp = false);
                              await ref.read(otpProvider.notifier).requestOTP(
                                driverId: user.uid,
                                deviceId: user.deviceId ?? '',
                                fleetId: user.fleetId ?? '',
                                driverName: user.name,
                                phone: user.phone ?? '',
                                driverLocation: {
                                  'lat': position?.latitude ?? 0.0,
                                  'lng': position?.longitude ?? 0.0,
                                  'placeName': placeName,
                                  'timestamp': FieldValue.serverTimestamp(),
                                },
                              );
                              if (user.fleetId != null) {
                                await _notifyAdmins(user.fleetId!, '🔑 OTP Request', '${user.name} is requesting an unlock OTP for ${user.deviceId ?? "their carrier"}');
                              }
                            }
                          } catch (e) {
                            if (mounted) setState(() => _isLocatingForOtp = false);
                          }
                        },
                      ).animate().fadeIn(duration: 300.ms),
                    ],

                    SizedBox(height: sh * 0.03),

                    // Quick stats
                    Text('QUICK STATS', style: AppTextStyles.sectionLabel)
                        .animate()
                        .fadeIn(delay: 600.ms),
                    SizedBox(height: sh * 0.015),

                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Total Unlocks',
                            value: '$totalUnlocks',
                            icon: Icons.lock_open_rounded,
                            color: AppColors.green,
                            onTap: () => _showStatsScreen('Total Unlocks', 'totalUnlocks', fleetStats),
                          ),
                        ),
                        SizedBox(width: sw * 0.03),
                        Expanded(
                          child: _StatCard(
                            label: 'Active Time',
                            value: formattedActiveTime,
                            icon: Icons.timer_outlined,
                            color: AppColors.gold,
                            onTap: () => _showStatsScreen('Active Time', 'activeTimeSeconds', fleetStats),
                          ),
                        ),
                        SizedBox(width: sw * 0.03),
                        Expanded(
                          child: _StatCard(
                            label: 'Distance',
                            value: totalDistanceKm > 0 ? '${totalDistanceKm.toStringAsFixed(1)}km' : '0km',
                            icon: Icons.route_rounded,
                            color: AppColors.teal,
                            onTap: () => _showStatsScreen('Distance Covered', 'distanceKm', fleetStats),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 700.ms, duration: 400.ms),

                    SizedBox(height: sh * 0.03),

                    // Recent activity
                    Text('RECENT ACTIVITY', style: AppTextStyles.sectionLabel)
                        .animate()
                        .fadeIn(delay: 800.ms),
                    SizedBox(height: sh * 0.015),

                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('alerts')
                          .where('driverId', isEqualTo: user.uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: AppColors.gold));
                        }
                        if (snapshot.hasError) {
                          return Center(child: Text('Error loading activity', style: AppTextStyles.body));
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

                        // Limit to 3 locally
                        if (driverAlerts.length > 3) {
                          driverAlerts = driverAlerts.sublist(0, 3);
                        }

                        if (driverAlerts.isEmpty) {
                          return Center(
                            child: Text('No recent activity',
                                style: AppTextStyles.body.copyWith(color: AppColors.textDimmer)),
                          );
                        }

                        return Column(
                          children: driverAlerts.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final severity = data['severity'] as String? ?? 'info';
                            
                            Color iconColor = AppColors.teal;
                            IconData icon = Icons.info_outline_rounded;
                            
                            if (severity == 'critical') {
                              iconColor = AppColors.red;
                              icon = Icons.error_outline_rounded;
                            } else if (severity == 'warning') {
                              iconColor = AppColors.gold;
                              icon = Icons.warning_amber_rounded;
                            }

                            final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                            final timeString = AppDateUtils.timeAgo(createdAt);

                            return _ActivityItem(
                              icon: icon,
                              iconColor: iconColor,
                              title: data['title'] ?? 'Activity',
                              subtitle: data['body'] ?? '',
                              time: timeString,
                            );
                          }).toList(),
                        );
                      },
                    ).animate().fadeIn(delay: 900.ms, duration: 400.ms),

                    SizedBox(height: sh * 0.1),
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
      },
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
    return GestureDetector(
      onTap: onTap,
      child: CarrierLockCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value,
                  style: AppTextStyles.statNumber
                      .copyWith(fontSize: 20, color: color)),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String time;

  const _ActivityItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.borderFaint),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withValues(alpha: 0.12),
            ),
            child: Icon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.body
                        .copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(subtitle,
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Text(time, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _FleetJoinCodeDisplay extends StatefulWidget {
  final String fleetId;
  final Widget Function(BuildContext, String) builder;

  const _FleetJoinCodeDisplay({required this.fleetId, required this.builder});

  @override
  State<_FleetJoinCodeDisplay> createState() => _FleetJoinCodeDisplayState();
}

class _FleetJoinCodeDisplayState extends State<_FleetJoinCodeDisplay> {
  String? joinCode;

  @override
  void initState() {
    super.initState();
    _fetchCode();
  }
  
  @override
  void didUpdateWidget(_FleetJoinCodeDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fleetId != widget.fleetId) {
      _fetchCode();
    }
  }

  Future<void> _fetchCode() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('fleets').doc(widget.fleetId).get();
      if (doc.exists && mounted) {
        setState(() {
          joinCode = doc.data()?['joinCode'] as String?;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, joinCode ?? widget.fleetId);
  }
}
