import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/daily_summary_controller.dart';
import '../../../app/theme/app_text_styles.dart';

class OverallScoreCard extends StatelessWidget {
  final DailySummaryController controller;

  const OverallScoreCard({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final summary = controller.summary.value;
      if (summary == null) return const SizedBox.shrink();

      final colors = controller.getScoreColors(summary.overallScore);

      return Container(
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(28.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10.r,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with icon and cached badge - mb-4 equivalent
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon and score info - gap-3 equivalent
                Row(
                  children: [
                    Container(
                      width: 48.w, // w-12
                      height: 48.h, // h-12
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2), // bg-white/20
                        borderRadius: BorderRadius.circular(16.r), // rounded-2xl
                      ),
                      child: Center(
                        child: Text(
                          '🎯',
                          style: TextStyle(fontSize: 24.sp), // text-2xl
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w), // gap-3
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Overall Score',
                          style: ResponsiveTextStyles.textSm.copyWith(
                            color: Colors.white.withOpacity(0.8), // text-white/80
                          ),
                        ),
                        Text(
                          '${summary.overallScore}/100',
                          style: ResponsiveTextStyles.text3Xl.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Cached badge
                if (summary.cached)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h), // px-3 py-1
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2), // bg-white/20
                      borderRadius: BorderRadius.circular(20.r), // rounded-full
                    ),
                    child: Text(
                      'Cached',
                      style: ResponsiveTextStyles.textXs.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 16.h), // mb-4 equivalent
            // Summary message - text-white/90 leading-relaxed
            Text(
              summary.summary,
              style: ResponsiveTextStyles.textBase.copyWith(
                color: Colors.white.withOpacity(0.9),
                height: 1.625, // leading-relaxed
              ),
            ),
          ],
        ),
      );
    });
  }
}

