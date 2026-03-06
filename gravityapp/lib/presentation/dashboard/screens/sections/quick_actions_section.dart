import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../app/theme/app_colors.dart';
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
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: AppColors.foreground.withOpacity(0.4),
      builder: (context) => FastingTrackerModal(controller: controller),
    );
  }
}

/// Fasting Tracker modal - matches new design with fasting mode selection and meal logging
class FastingTrackerModal extends StatefulWidget {
  final DashboardController controller;

  const FastingTrackerModal({super.key, required this.controller});

  @override
  State<FastingTrackerModal> createState() => _FastingTrackerModalState();
}

class _FastingTrackerModalState extends State<FastingTrackerModal> {
  Timer? _mealWindowTimer;
  /// Modal-local: true only after user taps Normal or O.M.A.D. Log Your Meals hidden until then.
  bool _hasSelectedFastingMode = false;

  @override
  void initState() {
    super.initState();
    _mealWindowTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      widget.controller.mealWindowTicker.value++;
    });
  }

  void _onFastingModeSelected(String mode) {
    setState(() => _hasSelectedFastingMode = true);
    controller.setFastingMode(mode);
    controller.resetMeals();
  }

  @override
  void dispose() {
    _mealWindowTimer?.cancel();
    super.dispose();
  }

  static const Color _kPrimaryDark = Color(0xFF0A2342);
  static const Color _kLightGray = Color(0xFFF5F6FA);

  DashboardController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height - 48.h;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 512, maxHeight: maxHeight),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: _kPrimaryDark.withOpacity(0.08), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20.r,
                offset: Offset(0, 8.h),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 20.h),
                child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: title row with close button on the right (matches Log Sleep / Add Weight)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Fasting Tracker',
                      style: ResponsiveTextStyles.textLg.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _kPrimaryDark,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: _kPrimaryDark.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(
                          Icons.close,
                          size: 18.sp,
                          color: _kPrimaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.restaurant_menu,
                      size: 24.sp,
                      color: const Color(0xFFD4AF37),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Manage your daily meal plan',
                      style: ResponsiveTextStyles.textSm.copyWith(
                        color: _kPrimaryDark.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                // Fasting Mode section
                Text(
                  'Fasting Mode:',
                  style: ResponsiveTextStyles.textSm.copyWith(
                    color: _kPrimaryDark.withOpacity(0.7),
                  ),
                ),
                SizedBox(height: 12.h),
                // Use Row directly - selection is driven by setState (_hasSelectedFastingMode) and controller
                // Obx would mix local state with observables, causing GetX "improper use" error
                Row(
                  children: [
                    Expanded(
                      child: _FastingModeButton(
                        label: 'Normal',
                        subtitle: '2 Meals/Day',
                        isSelected: _hasSelectedFastingMode && controller.fastingMode.value == 'normal',
                        onTap: () => _onFastingModeSelected('normal'),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: _FastingModeButton(
                        label: 'O.M.A.D',
                        subtitle: '1 Meal/Day',
                        isSelected: _hasSelectedFastingMode && controller.fastingMode.value == 'omad',
                        onTap: () => _onFastingModeSelected('omad'),
                      ),
                    ),
                  ],
                ),
                // Log Your Meals section: only visible AFTER fasting mode is selected
                if (_hasSelectedFastingMode) ...[
                  SizedBox(height: 24.h),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: _kPrimaryDark.withOpacity(0.1),
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    'Log Your Meals:',
                    style: ResponsiveTextStyles.textSm.copyWith(
                      color: _kPrimaryDark.withOpacity(0.7),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Obx(() {
                  controller.mealWindowTicker.value; // Trigger rebuild when time window changes
                  final mode = controller.fastingMode.value;
                  final meals = controller.mealsEaten.value;
                  final maxMeals = mode == 'omad' ? 1 : 2;
                  final canLog1 = controller.canLogMeal(1);
                  final canLog2 = controller.canLogMeal(2);
                  // Normal mode: only one meal at a time (meals==1 or meals==2)
                  // OMAD: meals>=1 means logged
                  final meal1Logged = mode == 'omad' ? meals >= 1 : meals == 1;
                  final meal2Logged = meals == 2;
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _MealLogButton(
                              label: 'Meal 1',
                              isLogged: meal1Logged,
                              allowedTime: controller.mealAllowedTime(1),
                              canLog: canLog1,
                              isLoading: controller.isMealLogging.value,
                              onTap: () {
                                final isLogging = !meal1Logged;
                                if (isLogging && !canLog1) {
                                  final time = controller.mealAllowedTime(1);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Meal 1 can only be logged between $time',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  return;
                                }
                                controller.markMealCompleted(1, isLogging);
                              },
                            ),
                          ),
                          if (maxMeals == 2) ...[
                            SizedBox(width: 12.w),
                            Expanded(
                              child: _MealLogButton(
                                label: 'Meal 2',
                                isLogged: meal2Logged,
                                allowedTime: controller.mealAllowedTime(2),
                                canLog: canLog2,
                                isLoading: controller.isMealLogging.value,
                                onTap: () {
                                  final isLogging = !meal2Logged;
                                  if (isLogging && !canLog2) {
                                    final time = controller.mealAllowedTime(2);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Meal 2 can only be logged between $time',
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                    return;
                                  }
                                  controller.markMealCompleted(2, isLogging);
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 12.h),
                      // Submit button: API work first, then close modal and return to dashboard on success
                      Obx(() {
                        final canSubmit = _hasSelectedFastingMode &&
                            controller.mealsEaten.value >= 1 &&
                            !controller.isMealLogging.value;
                        return SizedBox(
                        width: double.infinity,
                        child: GestureDetector(
                          onTap: canSubmit ? () async {
                            final success = await controller.submitFastMeal();
                            if (success && context.mounted) {
                              Navigator.of(context).pop();
                            }
                          } : null,
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                            decoration: BoxDecoration(
                              gradient: canSubmit
                                  ? const LinearGradient(
                                      colors: [Color(0xFFD4AF37), Color(0xFFB8941F)],
                                    )
                                  : null,
                              color: !canSubmit
                                  ? _kLightGray
                                  : null,
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (controller.isMealLogging.value)
                                  SizedBox(
                                    width: 18.w,
                                    height: 18.h,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0A2342)),
                                    ),
                                  ),
                                if (controller.isMealLogging.value) SizedBox(width: 8.w),
                                Text(
                                  'Submit',
                                  style: ResponsiveTextStyles.textSm.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: canSubmit
                                        ? Colors.white
                                        : _kPrimaryDark.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ); }),
                      SizedBox(height: 8.h),
                      // Reset All button
                      // SizedBox(
                      //   width: double.infinity,
                      //   child: TextButton(
                      //     onPressed: controller.isMealLogging.value ? null : () => controller.resetMeals(),
                      //     style: TextButton.styleFrom(
                      //       backgroundColor: _kLightGray,
                      //       foregroundColor: _kPrimaryDark.withOpacity(0.6),
                      //       padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                      //       shape: RoundedRectangleBorder(
                      //         borderRadius: BorderRadius.circular(12.r),
                      //       ),
                      //     ),
                      //     child: Text(
                      //       'Reset All',
                      //       style: ResponsiveTextStyles.textSm.copyWith(
                      //         fontWeight: FontWeight.w500,
                      //       ),
                      //     ),
                      //   ),
                      // ),
                    ],
                  );
                }),
                ],
              ],
            ),
              ),
          ],
        ),
        ),
      ),
    );
  }
}

