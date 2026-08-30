import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/gold_button.dart';
import '../../../../core/router/app_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Waiting for admin approval — shows 4-digit code entry after approval
class DriverWaitingApprovalScreen extends ConsumerStatefulWidget {
  final String pendingAuthId;
  final String driverUid;
  final String fleetId;
  final String driverName;

  const DriverWaitingApprovalScreen({
    super.key,
    required this.pendingAuthId,
    required this.driverUid,
    required this.fleetId,
    required this.driverName,
  });

  @override
  ConsumerState<DriverWaitingApprovalScreen> createState() =>
      _DriverWaitingApprovalScreenState();
}

class _DriverWaitingApprovalScreenState
    extends ConsumerState<DriverWaitingApprovalScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<TextEditingController> _codeControllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _codeFocusNodes =
      List.generate(4, (_) => FocusNode());

  bool _isApproved = false;
  bool _isRejected = false;
  bool _isVerifying = false;
  String? _errorMessage;
  String? _approvalCode; // set when admin approves

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation =
        Tween<double>(begin: 0.7, end: 1.0).animate(_pulseController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    for (final c in _codeControllers) c.dispose();
    for (final f in _codeFocusNodes) f.dispose();
    super.dispose();
  }

  String get _enteredCode => _codeControllers.map((c) => c.text).join();

  Future<void> _verifyApprovalCode() async {
    if (_enteredCode.length < 4) {
      setState(() => _errorMessage = 'Enter the complete 4-digit code');
      return;
    }
    if (_approvalCode == null) {
      setState(() => _errorMessage = 'Approval code not received yet');
      return;
    }
    if (_enteredCode != _approvalCode) {
      setState(() => _errorMessage = 'Incorrect code. Try again.');
      return;
    }

    setState(() { _isVerifying = true; _errorMessage = null; });

    try {
      // Mark driver as fully approved
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.driverUid)
          .update({
        'approvalStatus': 'approved',
        'isOnline': true,
      });

      // Mark pending auth as complete
      await FirebaseFirestore.instance
          .collection('pending_driver_auth')
          .doc(widget.pendingAuthId)
          .update({'status': 'approved'});

      // Load user profile into provider
      await ref.read(authProvider.notifier).reloadUser();

      if (!mounted) return;
      context.go(AppRoutes.driverHome);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isVerifying = false;
      });
    }
  }

  Widget _buildCodeBox(int index) {
    return SizedBox(
      width: 62,
      height: 72,
      child: TextFormField(
        controller: _codeControllers[index],
        focusNode: _codeFocusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.teal,
        ),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.teal, width: 2.5),
          ),
          filled: true,
          fillColor: AppColors.surface1,
        ),
        onChanged: (val) {
          if (val.isNotEmpty && index < 3) {
            _codeFocusNodes[index + 1].requestFocus();
          }
          if (val.isEmpty && index > 0) {
            _codeFocusNodes[index - 1].requestFocus();
          }
          setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    final hPad = sw * 0.06;

    return Scaffold(
      backgroundColor: AppColors.base,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('pending_driver_auth')
              .doc(widget.pendingAuthId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!.exists) {
              final data =
                  snapshot.data!.data() as Map<String, dynamic>;
              final status = data['status'] as String? ?? 'pending';

              if (status == 'rejected' && !_isRejected) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  setState(() => _isRejected = true);
                });
              }

              if (status == 'approved' && !_isApproved) {
                final code = data['approvalCode'] as String?;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  setState(() {
                    _isApproved = true;
                    _approvalCode = code;
                  });
                });
              }
            }

            // ── REJECTED STATE ──────────────────────────────────────
            if (_isRejected) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.redDim,
                        border: Border.all(color: AppColors.redBorder, width: 2),
                      ),
                      child: const Icon(Icons.cancel_rounded,
                          color: AppColors.red, size: 36),
                    ),
                    const SizedBox(height: 20),
                    Text('Request Rejected',
                        style: AppTextStyles.screenTitle
                            .copyWith(color: AppColors.red)),
                    const SizedBox(height: 10),
                    Text(
                      'Your admin has rejected this login request.\nPlease contact your fleet manager.',
                      style: AppTextStyles.label,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    GoldButton(
                      label: 'Go Back',
                      icon: Icons.arrow_back_rounded,
                      onPressed: () => context.go(AppRoutes.driverLogin),
                    ),
                  ],
                ),
              );
            }

            // ── APPROVED — Enter 4-digit code ────────────────────────
            if (_isApproved) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: sh * 0.08),
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.tealDim,
                        border:
                            Border.all(color: AppColors.teal, width: 2),
                      ),
                      child: const Icon(Icons.check_circle_rounded,
                          color: AppColors.teal, size: 36),
                    ),
                    const SizedBox(height: 20),
                    Text('Admin Approved!',
                        style: AppTextStyles.screenTitle
                            .copyWith(color: AppColors.teal)),
                    const SizedBox(height: 10),
                    Text(
                      'Enter the 4-digit code your admin shared with you to complete login.',
                      style: AppTextStyles.label,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: sh * 0.05),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (int i = 0; i < 4; i++) ...[
                          _buildCodeBox(i),
                          if (i < 3) const SizedBox(width: 12),
                        ]
                      ],
                    ),
                    SizedBox(height: sh * 0.035),
                    if (_errorMessage != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.redDim,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.redBorder),
                        ),
                        child:
                            Text(_errorMessage!, style: AppTextStyles.error),
                      ),
                    GoldButton(
                      label: 'Enter Fleet',
                      icon: Icons.login_rounded,
                      isLoading: _isVerifying,
                      onPressed:
                          _enteredCode.length == 4 ? _verifyApprovalCode : null,
                    ),
                  ],
                ),
              );
            }

            // ── WAITING STATE ────────────────────────────────────────
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.goldDim,
                        border:
                            Border.all(color: AppColors.goldBorder, width: 2),
                      ),
                      child: const Icon(Icons.hourglass_top_rounded,
                          color: AppColors.gold, size: 38),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Waiting for Approval',
                      style: AppTextStyles.screenTitle),
                  const SizedBox(height: 12),
                  Text(
                    'Your admin has been notified.\nThey will approve or reject your request.',
                    style: AppTextStyles.label,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  // Driver info card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface1,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderFaint),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.person_outline_rounded,
                              color: AppColors.gold, size: 16),
                          const SizedBox(width: 8),
                          Text('Driver', style: AppTextStyles.sectionLabel),
                        ]),
                        const SizedBox(height: 6),
                        Text(widget.driverName,
                            style: AppTextStyles.body
                                .copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Row(children: [
                          const Icon(Icons.directions_car_outlined,
                              color: AppColors.gold, size: 16),
                          const SizedBox(width: 8),
                          Text('Fleet', style: AppTextStyles.sectionLabel),
                        ]),
                        const SizedBox(height: 6),
                        Text(widget.fleetId,
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.teal)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.gold),
                  ),
                  const SizedBox(height: 12),
                  Text('Listening for admin response...',
                      style: AppTextStyles.caption),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
