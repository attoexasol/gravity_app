import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../controllers/weekly_review_controller.dart';
import '../../../../data/model/weekly_review.dart';
import '../../../../app/theme/app_text_styles.dart';

class WeeklyConsistencyGrid extends StatelessWidget {
  final WeeklyReviewController controller;

  const WeeklyConsistencyGrid({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final review = controller.weeklyReview.value;
      if (review == null) return const SizedBox.shrink();

      final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

      return Container(
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4.r,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Consistency',
              style: ResponsiveTextStyles.textLg.copyWith(
                color: const Color(0xFF0A2342),
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 16.h),
            
            // Grid
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 320.w,
                child: Column(
                  children: [
                    // Header row
                    _buildHeaderRow(dayLabels),
                    SizedBox(height: 12.h),
                    
                    // Nutrition row
                    _buildPillarRow(
                      icon: Icons.restaurant,
                      label: 'Nutr',
                      statuses: review.consistency.nutrition,
                    ),
                    SizedBox(height: 12.h),
                    
                    // Hydration row
                    _buildPillarRow(
                      icon: Icons.water_drop,
                      label: 'Hydr',
                      statuses: review.consistency.hydration,
                    ),
                    SizedBox(height: 12.h),
                    
                    // Sleep row
                    _buildPillarRow(
                      icon: Icons.bedtime,
                      label: 'Sleep',
                      statuses: review.consistency.sleep,
                    ),
                    SizedBox(height: 12.h),
                    
                    // Steps row
                    _buildPillarRow(
                      icon: Icons.directions_walk,
                      label: 'Step',
                      statuses: review.consistency.steps,
                    ),
                    SizedBox(height: 12.h),
                    
                    // Fasting row
                    _buildPillarRow(
                      icon: Icons.access_time,
                      label: 'Fast',
                      statuses: review.consistency.fasting,
                    ),
                    SizedBox(height: 12.h),
                    
                    // Weigh-in row
                    _buildPillarRow(
                      icon: Icons.monitor_weight,
                      label: 'Weigh',
                      statuses: review.consistency.weighin,
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16.h),
            
            // Legend
            _buildLegend(),
          ],
        ),
      );
    });
  }

  Widget _buildHeaderRow(List<String> dayLabels) {
    return Row(
      children: [
        SizedBox(width: 60.w), // Space for pillar label
        ...dayLabels.map((day) => Expanded(
          child: Center(
            child: Text(
              day,
              style: ResponsiveTextStyles.textXs.copyWith(
                color: const Color(0xFF0A2342).withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildPillarRow({
    required IconData icon,
    required String label,
    required List<PillarStatus> statuses,
  }) {
    return Row(
      children: [
        // Pillar label with icon
        SizedBox(
          width: 60.w,
          child: Row(
            children: [
              Icon(
                icon,
                size: 14.sp,
                color: const Color(0xFF0A2342).withOpacity(0.6),
              ),
              SizedBox(width: 6.w),
              Text(
                label,
                style: ResponsiveTextStyles.textXs.copyWith(
                  color: const Color(0xFF0A2342).withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        
        // Status circles
        ...statuses.map((status) => Expanded(
          child: Center(
            child: Container(
              width: 24.w,
              height: 24.h,
              decoration: BoxDecoration(
                color: controller.getStatusColor(status),
                shape: BoxShape.circle,
              ),
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: EdgeInsets.only(top: 16.h),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: const Color(0xFF0A2342).withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          _buildLegendItem(
            color: const Color(0xFF00B8A9),
            label: 'Complete',
          ),
          SizedBox(width: 16.w),
          _buildLegendItem(
            color: const Color(0xFFF5E6D3),
            label: 'Partial',
          ),
          SizedBox(width: 16.w),
          _buildLegendItem(
            color: const Color(0xFFE5E7EB),
            label: 'Missed',
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
  }) {
    return Row(
      children: [
        Container(
          width: 12.w,
          height: 12.h,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 6.w),
        Text(
          label,
          style: ResponsiveTextStyles.textXs.copyWith(
            color: const Color(0xFF0A2342).withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}

