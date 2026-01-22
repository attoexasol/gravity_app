import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/weight_history_controller.dart';
import '../../../../data/model/weight_history.dart';
import '../../../../app/theme/app_text_styles.dart';

class RecentEntriesSection extends StatelessWidget {
  final WeightHistoryController controller;

  const RecentEntriesSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
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
      child: Obx(() {
        // Loading state - Shimmer loader
        if (controller.isLoading.value) {
          return _buildShimmerLoader();
        }

        // Error state
        if (controller.hasError.value) {
          return _buildErrorState();
        }

        // Empty state
        if (controller.recentEntries.isEmpty) {
          return _buildEmptyState();
        }

        // Data state
        final entries = controller.recentEntries;
        final entryCount = entries.length;
        
        // Calculate height for 5 entries
        // Card structure:
        // - Container padding: 16.r * 2 = 32.h (top + bottom)
        // - Content: weight row (~24.h) + spacing (4.h) + date (~16.h) = ~44.h
        // - Card total: 32 + 44 = 76.h per card
        // - Bottom spacing between cards: 12.h
        // - Total per card with spacing: 76 + 12 = 88.h
        // For 5 visible cards: (88 * 4) + 76 = 428.h (last card has no bottom spacing)
        const double cardContentHeight = 76.0; // Card without bottom spacing
        const double cardSpacing = 12.0; // Spacing between cards
        final double maxVisibleHeight = ((cardContentHeight + cardSpacing) * 4 + cardContentHeight) * 1.h;
        final shouldScroll = entryCount > 5;
        
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Entries',
              style: ResponsiveTextStyles.textBase.copyWith(
                color: const Color(0xFF0A2342),
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 16.h),
            // Use SizedBox with fixed height for 5 entries, wrap ListView inside
            SizedBox(
              height: shouldScroll ? maxVisibleHeight : null,
              child: shouldScroll
                  ? ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: entryCount,
                      itemBuilder: (context, index) {
                        return _buildEntryCard(
                          entries[index],
                          index,
                          isLast: index == entryCount - 1,
                        );
                      },
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        entryCount,
                        (index) => _buildEntryCard(
                          entries[index],
                          index,
                          isLast: index == entryCount - 1,
                        ),
                      ),
                    ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildShimmerLoader() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title shimmer
        Container(
          width: 120.w,
          height: 20.h,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
        SizedBox(height: 16.h),
        // Entry shimmers
        ...List.generate(3, (index) => Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F6FA),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 100.w,
                        height: 18.h,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        width: 150.w,
                        height: 14.h,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 32.w,
                  height: 32.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Recent Entries',
          style: ResponsiveTextStyles.textBase.copyWith(
            color: const Color(0xFF0A2342),
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 24.h),
        Icon(
          Icons.error_outline,
          size: 48.sp,
          color: const Color(0xFF9CA3AF),
        ),
        SizedBox(height: 16.h),
        Text(
          controller.errorMessage.value.isNotEmpty
              ? controller.errorMessage.value
              : 'Failed to load weight history',
          style: ResponsiveTextStyles.textSm.copyWith(
            color: const Color(0xFF0A2342).withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 24.h),
        GestureDetector(
          onTap: controller.retry,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: const Color(0xFF00B8A9),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              'Retry',
              style: ResponsiveTextStyles.textBase.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Recent Entries',
          style: ResponsiveTextStyles.textBase.copyWith(
            color: const Color(0xFF0A2342),
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 24.h),
        Icon(
          Icons.inbox_outlined,
          size: 48.sp,
          color: const Color(0xFF9CA3AF),
        ),
        SizedBox(height: 16.h),
        Text(
          'No weight entries found',
          style: ResponsiveTextStyles.textSm.copyWith(
            color: const Color(0xFF0A2342).withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8.h),
        Text(
          'Start logging your weight to see your progress here',
          style: ResponsiveTextStyles.textXs.copyWith(
            color: const Color(0xFF0A2342).withOpacity(0.5),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Build individual entry card widget
  Widget _buildEntryCard(WeightEntry weightEntry, int index, {required bool isLast}) {
    final formattedDate = weightEntry.displayDate;
    
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12.h),
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        '${weightEntry.weight.toStringAsFixed(1)} kg',
                        style: ResponsiveTextStyles.textBase.copyWith(
                          color: const Color(0xFF0A2342),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (index == 0) ...[
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00B8A9),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            'Latest',
                            style: ResponsiveTextStyles.textXs.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    formattedDate,
                    style: ResponsiveTextStyles.textSm.copyWith(
                      color: const Color(0xFF0A2342).withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => controller.onEditEntry(weightEntry),
              child: Container(
                width: 32.w,
                height: 32.h,
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.edit,
                  color: const Color(0xFF0A2342).withOpacity(0.4),
                  size: 16.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

