import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_text_styles.dart';

class SummaryReportsNavSection extends StatelessWidget {
  final VoidCallback? onTodayTap;
  final VoidCallback? onWeeklyReviewTap;
  final VoidCallback? onDailyDetailsTap;

  const SummaryReportsNavSection({
    super.key,
    this.onTodayTap,
    this.onWeeklyReviewTap,
    this.onDailyDetailsTap,
  });

  /// Get current week range (Sunday to Saturday)
  String _getCurrentWeekRange() {
    final now = DateTime.now();
    // Get day of week: 0 = Sunday, 1 = Monday, ..., 6 = Saturday
    final dayOfWeek = now.weekday % 7; // Convert to 0-6 range (Sunday = 0)
    // Calculate Sunday of current week
    final startDate = now.subtract(Duration(days: dayOfWeek));
    final endDate = startDate.add(const Duration(days: 6));
    
    final formatter = DateFormat('MMM d', 'en_US');
    return '${formatter.format(startDate)} - ${formatter.format(endDate)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.r,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Gravity",
                style: ResponsiveTextStyles.textLg.copyWith(
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF0A2342),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                "Your wellness companion",
                style: ResponsiveTextStyles.textSm.copyWith(
                  color: const Color(0xFF0A2342).withOpacity(0.6),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Cards
          Column(
            children: [
              // Today Card
              _buildNavCard(
                icon: Icons.description,
                iconColor: const Color(0xFF00B8A9),
                backgroundColor: const Color(0xFFE6F7F5),
                borderColor: const Color(0xFF00B8A9).withOpacity(0.3),
                title: "Today",
                subtitle: "End-of-day summary",
                onTap: onTodayTap ?? () {},
              ),
              SizedBox(height: 12.h),

              // Weekly Review Card
              _buildNavCard(
                icon: Icons.calendar_today,
                iconColor: const Color(0xFFD4AF37),
                backgroundColor: const Color(0xFFFFF9E6),
                borderColor: const Color(0xFFD4AF37).withOpacity(0.3),
                title: "Weekly Review",
                subtitle: _getCurrentWeekRange(),
                onTap: onWeeklyReviewTap ?? () {},
              ),
              SizedBox(height: 12.h),

              // Daily Details Card
              _buildNavCard(
                icon: Icons.bar_chart,
                iconColor: const Color(0xFF00B8A9),
                backgroundColor: const Color(0xFFE6F7F5),
                borderColor: const Color(0xFF00B8A9).withOpacity(0.3),
                title: "Daily Details",
                subtitle: "Day-by-day breakdown",
                onTap: onDailyDetailsTap ?? () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavCard({
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required Color borderColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: borderColor,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              // Icon Container
              Container(
                width: 40.w,
                height: 40.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4.r,
                      offset: Offset(0, 2.h),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 16.w),
              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: ResponsiveTextStyles.textBase.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0A2342),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      subtitle,
                      style: ResponsiveTextStyles.textSm.copyWith(
                        color: const Color(0xFF0A2342).withOpacity(0.6),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              // Arrow
              Icon(
                Icons.arrow_forward_ios,
                color: iconColor,
                size: 16.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

