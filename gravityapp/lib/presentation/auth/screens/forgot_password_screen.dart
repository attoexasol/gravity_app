import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_text_styles.dart';
import '../controllers/forgot_password_controller.dart';

class _ForgotPasswordLayout {
  _ForgotPasswordLayout._(this.size, this.shortestSide);

  final Size size;
  final double shortestSide;

  factory _ForgotPasswordLayout.of(BuildContext context) {
    final media = MediaQuery.of(context);
    return _ForgotPasswordLayout._(media.size, media.size.shortestSide);
  }

  bool get isCompact => shortestSide < 360;
  bool get isMedium => shortestSide >= 360 && shortestSide < 420;

  double get horizontalPadding => isCompact ? 16.0 : (isMedium ? 20.0 : 24.0);

  double get cardInnerPadding => isCompact ? 20.0 : (isMedium ? 28.0 : 32.0);

  double get titleFontSize => isCompact ? 24.0 : (isMedium ? 28.0 : 32.0);

  double get headerHeight {
    final h = size.height;
    final fraction = h < 560 ? 0.24 : 0.28;
    return (h * fraction).clamp(180.0, 300.0);
  }

  double get cardTopSpacer => (size.height * 0.14).clamp(88.0, 200.0);

  double get fieldVerticalPadding => isCompact ? 12.0 : 16.0;

  double get primaryButtonHeight => isCompact ? 50.0 : 56.0;

  double get sectionGapLarge => isCompact ? 24.0 : 32.0;

  double get sectionGapMedium => isCompact ? 20.0 : 24.0;
}

class ForgotPasswordScreen extends GetView<ForgotPasswordController> {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final layout = _ForgotPasswordLayout.of(context);
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
                    'Forgot Password?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: layout.titleFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: layout.isCompact ? 6 : 8),
                  Text(
                    'Enter your email to receive an OTP',
                    style: AppTextStyles.textBase.copyWith(
                      color: Colors.white.withOpacity(0.9),
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
                                padding: EdgeInsets.all(layout.cardInnerPadding),
                                child: _buildFormView(layout),
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

  Widget _buildFormView(_ForgotPasswordLayout layout) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEmailField(layout),
        SizedBox(height: layout.sectionGapLarge),
        _buildSendButton(layout),
        SizedBox(height: layout.sectionGapMedium),
        _buildBackToLoginLink(),
      ],
    );
  }

  Widget _buildEmailField(_ForgotPasswordLayout layout) {
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
        Obx(
          () => TextField(
            controller: controller.emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            style: AppTextStyles.textBase.copyWith(
              color: const Color(0xFF0A2342),
            ),
            cursorColor: const Color(0xFF0A2342),
            decoration: InputDecoration(
              hintText: 'your.email@example.com',
              hintStyle: AppTextStyles.textBase.copyWith(
                color: const Color(0xFF0A2342).withOpacity(0.3),
              ),
              prefixIcon: Icon(
                controller.errorMessage.value.isNotEmpty
                    ? Icons.error_outline
                    : Icons.mail_outline,
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
                horizontal: 16,
                vertical: layout.fieldVerticalPadding,
              ),
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

  Widget _buildSendButton(_ForgotPasswordLayout layout) {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        height: layout.primaryButtonHeight,
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
                  'Send OTP',
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
