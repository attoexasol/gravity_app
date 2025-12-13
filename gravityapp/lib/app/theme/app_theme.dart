import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color Scheme
      colorScheme: ColorScheme.light(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.primaryForeground,
        secondary: AppColors.secondary,
        onSecondary: AppColors.secondaryForeground,
        error: AppColors.destructive,
        onError: AppColors.destructiveForeground,
        surface: AppColors.card,
        onSurface: AppColors.cardForeground,
        surfaceContainerHighest: AppColors.muted,
        outline: AppColors.border,
      ),

      // Scaffold
      scaffoldBackgroundColor: AppColors.background,

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.foreground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.textXl.copyWith(
          color: AppColors.foreground,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          side: BorderSide(color: AppColors.border, width: 1),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide(color: AppColors.ring, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide(color: AppColors.destructive),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: AppTextStyles.textBase.copyWith(
          color: AppColors.mutedForeground,
        ),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.primaryForeground,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          textStyle: AppTextStyles.textBase.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          textStyle: AppTextStyles.textBase.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.foreground,
          side: BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          textStyle: AppTextStyles.textBase.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.popover,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        titleTextStyle: AppTextStyles.textXl.copyWith(
          color: AppColors.popoverForeground,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusLg),
          ),
        ),
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryForeground;
          }
          return AppColors.switchBackground;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.switchBackground;
        }),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.secondary,
        labelStyle: AppTextStyles.textSm.copyWith(
          color: AppColors.secondaryForeground,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: AppTextStyles.text4Xl,
        displayMedium: AppTextStyles.text3Xl,
        displaySmall: AppTextStyles.text2Xl,
        headlineMedium: AppTextStyles.textXl,
        headlineSmall: AppTextStyles.textLg,
        titleLarge: AppTextStyles.textLg,
        titleMedium: AppTextStyles.textBase,
        titleSmall: AppTextStyles.textSm,
        bodyLarge: AppTextStyles.textBase,
        bodyMedium: AppTextStyles.textSm,
        bodySmall: AppTextStyles.textXs,
        labelLarge: AppTextStyles.textBase.copyWith(fontWeight: FontWeight.w500),
        labelMedium: AppTextStyles.textSm.copyWith(fontWeight: FontWeight.w500),
        labelSmall: AppTextStyles.textXs.copyWith(fontWeight: FontWeight.w500),
      ),
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Color Scheme
      colorScheme: ColorScheme.dark(
        brightness: Brightness.dark,
        primary: AppColorsDark.primary,
        onPrimary: AppColorsDark.primaryForeground,
        secondary: AppColorsDark.secondary,
        onSecondary: AppColorsDark.secondaryForeground,
        error: AppColorsDark.destructive,
        onError: AppColorsDark.destructiveForeground,
        surface: AppColorsDark.card,
        onSurface: AppColorsDark.cardForeground,
        surfaceContainerHighest: AppColorsDark.muted,
        outline: AppColorsDark.border,
      ),

      // Scaffold
      scaffoldBackgroundColor: AppColorsDark.background,

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColorsDark.background,
        foregroundColor: AppColorsDark.foreground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.textXl.copyWith(
          color: AppColorsDark.foreground,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColorsDark.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          side: BorderSide(color: AppColorsDark.border, width: 1),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColorsDark.input,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide(color: AppColorsDark.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide(color: AppColorsDark.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide(color: AppColorsDark.ring, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide(color: AppColorsDark.destructive),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: AppTextStyles.textBase.copyWith(
          color: AppColorsDark.mutedForeground,
        ),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorsDark.primary,
          foregroundColor: AppColorsDark.primaryForeground,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          textStyle: AppTextStyles.textBase.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColorsDark.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          textStyle: AppTextStyles.textBase.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColorsDark.foreground,
          side: BorderSide(color: AppColorsDark.border),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          textStyle: AppTextStyles.textBase.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColorsDark.popover,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        titleTextStyle: AppTextStyles.textXl.copyWith(
          color: AppColorsDark.popoverForeground,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColorsDark.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusLg),
          ),
        ),
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: AppColorsDark.border,
        thickness: 1,
        space: 1,
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColorsDark.primaryForeground;
          }
          return AppColorsDark.muted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColorsDark.primary;
          }
          return AppColorsDark.muted;
        }),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColorsDark.secondary,
        labelStyle: AppTextStyles.textSm.copyWith(
          color: AppColorsDark.secondaryForeground,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: AppTextStyles.text4Xl.copyWith(color: AppColorsDark.foreground),
        displayMedium: AppTextStyles.text3Xl.copyWith(color: AppColorsDark.foreground),
        displaySmall: AppTextStyles.text2Xl.copyWith(color: AppColorsDark.foreground),
        headlineMedium: AppTextStyles.textXl.copyWith(color: AppColorsDark.foreground),
        headlineSmall: AppTextStyles.textLg.copyWith(color: AppColorsDark.foreground),
        titleLarge: AppTextStyles.textLg.copyWith(color: AppColorsDark.foreground),
        titleMedium: AppTextStyles.textBase.copyWith(color: AppColorsDark.foreground),
        titleSmall: AppTextStyles.textSm.copyWith(color: AppColorsDark.foreground),
        bodyLarge: AppTextStyles.textBase.copyWith(color: AppColorsDark.foreground),
        bodyMedium: AppTextStyles.textSm.copyWith(color: AppColorsDark.foreground),
        bodySmall: AppTextStyles.textXs.copyWith(color: AppColorsDark.foreground),
        labelLarge: AppTextStyles.textBase.copyWith(
          color: AppColorsDark.foreground,
          fontWeight: FontWeight.w500,
        ),
        labelMedium: AppTextStyles.textSm.copyWith(
          color: AppColorsDark.foreground,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: AppTextStyles.textXs.copyWith(
          color: AppColorsDark.foreground,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}