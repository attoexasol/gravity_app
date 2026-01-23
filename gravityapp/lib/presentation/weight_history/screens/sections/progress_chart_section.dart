import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../controllers/weight_history_controller.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../data/model/weight_history.dart' as weight_history;

/// Progress Over Time Chart Widget
/// 
/// A reusable chart widget that displays weight progress over time with:
/// 
/// GRID & AXIS:
/// - Horizontal straight grid lines (subtle grey, 5-unit intervals)
/// - Vertical dotted grid lines (aligned with dates)
/// - Left and bottom borders only (top/right removed)
/// 
/// Y-AXIS (WEIGHT):
/// - Fixed 5-unit interval (70, 75, 80, 85)
/// - Auto-calculated bounds: minY = lowest - 2, maxY = highest + 2
/// - Integer labels on left side
/// 
/// X-AXIS (DATES):
/// - Index-based spacing (X = entry index)
/// - Weekly time points with auto-skip if overcrowded
/// - Format: "Apr 16", "Apr 23", "Apr 30"
/// 
/// LINE STYLE:
/// - Smooth curved line (2.5px thickness)
/// - Dots on all points
/// - Last point 20% larger (5.0 vs 4.0 radius)
/// 
/// TARGET LINE:
/// - Horizontal dashed line (amber/yellow, 1.5px)
/// - "Target" label on right side
/// 
/// PERFORMANCE:
/// - StatelessWidget to avoid rebuilds
/// - Uses Obx only for data changes
/// - Const widgets where possible

/// Simple weight entry model for chart
class ChartWeightEntry {
  final DateTime date;
  final double weight;

  const ChartWeightEntry({
    required this.date,
    required this.weight,
  });

  /// Convert from existing WeightEntry model
  factory ChartWeightEntry.fromApiEntry(weight_history.WeightEntry entry) {
    return ChartWeightEntry(
      date: DateTime.parse(entry.date),
      weight: entry.weight,
    );
  }
}

class ProgressChartSection extends StatelessWidget {
  final WeightHistoryController controller;

  const ProgressChartSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with title and optional range label
          Obx(() {
            final sortedEntries = _getSortedEntries();
            return _buildHeader();
          }),
          SizedBox(height: 16.h),
          
          // Chart content
          Obx(() {
            final sortedEntries = _getSortedEntries();
            
            if (sortedEntries.isEmpty) {
              return _buildEmptyState();
            }
            
            return _buildChart(sortedEntries);
          }),
          
          SizedBox(height: 12.h),
          
