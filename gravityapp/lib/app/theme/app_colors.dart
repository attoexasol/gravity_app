import 'package:flutter/material.dart';

/// App Colors - Light Theme
/// Converted from React CSS variables
class AppColors {
  AppColors._();

  // Base Colors
  static const Color background = Color(0xFFFFFFFF);
  static const Color foreground = Color(0xFF252527); // oklch(0.145 0 0)

  // Card
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardForeground = Color(0xFF252527);

  // Popover
  static const Color popover = Color(0xFFFFFFFF);
  static const Color popoverForeground = Color(0xFF252527);

  // Primary
  static const Color primary = Color(0xFF030213);
  static const Color primaryForeground = Color(0xFFFFFFFF);

  // Secondary
  static const Color secondary = Color(0xFFF2F2F5); // oklch(0.95 0.0058 264.53)
  static const Color secondaryForeground = Color(0xFF030213);

  // Muted
  static const Color muted = Color(0xFFECECF0);
  static const Color mutedForeground = Color(0xFF717182);

  // Accent
  static const Color accent = Color(0xFFE9EBEF);
  static const Color accentForeground = Color(0xFF030213);

  // Destructive
  static const Color destructive = Color(0xFFD4183D);
  static const Color destructiveForeground = Color(0xFFFFFFFF);

  // Border & Input
  static const Color border = Color(0x1A000000); // rgba(0, 0, 0, 0.1)
  static const Color input = Colors.transparent;
  static const Color inputBackground = Color(0xFFF3F3F5);
  static const Color switchBackground = Color(0xFFCBCED4);

  // Ring (Focus)
  static const Color ring = Color(0xFFB5B5B5); // oklch(0.708 0 0)

  // Chart Colors
  static const Color chart1 = Color(0xFFE89C4A); // oklch(0.646 0.222 41.116)
  static const Color chart2 = Color(0xFF5EB8C8); // oklch(0.6 0.118 184.704)
  static const Color chart3 = Color(0xFF3D4F7A); // oklch(0.398 0.07 227.392)
  static const Color chart4 = Color(0xFFE8E364); // oklch(0.828 0.189 84.429)
  static const Color chart5 = Color(0xFFD8C456); // oklch(0.769 0.188 70.08)

  // Sidebar
  static const Color sidebar = Color(0xFFFBFBFB); // oklch(0.985 0 0)
  static const Color sidebarForeground = Color(0xFF252527);
  static const Color sidebarPrimary = Color(0xFF030213);
  static const Color sidebarPrimaryForeground = Color(0xFFFBFBFB);
  static const Color sidebarAccent = Color(0xFFF7F7F7); // oklch(0.97 0 0)
  static const Color sidebarAccentForeground = Color(0xFF383838); // oklch(0.205 0 0)
  static const Color sidebarBorder = Color(0xFFEBEBEB); // oklch(0.922 0 0)
  static const Color sidebarRing = Color(0xFFB5B5B5);
}

/// App Colors - Dark Theme
class AppColorsDark {
  AppColorsDark._();

  // Base Colors
  static const Color background = Color(0xFF252527); // oklch(0.145 0 0)
  static const Color foreground = Color(0xFFFBFBFB); // oklch(0.985 0 0)

  // Card
  static const Color card = Color(0xFF252527);
  static const Color cardForeground = Color(0xFFFBFBFB);

  // Popover
  static const Color popover = Color(0xFF252527);
  static const Color popoverForeground = Color(0xFFFBFBFB);

  // Primary
  static const Color primary = Color(0xFFFBFBFB);
  static const Color primaryForeground = Color(0xFF383838); // oklch(0.205 0 0)

  // Secondary
  static const Color secondary = Color(0xFF454545); // oklch(0.269 0 0)
  static const Color secondaryForeground = Color(0xFFFBFBFB);

  // Muted
  static const Color muted = Color(0xFF454545);
  static const Color mutedForeground = Color(0xFFB5B5B5); // oklch(0.708 0 0)

  // Accent
  static const Color accent = Color(0xFF454545);
  static const Color accentForeground = Color(0xFFFBFBFB);

  // Destructive
  static const Color destructive = Color(0xFF7F3540); // oklch(0.396 0.141 25.723)
  static const Color destructiveForeground = Color(0xFFD98D8E); // oklch(0.637 0.237 25.331)

  // Border & Input
  static const Color border = Color(0xFF454545);
  static const Color input = Color(0xFF454545);
  static const Color ring = Color(0xFF737373); // oklch(0.439 0 0)

  // Chart Colors
  static const Color chart1 = Color(0xFF6B5FCF); // oklch(0.488 0.243 264.376)
  static const Color chart2 = Color(0xFF6FC4A0); // oklch(0.696 0.17 162.48)
  static const Color chart3 = Color(0xFFD8C456); // oklch(0.769 0.188 70.08)
  static const Color chart4 = Color(0xFFCF6FC4); // oklch(0.627 0.265 303.9)
  static const Color chart5 = Color(0xFFD47056); // oklch(0.645 0.246 16.439)

  // Sidebar
  static const Color sidebar = Color(0xFF383838);
  static const Color sidebarForeground = Color(0xFFFBFBFB);
  static const Color sidebarPrimary = Color(0xFF6B5FCF);
  static const Color sidebarPrimaryForeground = Color(0xFFFBFBFB);
  static const Color sidebarAccent = Color(0xFF454545);
  static const Color sidebarAccentForeground = Color(0xFFFBFBFB);
  static const Color sidebarBorder = Color(0xFF454545);
  static const Color sidebarRing = Color(0xFF737373);
}

/// Size and Radius Constants
class AppSizes {
  AppSizes._();

  // Border Radius (base: 0.625rem = 10px)
  static const double radiusSm = 6.0; // radius - 4px
  static const double radiusMd = 8.0; // radius - 2px
  static const double radiusLg = 10.0; // radius
  static const double radiusXl = 14.0; // radius + 4px
}