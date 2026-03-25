import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_text_styles.dart';
import '../controllers/signup_controller.dart';

/// Layout metrics for signup — adapts to screen size and avoids keyboard overflow.
class _SignupLayout {
  _SignupLayout._(this.size, this.shortestSide);

  final Size size;
  final double shortestSide;

  factory _SignupLayout.of(BuildContext context) {
    final media = MediaQuery.of(context);
    return _SignupLayout._(media.size, media.size.shortestSide);
  }

  bool get isCompact => shortestSide < 360;
  bool get isMedium => shortestSide >= 360 && shortestSide < 420;

  double get horizontalPadding => isCompact ? 16.0 : (isMedium ? 20.0 : 24.0);

  double get cardInnerPadding => isCompact ? 20.0 : (isMedium ? 28.0 : 32.0);

  double get titleFontSize => isCompact ? 24.0 : (isMedium ? 28.0 : 32.0);

  double get headerHeight {
    final h = size.height;
    final fraction = h < 560 ? 0.26 : 0.28;
    return (h * fraction).clamp(200.0, 340.0);
  }

  double get cardTopSpacer {
    final h = size.height;
    return (h * 0.16).clamp(96.0, 220.0);
  }

  double get roleGap => isCompact ? 10.0 : 16.0;

  double get fieldVerticalPadding => isCompact ? 12.0 : 16.0;

  double get primaryButtonHeight => isCompact ? 50.0 : 56.0;
}

