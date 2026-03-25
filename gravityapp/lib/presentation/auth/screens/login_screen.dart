import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_text_styles.dart';
import '../controllers/login_controller.dart';

/// Layout metrics for login — adapts to screen size and avoids keyboard overflow.
class _LoginLayout {
  _LoginLayout._(this.size, this.shortestSide);

  final Size size;
  final double shortestSide;

  factory _LoginLayout.of(BuildContext context) {
    final media = MediaQuery.of(context);
    return _LoginLayout._(media.size, media.size.shortestSide);
  }

  bool get isCompact => shortestSide < 360;
  bool get isMedium => shortestSide >= 360 && shortestSide < 420;

  double get horizontalPadding => isCompact ? 16.0 : (isMedium ? 20.0 : 24.0);

  double get cardInnerPadding => isCompact ? 20.0 : (isMedium ? 28.0 : 32.0);

  double get titleFontSize => isCompact ? 24.0 : (isMedium ? 28.0 : 32.0);

  /// Gradient header height — clamped so short phones still fit.
  double get headerHeight {
    final h = size.height;
    final fraction = h < 560 ? 0.24 : 0.26;
    return (h * fraction).clamp(180.0, 320.0);
  }

  /// Space above the white card — scales down on short screens.
  double get cardTopSpacer {
    final h = size.height;
    return (h * 0.15).clamp(88.0, 200.0);
  }

  double get roleGap => isCompact ? 10.0 : 16.0;

  double get fieldVerticalPadding => isCompact ? 12.0 : 16.0;

  double get primaryButtonHeight => isCompact ? 50.0 : 56.0;
}

