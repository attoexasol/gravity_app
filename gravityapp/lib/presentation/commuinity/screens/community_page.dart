import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
        // Main feed - No padding at top (MainAppBar handles it)
        Obx(() => ListView.builder(
          padding: EdgeInsets.only(
            left: 20.w,
            right: 20.w,
            top: 20.h,
            bottom: 100.h, // Prevent overflow with bottom nav
          ),
          itemCount: controller.posts.length,
          itemBuilder: (context, index) {
            return _buildPostCard(controller.posts[index], index);
          },
        )),

        // Floating Action Button - Create Post
        Positioned(
          bottom: 90.h,
          right: 20.w,
          child: FloatingActionButton(
            onPressed: () => controller.showCreatePost.value = true,
            backgroundColor: const Color(0xFF00B8A9),
            elevation: 8,
            child: Icon(Icons.add, size: 28.sp, color: Colors.white),
          ),
        ),

        // Create Post Modal
        Obx(() => controller.showCreatePost.value
            ? _buildCreatePostModal()
            : const SizedBox.shrink()),

        // Comments Modal
        Obx(() => controller.selectedPostId.value != 0
            ? _buildCommentsModal()
            : const SizedBox.shrink()),
      ],
    );
  }

  Widget _buildPostCard(Post post, int index) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User header
          Padding(
            padding: EdgeInsets.all(20.r),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24.r,
                  backgroundImage: CachedNetworkImageProvider(post.user.avatar),
                  backgroundColor: AppColors.muted,
                ),
                SizedBox(width: 12.w),
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
              ],
            ),
          ),

          // Post image
          if (post.image.isNotEmpty)
            CachedNetworkImage(
              imageUrl: post.image,
              height: 250.h,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 250.h,
                color: AppColors.muted,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF00B8A9),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                height: 250.h,
                color: AppColors.muted,
                child: Icon(Icons.image_not_supported, size: 48.sp),
              ),
            ),

          // Post text
          Padding(
            padding: EdgeInsets.all(20.r),
            child: Text(
              post.text,
              style: ResponsiveTextStyles.textBase.copyWith(
                color: const Color(0xFF0A2342).withOpacity(0.8),
              ),
            ),
          ),

          // Reactions bar
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: const Color(0xFF0A2342).withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildReactionButton(
                        post.id,
                        'heart',
                        Icons.favorite,
                        post.reactions.heart,
                        Colors.red,
                      ),
                      SizedBox(width: 16.w),
                      _buildReactionButton(
                        post.id,
                        'thumbsUp',
                        Icons.thumb_up,
                        post.reactions.thumbsUp,
                        Colors.blue,
                      ),
                      SizedBox(width: 16.w),
                      _buildReactionButton(
                        post.id,
                        'fire',
                        Icons.local_fire_department,
                        post.reactions.fire,
                        Colors.orange,
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => controller.openComments(post.id),
                    borderRadius: BorderRadius.circular(8.r),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      child: Row(
                        children: [
                          Icon(
                            Icons.comment_outlined,
                            size: 20.sp,
                            color: const Color(0xFF0A2342).withOpacity(0.6),
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            '${post.comments.length}',
                            style: ResponsiveTextStyles.textSm.copyWith(
                              color: const Color(0xFF0A2342).withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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

      return InkWell(
        onTap: () => controller.toggleReaction(postId, reaction),
        borderRadius: BorderRadius.circular(8.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20.sp,
                color: isActive
                    ? activeColor
                    : const Color(0xFF0A2342).withOpacity(0.6),
              ),
              SizedBox(width: 6.w),
              Text(
                '$count',
                style: ResponsiveTextStyles.textSm.copyWith(
                  color: isActive
                      ? activeColor
                      : const Color(0xFF0A2342).withOpacity(0.6),
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildCreatePostModal() {
    return Material(
      color: Colors.black.withOpacity(0.5),
      child: SafeArea(
        child: Stack(
          children: [
            // Backdrop - dismiss on tap
            GestureDetector(
              onTap: () {
                controller.showCreatePost.value = false;
                controller.newPostText.value = '';
                controller.selectedImage.value = '';
              },
              child: Container(color: Colors.transparent),
            ),

            // Modal content
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                constraints: BoxConstraints(maxHeight: 0.9.sh),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Padding(
                      padding: EdgeInsets.all(20.r),
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
                          IconButton(
                            onPressed: () {
                              controller.showCreatePost.value = false;
                              controller.newPostText.value = '';
                              controller.selectedImage.value = '';
                            },
                            icon: Icon(Icons.close, size: 24.sp),
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(
                              minWidth: 40.w,
                              minHeight: 40.h,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Divider(height: 1.h, color: const Color(0xFF0A2342).withOpacity(0.1)),

                    // User info
                    Padding(
                      padding: EdgeInsets.all(20.r),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24.r,
                            backgroundImage: const CachedNetworkImageProvider(
                              'https://i.pravatar.cc/150?img=1',
                            ),
                            backgroundColor: AppColors.muted,
                          ),
                          SizedBox(width: 12.w),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'You',
                                style: ResponsiveTextStyles.textBase.copyWith(
                                  color: const Color(0xFF0A2342),
                                  fontWeight: FontWeight.w600,
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
                    ),

                    // Content area
                    Flexible(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: Column(
                          children: [
                            // Text input
                            TextField(
                              onChanged: (value) => controller.newPostText.value = value,
                              maxLines: 5,
                              decoration: InputDecoration(
                                hintText: 'Share your wellness journey...',
                                hintStyle: ResponsiveTextStyles.textBase.copyWith(
                                  color: const Color(0xFF0A2342).withOpacity(0.4),
                                ),
                                border: InputBorder.none,
                              ),
                              style: ResponsiveTextStyles.textBase,
                            ),

                            // Selected image preview
                            Obx(() => controller.selectedImage.value.isNotEmpty
                                ? Container(
                              margin: EdgeInsets.symmetric(vertical: 12.h),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(20.r),
                                    child: CachedNetworkImage(
                                      imageUrl: controller.selectedImage.value,
                                      height: 200.h,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 8.h,
                                    right: 8.w,
                                    child: InkWell(
                                      onTap: () => controller.selectedImage.value = '',
                                      child: Container(
                                        padding: EdgeInsets.all(6.r),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.5),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 18.sp,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                                : const SizedBox.shrink()),

                            // Image gallery
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
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 8.w,
                                    mainAxisSpacing: 8.h,
                                  ),
                                  itemCount: controller.sampleImages.length,
                                  itemBuilder: (context, index) {
                                    return InkWell(
                                      onTap: () => controller.selectedImage.value =
                                      controller.sampleImages[index],
                                      borderRadius: BorderRadius.circular(16.r),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16.r),
                                        child: CachedNetworkImage(
                                          imageUrl: controller.sampleImages[index],
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Container(
                                            color: AppColors.muted,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            )
                                : const SizedBox.shrink()),

                            SizedBox(height: 20.h),
                          ],
                        ),
                      ),
                    ),

                    // Post button
                    Container(
                      padding: EdgeInsets.all(20.r),
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
                        return SizedBox(
                          width: double.infinity,
                          height: 50.h,
                          child: ElevatedButton(
                            onPressed: canPost ? controller.createPost : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00B8A9),
                              disabledBackgroundColor:
                              const Color(0xFF0A2342).withOpacity(0.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.send, size: 20.sp, color: Colors.white),
                                SizedBox(width: 8.w),
                                Text(
                                  'Share Post',
                                  style: ResponsiveTextStyles.textBase.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsModal() {
    final post = controller.selectedPost;
    if (post == null) return const SizedBox.shrink();

    return Material(
      color: Colors.black.withOpacity(0.5),
      child: SafeArea(
        child: Stack(
          children: [
            // Backdrop
            GestureDetector(
              onTap: controller.closeComments,
              child: Container(color: Colors.transparent),
            ),

            // Modal content
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                constraints: BoxConstraints(maxHeight: 0.85.sh),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with gradient
                    Container(
                      padding: EdgeInsets.all(20.r),
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
                            'Comments (${post.comments.length})',
                            style: ResponsiveTextStyles.textXl.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: controller.closeComments,
                            icon: Container(
                              padding: EdgeInsets.all(6.r),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.close, color: Colors.white, size: 20.sp),
                            ),
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(
                              minWidth: 40.w,
                              minHeight: 40.h,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Comments list
                    Flexible(
                      child: post.comments.isEmpty
                          ? _buildEmptyComments()
                          : ListView.builder(
                        padding: EdgeInsets.all(20.r),
                        itemCount: post.comments.length,
                        itemBuilder: (context, index) {
                          return _buildCommentItem(post.id, post.comments[index]);
                        },
                      ),
                    ),

                    // Add comment input
                    Container(
                      color: Colors.white,
                      padding: EdgeInsets.all(20.r),
                      decoration: BoxDecoration(
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
                              onChanged: (value) => controller.newComment.value = value,
                              onSubmitted: (_) {
                                if (controller.newComment.value.trim().isNotEmpty) {
                                  controller.addComment(post.id);
                                }
                              },
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
                              ),
                              style: ResponsiveTextStyles.textSm,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Obx(() {
                            final canSend = controller.newComment.value.trim().isNotEmpty;
                            return IconButton(
                              onPressed: canSend ? () => controller.addComment(post.id) : null,
                              icon: Container(
                                padding: EdgeInsets.all(8.r),
                                decoration: BoxDecoration(
                                  gradient: canSend
                                      ? const LinearGradient(
                                    colors: [Color(0xFF00B8A9), Color(0xFF0A2342)],
                                  )
                                      : null,
                                  color: canSend ? null : Colors.grey.shade300,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.send,
                                  color: Colors.white,
                                  size: 20.sp,
                                ),
                              ),
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(
                                minWidth: 40.w,
                                minHeight: 40.h,
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyComments() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.comment_outlined,
              size: 64.sp,
              color: const Color(0xFF0A2342).withOpacity(0.2),
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
}