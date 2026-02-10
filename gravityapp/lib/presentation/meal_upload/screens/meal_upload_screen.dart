// ------------------------
// PART 1 OF 3
// ------------------------

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_text_styles.dart';
import '../controllers/meal_upload_controller.dart';
import '../../../data/model/meal_analysis.dart';

class MealUploadScreen extends GetView<MealUploadController> {
  const MealUploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF5F6FA), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SafeArea(
                    top: false, // Don't apply top safe area (header handles it)
                    child: Obx(() {
                      final hasImage = controller.selectedImagePath.value != null;
                      final hasResult = controller.analysis.value != null;
                      final isAnalyzing = controller.isAnalyzing.value;
                      final hasError = controller.error.value != null;

                      if (!hasImage) {
                        return _buildUploadState();
                      }
                      if (hasImage && !hasResult && !isAnalyzing && !hasError) {
                        return _buildReviewState();
                      }
                      return _buildAnalysisState();
                    }),
                  ),
                ),
              ],
            ),
          ),

          /// Limit warning modal
          Obx(
            () => controller.showLimitWarning.value
                ? _buildLimitWarningModal()
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // -------------------------
  // HEADER (React Style) - Extends to status bar like MainAppBar
  // -------------------------
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A2342), Color(0xFF00B8A9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: SafeArea(
        bottom: false, // Don't apply bottom safe area padding
        child: Padding(
          padding: EdgeInsets.only(
            left: 24.w,
            right: 24.w,
            top: 12.h,
            bottom: 24.h,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: controller.navigateBack,
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedScale(
                        scale: 1.0,
                        duration: const Duration(milliseconds: 150),
                        child: Container(
                          width: 44.w,
                          height: 44.h,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.20),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(
                            Icons.arrow_back,
                            size: 20.sp,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Flexible(
                      child: Text(
                        "AI Meal Analysis",
                        style: ResponsiveTextStyles.textXl.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              /// Daily Limit Indicator
              Obx(() {
                // Access trigger to make this reactive
                controller.statsTrigger.value;
                final remaining = controller.remainingAnalyses;
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.20),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    "$remaining/5000 left today",
                    style: ResponsiveTextStyles.textSm.copyWith(
                      color: Colors.white,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------
  // UPLOAD STATE (React UI)
  // -------------------------
  Widget _buildUploadState() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
      child: Column(
        children: [
          /// Upload Box
          _buildUploadCard(),
          SizedBox(height: 24.h),

          /// Usage Stats
          _buildUsageStatsCard(),
          SizedBox(height: 24.h),

          /// Pro Tips
          _buildProTipsCard(),
        ],
      ),
    );
  }

  // -------------------------
  // UPLOAD CARD — React Style Redesign
  // -------------------------
  Widget _buildUploadCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(
          color: const Color(0xFF00B8A9).withOpacity(0.30),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(32.w),
      child: Column(
        children: [
          /// Camera Icon (React Gradient Box)
          Container(
            width: 96.w,
            height: 96.h,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24.r),
            ),
            child: Icon(Icons.camera_alt, color: Colors.white, size: 42.sp),
          ),

          SizedBox(height: 24.h),
          Text(
            "Upload Your Meal Photo",
            style: ResponsiveTextStyles.textLg.copyWith(
              color: const Color(0xFF0A2342),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            "AI-powered nutrition analysis in seconds",
            style: ResponsiveTextStyles.textBase.copyWith(
              color: const Color(0xFF0A2342).withOpacity(0.60),
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 24.h),

          Obx(() {
            // Access trigger to make this reactive
            controller.statsTrigger.value;
            final remaining = controller.remainingAnalyses;
            final disabled = remaining <= 0;

            return Column(
              children: [
                _GradientButton(
                  enabled: !disabled,
                  icon: Icons.camera_alt,
                  text: "Take Photo",
                  onPressed: !disabled
                      ? controller.selectImageFromCamera
                      : null,
                ),
                SizedBox(height: 16.h),
                _OutlinedButton(
                  enabled: !disabled,
                  icon: Icons.photo,
                  text: "Choose from Gallery",
                  onPressed: !disabled
                      ? controller.selectImageFromGallery
                      : null,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // -------------------------
  // USAGE STATS CARD (React Style)
  // -------------------------
  Widget _buildUsageStatsCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: EdgeInsets.all(24.w),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40.w,
                height: 40.h,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFA78BFA), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 22.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Obx(() {
                  // Access trigger to make this reactive
                  controller.statsTrigger.value;
                  final stats = controller.usageStats;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "AI Analysis Powered by Gemini",
                        style: ResponsiveTextStyles.textBase.copyWith(
                          color: const Color(0xFF0A2342),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        "${stats.totalCalls} total analyses · \$${stats.totalCost.toStringAsFixed(3)} spent",
                        style: ResponsiveTextStyles.textSm.copyWith(
                          color: const Color(0xFF0A2342).withOpacity(0.6),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
          SizedBox(height: 20.h),

          /// Progress bar
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F6FA),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Daily Limit",
                      style: ResponsiveTextStyles.textSm.copyWith(
                        color: const Color(0xFF0A2342).withOpacity(0.7),
                      ),
                    ),
                    Obx(() {
                      // Access trigger to make this reactive
                      controller.statsTrigger.value;
                      final remaining = controller.remainingAnalyses;
                      return Text(
                        "${5000 - remaining}/5000 used",
                        style: ResponsiveTextStyles.textSm.copyWith(
                          color: const Color(0xFF0A2342),
                        ),
                      );
                    }),
                  ],
                ),
                SizedBox(height: 8.h),

                /// Animated Progress
                Obx(() {
                  // Access trigger to make this reactive
                  controller.statsTrigger.value;
                  final remaining = controller.remainingAnalyses;
                  final percent = (5000 - remaining) / 5000;

                  return Container(
                    height: 8.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: FractionallySizedBox(
                      widthFactor: percent,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00B8A9), Color(0xFF0A2342)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                      ),
                    ),
                  );
                }),

                SizedBox(height: 8.h),
                Obx(() {
                  // Access trigger to make this reactive
                  controller.statsTrigger.value;
                  final stats = controller.usageStats;
                  return Text(
                    "Resets at ${DateFormat('h:mm a').format(stats.resetTime)}",
                    style: ResponsiveTextStyles.textXs.copyWith(
                      color: const Color(0xFF0A2342).withOpacity(0.5),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------
  // PRO TIPS (React UI)
  // -------------------------
  Widget _buildProTipsCard() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFD4AF37).withOpacity(0.20),
            const Color(0xFFD4AF37).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "💡 Pro Tips",
            style: ResponsiveTextStyles.textBase.copyWith(
              color: const Color(0xFF0A2342),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 14.h),

          _buildTip("Ensure good lighting for accurate analysis"),
          SizedBox(height: 8.h),
          _buildTip("Capture the entire plate in frame"),
          SizedBox(height: 8.h),
          _buildTip("Include all dishes and portions visible"),
          SizedBox(height: 8.h),
          _buildTip("Results are cached for 7 days"),
        ],
      ),
    );
  }

  Widget _buildTip(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 6.w,
          height: 6.h,
          margin: EdgeInsets.only(top: 6.h, right: 8.w),
          decoration: const BoxDecoration(
            color: Color(0xFFD4AF37),
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: ResponsiveTextStyles.textSm.copyWith(
              color: const Color(0xFF0A2342).withOpacity(0.70),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------
  // REVIEW MEAL STATE (preview + optional details + Analyze / Change photo)
  // -------------------------
  Widget _buildReviewState() {
    final imagePath = controller.selectedImagePath.value!;
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
      child: Column(
        children: [
          /// Image preview card
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 240.h,
                  width: double.infinity,
                  color: const Color(0xFFF5F6FA),
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(28.r),
                      topRight: Radius.circular(28.r),
                    ),
                    child: Image.file(
                      File(imagePath),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "Add meal details (optional)",
                        style: ResponsiveTextStyles.textSm.copyWith(
                          color: const Color(0xFF0A2342),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      TextField(
                        controller: controller.mealDetailsEditingController,
                        maxLength: MealUploadController.mealDetailsMaxLength,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText:
                              "e.g. Grilled chicken with rice, homemade, medium portion",
                          hintStyle: ResponsiveTextStyles.textSm.copyWith(
                            color: const Color(0xFF0A2342).withOpacity(0.45),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF5F6FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14.r),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14.r),
                            borderSide: BorderSide(
                              color: const Color(0xFF0A2342).withOpacity(0.12),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14.r),
                            borderSide: const BorderSide(
                              color: Color(0xFF00B8A9),
                              width: 2,
                            ),
                          ),
                          counterText: '',
                        ),
                        style: ResponsiveTextStyles.textBase.copyWith(
                          color: const Color(0xFF0A2342),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: controller.mealDetailsEditingController,
                        builder: (_, value, __) => Text(
                          "${value.text.length}/${MealUploadController.mealDetailsMaxLength}",
                          style: ResponsiveTextStyles.textXs.copyWith(
                            color: const Color(0xFF0A2342).withOpacity(0.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),

          /// Primary: Analyze Meal
          Obx(() {
            controller.statsTrigger.value;
            final remaining = controller.remainingAnalyses;
            final disabled = remaining <= 0;
            return _GradientButton(
              enabled: !disabled,
              icon: Icons.auto_awesome,
              text: "Analyze Meal",
              onPressed: !disabled ? controller.analyzeMeal : null,
            );
          }),
          SizedBox(height: 16.h),

          /// Secondary: Change / retake photo
          _OutlinedButton(
            enabled: true,
            icon: Icons.camera_alt_outlined,
            text: "Change or retake photo",
            onPressed: controller.clearSelection,
          ),
        ],
      ),
    );
  }

  // -------------------------
  // ANALYSIS STATE
  // -------------------------
  Widget _buildAnalysisState() {
    return Obx(() {
      if (controller.isAnalyzing.value) return _buildLoadingState();
      if (controller.error.value != null) return _buildErrorState();
      if (controller.analysis.value != null) return _buildSuccessState();
      return const SizedBox.shrink();
    });
  }

  // -------------------------
  // LOADING STATE (React Motion)
  // -------------------------
  Widget _buildLoadingState() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.all(32.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Rotating loader
            SizedBox(
              width: 90.w,
              height: 90.h,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(seconds: 2),
                      curve: Curves.linear,
                      builder: (_, value, child) {
                        return Transform.rotate(
                          angle: value * 6.3,
                          child: child,
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00B8A9), Color(0xFF0A2342)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      width: 60.w,
                      height: 60.h,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        size: 32.sp,
                        color: Color(0xFF00B8A9),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),
            Text(
              "Analyzing Your Meal...",
              style: ResponsiveTextStyles.textLg.copyWith(
                color: const Color(0xFF0A2342),
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              "Our AI is identifying ingredients and calculating nutrition",
              style: ResponsiveTextStyles.textBase.copyWith(
                color: const Color(0xFF0A2342).withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------
  // ERROR STATE (React Styled)
  // -------------------------
  Widget _buildErrorState() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.all(32.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 80.w,
              height: 80.h,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, color: Colors.red, size: 38.sp),
            ),
            SizedBox(height: 24.h),
            Text(
              "Analysis Failed",
              style: ResponsiveTextStyles.textLg.copyWith(
                color: const Color(0xFF0A2342),
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 10.h),

            Obx(() {
              return Text(
                controller.error.value ?? "Something went wrong.",
                textAlign: TextAlign.center,
                style: ResponsiveTextStyles.textBase.copyWith(
                  color: const Color(0xFF0A2342).withOpacity(0.6),
                ),
              );
            }),

            SizedBox(height: 24.h),
            _GradientButton(
              text: "Try Again",
              icon: null,
              enabled: true,
              onPressed: controller.reset,
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------
  // SUCCESS STATE (React Styled)
  // -------------------------
  Widget _buildSuccessState() {
    final analysis = controller.analysis.value!;

    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Column(
        children: [
          _buildMealImageCard(analysis),
          SizedBox(height: 24.h),

          Row(
            children: [
              Expanded(
                child: _OutlinedButton(
                  text: "Analyze Another",
                  icon: null,
                  enabled: true,
                  onPressed: controller.reset,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _GradientButton(
                  text: "Done",
                  icon: null,
                  enabled: true,
                  onPressed: controller.navigateBack,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------
  // MEAL IMAGE CARD — React UI
  // -------------------------
  Widget _buildMealImageCard(MealAnalysis analysis) {
    final imagePath = controller.selectedImagePath.value;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// Top Image with overlay badges
          Container(
            height: 200.h,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFCD34D), Color(0xFFFBBF24)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                if (imagePath != null)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(28.r),
                        topRight: Radius.circular(28.r),
                      ),
                      child: Image.file(File(imagePath), fit: BoxFit.cover),
                    ),
                  ),

                /// Status badges
                Positioned(
                  top: 16.h,
                  left: 16.w,
                  right: 16.w,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Cached / Analyzed badge
                      Flexible(
                        flex: 1,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: analysis.cached ? Colors.blue : Colors.green,
                            borderRadius: BorderRadius.circular(22.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                analysis.cached
                                    ? Icons.access_time
                                    : Icons.check_circle,
                                color: Colors.white,
                                size: 16.sp,
                              ),
                              SizedBox(width: 6.w),
                              Flexible(
                                child: Text(
                                  analysis.cached ? "Cached" : "Analyzed",
                                  style: ResponsiveTextStyles.textXs.copyWith(
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(width: 8.w),

                      // Confidence Indicator
                      Flexible(
                        flex: 1,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22.r),
                            color: Colors.white.withOpacity(0.90),
                          ),
                          child: Text(
                            "${(analysis.confidence * 100).round()}% confident",
                            style: ResponsiveTextStyles.textXs.copyWith(
                              color: const Color(0xFF0A2342),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          /// Content
          Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --------------------------
                // Detected Items
                // --------------------------
                Text(
                  "Detected Items",
                  style: ResponsiveTextStyles.textBase.copyWith(
                    color: const Color(0xFF0A2342),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12.h),

                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: analysis.foodItems.map((item) {
                    return Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00B8A9).withOpacity(0.10),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        item,
                        style: ResponsiveTextStyles.textSm.copyWith(
                          color: const Color(0xFF00B8A9),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        softWrap: true,
                      ),
                    );
                  }).toList(),
                ),

                SizedBox(height: 24.h),

                // --------------------------
                // Health Score Bar
                // --------------------------
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        "Health Score",
                        style: ResponsiveTextStyles.textBase.copyWith(
                          color: const Color(0xFF0A2342),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    Text(
                      "${analysis.healthScore}/100",
                      style: ResponsiveTextStyles.textBase.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0A2342),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),

                SizedBox(height: 10.h),

                AnimatedContainer(
                  duration: const Duration(milliseconds: 700),
                  height: 14.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    color: Colors.grey.shade200,
                  ),
                  child: FractionallySizedBox(
                    widthFactor: analysis.healthScore / 100,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 700),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        gradient: LinearGradient(
                          colors: analysis.healthScore >= 80
                              ? [Colors.green.shade400, Colors.green.shade600]
                              : analysis.healthScore >= 60
                              ? [Colors.yellow.shade400, Colors.yellow.shade600]
                              : [
                                  Colors.orange.shade400,
                                  Colors.orange.shade600,
                                ],
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 24.h),

                // --------------------------
                // Nutrition Breakdown
                // --------------------------
                Text(
                  "Nutrition Breakdown",
                  style: ResponsiveTextStyles.textBase.copyWith(
                    color: const Color(0xFF0A2342),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 20.h),

                /// Dynamic Grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    return GridView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16.w,
                        mainAxisSpacing: 16.h,
                        childAspectRatio:
                            1.1, // Reduced from 1.3 to give more height
                      ),
                      children: [
                        _NutritionCard(
                          icon: Icons.local_fire_department,
                          label: "Calories",
                          value: analysis.nutritionInfo.calories.toString(),
                          unit: "kcal",
                          colors: [
                            Colors.orange.shade400,
                            Colors.orange.shade600,
                          ],
                        ),
                        _NutritionCard(
                          icon: Icons.set_meal,
                          label: "Protein",
                          value: analysis.nutritionInfo.protein.toString(),
                          unit: "g",
                          colors: [Colors.red.shade400, Colors.red.shade600],
                        ),
                        _NutritionCard(
                          icon: Icons.apple,
                          label: "Carbs",
                          value: analysis.nutritionInfo.carbs.toString(),
                          unit: "g",
                          colors: [
                            Colors.green.shade400,
                            Colors.green.shade600,
                          ],
                        ),
                        _NutritionCard(
                          icon: Icons.water_drop,
                          label: "Fat",
                          value: analysis.nutritionInfo.fat.toString(),
                          unit: "g",
                          colors: [
                            Colors.yellow.shade400,
                            Colors.yellow.shade600,
                          ],
                        ),
                      ],
                    );
                  },
                ),

                SizedBox(height: 16.h),

                // --------------------------
                // Additional nutrients
                // --------------------------
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F6FA),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Fiber",
                              style: ResponsiveTextStyles.textXs.copyWith(
                                color: const Color(0xFF0A2342).withOpacity(0.6),
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              "${analysis.nutritionInfo.fiber}g",
                              style: ResponsiveTextStyles.textBase.copyWith(
                                color: const Color(0xFF0A2342),
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F6FA),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Sodium",
                              style: ResponsiveTextStyles.textXs.copyWith(
                                color: const Color(0xFF0A2342).withOpacity(0.6),
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              "${analysis.nutritionInfo.sodium}mg",
                              style: ResponsiveTextStyles.textBase.copyWith(
                                color: const Color(0xFF0A2342),
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 24.h),

                // --------------------------
                // AI Insights Card
                // --------------------------
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00B8A9).withOpacity(0.10),
                    borderRadius: BorderRadius.circular(18.r),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 20.sp,
                        color: const Color(0xFF00B8A9),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "AI Insights",
                              style: ResponsiveTextStyles.textBase.copyWith(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0A2342),
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              analysis.feedback,
                              style: ResponsiveTextStyles.textSm.copyWith(
                                height: 1.5,
                                color: const Color(
                                  0xFF0A2342,
                                ).withOpacity(0.80),
                              ),
                              overflow: TextOverflow.visible,
                              softWrap: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16.h),

                // --------------------------
                // Suggestions Card
                // --------------------------
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withOpacity(0.10),
                    borderRadius: BorderRadius.circular(18.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "💡 Suggestions",
                        style: ResponsiveTextStyles.textBase.copyWith(
                          color: const Color(0xFF0A2342),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 12.h),

                      ...analysis.suggestions.map((suggestion) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: 8.h),
                          child: _buildTip(suggestion),
                        );
                      }),
                    ],
                  ),
                ),

                SizedBox(height: 16.h),

                Center(
                  child: Text(
                    "Powered by ${analysis.aiProvider == 'gemini'
                        ? 'Google Gemini'
                        : analysis.aiProvider == 'n8n'
                        ? 'N8N'
                        : 'OpenAI GPT-4'} Vision",
                    style: ResponsiveTextStyles.textXs.copyWith(
                      color: const Color(0xFF0A2342).withOpacity(0.40),
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------
  // LIMIT WARNING MODAL (React Styled w/ Fade + Scale Animation)
  // -------------------------
  Widget _buildLimitWarningModal() {
    return AnimatedOpacity(
      opacity: controller.showLimitWarning.value ? 1 : 0,
      duration: const Duration(milliseconds: 250),
      child: GestureDetector(
        onTap: controller.closeLimitWarning,
        child: Container(
          color: Colors.black.withOpacity(0.50),
          child: Center(
            child: GestureDetector(
              onTap: () {}, // Prevent closing when tapping modal content
              child: AnimatedScale(
                scale: controller.showLimitWarning.value ? 1 : 0.9,
                duration: const Duration(milliseconds: 250),
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 24.w),
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64.w,
                        height: 64.h,
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Icon(
                          Icons.warning_amber_rounded,
                          size: 32.sp,
                          color: Colors.orange.shade700,
                        ),
                      ),
                      SizedBox(height: 16.h),

                      Text(
                        "Daily Limit Reached",
                        textAlign: TextAlign.center,
                        style: ResponsiveTextStyles.textLg.copyWith(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0A2342),
                        ),
                      ),

                      SizedBox(height: 10.h),

                      Obx(() {
                        // Access trigger to make this reactive
                        controller.statsTrigger.value;
                        final stats = controller.usageStats;
                        return Text(
                          "You've used all 5000 daily AI analyses. This helps us manage API costs (~\$0.002 per analysis).\nYour limit resets at ${DateFormat('h:mm a').format(stats.resetTime)}.",
                          textAlign: TextAlign.center,
                          style: ResponsiveTextStyles.textSm.copyWith(
                            color: const Color(0xFF0A2342).withOpacity(0.70),
                            height: 1.5,
                          ),
                        );
                      }),

                      SizedBox(height: 24.h),

                      _GradientButton(
                        text: "Got It",
                        icon: null,
                        enabled: true,
                        onPressed: controller.closeLimitWarning,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// -------------------------
// GRADIENT BUTTON (Animated Press)
// -------------------------
class _GradientButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final String text;
  final IconData? icon;
  final bool enabled;

  const _GradientButton({
    required this.onPressed,
    required this.text,
    required this.icon,
    required this.enabled,
  });

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 110),
      vsync: this,
    );

    _scale = Tween(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _tapDown(TapDownDetails d) {
    if (widget.enabled) _controller.forward();
  }

  void _tapUp(TapUpDetails d) {
    _controller.reverse();
    if (widget.enabled && widget.onPressed != null) widget.onPressed!();
  }

  void _tapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _tapDown,
      onTapUp: _tapUp,
      onTapCancel: _tapCancel,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          decoration: BoxDecoration(
            gradient: widget.enabled
                ? const LinearGradient(
                    colors: [Color(0xFF00B8A9), Color(0xFF0A2342)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: widget.enabled ? null : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null)
                Icon(widget.icon, size: 20.sp, color: Colors.white),
              if (widget.icon != null) SizedBox(width: 8.w),
              Text(
                widget.text,
                style: ResponsiveTextStyles.textBase.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------
// OUTLINED BUTTON (Animated Press)
// -------------------------
class _OutlinedButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final String text;
  final IconData? icon;
  final bool enabled;

  const _OutlinedButton({
    required this.onPressed,
    required this.text,
    required this.icon,
    required this.enabled,
  });

  @override
  State<_OutlinedButton> createState() => _OutlinedButtonState();
}

class _OutlinedButtonState extends State<_OutlinedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 110),
      vsync: this,
    );

    _scale = Tween(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _tapDown(TapDownDetails d) {
    if (widget.enabled) _controller.forward();
  }

  void _tapUp(TapUpDetails d) {
    _controller.reverse();
    if (widget.enabled && widget.onPressed != null) widget.onPressed!();
  }

  void _tapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.enabled
        ? const Color(0xFF00B8A9)
        : Colors.grey.shade300;
    final textColor = widget.enabled
        ? const Color(0xFF00B8A9)
        : Colors.grey.shade400;

    return GestureDetector(
      onTapDown: _tapDown,
      onTapUp: _tapUp,
      onTapCancel: _tapCancel,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: borderColor, width: 2),
            color: Colors.white,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null)
                Icon(widget.icon, size: 20.sp, color: textColor),
              if (widget.icon != null) SizedBox(width: 8.w),
              Text(
                widget.text,
                style: ResponsiveTextStyles.textBase.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------
// Nutrition Card Redesign
// -------------------------
class _NutritionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final List<Color> colors;

  const _NutritionCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.all(12.w), // Reduced from 16.w
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF5F6FA), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Added to prevent overflow
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36.w, // Reduced from 40.w
            height: 36.h, // Reduced from 40.h
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              gradient: LinearGradient(colors: colors),
            ),
            child: Icon(
              icon,
              size: 18.sp,
              color: Colors.white,
            ), // Reduced from 20.sp
          ),
          SizedBox(height: 8.h), // Reduced from 12.h

          Text(
            label,
            style: ResponsiveTextStyles.textXs.copyWith(
              color: const Color(0xFF0A2342).withOpacity(0.60),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          SizedBox(height: 2.h), // Reduced from 4.h

          RichText(
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            text: TextSpan(
              text: value,
              style: ResponsiveTextStyles.textSm.copyWith(
                // Reduced from textBase
                color: const Color(0xFF0A2342),
                fontWeight: FontWeight.w600,
              ),
              children: [
                TextSpan(
                  text: " $unit",
                  style: ResponsiveTextStyles.textXs.copyWith(
                    // Reduced from textSm
                    color: const Color(0xFF0A2342).withOpacity(0.60),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------
// End of File
// -------------------------
