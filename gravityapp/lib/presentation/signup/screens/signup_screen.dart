import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_text_styles.dart';
import '../controllers/signup_controller.dart';

class SignupScreen extends GetView<SignupController> {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Stack(
        children: [
          // BACKGROUND HEADER
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: size.height * 0.30,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0A2342), Color(0xFF00B8A9)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  Row(
                    children: [
                      InkWell(
                        onTap: controller.navigateToLogin,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Create Account',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 28 : 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start your wellness journey today',
                    style: AppTextStyles.textBase.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // FOREGROUND SIGNUP CARD (SCROLLABLE)
          Positioned.fill(
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: size.height * 0.18),

                    // SIGNUP CARD
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 600),
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
                        padding: EdgeInsets.all(isSmallScreen ? 24 : 32),
                        child: Obx(
                          () => controller.isSignupSuccess.value
                              ? _buildSuccessContent(isSmallScreen)
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildRoleSelection(),
                                    const SizedBox(height: 24),
                                    _buildFullNameField(),
                                    const SizedBox(height: 16),
                                    _buildEmailField(),
                                    const SizedBox(height: 16),
                                    _buildPhoneField(),
                                    const SizedBox(height: 16),
                                    _buildPasswordField(),
                                    const SizedBox(height: 16),
                                    _buildConfirmPasswordField(),
                                    const SizedBox(height: 24),
                                    _buildSignupButton(),
                                    const SizedBox(height: 24),
                                    _buildDivider(),
                                    const SizedBox(height: 24),
                                    _buildSocialButtons(isSmallScreen),
                                    const SizedBox(height: 24),
                                    _buildTermsText(),
                                  ],
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // LOGIN LINK
                    _buildLoginLink(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- ROLE SELECTION ----------

  Widget _buildRoleSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'I am a',
          style: AppTextStyles.textBase.copyWith(
            color: const Color(0xFF0A2342).withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 12),
        Obx(() {
          final selected = controller.selectedRole.value;
          return Row(
            children: [
              Expanded(
                child: _buildRoleCard(
                  label: 'Customer',
                  description: 'Track my wellness',
                  icon: Icons.person,
                  isSelected: selected == UserType.customer,
                  accentColor: const Color(0xFF00B8A9),
                  onTap: () => controller.selectRole(UserType.customer),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildRoleCard(
                  label: 'Coach',
                  description: 'Manage clients',
                  icon: Icons.manage_accounts,
                  isSelected: selected == UserType.coach,
                  accentColor: const Color(0xFFD4AF37),
                  onTap: () => controller.selectRole(UserType.coach),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildRoleCard({
    required String label,
    required String description,
    required IconData icon,
    required bool isSelected,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? accentColor
                : const Color(0xFF0A2342).withOpacity(0.1),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isSelected
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [accentColor, accentColor.withOpacity(0.7)],
                      )
                    : null,
                color: isSelected
                    ? null
                    : const Color(0xFF0A2342).withOpacity(0.1),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? Colors.white
                    : const Color(0xFF0A2342).withOpacity(0.4),
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: AppTextStyles.textBase.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? accentColor
                    : const Color(0xFF0A2342).withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: AppTextStyles.textXs.copyWith(
                color: const Color(0xFF0A2342).withOpacity(0.4),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ---------- FIELDS ----------

  Widget _buildFullNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Full Name',
          style: AppTextStyles.textBase.copyWith(
            color: const Color(0xFF0A2342).withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller.fullNameController,
          keyboardType: TextInputType.name,
          style: AppTextStyles.textBase.copyWith(
            color: const Color(0xFF0A2342), // Dark text color
          ),
          cursorColor: const Color(0xFF0A2342), // Dark cursor
          decoration: _baseInputDecoration(
            hint: 'John Doe',
            icon: Icons.person_outline,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email',
          style: AppTextStyles.textBase.copyWith(
            color: const Color(0xFF0A2342).withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller.emailController,
          keyboardType: TextInputType.emailAddress,
          style: AppTextStyles.textBase.copyWith(
            color: const Color(0xFF0A2342), // Dark text color
          ),
          cursorColor: const Color(0xFF0A2342), // Dark cursor
          decoration: _baseInputDecoration(
            hint: 'your.email@example.com',
            icon: Icons.mail_outline,
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phone Number (Optional)',
          style: AppTextStyles.textBase.copyWith(
            color: const Color(0xFF0A2342).withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller.phoneController,
          keyboardType: TextInputType.phone,
          style: AppTextStyles.textBase.copyWith(
            color: const Color(0xFF0A2342), // Dark text color
          ),
          cursorColor: const Color(0xFF0A2342), // Dark cursor
          decoration: _baseInputDecoration(
            hint: '+1 (555) 000-0000',
            icon: Icons.phone_outlined,
          ),
        ),
      ],
    );
  }

  InputDecoration _baseInputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.textBase.copyWith(
        color: const Color(0xFF0A2342).withOpacity(0.3),
      ),
      prefixIcon: Icon(icon, color: const Color(0xFF00B8A9)),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: const Color(0xFF0A2342).withOpacity(0.1),
          width: 2,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: const Color(0xFF0A2342).withOpacity(0.1),
          width: 2,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF00B8A9), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password',
          style: AppTextStyles.textBase.copyWith(
            color: const Color(0xFF0A2342).withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 8),
        Obx(() {
          return TextField(
            controller: controller.passwordController,
            obscureText: !controller.isPasswordVisible.value,
            style: AppTextStyles.textBase.copyWith(
              color: const Color(0xFF0A2342), // Dark text color
            ),
            cursorColor: const Color(0xFF0A2342), // Dark cursor
            decoration: InputDecoration(
              hintText: '••••••••',
              hintStyle: AppTextStyles.textBase.copyWith(
                color: const Color(0xFF0A2342).withOpacity(0.3),
              ),
              prefixIcon: const Icon(
                Icons.lock_outline,
                color: Color(0xFF00B8A9),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  controller.isPasswordVisible.value
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: const Color(0xFF0A2342).withOpacity(0.4),
                ),
                onPressed: controller.togglePasswordVisibility,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: const Color(0xFF0A2342).withOpacity(0.1),
                  width: 2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: const Color(0xFF0A2342).withOpacity(0.1),
                  width: 2,
                ),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
                borderSide: BorderSide(color: Color(0xFF00B8A9), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          );
        }),
        const SizedBox(height: 4),
        Text(
          'At least 8 characters',
          style: AppTextStyles.textXs.copyWith(
            color: const Color(0xFF0A2342).withOpacity(0.4),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Confirm Password',
          style: AppTextStyles.textBase.copyWith(
            color: const Color(0xFF0A2342).withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 8),
        Obx(() {
          final hasText = controller.confirmPasswordText.value.isNotEmpty;
          final mismatch = !controller.passwordsMatch;
          final showError = hasText && mismatch;

          final Color borderColor = showError
              ? Colors.red
              : const Color(0xFF0A2342).withOpacity(0.1);
          final Color focusedColor = showError
              ? Colors.red
              : const Color(0xFF00B8A9);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller.confirmPasswordController,
                obscureText: !controller.isConfirmPasswordVisible.value,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  hintStyle: AppTextStyles.textBase.copyWith(
                    color: const Color(0xFF0A2342).withOpacity(0.3),
                  ),
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: Color(0xFF00B8A9),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.isConfirmPasswordVisible.value
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: const Color(0xFF0A2342).withOpacity(0.4),
                    ),
                    onPressed: controller.toggleConfirmPasswordVisibility,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: borderColor, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: borderColor, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: focusedColor, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
              if (showError) const SizedBox(height: 4),
              if (showError)
                Text(
                  'Passwords do not match',
                  style: AppTextStyles.textXs.copyWith(color: Colors.red),
                ),
            ],
          );
        }),
      ],
    );
  }

  // ---------- SIGNUP BUTTON ----------

  Widget _buildSignupButton() {
    return Obx(() {
      final isBusy = controller.isLoading.value;
      final isEnabled = controller.isFormValid.value && !isBusy;

      return SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: isEnabled ? controller.handleSignup : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: isEnabled
                ? const Color(0xFF00B8A9)
                : const Color(0xFF0A2342).withOpacity(0.2),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: isBusy
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'Create Account',
                  style: AppTextStyles.textBase.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isEnabled
                        ? Colors.white
                        : const Color(0xFF0A2342).withOpacity(0.4),
                  ),
                ),
        ),
      );
    });
  }

  // ---------- DIVIDER & SOCIAL ----------

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: const Color(0xFF0A2342).withOpacity(0.1),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or continue with',
            style: AppTextStyles.textSm.copyWith(
              color: const Color(0xFF0A2342).withOpacity(0.4),
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: const Color(0xFF0A2342).withOpacity(0.1),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButtons(bool isSmallScreen) {
    return Obx(() {
      final isBusy = controller.isLoading.value;
      return Row(
        children: [
          Expanded(
            child: _buildSocialButton(
              label: 'Google',
              onTap: isBusy ? null : controller.handleGoogleSignup,
              child: _GoogleLogo(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSocialButton(
              label: 'Apple',
              onTap: isBusy ? null : controller.handleAppleSignup,
              child: _AppleLogo(),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildSocialButton({
    required String label,
    required VoidCallback? onTap,
    required Widget child,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFF0A2342).withOpacity(0.1),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              child,
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.textBase.copyWith(
                  color: const Color(0xFF0A2342),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- TERMS & LOGIN LINK ----------

  Widget _buildTermsText() {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: AppTextStyles.textSm.copyWith(
          color: const Color(0xFF0A2342).withOpacity(0.5),
        ),
        children: [
          const TextSpan(text: 'By signing up, you agree to our '),
          TextSpan(
            text: 'Terms of Service',
            style: AppTextStyles.textSm.copyWith(
              color: const Color(0xFF00B8A9),
              decoration: TextDecoration.underline,
            ),
          ),
          const TextSpan(text: ' and '),
          TextSpan(
            text: 'Privacy Policy',
            style: AppTextStyles.textSm.copyWith(
              color: const Color(0xFF00B8A9),
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginLink() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Already have an account? ",
            style: AppTextStyles.textBase.copyWith(
              color: const Color(0xFF0A2342).withOpacity(0.6),
            ),
          ),
          GestureDetector(
            onTap: controller.navigateToLogin,
            child: Text(
              'Sign In',
              style: AppTextStyles.textBase.copyWith(
                color: const Color(0xFF00B8A9),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- SUCCESS CONTENT ----------

  Widget _buildSuccessContent(bool isSmallScreen) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        // Success Icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF00B8A9).withOpacity(0.1),
          ),
          child: const Icon(
            Icons.check_circle,
            color: Color(0xFF00B8A9),
            size: 50,
          ),
        ),
        const SizedBox(height: 24),
        // Success Title
        Text(
          'Account Created!',
          style: AppTextStyles.textBase.copyWith(
            fontSize: isSmallScreen ? 24 : 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0A2342),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        // Success Message
        Text(
          'Your account has been successfully created. You can now sign in to continue.',
          style: AppTextStyles.textBase.copyWith(
            color: const Color(0xFF0A2342).withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        // Back to Login Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: controller.navigateToLoginAfterSignup,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00B8A9),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Text(
              'Back to Login',
              style: AppTextStyles.textBase.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

// ---------- GOOGLE LOGO (simple custom paint) ----------

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/google_logo.svg',
      width: 20,
      height: 20,
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Outer colored circle
    paint.color = const Color(0xFF4285F4);
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2,
      paint,
    );

    // Inner white circle
    paint.color = Colors.white;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 3,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------- APPLE LOGO ----------

class _AppleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.apple, color: Color(0xFF0A2342), size: 20);
  }
}
