import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/carrierlock_card.dart';

/// Screen to reset a hard-locked device.
class AdminHardlockResetScreen extends StatefulWidget {
  final String deviceId;
  final String driverId;
  final String fleetId;

  const AdminHardlockResetScreen({
    super.key,
    required this.deviceId,
    required this.driverId,
    required this.fleetId,
  });

  @override
  State<AdminHardlockResetScreen> createState() =>
      _AdminHardlockResetScreenState();
}

class _AdminHardlockResetScreenState extends State<AdminHardlockResetScreen> {
  bool _isResetting = false;

  void _resetDevice() {
    setState(() => _isResetting = true);

    // Simulate API call to Cloud Function
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isResetting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Device ${widget.deviceId} successfully reset.')),
        );
        context.pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    final hPad = sw * 0.06;

    return Scaffold(
      backgroundColor: AppColors.base,
      appBar: AppBar(
        title: Text('Reset Device',
            style: AppTextStyles.screenTitle.copyWith(color: AppColors.red)),
        iconTheme: const IconThemeData(color: AppColors.red),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: hPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: sh * 0.04),
            CarrierLockCard(
              type: CardType.red,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lock_rounded,
                            color: AppColors.red, size: 24),
                        const SizedBox(width: 12),
                        Text('DEVICE IS HARD-LOCKED',
                            style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.red)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'This device exceeded the maximum number of failed OTP attempts. It requires a manual reset before the driver can request a new unlock OTP.',
                      style: AppTextStyles.body,
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn().slideY(begin: 0.1),
            SizedBox(height: sh * 0.04),
            Text('DEVICE INFO', style: AppTextStyles.sectionLabel),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderFaint),
              ),
              child: Column(
                children: [
                  _InfoRow(label: 'Device ID', value: widget.deviceId),
                  const Divider(color: AppColors.borderFaint, height: 24),
                  _InfoRow(label: 'Assigned Driver', value: widget.driverId),
                  const Divider(color: AppColors.borderFaint, height: 24),
                  _InfoRow(label: 'Fleet ID', value: widget.fleetId),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms),
            SizedBox(height: sh * 0.06),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: _isResetting ? null : _resetDevice,
                icon: _isResetting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.restart_alt_rounded,
                        color: Colors.white, size: 18),
                label: Text('Reset Device State',
                    style:
                        AppTextStyles.buttonText.copyWith(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11)),
                ),
              ),
            ).animate().fadeIn(delay: 200.ms),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
        Text(value,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
