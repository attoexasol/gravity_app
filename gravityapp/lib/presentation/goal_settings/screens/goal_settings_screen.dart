import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gravityapp/presentation/goal_settings/screens/sections/goal_settings_header.dart';
import '../../../app/theme/app_text_styles.dart';
import '../controllers/goal_settings_controller.dart';

class GoalSettingsScreen extends GetView<GoalSettingsController> {
  const GoalSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF5F6FA), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // UPDATED HEADER — IDENTICAL TO LOGIN SCREEN
              buildHeader(),

              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 24 : 32,
                    vertical: 32,
                  ),
                  child: Column(
                    children: [
                      _buildWeightGoalsCard(),
                      const SizedBox(height: 24),

                      _buildDailyActivityCard(),
                      const SizedBox(height: 24),

                      _buildHydrationSleepCard(),
                      const SizedBox(height: 24),

                      _buildAiInteractionCard(),
                      const SizedBox(height: 24),

                      _buildInfoNote(),
                      const SizedBox(height: 32),
                      _buildContinueButton(isSmallScreen),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ❤️ PERFECT MATCH TO LOGIN SCREEN HEADER

  Widget _buildWeightGoalsCard() {
    return _buildGoalCard(
      icon: Icons.trending_down,
      title: 'Weight Goals',
      subtitle: 'Track your progress',
      gradientColors: const [Color(0xFF00B8A9), Color(0xFF0A2342)],
      children: [
        const SizedBox(height: 8),

        _buildTextField(
          label: 'Current Weight (kg)',
          controller: controller.currentWeightController,
          hint: 'e.g., 75',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),

        _buildTextField(
          label: 'Target Weight (kg)',
          controller: controller.targetWeightController,
          hint: 'e.g., 70',
          keyboardType: TextInputType.number,
        ),

        // FIXED OBX — NO GETX WARNINGS
        Obx(() {
          final diff = controller.weightDiff.value;
          if (diff.isEmpty) return const SizedBox.shrink();

          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF00B8A9).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                diff,
                style: AppTextStyles.textSm.copyWith(
                  color: const Color(0xFF00B8A9),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDailyActivityCard() {
    return _buildGoalCard(
      icon: Icons.directions_walk,
      title: 'Daily Activity',
      subtitle: 'Stay active every day',
      gradientColors: const [Color(0xFF00B8A9), Color(0xFF0A2342)],
      children: [
        const SizedBox(height: 8),
        _buildTextField(
          label: 'Step Goal',
          controller: controller.stepGoalController,
          hint: 'e.g., 12000',
          keyboardType: TextInputType.number,
          helperText: 'Recommended: 10,000 - 15,000 steps',
        ),
      ],
    );
  }

  Widget _buildHydrationSleepCard() {
    return _buildGoalCard(
      icon: Icons.water_drop_outlined,
      title: 'Hydration & Rest',
      subtitle: 'Essential for wellness',
      gradientColors: const [Color(0xFF00B8A9), Color(0xFF0A2342)],
      children: [
        const SizedBox(height: 8),

        _buildTextField(
          label: 'Daily Water Intake (L)',
          controller: controller.waterIntakeController,
          hint: 'e.g., 3',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          helperText: 'Recommended: 2.5 - 4 liters',
        ),
        const SizedBox(height: 16),

        _buildTextField(
          label: 'Sleep Hours',
          controller: controller.sleepHoursController,
          hint: 'e.g., 7-8',
          keyboardType: TextInputType.text,
          helperText: 'Recommended: 7-9 hours',
        ),
      ],
    );
  }

  Widget _buildAiInteractionCard() {
    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 600;
        final cardPadding = isSmallScreen ? 48.0 : 64.0; // 24*2 or 32*2
        final cardInnerPadding = 48.0; // 24*2 for card padding
        final spacing = 10.0;
        final buttonWidth =
            (screenWidth - cardPadding - cardInnerPadding - spacing) / 2;

        return _buildGoalCard(
          icon: Icons.smart_toy_outlined,
          title: 'AI Interaction Style',
          subtitle: 'How AI will interact with you',
          gradientColors: const [Color(0xFF00B8A9), Color(0xFF0A2342)],
          children: [
            const SizedBox(height: 16),
            Obx(
              () => Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: GoalSettingsController.aiTones.map((tone) {
                  final isSelected = controller.selectedAiTone.value == tone;
                  return GestureDetector(
                    onTap: () => controller.selectAiTone(tone),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: buttonWidth,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF00B8A9)
                            : const Color(0xFFF5F6FA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF00B8A9)
                              : const Color(0xFF0A2342).withOpacity(0.1),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        tone,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.textXs.copyWith(
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF0A2342).withOpacity(0.7),
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            // Show example conversation for selected tone
            Obx(() {
              final selectedTone = controller.selectedAiTone.value;
              if (selectedTone.isEmpty) return const SizedBox.shrink();
              
              final example = controller.getExampleForTone();
              if (example.isEmpty) return const SizedBox.shrink();
              
              return Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00B8A9).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF00B8A9).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 20,
                        color: const Color(0xFF00B8A9),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Example:',
                              style: AppTextStyles.textXs.copyWith(
                                color: const Color(0xFF0A2342).withOpacity(0.6),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              example,
                              style: AppTextStyles.textSm.copyWith(
                                color: const Color(0xFF0A2342),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildGoalCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors
                        .map((c) => c.withOpacity(0.1))
                        .toList(),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: gradientColors[0], size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.textLg.copyWith(
                        color: const Color(0xFF0A2342),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTextStyles.textSm.copyWith(
                        color: const Color(0xFF0A2342).withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required TextInputType keyboardType,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.textSm.copyWith(
            color: const Color(0xFF0A2342).withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),

        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: AppTextStyles.textBase.copyWith(
            color: const Color(0xFF0A2342), // Dark text color
          ),
          cursorColor: const Color(0xFF0A2342), // Dark cursor
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.textBase.copyWith(
              color: const Color(0xFF0A2342).withOpacity(0.4),
            ),
            filled: true,
            fillColor: Colors.white, // Ensure white background
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF00B8A9), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),

        if (helperText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              helperText,
              style: AppTextStyles.textXs.copyWith(
                color: const Color(0xFF0A2342).withOpacity(0.4),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFD4AF37).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFD4AF37), size: 20),
          const SizedBox(width: 12),

          Expanded(
            child: Text(
              'You can change these goals later from Settings.',
              style: AppTextStyles.textSm.copyWith(
                color: const Color(0xFF0A2342).withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// FINAL FIXED CONTINUE BUTTON
  Widget _buildContinueButton(bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 24 : 32,
        vertical: 32,
      ),
      child: Obx(() {
        final valid = controller.isFormValid.value && controller.selectedAiTone.value.isNotEmpty;
        final isLoading = controller.isLoading.value;

        return SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: (valid && !isLoading) ? controller.saveGoalsAndContinue : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              disabledBackgroundColor: const Color(0xFF0A2342).withOpacity(0.2),
              shadowColor: Colors.transparent,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Ink(
              decoration: BoxDecoration(
                gradient: valid
                    ? const LinearGradient(
                        colors: [Color(0xFF00B8A9), Color(0xFF0A2342)],
                      )
                    : null,
                color: valid ? null : const Color(0xFF0A2342).withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            valid ? Colors.white : const Color(0xFF0A2342).withOpacity(0.4),
                          ),
                        ),
                      )
                    : Text(
                        'Continue',
                        style: AppTextStyles.textBase.copyWith(
                          color: valid
                              ? Colors.white
                              : const Color(0xFF0A2342).withOpacity(0.4),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
