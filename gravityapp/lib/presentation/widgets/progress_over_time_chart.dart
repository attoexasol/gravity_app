import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../app/theme/app_text_styles.dart';

/// Simple weight entry model for the chart
class ChartWeightEntry {
  final DateTime date;
  final double weight;

  const ChartWeightEntry({
    required this.date,
    required this.weight,
  });
}

/// Reusable "Progress Over Time" chart widget
/// 
/// Features:
/// - Smooth curved line chart with dot indicators
/// - Dynamic Y-axis with padding (min = lowest - 1, max = highest + 1)
/// - Horizontal target/goal line with label
/// - Vertical dotted grid lines aligned with dates
/// - Horizontal light grid lines
/// - Responsive and performant
class ProgressOverTimeChart extends StatelessWidget {
  /// List of weight entries (will be auto-sorted by date)
  final List<ChartWeightEntry> entries;
  
  /// Target weight for the goal line
  final double targetWeight;
  
  /// Optional subtitle (e.g., "Last 30 Days")
  final String? rangeLabel;
  
  /// Chart height (default: 240px, range: 220-260px)
  final double? chartHeight;
  
  /// Card border radius (default: 18)
  final double? borderRadius;
  
  /// Padding inside card (default: 18)
  final double? cardPadding;

  const ProgressOverTimeChart({
    super.key,
    required this.entries,
    required this.targetWeight,
    this.rangeLabel,
    this.chartHeight,
    this.borderRadius,
    this.cardPadding,
  });

  @override
  Widget build(BuildContext context) {
    // Sort entries by date (oldest to newest)
    final sortedEntries = List<ChartWeightEntry>.from(entries)
      ..sort((a, b) => a.date.compareTo(b.date));

    return Container(
      padding: EdgeInsets.all((cardPadding ?? 18).r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular((borderRadius ?? 18).r),
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
          // Title and optional subtitle row
          _buildHeader(rangeLabel),
          SizedBox(height: 16.h),
          
          // Chart content
          if (sortedEntries.isEmpty)
            _buildEmptyState()
          else
            _buildChart(sortedEntries, targetWeight),
          
          SizedBox(height: 12.h),
          
          // Helper text
          _buildHelperText(),
        ],
      ),
    );
  }

  /// Build header with title and optional subtitle
  Widget _buildHeader(String? subtitle) {
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
        if (subtitle != null)
          Text(
            subtitle,
            style: ResponsiveTextStyles.textXs.copyWith(
              color: const Color(0xFF0A2342).withOpacity(0.6),
            ),
          ),
      ],
    );
  }

  /// Build empty state with shimmer placeholder
  Widget _buildEmptyState() {
    return SizedBox(
      height: (chartHeight ?? 240).h,
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
  Widget _buildChart(List<ChartWeightEntry> sortedEntries, double targetWeight) {
    // Calculate dynamic Y-axis bounds with padding
    final weights = sortedEntries.map((e) => e.weight).toList();
    final minWeight = weights.reduce((a, b) => a < b ? a : b);
    final maxWeight = weights.reduce((a, b) => a > b ? a : b);
    
    // Dynamic padding: min = lowest - 1, max = highest + 1
    final minY = (minWeight - 1).roundToDouble();
    final maxY = (maxWeight + 1).roundToDouble();
    
    // Generate Y-axis labels (whole numbers and .5 values)
    final yAxisLabels = _generateYAxisLabels(minY, maxY);
    
    // Convert entries to FlSpot for fl_chart
    final chartSpots = sortedEntries.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.weight);
    }).toList();
    
    // Calculate X-axis interval for date labels (auto-skip if overcrowded)
    final xAxisInterval = _calculateXAxisInterval(sortedEntries.length);
    
    return SizedBox(
      height: (chartHeight ?? 240).h,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r), // Rounded chart edges
        child: Stack(
          children: [
            // Main chart
            LineChart(
            LineChartData(
          // Y-axis bounds with dynamic padding
          minY: minY,
          maxY: maxY,
          
          // X-axis bounds
          minX: 0,
          maxX: (sortedEntries.length - 1).toDouble(),
          
          // Clip data to chart bounds
          clipData: const FlClipData.all(),
          
          // Remove chart borders
          borderData: FlBorderData(show: false),
          
          // Grid configuration
          gridData: FlGridData(
            show: true,
            // Horizontal light grid lines
            horizontalInterval: _calculateHorizontalInterval(minY, maxY),
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: const Color(0xFF0A2342).withOpacity(0.08),
                strokeWidth: 1,
              );
            },
            // Vertical dotted grid lines aligned with dates
            verticalInterval: xAxisInterval.toDouble(),
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: const Color(0xFF0A2342).withOpacity(0.12),
                strokeWidth: 1,
                dashArray: [4, 4], // Dotted line
              );
            },
            drawVerticalLine: true,
            drawHorizontalLine: true,
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
            // Left Y-axis: show whole numbers and .5 values
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50.w,
                interval: _calculateHorizontalInterval(minY, maxY),
                getTitlesWidget: (value, meta) {
                  // Show label if it's in our generated list
                  if (yAxisLabels.contains(value)) {
                    return Padding(
                      padding: EdgeInsets.only(right: 8.w),
                      child: Text(
                        value.toStringAsFixed(1),
                        style: ResponsiveTextStyles.textXs.copyWith(
                          color: const Color(0xFF0A2342).withOpacity(0.6),
                        ),
                        textAlign: TextAlign.right,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            // Bottom X-axis: date labels
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
                FlSpot(0, targetWeight),
                FlSpot((sortedEntries.length - 1).toDouble(), targetWeight),
              ],
              isCurved: false,
              color: const Color(0xFFFFB84D), // Amber/yellow
              barWidth: 1.5,
              dashArray: [5, 5],
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
                  // Last point is 20% larger
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
          if (_isTargetVisible(targetWeight, minY, maxY))
            Positioned(
              right: 0,
              top: _calculateTargetLabelY(targetWeight, minY, maxY, chartHeight ?? 240),
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

  /// Generate Y-axis labels (whole numbers and .5 values)
  /// Example: 69.5, 70.0, 70.5, 71.0, etc.
  List<double> _generateYAxisLabels(double minY, double maxY) {
    final labels = <double>[];
    double current = minY;
    
    // Round to nearest 0.5
    current = (current * 2).roundToDouble() / 2;
    
    while (current <= maxY) {
      labels.add(current);
      current += 0.5;
    }
    
    return labels;
  }

  /// Calculate horizontal grid interval (0.5 or 1.0 based on range)
  double _calculateHorizontalInterval(double minY, double maxY) {
    final range = maxY - minY;
    // If range is small, use 0.5 intervals; otherwise use 1.0
    return range <= 10 ? 0.5 : 1.0;
  }

  /// Calculate X-axis interval for date labels (auto-skip if overcrowded)
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
    final normalized = (maxY - targetWeight) / (maxY - minY);
    final pixelY = normalized * chartHeight;
    
    // Center the label vertically on the line (label height ~20px)
    return (pixelY - 10).clamp(0.0, chartHeight - 20);
  }
}
