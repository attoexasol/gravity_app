import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../data/model/comment.dart';
import '../../../../data/model/reply.dart';
import '../../controllers/community_controller.dart';
import 'post_card.dart';

/// Comment-related UI widgets. All logic is delegated to [CommunityController].
class CommunityCommentsSection {
  CommunityCommentsSection._();

  static Widget buildCommentsBottomSheet(CommunityController controller) {
    return Builder(
      builder: (BuildContext bottomSheetContext) {
        return Obx(() {
          final postId = controller.selectedPostId.value;
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
                // Header with gradient — only title/count reactive
                Container(
                  padding: EdgeInsets.all(24.r),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0A2342), Color(0xFF00B8A9)],
                    ),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(40.r),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Obx(() {
                        final isLoading =
                            controller.isLoadingComments.value;
                        final totalCount =
                            controller.currentPostCommentsTotalFromList;
                        return Text(
                          isLoading
                              ? 'Loading...'
                              : 'Comments ($totalCount)',
                          style: ResponsiveTextStyles.textXl.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }),
                      _AnimatedTapWidget(
                        onTap: () {
                          controller.closeComments();
                          Navigator.of(bottomSheetContext).pop();
                        },
                        child: Container(
                          // width: 40.w,
                          // height: 40.h,
                          padding: EdgeInsets.all(8.r),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            // shape: BoxShape.circle,
                            borderRadius: BorderRadius.circular(10.r),
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

                // Comments list with loading state — scoped Obx
                Flexible(
                  child: Obx(() {
                    final comments = controller.postComments;
                    final isLoading =
                        controller.isLoadingComments.value;
                    final error = controller.commentsError.value;
                    if (isLoading) {
                      return Center(
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
                                style: ResponsiveTextStyles.textSm
                                    .copyWith(
                                      color: const Color(0xFF0A2342)
                                          .withOpacity(0.6),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    if (error.isNotEmpty) {
                      return Center(
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
                                style: ResponsiveTextStyles.textSm
                                    .copyWith(
                                      color: const Color(0xFF0A2342)
                                          .withOpacity(0.6),
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    if (comments.isEmpty) {
                      return buildEmptyComments();
                    }
                    return ListView.builder(
                      padding: EdgeInsets.all(20.r),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        return buildCommentItem(
                          controller,
                          controller.selectedPostId.value,
                          comments[index],
                        );
                      },
                    );
                  }),
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
                      Obx(() => UserAvatar(
                            avatarUrl: controller.currentUserProfileImage,
                            name: controller.currentUserName,
                            size: 40.r,
                          )),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: TextField(
                          controller: controller.commentTextController,
                          onChanged: (value) =>
                              controller.newComment.value = value,
                          onSubmitted: (_) async {
                            if (controller.newComment.value.trim().isNotEmpty &&
                                postId != 0 &&
                                !controller.isCreatingComment.value) {
                              await controller.addComment(postId);
                            }
                          },
                          enabled: !controller.isCreatingComment.value,
                          style: ResponsiveTextStyles.textSm.copyWith(
                            color: const Color(0xFF0A2342), // Dark text color
                          ),
                          cursorColor: const Color(0xFF0A2342), // Dark cursor
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
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Obx(() {
                        final canSend =
                            controller.newComment.value.trim().isNotEmpty &&
                                postId != 0;
                        final isCreating = controller.isCreatingComment.value;
                        return _AnimatedTapWidget(
                          onTap: (canSend && !isCreating)
                              ? () => controller.addComment(postId)
                              : () {},
                          child: Container(
                            width: 48.w,
                            height: 48.h,
                            decoration: BoxDecoration(
                              gradient: (canSend || isCreating)
                                  ? const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF00B8A9),
                                        Color(0xFF0A2342),
                                      ],
                                    )
                                  : null,
                              color: (canSend || isCreating)
                                  ? null
                                  : const Color(0xFF0A2342).withOpacity(0.1),
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
                                        : const Color(0xFF0A2342)
                                            .withOpacity(0.4),
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
      },
    );
  }

  static Widget buildCommentsModal(CommunityController controller) {
    return Obx(() {
      final postId = controller.selectedPostId.value;
      if (postId == 0) return const SizedBox.shrink();

      return Material(
        color: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              // Header with gradient - only title/count reactive
              Container(
                padding: EdgeInsets.all(24.r),
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
                    Obx(() {
                      final isLoading =
                          controller.isLoadingComments.value;
                      final totalCount =
                          controller.currentPostCommentsTotalFromList;
                      return Text(
                        isLoading
                            ? 'Loading...'
                            : 'Comments ($totalCount)',
                        style: ResponsiveTextStyles.textXl.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }),
                    _AnimatedTapWidget(
                      onTap: controller.closeComments,
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

              // Comments list with loading state — scoped Obx
              Expanded(
                child: Obx(() {
                  final comments = controller.postComments;
                  final isLoading =
                      controller.isLoadingComments.value;
                  final error = controller.commentsError.value;
                  if (isLoading) {
                    return Center(
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
                    );
                  }
                  if (error.isNotEmpty) {
                    return Center(
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
                    );
                  }
                  if (comments.isEmpty) {
                    return buildEmptyComments();
                  }
                  return ListView.builder(
                    padding: EdgeInsets.all(20.r),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      return buildCommentItem(
                        controller,
                        controller.selectedPostId.value,
                        comments[index],
                      );
                    },
                  );
                }),
              ),

              // Add comment input - Match React: p-6 border-t border-[#0A2342]/10 bg-white
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
                    Obx(() {
                      final profileImage =
                          controller.currentUserProfileImage;
                      ImageProvider? imageProvider;

                      if (profileImage.isNotEmpty) {
                        if (profileImage.startsWith('/') ||
                            profileImage.contains('\\') ||
                            profileImage.startsWith('file://')) {
                          try {
                            final file = File(
                              profileImage.replaceFirst('file://', ''),
                            );
                            if (file.existsSync()) {
                              imageProvider = FileImage(file);
                            }
                          } catch (e) {
                            // Ignore file errors
                          }
                        } else {
                          imageProvider =
                              CachedNetworkImageProvider(profileImage);
                        }
                      }

                      return CircleAvatar(
                        radius: 20.r,
                        backgroundImage: imageProvider,
                        backgroundColor: AppColors.muted,
                        child: imageProvider == null
                            ? Icon(
                                Icons.person,
                                size: 20.sp,
                                color: const Color(0xFF0A2342).withOpacity(0.5),
                              )
                            : null,
                      );
                    }),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: TextField(
                        controller: controller.commentTextController,
                        onChanged: (value) =>
                            controller.newComment.value = value,
                        onSubmitted: (_) async {
                          if (controller.newComment.value
                                  .trim()
                                  .isNotEmpty &&
                              postId != 0 &&
                              !controller.isCreatingComment.value) {
                            await controller.addComment(postId);
                          }
                        },
                        enabled: !controller.isCreatingComment.value,
                        style: ResponsiveTextStyles.textSm.copyWith(
                          color: const Color(0xFF0A2342),
                        ),
                        cursorColor: const Color(0xFF0A2342),
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
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Obx(() {
                      final canSend =
                          controller.newComment.value.trim().isNotEmpty &&
                              postId != 0;
                      final isCreating =
                          controller.isCreatingComment.value;
                      return _AnimatedTapWidget(
                        onTap: (canSend && !isCreating)
                            ? () => controller.addComment(postId)
                            : () {},
                        child: Container(
                          width: 48.w,
                          height: 48.h,
                          decoration: BoxDecoration(
                            gradient: (canSend || isCreating)
                                ? const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF00B8A9),
                                      Color(0xFF0A2342),
                                    ],
                                  )
                                : null,
                            color: (canSend || isCreating)
                                ? null
                                : const Color(0xFF0A2342).withOpacity(0.1),
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
        ).animate().fadeIn(duration: 300.ms).slideY(
              begin: 0.1,
              end: 0,
              duration: 400.ms,
              curve: Curves.easeOutCubic,
            ),
      );
    });
  }

  static Widget buildEmptyComments() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 40.w,
          vertical: 20.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.mode_comment_outlined,
              size: 56.sp,
              color: const Color(0xFF0A2342).withOpacity(0.2),
            ),
            SizedBox(height: 12.h),
            Text(
              'No comments yet',
              style: ResponsiveTextStyles.textBase.copyWith(
                color: const Color(0xFF0A2342).withOpacity(0.4),
              ),
            ),
            SizedBox(height: 6.h),
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

  static Widget buildCommentItem(
    CommunityController controller,
    int postId,
    Comment comment,
  ) {
    final userName = comment.user.name.isNotEmpty
        ? comment.user.name
        : 'Unknown User';
    final avatarUrl = comment.user.avatar;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onLongPress: () {
              if (controller.isCurrentUserComment(comment)) {
                controller.showCommentActions(postId, comment);
              }
            },
            child: Obx(() {
              final isEditing =
                  controller.editingCommentId.value == comment.id;

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
                        UserAvatar(
                          avatarUrl: avatarUrl,
                          name: userName,
                          size: 32.r,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
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
                        if (controller.isCurrentUserComment(comment))
                          Icon(
                            Icons.more_horiz,
                            size: 16.sp,
                            color: const Color(0xFF0A2342).withOpacity(0.4),
                          ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    if (isEditing)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: controller.editCommentTextController,
                            onChanged: (value) =>
                                controller.editCommentText.value = value,
                            maxLines: 3,
                            autofocus: true,
                            enabled: !controller.isUpdatingComment.value,
                            style: ResponsiveTextStyles.textSm.copyWith(
                              color: const Color(0xFF0A2342),
                            ),
                            cursorColor: const Color(0xFF0A2342),
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
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Cancel',
                                  style: ResponsiveTextStyles.textSm.copyWith(
                                    color: const Color(0xFF0A2342)
                                        .withOpacity(0.6),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Obx(() {
                                final isUpdating =
                                    controller.isUpdatingComment.value;
                                final canSave = controller
                                    .editCommentText.value
                                    .trim()
                                    .isNotEmpty;
                                return ElevatedButton(
                                  onPressed: (canSave && !isUpdating)
                                      ? () => controller.updateComment()
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00B8A9),
                                    disabledBackgroundColor: const Color(
                                      0xFF00B8A9,
                                    ).withOpacity(0.5),
                                    minimumSize: Size.zero,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16.w,
                                      vertical: 8.h,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
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
                                          style: ResponsiveTextStyles.textSm
                                              .copyWith(
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
                    .map((reply) =>
                        buildReplyItem(controller, postId, comment, reply))
                    .toList(),
              ),
            ),

          // Reply input
          Obx(() {
            final isReplying =
                controller.replyingToPostId.value == postId &&
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
                        UserAvatar(
                          avatarUrl: controller.currentUserProfileImage,
                          name: controller.currentUserName,
                          size: 24.r,
                        ),
                        SizedBox(width: 8.w),
                        Flexible(
                          child: Text(
                            'Replying to $userName',
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
                      autofocus: true,
                      enabled: !controller.isCreatingReply.value,
                      style: ResponsiveTextStyles.textSm.copyWith(
                        color: const Color(0xFF0A2342),
                      ),
                      cursorColor: const Color(0xFF0A2342),
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
                          final isCreating =
                              controller.isCreatingReply.value;
                          final canSend = controller.newReply.value
                              .trim()
                              .isNotEmpty;
                          return ElevatedButton(
                            onPressed: (canSend && !isCreating)
                                ? () => controller.addReply(postId, comment.id)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00B8A9),
                              disabledBackgroundColor: const Color(0xFF00B8A9)
                                  .withOpacity(0.5),
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
                                    style: ResponsiveTextStyles.textSm
                                        .copyWith(
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

  static Widget buildReplyItem(
    CommunityController controller,
    int postId,
    Comment parentComment,
    Reply reply,
  ) {
    final replyUserName = reply.user.name.isNotEmpty
        ? reply.user.name
        : 'Unknown User';
    final replyAvatarUrl = reply.user.avatar;

    return GestureDetector(
      onLongPress: () {
        if (controller.isCurrentUserReply(reply)) {
          controller.showReplyActions(postId, parentComment, reply);
        }
      },
      child: Obx(() {
        final isEditingReply =
            controller.editingCommentId.value == reply.id &&
                controller.editingReplyParentCommentId.value ==
                    parentComment.id;
        return Container(
          margin: EdgeInsets.only(bottom: 8.h),
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: AppColors.inputBackground,
            borderRadius: BorderRadius.circular(16.r),
            border: isEditingReply
                ? Border.all(color: const Color(0xFF00B8A9), width: 2)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  UserAvatar(
                    avatarUrl: replyAvatarUrl,
                    name: replyUserName,
                    size: 24.r,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          replyUserName,
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
                  if (controller.isCurrentUserReply(reply))
                    Icon(
                      Icons.more_horiz,
                      size: 14.sp,
                      color: const Color(0xFF0A2342).withOpacity(0.4),
                    ),
                ],
              ),
              SizedBox(height: 6.h),
              if (isEditingReply)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: controller.editCommentTextController,
                      onChanged: (value) =>
                          controller.editCommentText.value = value,
                      maxLines: 3,
                      autofocus: true,
                      enabled: !controller.isUpdatingComment.value,
                      style: ResponsiveTextStyles.textXs.copyWith(
                        color: const Color(0xFF0A2342),
                      ),
                      cursorColor: const Color(0xFF0A2342),
                      decoration: InputDecoration(
                        hintText: 'Edit your reply...',
                        hintStyle: ResponsiveTextStyles.textXs.copyWith(
                          color: const Color(0xFF0A2342).withOpacity(0.4),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.all(10.r),
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
                              horizontal: 10.w,
                              vertical: 6.h,
                            ),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Cancel',
                            style: ResponsiveTextStyles.textXs.copyWith(
                              color: const Color(0xFF0A2342).withOpacity(0.6),
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Obx(() {
                          final isUpdating =
                              controller.isUpdatingComment.value;
                          final canSave = controller.editCommentText.value
                              .trim()
                              .isNotEmpty;
                          return ElevatedButton(
                            onPressed: (canSave && !isUpdating)
                                ? () => controller.updateComment()
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00B8A9),
                              disabledBackgroundColor: const Color(0xFF00B8A9)
                                  .withOpacity(0.5),
                              minimumSize: Size.zero,
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 6.h,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: isUpdating
                                ? SizedBox(
                                    width: 14.sp,
                                    height: 14.sp,
                                    child: const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'Save',
                                    style: ResponsiveTextStyles.textXs
                                        .copyWith(
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
                  reply.text,
                  style: ResponsiveTextStyles.textXs.copyWith(
                    color: const Color(0xFF0A2342).withOpacity(0.8),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

/// Tap animation widget used only within the comments section.
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
    ).animate(CurvedAnimation(
        parent: _controller, curve: Curves.easeInOut));
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
