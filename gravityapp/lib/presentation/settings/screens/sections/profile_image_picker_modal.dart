import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../controllers/settings_controller.dart';

class ProfileImagePickerModal extends StatelessWidget {
  final SettingsController controller;

  const ProfileImagePickerModal({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Obx(() {
          final tempImage = controller.tempImagePath.value;
          final tempImageBytes = controller.tempImageBytes.value;
          final isProcessing = controller.isProcessingImage.value;

          return Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Profile Image',
                      style: ResponsiveTextStyles.textLg.copyWith(
                        color: const Color(0xFF0A2342),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: isProcessing
                          ? null
                          : controller.closeProfileImageModal,
                      icon: Icon(
                        Icons.close,
                        color: isProcessing
                            ? Colors.grey
                            : const Color(0xFF0A2342),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),
                
                // Image Preview or Selection Options
                if (tempImage == null)
                  // Selection Options
                  Column(
                    children: [
                      _buildOptionButton(
                        context: context,
                        icon: Icons.camera_alt,
                        title: 'Take Photo',
                        subtitle: 'Capture a new photo',
                        onTap: controller.pickImageFromCamera,
                      ),
                      SizedBox(height: 16.h),
                      _buildOptionButton(
                        context: context,
                        icon: Icons.photo_library,
                        title: 'Choose from Gallery',
                        subtitle: 'Select from your photos',
                        onTap: controller.pickImageFromGallery,
                      ),
                    ],
                  )
                else
                  // Image Preview with Crop Instructions
                  Column(
                    children: [
                      // Instructions
                      // Container(
                      //   padding: EdgeInsets.all(12.w),
                      //   decoration: BoxDecoration(
                      //     color: const Color(0xFF00B8A9).withOpacity(0.1),
                      //     borderRadius: BorderRadius.circular(12.r),
                      //     border: Border.all(
                      //       color: const Color(0xFF00B8A9).withOpacity(0.3),
                      //       width: 1,
                      //     ),
                      //   ),

                      // ),
                      SizedBox(height: 16.h),
                      // Image Preview
                      Container(
                        width: double.infinity,
                        height: 300.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: const Color(0xFF00B8A9).withOpacity(0.3),
                            width: 2,
                          ),
                          color: Colors.grey[100],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14.r),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              _buildImageWidget(tempImage, tempImageBytes),
                              // Overlay crop guide (square)
                             
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 24.h),
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isProcessing
                                  ? null
                                  : () {
                                      controller.tempImagePath.value = null;
                                      controller.tempImageBytes.value = null;
                                    },
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 16.h),
                                side: BorderSide(
                                  color: const Color(0xFF0A2342).withOpacity(0.3),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                              child: Text(
                                'Change',
                                style: ResponsiveTextStyles.textBase.copyWith(
                                  color: const Color(0xFF0A2342),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: isProcessing
                                  ? null
                                  : controller.saveProfileImage,
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 16.h),
                                backgroundColor: const Color(0xFF00B8A9),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                elevation: 0,
                              ),
                              child: isProcessing
                                  ? SizedBox(
                                      height: 20.h,
                                      width: 20.w,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Save',
                                          style: ResponsiveTextStyles.textBase.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  /// Build Image Widget (web-compatible)
  Widget _buildImageWidget(String? imagePath, Uint8List? imageBytes) {
    if (kIsWeb) {
      // For web, use Image.memory with bytes
      if (imageBytes != null && imageBytes.isNotEmpty) {
        return Image.memory(
          imageBytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[200],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.grey[400],
                      size: 48.sp,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Failed to load image',
                      style: ResponsiveTextStyles.textSm.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      } else {
        return Container(
          color: Colors.grey[200],
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.grey[400],
                  size: 48.sp,
                ),
                SizedBox(height: 8.h),
                Text(
                  'No image data',
                  style: ResponsiveTextStyles.textSm.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } else {
      // For mobile, use Image.file
      if (imagePath != null) {
        try {
          final file = File(imagePath);
          if (file.existsSync()) {
            return Image.file(
              file,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.grey[400],
                          size: 48.sp,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Failed to load image',
                          style: ResponsiveTextStyles.textSm.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        } catch (e) {
          debugPrint('Error loading image file: $e');
        }
      }
      return Container(
        color: Colors.grey[200],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.grey[400],
                size: 48.sp,
              ),
              SizedBox(height: 8.h),
              Text(
                'No image selected',
                style: ResponsiveTextStyles.textSm.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  /// Build Option Button
  Widget _buildOptionButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: const Color(0xFF00B8A9).withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56.w,
              height: 56.h,
              decoration: BoxDecoration(
                color: const Color(0xFF00B8A9).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF00B8A9),
                size: 28.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: ResponsiveTextStyles.textBase.copyWith(
                      color: const Color(0xFF0A2342),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: ResponsiveTextStyles.textSm.copyWith(
                      color: const Color(0xFF0A2342).withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: const Color(0xFF0A2342).withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter to draw crop guide overlay (square)
class CropGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final dashPaint = Paint()
      ..color = const Color(0xFF00B8A9).withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Calculate square size (80% of smaller dimension)
    final minSize = size.width < size.height ? size.width : size.height;
    final squareSize = minSize * 0.8;
    final left = (size.width - squareSize) / 2;
    final top = (size.height - squareSize) / 2;
    final right = left + squareSize;
    final bottom = top + squareSize;

    // Draw semi-transparent overlay outside crop area
    final overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    // Top overlay
    canvas.drawRect(Rect.fromLTRB(0, 0, size.width, top), overlayPaint);
    // Bottom overlay
    canvas.drawRect(Rect.fromLTRB(0, bottom, size.width, size.height), overlayPaint);
    // Left overlay
    canvas.drawRect(Rect.fromLTRB(0, top, left, bottom), overlayPaint);
    // Right overlay
    canvas.drawRect(Rect.fromLTRB(right, top, size.width, bottom), overlayPaint);

    // Draw crop guide border
    canvas.drawRect(
      Rect.fromLTRB(left, top, right, bottom),
      dashPaint,
    );

    // Draw corner indicators
    final cornerLength = 20.0;
    final cornerPaint = Paint()
      ..color = const Color(0xFF00B8A9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Top-left corner
    canvas.drawLine(
      Offset(left, top),
      Offset(left + cornerLength, top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left, top),
      Offset(left, top + cornerLength),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(right, top),
      Offset(right - cornerLength, top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(right, top),
      Offset(right, top + cornerLength),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(left, bottom),
      Offset(left + cornerLength, bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left, bottom),
      Offset(left, bottom - cornerLength),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(right, bottom),
      Offset(right - cornerLength, bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(right, bottom),
      Offset(right, bottom - cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(CropGuidePainter oldDelegate) => false;
}

