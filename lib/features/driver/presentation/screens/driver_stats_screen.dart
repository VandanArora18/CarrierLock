import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DriverStatsScreen extends ConsumerStatefulWidget {
  final String title;
  final String statKey;
  final Map<String, dynamic> fleetStats;

  const DriverStatsScreen({
    super.key,
    required this.title,
    required this.statKey,
    required this.fleetStats,
  });

  @override
  ConsumerState<DriverStatsScreen> createState() => _DriverStatsScreenState();
}

class _DriverStatsScreenState extends ConsumerState<DriverStatsScreen> {
  // We need to resolve fleet IDs to join codes.
  final Map<String, String> _resolvedCodes = {};

  @override
  void initState() {
    super.initState();
    _resolveCodes();
  }

  Future<void> _resolveCodes() async {
    for (String fleetId in widget.fleetStats.keys) {
      try {
        final doc = await FirebaseFirestore.instance.collection('fleets').doc(fleetId).get();
        if (doc.exists) {
          final code = doc.data()?['joinCode'] as String?;
          if (code != null) {
            if (mounted) {
              setState(() {
                _resolvedCodes[fleetId] = code;
              });
            }
          }
        }
      } catch (_) {}
    }
  }

  String _formatStat(dynamic value) {
    if (widget.statKey == 'totalUnlocks') {
      return value.toString();
    } else if (widget.statKey == 'activeTimeSeconds') {
      final secs = value as int;
      if (secs == 0) return '0h';
      final h = secs ~/ 3600;
      final m = (secs % 3600) ~/ 60;
      return h > 0 ? '${h}h ${m}m' : '${m}m';
    } else if (widget.statKey == 'distanceKm') {
      return '${(value as double).toStringAsFixed(1)}km';
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final fleets = widget.fleetStats.keys.toList();

    return Scaffold(
      backgroundColor: AppColors.base,
      appBar: AppBar(
        backgroundColor: AppColors.base,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(widget.title, style: AppTextStyles.screenTitle),
      ),
      body: SafeArea(
        child: widget.fleetStats.isEmpty
            ? Center(
                child: Text('No ${widget.title.toLowerCase()} recorded.',
                    style: AppTextStyles.body, textAlign: TextAlign.center),
              )
            : ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: fleets.length,
                separatorBuilder: (ctx, i) => const Divider(color: AppColors.borderFaint, height: 1),
                itemBuilder: (ctx, i) {
                  final fleetId = fleets[i];
                  final stats = widget.fleetStats[fleetId];
                  final val = stats[widget.statKey] ?? 0;
                  final displayCode = _resolvedCodes[fleetId] ?? fleetId;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.goldDim,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.goldBorder),
                      ),
                      child: const Icon(Icons.numbers_rounded, color: AppColors.gold, size: 20),
                    ),
                    title: Text(displayCode, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600, fontSize: 18, letterSpacing: 2)),
                    trailing: Text(_formatStat(val), style: AppTextStyles.statNumber.copyWith(fontSize: 18)),
                  );
                },
              ),
      ),
    );
  }
}
