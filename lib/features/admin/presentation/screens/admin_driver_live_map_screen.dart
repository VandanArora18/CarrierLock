import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/carrierlock_card.dart';
import '../../../../core/widgets/live_pulse.dart';
import '../../../../core/router/app_router.dart';
import '../providers/driver_location_stream_provider.dart';

/// Screen to view a specific driver's live location.
class AdminDriverLiveMapScreen extends ConsumerWidget {
  final String driverId;
  final String driverName;

  const AdminDriverLiveMapScreen({
    super.key,
    required this.driverId,
    required this.driverName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    final locationAsync = ref.watch(driverLocationStreamProvider(driverId));

    return Scaffold(
      backgroundColor: AppColors.base,
      appBar: AppBar(
        title: Text('Tracking $driverName'),
      ),
      body: Stack(
        children: [
          // Map Background
          SizedBox(
            width: sw,
            height: sh,
            child: locationAsync.when(
              data: (location) {
                if (location == null) {
                  return const Center(
                    child: Text('Waiting for GPS signal...', style: TextStyle(color: AppColors.textSecondary)),
                  );
                }
                return FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(location.latitude, location.longitude),
                    initialZoom: 15.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.carrierlock.app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(location.latitude, location.longitude),
                          width: 40,
                          height: 40,
                          child: const LivePulse(size: 20, color: AppColors.teal),
                        ),
                      ],
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.teal)),
              error: (e, st) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.red))),
            ),
          ),

          // Info overlay at bottom
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: CarrierLockCard(
              type: CardType.teal,
              padding: const EdgeInsets.all(20),
              child: locationAsync.when(
                data: (location) {
                  final isOnline = location != null && DateTime.now().difference(location.updatedAt).inMinutes < 5;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(driverName,
                              style: AppTextStyles.body
                                  .copyWith(fontWeight: FontWeight.bold)),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isOnline ? AppColors.green : AppColors.red,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(isOnline ? 'Online' : 'Offline',
                                  style: AppTextStyles.caption
                                      .copyWith(color: isOnline ? AppColors.green : AppColors.red)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: AppColors.borderFaint),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.speed_rounded,
                              size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Text(location != null ? '${(location.speed * 3.6).toStringAsFixed(1)} km/h' : '-- km/h', style: AppTextStyles.label),
                          const SizedBox(width: 24),
                          const Icon(Icons.location_on_rounded,
                              size: 16, color: AppColors.teal),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              location != null ? '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}' : 'Unknown Location',
                              style: AppTextStyles.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.base)),
                error: (e, st) => const SizedBox(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
