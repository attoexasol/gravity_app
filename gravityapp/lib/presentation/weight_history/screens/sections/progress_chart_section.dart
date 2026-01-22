import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../controllers/weight_history_controller.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../data/model/weight_history.dart';

class ProgressChartSection extends StatefulWidget {
  final WeightHistoryController controller;

  const ProgressChartSection({
    super.key,
    required this.controller,
  });

  @override
  State<ProgressChartSection> createState() => _ProgressChartSectionState();
}

class _ProgressChartSectionState extends State<ProgressChartSection> {
  final ScrollController _scrollController = ScrollController();
  bool _isFocusedOnLast7Days = false;
  int? _selectedPointIndex;
  DateTime? _lastTapTime;
  static const Duration _tapDebounceDuration = Duration(milliseconds: 300);
  
  /// SINGLE Y-axis scale mapping function used everywhere
  /// Exact formula: pixelY = chartHeight * (maxY - value) / (maxY - minY)
  /// This ensures pixel-perfect alignment between grid lines, labels, and data points
  /// 
  /// Parameters:
  /// - value: The Y-axis value (weight in kg)
  /// - minY: Minimum Y-axis value
  /// - maxY: Maximum Y-axis value
  /// - chartHeight: Total chart height in pixels
  /// - topPadding: Top padding (must match chart padding)
  /// 
  /// Returns: Pixel Y position from top of chart container
  double _mapYToPixel(
    double value,
    double minY,
    double maxY,
    double chartHeight,
    double topPadding,
  ) {
    if (maxY <= minY) return topPadding;
    
    // Exact formula: pixelY = chartHeight * (maxY - value) / (maxY - minY)
    // Adjusted for padding: pixelY = topPadding + (chartHeight - 2*topPadding) * (maxY - value) / (maxY - minY)
    final chartContentHeight = chartHeight - (2 * topPadding);
    final normalized = (maxY - value) / (maxY - minY);
    return topPadding + (normalized * chartContentHeight);
  }
  
  /// Check if a value is a major tick (whole numbers: 70, 71, 72, 73, 74, 75)
  /// Major ticks are whole numbers, minor ticks are 0.5 increments
  bool _isMajorTick(double value) {
    // Check if value is a whole number (no decimal part)
    // Major ticks: 70, 71, 72, 73, 74, 75
    // Minor ticks: 70.5, 71.5, 72.5, 73.5, 74.5
    return value == value.roundToDouble();
  }

