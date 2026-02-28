import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../data/model/post.dart';
import '../../controllers/community_controller.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final int index;
  final GlobalKey postKey;
  final CommunityController controller;
  final VoidCallback onShowComments;

  const PostCard({
    super.key,
    required this.post,
    required this.index,
    required this.postKey,
    required this.controller,
    required this.onShowComments,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Long-press to pin/unpin post (WhatsApp-style interaction)
      onLongPress: () {
        if (post.communityId > 0) {
          controller.pinPost(post.id, post.communityId);
        } else {
          Get.snackbar(
            'Error',
            'Community ID not available',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFFE53935),
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
        }
      },
      child: Obx(() {
        final isFocused = controller.focusPostId.value == post.id.toString();
        final content = Container(
          key: postKey,
          margin: EdgeInsets.only(
            bottom: 16.h,
          ), // space-y-4 = 16px spacing between posts
          decoration: BoxDecoration(
            color: Colors.white, // bg-white
            borderRadius: BorderRadius.circular(28.r), // rounded-[28px]
            border: isFocused
                ? Border.all(color: AppColors.primary, width: 2)
                : null,
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
                              errorWidget: (context, url, error) =>
                                  Container(
                                    width: 48.w,
                                    height: 48.h,
                                    color: Colors.grey[200],
                                    child: Icon(
                                      Icons.person,
                                      size: 24.sp,
                                      color: const Color(
                                        0xFF0A2342,
                                      ).withOpacity(0.5),
                                    ),
                                  ),
                            )
                          : Icon(
                              Icons.person,
                              size: 24.sp,
                              color: const Color(
                                0xFF0A2342,
                              ).withOpacity(0.5),
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
                            color: const Color(
                              0xFF0A2342,
                            ).withOpacity(0.5), // text-[#0A2342]/50
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Pin icon (only if pinned)
                  if (post.isPinned)
                    Padding(
                      padding: EdgeInsets.only(right: 5.w),
                      child: Icon(
                        Icons.push_pin,
                        size: 18.sp,
                        color: const Color(0xFF00B8A9),
                      ),
                    ),
                  // 3-dot menu button
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      size: 20.sp,
                      color: const Color(0xFF0A2342).withOpacity(0.6),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    itemBuilder: (BuildContext context) => [
                      PopupMenuItem<String>(
                        value: post.isPinned ? 'unpin' : 'pin',
                        child: Row(
                          children: [
                            Icon(
                              Icons.push_pin,
                              size: 18.sp,
                              color: const Color(
                                0xFF0A2342,
                              ).withOpacity(0.8),
                            ),
                            SizedBox(width: 12.w),
                            Text(
                              post.isPinned
                                  ? 'Unpin The Post'
                                  : 'Pin The Post',
                              style: ResponsiveTextStyles.textSm.copyWith(
                                color: const Color(0xFF0A2342),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (String value) {
                      if (value == 'pin' || value == 'unpin') {
                        if (post.communityId > 0) {
                          controller.pinPost(post.id, post.communityId);
                        } else {
                          Get.snackbar(
                            'Error',
                            'Community ID not available',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: const Color(0xFFE53935),
                            colorText: Colors.white,
                            duration: const Duration(seconds: 2),
                          );
                        }
                      }
                    },
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
                        color: const Color(
                          0xFF0A2342,
                        ).withOpacity(0.8), // text-[#0A2342]/80
                      ),
                    ),
                  ),

                  // Reactions Bar - Match React: flex items-center justify-between pt-4 border-t border-[#0A2342]/10
                  Container(
                    padding: EdgeInsets.only(top: 16.h), // pt-4 = 16px
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: const Color(
                            0xFF0A2342,
                          ).withOpacity(0.1), // border-[#0A2342]/10
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween, // justify-between
                      crossAxisAlignment:
                          CrossAxisAlignment.center, // items-center
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
                        _buildCommentButton(
                          post.id,
                          _getTotalCommentCount(post),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
    );
    return content
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
      }),
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
                  : const Color(
                      0xFF0A2342,
                    ).withOpacity(0.6), // text-[#0A2342]/60
            ),
            SizedBox(width: 8.w), // gap-2 = 8px (match React)
            Text(
              '$count',
              style: ResponsiveTextStyles.textSm.copyWith(
                color: isActive
                    ? activeColor
                    : const Color(
                        0xFF0A2342,
                      ).withOpacity(0.6), // text-[#0A2342]/60
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      );
    });
  }

  /// Calculate total comment count including replies
  int _getTotalCommentCount(Post post) {
    // Count top-level comments
    int totalCount = post.comments.length;

    // Add count of replies for each comment
    for (final comment in post.comments) {
      totalCount += comment.replies.length;
    }

    return totalCount;
  }

  // Comment button - Match React: motion.button with MessageCircle icon
  // className="flex items-center gap-2 text-[#0A2342]/60 hover:text-[#00B8A9] transition-colors"
  // whileTap={{ scale: 0.9 }}
  Widget _buildCommentButton(int postId, int commentCount) {
    return _AnimatedTapWidget(
      onTap: onShowComments, // Opens bottom sheet modal
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons
                .mode_comment_outlined, // MessageCircle equivalent - matches React <MessageCircle className="w-5 h-5" />
            size: 20.sp, // w-5 h-5 = 20px (match React)
            color: const Color(
              0xFF0A2342,
            ).withOpacity(0.6), // text-[#0A2342]/60
          ),
          SizedBox(width: 8.w), // gap-2 = 8px (match React)
          Text(
            '$commentCount',
            style: ResponsiveTextStyles.textSm.copyWith(
              // text-sm
              color: const Color(
                0xFF0A2342,
              ).withOpacity(0.6), // text-[#0A2342]/60
            ),
          ),
        ],
      ),
    );
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

