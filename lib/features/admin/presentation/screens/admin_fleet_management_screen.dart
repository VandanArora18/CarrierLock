import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/gold_button.dart';
import '../../../../core/widgets/carrierlock_card.dart';
import '../../../../core/router/app_router.dart';

/// Screen to manage a fleet's details and drivers.
class AdminFleetManagementScreen extends StatelessWidget {
  const AdminFleetManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final hPad = sw * 0.044;

    return Scaffold(
      backgroundColor: AppColors.base,
      appBar: AppBar(
        title: const Text('Fleet Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.push(AppRoutes.adminCreateFleet),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CarrierLockCard(
              type: CardType.gold,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Alpha Logistics',
                          style:
                              AppTextStyles.screenTitle.copyWith(fontSize: 20)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.goldDim,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.goldBorder),
                        ),
                        child: Text('FLT-4821', style: AppTextStyles.fleetId),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Primary transport fleet for northern routes.',
                      style: AppTextStyles.body),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.people_alt_rounded,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text('14 Drivers', style: AppTextStyles.label),
                      const SizedBox(width: 16),
                      const Icon(Icons.admin_panel_settings_rounded,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text('2 Admins', style: AppTextStyles.label),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text('FLEET ACTIONS', style: AppTextStyles.sectionLabel),
            const SizedBox(height: 16),
            GoldButton(
              label: 'View All Drivers',
              icon: Icons.list_rounded,
              outlined: true,
              onPressed: () => context.push(AppRoutes.adminAllDrivers),
            ),
            const SizedBox(height: 12),
            GoldButton(
              label: 'Invite New Driver',
              icon: Icons.person_add_rounded,
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