class LoginScreen extends GetView<LoginController> {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final layout = _LoginLayout.of(context);
    final media = MediaQuery.of(context);
    final viewInsets = media.viewInsets;
    final statusBarHeight = media.padding.top;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF5F6FA),
      body: Stack(
        children: [
          // BACKGROUND WELCOME CARD
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: layout.headerHeight,
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
              padding: EdgeInsets.only(
                left: layout.horizontalPadding,
                right: layout.horizontalPadding,
                top: statusBarHeight + (layout.isCompact ? 20 : 30),
                bottom: layout.isCompact ? 36 : 48,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome Back',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: layout.titleFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: layout.isCompact ? 6 : 8),
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
              bottom: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    physics: const ClampingScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: viewInsets.bottom + 24,
                      ),
                      child: Column(
                        children: [
                          SizedBox(height: layout.cardTopSpacer),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: layout.horizontalPadding,
                            ),
                            child: Center(
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth: 600,
                                  minWidth: 0,
                                ),
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
                                padding: EdgeInsets.all(layout.cardInnerPadding),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildRoleSelection(layout),
                                    SizedBox(height: layout.isCompact ? 20 : 24),
                                    _buildEmailField(layout),
                                    SizedBox(height: layout.isCompact ? 12 : 16),
                                    _buildPasswordField(layout),
                                    SizedBox(height: layout.isCompact ? 10 : 12),
                                    _buildForgotPasswordLink(),
                                    SizedBox(height: layout.isCompact ? 20 : 24),
                                    _buildLoginButton(context, layout),
                                    SizedBox(height: layout.isCompact ? 20 : 24),
                                    _buildDivider(layout),
                                    SizedBox(height: layout.isCompact ? 20 : 24),
                                    _buildSocialButtons(layout),
                                    SizedBox(height: layout.isCompact ? 20 : 24),
                                    _buildPrivacyText(),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: layout.isCompact ? 24 : 32),

                          // SIGN UP LINK
                          GestureDetector(
                            onTap: controller.navigateToSignUp,
                            child: Padding(
                              padding: EdgeInsets.only(
                                bottom: 24 + media.padding.bottom,
                              ),
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    "Don't have an account? ",
                                    style: AppTextStyles.textBase.copyWith(
                                      color: const Color(0xFF0A2342)
                                          .withOpacity(0.6),
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
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSelection(_LoginLayout layout) {
    final controller = this.controller;
    return Obx(
      () => Row(
        children: [
          Expanded(
            child: _buildRoleCard(
              layout: layout,
              label: 'Customer',
              description: 'Track my wellness',
              icon: Icons.person,
              isSelected: controller.selectedRole.value == UserType.customer,
              accentColor: const Color(0xFF00B8A9),
              onTap: () => controller.selectRole(UserType.customer),
            ),
          ),
          SizedBox(width: layout.roleGap),
          Expanded(
            child: _buildRoleCard(
              layout: layout,
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
    required _LoginLayout layout,
    required String label,
    required String description,
    required IconData icon,
    required bool isSelected,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    final pad = layout.isCompact ? 12.0 : 16.0;
    final iconSize = layout.isCompact ? 22.0 : 24.0;
    final circle = layout.isCompact ? 44.0 : 48.0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(pad),
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
              width: circle,
              height: circle,
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
                size: iconSize,
              ),
            ),
            SizedBox(height: layout.isCompact ? 8 : 12),
            Text(
              label,
              style: AppTextStyles.textBase.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? accentColor
                    : const Color(0xFF0A2342).withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: layout.isCompact ? 2 : 4),
            Text(
              description,
              style: AppTextStyles.textXs.copyWith(
                color: const Color(0xFF0A2342).withOpacity(0.4),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailField(_LoginLayout layout) {
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
          textInputAction: TextInputAction.next,
          style: AppTextStyles.textBase.copyWith(
            color: const Color(0xFF0A2342),
          ),
          cursorColor: const Color(0xFF0A2342),
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
            isDense: layout.isCompact,
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
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: layout.fieldVerticalPadding,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(_LoginLayout layout) {
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
            textInputAction: TextInputAction.done,
            style: AppTextStyles.textBase.copyWith(
              color: const Color(0xFF0A2342),
            ),
            cursorColor: const Color(0xFF0A2342),
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
              isDense: layout.isCompact,
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
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: layout.fieldVerticalPadding,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForgotPasswordLink() {
    final controller = this.controller;
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: controller.navigateToForgotPassword,
        child: Text(
          'Forgot Password?',
          style: AppTextStyles.textSm.copyWith(
            color: const Color(0xFF00B8A9),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context, _LoginLayout layout) {
    final controller = this.controller;
    return Obx(
      () => SizedBox(
        width: double.infinity,
        height: layout.primaryButtonHeight,
        child: ElevatedButton(
          onPressed: controller.isLoading.value
              ? null
              : () => controller.handleLogin(context),
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

  Widget _buildDivider(_LoginLayout layout) {
    final labelStyle = layout.isCompact
        ? AppTextStyles.textSm.copyWith(
            color: const Color(0xFF0A2342).withOpacity(0.4),
            fontSize: 12,
          )
        : AppTextStyles.textSm.copyWith(
            color: const Color(0xFF0A2342).withOpacity(0.4),
          );
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: const Color(0xFF0A2342).withOpacity(0.1),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: layout.isCompact ? 10 : 16,
          ),
          child: Text(
            'or continue with',
            style: labelStyle,
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

  Widget _buildSocialButtons(_LoginLayout layout) {
    final controller = this.controller;
    return Obx(
      () => Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSocialButton(
                  layout: layout,
                  label: 'Google',
                  onTap: controller.isLoading.value
                      ? null
                      : controller.handleGoogleLogin,
                  child: _GoogleLogo(compact: layout.isCompact),
                ),
              ),
              SizedBox(width: layout.roleGap),
              Expanded(
                child: _buildSocialButton(
                  layout: layout,
                  label: 'Apple',
                  onTap: controller.isLoading.value
                      ? null
                      : controller.handleAppleLogin,
                  child: _AppleLogo(compact: layout.isCompact),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required _LoginLayout layout,
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
          padding: EdgeInsets.symmetric(
            vertical: layout.isCompact ? 10 : 12,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFF0A2342).withOpacity(0.1),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              child,
              SizedBox(width: layout.isCompact ? 6 : 8),
              Flexible(
                child: Text(
                  label,
                  style: layout.isCompact
                      ? AppTextStyles.textBase.copyWith(
                          color: const Color(0xFF0A2342),
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        )
                      : AppTextStyles.textBase.copyWith(
                          color: const Color(0xFF0A2342),
                          fontWeight: FontWeight.w500,
                        ),
                  overflow: TextOverflow.ellipsis,
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
  const _GoogleLogo({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final s = compact ? 18.0 : 20.0;
    return SvgPicture.asset(
      'assets/images/google_logo.svg',
      width: s,
      height: s,
    );
  }
}

// Apple Logo
class _AppleLogo extends StatelessWidget {
  const _AppleLogo({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.apple,
      color: const Color(0xFF0A2342),
      size: compact ? 18 : 20,
    );
  }
}
