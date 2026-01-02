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
        fillColor: Colors.white, // Ensure white background for all inputs
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
          color: const Color(0xFF0A2342).withOpacity(0.4), // Dark hint text
        ),
      ),

      // Text Selection Theme - Ensure dark cursor and selection
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: const Color(0xFF0A2342), // Dark cursor
        selectionColor: const Color(0xFF0A2342).withOpacity(0.2), // Dark selection highlight
        selectionHandleColor: const Color(0xFF0A2342), // Dark selection handles
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

  // Dark Theme - FORCED TO LIGHT MODE
  // This ensures system dark mode never affects the app
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light, // Force light brightness

      // Color Scheme - FORCED TO LIGHT COLORS
      colorScheme: ColorScheme.light(
        brightness: Brightness.light, // Force light brightness
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

      // Scaffold - FORCED TO LIGHT COLORS
      scaffoldBackgroundColor: AppColors.background,

      // AppBar Theme - FORCED TO LIGHT COLORS
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

      // Card Theme - FORCED TO LIGHT COLORS
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          side: BorderSide(color: AppColors.border, width: 1),
        ),
      ),

      // Input Decoration Theme - FORCED TO LIGHT COLORS WITH DARK TEXT
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white, // Ensure white background
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
          color: const Color(0xFF0A2342).withOpacity(0.4), // Dark hint text
        ),
      ),

      // Text Selection Theme - FORCED TO DARK CURSOR AND SELECTION
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: const Color(0xFF0A2342), // Dark cursor
        selectionColor: const Color(0xFF0A2342).withOpacity(0.2), // Dark selection highlight
        selectionHandleColor: const Color(0xFF0A2342), // Dark selection handles
      ),

      // Elevated Button Theme - FORCED TO LIGHT COLORS
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

      // Text Button Theme - FORCED TO LIGHT COLORS
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

      // Outlined Button Theme - FORCED TO LIGHT COLORS
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

      // Dialog Theme - FORCED TO LIGHT COLORS
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

      // Bottom Sheet Theme - FORCED TO LIGHT COLORS
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusLg),
          ),
        ),
      ),

      // Divider Theme - FORCED TO LIGHT COLORS
      dividerTheme: DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      // Switch Theme - FORCED TO LIGHT COLORS
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

      // Chip Theme - FORCED TO LIGHT COLORS
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

      // Text Theme - FORCED TO LIGHT COLORS WITH DARK TEXT
      textTheme: TextTheme(
        displayLarge: AppTextStyles.text4Xl.copyWith(color: AppColors.foreground),
        displayMedium: AppTextStyles.text3Xl.copyWith(color: AppColors.foreground),
        displaySmall: AppTextStyles.text2Xl.copyWith(color: AppColors.foreground),
        headlineMedium: AppTextStyles.textXl.copyWith(color: AppColors.foreground),
        headlineSmall: AppTextStyles.textLg.copyWith(color: AppColors.foreground),
        titleLarge: AppTextStyles.textLg.copyWith(color: AppColors.foreground),
        titleMedium: AppTextStyles.textBase.copyWith(color: AppColors.foreground),
        titleSmall: AppTextStyles.textSm.copyWith(color: AppColors.foreground),
        bodyLarge: AppTextStyles.textBase.copyWith(color: AppColors.foreground),
        bodyMedium: AppTextStyles.textSm.copyWith(color: AppColors.foreground),
        bodySmall: AppTextStyles.textXs.copyWith(color: AppColors.foreground),
        labelLarge: AppTextStyles.textBase.copyWith(
          color: AppColors.foreground,
          fontWeight: FontWeight.w500,
        ),
        labelMedium: AppTextStyles.textSm.copyWith(
          color: AppColors.foreground,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: AppTextStyles.textXs.copyWith(
          color: AppColors.foreground,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}