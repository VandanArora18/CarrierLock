import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/carrierlock_card.dart';

/// Screen for the admin to initiate a remote fallback unlock.
class AdminFallbackScreen extends StatefulWidget {
  const AdminFallbackScreen({super.key});

  @override
  State<AdminFallbackScreen> createState() => _AdminFallbackScreenState();
}

class _AdminFallbackScreenState extends State<AdminFallbackScreen> {
  final _deviceController = TextEditingController();
  bool _isSending = false;

  void _sendFallback() {
    if (_deviceController.text.isEmpty) return;

    setState(() => _isSending = true);

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isSending = false);
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface1,
            title: const Text('Fallback Sent',
                style: TextStyle(color: AppColors.gold)),
            content: Text(
                'A remote unlock command was sent to ${_deviceController.text}.',
                style: AppTextStyles.body),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.pop();
                },
                child:
                    const Text('OK', style: TextStyle(color: AppColors.gold)),
              ),
            ],
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _deviceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    final hPad = sw * 0.06;

    return Scaffold(
      backgroundColor: AppColors.base,
      appBar: AppBar(
        title: Text('Remote Fallback',
            style: AppTextStyles.screenTitle.copyWith(color: AppColors.amber)),
        iconTheme: const IconThemeData(color: AppColors.amber),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: hPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: sh * 0.04),
            CarrierLockCard(
              type: CardType.amber,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: AppColors.amber, size: 28),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Use this only when the driver is unreachable or the device is unresponsive.',
                        style: AppTextStyles.body,
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn().slideY(begin: 0.1),
            SizedBox(height: sh * 0.04),
            Text('TARGET DEVICE ID', style: AppTextStyles.sectionLabel),
            const SizedBox(height: 8),
            TextField(
              controller: _deviceController,
              style: AppTextStyles.inputText,
              decoration: const InputDecoration(
                hintText: 'e.g. DEV-042',
                prefixIcon:
                    Icon(Icons.router_rounded, color: AppColors.textSecondary),
              ),
            ).animate().fadeIn(delay: 100.ms),
            SizedBox(height: sh * 0.06),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: _isSending ? null : _sendFallback,
                icon: _isSending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.base))
                    : const Icon(Icons.cell_tower_rounded,
                        color: AppColors.base, size: 18),
                label: Text('Send Fallback Unlock',
                    style: AppTextStyles.buttonText
                        .copyWith(color: AppColors.base)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.amber,
                  foregroundColor: AppColors.base,
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
