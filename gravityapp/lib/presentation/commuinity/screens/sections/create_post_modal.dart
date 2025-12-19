import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';    
import '../../../../app/theme/app_text_styles.dart';    
import '../../../commuinity/controllers/community_controller.dart';    

class CreatePostModal extends StatelessWidget {
  final dynamic controller;
  final Widget Function({
    required String imageUrl,
    required double size,
  }) buildUserAvatar;

  const CreatePostModal({
    super.key,
    required this.controller,
    required this.buildUserAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            _Header(onClose: _closeModal),
              _UserInfo(
                controller: controller,
                buildUserAvatar: buildUserAvatar,
              ),
              _PostBody(controller: controller),
              _PostButton(controller: controller),
          ],
        ),
      )
          .animate()
          .fadeIn(duration: 300.ms)
          .slideY(
            begin: 0.1,
            end: 0,
            duration: 400.ms,
            curve: Curves.easeOutCubic,
          ),
    );
  }

  void _closeModal() {
    // Reset state and close dialog
    // Note: resetCreatePostState() is called in closeCreatePostDialog(),
    // but we also call it here for manual close (X button) to ensure clean state
    controller.resetCreatePostState();
    controller.safeBack();
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onClose;

  const _Header({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF0A2342).withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Create Post',
            style: ResponsiveTextStyles.textXl.copyWith(
              color: const Color(0xFF0A2342),
              fontWeight: FontWeight.bold,
            ),
          ),
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 40.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: const Color(0xFF0A2342).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                size: 24.sp,
                color: const Color(0xFF0A2342),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserInfo extends StatelessWidget {
  final dynamic controller;
  final Widget Function({
    required String imageUrl,
    required double size,
  }) buildUserAvatar;

  const _UserInfo({
    required this.controller,
    required this.buildUserAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF0A2342).withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          ClipOval(
            child: Obx(
              () => buildUserAvatar(
                imageUrl: controller.currentUserProfileImage,
                size: 48,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Obx(
                () => Text(
                  controller.currentUserName,
                  style: ResponsiveTextStyles.textBase.copyWith(
                    color: const Color(0xFF0A2342),
                  ),
                ),
              ),
              Text(
                'Sharing to Community',
                style: ResponsiveTextStyles.textXs.copyWith(
                  color: const Color(0xFF0A2342).withOpacity(0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PostBody extends StatelessWidget {
  final dynamic controller;

  const _PostBody({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(24.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller.createPostTextController,
              onChanged: (v) => controller.newPostText.value = v,
              maxLines: 5,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Share your wellness journey...',
                border: InputBorder.none,
              ),
            ),
            // Image Preview (when image is selected)
            Obx(
              () => controller.selectedImage.value.isEmpty
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: EdgeInsets.only(top: 16.h),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20.r),
                            child: controller.selectedImagePath.value.isNotEmpty
                                ? Image.file(
                                    File(controller.selectedImagePath.value),
                                    height: 256.h,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  )
                                : CachedNetworkImage(
                                    imageUrl: controller.selectedImage.value,
                                    height: 256.h,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          // Remove image button
                          Positioned(
                            top: 12.h,
                            right: 12.w,
                            child: GestureDetector(
                              onTap: () => controller.clearSelectedImage(),
                              child: Container(
                                width: 32.w,
                                height: 32.h,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16.sp,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            // Image Upload Section (when no image is selected)
            Obx(
              () => controller.selectedImage.value.isEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 16.h),
                        Row(
                          children: [
                            Icon(
                              Icons.image_outlined,
                              size: 20.sp,
                              color: const Color(0xFF00B8A9),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'Add a photo to your post',
                              style: ResponsiveTextStyles.textSm.copyWith(
                                color: const Color(0xFF0A2342).withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        // Upload Image Button
                        Obx(
                          () => GestureDetector(
                            onTap: controller.isPickingImage.value
                                ? () {}
                                : () => controller.showImageSourcePicker(),
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(vertical: 20.h),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00B8A9).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(
                                  color: const Color(0xFF00B8A9).withOpacity(0.3),
                                  width: 2,
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: controller.isPickingImage.value
                                  ? Center(
                                      child: SizedBox(
                                        width: 24.w,
                                        height: 24.h,
                                        child: const CircularProgressIndicator(
                                          color: Color(0xFF00B8A9),
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                  : Column(
                                      children: [
                                        Icon(
                                          Icons.cloud_upload_outlined,
                                          size: 32.sp,
                                          color: const Color(0xFF00B8A9),
                                        ),
                                        SizedBox(height: 8.h),
                                        Text(
                                          'Upload from Device',
                                          style: ResponsiveTextStyles.textSm.copyWith(
                                            color: const Color(0xFF00B8A9),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(height: 4.h),
                                        Text(
                                          'Tap to select from gallery or camera',
                                          style: ResponsiveTextStyles.textXs.copyWith(
                                            color: const Color(0xFF0A2342).withOpacity(0.5),
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostButton extends StatelessWidget {
  final dynamic controller;

  const _PostButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: const Color(0xFF0A2342).withOpacity(0.1),
          ),
        ),
      ),
      child: Obx(() {
        final canPost = controller.newPostText.value.trim().isNotEmpty;
        final isCreating = controller.isCreatingPost.value;

        return GestureDetector(
          onTap: canPost && !isCreating ? controller.createPost : null,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            decoration: BoxDecoration(
              gradient: canPost
                  ? const LinearGradient(
                      colors: [
                        Color(0xFF00B8A9),
                        Color(0xFF0A2342),
                      ],
                    )
                  : null,
              color: canPost
                  ? null
                  : const Color(0xFF0A2342).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Center(
              child: Text(
                isCreating ? 'Creating...' : 'Share Post',
                style: ResponsiveTextStyles.textBase.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
