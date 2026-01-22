import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../controllers/weight_history_controller.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../data/model/weight_history.dart';


class ProgressChartSection extends StatelessWidget {
  final WeightHistoryController controller;

  const ProgressChartSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    // Fixed chart height
    const double chartHeight = 260.0;

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
          /// Title
          Text(
            'Progress Over Time',
            style: ResponsiveTextStyles.textBase.copyWith(
              color: const Color(0xFF0A2342),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16.h),

          /// Chart
          Obx(() {
            // Get sorted entries (oldest to newest) and filter invalid weights
            final sortedEntries = _getValidSortedEntriesForChart();
            
            if (sortedEntries.isEmpty) {
              return SizedBox(
                height: chartHeight.h,
                child: Center(
                  child: Text(
                    'No weight data available',
                    style: ResponsiveTextStyles.textSm.copyWith(
                      color: const Color(0xFF0A2342).withOpacity(0.5),
                    ),
                  ),
                ),
              );
            }

            // Build spots using INDEX as X values (0, 1, 2, ...)
            // Only use actual entries - NO missing days filled as 0
            final chartSpots = sortedEntries.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.weight.toDouble());
            }).toList();

            // Calculate Y-axis bounds with safe margins (do NOT use 0 as minY)
            final weights = sortedEntries.map((e) => e.weight).where((w) => w > 0).toList();
            if (weights.isEmpty) {
              return SizedBox(
                height: chartHeight.h,
                child: Center(
                  child: Text(
                    'No valid weight data',
                    style: ResponsiveTextStyles.textSm.copyWith(
                      color: const Color(0xFF0A2342).withOpacity(0.5),
                    ),
                  ),
                ),
              );
            }
            
            final minWeight = weights.reduce((a, b) => a < b ? a : b);
            final maxWeight = weights.reduce((a, b) => a > b ? a : b);
            final minY = (minWeight - 2).floorToDouble();
            final maxY = (maxWeight + 2).ceilToDouble();

            // Calculate dynamic chart width
            final screenWidth = MediaQuery.of(context).size.width;
            final chartWidth = (sortedEntries.length * 64.0).clamp(screenWidth, double.infinity);

