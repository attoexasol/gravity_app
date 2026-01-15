import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_text_styles.dart';
import '../controllers/otp_verification_controller.dart';

class OtpVerificationScreen extends GetView<OtpVerificationController> {
  const OtpVerificationScreen({super.key});

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
                    'Verify OTP',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 28 : 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Obx(
                    () => Text(
                      'Enter the OTP sent to\n${controller.email.value}',
                      style: AppTextStyles.textBase.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
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
                    // OTP VERIFICATION CARD
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
                            _buildOtpField(),
                            const SizedBox(height: 24),
                            _buildResendOtpSection(),
                            const SizedBox(height: 32),
                            _buildVerifyButton(),
                            const SizedBox(height: 24),
                            _buildBackLink(),
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

  Widget _buildOtpField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter OTP',
          style: AppTextStyles.textBase.copyWith(
            color: const Color(0xFF0A2342).withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 8),
        Obx(
          () => TextField(
            controller: controller.otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            style: AppTextStyles.textBase.copyWith(
              color: const Color(0xFF0A2342),
              fontSize: 24,
              letterSpacing: 8,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            cursorColor: const Color(0xFF0A2342),
            decoration: InputDecoration(
              hintText: '000000',
              hintStyle: AppTextStyles.textBase.copyWith(
                color: const Color(0xFF0A2342).withOpacity(0.3),
                fontSize: 24,
                letterSpacing: 8,
              ),
              prefixIcon: Icon(
                controller.errorMessage.value.isNotEmpty
                    ? Icons.error_outline
                    : Icons.lock_outline,
                color: controller.errorMessage.value.isNotEmpty
                    ? Colors.red
                    : const Color(0xFF00B8A9),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: controller.errorMessage.value.isNotEmpty
                      ? Colors.red
                      : const Color(0xFF0A2342).withOpacity(0.1),
                  width: 2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: controller.errorMessage.value.isNotEmpty
                      ? Colors.red
                      : const Color(0xFF0A2342).withOpacity(0.1),
                  width: 2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: controller.errorMessage.value.isNotEmpty
                      ? Colors.red
                      : const Color(0xFF00B8A9),
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              counterText: '',
            ),
          ),
        ),
        // Error message display
        Obx(
          () => controller.errorMessage.value.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 18,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          controller.errorMessage.value,
                          style: AppTextStyles.textSm.copyWith(
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildResendOtpSection() {
    return Obx(
      () => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Didn't receive the OTP?",
            style: AppTextStyles.textSm.copyWith(
              color: const Color(0xFF0A2342).withOpacity(0.6),
            ),
          ),
          const SizedBox(width: 8),
          if (controller.canResend.value)
            GestureDetector(
              onTap: controller.resendOtp,
              child: Text(
                'Resend OTP',
                style: AppTextStyles.textSm.copyWith(
                  color: const Color(0xFF00B8A9),
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            Text(
              'Resend OTP in ${controller.resendCountdown.value}s',
              style: AppTextStyles.textSm.copyWith(
                color: const Color(0xFF0A2342).withOpacity(0.4),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVerifyButton() {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: controller.isLoading.value
              ? null
              : controller.handleVerifyOtp,
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
                  'Verify OTP',
                  style: AppTextStyles.textBase.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildBackLink() {
    return GestureDetector(
      onTap: controller.navigateBack,
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
            'Back',
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
