import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/app_colors.dart';
import '../controllers/community_controller.dart';

class CommunityPage extends GetView<CommunityController> {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize controller if not already done
    if (!Get.isRegistered<CommunityController>()) {
      Get.put(CommunityController());
    }

    return Stack(
      children: [
        // Main feed - Match React: px-6 py-6 space-y-4
        Obx(() {
          // Show communities if available, otherwise show posts
          if (controller.communities.isNotEmpty) {
            return ListView.builder(
              padding: EdgeInsets.only(
                left: 24.w,  // px-6 = 24px
                right: 24.w, // px-6 = 24px
                top: 24.h,   // py-6 = 24px
                bottom: 100.h, // Prevent overflow with bottom nav
              ),
              itemCount: controller.communities.length,
              itemBuilder: (context, index) {
                return _buildCommunityCard(controller.communities[index], index);
              },
            );
          } else {
            return ListView.builder(
              padding: EdgeInsets.only(
                left: 24.w,  // px-6 = 24px
                right: 24.w, // px-6 = 24px
                top: 24.h,   // py-6 = 24px
                bottom: 100.h, // Prevent overflow with bottom nav
              ),
              itemCount: controller.posts.length,
              itemBuilder: (context, index) {
                return _buildPostCard(controller.posts[index], index);
              },
            );
          }
        }),

        // Floating Action Button - Create Post
        Positioned(
          bottom: 24.h,
          right: 24.w,
          child: FloatingActionButton(
            onPressed: () => _showCreatePostModal(context),
            backgroundColor: const Color(0xFF00B8A9),
            elevation: 8,
            child: Icon(Icons.add, size: 28.sp, color: Colors.white),
          ),
        ),

        // Comments Modal
        Obx(() => controller.selectedPostId.value != 0
            ? _buildCommentsModal()
            : const SizedBox.shrink()),

        // Edit Post Modal
        Obx(() => controller.showEditPost.value
            ? _buildEditPostModal()
            : const SizedBox.shrink()),
      ],
    );
  }

  Widget _buildPostCard(Post post, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h), // space-y-4 = 16px spacing between posts
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User header - Match React: p-5 padding
          Padding(
            padding: EdgeInsets.all(20.r), // p-5 = 20px
            child: Row(
              children: [
                // Avatar - Match React: w-12 h-12 = 48px diameter, radius 24
                CircleAvatar(
                  radius: 24.r,
                  backgroundImage: CachedNetworkImageProvider(post.user.avatar),
                  backgroundColor: AppColors.muted,
                ),
                SizedBox(width: 12.w), // gap-3 = 12px
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.user.name,
                        style: ResponsiveTextStyles.textBase.copyWith(
                          color: const Color(0xFF0A2342),
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        post.timestamp,
                        style: ResponsiveTextStyles.textXs.copyWith(
                          color: const Color(0xFF0A2342).withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                // More options button (Edit/Delete)
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: const Color(0xFF0A2342).withOpacity(0.5),
                    size: 20.sp,
                  ),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      controller.openEditPost(post);
                    } else if (value == 'delete') {
                      controller.confirmDeletePost(post.id);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            size: 18.sp,
                            color: const Color(0xFF0A2342),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'Edit Post',
                            style: ResponsiveTextStyles.textSm.copyWith(
                              color: const Color(0xFF0A2342),
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outlined,
                            size: 18.sp,
                            color: const Color(0xFFE53935),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'Delete Post',
                            style: ResponsiveTextStyles.textSm.copyWith(
                              color: const Color(0xFFE53935),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Post image - Match React: h-64 = 256px
          if (post.image.isNotEmpty)
            Container(
              height: 256.h, // h-64 = 256px (exact match)
              width: double.infinity,
              color: AppColors.muted,
              child: CachedNetworkImage(
                imageUrl: post.image,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 256.h,
                  color: AppColors.muted,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF00B8A9),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 256.h,
                  color: AppColors.muted,
                  child: Icon(Icons.image_not_supported, size: 48.sp),
                ),
              ),
            ),

          // Post text - Match React: p-5 padding, mb-4 margin-bottom
          Padding(
            padding: EdgeInsets.all(20.r), // p-5 = 20px
            child: Text(
              post.text,
              style: ResponsiveTextStyles.textBase.copyWith(
                color: const Color(0xFF0A2342).withOpacity(0.8),
              ),
            ),
          ),

          // Reactions bar - Match React: flex items-center justify-between pt-4 border-t border-[#0A2342]/10
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h), // p-5 = 20px horizontal/vertical
            child: Container(
              padding: EdgeInsets.only(top: 16.h), // pt-4 = 16px top padding
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: const Color(0xFF0A2342).withOpacity(0.1), // border-[#0A2342]/10
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // justify-between
                crossAxisAlignment: CrossAxisAlignment.center, // items-center
                children: [
                  // Left side: Reaction buttons - Match React: flex items-center gap-4
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildReactionButton(
                        post.id,
                        'heart',
                        Icons.favorite,
                        post.reactions.heart,
                        Colors.red,
                      ),
                      SizedBox(width: 16.w), // gap-4 = 16px
                      _buildReactionButton(
                        post.id,
                        'thumbsUp',
                        Icons.thumb_up,
                        post.reactions.thumbsUp,
                        Colors.blue,
                      ),
                      SizedBox(width: 16.w), // gap-4 = 16px
                      _buildReactionButton(
                        post.id,
                        'fire',
                        Icons.local_fire_department,
                        post.reactions.fire,
                        Colors.orange,
                      ),
                    ],
                  ),
                  // Right side: Comment button - Match React: motion.button with whileTap={{ scale: 0.9 }}
                  _buildCommentButton(post.id, post.comments.length),
                ],
              ),
            ),
          ),
        ],
      ),
    )
        // Match React AnimatePresence animation: initial={{ opacity: 0, y: 20 }}, animate={{ opacity: 1, y: 0 }}, delay: index * 0.1
        .animate()
        .fadeIn(duration: 300.ms, delay: (index * 100).ms)
        .moveY(
          begin: 20.h, // y: 20 (20 pixels)
          end: 0,
          duration: 300.ms,
          delay: (index * 100).ms,
          curve: Curves.easeOut,
        );
  }

  Widget _buildReactionButton(
      int postId,
      String reaction,
      IconData icon,
      int count,
      Color activeColor,
      ) {
    return Obx(() {
      final isActive =
          controller.activeReactions[postId]?.contains(reaction) ?? false;

      // Match React: motion.button with whileTap={{ scale: 0.9 }}
      return _AnimatedTapWidget(
        onTap: () => controller.toggleReaction(postId, reaction),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20.sp, // w-5 h-5 = 20px (match React)
              color: isActive
                  ? activeColor
                  : const Color(0xFF0A2342).withOpacity(0.6), // text-[#0A2342]/60
            ),
            SizedBox(width: 8.w), // gap-2 = 8px (match React)
            Text(
              '$count',
              style: ResponsiveTextStyles.textSm.copyWith(
                color: isActive
                    ? activeColor
                    : const Color(0xFF0A2342).withOpacity(0.6), // text-[#0A2342]/60
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      );
    });
  }

  // Comment button - Match React: motion.button with MessageCircle icon
  // className="flex items-center gap-2 text-[#0A2342]/60 hover:text-[#00B8A9] transition-colors"
  // whileTap={{ scale: 0.9 }}
  Widget _buildCommentButton(int postId, int commentCount) {
    return _AnimatedTapWidget(
      onTap: () => controller.openComments(postId), // Opens bottom sheet modal
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.mode_comment_outlined, // MessageCircle equivalent - matches React <MessageCircle className="w-5 h-5" />
            size: 20.sp, // w-5 h-5 = 20px (match React)
            color: const Color(0xFF0A2342).withOpacity(0.6), // text-[#0A2342]/60
          ),
          SizedBox(width: 8.w), // gap-2 = 8px (match React)
          Text(
            '$commentCount',
            style: ResponsiveTextStyles.textSm.copyWith( // text-sm
              color: const Color(0xFF0A2342).withOpacity(0.6), // text-[#0A2342]/60
            ),
          ),
        ],
      ),
    );
  }

  // Show Create Post Modal - Match React: fixed inset-0 z-[60] for backdrop, z-[70] for modal
  // Uses Get.dialog() to appear ABOVE the app header
  void _showCreatePostModal(BuildContext context) {
    Get.dialog(
      // Full screen dialog that covers everything including header
      Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Backdrop - Match React: fixed inset-0 bg-black/50 z-[60]
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  controller.newPostText.value = '';
                  controller.clearSelectedImage();
                  Get.back();
                },
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                ),
              ),
            ).animate().fadeIn(duration: 200.ms),

            // Modal - Match React: fixed bottom-0 left-0 right-0 rounded-t-[40px] z-[70] max-h-[90vh]
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                constraints: BoxConstraints(maxHeight: 0.9.sh),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Modal Header - Match React: p-6 border-b border-[#0A2342]/10
                    Container(
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
                          _AnimatedTapWidget(
                            onTap: () {
                              controller.newPostText.value = '';
                              controller.clearSelectedImage();
                              Get.back();
                            },
                            child: Container(
                              width: 32.w,
                              height: 32.h,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0A2342).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                size: 20.sp,
                                color: const Color(0xFF0A2342),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // User Info - Match React: p-6 border-b border-[#0A2342]/10
                    Container(
                      padding: EdgeInsets.all(24.r), // p-6 = 24px
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: const Color(0xFF0A2342).withOpacity(0.1),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Avatar - Match React: w-12 h-12 rounded-full
                          Container(
                            width: 48.w, // w-12 = 48px
                            height: 48.h, // h-12 = 48px
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[200], // bg-gray-200
                            ),
                            child: ClipOval(
                              child: Obx(() => _buildUserAvatar(
                                imageUrl: controller.currentUserProfileImage,
                                size: 48,
                              )),
                            ),
                          ),
                          SizedBox(width: 12.w), // gap-3 = 12px
                          // User Info Text
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // User name - Match React: text-[#0A2342]
                              Obx(() => Text(
                                controller.currentUserName,
                                style: ResponsiveTextStyles.textBase.copyWith(
                                  color: const Color(0xFF0A2342),
                                ),
                              )),
                              // "Sharing to Community" text - Match React: text-[#0A2342]/50 text-xs
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
                    ),

                    // Post Content - Match React: flex-1 overflow-y-auto p-6 space-y-4
                    Flexible(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(24.r),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Text Input
                            TextField(
                              onChanged: (value) => controller.newPostText.value = value,
                              maxLines: 5,
                              autofocus: true,
                              decoration: InputDecoration(
                                hintText: 'Share your wellness journey...',
                                hintStyle: ResponsiveTextStyles.textBase.copyWith(
                                  color: const Color(0xFF0A2342).withOpacity(0.4),
                                ),
                                border: InputBorder.none,
                              ),
                              style: ResponsiveTextStyles.textBase.copyWith(
                                color: const Color(0xFF0A2342),
                              ),
                            ),

                            // Selected Image Preview
                            Obx(() => controller.selectedImage.value.isNotEmpty
                                ? Container(
                                    margin: EdgeInsets.only(top: 16.h),
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(20.r),
                                          child: controller.selectedImagePath.value.isNotEmpty
                                              // Local file image
                                              ? Image.file(
                                                  File(controller.selectedImagePath.value),
                                                  height: 256.h,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                )
                                              // Network image (sample images)
                                              : CachedNetworkImage(
                                                  imageUrl: controller.selectedImage.value,
                                                  height: 256.h,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                ),
                                        ),
                                        Positioned(
                                          top: 12.h,
                                          right: 12.w,
                                          child: _AnimatedTapWidget(
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
                                  )
                                    .animate()
                                    .fadeIn(duration: 200.ms)
                                    .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), duration: 200.ms)
                                : const SizedBox.shrink()),

                            // Image Gallery / Upload Section
                            Obx(() => controller.selectedImage.value.isEmpty
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
                                      Obx(() => _AnimatedTapWidget(
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
                                      )),
                                      
                                    ],
                                  )
                                : const SizedBox.shrink()),
                          ],
                        ),
                      ),
                    ),

                    // Post Button - Match React: p-6 border-t border-[#0A2342]/10 bg-white
                    Container(
                      padding: EdgeInsets.all(24.r),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(
                            color: const Color(0xFF0A2342).withOpacity(0.1),
                          ),
                        ),
                      ),
                      child: Obx(() {
                        final canPost = controller.newPostText.value.trim().isNotEmpty;
                        final isCreating = controller.isCreatingPost.value;
                        
                        return _AnimatedTapWidget(
                          onTap: (canPost && !isCreating) ? () async {
                            // Controller handles dialog closing and success message
                            await controller.createPost();
                          } : () {},
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            decoration: BoxDecoration(
                              gradient: (canPost && !isCreating)
                                  ? const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [Color(0xFF00B8A9), Color(0xFF0A2342)],
                                    )
                                  : null,
                              color: (canPost && !isCreating) ? null : const Color(0xFF0A2342).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isCreating)
                                  SizedBox(
                                    width: 20.sp,
                                    height: 20.sp,
                                    child: const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                else
                                  Icon(
                                    Icons.send,
                                    size: 20.sp,
                                    color: canPost
                                        ? Colors.white
                                        : const Color(0xFF0A2342).withOpacity(0.4),
                                  ),
                                SizedBox(width: 8.w),
                                Text(
                                  isCreating ? 'Creating...' : 'Share Post',
                                  style: ResponsiveTextStyles.textBase.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: (canPost || isCreating)
                                        ? Colors.white
                                        : const Color(0xFF0A2342).withOpacity(0.4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              )
                  .animate()
                  .slideY(
                    begin: 1.0,
                    end: 0.0,
                    duration: 400.ms,
                    curve: Curves.easeOutCubic,
                  ),
            ),
          ],
        ),
      ),
      barrierDismissible: false, // We handle dismissal ourselves
      barrierColor: Colors.transparent, // We draw our own backdrop
      useSafeArea: false, // Important: Don't use SafeArea to cover entire screen
    );
  }

  // Edit Post Modal - Similar to Create Post Modal but for editing
  Widget _buildEditPostModal() {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Backdrop
          Positioned.fill(
            child: GestureDetector(
              onTap: () => controller.closeEditPost(),
              child: Container(
                color: Colors.black.withOpacity(0.5),
              ),
            ),
          ).animate().fadeIn(duration: 200.ms),

          // Modal
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              constraints: BoxConstraints(maxHeight: 0.9.sh),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Modal Header
                  Container(
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
                          'Edit Post',
                          style: ResponsiveTextStyles.textXl.copyWith(
                            color: const Color(0xFF0A2342),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        _AnimatedTapWidget(
                          onTap: () => controller.closeEditPost(),
                          child: Container(
                            width: 32.w,
                            height: 32.h,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0A2342).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              size: 20.sp,
                              color: const Color(0xFF0A2342),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // User Info - Match React: p-6 border-b border-[#0A2342]/10
                  Container(
                    padding: EdgeInsets.all(24.r), // p-6 = 24px
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: const Color(0xFF0A2342).withOpacity(0.1),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Avatar - Match React: w-12 h-12 rounded-full
                        Container(
                          width: 48.w, // w-12 = 48px
                          height: 48.h, // h-12 = 48px
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[200], // bg-gray-200
                          ),
                          child: ClipOval(
                            child: Obx(() => _buildUserAvatar(
                              imageUrl: controller.currentUserProfileImage,
                              size: 48,
                            )),
                          ),
                        ),
                        SizedBox(width: 12.w), // gap-3 = 12px
                        // User Info Text
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // User name - Match React: text-[#0A2342]
                            Obx(() => Text(
                              controller.currentUserName,
                              style: ResponsiveTextStyles.textBase.copyWith(
                                color: const Color(0xFF0A2342),
                              ),
                            )),
                            // "Editing in Community" text - Match React style: text-[#0A2342]/50 text-xs
                            Text(
                              'Editing in Community',
                              style: ResponsiveTextStyles.textXs.copyWith(
                                color: const Color(0xFF0A2342).withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Edit Content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(24.r),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Text Input
                          Obx(() => TextField(
                            controller: TextEditingController(text: controller.editPostText.value)
                              ..selection = TextSelection.fromPosition(
                                TextPosition(offset: controller.editPostText.value.length),
                              ),
                            onChanged: (value) => controller.editPostText.value = value,
                            maxLines: 5,
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: 'Edit your post...',
                              hintStyle: ResponsiveTextStyles.textBase.copyWith(
                                color: const Color(0xFF0A2342).withOpacity(0.4),
                              ),
                              border: InputBorder.none,
                            ),
                            style: ResponsiveTextStyles.textBase.copyWith(
                              color: const Color(0xFF0A2342),
                            ),
                          )),

                          // Current Image Preview
                          Obx(() => controller.editPostImage.value.isNotEmpty
                              ? Container(
                                  margin: EdgeInsets.only(top: 16.h),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(20.r),
                                        child: controller.editPostImagePath.value.isNotEmpty
                                            // Local file image (newly picked)
                                            ? Image.file(
                                                File(controller.editPostImagePath.value),
                                                height: 200.h,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                              )
                                            // Network image (existing image or URL)
                                            : CachedNetworkImage(
                                                imageUrl: controller.editPostImage.value,
                                                height: 200.h,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) => Container(
                                                  height: 200.h,
                                                  color: AppColors.muted,
                                                  child: const Center(
                                                    child: CircularProgressIndicator(
                                                      color: Color(0xFF00B8A9),
                                                    ),
                                                  ),
                                                ),
                                                errorWidget: (context, url, error) => Container(
                                                  height: 200.h,
                                                  color: AppColors.muted,
                                                  child: const Icon(Icons.image_not_supported),
                                                ),
                                              ),
                                      ),
                                      Positioned(
                                        top: 12.h,
                                        right: 12.w,
                                        child: _AnimatedTapWidget(
                                          onTap: () => controller.clearEditSelectedImage(),
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
                                )
                              : const SizedBox.shrink()),

                          // Image Upload Section (for adding new image)
                          Obx(() => controller.editPostImage.value.isEmpty
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
                                    Obx(() => _AnimatedTapWidget(
                                      onTap: controller.isPickingImage.value 
                                          ? () {} 
                                          : () => controller.showImageSourcePickerForEdit(),
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
                                    )),
                                  ],
                                )
                              : const SizedBox.shrink()),
                        ],
                      ),
                    ),
                  ),

                  // Update Button
                  Container(
                    padding: EdgeInsets.all(24.r),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(
                          color: const Color(0xFF0A2342).withOpacity(0.1),
                        ),
                      ),
                    ),
                    child: Obx(() {
                      final canUpdate = controller.editPostText.value.trim().isNotEmpty;
                      final isUpdating = controller.isUpdatingPost.value;
                      
                      return _AnimatedTapWidget(
                        onTap: (canUpdate && !isUpdating) ? () async {
                          await controller.updatePost();
                        } : () {},
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          decoration: BoxDecoration(
                            gradient: (canUpdate && !isUpdating)
                                ? const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Color(0xFF00B8A9), Color(0xFF0A2342)],
                                  )
                                : null,
                            color: (canUpdate && !isUpdating) ? null : const Color(0xFF0A2342).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (isUpdating)
                                SizedBox(
                                  width: 20.sp,
                                  height: 20.sp,
                                  child: const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              else
                                Icon(
                                  Icons.check,
                                  size: 20.sp,
                                  color: canUpdate
                                      ? Colors.white
                                      : const Color(0xFF0A2342).withOpacity(0.4),
                                ),
                              SizedBox(width: 8.w),
                              Text(
                                isUpdating ? 'Updating...' : 'Update Post',
                                style: ResponsiveTextStyles.textBase.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: (canUpdate || isUpdating)
                                      ? Colors.white
                                      : const Color(0xFF0A2342).withOpacity(0.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            )
                .animate()
                .slideY(
                  begin: 1.0,
                  end: 0.0,
                  duration: 400.ms,
                  curve: Curves.easeOutCubic,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsModal() {
    // Match React: AnimatePresence with spring animations
    return Obx(() {
      final post = controller.selectedPost;
      final isLoading = controller.isLoadingSinglePost.value;
      final error = controller.singlePostError.value;
      
      if (post == null && !isLoading) return const SizedBox.shrink();

      return Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Backdrop - Match React: initial={{ opacity: 0 }}, animate={{ opacity: 1 }}, bg-black/50
            Positioned.fill(
              child: GestureDetector(
                onTap: controller.closeComments,
                child: Container(
                  color: Colors.black.withOpacity(0.5), // bg-black/50
                ),
              ),
            ).animate().fadeIn(duration: 300.ms),

            // Modal content - Match React: spring animation, slide up from bottom
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                constraints: BoxConstraints(maxHeight: 0.85.sh), // max-h-[85vh]
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)), // rounded-t-[40px]
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20.r,
                      offset: Offset(0, -4.h),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with gradient - Match React: bg-gradient-to-br from-[#0A2342] to-[#00B8A9]
                    Container(
                      padding: EdgeInsets.all(24.r), // p-6 = 24px
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF0A2342), Color(0xFF00B8A9)],
                        ),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isLoading 
                                ? 'Loading...' 
                                : 'Comments (${post?.comments.length ?? 0})',
                            style: ResponsiveTextStyles.textXl.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          _AnimatedTapWidget(
                            onTap: controller.closeComments,
                            child: Container(
                              width: 40.w, // w-10 = 40px
                              height: 40.h, // h-10 = 40px
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2), // bg-white/20
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 20.sp, // w-5 h-5 = 20px
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Comments list with loading state
                    Flexible(
                      child: isLoading
                          ? Center(
                              child: Padding(
                                padding: EdgeInsets.all(40.r),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const CircularProgressIndicator(
                                      color: Color(0xFF00B8A9),
                                    ),
                                    SizedBox(height: 16.h),
                                    Text(
                                      'Loading post...',
                                      style: ResponsiveTextStyles.textSm.copyWith(
                                        color: const Color(0xFF0A2342).withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : error.isNotEmpty
                              ? Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(40.r),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          size: 48.sp,
                                          color: Colors.red.withOpacity(0.6),
                                        ),
                                        SizedBox(height: 16.h),
                                        Text(
                                          error,
                                          style: ResponsiveTextStyles.textSm.copyWith(
                                            color: const Color(0xFF0A2342).withOpacity(0.6),
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : post == null
                                  ? _buildEmptyComments()
                                  : post.comments.isEmpty
                                      ? _buildEmptyComments()
                                      : ListView.builder(
                                          padding: EdgeInsets.all(20.r),
                                          itemCount: post.comments.length,
                                          itemBuilder: (context, index) {
                                            return _buildCommentItem(post.id, post.comments[index]);
                                          },
                                        ),
                    ),

                    // Add comment input - Match React: p-6 border-t border-[#0A2342]/10 bg-white
                    Container(
                      padding: EdgeInsets.all(24.r), // p-6 = 24px
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(
                            color: const Color(0xFF0A2342).withOpacity(0.1), // border-[#0A2342]/10
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Avatar - Match React: w-10 h-10 = 40px
                          CircleAvatar(
                            radius: 20.r, // w-10 h-10 = 40px diameter
                            backgroundImage: const CachedNetworkImageProvider(
                              'https://i.pravatar.cc/150?img=1',
                            ),
                            backgroundColor: AppColors.muted,
                          ),
                          SizedBox(width: 12.w), // gap-3 = 12px
                          Expanded(
                            child: TextField(
                              onChanged: (value) => controller.newComment.value = value,
                              onSubmitted: (_) {
                                if (controller.newComment.value.trim().isNotEmpty && post != null) {
                                  controller.addComment(post.id);
                                }
                              },
                              decoration: InputDecoration(
                                hintText: 'Add a comment...',
                                hintStyle: ResponsiveTextStyles.textSm.copyWith(
                                  color: const Color(0xFF0A2342).withOpacity(0.4), // placeholder-[#0A2342]/40
                                ),
                                filled: true,
                                fillColor: AppColors.inputBackground, // bg-[#F5F6FA]
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24.r), // rounded-full
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16.w, // px-4
                                  vertical: 12.h, // py-3
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24.r),
                                  borderSide: BorderSide(
                                    color: const Color(0xFF00B8A9).withOpacity(0.2), // focus:ring-2 focus:ring-[#00B8A9]/20
                                    width: 2,
                                  ),
                                ),
                              ),
                              style: ResponsiveTextStyles.textSm.copyWith(
                                color: const Color(0xFF0A2342), // text-[#0A2342]
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w), // gap-3 = 12px
                          // Send button - Match React: w-12 h-12 rounded-full, gradient when enabled
                          Obx(() {
                            final canSend = controller.newComment.value.trim().isNotEmpty && post != null;
                            return _AnimatedTapWidget(
                              onTap: canSend ? () => controller.addComment(post!.id) : () {},
                              child: Container(
                                width: 48.w, // w-12 = 48px
                                height: 48.h, // h-12 = 48px
                                decoration: BoxDecoration(
                                  gradient: canSend
                                      ? const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [Color(0xFF00B8A9), Color(0xFF0A2342)],
                                        )
                                      : null,
                                  color: canSend ? null : const Color(0xFF0A2342).withOpacity(0.1), // bg-[#0A2342]/10
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.send,
                                  color: canSend
                                      ? Colors.white
                                      : const Color(0xFF0A2342).withOpacity(0.4), // text-[#0A2342]/40
                                  size: 20.sp, // w-5 h-5 = 20px
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              )
                // Match React: spring animation slide up from bottom
                // initial={{ opacity: 0, y: '100%' }}, animate={{ opacity: 1, y: 0 }}
                // transition={{ type: 'spring', damping: 30, stiffness: 300 }}
                .animate()
                .slideY(
                  begin: 1.0, // Start from bottom (y: '100%')
                  end: 0.0, // End at normal position (y: 0)
                  duration: 400.ms,
                  curve: Curves.easeOutCubic, // Spring-like: damping: 30, stiffness: 300
                )
                .fadeIn(duration: 300.ms),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildEmptyComments() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.mode_comment_outlined, // Match React: MessageCircle
              size: 64.sp, // w-16 h-16 = 64px
              color: const Color(0xFF0A2342).withOpacity(0.2), // text-[#0A2342]/20
            ),
            SizedBox(height: 16.h),
            Text(
              'No comments yet',
              style: ResponsiveTextStyles.textBase.copyWith(
                color: const Color(0xFF0A2342).withOpacity(0.4),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Be the first to comment!',
              style: ResponsiveTextStyles.textSm.copyWith(
                color: const Color(0xFF0A2342).withOpacity(0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentItem(int postId, Comment comment) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Comment
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16.r,
                      backgroundImage: CachedNetworkImageProvider(comment.user.avatar),
                      backgroundColor: AppColors.muted,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            comment.user.name,
                            style: ResponsiveTextStyles.textSm.copyWith(
                              color: const Color(0xFF0A2342),
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            comment.timestamp,
                            style: ResponsiveTextStyles.textXs.copyWith(
                              color: const Color(0xFF0A2342).withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  comment.text,
                  style: ResponsiveTextStyles.textSm.copyWith(
                    color: const Color(0xFF0A2342).withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),

          // Reply button
          Padding(
            padding: EdgeInsets.only(left: 16.w, top: 8.h),
            child: InkWell(
              onTap: () => controller.startReply(postId, comment.id),
              borderRadius: BorderRadius.circular(4.r),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                child: Text(
                  'Reply',
                  style: ResponsiveTextStyles.textXs.copyWith(
                    color: const Color(0xFF00B8A9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),

          // Replies
          if (comment.replies.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(left: 32.w, top: 12.h),
              child: Column(
                children: comment.replies
                    .map((reply) => _buildReplyItem(reply))
                    .toList(),
              ),
            ),

          // Reply input
          Obx(() {
            final isReplying = controller.replyingToPostId.value == postId &&
                controller.replyingToCommentId.value == comment.id;

            if (!isReplying) return const SizedBox.shrink();

            return Padding(
              padding: EdgeInsets.only(left: 32.w, top: 12.h),
              child: Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: const Color(0xFF00B8A9).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12.r,
                          backgroundImage: const CachedNetworkImageProvider(
                            'https://i.pravatar.cc/150?img=1',
                          ),
                          backgroundColor: AppColors.muted,
                        ),
                        SizedBox(width: 8.w),
                        Flexible(
                          child: Text(
                            'Replying to ${comment.user.name}',
                            style: ResponsiveTextStyles.textXs.copyWith(
                              color: const Color(0xFF0A2342).withOpacity(0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    TextField(
                      onChanged: (value) => controller.newReply.value = value,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Write a reply...',
                        hintStyle: ResponsiveTextStyles.textSm.copyWith(
                          color: const Color(0xFF0A2342).withOpacity(0.4),
                        ),
                        filled: true,
                        fillColor: AppColors.inputBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.all(12.r),
                      ),
                      style: ResponsiveTextStyles.textSm,
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: controller.cancelReply,
                          style: TextButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 8.h,
                            ),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Cancel',
                            style: ResponsiveTextStyles.textSm.copyWith(
                              color: const Color(0xFF0A2342).withOpacity(0.6),
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        ElevatedButton(
                          onPressed: () {
                            if (controller.newReply.value.trim().isNotEmpty) {
                              controller.addReply(postId, comment.id);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00B8A9),
                            minimumSize: Size.zero,
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 8.h,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Send',
                            style: ResponsiveTextStyles.textSm.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildReplyItem(Reply reply) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12.r,
                backgroundImage: CachedNetworkImageProvider(reply.user.avatar),
                backgroundColor: AppColors.muted,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reply.user.name,
                      style: ResponsiveTextStyles.textXs.copyWith(
                        color: const Color(0xFF0A2342),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      reply.timestamp,
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: const Color(0xFF0A2342).withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            reply.text,
            style: ResponsiveTextStyles.textXs.copyWith(
              color: const Color(0xFF0A2342).withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityCard(Map<String, dynamic> community, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Community header
            Row(
              children: [
                // Community icon
                Container(
                  width: 48.w,
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00B8A9).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.people,
                    color: const Color(0xFF00B8A9),
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        community['community_name'] ?? 'Unknown Community',
                        style: ResponsiveTextStyles.textBase.copyWith(
                          color: const Color(0xFF0A2342),
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'ID: ${community['id'] ?? 'N/A'}',
                        style: ResponsiveTextStyles.textXs.copyWith(
                          color: const Color(0xFF0A2342).withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            // Community description
            Text(
              community['community_description'] ?? '',
              style: ResponsiveTextStyles.textSm.copyWith(
                color: const Color(0xFF0A2342).withOpacity(0.8),
              ),
            ),
            SizedBox(height: 12.h),
            // Timestamps
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14.sp,
                  color: const Color(0xFF0A2342).withOpacity(0.5),
                ),
                SizedBox(width: 4.w),
                Flexible(
                  child: Text(
                    'Created: ${_formatDate(community['created_at'])}',
                    style: ResponsiveTextStyles.textXs.copyWith(
                      color: const Color(0xFF0A2342).withOpacity(0.5),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                SizedBox(width: 16.w),
                Icon(
                  Icons.update,
                  size: 14.sp,
                  color: const Color(0xFF0A2342).withOpacity(0.5),
                ),
                SizedBox(width: 4.w),
                Flexible(
                  child: Text(
                    'Updated: ${_formatDate(community['updated_at'])}',
                    style: ResponsiveTextStyles.textXs.copyWith(
                      color: const Color(0xFF0A2342).withOpacity(0.5),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms, delay: (index * 100).ms)
        .moveY(
          begin: 20.h,
          end: 0,
          duration: 300.ms,
          delay: (index * 100).ms,
          curve: Curves.easeOut,
        );
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  /// Build user avatar widget that handles local files, network URLs, and fallback
  Widget _buildUserAvatar({required String imageUrl, required double size}) {
    // If no image URL, show default icon
    if (imageUrl.isEmpty) {
      return Container(
        width: size.w,
        height: size.h,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.person,
          size: (size / 2).sp,
          color: Colors.grey[400],
        ),
      );
    }

    // Check if it's a local file path (starts with / or contains file path pattern)
    final isLocalFile = imageUrl.startsWith('/') || 
                        imageUrl.contains('\\') ||
                        imageUrl.startsWith('file://');

    if (isLocalFile) {
      // Local file image
      final file = File(imageUrl.replaceFirst('file://', ''));
      if (file.existsSync()) {
        return Image.file(
          file,
          width: size.w,
          height: size.h,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.person,
            size: (size / 2).sp,
            color: Colors.grey[400],
          ),
        );
      } else {
        return Icon(
          Icons.person,
          size: (size / 2).sp,
          color: Colors.grey[400],
        );
      }
    } else {
      // Network image
      return CachedNetworkImage(
        imageUrl: imageUrl,
        width: size.w,
        height: size.h,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[200],
          child: Icon(
            Icons.person,
            size: (size / 2).sp,
            color: Colors.grey[400],
          ),
        ),
        errorWidget: (context, url, error) => Icon(
          Icons.person,
          size: (size / 2).sp,
          color: Colors.grey[400],
        ),
      );
    }
  }
}

// Helper widget to provide tap animation matching React's motion.button whileTap={{ scale: 0.9 }}
class _AnimatedTapWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _AnimatedTapWidget({
    required this.child,
    required this.onTap,
  });

  @override
  State<_AnimatedTapWidget> createState() => _AnimatedTapWidgetState();
}

class _AnimatedTapWidgetState extends State<_AnimatedTapWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}