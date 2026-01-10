import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/daily_summary_controller.dart';
import '../../../app/theme/app_text_styles.dart';

class HighlightsSection extends StatelessWidget {
  final DailySummaryController controller;

  const HighlightsSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final summary = controller.summary.value;
      if (summary == null || summary.highlights.isEmpty) {
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
                Text(
                  '🌟',
                  style: TextStyle(fontSize: 20.sp),
                ),
                SizedBox(width: 8.w),
                Text(
                  'Highlights',
                  style: ResponsiveTextStyles.h3.copyWith(
                    color: const Color(0xFF0A2342),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h), // mb-4
            Column(
              children: summary.highlights.asMap().entries.map((entry) {
                final index = entry.key;
                final highlight = entry.value;
                return Padding(
                  padding: EdgeInsets.only(bottom: index < summary.highlights.length - 1 ? 12.h : 0), // space-y-3
                  child: Container(
                    padding: EdgeInsets.all(16.r), // p-4
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4), // bg-green-50
                      border: Border.all(
                        color: const Color(0xFF86EFAC).withOpacity(0.5), // border-green-200
                      ),
                      borderRadius: BorderRadius.circular(16.r), // rounded-2xl
                    ),
                    child: Text(
                      highlight,
                      style: ResponsiveTextStyles.textSm.copyWith(
                        color: const Color(0xFF0A2342).withOpacity(0.8), // text-[#0A2342]/80
                        height: 1.625, // leading-relaxed
                      ),
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

