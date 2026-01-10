import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../controllers/weight_history_controller.dart';
import '../../../../app/theme/app_text_styles.dart';


class ProgressChartSection extends StatelessWidget {
  final WeightHistoryController controller;

  const ProgressChartSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    // 🔥 Compact chart height
    final double chartHeight = 190.h;

    // 🔥 Tight Y-axis range based on data
    final yValues = controller.chartSpots.map((e) => e.y).toList();
    final minY = yValues.reduce((a, b) => a < b ? a : b) - 2;
    final maxY = yValues.reduce((a, b) => a > b ? a : b) + 2;

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
          SizedBox(
            height: chartHeight,
            child: Stack(
              children: [
                LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: (controller.weightHistory.length - 1).toDouble(),
                    minY: minY,
                    maxY: maxY,

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

                      /// Bottom dates (🔥 overlap fixed)
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28.h,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();

                            // 🔥 show label every 2 points only
                            if (index % 2 != 0) {
                              return const SizedBox.shrink();
                            }

                            if (index >= 0 &&
                                index < controller.weightHistory.length) {
                              return Padding(
                                padding: EdgeInsets.only(top: 8.h),
                                child: Text(
                                  controller
                                      .weightHistory[index].displayDate,
                                  style: ResponsiveTextStyles.textXs.copyWith(
                                    color: const Color(0xFF0A2342)
                                        .withOpacity(0.5),
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),

                      /// Left Y-axis
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 48.w,
                          interval: 5,
                          getTitlesWidget: (value, meta) {
                            if (value % 5 == 0 ||
                                value == minY ||
                                value == maxY) {
                              return Text(
                                value.toStringAsFixed(1),
                                style:
                                    ResponsiveTextStyles.textXs.copyWith(
                                  color: const Color(0xFF0A2342)
                                      .withOpacity(0.5),
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
                            (controller.weightHistory.length - 1)
                                .toDouble(),
                            controller.goalWeight,
                          ),
                        ],
                        isCurved: false,
                        color: const Color(0xFFD4AF37),
                        barWidth: 2,
                        dashArray: [5, 5],
                        dotData: const FlDotData(show: false),
                      ),

                      /// Weight trend
                      LineChartBarData(
                        spots: controller.chartSpots,
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
                            if (index >= 0 && index < controller.weightHistory.length) {
                              final entry = controller.weightHistory[index];
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

                /// Goal label (🔥 dynamic position)
                Positioned(
                  right: 8.w,
                  top: ((maxY - controller.goalWeight) /
                              (maxY - minY)) *
                          chartHeight -
                      8.h,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      'Goal',
                      style: ResponsiveTextStyles.textXs.copyWith(
                        color: const Color(0xFFD4AF37),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

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

