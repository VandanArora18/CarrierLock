import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/pdf_service.dart';

class AdminHistoryDetailScreen extends StatelessWidget {
  final DocumentSnapshot historyDoc;

  const AdminHistoryDetailScreen({super.key, required this.historyDoc});

  Future<void> _openMaps(BuildContext context, double lat, double lng) async {
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps', style: TextStyle(color: Colors.white)), backgroundColor: AppColors.red),
        );
      }
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: AppColors.base.withOpacity(0.85),
      builder: (ctx) {
        final driverName = (historyDoc.data() as Map<String, dynamic>)['driverName'] ?? 'Driver';
        return AlertDialog(
          backgroundColor: AppColors.surface2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.red, width: 1),
          ),
          icon: const Icon(Icons.warning_amber_rounded, color: AppColors.red, size: 40),
          title: Text('Delete History', style: AppTextStyles.screenTitle.copyWith(color: AppColors.red), textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Are you sure you want to delete\n$driverName\'s history record?', style: AppTextStyles.body, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await historyDoc.reference.delete();
                    if (context.mounted) context.pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.red,
                    foregroundColor: Colors.white,
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
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surface1,
                    foregroundColor: AppColors.textPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Denied', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = historyDoc.data() as Map<String, dynamic>;
    final driverName = data['driverName'] ?? 'Unknown';
    final fleetId = data['fleetId'] ?? '';
    final phone = data['phone'] ?? 'N/A';
    final email = data['email'] ?? 'N/A';
    
    // 4 digit fleet code
    final fleetShortId = fleetId.length >= 4 ? fleetId.substring(0, 4).toUpperCase() : fleetId.toUpperCase();

    final dateFormat = DateFormat('MMM dd, yyyy - hh:mm a');

    // Unlock data
    final unlockLat = data['unlockLat']?.toDouble();
    final unlockLng = data['unlockLng']?.toDouble();
    final unlockPlaceName = data['unlockPlaceName'] as String?;
    final unlockedBy = data['unlockedBy'] as String?;
    final unlockedAtTs = data['unlockedAt'] as Timestamp?;
    final unlockedAt = unlockedAtTs?.toDate();

    // Lock data
    final lockLat = data['lockLat']?.toDouble();
    final lockLng = data['lockLng']?.toDouble();
    final lockPlaceName = data['lockPlaceName'] as String?;
    final lockedBy = data['lockedBy'] as String?;
    final lockedAtTs = data['lockedAt'] as Timestamp?;
    final lockedAt = lockedAtTs?.toDate();

    return Scaffold(
      backgroundColor: AppColors.base,
      appBar: AppBar(
        title: const Text('History Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.red),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('fleets').doc(fleetId).get(),
        builder: (context, fleetSnap) {
          String fleetJoinCode = fleetShortId;
          if (fleetSnap.hasData && fleetSnap.data!.exists) {
            fleetJoinCode = (fleetSnap.data!.data() as Map<String, dynamic>)['joinCode'] ?? fleetShortId;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Driver Profile
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(color: AppColors.surface2, shape: BoxShape.circle),
                        child: Center(
                          child: Text(
                            driverName.isNotEmpty ? driverName[0].toUpperCase() : '?',
                            style: const TextStyle(color: AppColors.teal, fontSize: 32, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(driverName, style: AppTextStyles.screenTitle.copyWith(fontSize: 24)),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Info Cards
                _InfoRow(label: 'FLEET ID', value: fleetJoinCode, icon: Icons.tag_rounded, color: AppColors.gold),
            const SizedBox(height: 12),
            _InfoRow(label: 'PHONE NUMBER', value: phone, icon: Icons.phone_rounded),
            
            const SizedBox(height: 24),
            Text('LOCATIONS', style: AppTextStyles.sectionLabel),
            const SizedBox(height: 12),

            // Unlocked At
            _LocationCard(
              label: 'Unlocked At',
              dateStr: unlockedAt != null ? dateFormat.format(unlockedAt) : 'N/A',
              byStr: unlockedBy == 'admin' ? 'Admin' : 'Driver',
              placeName: unlockPlaceName ?? (unlockLat != null ? '${unlockLat.toStringAsFixed(5)}, ${unlockLng?.toStringAsFixed(5)}' : 'Not recorded'),
              color: AppColors.teal,
              borderColor: AppColors.tealBorder,
              bgColor: AppColors.tealDim,
              icon: Icons.lock_open_rounded,
              onMapTap: unlockLat != null && unlockLng != null ? () => _openMaps(context, unlockLat, unlockLng) : null,
            ),
            const SizedBox(height: 12),

            // Locked At
            _LocationCard(
              label: 'Locked At',
              dateStr: lockedAt != null ? dateFormat.format(lockedAt) : 'N/A',
              byStr: lockedBy == 'admin' ? 'Admin' : 'Driver',
              placeName: lockPlaceName ?? (lockLat != null ? '${lockLat.toStringAsFixed(5)}, ${lockLng?.toStringAsFixed(5)}' : 'Not recorded'),
              color: AppColors.gold,
              borderColor: AppColors.goldBorder,
              bgColor: AppColors.goldDim,
              icon: Icons.lock_rounded,
              onMapTap: lockLat != null && lockLng != null ? () => _openMaps(context, lockLat, lockLng) : null,
            ),
            
            const SizedBox(height: 40),

            // Download PDF
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
                label: const Text('Download PDF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  PdfService.generateAndDownloadHistoryPdf(
                    context,
                    driverName: driverName,
                    phone: phone,
                    fleetId: fleetJoinCode,
                    email: email,
                    unlockedAt: unlockedAt,
                    unlockPlaceName: unlockPlaceName,
                    unlockLat: unlockLat,
                    unlockLng: unlockLng,
                    unlockedBy: unlockedBy,
                    lockedAt: lockedAt,
                    lockPlaceName: lockPlaceName,
                    lockLat: lockLat,
                    lockLng: lockLng,
                    lockedBy: lockedBy,
                  );
                },
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      );
    },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _InfoRow({required this.label, required this.value, required this.icon, this.color});

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
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.textSecondary, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.sectionLabel.copyWith(fontSize: 10)),
              const SizedBox(height: 3),
              Text(value, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold, fontSize: 18, color: color ?? AppColors.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final String label;
  final String dateStr;
  final String byStr;
  final String placeName;
  final Color color;
  final Color borderColor;
  final Color bgColor;
  final IconData icon;
  final VoidCallback? onMapTap;

  const _LocationCard({
    required this.label, required this.dateStr, required this.byStr, required this.placeName,
    required this.color, required this.borderColor, required this.bgColor, required this.icon, this.onMapTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label, style: AppTextStyles.sectionLabel.copyWith(color: color, fontSize: 12)),
                    if (onMapTap != null)
                      GestureDetector(
                        onTap: onMapTap,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                          child: Icon(Icons.arrow_outward_rounded, color: color, size: 16),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(placeName, style: AppTextStyles.body.copyWith(color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(dateStr, style: AppTextStyles.caption),
                    Text('By: $byStr', style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
