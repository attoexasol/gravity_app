import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../controllers/today_controller.dart';
import '../../../../app/theme/app_text_styles.dart';

/// Reusable Weight Goals modal opened from the Weight Journey card edit (pencil) icon.
/// Allows updating starting weight and target weight with validation and dynamic goal summary.
class WeightGoalsModal extends StatefulWidget {
  final TodayController controller;

  const WeightGoalsModal({
    super.key,
    required this.controller,
  });

  @override
  State<WeightGoalsModal> createState() => _WeightGoalsModalState();
}

class _WeightGoalsModalState extends State<WeightGoalsModal> {
  late final TextEditingController _startingController;
  late final TextEditingController _targetController;

  /// Inline validation error message (target must be < starting, both > 0).
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startingController = TextEditingController(
      text: widget.controller.startingWeight.value.toStringAsFixed(1),
    );
    _targetController = TextEditingController(
      text: widget.controller.goalWeight.value.toStringAsFixed(1),
    );
    _startingController.addListener(_onFieldsChanged);
    _targetController.addListener(_onFieldsChanged);
  }

  void _onFieldsChanged() {
    setState(() {
      _errorMessage = null;
    });
  }

  @override
  void dispose() {
    _startingController.removeListener(_onFieldsChanged);
    _targetController.removeListener(_onFieldsChanged);
    _startingController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  /// Parse and validate; returns null if invalid and sets _errorMessage.
  bool _validate() {
    final starting = double.tryParse(_startingController.text);
    final target = double.tryParse(_targetController.text);

    if (starting == null || starting <= 0) {
      setState(() {
        _errorMessage = 'Please enter a valid starting weight greater than 0.';
      });
      return false;
    }
    if (target == null || target <= 0) {
      setState(() {
        _errorMessage = 'Please enter a valid target weight greater than 0.';
      });
      return false;
    }
    if (target >= starting) {
      setState(() {
        _errorMessage = 'Target weight must be less than starting weight.';
      });
      return false;
    }
    setState(() => _errorMessage = null);
    return true;
  }

  void _save() {
    if (!_validate()) return;
    final starting = double.parse(_startingController.text);
    final target = double.parse(_targetController.text);
    widget.controller.saveWeightGoals(startingKg: starting, targetKg: target);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!widget.controller.showGoalsModal.value) {
        return const SizedBox.shrink();
      }

      return GestureDetector(
        onTap: widget.controller.closeGoalsModal,
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: BoxConstraints(maxWidth: 400.w),
                margin: EdgeInsets.symmetric(horizontal: 16.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20.r,
                      offset: Offset(0, 8.r),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(20.r),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header: title, subtitle, close (X)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Weight Goals',
                                    style: ResponsiveTextStyles.h3.copyWith(
                                      color: const Color(0xFF0A2342),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    'You can update these anytime. Your goal weight — take your time.',
                                    style: ResponsiveTextStyles.textSm.copyWith(
                                      color: const Color(0xFF0A2342).withOpacity(0.6),
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: widget.controller.closeGoalsModal,
                              child: Padding(
                                padding: EdgeInsets.all(4.r),
                                child: Icon(
                                  Icons.close,
                                  color: const Color(0xFF0A2342),
                                  size: 24.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 24.h),

                        // Starting Weight (kg)
                        _buildLabel('Starting Weight (kg)'),
                        SizedBox(height: 8.h),
                        _buildNumberField(
                          controller: _startingController,
                          hint: '85',
                        ),
                        SizedBox(height: 16.h),

                        // Target Weight (kg) with target icon
                        _buildLabel('Target Weight (kg)'),
                        SizedBox(height: 8.h),
                        _buildTargetField(controller: _targetController, hint: '71.5'),
                        SizedBox(height: 16.h),

                        // Goal summary box (soft gold/cream gradient, dynamic)
                        _buildGoalSummary(),
                        if (_errorMessage != null) ...[
                          SizedBox(height: 12.h),
                          Text(
                            _errorMessage!,
                            style: ResponsiveTextStyles.textSm.copyWith(
                              color: const Color(0xFFE53935),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        SizedBox(height: 24.h),

                        // Buttons: Cancel, Save Goals
                        Row(
                          children: [
                            Expanded(
                              child: _buildCancelButton(),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: _buildSaveButton(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: ResponsiveTextStyles.textSm.copyWith(
        color: const Color(0xFF0A2342).withOpacity(0.7),
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
      ],
      style: ResponsiveTextStyles.textLg.copyWith(
        color: const Color(0xFF0A2342),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF5F6FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFF00B8A9), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFFE53935)),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      ),
    );
  }

  Widget _buildTargetField({
    required TextEditingController controller,
    required String hint,
  }) {
    return Stack(
      alignment: Alignment.centerRight,
      children: [
        _buildNumberField(controller: controller, hint: hint),
        Padding(
          padding: EdgeInsets.only(right: 12.w),
          child: Icon(
            Icons.gps_fixed,
            color: Colors.orange.shade700,
            size: 22.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildGoalSummary() {
    final starting = double.tryParse(_startingController.text);
    final target = double.tryParse(_targetController.text);
    final totalLoss = (starting != null && target != null && starting > target)
        ? starting - target
        : 0.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFF8E7),
            const Color(0xFFFFF4D6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: RichText(
        text: TextSpan(
          style: ResponsiveTextStyles.textBase.copyWith(
            color: const Color(0xFF0A2342),
          ),
          children: [
            const TextSpan(text: 'Total goal: '),
            TextSpan(
              text: '${totalLoss.toStringAsFixed(1)} kg loss',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return GestureDetector(
      onTap: widget.controller.closeGoalsModal,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(12.r),
        ),
        alignment: Alignment.center,
        child: Text(
          'Cancel',
          style: ResponsiveTextStyles.textBase.copyWith(
            color: const Color(0xFF0A2342),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _save,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE0A82E), Color(0xFF0A2342)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12.r),
        ),
        alignment: Alignment.center,
        child: Text(
          'Save Goals',
          style: ResponsiveTextStyles.textBase.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
