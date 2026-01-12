import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_text_styles.dart';
import '../controllers/consent_controller.dart';

class ConsentScreen extends GetView<ConsentController> {
  const ConsentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final isMediumScreen = size.width >= 600 && size.width < 900;
    final isLargeScreen = size.width >= 900;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFFF5F6FA), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Main content
              SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isLargeScreen ? 64 : (isMediumScreen ? 48 : 24),
                    vertical: isLargeScreen ? 64 : (isMediumScreen ? 56 : 48),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Icon
                      _buildHeaderIcon(
                        isSmallScreen,
                        isMediumScreen,
                        isLargeScreen,
                      ),

                      SizedBox(height: isSmallScreen ? 24 : 32),

                      // Title
                      Text(
                        'Privacy & Data Control',
                        style: TextStyle(
                          color: const Color(0xFF0A2342),
                          fontSize: isLargeScreen
                              ? 36
                              : (isMediumScreen ? 32 : 28),
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Subtitle
                      Text(
                        'Your privacy matters. Manage your data preferences and opt out anytime.',
                        style: AppTextStyles.textBase.copyWith(
                          color: const Color(0xFF0A2342).withOpacity(0.6),
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 24 : 32),

                      // Privacy Notice
                      _buildPrivacyNotice(),

                      const SizedBox(height: 24),

                      // AI Features Section
                      _buildSectionTitle('AI Features (Opt-Out Anytime)'),
                      const SizedBox(height: 12),
                      _buildAiFeaturesCard(),

                      const SizedBox(height: 24),

                      // Data Preferences Section
                      _buildSectionTitle('Data Preferences'),
                      const SizedBox(height: 12),
                      _buildDataPreferencesCard(),

                      const SizedBox(height: 24),

                      // Data Deletion Section
                      _buildDataDeletionCard(),

                      const SizedBox(height: 24),

                      // Info Box
                      _buildInfoBox(),

                      const SizedBox(height: 24),

                      // Continue Button
                      _buildContinueButton(),

                      const SizedBox(height: 16),

                      // Privacy acknowledgment
                      Text(
                        'By continuing, you acknowledge our privacy practices',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.textSm.copyWith(
                          color: const Color(0xFF0A2342).withOpacity(0.5),
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // Delete Confirmation Modal
              Obx(
                () => controller.showDeleteConfirm.value
                    ? _buildDeleteConfirmationModal()
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderIcon(
    bool isSmallScreen,
    bool isMediumScreen,
    bool isLargeScreen,
  ) {
    final size = isLargeScreen ? 96.0 : (isMediumScreen ? 80.0 : 64.0);

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, double value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF00B8A9), Color(0xFF0A2342)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00B8A9).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(Icons.shield, color: Colors.white, size: size * 0.5),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: AppTextStyles.textLg.copyWith(
          color: const Color(0xFF0A2342),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPrivacyNotice() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 800),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border.all(color: Colors.blue.shade200, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.description_outlined,
            color: Colors.blue.shade600,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Privacy Notice',
                  style: AppTextStyles.textBase.copyWith(
                    color: const Color(0xFF0A2342),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Gravity collects and processes health data to provide personalized wellness insights. Your data is encrypted, stored securely, and never sold to third parties. You have full control over your information and can opt out of AI features or delete your data at any time.',
                  style: AppTextStyles.textSm.copyWith(
                    color: const Color(0xFF0A2342).withOpacity(0.7),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    // TODO: Navigate to full privacy policy
                    Get.snackbar(
                      'Privacy Policy',
                      'Opening full privacy policy...',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                  child: Row(
                    children: [
                      Text(
                        'Read Full Privacy Policy',
                        style: AppTextStyles.textSm.copyWith(
                          color: const Color(0xFF00B8A9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right,
                        color: Color(0xFF00B8A9),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiFeaturesCard() {
    return ConsentCard(
      icon: Icons.camera_alt_outlined,
      title: 'AI Features',
      description:
          'Analyze meal photos and get nutrition insights using AI. Receive personalized health suggestions based on your data',
      checked: controller.aiFeatures,
      onToggle: controller.toggleAiFeatures,
      gradientColors: const [Color(0xFFA78BFA), Color(0xFF7C3AED)],
      optOut: true,
    );
  }

  Widget _buildDataPreferencesCard() {
    return ConsentCard(
      icon: Icons.shield_outlined,
      title: 'Data Preferences',
      description:
          'Receive wellness notifications and reminders. Sync with Apple Health or Google Fit. Share anonymous usage data to help improve Gravity',
      checked: controller.dataPreferences,
      onToggle: controller.toggleDataPreferences,
      gradientColors: const [Color(0xFF5EEAD4), Color(0xFF14B8A6)],
    );
  }

  Widget _buildDataDeletionCard() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 800),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.delete_outline, color: Colors.red.shade600, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delete My Data',
                  style: AppTextStyles.textBase.copyWith(
                    color: const Color(0xFF0A2342),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You have the right to request permanent deletion of all your personal data. This action is irreversible and will remove all your health records, meal logs, and account information from our servers.',
                  style: AppTextStyles.textSm.copyWith(
                    color: const Color(0xFF0A2342).withOpacity(0.7),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: controller.showDeleteConfirmation,
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Request Data Deletion'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 800),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFD4AF37).withOpacity(0.1),
        border: Border.all(
          color: const Color(0xFFD4AF37).withOpacity(0.3),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '💡 You can change these preferences anytime in Settings. Your choices are saved automatically.',
        style: AppTextStyles.textSm.copyWith(
          color: const Color(0xFF0A2342).withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return Obx(
      () => Container(
        constraints: const BoxConstraints(maxWidth: 448),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: controller.isLoading.value
                ? null
                : controller.continueToApp,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              shadowColor: Colors.transparent,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: controller.isLoading.value
                      ? [
                          const Color(0xFF00B8A9).withOpacity(0.6),
                          const Color(0xFF0A2342).withOpacity(0.6),
                        ]
                      : const [Color(0xFF00B8A9), Color(0xFF0A2342)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                alignment: Alignment.center,
                child: controller.isLoading.value
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        'Done',
                        style: AppTextStyles.textBase.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteConfirmationModal() {
    return GestureDetector(
      onTap: controller.hideDeleteConfirmation,
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent dismiss when tapping modal
            child: Container(
              margin: const EdgeInsets.all(24),
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      color: Colors.red.shade600,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    'Delete All Data?',
                    style: AppTextStyles.textXl.copyWith(
                      color: const Color(0xFF0A2342),
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Description
                  Text(
                    'This will permanently delete all your health data, meal logs, and account information. This action cannot be undone. Are you sure?',
                    style: AppTextStyles.textSm.copyWith(
                      color: const Color(0xFF0A2342).withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: controller.hideDeleteConfirmation,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0A2342),
                            side: BorderSide(
                              color: const Color(0xFF0A2342).withOpacity(0.2),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: controller.confirmDataDeletion,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Delete Forever'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Reusable Consent Card Widget
class ConsentCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final RxBool checked;
  final VoidCallback onToggle;
  final List<Color> gradientColors;
  final bool optOut;

  const ConsentCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.checked,
    required this.onToggle,
    required this.gradientColors,
    this.optOut = false,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => GestureDetector(
        onTap: onToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(maxWidth: 800),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: checked.value
                  ? const Color(0xFF00B8A9)
                  : const Color(0xFF0A2342).withOpacity(0.1),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.textBase.copyWith(
                            color: const Color(0xFF0A2342),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (optOut) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Opt-out',
                              style: AppTextStyles.textXs.copyWith(
                                color: Colors.amber.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: AppTextStyles.textSm.copyWith(
                        color: const Color(0xFF0A2342).withOpacity(0.6),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              // Toggle Switch
              const SizedBox(width: 12),
              _buildSwitch(checked.value),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitch(bool value) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value ? 1 : 0),
      duration: const Duration(milliseconds: 200),
      builder: (context, animValue, child) {
        return Container(
          width: 48,
          height: 24,
          decoration: BoxDecoration(
            color: Color.lerp(
              Colors.grey.shade300,
              const Color(0xFF00B8A9),
              animValue,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                left: value ? 26 : 2,
                top: 2,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
