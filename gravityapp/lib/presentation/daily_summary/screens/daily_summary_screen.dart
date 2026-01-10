import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/daily_summary_controller.dart';
import '../widgets/daily_summary_header.dart';
import '../widgets/overall_score_card.dart';
import '../widgets/trends_chart_section.dart';
import '../widgets/highlights_section.dart';
import '../widgets/concerns_section.dart';
import '../widgets/recommendations_section.dart';
import '../widgets/loading_spinner.dart';
import '../../../app/theme/app_text_styles.dart';

class DailySummaryScreen extends GetView<DailySummaryController> {
  const DailySummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Obx(() {
          if (controller.isGenerating.value) {
            return _buildLoadingState();
          } else if (controller.error.value.isNotEmpty && controller.summary.value == null) {
            return _buildErrorState();
          } else if (controller.summary.value != null) {
            return _buildSummaryContent();
          } else {
            return _buildLoadingState();
          }
        }),
      ),
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // Header
          DailySummaryHeader(controller: controller),
          
          // Loading Content
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
            child: Container(
              padding: EdgeInsets.all(32.r),
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
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const LoadingSpinner(),
                  SizedBox(height: 16.h),
                  Text(
                    'Generating AI Summary...',
                    style: ResponsiveTextStyles.h3.copyWith(
                      color: const Color(0xFF0A2342),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Analyzing your wellness data and creating personalized insights',
                    style: ResponsiveTextStyles.textSm.copyWith(
                      color: const Color(0xFF0A2342).withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          
          // Back to Dashboard Button
          _buildBackButton(),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // Header
          DailySummaryHeader(controller: controller),
          
          // Error Content
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
            child: Container(
              padding: EdgeInsets.all(32.r),
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
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64.w,
                    height: 64.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.withOpacity(0.1),
                    ),
                    child: Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 32.sp,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Generation Failed',
                    style: ResponsiveTextStyles.h3.copyWith(
                      color: const Color(0xFF0A2342),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    controller.error.value,
                    style: ResponsiveTextStyles.textSm.copyWith(
                      color: const Color(0xFF0A2342).withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24.h),
                  GestureDetector(
                    onTap: () => controller.generateSummary(),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00B8A9), Color(0xFF0A2342)],
                        ),
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh, color: Colors.white, size: 16.sp),
                          SizedBox(width: 8.w),
                          Text(
                            'Retry',
                            style: ResponsiveTextStyles.button.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Back to Dashboard Button
          _buildBackButton(),
        ],
      ),
    );
  }

  Widget _buildSummaryContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // Header
          DailySummaryHeader(controller: controller),
          
          // Content
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overall Score Card
                OverallScoreCard(controller: controller),
                SizedBox(height: 24.h),
                
                // 7-Day Trends
                TrendsChartSection(controller: controller),
                SizedBox(height: 24.h),
                
                // Highlights
                if (controller.summary.value!.highlights.isNotEmpty) ...[
                  HighlightsSection(controller: controller),
                  SizedBox(height: 24.h),
                ],
                
                // Concerns
                if (controller.summary.value!.concerns.isNotEmpty) ...[
                  ConcernsSection(controller: controller),
                  SizedBox(height: 24.h),
                ],
                
                // Recommendations
                RecommendationsSection(controller: controller),
                SizedBox(height: 24.h),
                
                // Footer Info
                Center(
                  child: Text(
                    'Generated by AI · ${DateFormat('M/d/yyyy, h:mm:ss a').format(controller.summary.value!.generatedAt)}',
                    style: ResponsiveTextStyles.textXs.copyWith(
                      color: const Color(0xFF0A2342).withOpacity(0.4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Back to Dashboard Button
          _buildBackButton(),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
      child: GestureDetector(
        onTap: () => controller.navigateToHome(),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00B8A9), Color(0xFF0A2342)],
            ),
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8.r,
                offset: Offset(0, 2.h),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'Back to Dashboard',
              style: ResponsiveTextStyles.button.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

