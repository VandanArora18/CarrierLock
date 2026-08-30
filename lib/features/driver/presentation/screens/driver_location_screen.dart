import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/carrierlock_card.dart';
import '../../../../core/widgets/live_pulse.dart';
import '../providers/location_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Driver location status screen.
class DriverLocationScreen extends ConsumerStatefulWidget {
  const DriverLocationScreen({super.key});

  @override
  ConsumerState<DriverLocationScreen> createState() => _DriverLocationScreenState();
}

class _DriverLocationScreenState extends ConsumerState<DriverLocationScreen> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(locationProvider.notifier).requestLocation();
      final user = ref.read(currentUserProvider);
      if (user != null) {
        ref.read(locationProvider.notifier).startTracking(user.uid);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final hPad = sw * 0.044;
    final locationState = ref.watch(locationProvider);

    return Scaffold(
      backgroundColor: AppColors.base,
      appBar: AppBar(
        title: const Text('Live Tracking'),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CarrierLockCard(
              type: CardType.standard,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  LivePulse(size: 20, color: locationState.isTracking ? AppColors.green : AppColors.red),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(locationState.isTracking ? 'Status: Active Tracking' : 'Status: Inactive',
                            style: AppTextStyles.body
                                .copyWith(color: locationState.isTracking ? AppColors.green : AppColors.red)),
                        Text('Location shared with Fleet Admin',
                            style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface1,
                    border: Border.all(color: AppColors.borderFaint),
                  ),
                  child: locationState.currentPosition == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(color: AppColors.gold),
                              const SizedBox(height: 16),
                              Text(locationState.error ?? 'Acquiring GPS Signal...',
                                  style: AppTextStyles.label
                                      .copyWith(color: AppColors.textSecondary)),
                            ],
                          ),
                        )
                      : FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: LatLng(
                              locationState.currentPosition!.latitude,
                              locationState.currentPosition!.longitude,
                            ),
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
                                  point: LatLng(
                                    locationState.currentPosition!.latitude,
                                    locationState.currentPosition!.longitude,
                                  ),
                                  width: 40,
                                  height: 40,
                                  child: const LivePulse(size: 20, color: AppColors.teal),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
