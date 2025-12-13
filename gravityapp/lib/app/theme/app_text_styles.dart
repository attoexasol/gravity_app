import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Responsive Text Styles using ScreenUtil
/// All sizes automatically adapt to screen size
class ResponsiveTextStyles {
  ResponsiveTextStyles._();

  // Font Weights
  static const FontWeight fontWeightNormal = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemiBold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;

  // Line Height
  static const double lineHeight = 1.5;

  // Text Styles with Responsive Sizing

  /// Extra Small Text (12sp)
  static TextStyle get textXs => TextStyle(
    fontSize: 12.sp,
    fontWeight: fontWeightNormal,
    height: lineHeight,
  );

  /// Small Text (14sp)
  static TextStyle get textSm => TextStyle(
    fontSize: 14.sp,
    fontWeight: fontWeightNormal,
    height: lineHeight,
  );

  /// Base Text (16sp)
  static TextStyle get textBase => TextStyle(
    fontSize: 16.sp,
    fontWeight: fontWeightNormal,
    height: lineHeight,
  );

  /// Large Text (18sp)
  static TextStyle get textLg => TextStyle(
    fontSize: 18.sp,
    fontWeight: fontWeightNormal,
    height: lineHeight,
  );

  /// Extra Large Text (20sp)
  static TextStyle get textXl => TextStyle(
    fontSize: 20.sp,
    fontWeight: fontWeightNormal,
    height: lineHeight,
  );

  /// 2X Large Text (24sp)
  static TextStyle get text2Xl => TextStyle(
    fontSize: 24.sp,
    fontWeight: fontWeightNormal,
    height: lineHeight,
  );

  /// 3X Large Text (30sp)
  static TextStyle get text3Xl => TextStyle(
    fontSize: 30.sp,
    fontWeight: fontWeightNormal,
    height: lineHeight,
  );

  /// 4X Large Text (36sp)
  static TextStyle get text4Xl => TextStyle(
    fontSize: 36.sp,
    fontWeight: fontWeightNormal,
    height: lineHeight,
  );

  // Heading Styles

  /// H1 - Display Large (24sp, Medium)
  static TextStyle get h1 => TextStyle(
    fontSize: 24.sp,
    fontWeight: fontWeightMedium,
    height: lineHeight,
  );

  /// H2 - Display Medium (20sp, Medium)
  static TextStyle get h2 => TextStyle(
    fontSize: 20.sp,
    fontWeight: fontWeightMedium,
    height: lineHeight,
  );

  /// H3 - Display Small (18sp, Medium)
  static TextStyle get h3 => TextStyle(
    fontSize: 18.sp,
    fontWeight: fontWeightMedium,
    height: lineHeight,
  );

  /// H4 - Title (16sp, Medium)
  static TextStyle get h4 => TextStyle(
    fontSize: 16.sp,
    fontWeight: fontWeightMedium,
    height: lineHeight,
  );

  // Button Styles

  /// Button Text - Medium Weight (16sp)
  static TextStyle get button => TextStyle(
    fontSize: 16.sp,
    fontWeight: fontWeightMedium,
    height: lineHeight,
  );

  /// Button Text Small - Medium Weight (14sp)
  static TextStyle get buttonSm => TextStyle(
    fontSize: 14.sp,
    fontWeight: fontWeightMedium,
    height: lineHeight,
  );

  /// Button Text Large - Medium Weight (18sp)
  static TextStyle get buttonLg => TextStyle(
    fontSize: 18.sp,
    fontWeight: fontWeightMedium,
    height: lineHeight,
  );
}

/// Alias for backward compatibility
/// Use AppTextStyles or ResponsiveTextStyles - both work the same
typedef AppTextStyles = ResponsiveTextStyles;

/// ⚠️ IMPORTANT: DO NOT define custom extensions for .w, .h, .sp, .r
/// These are already provided by flutter_screenutil package's SizeExtension
///
/// Usage:
/// - 20.w for responsive width
/// - 20.h for responsive height
/// - 20.sp for responsive font size
/// - 20.r for responsive radius