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
        // Detect and extract nutrition from post.text (display-only; data unchanged)
        String displayText = post.text;
        Map<String, String>? nutrition;
        if (post.text.contains('Calories:')) {
          nutrition = _extractNutritionFromText(post.text);
          if (nutrition != null && nutrition.isNotEmpty) {
            displayText = _stripNutritionLinesFromText(post.text);
          } else {
            nutrition = null;
          }
        }
        // Split display text into Title, Health Score, AI Insight (for reorder)
        final parsed = _parseTitleHealthAndInsight(displayText);
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
                  // Avatar: network image or letter fallback when no profile image
                  UserAvatar(
                    avatarUrl: post.user.avatar,
                    name: post.user.name,
                    size: 48.r,
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
                  // Expandable body: preview + "See More" when long, full content when expanded
                  _ExpandablePostContent(
                    title: parsed.title,
                    healthScore: parsed.healthScore,
                    aiInsight: parsed.aiInsight,
                    nutritionWidget: nutrition != null && nutrition.isNotEmpty
                        ? _buildNutritionSection(nutrition!)
                        : null,
                    titleStyle: ResponsiveTextStyles.textBase.copyWith(
                      color: const Color(0xFF0A2342).withOpacity(0.8),
                    ),
                    healthScoreStyle: _healthScoreStyle,
                    aiInsightStyle: ResponsiveTextStyles.textBase.copyWith(
                      color: const Color(0xFF0A2342).withOpacity(0.8),
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

  static final RegExp _reCalories = RegExp(r'Calories:\s*([\d.]+)\s*kcal', caseSensitive: false);
  static final RegExp _reProtein = RegExp(r'Protein:\s*([\d.]+)\s*g', caseSensitive: false);
  static final RegExp _reCarbs = RegExp(r'Carbs:\s*([\d.]+)\s*g', caseSensitive: false);
  static final RegExp _reFat = RegExp(r'Fat:\s*([\d.]+)\s*g', caseSensitive: false);
  static final RegExp _reFiber = RegExp(r'Fiber:\s*([\d.]+)\s*g', caseSensitive: false);
  static final RegExp _reSodium = RegExp(r'Sodium:\s*([\d.]+)\s*mg', caseSensitive: false);

  /// Extract nutrition key-value pairs from text. Returns null if none found.
  Map<String, String>? _extractNutritionFromText(String text) {
    if (text.isEmpty) return null;
    final map = <String, String>{};
    void add(String key, RegExp re, String suffix) {
      final m = re.firstMatch(text);
      if (m != null && m.group(1) != null) map[key] = '${m.group(1)!}$suffix';
    }
    add('calories', _reCalories, ' kcal');
    add('protein', _reProtein, 'g');
    add('carbs', _reCarbs, 'g');
    add('fat', _reFat, 'g');
    add('fiber', _reFiber, 'g');
    add('sodium', _reSodium, 'mg');
    return map.isEmpty ? null : map;
  }

  /// Remove nutrition lines from text so only main post content is shown.
  String _stripNutritionLinesFromText(String text) {
    final lines = text.split('\n');
    final reList = [_reCalories, _reProtein, _reCarbs, _reFat, _reFiber, _reSodium];
    final kept = lines.where((line) {
      return !reList.any((re) => re.hasMatch(line));
    }).toList();
    return kept.join('\n').trim();
  }

  /// Parses display text into Title, Health Score (one line only), and AI Insight for layout reorder.
  /// Health Score is always a single line so Nutrition can sit directly under it.
  /// Uses case-insensitive matching; everything after the Health Score line is treated as AI Insight.
  ({String title, String? healthScore, String? aiInsight}) _parseTitleHealthAndInsight(String text) {
    if (text.isEmpty) return (title: '', healthScore: null, aiInsight: null);
    final lower = text.toLowerCase();
    final healthMark = 'health score:';
    final aiMark = 'ai insight:';
    final healthIdx = lower.indexOf(healthMark);
    final aiIdx = lower.indexOf(aiMark);
    final healthStart = healthIdx >= 0 ? healthIdx : -1;
    final aiStart = aiIdx >= 0 ? aiIdx : -1;

    // When we have "Health Score:", take only that single line so Nutrition shows right after it.
    // Everything after that line is AI Insight (with or without an "AI Insight:" label).
    if (healthStart >= 0) {
      final afterHealth = text.substring(healthStart);
      final lineEnd = afterHealth.indexOf('\n');
      final healthScoreLine = lineEnd < 0
          ? afterHealth.trim()
          : afterHealth.substring(0, lineEnd).trim();
      final afterHealthLine = lineEnd < 0 ? '' : afterHealth.substring(lineEnd + 1).trim();

      return (
        title: text.substring(0, healthStart).trim(),
        healthScore: healthScoreLine,
        aiInsight: afterHealthLine.isEmpty ? null : afterHealthLine,
      );
    }

    if (aiStart >= 0) {
      return (
        title: text.substring(0, aiStart).trim(),
        healthScore: null,
        aiInsight: text.substring(aiStart).trim(),
      );
    }
    return (title: text, healthScore: null, aiInsight: null);
  }

  /// Same text style as Health Score: w500, 0xFF0A2342, slightly smaller than main post text.
  TextStyle get _healthScoreStyle => ResponsiveTextStyles.textSm.copyWith(
    fontWeight: FontWeight.w500,
    color: const Color(0xFF0A2342),
  );

  Widget _buildNutritionSection(Map<String, String> nutrition) {
    final style = _healthScoreStyle;
    final rows = <Widget>[];
    // Row 1: Calories | Protein
    final r1 = _nutritionRow(
      nutrition['calories'] != null ? '🔥 Calories: ${nutrition['calories']}' : null,
      nutrition['protein'] != null ? '💪 Protein: ${nutrition['protein']}' : null,
      style,
    );
    if (r1 != null) rows.add(r1);
    // Row 2: Carbs | Fat
    final r2 = _nutritionRow(
      nutrition['carbs'] != null ? '🍞 Carbs: ${nutrition['carbs']}' : null,
      nutrition['fat'] != null ? '🧈 Fat: ${nutrition['fat']}' : null,
      style,
    );
    if (r2 != null) { if (rows.isNotEmpty) rows.add(SizedBox(height: 6.h)); rows.add(r2); }
    // Row 3: Fiber | Sodium
    final r3 = _nutritionRow(
      nutrition['fiber'] != null ? '🌽 Fiber: ${nutrition['fiber']}' : null,
      nutrition['sodium'] != null ? '🧂 Sodium: ${nutrition['sodium']}' : null,
      style,
    );
    if (r3 != null) { if (rows.isNotEmpty) rows.add(SizedBox(height: 6.h)); rows.add(r3); }
    if (rows.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: rows,
    );
  }

  Widget? _nutritionRow(String? left, String? right, TextStyle style) {
    if (left == null && right == null) return null;
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (left != null) Text(left, style: style),
        if (left != null && right != null) SizedBox(width: 8.w),
        if (left != null && right != null) Text('|', style: style),
        if (left != null && right != null) SizedBox(width: 8.w),
        if (right != null) Text(right, style: style),
      ],
    );
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

/// Expandable post body: shows a short preview with "See More" when content is long.
class _ExpandablePostContent extends StatefulWidget {
  final String title;
  final String? healthScore;
  final String? aiInsight;
  final Widget? nutritionWidget;
  final TextStyle titleStyle;
  final TextStyle healthScoreStyle;
  final TextStyle aiInsightStyle;

  const _ExpandablePostContent({
    required this.title,
    this.healthScore,
    this.aiInsight,
    this.nutritionWidget,
    required this.titleStyle,
    required this.healthScoreStyle,
    required this.aiInsightStyle,
  });

  @override
  State<_ExpandablePostContent> createState() => _ExpandablePostContentState();
}

class _ExpandablePostContentState extends State<_ExpandablePostContent> {
  static const int _maxLines = 3;
  bool _expanded = false;

  bool _aiInsightExceedsMaxLines(String text, double maxWidth, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: _maxLines,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    return painter.didExceedMaxLines;
  }

  @override
  Widget build(BuildContext context) {
    final hasAnyContent = widget.title.isNotEmpty ||
        (widget.healthScore != null && widget.healthScore!.isNotEmpty) ||
        (widget.aiInsight != null && widget.aiInsight!.isNotEmpty);

    if (!hasAnyContent) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.nutritionWidget != null) ...[
            widget.nutritionWidget!,
            SizedBox(height: 16.h),
          ],
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final hasAiInsight = widget.aiInsight != null && widget.aiInsight!.isNotEmpty;
        final aiExceedsThreeLines = hasAiInsight &&
            !_expanded &&
            _aiInsightExceedsMaxLines(widget.aiInsight!, maxWidth, widget.aiInsightStyle);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.title.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(bottom: 16.h),
                child: Text(widget.title, style: widget.titleStyle),
              ),
            if (widget.healthScore != null && widget.healthScore!.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(bottom: 16.h),
                child: Text(widget.healthScore!, style: widget.healthScoreStyle),
              ),
            if (widget.nutritionWidget != null) ...[
              widget.nutritionWidget!,
              SizedBox(height: 16.h),
            ],
            if (hasAiInsight) ...[
              Padding(
                padding: EdgeInsets.only(bottom: aiExceedsThreeLines ? 8.h : 16.h),
                child: Text(
                  widget.aiInsight!,
                  style: widget.aiInsightStyle,
                  maxLines: aiExceedsThreeLines ? _maxLines : null,
                  overflow: aiExceedsThreeLines ? TextOverflow.ellipsis : null,
                ),
              ),
              if (aiExceedsThreeLines)
                GestureDetector(
                  onTap: () => setState(() => _expanded = true),
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 16.h),
                    child: Text(
                      'See More',
                      style: ResponsiveTextStyles.textSm.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ],
        );
      },
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

/// Reusable avatar: shows [CachedNetworkImage] when [avatarUrl] is not empty,
/// otherwise a [CircleAvatar] with first letter of [name] (or "?" if null/empty).
class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String? name;
  final double size;

  const UserAvatar({
    super.key,
    this.avatarUrl,
    this.name,
    this.size = 48,
  });

  static const Color _letterFallbackBg = Color(0xFFE0E0E0);
  static const Color _letterFallbackText = Colors.white;

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl?.trim() ?? '';
    if (url.isNotEmpty) {
      return ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: CachedNetworkImage(
            imageUrl: url,
            width: size,
            height: size,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              width: size,
              height: size,
              color: _letterFallbackBg,
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF00B8A9),
                  strokeWidth: 2,
                ),
              ),
            ),
            errorWidget: (context, url, error) => _buildLetterAvatar(context),
          ),
        ),
      );
    }
    return _buildLetterAvatar(context);
  }

  Widget _buildLetterAvatar(BuildContext context) {
    final displayName = name?.trim() ?? '';
    final letter = displayName.isEmpty
        ? '?'
        : displayName.substring(0, 1).toUpperCase();
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: _letterFallbackBg,
      child: Text(
        letter,
        style: TextStyle(
          color: _letterFallbackText,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.5,
        ),
      ),
    );
  }
}

