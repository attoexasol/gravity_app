import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/today_controller.dart';
import 'sections/today_header.dart';
import 'sections/pillar_status_section.dart';
import 'sections/weight_journey_section.dart';
import 'sections/wins_today_section.dart';
import 'sections/one_thing_to_watch_section.dart';
import 'sections/reflection_section.dart';
import 'sections/done_button_section.dart';
import 'modals/log_weigh_in_modal.dart';

class TodayScreen extends GetView<TodayController> {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Header
                TodayHeader(controller: controller),
                // Scrollable content with pull-to-refresh
                Expanded(
                  child: Obx(() {
                    // Show skeleton loader only on initial load (first time, no data yet)
                    if (controller.isLoading.value && controller.dateWiseData.value == null && !controller.hasError.value) {
                      return _buildSkeletonLoader();
                    }
                    
                    // Show error state ONLY for actual errors (network failures, etc.)
                    // NOT for "no data" responses (which is normal for new users)
                    if (controller.hasError.value && controller.errorMessage.value.isNotEmpty) {
                      return _buildErrorState(controller);
                    }
                    
                    // Always show content - even when no data exists (new users, empty days)
                    // UI will display with default/empty values
                    return RefreshIndicator(
                      onRefresh: controller.onRefresh,
                      color: const Color(0xFF00B8A9),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeIn,
                        builder: (context, opacity, child) {
                          return Opacity(
                            opacity: opacity,
                            child: child,
                          );
                        },
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(height: 24.h),
                              // Pillar Status
                              PillarStatusSection(controller: controller),
                              SizedBox(height: 16.h),
                              // Weight Journey
                              WeightJourneySection(controller: controller),
                              SizedBox(height: 16.h),
                              // Wins Today
                              WinsTodaySection(),
                              SizedBox(height: 16.h),
                              // One Thing to Watch
                              OneThingToWatchSection(),
                              SizedBox(height: 16.h),
                              // Reflection
                              ReflectionSection(controller: controller),
                              SizedBox(height: 16.h),
                              // Done Button
                              DoneButtonSection(controller: controller),
                              SizedBox(height: 96.h), // Bottom padding
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
            // Modal overlay
            Obx(() => controller.showWeighInModal.value
                ? LogWeighInModal(controller: controller)
                : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSkeletonLoader() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          SizedBox(height: 24.h),
          _buildSkeletonCard(),
          SizedBox(height: 16.h),
          _buildSkeletonCard(),
          SizedBox(height: 16.h),
          _buildSkeletonCard(),
        ],
      ),
    );
  }
  
  Widget _buildSkeletonCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
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
          _buildSkeletonLine(width: 120.w),
          SizedBox(height: 16.h),
          _buildSkeletonLine(),
          SizedBox(height: 12.h),
          _buildSkeletonLine(),
          SizedBox(height: 12.h),
          _buildSkeletonLine(width: 200.w),
        ],
      ),
    );
  }
  
  Widget _buildSkeletonLine({double? width}) {
    return Container(
      width: width ?? double.infinity,
      height: 16.h,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8.r),
      ),
    );
  }
  
  Widget _buildErrorState(TodayController controller) {
    return RefreshIndicator(
      onRefresh: controller.onRefresh,
      color: const Color(0xFF00B8A9),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          padding: EdgeInsets.all(32.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 100.h),
              Icon(
                Icons.error_outline,
                size: 64.sp,
                color: const Color(0xFF9CA3AF),
              ),
              SizedBox(height: 24.h),
              Text(
                'No Data Available',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0A2342),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                controller.errorMessage.value.isNotEmpty
                    ? controller.errorMessage.value
                    : 'No data exists for the selected date.',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: const Color(0xFF0A2342).withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32.h),
              ElevatedButton(
                onPressed: () => controller.fetchDateWiseGravity(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00B8A9),
                  padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'Retry',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
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

