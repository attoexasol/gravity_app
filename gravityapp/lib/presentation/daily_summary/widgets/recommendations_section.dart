import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/daily_summary_controller.dart';
import '../../../app/theme/app_text_styles.dart';

class RecommendationsSection extends StatelessWidget {
  final DailySummaryController controller;

  const RecommendationsSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final summary = controller.summary.value;
      if (summary == null || summary.recommendations.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        padding: EdgeInsets.all(24.r),
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
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: const Color(0xFF00B8A9),
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  'AI Recommendations',
                  style: ResponsiveTextStyles.h3.copyWith(
                    color: const Color(0xFF0A2342),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h), // mb-4
            Column(
              children: summary.recommendations.asMap().entries.map((entry) {
                final index = entry.key;
                final recommendation = entry.value;
                return Padding(
                  padding: EdgeInsets.only(bottom: index < summary.recommendations.length - 1 ? 12.h : 0), // space-y-3
                  child: Container(
                    padding: EdgeInsets.all(16.r), // p-4
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF), // bg-blue-50
                      border: Border.all(
                        color: const Color(0xFF93C5FD).withOpacity(0.5), // border-blue-200
                      ),
                      borderRadius: BorderRadius.circular(16.r), // rounded-2xl
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24.w, // w-6
                          height: 24.h, // h-6
                          decoration: const BoxDecoration(
                            color: Color(0xFF3B82F6), // bg-blue-500
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: ResponsiveTextStyles.textXs.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w), // gap-3
                        Expanded(
                          child: Text(
                            recommendation,
                            style: ResponsiveTextStyles.textSm.copyWith(
                              color: const Color(0xFF0A2342).withOpacity(0.8), // text-[#0A2342]/80
                              height: 1.625, // leading-relaxed
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );
    });
  }
}

