import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_text_styles.dart';
import '../controllers/otp_verification_controller.dart';

class _OtpVerificationLayout {
  _OtpVerificationLayout._(this.size, this.shortestSide);

  final Size size;
  final double shortestSide;

  factory _OtpVerificationLayout.of(BuildContext context) {
    final media = MediaQuery.of(context);
    return _OtpVerificationLayout._(media.size, media.size.shortestSide);
  }

  bool get isCompact => shortestSide < 360;
  bool get isMedium => shortestSide >= 360 && shortestSide < 420;

  double get horizontalPadding => isCompact ? 16.0 : (isMedium ? 20.0 : 24.0);

  double get cardInnerPadding => isCompact ? 20.0 : (isMedium ? 28.0 : 32.0);

  double get titleFontSize => isCompact ? 24.0 : (isMedium ? 28.0 : 32.0);

  double get otpFontSize => isCompact ? 18.0 : (isMedium ? 22.0 : 24.0);

  double get otpLetterSpacing => isCompact ? 4.0 : (isMedium ? 6.0 : 8.0);

  double get headerHeight {
    final h = size.height;
    final fraction = h < 560 ? 0.26 : 0.30;
    return (h * fraction).clamp(200.0, 340.0);
  }

  double get cardTopSpacer => (size.height * 0.14).clamp(88.0, 210.0);

  double get fieldVerticalPadding => isCompact ? 12.0 : 16.0;

  double get primaryButtonHeight => isCompact ? 50.0 : 56.0;

  double get sectionGapLarge => isCompact ? 24.0 : 32.0;

  double get sectionGapMedium => isCompact ? 20.0 : 24.0;
}

class OtpVerificationScreen extends GetView<OtpVerificationController> {
  const OtpVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final layout = _OtpVerificationLayout.of(context);
    final media = MediaQuery.of(context);
    final viewInsets = media.viewInsets;
    final statusBarHeight = media.padding.top;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF5F6FA),
      body: Stack(
        children: [
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
                top: statusBarHeight + (layout.isCompact ? 20 : 24),
                bottom: layout.isCompact ? 24 : 32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Verify OTP',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: layout.titleFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: layout.isCompact ? 6 : 8),
                  Obx(
                    () => Text(
                      'Enter the OTP sent to\n${controller.email.value}',
                      style: AppTextStyles.textBase.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

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
                      padding: EdgeInsets.only(bottom: viewInsets.bottom + 24),
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
                                padding:
                                    EdgeInsets.all(layout.cardInnerPadding),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildOtpField(layout),
                                    SizedBox(height: layout.sectionGapMedium),
                                    _buildResendOtpSection(layout),
                                    SizedBox(height: layout.sectionGapLarge),
                                    _buildVerifyButton(layout),
                                    SizedBox(height: layout.sectionGapMedium),
                                    _buildBackLink(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 16 + media.padding.bottom),
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

  Widget _buildOtpField(_OtpVerificationLayout layout) {
    final otpStyle = AppTextStyles.textBase.copyWith(
      color: const Color(0xFF0A2342),
      fontSize: layout.otpFontSize,
      letterSpacing: layout.otpLetterSpacing,
      fontWeight: FontWeight.bold,
    );
    final hintStyle = AppTextStyles.textBase.copyWith(
      color: const Color(0xFF0A2342).withOpacity(0.3),
      fontSize: layout.otpFontSize,
      letterSpacing: layout.otpLetterSpacing,
    );

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
            textInputAction: TextInputAction.done,
            maxLength: 6,
            style: otpStyle,
            textAlign: TextAlign.center,
            cursorColor: const Color(0xFF0A2342),
            decoration: InputDecoration(
              hintText: '000000',
              hintStyle: hintStyle,
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
              isDense: layout.isCompact,
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
              contentPadding: EdgeInsets.symmetric(
                horizontal: layout.isCompact ? 8 : 16,
                vertical: layout.fieldVerticalPadding,
              ),
              counterText: '',
            ),
          ),
        ),
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

  Widget _buildResendOtpSection(_OtpVerificationLayout layout) {
    return Obx(
      () => Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 6,
        children: [
          Text(
            "Didn't receive the OTP?",
            style: AppTextStyles.textSm.copyWith(
              color: const Color(0xFF0A2342).withOpacity(0.6),
            ),
          ),
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

  Widget _buildVerifyButton(_OtpVerificationLayout layout) {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        height: layout.primaryButtonHeight,
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
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        children: [
          const Icon(
            Icons.arrow_back,
            size: 16,
            color: Color(0xFF00B8A9),
          ),
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