            // Wrap in horizontal scroll (RTL - reverse so latest is on right)
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true, // RTL: latest data appears on RIGHT
              physics: const BouncingScrollPhysics(),
              child: SizedBox(
                width: chartWidth,
                height: chartHeight.h,
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                        left: 48.w, // Space for Y-axis labels
                        right: 48.w, // Space for Goal label and padding
                        top: 4.h, // Top margin
                        bottom: 4.h, // Bottom margin
                      ),
                      child: LineChart(
                        LineChartData(
                          minX: 0,
                          maxX: (sortedEntries.length - 1).toDouble(),
                          minY: minY,
                          maxY: maxY,
                          clipData: const FlClipData.all(), // Enable clipping
                          borderData: FlBorderData(show: false),

                          /// Grid
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 5,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: const Color(0xFF0A2342).withOpacity(0.1),
                                strokeWidth: 1,
                                dashArray: [3, 3],
                              );
                            },
                          ),

                          /// Axis titles
                          titlesData: FlTitlesData(
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),

                            /// Bottom dates - short labels with reduced density
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 32.h, // Reserved space for labels
                                interval: _calculateXAxisInterval(sortedEntries.length).toDouble(),
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();

                                  if (index >= 0 && index < sortedEntries.length) {
                                    final interval = _calculateXAxisInterval(sortedEntries.length);
                                    // Show label only when (index % interval == 0) or first/last
                                    if (index % interval != 0 && 
                                        index != 0 && 
                                        index != sortedEntries.length - 1) {
                                      return const SizedBox.shrink();
                                    }

                                    // Format short date label: "Jan 2" (no weekday)
                                    final entry = sortedEntries[index];
                                    final date = DateTime.parse(entry.date);
                                    final shortDate = _formatShortDate(date);

                                    return Padding(
                                      padding: EdgeInsets.only(top: 8.h),
                                      child: Text(
                                        shortDate,
                                        style: ResponsiveTextStyles.textXs.copyWith(
                                          color: const Color(0xFF0A2342).withOpacity(0.5),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),

                            /// Left Y-axis - clean alignment with proper reserved space
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 48.w, // Reserved space for clean alignment
                                interval: _calculateYAxisInterval(maxY - minY),
                                getTitlesWidget: (value, meta) {
                                  final interval = _calculateYAxisInterval(maxY - minY);
                                  // Show labels at intervals and at min/max
                                  if (value % interval < 0.1 || 
                                      (value - minY).abs() < 0.1 || 
                                      (value - maxY).abs() < 0.1) {
                                    return Padding(
                                      padding: EdgeInsets.only(right: 4.w),
                                      child: Text(
                                        value.toStringAsFixed(1),
                                        style: ResponsiveTextStyles.textXs.copyWith(
                                          color: const Color(0xFF0A2342).withOpacity(0.5),
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                          ),

                          /// Lines
                          lineBarsData: [
                            /// Goal line
                            LineChartBarData(
                              spots: [
                                FlSpot(0, controller.goalWeight),
                                FlSpot(
                                  sortedEntries.isEmpty 
                                      ? 0 
                                      : (sortedEntries.length - 1).toDouble(),
                                  controller.goalWeight,
                                ),
                              ],
                              isCurved: false,
                              color: const Color(0xFFD4AF37),
                              barWidth: 2,
                              dashArray: [5, 5],
                              dotData: const FlDotData(show: false),
                            ),

                            /// Weight trend - using index-based spots
                            LineChartBarData(
                              spots: chartSpots,
                              isCurved: true,
                              color: const Color(0xFF00B8A9),
                              barWidth: 3,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter:
                                    (spot, percent, barData, index) {
                                  return FlDotCirclePainter(
                                    radius: 5.r,
                                    color: const Color(0xFF00B8A9),
                                    strokeWidth: 2,
                                    strokeColor: Colors.white,
                                  );
                                },
                              ),
                            ),
                          ],
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipColor: (touchedSpot) => Colors.white,
                              tooltipRoundedRadius: 12.r,
                              tooltipPadding: EdgeInsets.all(12.r),
                              tooltipBorder: BorderSide(
                                color: const Color(0xFF0A2342).withOpacity(0.1),
                                width: 1,
                              ),
                              getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                                return touchedBarSpots.map((barSpot) {
                                  final index = barSpot.x.toInt();
                                  if (index >= 0 && index < sortedEntries.length) {
                                    final entry = sortedEntries[index];
                                    return LineTooltipItem(
                                      '${entry.displayDate}\n',
                                      ResponsiveTextStyles.textXs.copyWith(
                                        color: const Color(0xFF0A2342).withOpacity(0.6),
                                      ),
                                      children: [
                                        TextSpan(
                                          text: '${barSpot.y.toStringAsFixed(1)} kg',
                                          style: ResponsiveTextStyles.textLg.copyWith(
                                            color: const Color(0xFF00B8A9),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    );
                                  }
                                  return null;
                                }).toList();
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    /// Goal label - positioned within bounds (not clipped)
                    if (controller.goalWeight >= minY && controller.goalWeight <= maxY)
                      Positioned(
                        right: 12.w, // Increased padding to prevent clipping
                        top: _calculateGoalLabelPosition(
                          controller.goalWeight,
                          minY,
                          maxY,
                          chartHeight.h,
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4.r,
                              ),
                            ],
                          ),
                          child: Text(
                            'Goal',
                            style: ResponsiveTextStyles.textXs.copyWith(
                              color: const Color(0xFFD4AF37),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
          SizedBox(height: 16.h),

          /// Footer note
          Center(
            child: Text(
              'Focus on the trend, not individual points',
              style: ResponsiveTextStyles.textXs.copyWith(
                color: const Color(0xFF0A2342).withOpacity(0.5),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Get valid sorted entries (oldest to newest) for chart plotting
  /// Filters out invalid weights (<= 0) and only uses actual API entries
  List<WeightEntry> _getValidSortedEntriesForChart() {
    if (controller.weightHistory.isEmpty) return [];
    
    // Filter out invalid weights (<= 0) - do NOT fill missing days as 0
    final validEntries = controller.weightHistory
        .where((entry) => entry.weight > 0) // Only valid weights
        .toList();
    
    if (validEntries.isEmpty) return [];
    
    // Sort by date ascending (oldest to newest)
    final sorted = List<WeightEntry>.from(validEntries);
    sorted.sort((a, b) {
      final dateA = DateTime.parse(a.date);
      final dateB = DateTime.parse(b.date);
      return dateA.compareTo(dateB); // Ascending: oldest to newest
    });
    
    return sorted;
  }

  /// Format short date label: "Jan 22"
  String _formatShortDate(DateTime date) {
    final formatter = DateFormat('MMM d', 'en_US');
    return formatter.format(date);
  }

  /// Calculate optimal X-axis interval to prevent label overlap
  int _calculateXAxisInterval(int dataPointCount) {
    if (dataPointCount <= 7) return 1; // Show all if 7 or fewer
    if (dataPointCount <= 14) return 2; // Show every 2nd if 8-14
    if (dataPointCount <= 21) return 3; // Show every 3rd if 15-21
    return 4; // Show every 4th if more than 21
  }

  /// Calculate optimal Y-axis interval based on range
  double _calculateYAxisInterval(double range) {
    if (range <= 5) return 1.0;
    if (range <= 10) return 2.0;
    if (range <= 20) return 5.0;
    return 10.0; // For larger ranges
  }

  /// Calculate Goal label Y position within chart bounds
  double _calculateGoalLabelPosition(
    double goalWeight,
    double minY,
    double maxY,
    double chartHeight,
  ) {
    // Calculate position as percentage of chart height
    final yRange = maxY - minY;
    if (yRange <= 0) return chartHeight / 2;
    
    final normalizedPosition = (maxY - goalWeight) / yRange;
    final position = normalizedPosition * (chartHeight - 8.h); // Account for padding
    
    // Clamp position to stay within bounds (with margin for label height)
    return position.clamp(4.h, chartHeight - 24.h);
  }
}


// class ProgressChartSection extends StatelessWidget {
//   final WeightHistoryController controller;

//   const ProgressChartSection({
//     super.key,
//     required this.controller,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: EdgeInsets.symmetric(horizontal: 16.w),
//       padding: EdgeInsets.all(20.r),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20.r),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10.r,
//           ),
//         ],
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Progress Over Time',
//             style: ResponsiveTextStyles.textBase.copyWith(
//               color: const Color(0xFF0A2342),
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           SizedBox(height: 16.h),
//           SizedBox(
//             height: 256.h,
//             child: Stack(
//               children: [
//                 LineChart(
//                   LineChartData(
//                     gridData: FlGridData(
//                       show: true,
//                       drawVerticalLine: false,
//                       horizontalInterval: 5,
//                       getDrawingHorizontalLine: (value) {
//                         return FlLine(
//                           color: const Color(0xFF0A2342).withOpacity(0.1),
//                           strokeWidth: 1,
//                           dashArray: [3, 3],
//                         );
//                       },
//                     ),
//                     titlesData: FlTitlesData(
//                       show: true,
//                       rightTitles: const AxisTitles(
//                         sideTitles: SideTitles(showTitles: false),
//                       ),
//                       topTitles: const AxisTitles(
//                         sideTitles: SideTitles(showTitles: false),
//                       ),
//                       bottomTitles: AxisTitles(
//                         sideTitles: SideTitles(
//                           showTitles: true,
//                           reservedSize: 30.h,
//                           getTitlesWidget: (value, meta) {
//                             if (value.toInt() >= 0 && value.toInt() < controller.weightHistory.length) {
//                               return Padding(
//                                 padding: EdgeInsets.only(top: 8.h),
//                                 child: Text(
//                                   controller.weightHistory[value.toInt()].displayDate,
//                                   style: ResponsiveTextStyles.textXs.copyWith(
//                                     color: const Color(0xFF0A2342).withOpacity(0.5),
//                                   ),
//                                 ),
//                               );
//                             }
//                             return const Text('');
//                           },
//                         ),
//                       ),
//                       leftTitles: AxisTitles(
//                         sideTitles: SideTitles(
//                           showTitles: true,
//                           reservedSize: 50.w,
//                           interval: 5,
//                           getTitlesWidget: (value, meta) {
//                             // Only show labels at specific intervals
//                             if (value % 5 == 0 || value == controller.minY || value == controller.maxY) {
//                               return Text(
//                                 value.toStringAsFixed(1),
//                                 style: ResponsiveTextStyles.textXs.copyWith(
//                                   color: const Color(0xFF0A2342).withOpacity(0.5),
//                                 ),
//                               );
//                             }
//                             return const Text('');
//                           },
//                         ),
//                       ),
//                     ),
//                     borderData: FlBorderData(show: false),
//                     minX: 0,
//                     maxX: (controller.weightHistory.length - 1).toDouble(),
//                     minY: controller.minY,
//                     maxY: controller.maxY,
//                     lineBarsData: [
//                       // Goal reference line
//                       LineChartBarData(
//                         spots: [
//                           FlSpot(0, controller.goalWeight),
//                           FlSpot((controller.weightHistory.length - 1).toDouble(), controller.goalWeight),
//                         ],
//                         isCurved: false,
//                         color: const Color(0xFFD4AF37),
//                         barWidth: 2,
//                         dotData: const FlDotData(show: false),
//                         dashArray: [5, 5],
//                         belowBarData: BarAreaData(show: false),
//                       ),
//                       // Weight line
//                       LineChartBarData(
//                         spots: controller.chartSpots,
//                         isCurved: true,
//                         color: const Color(0xFF00B8A9),
//                         barWidth: 3,
//                         dotData: FlDotData(
//                           show: true,
//                           getDotPainter: (spot, percent, barData, index) {
//                             return FlDotCirclePainter(
//                               radius: 5.r,
//                               color: const Color(0xFF00B8A9),
//                               strokeWidth: 2,
//                               strokeColor: Colors.white,
//                             );
//                           },
//                         ),
//                         belowBarData: BarAreaData(show: false),
//                       ),
//                     ],
//                     lineTouchData: LineTouchData(
//                       touchTooltipData: LineTouchTooltipData(
//                         getTooltipColor: (touchedSpot) => Colors.white,
//                         tooltipRoundedRadius: 12.r,
//                         tooltipPadding: EdgeInsets.all(12.r),
//                         tooltipBorder: BorderSide(
//                           color: const Color(0xFF0A2342).withOpacity(0.1),
//                           width: 1,
//                         ),
//                         getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
//                           return touchedBarSpots.map((barSpot) {
//                             final index = barSpot.x.toInt();
//                             if (index >= 0 && index < controller.weightHistory.length) {
//                               final entry = controller.weightHistory[index];
//                               return LineTooltipItem(
//                                 '${entry.displayDate}\n',
//                                 ResponsiveTextStyles.textXs.copyWith(
//                                   color: const Color(0xFF0A2342).withOpacity(0.6),
//                                 ),
//                                 children: [
//                                   TextSpan(
//                                     text: '${barSpot.y.toStringAsFixed(1)} kg',
//                                     style: ResponsiveTextStyles.textLg.copyWith(
//                                       color: const Color(0xFF00B8A9),
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                   ),
//                                 ],
//                               );
//                             }
//                             return null;
//                           }).toList();
//                         },
//                       ),
//                     ),
//                   ),
//                 ),
//                 // Goal label
//                 Positioned(
//                   right: 8.w,
//                   top: ((controller.maxY - controller.goalWeight) / (controller.maxY - controller.minY)) * 256.h - 10.h,
//                   child: Container(
//                     padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(4.r),
//                     ),
//                     child: Text(
//                       'Goal',
//                       style: ResponsiveTextStyles.textXs.copyWith(
//                         color: const Color(0xFFD4AF37),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           SizedBox(height: 16.h),
//           Center(
//             child: Text(
//               'Focus on the trend, not individual points',
//               style: ResponsiveTextStyles.textXs.copyWith(
//                 color: const Color(0xFF0A2342).withOpacity(0.5),
//                 fontStyle: FontStyle.italic,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

