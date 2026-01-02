import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../app/theme/app_text_styles.dart';

class CreatePostModal extends StatelessWidget {
  final dynamic controller;
  final Widget Function({required String imageUrl, required double size})
  buildUserAvatar;

  const CreatePostModal({
    super.key,
    required this.controller,
    required this.buildUserAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside the text field
        FocusScope.of(context).unfocus();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20.r,
              offset: Offset(0, -4.h),
            ),
          ],
        ),
        child:
            Material(
                  color: Colors.transparent,
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
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A2342), Color(0xFF00B8A9)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
        border: Border(
          bottom: BorderSide(color: const Color(0xFF0A2342).withOpacity(0.1)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Create Post',
            style: ResponsiveTextStyles.textXl.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 40.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, size: 24.sp, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserInfo extends StatelessWidget {
  final dynamic controller;
  final Widget Function({required String imageUrl, required double size})
  buildUserAvatar;

  const _UserInfo({required this.controller, required this.buildUserAvatar});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: const Color(0xFF0A2342).withOpacity(0.1)),
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

class _PostBody extends StatefulWidget {
  final dynamic controller;

  const _PostBody({required this.controller});

  @override
  State<_PostBody> createState() => _PostBodyState();
}

class _PostBodyState extends State<_PostBody> {
  late FocusNode _textFieldFocusNode;

  @override
  void initState() {
    super.initState();
    _textFieldFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _textFieldFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Only autofocus on Android, not iOS
    final bool shouldAutofocus = Platform.isAndroid;

    return Expanded(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(24.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: widget.controller.createPostTextController,
              focusNode: _textFieldFocusNode,
              onChanged: (v) => widget.controller.newPostText.value = v,
              onEditingComplete: () {
                // Dismiss keyboard when user finishes editing (iOS behavior)
                if (Platform.isIOS) {
                  _textFieldFocusNode.unfocus();
                }
              },
              onSubmitted: (_) {
                // Dismiss keyboard when user submits (iOS behavior)
                if (Platform.isIOS) {
                  _textFieldFocusNode.unfocus();
                }
              },
              maxLines: 5,
              autofocus: shouldAutofocus,
              style: AppTextStyles.textBase.copyWith(
                color: const Color(0xFF0A2342), // Dark text color
              ),
              cursorColor: const Color(0xFF0A2342), // Dark cursor
              decoration: InputDecoration(
                hintText: 'Share your wellness journey...',
                hintStyle: AppTextStyles.textBase.copyWith(
                  color: const Color(0xFF0A2342).withOpacity(0.4),
                ),
                border: InputBorder.none,
              ),
            ),
            // Image Preview (when image is selected)
            Obx(
              () => widget.controller.selectedImage.value.isEmpty
                  ? const SizedBox.shrink()
                  : GestureDetector(
                      onTap: () {
                        // Dismiss keyboard when tapping on image section (iOS)
                        if (Platform.isIOS) {
                          _textFieldFocusNode.unfocus();
                        }
                      },
                      child: Padding(
                        padding: EdgeInsets.only(top: 16.h),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20.r),
                              child:
                                  widget
                                      .controller
                                      .selectedImagePath
                                      .value
                                      .isNotEmpty
                                  ? Image.file(
                                      File(
                                        widget
                                            .controller
                                            .selectedImagePath
                                            .value,
                                      ),
                                      height: 256.h,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    )
                                  : CachedNetworkImage(
                                      imageUrl:
                                          widget.controller.selectedImage.value,
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
                                onTap: () {
                                  widget.controller.clearSelectedImage();
                                  // Dismiss keyboard when removing image (iOS)
                                  if (Platform.isIOS) {
                                    _textFieldFocusNode.unfocus();
                                  }
                                },
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
            ),
            // Image Upload Section (when no image is selected)
            Obx(
              () => widget.controller.selectedImage.value.isEmpty
                  ? GestureDetector(
                      onTap: () {
                        // Dismiss keyboard when tapping on upload section (iOS)
                        if (Platform.isIOS) {
                          _textFieldFocusNode.unfocus();
                        }
                      },
                      child: Column(
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
                                  color: const Color(
                                    0xFF0A2342,
                                  ).withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12.h),
                          // Upload Image Button
                          Obx(
                            () => GestureDetector(
                              onTap: widget.controller.isPickingImage.value
                                  ? () {}
                                  : () {
                                      // Dismiss keyboard before showing image picker (iOS)
                                      if (Platform.isIOS) {
                                        _textFieldFocusNode.unfocus();
                                      }
                                      widget.controller.showImageSourcePicker();
                                    },
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(vertical: 20.h),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF00B8A9,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16.r),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF00B8A9,
                                    ).withOpacity(0.3),
                                    width: 2,
                                    style: BorderStyle.solid,
                                  ),
                                ),
                                child: widget.controller.isPickingImage.value
                                    ? Center(
                                        child: SizedBox(
                                          width: 24.w,
                                          height: 24.h,
                                          child:
                                              const CircularProgressIndicator(
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
                                            style: ResponsiveTextStyles.textSm
                                                .copyWith(
                                                  color: const Color(
                                                    0xFF00B8A9,
                                                  ),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          SizedBox(height: 4.h),
                                          Text(
                                            'Tap to select from gallery or camera',
                                            style: ResponsiveTextStyles.textXs
                                                .copyWith(
                                                  color: const Color(
                                                    0xFF0A2342,
                                                  ).withOpacity(0.5),
                                                ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
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
          top: BorderSide(color: const Color(0xFF0A2342).withOpacity(0.1)),
        ),
      ),
      child: Obx(() {
        final canPost = controller.newPostText.value.trim().isNotEmpty;
        final isCreating = controller.isCreatingPost.value;

        return GestureDetector(
          onTap: canPost && !isCreating
              ? () {
                  // Dismiss keyboard before creating post (iOS)
                  if (Platform.isIOS) {
                    FocusScope.of(context).unfocus();
                  }
                  controller.createPost();
                }
              : null,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            decoration: BoxDecoration(
              gradient: canPost
                  ? const LinearGradient(
                      colors: [Color(0xFF00B8A9), Color(0xFF0A2342)],
                    )
                  : null,
              color: canPost ? null : const Color(0xFF0A2342).withOpacity(0.1),
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
