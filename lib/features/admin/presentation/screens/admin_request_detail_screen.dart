import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/carrierlock_card.dart';
import '../../../../core/widgets/gold_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../driver/presentation/providers/otp_provider.dart';

/// Admin request detail screen — review an unlock request and approve/deny.
class AdminRequestDetailScreen extends ConsumerStatefulWidget {
  final String requestId;

  const AdminRequestDetailScreen({
    super.key,
    required this.requestId,
  });

  @override
  ConsumerState<AdminRequestDetailScreen> createState() =>
      _AdminRequestDetailScreenState();
}

class _AdminRequestDetailScreenState
    extends ConsumerState<AdminRequestDetailScreen> {
  bool _isApprovingPart1 = false;
  bool _isApprovingPart2 = false;
  bool _isDenying = false;

  void _approvePart1(String adminPart1) async {
    setState(() => _isApprovingPart1 = true);
    try {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        await ref.read(otpProvider.notifier).approveRequestPart1(
          reqId: widget.requestId,
          adminPart1: adminPart1,
          adminId: user.uid,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Part 1 Approved & Sent.'), backgroundColor: AppColors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isApprovingPart1 = false);
    }
  }

  void _approvePart2(String adminPart2, String fleetId, String driverId, String deviceId) async {
    setState(() => _isApprovingPart2 = true);
    try {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        await ref.read(otpProvider.notifier).approveRequestPart2(
          reqId: widget.requestId,
          adminPart2: adminPart2,
          adminId: user.uid,
          fleetId: fleetId,
          driverId: driverId,
          deviceId: deviceId,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Part 2 Approved. OTP Complete.'), backgroundColor: AppColors.green),
          );
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isApprovingPart2 = false);
    }
  }

  void _deny(String fleetId, String driverId, String deviceId) async {
    setState(() => _isDenying = true);
    try {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        await ref.read(otpProvider.notifier).denyRequest(
          reqId: widget.requestId,
          adminId: user.uid,
          fleetId: fleetId,
          driverId: driverId,
          deviceId: deviceId,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Request Denied.'), backgroundColor: AppColors.gold),
          );
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isDenying = false);
    }
  }

  Widget _buildOTPBox(String digit) {
    return Container(
      width: 45,
      height: 55,
      decoration: BoxDecoration(
        color: AppColors.tealDim,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.tealBorder),
      ),
      child: Center(
        child: Text(
          digit,
          style: AppTextStyles.otpDigit.copyWith(
            fontSize: 24,
            color: AppColors.teal,
          ),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchDetails() async {
    final reqDoc = await FirebaseFirestore.instance.collection('unlock_requests').doc(widget.requestId).get();
    if (!reqDoc.exists) return {};
    final reqData = reqDoc.data()!;
    
    final adminDoc = await FirebaseFirestore.instance.collection('unlock_requests').doc(widget.requestId).collection('admin_data').doc('otp').get();
    
    final driverDoc = await FirebaseFirestore.instance.collection('users').doc(reqData['driverId']).get();
    final fleetDoc = await FirebaseFirestore.instance.collection('fleets').doc(reqData['fleetId']).get();
    
    return {
      'req': reqData,
      'admin': adminDoc.exists ? adminDoc.data() : {},
      'driver': driverDoc.exists ? driverDoc.data() : {},
      'fleet': fleetDoc.exists ? fleetDoc.data() : {},
    };
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    final hPad = sw * 0.06;

    return Scaffold(
      backgroundColor: AppColors.base,
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _fetchDetails(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.gold));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('Request not found or expired', style: AppTextStyles.body));
            }

            final data = snapshot.data!;
            final reqData = data['req'] as Map<String, dynamic>;
            final adminData = data['admin'] as Map<String, dynamic>;
            final driverData = data['driver'] as Map<String, dynamic>;
            final fleetData = data['fleet'] as Map<String, dynamic>;

            // Use driver profile data as primary source of truth, fallback to request data
            final driverName = driverData['name'] as String? ?? reqData['driverName'] as String? ?? 'Unknown';
            final phone = driverData['phone'] as String? ?? reqData['phone'] as String? ?? 'Unknown Phone';
            final fleetId = fleetData['joinCode'] as String? ?? reqData['fleetId'] as String? ?? '';
            
            final deviceId = reqData['deviceId'] ?? 'Unknown';
            final originalFleetId = reqData['fleetId'] ?? '';
            final driverId = reqData['driverId'] ?? '';

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: sh * 0.02),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
                      Text('Review Request', style: AppTextStyles.screenTitle.copyWith(color: AppColors.teal)),
                    ],
                  ),
                  SizedBox(height: sh * 0.04),

                  // Driver Info Card
                  Text('DRIVER INFO', style: AppTextStyles.sectionLabel),
                  const SizedBox(height: 12),
                  CarrierLockCard(
                    type: CardType.standard,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.goldDim,
                            border: Border.all(color: AppColors.goldBorder),
                          ),
                          child: Center(
                              child: Text(driverName.isNotEmpty ? driverName[0].toUpperCase() : 'D',
                                  style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold))),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(driverName, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text(phone, style: AppTextStyles.label.copyWith(color: AppColors.textDimmer)),
                              const SizedBox(height: 4),
                              Text('Fleet: $fleetId', style: AppTextStyles.label),
                              Text(deviceId, style: AppTextStyles.caption.copyWith(color: AppColors.teal)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn().slideY(begin: 0.1),

                  SizedBox(height: sh * 0.04),

                  // Real-time listener for the unlock request
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('unlock_requests').doc(widget.requestId).snapshots(),
                    builder: (context, reqSnapshot) {
                      if (!reqSnapshot.hasData) return const SizedBox();
                      final rtReqData = reqSnapshot.data!.data() as Map<String, dynamic>? ?? {};
                      
                      final adminApprovedPart1 = rtReqData['adminApprovedPart1'] == true;
                      final driverReceivedPart1 = rtReqData['driverReceivedPart1'] == true;
                      final adminApprovedPart2 = rtReqData['adminApprovedPart2'] == true;
                      
                      final adminPart1 = adminData['adminPart1'] as String? ?? '   ';
                      final adminPart2 = adminData['adminPart2'] as String? ?? '  ';

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Part 1 Display
                          Text('PART 1 TO SEND (3 Digits)', style: AppTextStyles.sectionLabel),
                          const SizedBox(height: 12),
                          CarrierLockCard(
                            type: adminApprovedPart1 ? CardType.standard : CardType.gold,
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildOTPBox(adminPart1.length > 0 ? adminPart1[0] : ' '),
                                const SizedBox(width: 8),
                                _buildOTPBox(adminPart1.length > 1 ? adminPart1[1] : ' '),
                                const SizedBox(width: 8),
                                _buildOTPBox(adminPart1.length > 2 ? adminPart1[2] : ' '),
                              ],
                            ),
                          ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.95, 0.95)),

                          const SizedBox(height: 16),
                          
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton.icon(
                              onPressed: adminApprovedPart1 || _isApprovingPart1 ? null : () => _approvePart1(adminPart1),
                              icon: _isApprovingPart1
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : Icon(adminApprovedPart1 ? Icons.check_circle_rounded : Icons.send_rounded, color: Colors.white, size: 18),
                              label: Text(adminApprovedPart1 ? 'Part 1 Sent' : 'Approve & Send Part 1', style: AppTextStyles.buttonText.copyWith(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: adminApprovedPart1 ? AppColors.tealDim : AppColors.teal,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: AppColors.tealDim,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                              ),
                            ),
                          ),

                          SizedBox(height: sh * 0.04),

                          // Part 2 Display
                          Text('PART 2 TO SEND (2 Digits)', style: AppTextStyles.sectionLabel),
                          const SizedBox(height: 12),
                          CarrierLockCard(
                            type: driverReceivedPart1 && !adminApprovedPart2 ? CardType.gold : CardType.standard,
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildOTPBox(adminPart2.length > 0 ? adminPart2[0] : ' '),
                                const SizedBox(width: 8),
                                _buildOTPBox(adminPart2.length > 1 ? adminPart2[1] : ' '),
                              ],
                            ),
                          ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.95, 0.95)),

                          const SizedBox(height: 16),
                          
                          if (adminApprovedPart1 && !driverReceivedPart1)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text('Waiting for driver to receive Part 1...', style: AppTextStyles.caption.copyWith(color: AppColors.gold, fontStyle: FontStyle.italic)),
                            ),

                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton.icon(
                              onPressed: (!driverReceivedPart1) || adminApprovedPart2 || _isApprovingPart2 ? null : () => _approvePart2(adminPart2, originalFleetId, driverId, deviceId),
                              icon: _isApprovingPart2
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : Icon(adminApprovedPart2 ? Icons.check_circle_rounded : Icons.send_rounded, color: Colors.white, size: 18),
                              label: Text(adminApprovedPart2 ? 'Part 2 Sent' : 'Approve & Send Part 2', style: AppTextStyles.buttonText.copyWith(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: (!driverReceivedPart1) || adminApprovedPart2 ? AppColors.tealDim : AppColors.teal,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: AppColors.tealDim,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                              ),
                            ),
                          ),
                          
                          SizedBox(height: sh * 0.04),

                          // Deny Button
                          if (!adminApprovedPart1)
                            SizedBox(
                              width: double.infinity,
                              child: GoldButton(
                                label: 'Deny Request',
                                icon: Icons.close_rounded,
                                outlined: true,
                                isLoading: _isDenying,
                                onPressed: _isApprovingPart1 ? null : () => _deny(originalFleetId, driverId, deviceId),
                              ),
                            ),
                            
                          SizedBox(height: sh * 0.04),
                        ],
                      );
                    }
                  ),
                ],
              ),
            );
          }
        ),
      ),
    );
  }
}
