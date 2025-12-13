import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/app_text_styles.dart'; // update this path if needed

class SectionTitleWidget extends StatelessWidget {
  final String title;
  final bool isDanger;

  const SectionTitleWidget({
    super.key,
    required this.title,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h, left: 4.w),
      child: Text(
        title,
        style: ResponsiveTextStyles.textLg.copyWith(
          color: isDanger
              ? Colors.red.withOpacity(0.6)
              : const Color(0xFF0A2342).withOpacity(0.6),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
