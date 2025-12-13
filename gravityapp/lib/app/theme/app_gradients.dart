import 'package:flutter/material.dart';
import 'app_colors.dart';

/// App Gradients
/// Gradient definitions for backgrounds and decorative elements
class AppGradients {
  AppGradients._();

  // Light Theme Gradients

  /// Primary Gradient - Main brand gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.primary,
      Color(0xFF1A1A2E),
    ],
  );

  /// Secondary Gradient - Subtle background
  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppColors.secondary,
      AppColors.muted,
    ],
  );

  /// Accent Gradient - Highlight elements
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.accent,
      AppColors.secondary,
    ],
  );

  /// Card Gradient - Elevated card background
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFFAFAFA),
    ],
  );

  /// Chart Gradient 1 - Orange
  static const LinearGradient chartGradient1 = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppColors.chart1,
      Color(0xFFFFB366),
    ],
  );

  /// Chart Gradient 2 - Cyan
  static const LinearGradient chartGradient2 = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppColors.chart2,
      Color(0xFF7DCCE0),
    ],
  );

  /// Chart Gradient 3 - Blue
  static const LinearGradient chartGradient3 = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppColors.chart3,
      Color(0xFF5A6B99),
    ],
  );

  /// Chart Gradient 4 - Yellow
  static const LinearGradient chartGradient4 = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppColors.chart4,
      Color(0xFFFFF089),
    ],
  );

  /// Chart Gradient 5 - Gold
  static const LinearGradient chartGradient5 = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppColors.chart5,
      Color(0xFFEDD973),
    ],
  );

  /// Shimmer Gradient - Loading effect
  static const LinearGradient shimmerGradient = LinearGradient(
    begin: Alignment(-1.0, -0.5),
    end: Alignment(1.0, 0.5),
    colors: [
      Color(0xFFECECF0),
      Color(0xFFF3F3F5),
      Color(0xFFECECF0),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // Dark Theme Gradients

  /// Dark Primary Gradient
  static const LinearGradient primaryGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColorsDark.primary,
      Color(0xFFD0D0D0),
    ],
  );

  /// Dark Secondary Gradient
  static const LinearGradient secondaryGradientDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppColorsDark.secondary,
      AppColorsDark.muted,
    ],
  );

  /// Dark Accent Gradient
  static const LinearGradient accentGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColorsDark.accent,
      AppColorsDark.secondary,
    ],
  );

  /// Dark Card Gradient
  static const LinearGradient cardGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF252527),
      Color(0xFF2A2A2C),
    ],
  );

  /// Dark Chart Gradient 1 - Purple
  static const LinearGradient chartGradient1Dark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppColorsDark.chart1,
      Color(0xFF8A7FE5),
    ],
  );

  /// Dark Chart Gradient 2 - Green
  static const LinearGradient chartGradient2Dark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppColorsDark.chart2,
      Color(0xFF8DD9B8),
    ],
  );

  /// Dark Chart Gradient 3 - Gold
  static const LinearGradient chartGradient3Dark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppColorsDark.chart3,
      Color(0xFFEDD973),
    ],
  );

  /// Dark Chart Gradient 4 - Pink
  static const LinearGradient chartGradient4Dark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppColorsDark.chart4,
      Color(0xFFE58DD9),
    ],
  );

  /// Dark Chart Gradient 5 - Orange
  static const LinearGradient chartGradient5Dark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppColorsDark.chart5,
      Color(0xFFE99173),
    ],
  );

  /// Dark Shimmer Gradient - Loading effect
  static const LinearGradient shimmerGradientDark = LinearGradient(
    begin: Alignment(-1.0, -0.5),
    end: Alignment(1.0, 0.5),
    colors: [
      Color(0xFF454545),
      Color(0xFF525252),
      Color(0xFF454545),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // Radial Gradients

  /// Radial Gradient - Spotlight effect
  static const RadialGradient spotlightGradient = RadialGradient(
    center: Alignment.center,
    radius: 1.0,
    colors: [
      Color(0x33FFFFFF),
      Color(0x00FFFFFF),
    ],
  );

  /// Radial Gradient Dark - Dark spotlight
  static const RadialGradient spotlightGradientDark = RadialGradient(
    center: Alignment.center,
    radius: 1.0,
    colors: [
      Color(0x1AFFFFFF),
      Color(0x00FFFFFF),
    ],
  );

  // Sweep Gradients

  /// Sweep Gradient - Circular progress
  static const SweepGradient progressGradient = SweepGradient(
    startAngle: 0,
    endAngle: 6.28, // 2 * pi
    colors: [
      AppColors.chart1,
      AppColors.chart2,
      AppColors.chart3,
      AppColors.chart4,
      AppColors.chart5,
      AppColors.chart1,
    ],
  );

  /// Sweep Gradient Dark - Dark circular progress
  static const SweepGradient progressGradientDark = SweepGradient(
    startAngle: 0,
    endAngle: 6.28, // 2 * pi
    colors: [
      AppColorsDark.chart1,
      AppColorsDark.chart2,
      AppColorsDark.chart3,
      AppColorsDark.chart4,
      AppColorsDark.chart5,
      AppColorsDark.chart1,
    ],
  );
}