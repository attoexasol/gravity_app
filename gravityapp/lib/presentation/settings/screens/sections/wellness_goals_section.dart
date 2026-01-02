import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'section_title_widget.dart';
import '../../../../app/theme/app_text_styles.dart';

class WellnessGoalsSection extends StatelessWidget {
  final dynamic controller;

  const WellnessGoalsSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitleWidget(title: 'Wellness Goals', isDanger: false),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: controller.isLoadingGoals.value
                ? _buildLoadingState()
                : controller.showGoalsEditor.value
                ? _buildGoalsEditor(controller)
                : _buildGoalsDisplay(controller),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: EdgeInsets.all(40.w),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                const Color(0xFF00B8A9),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Loading goals...',
              style: ResponsiveTextStyles.textSm.copyWith(
                color: const Color(0xFF0A2342).withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsEditor(dynamic controller) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            children: [
              _buildGoalInput(
                label: 'Current Weight (kg)',
                value: controller.goals['currentWeight'] ?? '',
                onChanged: (value) => controller.goals['currentWeight'] = value,
              ),
              SizedBox(height: 16.h),
              _buildGoalInput(
                label: 'Target Weight (kg)',
                value: controller.goals['targetWeight'] ?? '',
                onChanged: (value) => controller.goals['targetWeight'] = value,
              ),
              SizedBox(height: 16.h),
              _buildGoalInput(
                label: 'Step Goal',
                value: controller.goals['stepGoal'] ?? '',
                onChanged: (value) => controller.goals['stepGoal'] = value,
              ),
              SizedBox(height: 16.h),
              _buildGoalInput(
                label: 'Daily Water Intake (L)',
                value: controller.goals['waterIntake'] ?? '',
                onChanged: (value) => controller.goals['waterIntake'] = value,
              ),
              SizedBox(height: 16.h),
              _buildGoalInput(
                label: 'Sleep Hours',
                value: controller.goals['sleepHours'] ?? '',
                onChanged: (value) => controller.goals['sleepHours'] = value,
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: const Color(0xFF0A2342).withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => controller.showGoalsEditor.value = false,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: ResponsiveTextStyles.textBase.copyWith(
                      color: const Color(0xFF0A2342),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: controller.saveGoals,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00B8A9),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 20.sp),
                      SizedBox(width: 8.w),
                      Text(
                        'Save',
                        style: ResponsiveTextStyles.textBase.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGoalInput({
    required String label,
    required String value,
    required Function(String) onChanged,
    Key? key,
  }) {
    return _GoalInputField(
      key: key,
      label: label,
      initialValue: value,
      onChanged: onChanged,
    );
  }

  Widget _buildGoalsDisplay(dynamic controller) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            children: [
              _buildGoalItem(
                icon: Icons.trending_down,
                label: 'Weight',
                value:
                    '${controller.goals['currentWeight']} kg → ${controller.goals['targetWeight']} kg',
              ),
              SizedBox(height: 16.h),
              _buildGoalItem(
                icon: Icons.directions_walk,
                label: 'Daily Steps',
                value:
                    '${NumberFormat('#,###').format(int.tryParse(controller.goals['stepGoal'] ?? '0') ?? 0)} steps',
              ),
              SizedBox(height: 16.h),
              _buildGoalItem(
                icon: Icons.water_drop,
                label: 'Water Intake',
                value: '${controller.goals['waterIntake']} liters',
              ),
              SizedBox(height: 16.h),
              _buildGoalItem(
                icon: Icons.bedtime,
                label: 'Sleep',
                value: '${controller.goals['sleepHours']} hours',
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: const Color(0xFF0A2342).withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: _EditGoalsButton(
            onPressed: () => controller.showGoalsEditor.value = true,
          ),
        ),
      ],
    );
  }

  Widget _buildGoalItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF00B8A9), size: 20.sp),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: ResponsiveTextStyles.textSm.copyWith(
                  color: const Color(0xFF0A2342),
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: ResponsiveTextStyles.textBase.copyWith(
                  color: const Color(0xFF0A2342).withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Edit Goals Button with gradient and tap animation (matching React design)
class _EditGoalsButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _EditGoalsButton({required this.onPressed});

  @override
  State<_EditGoalsButton> createState() => _EditGoalsButtonState();
}

class _EditGoalsButtonState extends State<_EditGoalsButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onPressed();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF00B8A9), Color(0xFF0A2342)],
            ),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.track_changes, color: Colors.white, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                'Edit Goals',
                style: ResponsiveTextStyles.textBase.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Stateful widget for goal input field to properly manage TextEditingController
class _GoalInputField extends StatefulWidget {
  final String label;
  final String initialValue;
  final Function(String) onChanged;

  const _GoalInputField({
    super.key,
    required this.label,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<_GoalInputField> createState() => _GoalInputFieldState();
}

class _GoalInputFieldState extends State<_GoalInputField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(_GoalInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: ResponsiveTextStyles.textSm.copyWith(
            color: const Color(0xFF0A2342).withOpacity(0.7),
          ),
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: _controller,
          onChanged: widget.onChanged,
          keyboardType: TextInputType.number,
          style: ResponsiveTextStyles.textSm.copyWith(
            color: const Color(0xFF0A2342), // Dark text color
          ),
          cursorColor: const Color(0xFF0A2342), // Dark cursor
          decoration: InputDecoration(
            hintText: 'Enter value',
            hintStyle: ResponsiveTextStyles.textSm.copyWith(
              color: const Color(0xFF0A2342).withOpacity(0.4),
            ),
            filled: true,
            fillColor: Colors.white, // Ensure white background
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 12.h,
            ),
          ),
        ),
      ],
    );
  }
}
