import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import 'package:go_router/go_router.dart';

/// Shows full driver details for an admin: name, fleet ID, phone, locations, hard lock.
class AdminDriverDetailScreen extends StatelessWidget {
  final String driverId;
  const AdminDriverDetailScreen({super.key, required this.driverId});

  void _openMaps(BuildContext context, double lat, double lng) {
    // Use MethodChannel to open Google Maps on Android
    const platform = MethodChannel('com.carrierlock.app/maps');
    platform.invokeMethod('openMaps', {'lat': lat, 'lng': lng}).catchError((_) {
      // Fallback: copy coordinates to clipboard
      Clipboard.setData(ClipboardData(text: '$lat, $lng'));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Coordinates copied to clipboard'),
          backgroundColor: AppColors.teal,
        ),
      );
    });
  }

  Future<String?> _getFleetShortId(String? fleetId) async {
    if (fleetId == null) return null;
    try {
      final doc = await FirebaseFirestore.instance.collection('fleets').doc(fleetId).get();
      final data = doc.data();
      return data?['joinCode']?.toString();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.base,
      appBar: AppBar(
        title: const Text('Driver Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(driverId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.teal));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Driver not found'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final name = data['name'] ?? 'Unknown';
          final phone = data['phone'] ?? 'N/A';
          final fleetId = data['fleetId'] as String?;
          final carrierStatus = data['carrierStatus'] ?? 'locked';

          // Unlock location
          final unlockLat = data['unlockLat']?.toDouble();
          final unlockLng = data['unlockLng']?.toDouble();
          final unlockPlaceName = data['unlockPlaceName'] as String?;

          // Lock location
          final lockLat = data['lockLat']?.toDouble();
          final lockLng = data['lockLng']?.toDouble();
          final lockPlaceName = data['lockPlaceName'] as String?;

          return FutureBuilder<String?>(
            future: _getFleetShortId(fleetId),
            builder: (context, fleetSnap) {
              final fleetShortId = fleetSnap.data ?? (fleetId?.length == 4 ? fleetId : 'N/A');

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Driver Header
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.tealDim,
                              border: Border.all(color: AppColors.tealBorder, width: 2),
                            ),
                            child: Center(
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  color: AppColors.teal,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(name, style: AppTextStyles.screenTitle.copyWith(fontSize: 22)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: carrierStatus == 'unlocked' ? AppColors.tealDim : AppColors.surface2,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: carrierStatus == 'unlocked' ? AppColors.tealBorder : AppColors.borderFaint,
                              ),
                            ),
                            child: Text(
                              carrierStatus == 'unlocked' ? '● Carrier Unlocked' : '● Carrier Locked',
                              style: AppTextStyles.label.copyWith(
                                color: carrierStatus == 'unlocked' ? AppColors.teal : AppColors.textDimmer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Info Cards
                    _InfoCard(
                      label: 'FLEET ID',
                      icon: Icons.tag_rounded,
                      value: fleetShortId ?? 'N/A',
                      valueColor: AppColors.gold,
                    ),
                    const SizedBox(height: 12),
                    _InfoCard(
                      label: 'PHONE NUMBER',
                      icon: Icons.phone_rounded,
                      value: phone,
                    ),

                    const SizedBox(height: 24),
                    Text('LOCATIONS', style: AppTextStyles.sectionLabel),
                    const SizedBox(height: 12),

                    // Unlock Location
                    if (carrierStatus == 'unlocked')
                      _LocationCard(
                        label: 'Unlocked At',
                        placeName: unlockPlaceName ??
                            (unlockLat != null
                                ? '${unlockLat.toStringAsFixed(5)}, ${unlockLng?.toStringAsFixed(5)}'
                                : 'Not recorded'),
                        color: AppColors.teal,
                        borderColor: AppColors.tealBorder,
                        bgColor: AppColors.tealDim,
                        icon: Icons.lock_open_rounded,
                        onMapTap: unlockLat != null && unlockLng != null
                            ? () => _openMaps(context, unlockLat, unlockLng!)
                            : null,
                      ),
                    
                    if (carrierStatus == 'unlocked' && carrierStatus == 'locked') // just to manage spacing correctly if we only show one
                      const SizedBox(height: 12),

                    // Lock Location
                    if (carrierStatus == 'locked')
                      _LocationCard(
                        label: 'Locked At',
                        placeName: lockPlaceName ??
                            (lockLat != null
                                ? '${lockLat.toStringAsFixed(5)}, ${lockLng?.toStringAsFixed(5)}'
                                : 'Not recorded'),
                        color: AppColors.gold,
                        borderColor: AppColors.goldBorder,
                        bgColor: AppColors.goldDim,
                        icon: Icons.lock_rounded,
                        onMapTap: lockLat != null && lockLng != null
                            ? () => _openMaps(context, lockLat, lockLng!)
                            : null,
                      ),

                    const SizedBox(height: 32),

                    // Hard Lock Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.lock_outline_rounded, color: Colors.white),
                        label: const Text(
                          'Hard Lock Device',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.red,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          context.push(
                            AppRoutes.adminHardLockConfirm,
                            extra: {
                              'driverId': driverId,
                              'driverName': name,
                              'fleetId': fleetId ?? '',
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
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

class _InfoCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final Color? valueColor;

  const _InfoCard({
    required this.label,
    required this.icon,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderFaint),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.textSecondary, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.sectionLabel.copyWith(fontSize: 10)),
              const SizedBox(height: 3),
              Text(
                value,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? AppColors.textPrimary,
                  fontSize: 18,
                  letterSpacing: valueColor != null ? 4 : 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final String label;
  final String placeName;
  final Color color;
  final Color borderColor;
  final Color bgColor;
  final IconData icon;
  final VoidCallback? onMapTap;

  const _LocationCard({
    required this.label,
    required this.placeName,
    required this.color,
    required this.borderColor,
    required this.bgColor,
    required this.icon,
    this.onMapTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTextStyles.sectionLabel.copyWith(fontSize: 10, color: color)),
                const SizedBox(height: 2),
                Text(
                  placeName,
                  style: AppTextStyles.body.copyWith(fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onMapTap != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onMapTap,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                child: Icon(Icons.map_rounded, color: color, size: 18),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
