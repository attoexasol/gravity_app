import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/app_colors.dart';
import '../controllers/community_controller.dart';
import 'sections/create_post_modal.dart';


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
        // Main feed with pull-to-refresh - Match React: px-6 py-6 space-y-4
        RefreshIndicator(
          onRefresh: controller.refreshPosts,
          color: const Color(0xFF00B8A9),
          backgroundColor: Colors.white,
          child: Obx(() {
            // Show loading indicator while fetching posts
            if (controller.isLoadingPosts.value && controller.posts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: Color(0xFF00B8A9),
                      strokeWidth: 3,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Loading posts...',
                      style: ResponsiveTextStyles.textBase.copyWith(
                        color: const Color(0xFF0A2342).withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              );
            }

            // Show error message if posts failed to load
            if (controller.postsError.value.isNotEmpty && controller.posts.isEmpty) {
              // Wrap in ListView to enable pull-to-refresh even on error
              return ListView(
                padding: EdgeInsets.all(40.r),
                children: [
                  SizedBox(height: 200.h), // Center vertically
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64.sp,
                        color: Colors.red.withOpacity(0.6),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        controller.postsError.value,
                        style: ResponsiveTextStyles.textBase.copyWith(
                          color: const Color(0xFF0A2342).withOpacity(0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 24.h),
                      ElevatedButton(
                        onPressed: () => controller.onReady(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00B8A9),
                          padding: EdgeInsets.symmetric(
                            horizontal: 24.w,
                            vertical: 12.h,
                          ),
                        ),
                        child: Text(
                          'Retry',
                          style: ResponsiveTextStyles.textBase.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'Or pull down to refresh',
                        style: ResponsiveTextStyles.textSm.copyWith(
                          color: const Color(0xFF0A2342).withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }

            // Show empty state if no posts
            if (controller.posts.isEmpty) {
              // Wrap in ListView to enable pull-to-refresh even when empty
              return ListView(
                padding: EdgeInsets.all(40.r),
                children: [
                  SizedBox(height: 200.h), // Center vertically
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.forum_outlined,
                        size: 64.sp,
                        color: const Color(0xFF0A2342).withOpacity(0.3),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'No posts yet',
                        style: ResponsiveTextStyles.textXl.copyWith(
                          color: const Color(0xFF0A2342),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Be the first to share something!',
                        style: ResponsiveTextStyles.textBase.copyWith(
                          color: const Color(0xFF0A2342).withOpacity(0.6),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'Pull down to refresh',
                        style: ResponsiveTextStyles.textSm.copyWith(
                          color: const Color(0xFF0A2342).withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }

            // Show posts list
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
          }),
        ),

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

        // Comments Modal - Removed from Stack, now uses Get.bottomSheet via _showCommentsModal

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
        color: Colors.white, // bg-white
        borderRadius: BorderRadius.circular(28.r), // rounded-[28px]
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1), // shadow-md
            blurRadius: 10.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge, // overflow-hidden
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Header - Match React: p-5 flex items-center gap-3
          Padding(
            padding: EdgeInsets.all(20.r), // p-5 = 20px
            child: Row(
              children: [
                // Avatar - Match React: w-12 h-12 rounded-full overflow-hidden bg-gray-200
                ClipOval(
                  child: Container(
                    width: 48.w, // w-12 = 48px
                    height: 48.h, // h-12 = 48px
                    color: Colors.grey[200], // bg-gray-200
                    child: post.user.avatar.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: post.user.avatar,
                            width: 48.w,
                            height: 48.h,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width: 48.w,
                              height: 48.h,
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF00B8A9),
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: 48.w,
                              height: 48.h,
                              color: Colors.grey[200],
                              child: Icon(
                                Icons.person,
                                size: 24.sp,
                                color: const Color(0xFF0A2342).withOpacity(0.5),
                              ),
                            ),
                          )
                        : Icon(
                            Icons.person,
                            size: 24.sp,
                            color: const Color(0xFF0A2342).withOpacity(0.5),
                          ),
                  ),
                ),
                SizedBox(width: 12.w), // gap-3 = 12px
                // User Info - Match React: flex-1
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name - Match React: text-[#0A2342]
                      Text(
                        post.user.name,
                        style: ResponsiveTextStyles.textBase.copyWith(
                          color: const Color(0xFF0A2342),
                        ),
                      ),
                      // Timestamp - Match React: text-[#0A2342]/50 text-xs
                      Text(
                        post.timestamp,
                        style: ResponsiveTextStyles.textXs.copyWith(
                          color: const Color(0xFF0A2342).withOpacity(0.5), // text-[#0A2342]/50
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Post Image - Match React: relative h-64 bg-gray-100 (only if post.image exists)
          if (post.image.isNotEmpty)
            Container(
              height: 256.h, // h-64 = 256px
              width: double.infinity,
              color: Colors.grey[100], // bg-gray-100
              child: CachedNetworkImage(
                imageUrl: post.image,
                width: double.infinity,
                height: 256.h,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 256.h,
                  color: Colors.grey[100],
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF00B8A9),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 256.h,
                  color: Colors.grey[100],
                  child: Icon(Icons.image_not_supported, size: 48.sp),
                ),
              ),
            ),

          // Post Text + Reactions - Match React: p-5
          Padding(
            padding: EdgeInsets.all(20.r), // p-5 = 20px
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Post Text - Match React: text-[#0A2342]/80 mb-4
                Padding(
                  padding: EdgeInsets.only(bottom: 16.h), // mb-4 = 16px
                  child: Text(
                    post.text,
                    style: ResponsiveTextStyles.textBase.copyWith(
                      color: const Color(0xFF0A2342).withOpacity(0.8), // text-[#0A2342]/80
                    ),
                  ),
                ),

                // Reactions Bar - Match React: flex items-center justify-between pt-4 border-t border-[#0A2342]/10
                Container(
                  padding: EdgeInsets.only(top: 16.h), // pt-4 = 16px
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
                      // Right side: Comment button - Match React: flex items-center gap-2 text-[#0A2342]/60
                      _buildCommentButton(post.id, post.comments.length),
                    ],
                  ),
                ),
              ],
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
      onTap: () => _showCommentsModal(postId), // Opens bottom sheet modal
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

  // Show Create Post Modal - Full screen mode
  // Root cause: State must be reset BEFORE opening dialog to ensure fresh state every time
  void _showCreatePostModal(BuildContext context) {
    // Ensure any previous dialog is closed first
    if (Get.isDialogOpen == true) {
      Get.back();
      // Wait a frame to ensure dialog is fully closed
      Future.delayed(const Duration(milliseconds: 100), () {
        _openCreatePostDialog();
      });
    } else {
      _openCreatePostDialog();
    }
  }

  // Open the create post dialog with fresh state
  void _openCreatePostDialog() {
    // Reset all state BEFORE opening dialog to ensure consistent behavior
    controller.resetCreatePostState();
    
    Get.dialog(
      CreatePostModal(
        controller: controller,
        buildUserAvatar: _buildUserAvatar,
      ),
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.3),
      useSafeArea: true,
    );
  }

  // Show Comments Modal - Bottom sheet mode
  void _showCommentsModal(int postId) {
    controller.openComments(postId);
    Get.bottomSheet(
      _buildCommentsBottomSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      isDismissible: true,
      enableDrag: true,
    );
  }

  // Build Comments Bottom Sheet
  Widget _buildCommentsBottomSheet() {
    return Obx(() {
      final postId = controller.selectedPostId.value;
      final comments = controller.postComments;
      final isLoading = controller.isLoadingComments.value;
      final error = controller.commentsError.value;
      
      if (postId == 0) return const SizedBox.shrink();

      return Container(
        constraints: BoxConstraints(maxHeight: 0.9.sh),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with gradient
            Container(
              padding: EdgeInsets.all(24.r),
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
                        : 'Comments (${comments.length})',
                    style: ResponsiveTextStyles.textXl.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _AnimatedTapWidget(
                    onTap: () {
                      controller.closeComments();
                      Get.back();
                    },
                    child: Container(
                      width: 40.w,
                      height: 40.h,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20.sp,
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
                              'Loading comments...',
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
                      : comments.isEmpty
                          ? _buildEmptyComments()
                          : ListView.builder(
                              padding: EdgeInsets.all(20.r),
                              itemCount: comments.length,
                              itemBuilder: (context, index) {
                                return _buildCommentItem(postId, comments[index]);
                              },
                            ),
            ),

            // Add comment input
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
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20.r,
                    backgroundImage: const CachedNetworkImageProvider(
                      'https://i.pravatar.cc/150?img=1',
                    ),
                    backgroundColor: AppColors.muted,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: TextField(
                      controller: controller.commentTextController,
                      onChanged: (value) => controller.newComment.value = value,
                      onSubmitted: (_) async {
                        if (controller.newComment.value.trim().isNotEmpty && 
                            postId != 0 && 
                            !controller.isCreatingComment.value) {
                          await controller.addComment(postId);
                        }
                      },
                      enabled: !controller.isCreatingComment.value,
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        hintStyle: ResponsiveTextStyles.textSm.copyWith(
                          color: const Color(0xFF0A2342).withOpacity(0.4),
                        ),
                        filled: true,
                        fillColor: AppColors.inputBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.r),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.r),
                          borderSide: BorderSide(
                            color: const Color(0xFF00B8A9).withOpacity(0.2),
                            width: 2,
                          ),
                        ),
                      ),
                      style: ResponsiveTextStyles.textSm.copyWith(
                        color: const Color(0xFF0A2342),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Obx(() {
                    final canSend = controller.newComment.value.trim().isNotEmpty && postId != 0;
                    final isCreating = controller.isCreatingComment.value;
                    return _AnimatedTapWidget(
                      onTap: (canSend && !isCreating) ? () => controller.addComment(postId) : () {},
                      child: Container(
                        width: 48.w,
                        height: 48.h,
                        decoration: BoxDecoration(
                          gradient: (canSend || isCreating)
                              ? const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Color(0xFF00B8A9), Color(0xFF0A2342)],
                                )
                              : null,
                          color: (canSend || isCreating) ? null : const Color(0xFF0A2342).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: isCreating
                            ? SizedBox(
                                width: 20.sp,
                                height: 20.sp,
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                Icons.send,
                                color: canSend
                                    ? Colors.white
                                    : const Color(0xFF0A2342).withOpacity(0.4),
                                size: 20.sp,
                              ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      );
    });
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
      final postId = controller.selectedPostId.value;
      final comments = controller.postComments;
      final isLoading = controller.isLoadingComments.value;
      final error = controller.commentsError.value;
      
      if (postId == 0) return const SizedBox.shrink();

      return Material(
        color: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              // Header with gradient - Match React: bg-gradient-to-br from-[#0A2342] to-[#00B8A9]
              Container(
                padding: EdgeInsets.all(24.r), // p-6 = 24px
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0A2342), Color(0xFF00B8A9)],
                  ),
                ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isLoading 
                                ? 'Loading...' 
                                : 'Comments (${comments.length})',
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
              Expanded(
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
                                      'Loading comments...',
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
                              : comments.isEmpty
                                  ? _buildEmptyComments()
                                  : ListView.builder(
                                      padding: EdgeInsets.all(20.r),
                                      itemCount: comments.length,
                                      itemBuilder: (context, index) {
                                        return _buildCommentItem(postId, comments[index]);
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
                              controller: controller.commentTextController,
                              onChanged: (value) => controller.newComment.value = value,
                              onSubmitted: (_) async {
                                if (controller.newComment.value.trim().isNotEmpty && 
                                    postId != 0 && 
                                    !controller.isCreatingComment.value) {
                                  await controller.addComment(postId);
                                }
                              },
                              enabled: !controller.isCreatingComment.value,
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
                            final canSend = controller.newComment.value.trim().isNotEmpty && postId != 0;
                            final isCreating = controller.isCreatingComment.value;
                            return _AnimatedTapWidget(
                              onTap: (canSend && !isCreating) ? () => controller.addComment(postId) : () {},
                              child: Container(
                                width: 48.w, // w-12 = 48px
                                height: 48.h, // h-12 = 48px
                                decoration: BoxDecoration(
                                  gradient: (canSend || isCreating)
                                      ? const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [Color(0xFF00B8A9), Color(0xFF0A2342)],
                                        )
                                      : null,
                                  color: (canSend || isCreating) ? null : const Color(0xFF0A2342).withOpacity(0.1), // bg-[#0A2342]/10
                                  shape: BoxShape.circle,
                                ),
                                child: isCreating
                                    ? SizedBox(
                                        width: 20.sp,
                                        height: 20.sp,
                                        child: const CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Icon(
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
            .animate()
            .fadeIn(duration: 300.ms)
            .slideY(
              begin: 0.1,
              end: 0,
              duration: 400.ms,
              curve: Curves.easeOutCubic,
            ),
      );
    });
  }

  Widget _buildEmptyComments() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 20.h), // Reduced vertical padding
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.mode_comment_outlined, // Match React: MessageCircle
              size: 56.sp, // Slightly reduced from 64px
              color: const Color(0xFF0A2342).withOpacity(0.2), // text-[#0A2342]/20
            ),
            SizedBox(height: 12.h), // Reduced from 16.h
            Text(
              'No comments yet',
              style: ResponsiveTextStyles.textBase.copyWith(
                color: const Color(0xFF0A2342).withOpacity(0.4),
              ),
            ),
            SizedBox(height: 6.h), // Reduced from 8.h
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
          // Comment - with long press for edit/delete
          GestureDetector(
            onLongPress: () {
              // Only show actions if the comment belongs to the current user
              if (controller.isCurrentUserComment(comment)) {
                controller.showCommentActions(postId, comment);
              }
            },
            child: Obx(() {
              final isEditing = controller.editingCommentId.value == comment.id;
              
              return Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(20.r),
                  border: isEditing
                      ? Border.all(color: const Color(0xFF00B8A9), width: 2)
                      : null,
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
                        // Show indicator if user owns the comment
                        if (controller.isCurrentUserComment(comment))
                          Icon(
                            Icons.more_horiz,
                            size: 16.sp,
                            color: const Color(0xFF0A2342).withOpacity(0.4),
                          ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    // Show TextField if editing, otherwise show text
                    if (isEditing)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: controller.editCommentTextController,
                            onChanged: (value) => controller.editCommentText.value = value,
                            maxLines: 3,
                            autofocus: true,
                            enabled: !controller.isUpdatingComment.value,
                            decoration: InputDecoration(
                              hintText: 'Edit your comment...',
                              hintStyle: ResponsiveTextStyles.textSm.copyWith(
                                color: const Color(0xFF0A2342).withOpacity(0.4),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.all(12.r),
                            ),
                            style: ResponsiveTextStyles.textSm.copyWith(
                              color: const Color(0xFF0A2342).withOpacity(0.8),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: controller.isUpdatingComment.value
                                    ? null
                                    : () => controller.closeEditComment(),
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
                              Obx(() {
                                final isUpdating = controller.isUpdatingComment.value;
                                final canSave = controller.editCommentText.value.trim().isNotEmpty;
                                return ElevatedButton(
                                  onPressed: (canSave && !isUpdating)
                                      ? () => controller.updateComment()
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00B8A9),
                                    disabledBackgroundColor: const Color(0xFF00B8A9).withOpacity(0.5),
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
                                  child: isUpdating
                                      ? SizedBox(
                                          width: 16.sp,
                                          height: 16.sp,
                                          child: const CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          'Save',
                                          style: ResponsiveTextStyles.textSm.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                );
                              }),
                            ],
                          ),
                        ],
                      )
                    else
                      Text(
                        comment.text,
                        style: ResponsiveTextStyles.textSm.copyWith(
                          color: const Color(0xFF0A2342).withOpacity(0.8),
                        ),
                      ),
                  ],
                ),
              );
            }),
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
                      controller: controller.replyTextController,
                      onChanged: (value) => controller.newReply.value = value,
                      maxLines: 3,
                      enabled: !controller.isCreatingComment.value,
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
                        Obx(() {
                          final isCreating = controller.isCreatingComment.value;
                          final canSend = controller.newReply.value.trim().isNotEmpty;
                          return ElevatedButton(
                            onPressed: (canSend && !isCreating)
                                ? () => controller.addReply(postId, comment.id)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00B8A9),
                              disabledBackgroundColor: const Color(0xFF00B8A9).withOpacity(0.5),
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
                            child: isCreating
                                ? SizedBox(
                                    width: 16.sp,
                                    height: 16.sp,
                                    child: const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'Send',
                                    style: ResponsiveTextStyles.textSm.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          );
                        }),
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