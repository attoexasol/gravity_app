import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_text_styles.dart';
import '../controllers/login_controller.dart';

class LoginScreen extends GetView<LoginController> {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure controller is available - GetView automatically handles this
    ///Get.put(LoginController());
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Stack(
        children: [
          // BACKGROUND WELCOME CARD
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome Back',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 28 : 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to continue your wellness journey',
                    style: AppTextStyles.textBase.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // FOREGROUND LOGIN CARD (SCROLLABLE & INDEPENDENT)
          Positioned.fill(
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: size.height * 0.18),
                    // LOGIN CARD
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildRoleSelection(),
                            const SizedBox(height: 24),
                            _buildEmailField(),
                            const SizedBox(height: 16),
                            _buildPasswordField(),
                            const SizedBox(height: 24),
                            _buildLoginButton(),
                            const SizedBox(height: 24),
                            _buildDivider(),
                            const SizedBox(height: 24),
                            _buildSocialButtons(isSmallScreen),
                            const SizedBox(height: 24),
                            _buildPrivacyText(),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // SIGN UP LINK
                    GestureDetector(
                      onTap: controller.navigateToSignUp,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 32),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: AppTextStyles.textBase.copyWith(
                                color: const Color(0xFF0A2342).withOpacity(0.6),
                              ),
                            ),
                            Text(
                              'Sign Up',
                              style: AppTextStyles.textBase.copyWith(
                                color: const Color(0xFF00B8A9),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSelection() {
    final controller = this.controller;
    return Obx(
      () => Row(
        children: [
          Expanded(
            child: _buildRoleCard(
              label: 'Customer',
              description: 'Track my wellness',
              icon: Icons.person,
              isSelected: controller.selectedRole.value == UserType.customer,
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
              isSelected: controller.selectedRole.value == UserType.coach,
              accentColor: const Color(0xFFD4AF37),
              onTap: () => controller.selectRole(UserType.coach),
            ),
          ),
        ],
      ),
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

  Widget _buildEmailField() {
    // Use controller from GetView
    final controller = this.controller;

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
          decoration: InputDecoration(
            hintText: 'your.email@example.com',
            hintStyle: AppTextStyles.textBase.copyWith(
              color: const Color(0xFF0A2342).withOpacity(0.3),
            ),
            prefixIcon: const Icon(
              Icons.mail_outline,
              color: Color(0xFF00B8A9),
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
      ],
    );
  }

  Widget _buildPasswordField() {
    // Use controller from GetView
    final controller = this.controller;

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
        Obx(
          () => TextField(
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
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFF00B8A9),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    final controller = this.controller;
    return Obx(
      () => SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: controller.isLoading.value ? null : controller.handleLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00B8A9),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: controller.isLoading.value
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'Sign In',
                  style: AppTextStyles.textBase.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

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
    final controller = this.controller;
    return Obx(
      () => Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSocialButton(
                  label: 'Google',
                  onTap: controller.isLoading.value
                      ? null
                      : controller.handleGoogleLogin,
                  child: _GoogleLogo(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSocialButton(
                  label: 'Apple',
                  onTap: controller.isLoading.value
                      ? null
                      : controller.handleAppleLogin,
                  child: _AppleLogo(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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

  Widget _buildPrivacyText() {
    return Text(
      'By continuing, you accept our Privacy Policy',
      textAlign: TextAlign.center,
      style: AppTextStyles.textSm.copyWith(
        color: const Color(0xFF0A2342).withOpacity(0.5),
      ),
    );
  }
}

// Google Logo SVG Component
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
    // Google logo colors and simple representation
    final paint = Paint()..style = PaintingStyle.fill;

    // Simplified Google "G" logo using circle
    paint.color = const Color(0xFF4285F4);
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2,
      paint,
    );

    // White center
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

// Apple Logo
class _AppleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.apple, color: Color(0xFF0A2342), size: 20);
  }
}
