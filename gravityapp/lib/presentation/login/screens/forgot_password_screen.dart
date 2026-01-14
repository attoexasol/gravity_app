import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_text_styles.dart';
import '../controllers/forgot_password_controller.dart';

class ForgotPasswordScreen extends GetView<ForgotPasswordController> {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Stack(
        children: [
          // BACKGROUND HEADER - Extends to status bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: size.height * 0.28,
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
                left: 24,
                right: 24,
                top: statusBarHeight + 24,
                bottom: 32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 28 : 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your email to receive a password reset link',
                    style: AppTextStyles.textBase.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // FOREGROUND CONTENT (SCROLLABLE)
          Positioned.fill(
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: size.height * 0.18),
                    // FORGOT PASSWORD CARD
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
                          () => controller.isSuccess.value
                              ? _buildSuccessView()
                              : _buildFormView(),
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

  Widget _buildFormView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEmailField(),
        const SizedBox(height: 32),
        _buildSendButton(),
        const SizedBox(height: 24),
        _buildBackToLoginLink(),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF00B8A9).withOpacity(0.1),
          ),
          child: const Icon(
            Icons.check_circle_outline,
            color: Color(0xFF00B8A9),
            size: 50,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Check Your Email',
          style: AppTextStyles.textXl.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0A2342),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'We\'ve sent a password reset link to your email address. Please check your inbox and follow the instructions.',
          textAlign: TextAlign.center,
          style: AppTextStyles.textBase.copyWith(
            color: const Color(0xFF0A2342).withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 32),
        // Demo: Show reset password button (in real app, this would be via email link)
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: () => controller.navigateToResetPassword(),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF00B8A9), width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'Demo: Go to Reset Password',
              style: AppTextStyles.textBase.copyWith(
                color: const Color(0xFF00B8A9),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildBackToLoginLink(),
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

  Widget _buildSendButton() {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: controller.isLoading.value
              ? null
              : controller.handleForgotPassword,
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
                  'Send Reset Link',
                  style: AppTextStyles.textBase.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildBackToLoginLink() {
    return GestureDetector(
      onTap: controller.navigateToLogin,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.arrow_back,
            size: 16,
            color: Color(0xFF00B8A9),
          ),
          const SizedBox(width: 8),
          Text(
            'Back to Login',
            style: AppTextStyles.textBase.copyWith(
              color: const Color(0xFF00B8A9),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

