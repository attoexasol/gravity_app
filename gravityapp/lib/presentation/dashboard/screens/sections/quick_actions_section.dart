import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../controllers/dashboard_controller.dart';

class QuickActionsSection extends StatelessWidget {
  final DashboardController controller;

  const QuickActionsSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Quick Actions",
            style: ResponsiveTextStyles.textLg.copyWith(
              fontWeight: FontWeight.w500,
              color: const Color(0xFF0A2342),
            ),
          ),
          SizedBox(height: 15.h),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10.h,
            crossAxisSpacing: 10.w,
            childAspectRatio: 2.5,
            children: [
              // Fasting Mode
              Builder(
                builder: (context) => _QuickActionCard(
                  icon: Icons.restaurant_outlined,
                  title: 'Fasting Mode',
                  gradient: const [Color(0xFFD4AF37), Color(0xFFB8941F)],
                  onTap: () => _showFastingModal(context),
                ),
              ),
              // Upload Meal
              _QuickActionCard(
                icon: Icons.camera_alt_outlined,
                title: 'Upload Meal',
                gradient: const [Color(0xFFF9A71F), Color(0xFFF57C00)],
                onTap: () => Get.toNamed('/meal-upload'),
              ),
              // Add Weight
              Builder(
                builder: (context) => _QuickActionCard(
                  icon: Icons.monitor_weight_outlined,
                  title: 'Add Weight',
                  gradient: const [Color(0xFF00B8A9), Color(0xFF0A2342)],
                  onTap: () => _showWeightModal(context),
                ),
              ),
              // Log Sleep
              Builder(
                builder: (context) => _QuickActionCard(
                  icon: Icons.bedtime_outlined,
                  title: 'Log Sleep',
                  gradient: const [Color(0xFF6C63FF), Color(0xFF7F82FF)],
                  onTap: () => _showSleepModal(context),
                ),
              ),
              // Log Hydration
              Builder(
                builder: (context) => _QuickActionCard(
                  icon: Icons.water_drop_outlined,
                  title: 'Log Hydration',
                  gradient: const [Color(0xFF00B8A9), Color(0xFF00E5D3)],
                  onTap: () => _showHydrationModal(context),
                ),
              ),
              // Log Steps
              Builder(
                builder: (context) => _QuickActionCard(
                  icon: Icons.directions_walk_outlined,
                  title: 'Log Steps',
                  gradient: const [Color(0xFF00B8A9), Color(0xFF00D4C3)],
                  onTap: () => _showStepsModal(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Show Weight Entry Modal
  void _showWeightModal(BuildContext context) {
    ManualEntryModal.show(
      context: context,
      title: 'Add Weight',
      icon: Icons.monitor_weight_outlined,
      iconColor: const Color(0xFF00B8A9),
      value: controller.weightInput.value,
      onChanged: (value) => controller.weightInput.value = value,
      onSubmit: () => controller.handleWeightSubmit(),
      onClose: () => controller.weightInput.value = '',
      placeholder: 'Enter weight in kg',
      unit: 'kg',
      gradient: const [Color(0xFF00B8A9), Color(0xFF0A2342)],
      description: 'Your weight will be recorded and tracked over time.',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
    );
  }

  /// Show Sleep Entry Modal
  void _showSleepModal(BuildContext context) {
    ManualEntryModal.show(
      context: context,
      title: 'Log Sleep',
      icon: Icons.bedtime_outlined,
      iconColor: const Color(0xFF6C63FF),
      value: controller.sleepInput.value,
      onChanged: (value) => controller.sleepInput.value = value,
      onSubmit: () => controller.handleSleepSubmit(),
      onClose: () => controller.sleepInput.value = '',
      placeholder: 'Enter hours slept',
      unit: 'hours',
      gradient: const [Color(0xFF6C63FF), Color(0xFF7F82FF)],
      description: 'Track your sleep patterns for better health insights.',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
    );
  }

  /// Show Hydration Entry Modal
  void _showHydrationModal(BuildContext context) {
    ManualEntryModal.show(
      context: context,
      title: 'Log Hydration',
      icon: Icons.water_drop_outlined,
      iconColor: const Color(0xFF00B8A9),
      value: controller.hydrationInput.value,
      onChanged: (value) => controller.hydrationInput.value = value,
      onSubmit: () => controller.handleHydrationSubmit(),
      onClose: () => controller.hydrationInput.value = '',
      placeholder: 'Enter water intake in liters',
      unit: 'L',
      gradient: const [Color(0xFF00B8A9), Color(0xFF00E5D3)],
      description: 'Stay hydrated! Track your daily water consumption.',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
    );
  }

  /// Show Steps Entry Modal
  void _showStepsModal(BuildContext context) {
    ManualEntryModal.show(
      context: context,
      title: 'Log Steps',
      icon: Icons.directions_walk_outlined,
      iconColor: const Color(0xFF00B8A9),
      value: controller.stepsInput.value,
      onChanged: (value) => controller.stepsInput.value = value,
      onSubmit: () => controller.handleStepsSubmit(),
      onClose: () => controller.stepsInput.value = '',
      placeholder: 'Enter steps count',
      unit: 'steps',
      gradient: const [Color(0xFF00B8A9), Color(0xFF00D4C3)],
      description: 'Track your daily steps to stay active and healthy.',
      keyboardType: TextInputType.number,
    );
  }

  /// Show Fasting Mode Modal
  void _showFastingModal(BuildContext context) {
    ManualEntryModal.show(
      context: context,
      title: 'Log Meals',
      icon: Icons.restaurant_outlined,
      iconColor: const Color(0xFFD4AF37),
      value: controller.fastingInput.value,
      onChanged: (value) => controller.fastingInput.value = value,
      onSubmit: () => controller.handleFastingSubmit(),
      onClose: () => controller.fastingInput.value = '',
      placeholder: 'Enter number of meals (0-2)',
      unit: 'meals',
      gradient: const [Color(0xFFD4AF37), Color(0xFFB8941F)],
      description: 'Track your daily meals. Enter 0-2 meals eaten today.',
      keyboardType: TextInputType.number,
    );
  }
}

/// ManualEntryModal - A dialog for manual data entry
/// Matches the React ManualEntryModal component design
class ManualEntryModal extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;
  final VoidCallback onClose;
  final String placeholder;
  final String unit;
  final List<Color> gradient;
  final String description;
  final TextInputType keyboardType;

  const ManualEntryModal({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.onChanged,
    required this.onSubmit,
    required this.onClose,
    required this.placeholder,
    required this.unit,
    required this.gradient,
    this.description = 'This will be recorded in your health metrics.',
    this.keyboardType = TextInputType.number,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20.r,
              offset: Offset(0, 10.h),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(20.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row with close button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: ResponsiveTextStyles.textLg.copyWith(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0A2342),
                        ),
                      ),
                      GestureDetector(
                        onTap: onClose,
                        child: Container(
                          padding: EdgeInsets.all(8.r),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A2342).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Icon(
                            Icons.close,
                            size: 18.sp,
                            color: const Color(0xFF0A2342),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  // Icon and unit info
                  Row(
                    children: [
                      Icon(
                        icon,
                        size: 24.sp,
                        color: iconColor,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Enter your $unit',
                        style: ResponsiveTextStyles.textSm.copyWith(
                          color: const Color(0xFF0A2342).withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    description,
                    style: ResponsiveTextStyles.textXs.copyWith(
                      color: const Color(0xFF0A2342).withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            // Input field
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: TextField(
                keyboardType: keyboardType,
                onChanged: onChanged,
                decoration: InputDecoration(
                  hintText: placeholder,
                  hintStyle: ResponsiveTextStyles.textSm.copyWith(
                    color: const Color(0xFF0A2342).withOpacity(0.4),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF5F6FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 14.h,
                  ),
                  suffixText: unit,
                  suffixStyle: ResponsiveTextStyles.textSm.copyWith(
                    color: const Color(0xFF0A2342).withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: ResponsiveTextStyles.textBase.copyWith(
                  color: const Color(0xFF0A2342),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            // Submit button
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onClose,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: ResponsiveTextStyles.textSm.copyWith(
                        color: const Color(0xFF0A2342).withOpacity(0.6),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  GestureDetector(
                    onTap: onSubmit,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 12.h,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: gradient),
                        borderRadius: BorderRadius.circular(10.r),
                        boxShadow: [
                          BoxShadow(
                            color: gradient.first.withOpacity(0.3),
                            blurRadius: 8.r,
                            offset: Offset(0, 4.h),
                          ),
                        ],
                      ),
                      child: Text(
                        'Submit',
                        style: ResponsiveTextStyles.textSm.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show the modal dialog
  static void show({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color iconColor,
    required String value,
    required ValueChanged<String> onChanged,
    required VoidCallback onSubmit,
    required VoidCallback onClose,
    required String placeholder,
    required String unit,
    required List<Color> gradient,
    String description = 'This will be recorded in your health metrics.',
    TextInputType keyboardType = TextInputType.number,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => ManualEntryModal(
        title: title,
        icon: icon,
        iconColor: iconColor,
        value: value,
        onChanged: onChanged,
        onSubmit: () {
          onSubmit();
          Navigator.of(context).pop();
        },
        onClose: () {
          onClose();
          Navigator.of(context).pop();
        },
        placeholder: placeholder,
        unit: unit,
        gradient: gradient,
        description: description,
        keyboardType: keyboardType,
      ),
    );
  }
}

// Helper widget for Quick Actions
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(20.r),
        ),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20.sp),
            SizedBox(width: 8.w),
            Flexible(
              child: Text(
                title,
                style: ResponsiveTextStyles.textSm.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