class _FastingModeButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _FastingModeButton({
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  static const Color _kPrimaryDark = Color(0xFF0A2342);
  static const Color _kLightGray = Color(0xFFF5F6FA);
  static const Color _kGoldStart = Color(0xFFD4AF37);
  static const Color _kGoldEnd = Color(0xFFB8941F);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_kGoldStart, _kGoldEnd],
                )
              : null,
          color: isSelected ? null : _kLightGray,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 24.sp,
              color: isSelected ? Colors.white : _kPrimaryDark,
            ),
            SizedBox(height: 8.h),
            Text(
              label,
              style: ResponsiveTextStyles.textBase.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : _kPrimaryDark,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              subtitle,
              style: ResponsiveTextStyles.textXs.copyWith(
                color: isSelected ? Colors.white.withOpacity(0.8) : _kPrimaryDark.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealLogButton extends StatelessWidget {
  final String label;
  final bool isLogged;
  final String allowedTime;
  final bool canLog;
  final bool isLoading;
  final VoidCallback onTap;

  const _MealLogButton({
    required this.label,
    required this.isLogged,
    required this.allowedTime,
    required this.canLog,
    required this.isLoading,
    required this.onTap,
  });

  static const Color _kPrimaryDark = Color(0xFF0A2342);
  static const Color _kLightGray = Color(0xFFF5F6FA);
  // Teal gradient for logged meals (from #00B8A9 to #0A2342)
  static const Color _kTealStart = Color(0xFF00B8A9);
  static const Color _kTealEnd = Color(0xFF0A2342);

  // Fixed min height so logged/unlogged/Normal/OMAD cards are visually consistent
  static const double _kCardMinHeight = 100;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Disable tap when loading to prevent double-tap
      onTap: isLoading ? null : onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Opacity(
            opacity: isLoading ? 0.6 : 1.0,
            child: Container(
              // Fixed min height: prevents content from defining height; same for all states
              constraints: BoxConstraints(minHeight: _kCardMinHeight.h),
              padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
              decoration: BoxDecoration(
                gradient: isLogged
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_kTealStart, _kTealEnd],
                      )
                    : null,
                color: isLogged ? null : _kLightGray,
                borderRadius: BorderRadius.circular(14.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8.r,
                    offset: Offset(0, 2.h),
                  ),
                ],
              ),
              // Vertically center content; keeps spacing consistent regardless of state
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.restaurant_menu,
                    size: 20.sp,
                    color: isLogged ? Colors.white : _kPrimaryDark.withOpacity(canLog ? 0.4 : 0.25),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    label,
                    style: ResponsiveTextStyles.textSm.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isLogged ? Colors.white : _kPrimaryDark.withOpacity(canLog ? 0.4 : 0.25),
                    ),
                  ),
                  // Fixed-height slot for third line: logged and unlogged use same vertical space
                  SizedBox(height: 2.h),
                  SizedBox(
                    height: 16.h,
                    child: Center(
                      child: isLogged
                          ? Text(
                              '✓ Logged',
                              style: ResponsiveTextStyles.textXs.copyWith(
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            )
                          : Text(
                              allowedTime,
                              style: ResponsiveTextStyles.textXs.copyWith(
                                color: _kPrimaryDark.withOpacity(canLog ? 0.5 : 0.3),
                                fontWeight: FontWeight.w400,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isLoading)
            Positioned.fill(
              child: Center(
                child: SizedBox(
                  width: 24.w,
                  height: 24.h,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00B8A9)),
                  ),
                ),
              ),
            ),
        ],
      ),
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

