import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/services/preferences_service.dart';
import '../../controllers/settings_controller.dart';

class AccountSection extends StatelessWidget {
  final String name;
  final String email;
  final String initials;
  final String? profileImagePath;

  const AccountSection({
    super.key,
    required this.name,
    required this.email,
    required this.initials,
    this.profileImagePath,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SettingsController>();
    
    // Load profile image from preferences as fallback (for persistence)
    // Prefer API URL over local path, matching Community page behavior
    final profileImageUrl = PreferencesService.getStorage().read('user_profile_image_url') as String?;
    final profileImagePathFromStorage = profileImageUrl ?? 
        (PreferencesService.getStorage().read('user_profile_image') as String?);
    
    // Use controller value if available, otherwise fallback to storage
    final effectiveProfileImagePath = profileImagePath ?? profileImagePathFromStorage;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Account'),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    controller.showProfileImagePickerModal();
                  },
                  child: Stack(
                    children: [
                      Container(
                        width: 64.w,
                        height: 64.h,
                        decoration: BoxDecoration(
                          gradient: effectiveProfileImagePath == null
                              ? const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Color(0xFF00B8A9), Color(0xFF0A2342)],
                                )
                              : null,
                          color: effectiveProfileImagePath != null ? Colors.transparent : null,
                          borderRadius: BorderRadius.circular(32.r),
                          border: effectiveProfileImagePath != null
                              ? Border.all(
                                  color: const Color(0xFF00B8A9),
                                  width: 2,
                                )
                              : null,
                        ),
                        child: effectiveProfileImagePath != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(32.r),
                                child: _buildProfileImageWidget(effectiveProfileImagePath, initials),
                              )
                            : Center(
                                child: Text(
                                  initials,
                                  style: ResponsiveTextStyles.textXl.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      ),
                      // Edit icon overlay
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 20.w,
                          height: 20.h,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00B8A9),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            size: 12.sp,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: ResponsiveTextStyles.textBase.copyWith(
                          color: const Color(0xFF0A2342),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        email,
                        style: ResponsiveTextStyles.textSm.copyWith(
                          color: const Color(0xFF0A2342).withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
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

  /// Build Profile Image Widget (web-compatible)
  Widget _buildProfileImageWidget(String imagePath, String initials) {
    // Check if imagePath is a network URL
    final isNetworkUrl = imagePath.startsWith('http://') || imagePath.startsWith('https://');
    
    if (isNetworkUrl) {
      // Use CachedNetworkImage for network URLs (from API)
      return CachedNetworkImage(
        imageUrl: imagePath,
        width: 64.w,
        height: 64.h,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: 64.w,
          height: 64.h,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF00B8A9), Color(0xFF0A2342)],
            ),
            borderRadius: BorderRadius.circular(32.r),
          ),
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
        errorWidget: (context, url, error) {
          return _buildInitialsFallback(initials);
        },
      );
    } else if (kIsWeb) {
      // For web, Image.file is not supported
      // Show initials as fallback for local files
      return _buildInitialsFallback(initials);
    } else {
      // For mobile, use Image.file for local files
      try {
        if (File(imagePath).existsSync()) {
          return Image.file(
            File(imagePath),
            width: 64.w,
            height: 64.h,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildInitialsFallback(initials);
            },
          );
        }
      } catch (e) {
        debugPrint('Error loading profile image: $e');
      }
      return _buildInitialsFallback(initials);
    }
  }

  /// Build Initials Fallback
  Widget _buildInitialsFallback(String initials) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00B8A9), Color(0xFF0A2342)],
        ),
        borderRadius: BorderRadius.circular(32.r),
      ),
      child: Center(
        child: Text(
          initials,
          style: ResponsiveTextStyles.textXl.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// Private Title Builder
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Text(
        title,
        style: ResponsiveTextStyles.textLg.copyWith(
          color: const Color(0xFF0A2342),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