  @override
  void initState() {
    super.initState();
    // Clear selection when scrolling
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Clear selection when scrolling
  void _onScroll() {
    if (_selectedPointIndex != null) {
      setState(() {
        _selectedPointIndex = null;
      });
    }
  }

  /// Handle tap on data point - toggle behavior
  void _handlePointTap(int tappedIndex) {
    // Prevent accidental multi-trigger
    final now = DateTime.now();
    if (_lastTapTime != null && 
        now.difference(_lastTapTime!) < _tapDebounceDuration) {
      return;
    }
    _lastTapTime = now;

    setState(() {
      // Toggle logic: if same point, hide; if different, show new
      if (_selectedPointIndex == tappedIndex) {
        _selectedPointIndex = null; // Hide tooltip
      } else {
        _selectedPointIndex = tappedIndex; // Show tooltip for new point
      }
    });
  }

  /// Dismiss tooltip when tapping outside
  void _dismissTooltip() {
    if (_selectedPointIndex != null) {
      setState(() {
        _selectedPointIndex = null;
      });
    }
  }

  /// Focus on last 7 days - scroll to end
  void _focusLast7Days() {
    setState(() {
      _isFocusedOnLast7Days = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Reset focus to show all data
  void _resetFocus() {
    setState(() {
      _isFocusedOnLast7Days = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const double chartHeight = 380.0; // Increased height for better visibility
    const double yAxisWidth = 52.0;

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
          /// Title and Focus Button Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress Over Time',
                style: ResponsiveTextStyles.textBase.copyWith(
                  color: const Color(0xFF0A2342),
                  fontWeight: FontWeight.w600,
                ),
              ),
              // Focus Last 7 Days button
              Obx(() {
                final sortedEntries = _getValidSortedEntriesForChart();
                if (sortedEntries.length > 7) {
                  return TextButton(
                    onPressed: _isFocusedOnLast7Days ? _resetFocus : _focusLast7Days,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      _isFocusedOnLast7Days ? 'Show All' : 'Last 7 Days',
                      style: ResponsiveTextStyles.textXs.copyWith(
                        color: const Color(0xFF00B8A9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          ),
          SizedBox(height: 16.h),

          /// Two-layer layout: Fixed Y-axis + Scrollable Chart
          Obx(() {
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

            // Fixed Y-axis bounds: 70kg to 75kg (no auto-scaling)
            const double minY = 70.0;
            const double maxY = 75.0;

            // Generate Y-axis labels
            final yAxisLabels = _generateYAxisLabels(minY, maxY);

            // Determine visible range for "Last 7 Days" focus
            int visibleStartIndex = 0;
            int visibleEndIndex = sortedEntries.length - 1;
            int visibleDataPoints = sortedEntries.length;
            
            if (_isFocusedOnLast7Days && sortedEntries.length > 7) {
              visibleStartIndex = sortedEntries.length - 7;
              visibleEndIndex = sortedEntries.length - 1;
              visibleDataPoints = 7;
            }

            // Calculate dynamic chart width
            final screenWidth = MediaQuery.of(context).size.width;
            final baseWidth = visibleDataPoints * 64.0;
            final chartWidth = baseWidth.clamp(screenWidth - 32.w - yAxisWidth, double.infinity);

            // Define consistent padding used everywhere
            // Increased bottom padding to ensure dates are placed BELOW grid lines
            const double topPadding = 8.0;
            const double bottomPadding = 40.0; // Increased to place dates below 70kg grid line
            
            return SizedBox(
              height: chartHeight.h,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Left Layer: Fixed Y-axis labels
                  SizedBox(
                    width: yAxisWidth.w,
                    height: chartHeight.h,
                    child: _buildFixedYAxis(yAxisLabels, minY, maxY, chartHeight, topPadding),
                  ),
                  
                  /// Right Layer: Horizontally scrollable chart
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      reverse: true, // Latest data on right
                      physics: const BouncingScrollPhysics(),
                      child: SizedBox(
                        width: chartWidth,
                        height: chartHeight.h,
                        child: _buildScrollableChart(
                          sortedEntries,
                          minY,
                          maxY,
                          visibleStartIndex,
                          visibleEndIndex,
                          chartHeight,
                          topPadding,
                          bottomPadding,
                        ),
                      ),
                    ),
                  ),
                ],
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

  /// Build fixed Y-axis labels on the left
  /// Uses SINGLE scale function for pixel-perfect alignment with grid lines
  /// Shows all labels: 70, 71, 72, 73, 74, 75
  Widget _buildFixedYAxis(
    List<double> labels,
    double minY,
    double maxY,
    double chartHeight,
    double topPadding,
  ) {
    return Padding(
      padding: EdgeInsets.only(top: topPadding, bottom: topPadding),
      child: Stack(
        clipBehavior: Clip.none,
        children: labels.map((value) {
          // Use SINGLE scale function - exact same calculation as grid lines
          final pixelY = _mapYToPixel(value, minY, maxY, chartHeight, topPadding);
          
          // Adjust for container padding to align with grid lines
          final adjustedY = pixelY - topPadding;
          
          return Positioned(
            top: adjustedY - 8.h, // Center text vertically on grid line
            right: 0,
            child: Text(
              value.toStringAsFixed(0),
              style: ResponsiveTextStyles.textXs.copyWith(
                color: const Color(0xFF0A2342).withOpacity(0.6),
                fontWeight: _isMajorTick(value) ? FontWeight.w600 : FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Build scrollable chart content (without Y-axis)
  /// Renders grid lines manually using SINGLE scale function for perfect alignment
  Widget _buildScrollableChart(
    List<WeightEntry> sortedEntries,
    double minY,
    double maxY,
    int visibleStartIndex,
    int visibleEndIndex,
    double chartHeight,
    double topPadding,
    double bottomPadding,
  ) {
    // Build spots using INDEX as X values
    final chartSpots = sortedEntries.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.weight.toDouble());
    }).toList();

    // Generate all grid line values (every 1 kg)
    final gridLines = _generateGridLines(minY, maxY);

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        // Manual grid lines rendered first (behind chart)
        Padding(
          padding: EdgeInsets.only(
            right: 52.w, // Space for Goal label
            top: topPadding.h,
            bottom: bottomPadding.h,
          ),
          child: SizedBox(
            width: double.infinity,
            height: (chartHeight - topPadding - bottomPadding).h,
            child: CustomPaint(
              painter: _GridLinePainter(
                gridLines: gridLines,
                minY: minY,
                maxY: maxY,
                chartHeight: chartHeight - topPadding - bottomPadding,
                topPadding: 0, // Already accounted in padding
                isMajorTick: _isMajorTick,
              ),
            ),
          ),
        ),
        
        // Chart overlay (on top of grid lines)
        Padding(
          padding: EdgeInsets.only(
            right: 52.w, // Space for Goal label
            top: topPadding.h,
            bottom: bottomPadding.h,
          ),
          child: LineChart(
            LineChartData(
              minX: _isFocusedOnLast7Days 
                  ? visibleStartIndex.toDouble() 
                  : 0,
              maxX: visibleEndIndex.toDouble(),
              minY: minY,
              maxY: maxY,
              // Allow data points outside the fixed range to be visible
              // This ensures accurate positioning relative to the fixed scale
              clipData: const FlClipData.none(),
              borderData: FlBorderData(show: false),

              /// Disable fl_chart's grid system - we render manually for perfect alignment
              gridData: const FlGridData(
                show: false, // Disabled - using manual grid lines
              ),

              /// Axis titles - hide left Y-axis since it's fixed on the left
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false), // Hidden - using fixed Y-axis
                ),

                /// Bottom dates - placed BELOW grid lines with proper spacing
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50.h, // Increased reserved size to place dates below grid lines
                    interval: _calculateXAxisInterval(sortedEntries.length).toDouble(),
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();

                      if (index >= 0 && index < sortedEntries.length) {
                        final interval = _calculateXAxisInterval(sortedEntries.length);
                        if (index % interval != 0 && 
                            index != 0 && 
                            index != sortedEntries.length - 1) {
                          return const SizedBox.shrink();
                        }

                        final entry = sortedEntries[index];
                        final date = DateTime.parse(entry.date);
                        final shortDate = _formatShortDate(date);

                        // Place dates BELOW the chart area, not overlapping with grid lines
                        return Padding(
                          padding: EdgeInsets.only(top: 12.h), // Additional padding to separate from grid
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
              ),

              /// Lines
              lineBarsData: [
                /// Goal line (dashed baseline)
                LineChartBarData(
                  spots: [
                    FlSpot(_isFocusedOnLast7Days 
                        ? visibleStartIndex.toDouble() 
                        : 0, 
                        widget.controller.goalWeight),
                    FlSpot(visibleEndIndex.toDouble(), widget.controller.goalWeight),
                  ],
                  isCurved: false,
                  color: const Color(0xFFD4AF37),
                  barWidth: 2,
                  dashArray: [5, 5],
                  dotData: const FlDotData(show: false),
                ),

                /// Weight trend line with highlightable dots
                /// Smooth curved interpolation for professional fitness app appearance
                LineChartBarData(
                  spots: chartSpots,
                  isCurved: true,
                  curveSmoothness: 0.35, // Smooth, slightly curved interpolation (0.0 = straight, 1.0 = very curved)
                  color: const Color(0xFF00B8A9),
                  barWidth: 3,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      final isSelected = _selectedPointIndex == index;
                      return FlDotCirclePainter(
                        radius: isSelected ? 7.r : 5.r,
                        color: isSelected 
                            ? const Color(0xFF0A2342) 
                            : const Color(0xFF00B8A9),
                        strokeWidth: isSelected ? 3 : 2,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                ),
              ],
              
              /// Custom touch interaction for tap-to-toggle
              lineTouchData: LineTouchData(
                enabled: true,
                touchSpotThreshold: 30, // Larger threshold for easier tapping
                getTouchLineStart: (barData, spotIndex) {
                  return 0;
                },
                getTouchLineEnd: (barData, spotIndex) {
                  return double.infinity;
                },
                // Disable built-in tooltip - we use custom one
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (touchedSpot) => Colors.transparent,
                  tooltipRoundedRadius: 0,
                  tooltipPadding: EdgeInsets.zero,
                  getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                    // Return tooltip items matching touched spots count (but invisible)
                    // This is required by fl_chart - count must match
                    return touchedBarSpots.map((spot) {
                      return LineTooltipItem(
                        '',
                        const TextStyle(
                          color: Colors.transparent,
                          fontSize: 0,
                        ),
                      );
                    }).toList();
                  },
                ),
                handleBuiltInTouches: true,
                // Handle tap events for toggle behavior
                touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
                  if (event is FlTapUpEvent) {
                    if (touchResponse != null && touchResponse.lineBarSpots != null) {
                      final lineBarSpots = touchResponse.lineBarSpots!;
                      if (lineBarSpots.isNotEmpty) {
                        // Tapped on a data point
                        final spot = lineBarSpots.first;
                        final index = spot.x.toInt();
                        if (index >= 0 && index < sortedEntries.length) {
                          _handlePointTap(index);
                        }
                      } else {
                        // Tapped on empty chart area - dismiss tooltip
                        _dismissTooltip();
                      }
                    } else {
                      // No touch response - tapped outside chart
                      _dismissTooltip();
                    }
                  } else if (event is FlPanStartEvent) {
                    // Dismiss on pan start (scrolling)
                    _dismissTooltip();
                  }
                },
              ),
            ),
          ),
        ),
        
        /// Goal label
        if (widget.controller.goalWeight >= minY && 
            widget.controller.goalWeight <= maxY)
          Positioned(
            right: 16.w,
            top: _calculateGoalLabelPosition(
              widget.controller.goalWeight,
              minY,
              maxY,
              chartHeight,
              topPadding,
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
        
        /// Custom animated tooltip
        if (_selectedPointIndex != null && 
            _selectedPointIndex! >= 0 && 
            _selectedPointIndex! < sortedEntries.length)
          _buildCustomTooltip(
            sortedEntries[_selectedPointIndex!],
            sortedEntries,
            minY,
            maxY,
            chartHeight,
            topPadding,
          ),
      ],
    );
  }

  /// Build custom animated tooltip
  Widget _buildCustomTooltip(
    WeightEntry entry,
    List<WeightEntry> sortedEntries,
    double minY,
    double maxY,
    double chartHeight,
    double topPadding,
  ) {
    final index = _selectedPointIndex!;
    final date = DateTime.parse(entry.date);
    final formattedDate = DateFormat('MMM d, yyyy', 'en_US').format(date);
    
    // Calculate tooltip position based on data point
    final chartSpots = sortedEntries.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.weight.toDouble());
    }).toList();
    
    if (index >= chartSpots.length) return const SizedBox.shrink();
    
    final spot = chartSpots[index];
    
    // Use SINGLE scale function for perfect alignment with grid lines
    final yPosition = _mapYToPixel(spot.y, minY, maxY, chartHeight, topPadding);
    
    // Calculate X position based on index and chart width
    final screenWidth = MediaQuery.of(context).size.width;
    final yAxisWidth = 52.0;
    final chartWidth = (sortedEntries.length * 64.0).clamp(screenWidth - 32.w - yAxisWidth, double.infinity);
    final maxIndex = sortedEntries.length > 1 ? sortedEntries.length - 1 : 1;
    final normalizedX = index / maxIndex;
    final xPosition = normalizedX * (chartWidth - 52.w); // Account for right padding
    
    // Position tooltip above the point, centered horizontally
    final tooltipWidth = 120.w;
    final tooltipLeft = (xPosition - tooltipWidth / 2).clamp(8.w, chartWidth - tooltipWidth - 52.w);
    final tooltipTop = (yPosition - 60.h).clamp(8.h, chartHeight - 100.h);
    
    return Positioned(
      left: tooltipLeft,
      top: tooltipTop,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.8 + (0.2 * value), // Scale from 0.8 to 1.0
              child: Opacity(
                opacity: value,
                child: Container(
                  constraints: BoxConstraints(maxWidth: tooltipWidth),
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 10.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8.r,
                        offset: Offset(0, 2.h),
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xFF0A2342).withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formattedDate,
                        style: ResponsiveTextStyles.textXs.copyWith(
                          color: const Color(0xFF0A2342).withOpacity(0.6),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '${entry.weight.toStringAsFixed(1)} kg',
                        style: ResponsiveTextStyles.textLg.copyWith(
                          color: const Color(0xFF00B8A9),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Generate Y-axis labels for fixed range (whole numbers only: 70, 71, 72, 73, 74, 75)
  /// Shows only major grid line labels (whole numbers), not 0.5 increments
  List<double> _generateYAxisLabels(double minY, double maxY) {
    // For fixed range 70-75kg, show only whole number labels: 70, 71, 72, 73, 74, 75
    // (0.5 increments are shown as grid lines but not labeled)
    final labels = <double>[];
    int current = minY.round(); // 70
    final maxYInt = maxY.round(); // 75
    
    while (current <= maxYInt) {
      labels.add(current.toDouble());
      current += 1;
    }
    
    return labels; // [70.0, 71.0, 72.0, 73.0, 74.0, 75.0]
  }

  /// Fixed Y-axis bounds: Always returns 70kg to 75kg
  /// This ensures the chart scale remains stable and doesn't auto-adjust
  Map<String, double> _calculateYAxisBounds(List<WeightEntry> entries) {
    // Fixed range: 70kg to 75kg (no auto-scaling)
    return {'min': 70.0, 'max': 75.0};
  }

  /// Get valid sorted entries (oldest to newest)
  List<WeightEntry> _getValidSortedEntriesForChart() {
    if (widget.controller.weightHistory.isEmpty) return [];
    
    final validEntries = widget.controller.weightHistory
        .where((entry) => entry.weight > 0)
        .toList();
    
    if (validEntries.isEmpty) return [];
    
    final sorted = List<WeightEntry>.from(validEntries);
    sorted.sort((a, b) {
      final dateA = DateTime.parse(a.date);
      final dateB = DateTime.parse(b.date);
      return dateA.compareTo(dateB);
    });
    
    return sorted;
  }

  /// Format short date label: "Jan 8"
  String _formatShortDate(DateTime date) {
    final formatter = DateFormat('MMM d', 'en_US');
    return formatter.format(date);
  }

  /// Calculate optimal X-axis interval
  int _calculateXAxisInterval(int dataPointCount) {
    if (dataPointCount <= 10) return 1;
    if (dataPointCount <= 20) return 2;
    return 3;
  }

  /// Calculate Goal label Y position
  /// Uses SINGLE scale function for perfect alignment
  double _calculateGoalLabelPosition(
    double goalWeight,
    double minY,
    double maxY,
    double chartHeight,
    double topPadding,
  ) {
    // Use SINGLE scale function for consistent positioning
    final position = _mapYToPixel(goalWeight, minY, maxY, chartHeight, topPadding);
    return position.clamp(topPadding.h, chartHeight - 28.h);
  }

  /// Generate all grid line values (every 0.5 kg interval for fixed 70-75kg range)
  /// Returns list of Y values where grid lines should be drawn
  /// Includes: 70.0, 70.5, 71.0, 71.5, 72.0, 72.5, 73.0, 73.5, 74.0, 74.5, 75.0 (11 lines, minimum 10)
  List<double> _generateGridLines(double minY, double maxY) {
    final lines = <double>[];
    
    // For fixed range 70-75kg, generate lines at every 0.5kg interval
    // This creates 11 grid lines (minimum 10 as required): 70.0, 70.5, 71.0, 71.5, 72.0, 72.5, 73.0, 73.5, 74.0, 74.5, 75.0
    double current = minY; // 70.0
    final maxYValue = maxY; // 75.0
    const interval = 0.5; // 0.5kg intervals
    
    while (current <= maxYValue + 0.01) { // Add small epsilon to handle floating point precision
      lines.add(current);
      current += interval;
    }
    
    return lines;
  }
}

/// Custom painter for manual grid line rendering
/// Uses SINGLE scale function to ensure perfect alignment with labels and data points
class _GridLinePainter extends CustomPainter {
  final List<double> gridLines;
  final double minY;
  final double maxY;
  final double chartHeight;
  final double topPadding;
  final bool Function(double) isMajorTick;

  _GridLinePainter({
    required this.gridLines,
    required this.minY,
    required this.maxY,
    required this.chartHeight,
    required this.topPadding,
    required this.isMajorTick,
  });

  /// SINGLE Y-axis scale mapping function
  /// Exact formula: pixelY = chartHeight * (maxY - value) / (maxY - minY)
  /// Uses canvas size for accurate pixel positioning
  /// Note: topPadding is 0 because canvas is already inside padding
  double _mapYToPixel(double value, Size canvasSize) {
    if (maxY <= minY) return 0;
    
    // Canvas height is already (chartHeight - 2*topPadding)
    // Since topPadding = 0 in this context, we use canvas height directly
    // Formula: pixelY = (maxY - value) / (maxY - minY) * canvasHeight
    final normalized = (maxY - value) / (maxY - minY);
    return normalized * canvasSize.height;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round; // Rounded line caps for cleaner appearance

    for (final value in gridLines) {
      final isMajor = isMajorTick(value);
      final pixelY = _mapYToPixel(value, size);

      if (isMajor) {
        // Major grid line (whole numbers: 70, 71, 72, 73, 74, 75): BOLD, dark, labeled
        paint
          ..color = const Color(0xFF0A2342).withOpacity(0.3)
          ..strokeWidth = 2.5;
      } else {
        // Minor grid line (0.5 increments: 70.5, 71.5, 72.5, 73.5, 74.5): normal/light, unlabeled
        paint
          ..color = const Color(0xFF0A2342).withOpacity(0.12)
          ..strokeWidth = 1.0;
      }

      // Draw horizontal line from exact start (0) to exact end (size.width) for perfect alignment
      // Ensure endpoints match chart boundaries perfectly - no gaps or overflows
      final startX = 0.0;
      final endX = size.width;
      
      // Use precise pixel coordinates - ensure lines extend to exact boundaries
      canvas.drawLine(
        Offset(startX, pixelY),
        Offset(endX, pixelY),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_GridLinePainter oldDelegate) {
    return oldDelegate.gridLines != gridLines ||
        oldDelegate.minY != minY ||
        oldDelegate.maxY != maxY ||
        oldDelegate.chartHeight != chartHeight;
  }
}