class SignupScreen extends GetView<SignupController> {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final layout = _SignupLayout.of(context);
    final media = MediaQuery.of(context);
    final viewInsets = media.viewInsets;
    final topPad = media.padding.top;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF5F6FA),
      body: Stack(
        children: [
          // BACKGROUND HEADER (visual only — back control is overlay below)
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
                top: topPad + 48,
                bottom: layout.isCompact ? 24 : 32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create Account',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: layout.titleFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: layout.isCompact ? 6 : 8),
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
                                constraints: const BoxConstraints(
                                  maxWidth: 600,
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
                                child: Obx(
                                  () => controller.isSignupSuccess.value
                                      ? _buildSuccessContent(layout)
                                      : Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _buildRoleSelection(layout),
                                            SizedBox(
                                                height:
                                                    layout.isCompact ? 20 : 24),
                                            _buildFullNameField(layout),
                                            SizedBox(
                                                height:
                                                    layout.isCompact ? 12 : 16),
                                            _buildEmailField(layout),
                                            SizedBox(
                                                height:
                                                    layout.isCompact ? 12 : 16),
                                            _buildPhoneField(layout),
                                            SizedBox(
                                                height:
                                                    layout.isCompact ? 12 : 16),
                                            _buildPasswordField(layout),
                                            SizedBox(
                                                height:
                                                    layout.isCompact ? 12 : 16),
                                            _buildConfirmPasswordField(layout),
                                            SizedBox(
                                                height:
                                                    layout.isCompact ? 20 : 24),
                                            _buildSignupButton(layout),
                                            SizedBox(
                                                height:
                                                    layout.isCompact ? 20 : 24),
                                            _buildDivider(layout),
                                            SizedBox(
                                                height:
                                                    layout.isCompact ? 20 : 24),
                                            _buildSocialButtons(layout),
                                            SizedBox(
                                                height:
                                                    layout.isCompact ? 20 : 24),
                                            _buildTermsText(),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: layout.isCompact ? 24 : 32),

                          _buildLoginLink(media.padding.bottom),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Back button above scroll so it stays tappable
          Positioned(
            left: layout.horizontalPadding,
            top: topPad + 8,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
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
            ),
          ),
        ],
      ),
    );
  }

  // ---------- ROLE SELECTION ----------

  Widget _buildRoleSelection(_SignupLayout layout) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'I am a',
          style: AppTextStyles.textBase.copyWith(
            color: const Color(0xFF0A2342).withOpacity(0.6),
          ),
        ),
        SizedBox(height: layout.isCompact ? 10 : 12),
        Obx(() {
          final selected = controller.selectedRole.value;
          return Row(
            children: [
              Expanded(
                child: _buildRoleCard(
                  layout: layout,
                  label: 'Customer',
                  description: 'Track my wellness',
                  icon: Icons.person,
                  isSelected: selected == UserType.customer,
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
    required _SignupLayout layout,
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

  // ---------- FIELDS ----------

  Widget _buildFullNameField(_SignupLayout layout) {
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
          textInputAction: TextInputAction.next,
          style: AppTextStyles.textBase.copyWith(
            color: const Color(0xFF0A2342),
          ),
          cursorColor: const Color(0xFF0A2342),
          decoration: _baseInputDecoration(
            layout: layout,
            hint: 'John Doe',
            icon: Icons.person_outline,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField(_SignupLayout layout) {
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
          decoration: _baseInputDecoration(
            layout: layout,
            hint: 'your.email@example.com',
            icon: Icons.mail_outline,
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField(_SignupLayout layout) {
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
          textInputAction: TextInputAction.next,
          style: AppTextStyles.textBase.copyWith(
            color: const Color(0xFF0A2342),
          ),
          cursorColor: const Color(0xFF0A2342),
          decoration: _baseInputDecoration(
            layout: layout,
            hint: '+1 (555) 000-0000',
            icon: Icons.phone_outlined,
          ),
        ),
      ],
    );
  }

  InputDecoration _baseInputDecoration({
    required _SignupLayout layout,
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
        borderSide: const BorderSide(color: Color(0xFF00B8A9), width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: layout.fieldVerticalPadding,
      ),
    );
  }

  Widget _buildPasswordField(_SignupLayout layout) {
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
            textInputAction: TextInputAction.next,
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
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
                borderSide: BorderSide(color: Color(0xFF00B8A9), width: 2),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: layout.fieldVerticalPadding,
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

  Widget _buildConfirmPasswordField(_SignupLayout layout) {
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
                textInputAction: TextInputAction.done,
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
                  isDense: layout.isCompact,
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
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: layout.fieldVerticalPadding,
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

  Widget _buildSignupButton(_SignupLayout layout) {
    return Obx(() {
      final isBusy = controller.isLoading.value;
      final isEnabled = controller.isFormValid.value && !isBusy;

      return SizedBox(
        width: double.infinity,
        height: layout.primaryButtonHeight,
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

  Widget _buildDivider(_SignupLayout layout) {
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

  Widget _buildSocialButtons(_SignupLayout layout) {
    return Obx(() {
      final isBusy = controller.isLoading.value;
      return Row(
        children: [
          Expanded(
            child: _buildSocialButton(
              layout: layout,
              label: 'Google',
              onTap: isBusy ? null : controller.handleGoogleSignup,
              child: _GoogleLogo(compact: layout.isCompact),
            ),
          ),
          SizedBox(width: layout.roleGap),
          Expanded(
            child: _buildSocialButton(
              layout: layout,
              label: 'Apple',
              onTap: isBusy ? null : controller.handleAppleSignup,
              child: _AppleLogo(compact: layout.isCompact),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildSocialButton({
    required _SignupLayout layout,
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

  Widget _buildLoginLink(double bottomInset) {
    return Padding(
      padding: EdgeInsets.only(bottom: 24 + bottomInset),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
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

  Widget _buildSuccessContent(_SignupLayout layout) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: layout.isCompact ? 12 : 20),
        Container(
          width: layout.isCompact ? 72 : 80,
          height: layout.isCompact ? 72 : 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF00B8A9).withOpacity(0.1),
          ),
          child: Icon(
            Icons.check_circle,
            color: const Color(0xFF00B8A9),
            size: layout.isCompact ? 44 : 50,
          ),
        ),
        SizedBox(height: layout.isCompact ? 20 : 24),
        Text(
          'Account Created!',
          style: AppTextStyles.textBase.copyWith(
            fontSize: layout.isCompact ? 22 : (layout.isMedium ? 26 : 28),
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0A2342),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: layout.isCompact ? 8 : 12),
        Text(
          'Your account has been successfully created. You can now sign in to continue.',
          style: AppTextStyles.textBase.copyWith(
            color: const Color(0xFF0A2342).withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: layout.isCompact ? 24 : 32),
        SizedBox(
          width: double.infinity,
          height: layout.primaryButtonHeight,
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
        SizedBox(height: layout.isCompact ? 12 : 20),
      ],
    );
  }
}

// ---------- GOOGLE LOGO ----------

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

// ---------- APPLE LOGO ----------

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
