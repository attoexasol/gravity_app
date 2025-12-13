import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../app/theme/app_text_styles.dart';

class AccountSection extends StatelessWidget {
  final String name;
  final String email;
  final String initials;

  const AccountSection({
    super.key,
    required this.name,
    required this.email,
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Account'),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Row(
              children: [
                Container(
                  width: 64.w,
                  height: 64.h,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF00B8A9), Color(0xFF0A2342)],
                    ),
                    borderRadius: BorderRadius.circular(32.r),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: ResponsiveTextStyles.textXl.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: ResponsiveTextStyles.textBase.copyWith(
                          color: const Color(0xFF0A2342),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        email,
                        style: ResponsiveTextStyles.textSm.copyWith(
                          color: const Color(0xFF0A2342).withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Private Title Builder
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Text(
        title,
        style: ResponsiveTextStyles.textLg.copyWith(
          color: const Color(0xFF0A2342),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
