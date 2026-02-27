import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../controllers/notifications_controller.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_shadows.dart';

class NotificationCard extends StatelessWidget {
  const NotificationCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  final NotificationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isPayment = item.type == NotificationType.payment;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: AppShadows.shadowSm,
          border: item.isUnread
              ? Border(
                  left: BorderSide(
                    color: AppColors.primary,
                    width: 4,
                  ),
                )
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIconContainer(),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: AppTextStyles.textBase.copyWith(
                                    color: AppColors.cardForeground,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                item.timeText,
                                style: AppTextStyles.textXs.copyWith(
                                  color: AppColors.mutedForeground,
                                ),
                              ),
                              if (item.isUnread) ...[
                                SizedBox(width: 6.w),
                                Container(
                                  width: 8.w,
                                  height: 8.h,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            item.description,
                            style: AppTextStyles.textSm.copyWith(
                              color: AppColors.mutedForeground,
                            ),
                          ),
                          if (item.isHighPriority) ...[
                            SizedBox(height: 8.h),
                            _buildHighPriorityPill(),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (item.actionText != null) ...[
                  SizedBox(height: 12.h),
                  Divider(
                    color: AppColors.primary.withOpacity(0.1),
                    height: 1,
                    thickness: 1,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    item.actionText!,
                    style: AppTextStyles.textSm.copyWith(
                      color: isPayment
                          ? AppColors.destructive
                          : AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconContainer() {
    return Container(
      width: 40.w,
      height: 40.h,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: _gradientForType(item.type),
      ),
      child: Icon(
        _iconForType(item.type),
        color: AppColors.primaryForeground,
        size: 20.sp,
      ),
    );
  }

  LinearGradient _gradientForType(NotificationType type) {
    switch (type) {
      case NotificationType.message:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.chart2],
        );
      case NotificationType.payment:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.destructive,
            AppColors.destructive.withOpacity(0.7),
          ],
        );
      case NotificationType.streak:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.chart2,
            AppColors.chart2.withOpacity(0.7),
          ],
        );
      case NotificationType.offer:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.chart5, AppColors.chart4],
        );
      case NotificationType.social:
      case NotificationType.update:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.chart3,
            AppColors.chart3.withOpacity(0.8),
          ],
        );
      case NotificationType.reminder:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.chart2,
          ],
        );
    }
  }

  IconData _iconForType(NotificationType type) {
    switch (type) {
      case NotificationType.message:
        return Icons.chat_bubble_outline;
      case NotificationType.payment:
        return Icons.credit_card;
      case NotificationType.streak:
        return Icons.local_fire_department;
      case NotificationType.offer:
        return Icons.card_giftcard;
      case NotificationType.social:
        return Icons.people_outline;
      case NotificationType.reminder:
        return Icons.info_outline;
      case NotificationType.update:
        return Icons.info_outline;
    }
  }

  Widget _buildHighPriorityPill() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.destructive.withOpacity(0.15),
        borderRadius: BorderRadius.circular(50.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_active,
            size: 14.sp,
            color: AppColors.destructive,
          ),
          SizedBox(width: 6.w),
          Text(
            'High Priority',
            style: AppTextStyles.textXs.copyWith(
              color: AppColors.destructive,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
