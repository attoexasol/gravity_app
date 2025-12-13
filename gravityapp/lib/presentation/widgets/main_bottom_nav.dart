import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../app/theme/app_text_styles.dart';

class MainBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final String userType;

  const MainBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.userType = 'customer',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: const Color(0xFF0A2342).withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavButton(
                index: 0,
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Home',
              ),
              _buildNavButton(
                index: 1,
                icon: Icons.people_outline,
                activeIcon: Icons.people,
                label: 'Community',
              ),
              _buildNavButton(
                index: 2,
                icon: Icons.smart_toy_outlined,
                activeIcon: Icons.smart_toy,
                label: 'AI Coach',
              ),
              _buildNavButton(
                index: 3,
                icon: Icons.message_outlined,
                activeIcon: Icons.message,
                label: 'Messages',
              ),
              // Dashboard menu item - only for coaches
              if (userType == 'coach')
                _buildNavButton(
                  index: 4,
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard,
                  label: 'Dashboard',
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isActive = currentIndex == index;

    return _NavButton(
      isActive: isActive,
      icon: isActive ? activeIcon : icon,
      label: label,
      onTap: () => onTap(index),
    );
  }
}

/// NavButton widget with tap animation (matching React motion behavior)
class _NavButton extends StatefulWidget {
  final bool isActive;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavButton({
    required this.isActive,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton>
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

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          constraints: BoxConstraints(minWidth: 60.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 24.sp,
                color: widget.isActive
                    ? const Color(0xFF00B8A9)
                    : const Color(0xFF0A2342).withOpacity(0.4),
              ),
              SizedBox(height: 4.h),
              Text(
                widget.label,
                style: ResponsiveTextStyles.textXs.copyWith(
                  color: widget.isActive
                      ? const Color(0xFF00B8A9)
                      : const Color(0xFF0A2342).withOpacity(0.4),
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
