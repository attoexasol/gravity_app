import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../data/model/post.dart';
import '../../../../app/theme/app_text_styles.dart';

class PinnedPostsBar extends StatelessWidget {
  final Post pinnedPost;
  final VoidCallback onScrollToPost;
  final void Function(int postId, int communityId) onUnpin;

  const PinnedPostsBar({
    super.key,
    required this.pinnedPost,
    required this.onScrollToPost,
    required this.onUnpin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A2342), Color(0xFF00B8A9)],
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Row(
        children: [
          /// LEFT SIDE – clickable area ONLY
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12.r),
              onTap: onScrollToPost,
              child: Row(
                children: [
                  Icon(Icons.push_pin, size: 18.sp, color: Colors.white),
                  SizedBox(width: 12.w),
                  Text(
                    'Pinned Posts',
                    style: ResponsiveTextStyles.textSm.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      pinnedPost.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ResponsiveTextStyles.textXs.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(width: 12.w),

          /// RIGHT SIDE – absorbs touch, never bubbles
          AbsorbPointer(
            absorbing: false, // button remains clickable
            child: ElevatedButton(
              onPressed: pinnedPost.communityId > 0
                  ? () => onUnpin(pinnedPost.id, pinnedPost.communityId)
                  : null,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                backgroundColor: Colors.white.withOpacity(0.2),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.push_pin, size: 14.sp, color: Colors.white),
                  SizedBox(width: 4.w),
                  Text(
                    'Unpin',
                    style: ResponsiveTextStyles.textXs.copyWith(
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
    );
  }
}
