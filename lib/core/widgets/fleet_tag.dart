import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

/// Fleet ID badge with gold accent — shows fleet code and optional name.
class FleetTag extends StatelessWidget {
  final String fleetId;
  final String? fleetName;
  final bool tappable;
  final VoidCallback? onTap;

  const FleetTag({
    super.key,
    required this.fleetId,
    this.fleetName,
    this.tappable = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tag = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.goldDim,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: AppColors.goldBorder.withValues(alpha: 0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.goldGlow.withValues(alpha: 0.12),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.factory_outlined, size: 12, color: AppColors.gold),
          const SizedBox(width: 5),
          Text(
            'Fleet ',
            style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
          ),
          Flexible(
            child: Text(
              fleetId,
              style: AppTextStyles.fleetId,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          if (fleetName != null) ...[
            const SizedBox(width: 5),
            Text('·', style: AppTextStyles.label),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                fleetName!,
                style: AppTextStyles.label,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
          if (tappable) ...[
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_drop_down,
              size: 14,
              color: AppColors.textSecondary,
            ),
          ],
        ],
      ),
    );

    if (tappable && onTap != null) {
      return GestureDetector(onTap: onTap, child: tag);
    }

    return tag;
  }
}
