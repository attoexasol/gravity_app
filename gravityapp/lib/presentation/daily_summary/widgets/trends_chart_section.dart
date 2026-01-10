import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import '../controllers/daily_summary_controller.dart';
import '../../../app/theme/app_text_styles.dart';

class TrendsChartSection extends StatelessWidget {
  final DailySummaryController controller;

  const TrendsChartSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final summary = controller.summary.value;
      final trends = controller.trendData;
      
      if (summary == null || trends.isEmpty) return const SizedBox.shrink();

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
            Text(
              '7-Day Trends',
              style: ResponsiveTextStyles.h3.copyWith(
                color: const Color(0xFF0A2342),
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 24.h),
            
            // Steps Chart
            _buildChart(
              title: 'Daily Steps',
              trend: summary.trends.steps,
              data: trends.map((d) => d.steps.toDouble()).toList(),
              colors: [const Color(0xFF00B8A9), const Color(0xFF00B8A9).withOpacity(0.6)],
              labels: trends.map((d) => d.day).toList(),
            ),
            SizedBox(height: 24.h),
            
            // Sleep Chart
            _buildChart(
              title: 'Sleep Hours',
              trend: summary.trends.sleep,
              data: trends.map((d) => d.sleep).toList(),
              colors: [const Color(0xFFD4AF37), const Color(0xFFD4AF37).withOpacity(0.6)],
              labels: trends.map((d) => d.day).toList(),
            ),
            SizedBox(height: 24.h),
            
            // Water Chart
            _buildChart(
              title: 'Water Intake (L)',
              trend: summary.trends.water,
              data: trends.map((d) => d.water).toList(),
              colors: [const Color(0xFF0A2342), const Color(0xFF0A2342).withOpacity(0.6)],
              labels: trends.map((d) => d.day).toList(),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildChart({
    required String title,
    required String trend,
    required List<double> data,
    required List<Color> colors,
    required List<String> labels,
  }) {
    if (data.isEmpty) return const SizedBox.shrink();

    final maxValue = data.reduce(math.max);
    final chartContainerHeight = 128.h; // h-32 equivalent
    final barContainerHeight = 100.h; // 100px as per React

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title and trend icon
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: ResponsiveTextStyles.textSm.copyWith(
                color: const Color(0xFF0A2342).withOpacity(0.7),
              ),
            ),
            Icon(
              controller.getTrendIcon(trend),
              size: 16.sp,
              color: const Color(0xFF0A2342).withOpacity(0.5),
            ),
          ],
        ),
        SizedBox(height: 8.h), // mb-2 equivalent
        
        // Chart bars - h-32 container
        SizedBox(
          height: chartContainerHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(data.length, (index) {
              final value = data[index];
              final heightPercent = maxValue > 0 ? (value / maxValue) : 0.0;
              final barHeight = heightPercent * barContainerHeight;
              
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2.w), // gap-2 equivalent
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Bar container with fixed height
                      SizedBox(
                        width: double.infinity,
                        height: barContainerHeight,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: barHeight),
                            duration: Duration(milliseconds: 500 + (index * 50)),
                            curve: Curves.easeOut,
                            builder: (context, animatedHeight, child) {
                              return Container(
                                width: double.infinity,
                                height: animatedHeight,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: colors,
                                  ),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(8.r), // rounded-t-lg
                                    topRight: Radius.circular(8.r),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 8.h), // gap-2 equivalent
                      // Day label
                      Text(
                        labels[index],
                        style: ResponsiveTextStyles.textXs.copyWith(
                          color: const Color(0xFF0A2342).withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

