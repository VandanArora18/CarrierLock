import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_constants.dart';
import '../utils/date_utils.dart';

/// Alert feed item card with severity-colored left bar.
class AlertItem extends StatelessWidget {
  final String title;
  final String body;
  final String severity;
  final DateTime createdAt;
  final bool read;
  final VoidCallback? onTap;

  const AlertItem({
    super.key,
    required this.title,
    required this.body,
    required this.severity,
    required this.createdAt,
    this.read = false,
    this.onTap,
  });

  Color _getBarColor() {
    switch (severity) {
      case AppConstants.severityCritical:
        return AppColors.red;
      case AppConstants.severityWarning:
        return AppColors.amber;
      case AppConstants.severityInfo:
      default:
        return AppColors.teal;
    }
  }

  Color _getCardColor() {
    switch (severity) {
      case AppConstants.severityCritical:
        return AppColors.redDim;
      case AppConstants.severityWarning:
        return AppColors.amberDim;
      case AppConstants.severityInfo:
      default:
        return AppColors.cardSurface;
    }
  }

  Color _getBorderColor() {
    switch (severity) {
      case AppConstants.severityCritical:
        return AppColors.redBorder;
      case AppConstants.severityWarning:
        return AppColors.amberBorder;
      case AppConstants.severityInfo:
      default:
        return AppColors.borderFaint;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        decoration: BoxDecoration(
          color: _getCardColor(),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: _getBorderColor()),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Severity color bar
              Container(
                width: 3,
                decoration: BoxDecoration(
                  color: _getBarColor(),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(11),
                    bottomLeft: Radius.circular(11),
                  ),
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (!read)
                            Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _getBarColor(),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        _getBarColor().withValues(alpha: 0.5),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          Expanded(
                            child: Text(
                              title,
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          Text(
                            AppDateUtils.timeAgo(createdAt),
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        body,
                        style: AppTextStyles.label,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