          // Helper text
          _buildHelperText(),
        ],
      ),
    );
  }

  /// Build header with title and optional range label
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Progress Over Time',
          style: ResponsiveTextStyles.textBase.copyWith(
            color: const Color(0xFF0A2342),
            fontWeight: FontWeight.w600,
          ),
        ),
        // Optional: Add range label here if needed
        // Text('Last 30 Days', style: ...)
      ],
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return SizedBox(
      height: 240.h,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: 48.sp,
              color: const Color(0xFF0A2342).withOpacity(0.3),
            ),
            SizedBox(height: 12.h),
            Text(
              'No weight data available',
              style: ResponsiveTextStyles.textSm.copyWith(
                color: const Color(0xFF0A2342).withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the main chart
  Widget _buildChart(List<ChartWeightEntry> sortedEntries) {
    // Calculate Y-axis bounds with padding: minY = lowest - 2, maxY = highest + 2
    final weights = sortedEntries.map((e) => e.weight).toList();
    final minWeight = weights.reduce((a, b) => a < b ? a : b);
    final maxWeight = weights.reduce((a, b) => a > b ? a : b);
    
    final minY = (minWeight - 2).roundToDouble();
    final maxY = (maxWeight + 2).roundToDouble();
    
    // Convert entries to FlSpot (using index as X value)
    final chartSpots = sortedEntries.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.weight);
    }).toList();
    
    // Calculate X-axis interval for weekly labels
    final xAxisInterval = _calculateXAxisInterval(sortedEntries.length);
    
    return SizedBox(
      height: 240.h,
      child: Stack(
        children: [
          // Main chart
          LineChart(
            LineChartData(
              // Y-axis bounds with padding
              minY: minY,
              maxY: maxY,
              
              // X-axis bounds (index-based)
              minX: 0,
              maxX: (sortedEntries.length - 1).toDouble(),
              
              // Clip data to chart bounds
              clipData: const FlClipData.all(),
              
              // Border configuration: show only left and bottom
              borderData: FlBorderData(
                show: true,
                border: Border(
                  left: BorderSide(
                    color: const Color(0xFF0A2342).withOpacity(0.2),
                    width: 1,
                  ),
                  bottom: BorderSide(
                    color: const Color(0xFF0A2342).withOpacity(0.2),
                    width: 1,
                  ),
                  top: BorderSide.none, // Remove top border
                  right: BorderSide.none, // Remove right border
                ),
              ),
              
              // Grid configuration
              gridData: FlGridData(
                show: true,
                // Horizontal grid lines (straight, subtle grey)
                horizontalInterval: 5.0, // Fixed 5-unit interval (70, 75, 80, 85)
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: const Color(0xFF0A2342).withOpacity(0.1), // Subtle grey
                    strokeWidth: 1,
                  );
                },
                drawHorizontalLine: true,
                drawVerticalLine: true,
                // Vertical grid lines (dotted, subtle grey)
                verticalInterval: xAxisInterval.toDouble(),
                getDrawingVerticalLine: (value) {
                  return FlLine(
                    color: const Color(0xFF0A2342).withOpacity(0.1), // Subtle grey
                    strokeWidth: 1,
                    dashArray: [4, 4], // Dashed pattern
                  );
                },
              ),
              
              // Titles configuration
              titlesData: FlTitlesData(
                // Top titles: disabled
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                // Right axis: disabled
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                // Left Y-axis: weight values with 5-unit interval
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50.w,
                    interval: 5.0, // Fixed 5-unit interval
                    getTitlesWidget: (value, meta) {
                      // Format as integer
                      return Padding(
                        padding: EdgeInsets.only(right: 8.w),
                        child: Text(
                          value.toInt().toString(),
                          style: ResponsiveTextStyles.textXs.copyWith(
                            color: const Color(0xFF0A2342).withOpacity(0.6),
                          ),
                          textAlign: TextAlign.right,
                        ),
                      );
                    },
                  ),
                ),
                // Bottom X-axis: date labels (weekly)
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40.h,
                    interval: xAxisInterval.toDouble(),
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < sortedEntries.length) {
                        final entry = sortedEntries[index];
                        final formattedDate = _formatShortDate(entry.date);
                        
                        return Padding(
                          padding: EdgeInsets.only(top: 8.h),
                          child: Text(
                            formattedDate,
                            style: ResponsiveTextStyles.textXs.copyWith(
                              color: const Color(0xFF0A2342).withOpacity(0.5),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              
              // Line bars data
              lineBarsData: [
                // Target/Goal line (dashed, amber/yellow)
                LineChartBarData(
                  spots: [
                    FlSpot(0, controller.goalWeight.value),
                    FlSpot((sortedEntries.length - 1).toDouble(), controller.goalWeight.value),
                  ],
                  isCurved: false,
                  color: const Color(0xFFFFB84D), // Amber/yellow
                  barWidth: 1.5,
                  dashArray: [5, 5], // Dashed pattern
                  dotData: const FlDotData(show: false),
                  preventCurveOverShooting: true,
                ),
                
                // Main weight trend line
                LineChartBarData(
                  spots: chartSpots,
                  isCurved: true,
                  curveSmoothness: 0.35, // Smooth, slightly curved
                  color: const Color(0xFF00B8A9), // Teal
                  barWidth: 2.5,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      final isLastPoint = index == chartSpots.length - 1;
                      // Last point is 20% larger (5.0 vs 4.0)
                      final radius = isLastPoint ? 5.0 : 4.0;
                      
                      return FlDotCirclePainter(
                        radius: radius.r,
                        color: const Color(0xFF00B8A9),
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                  preventCurveOverShooting: true,
                  belowBarData: BarAreaData(show: false),
                ),
              ],
              
              // Touch interaction disabled for cleaner UI
              lineTouchData: LineTouchData(
                enabled: false,
              ),
            ),
          ),
          
          // Target label positioned on the right side
          if (_isTargetVisible(controller.goalWeight.value, minY, maxY))
            Positioned(
              right: 0,
              top: _calculateTargetLabelY(
                controller.goalWeight.value,
                minY,
                maxY,
                240, // Chart height
              ),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  'Target',
                  style: ResponsiveTextStyles.textXs.copyWith(
                    color: const Color(0xFFFFB84D), // Amber/yellow to match goal line
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Build helper text at bottom
  Widget _buildHelperText() {
    return Center(
      child: Text(
        'Focus on the trend, not individual points',
        style: ResponsiveTextStyles.textXs.copyWith(
          color: const Color(0xFF0A2342).withOpacity(0.4),
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  /// Get sorted entries (oldest to newest)
  List<ChartWeightEntry> _getSortedEntries() {
    if (controller.weightHistory.isEmpty) return [];
    
    final validEntries = controller.weightHistory
        .where((entry) => entry.weight > 0)
        .map((entry) => ChartWeightEntry.fromApiEntry(entry))
        .toList();
    
    if (validEntries.isEmpty) return [];
    
    // Sort by date (oldest to newest)
    validEntries.sort((a, b) => a.date.compareTo(b.date));
    
    return validEntries;
  }

  /// Calculate X-axis interval for date labels (weekly spacing)
  int _calculateXAxisInterval(int dataPointCount) {
    if (dataPointCount <= 7) return 1; // Show all dates
    if (dataPointCount <= 14) return 2; // Show every other date
    if (dataPointCount <= 30) return 3; // Show every third date
    return 4; // Show every fourth date for larger datasets
  }

  /// Format short date (e.g., "Apr 16", "May 14")
  String _formatShortDate(DateTime date) {
    return DateFormat('MMM d', 'en_US').format(date);
  }

  /// Check if target weight is visible within chart bounds
  bool _isTargetVisible(double targetWeight, double minY, double maxY) {
    return targetWeight >= minY && targetWeight <= maxY;
  }

  /// Calculate Y position for target label
  double _calculateTargetLabelY(
    double targetWeight,
    double minY,
    double maxY,
    double chartHeight,
  ) {
    // Map target weight to pixel position
    // Formula: pixelY = chartHeight * (maxY - value) / (maxY - minY)
    // Account for padding (approximately 20px top, 40px bottom)
    const topPadding = 20.0;
    const bottomPadding = 40.0;
    final chartContentHeight = chartHeight - topPadding - bottomPadding;
    
    final normalized = (maxY - targetWeight) / (maxY - minY);
    final pixelY = topPadding + (normalized * chartContentHeight);
    
    // Center the label vertically on the line (label height ~20px)
    return (pixelY - 10).clamp(0.0, chartHeight - 20);
  }
}
