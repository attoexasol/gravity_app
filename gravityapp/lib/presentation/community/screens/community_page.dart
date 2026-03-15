  import 'dart:io';
  import 'package:flutter/material.dart';
  import 'package:flutter_screenutil/flutter_screenutil.dart';
  import 'package:get/get.dart';
  import 'package:cached_network_image/cached_network_image.dart';
  import 'package:flutter_animate/flutter_animate.dart';
  import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
  import '../../../app/routes/app_routes.dart';
  import '../../../app/theme/app_text_styles.dart';
  import '../../../app/theme/app_colors.dart';
  import '../../notifications/controllers/notifications_controller.dart';
  import '../../widgets/notification_icon_button.dart';
  import '../controllers/community_controller.dart';
  import 'sections/comments_modal.dart';
  import 'sections/create_post_modal.dart';
  import 'sections/pinned_posts_bar.dart';
  import 'sections/post_card.dart';

  class CommunityPage extends StatefulWidget {
    const CommunityPage({super.key});

    @override
    State<CommunityPage> createState() => _CommunityPageState();
  }

  class _CommunityPageState extends State<CommunityPage> {
    final ItemScrollController _itemScrollController = ItemScrollController();

    @override
    void initState() {
      super.initState();
      // Pass scroll controller to the controller after the first frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.setScrollController(_itemScrollController);
      });
    }

    @override
    void dispose() {
      super.dispose();
    }

    // Get controller instance
    CommunityController get controller {
      if (!Get.isRegistered<CommunityController>()) {
        Get.put(CommunityController());
      }
      return Get.find<CommunityController>();
    }

    // Scroll to a specific post - positions it just below the sticky pinned posts bar
    void _scrollToPost(int postId) {
      final index = controller.posts.indexWhere((p) => p.id == postId);
      if (index == -1) return;

      _itemScrollController.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.1, // space for pinned bar
      );
    }

    @override
    Widget build(BuildContext context) {
      // Initialize controller if not already done
      if (!Get.isRegistered<CommunityController>()) {
        Get.put(CommunityController());
      }

      return Column(
        children: [
          _buildCommunityHeader(),
          Obx(() {
            final pinnedPosts =
                controller.posts.where((p) => p.isPinned).toList();

            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final slideAnimation = Tween<Offset>(
                  begin: const Offset(0, -0.3),
                  end: Offset.zero,
                ).animate(animation);

                return SlideTransition(
                  position: slideAnimation,
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
              child: pinnedPosts.isEmpty
                  ? const SizedBox.shrink(key: ValueKey('empty'))
                  : PinnedPostsBar(
                      key: ValueKey(pinnedPosts.first.id),
                      pinnedPost: pinnedPosts.first,
                      onScrollToPost: () =>
                          _scrollToPost(pinnedPosts.first.id),
                      onUnpin: (postId, communityId) {
                        controller.pinPost(postId, communityId);
                      },
                    ),
            );
          }),
          Expanded(
            child: Stack(
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
              if (controller.postsError.value.isNotEmpty &&
                  controller.posts.isEmpty) {
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
              return ScrollablePositionedList.builder(
                itemScrollController: _itemScrollController,
                padding: EdgeInsets.only(
                  left: 24.w, // px-6 = 24px
                  right: 24.w, // px-6 = 24px
                  top: 16.h,
                  bottom: 100.h, // Prevent overflow with bottom nav
                ),
                itemCount: controller.posts.length,
                itemBuilder: (context, index) {
                  final post = controller.posts[index];
                  return PostCard(
                    post: post,
                    index: index,
                    postKey: GlobalKey(),
                    controller: controller,
                    onShowComments: () => _showCommentsModal(post.id),
                  );
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
          Obx(
            () => controller.showEditPost.value
                ? _buildEditPostModal()
                : const SizedBox.shrink(),
          ),
        ],
      ),
    ),
        ],
      );
    }

    Widget _buildCommunityHeader() {
      return Container(
        width: double.infinity,
        // padding: EdgeInsets.fromLTRB(24.w, 60.h, 24.w, 32.h),
        padding: EdgeInsets.fromLTRB(24.w, 38.h, 24.w, 18.h),

        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A2342),
              Color(0xFF00B8A9),
            ],
          ),
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(40.r),
          ),
          // borderRadius: BorderRadius.vertical(
          //   bottom: Radius.circular(26.r),
          // ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Community",
                  style: ResponsiveTextStyles.textXl.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  "Share your wellness journey",
                  style: ResponsiveTextStyles.textSm.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Obx(() {
                  final count = Get.isRegistered<NotificationsController>()
                      ? Get.find<NotificationsController>().unreadCount.value
                      : 0;
                  return NotificationIconButton(
                    unreadCount: count,
                    onTap: () => Get.toNamed(AppRoutes.notifications),
                    size: 44,
                    iconSize: 22,
                    icon: Icons.notifications_none,
                  );
                }),
                SizedBox(width: 12.w),
                _buildHeaderIcon(Icons.settings_outlined),
              ],
            ),
          ],
        ),
      );
    }

    /// Settings icon in header — matches MainAppBar style (same size, radius, shadow).
    Widget _buildHeaderIcon(IconData icon) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Get.toNamed(AppRoutes.settings),
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            width: 44.w,
            height: 44.h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8.r,
                  offset: Offset(0, 2.h),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22.sp),
          ),
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
        CommunityCommentsSection.buildCommentsBottomSheet(controller),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withOpacity(0.5),
        isDismissible: true,
        enableDrag: true,
      ).whenComplete(() => controller.closeComments());
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
                child: Container(color: Colors.black.withOpacity(0.5)),
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
                              child: Obx(
                                () => _buildUserAvatar(
                                  imageUrl: controller.currentUserProfileImage,
                                  size: 48,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w), // gap-3 = 12px
                          // User Info Text
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // User name - Match React: text-[#0A2342]
                              Obx(
                                () => Text(
                                  controller.currentUserName,
                                  style: ResponsiveTextStyles.textBase.copyWith(
                                    color: const Color(0xFF0A2342),
                                  ),
                                ),
                              ),
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
                            TextField(
                              controller: controller.editPostTextController,
                              onChanged: (value) =>
                                  controller.editPostText.value = value,
                              maxLines: 5,
                              autofocus: true,
                              style: ResponsiveTextStyles.textBase.copyWith(
                                color: const Color(0xFF0A2342), // Dark text color
                              ),
                              cursorColor: const Color(0xFF0A2342), // Dark cursor
                              decoration: InputDecoration(
                                hintText: 'Edit your post...',
                                hintStyle: ResponsiveTextStyles.textBase
                                    .copyWith(
                                      color: const Color(
                                        0xFF0A2342,
                                      ).withOpacity(0.4),
                                    ),
                                border: InputBorder.none,
                              ),
                            ),

                            // Current Image Preview
                            Obx(
                              () => controller.editPostImage.value.isNotEmpty
                                  ? Container(
                                      margin: EdgeInsets.only(top: 16.h),
                                      child: Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              20.r,
                                            ),
                                            child:
                                                controller
                                                    .editPostImagePath
                                                    .value
                                                    .isNotEmpty
                                                // Local file image (newly picked)
                                                ? Image.file(
                                                    File(
                                                      controller
                                                          .editPostImagePath
                                                          .value,
                                                    ),
                                                    height: 200.h,
                                                    width: double.infinity,
                                                    fit: BoxFit.cover,
                                                  )
                                                // Network image (existing image or URL)
                                                : CachedNetworkImage(
                                                    imageUrl: controller
                                                        .editPostImage
                                                        .value,
                                                    height: 200.h,
                                                    width: double.infinity,
                                                    fit: BoxFit.cover,
                                                    placeholder: (context, url) =>
                                                        Container(
                                                          height: 200.h,
                                                          color: AppColors.muted,
                                                          child: const Center(
                                                            child:
                                                                CircularProgressIndicator(
                                                                  color: Color(
                                                                    0xFF00B8A9,
                                                                  ),
                                                                ),
                                                          ),
                                                        ),
                                                    errorWidget:
                                                        (
                                                          context,
                                                          url,
                                                          error,
                                                        ) => Container(
                                                          height: 200.h,
                                                          color: AppColors.muted,
                                                          child: const Icon(
                                                            Icons
                                                                .image_not_supported,
                                                          ),
                                                        ),
                                                  ),
                                          ),
                                          Positioned(
                                            top: 12.h,
                                            right: 12.w,
                                            child: _AnimatedTapWidget(
                                              onTap: () => controller
                                                  .clearEditSelectedImage(),
                                              child: Container(
                                                width: 32.w,
                                                height: 32.h,
                                                decoration: BoxDecoration(
                                                  color: Colors.black.withOpacity(
                                                    0.5,
                                                  ),
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
                                  : const SizedBox.shrink(),
                            ),

                            // Image Upload Section (for adding new image)
                            Obx(
                              () => controller.editPostImage.value.isEmpty
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                              style: ResponsiveTextStyles.textSm
                                                  .copyWith(
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
                                          () => _AnimatedTapWidget(
                                            onTap: controller.isPickingImage.value
                                                ? () {}
                                                : () => controller
                                                      .showImageSourcePickerForEdit(),
                                            child: Container(
                                              width: double.infinity,
                                              padding: EdgeInsets.symmetric(
                                                vertical: 20.h,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(
                                                  0xFF00B8A9,
                                                ).withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(16.r),
                                                border: Border.all(
                                                  color: const Color(
                                                    0xFF00B8A9,
                                                  ).withOpacity(0.3),
                                                  width: 2,
                                                  style: BorderStyle.solid,
                                                ),
                                              ),
                                              child:
                                                  controller.isPickingImage.value
                                                  ? Center(
                                                      child: SizedBox(
                                                        width: 24.w,
                                                        height: 24.h,
                                                        child:
                                                            const CircularProgressIndicator(
                                                              color: Color(
                                                                0xFF00B8A9,
                                                              ),
                                                              strokeWidth: 2,
                                                            ),
                                                      ),
                                                    )
                                                  : Column(
                                                      children: [
                                                        Icon(
                                                          Icons
                                                              .cloud_upload_outlined,
                                                          size: 32.sp,
                                                          color: const Color(
                                                            0xFF00B8A9,
                                                          ),
                                                        ),
                                                        SizedBox(height: 8.h),
                                                        Text(
                                                          'Upload from Device',
                                                          style: ResponsiveTextStyles
                                                              .textSm
                                                              .copyWith(
                                                                color:
                                                                    const Color(
                                                                      0xFF00B8A9,
                                                                    ),
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                        ),
                                                        SizedBox(height: 4.h),
                                                        Text(
                                                          'Tap to select from gallery or camera',
                                                          style: ResponsiveTextStyles
                                                              .textXs
                                                              .copyWith(
                                                                color:
                                                                    const Color(
                                                                      0xFF0A2342,
                                                                    ).withOpacity(
                                                                      0.5,
                                                                    ),
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
                        final canUpdate = controller.editPostText.value
                            .trim()
                            .isNotEmpty;
                        final isUpdating = controller.isUpdatingPost.value;

                        return _AnimatedTapWidget(
                          onTap: (canUpdate && !isUpdating)
                              ? () async {
                                  await controller.updatePost();
                                }
                              : () {},
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            decoration: BoxDecoration(
                              gradient: (canUpdate && !isUpdating)
                                  ? const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF00B8A9),
                                        Color(0xFF0A2342),
                                      ],
                                    )
                                  : null,
                              color: (canUpdate && !isUpdating)
                                  ? null
                                  : const Color(0xFF0A2342).withOpacity(0.1),
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
                                        : const Color(
                                            0xFF0A2342,
                                          ).withOpacity(0.4),
                                  ),
                                SizedBox(width: 8.w),
                                Text(
                                  isUpdating ? 'Updating...' : 'Update Post',
                                  style: ResponsiveTextStyles.textBase.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: (canUpdate || isUpdating)
                                        ? Colors.white
                                        : const Color(
                                            0xFF0A2342,
                                          ).withOpacity(0.4),
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
              ).animate().slideY(begin: 1.0, end: 0.0, duration: 400.ms, curve: Curves.easeOutCubic),
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
          child: Icon(Icons.person, size: (size / 2).sp, color: Colors.grey[400]),
        );
      }

      // Check if it's a local file path (starts with / or contains file path pattern)
      final isLocalFile =
          imageUrl.startsWith('/') ||
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
            errorBuilder: (context, error, stackTrace) =>
                Icon(Icons.person, size: (size / 2).sp, color: Colors.grey[400]),
          );
        } else {
          return Icon(Icons.person, size: (size / 2).sp, color: Colors.grey[400]);
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
          errorWidget: (context, url, error) =>
              Icon(Icons.person, size: (size / 2).sp, color: Colors.grey[400]),
        );
      }
    }
  }

  // Helper widget to provide tap animation matching React's motion.button whileTap={{ scale: 0.9 }}
  class _AnimatedTapWidget extends StatefulWidget {
    final Widget child;
    final VoidCallback onTap;

    const _AnimatedTapWidget({required this.child, required this.onTap});

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
      _scaleAnimation = Tween<double>(
        begin: 1.0,
        end: 0.9,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
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
        child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
      );
    }
  }
