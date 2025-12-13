import 'package:flutter/material.dart';

/// App Shadows
/// Shadow definitions for consistent elevation throughout the app
class AppShadows {
  AppShadows._();

  // Light Theme Shadows

  /// Extra Small Shadow - Subtle elevation
  static const List<BoxShadow> shadowXs = [
    BoxShadow(
      color: Color(0x0A000000), // 4% opacity
      offset: Offset(0, 1),
      blurRadius: 2,
      spreadRadius: 0,
    ),
  ];

  /// Small Shadow - Card elevation
  static const List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Color(0x0D000000), // 5% opacity
      offset: Offset(0, 1),
      blurRadius: 3,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x0A000000), // 4% opacity
      offset: Offset(0, 1),
      blurRadius: 2,
      spreadRadius: -1,
    ),
  ];

  /// Medium Shadow - Raised elements
  static const List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Color(0x0D000000), // 5% opacity
      offset: Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -1,
    ),
    BoxShadow(
      color: Color(0x0A000000), // 4% opacity
      offset: Offset(0, 2),
      blurRadius: 4,
      spreadRadius: -2,
    ),
  ];

  /// Large Shadow - Floating elements
  static const List<BoxShadow> shadowLg = [
    BoxShadow(
      color: Color(0x0D000000), // 5% opacity
      offset: Offset(0, 10),
      blurRadius: 15,
      spreadRadius: -3,
    ),
    BoxShadow(
      color: Color(0x0A000000), // 4% opacity
      offset: Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -4,
    ),
  ];

  /// Extra Large Shadow - Modal dialogs
  static const List<BoxShadow> shadowXl = [
    BoxShadow(
      color: Color(0x14000000), // 8% opacity
      offset: Offset(0, 20),
      blurRadius: 25,
      spreadRadius: -5,
    ),
    BoxShadow(
      color: Color(0x0D000000), // 5% opacity
      offset: Offset(0, 8),
      blurRadius: 10,
      spreadRadius: -6,
    ),
  ];

  /// 2X Large Shadow - Large modals
  static const List<BoxShadow> shadow2Xl = [
    BoxShadow(
      color: Color(0x19000000), // 10% opacity
      offset: Offset(0, 25),
      blurRadius: 50,
      spreadRadius: -12,
    ),
  ];

  // Dark Theme Shadows

  /// Dark XS Shadow
  static const List<BoxShadow> shadowXsDark = [
    BoxShadow(
      color: Color(0x33000000), // 20% opacity
      offset: Offset(0, 1),
      blurRadius: 2,
      spreadRadius: 0,
    ),
  ];

  /// Dark Small Shadow
  static const List<BoxShadow> shadowSmDark = [
    BoxShadow(
      color: Color(0x33000000), // 20% opacity
      offset: Offset(0, 1),
      blurRadius: 3,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x26000000), // 15% opacity
      offset: Offset(0, 1),
      blurRadius: 2,
      spreadRadius: -1,
    ),
  ];

  /// Dark Medium Shadow
  static const List<BoxShadow> shadowMdDark = [
    BoxShadow(
      color: Color(0x33000000), // 20% opacity
      offset: Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -1,
    ),
    BoxShadow(
      color: Color(0x26000000), // 15% opacity
      offset: Offset(0, 2),
      blurRadius: 4,
      spreadRadius: -2,
    ),
  ];

  /// Dark Large Shadow
  static const List<BoxShadow> shadowLgDark = [
    BoxShadow(
      color: Color(0x33000000), // 20% opacity
      offset: Offset(0, 10),
      blurRadius: 15,
      spreadRadius: -3,
    ),
    BoxShadow(
      color: Color(0x26000000), // 15% opacity
      offset: Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -4,
    ),
  ];

  /// Dark Extra Large Shadow
  static const List<BoxShadow> shadowXlDark = [
    BoxShadow(
      color: Color(0x40000000), // 25% opacity
      offset: Offset(0, 20),
      blurRadius: 25,
      spreadRadius: -5,
    ),
    BoxShadow(
      color: Color(0x33000000), // 20% opacity
      offset: Offset(0, 8),
      blurRadius: 10,
      spreadRadius: -6,
    ),
  ];

  /// Dark 2X Large Shadow
  static const List<BoxShadow> shadow2XlDark = [
    BoxShadow(
      color: Color(0x4D000000), // 30% opacity
      offset: Offset(0, 25),
      blurRadius: 50,
      spreadRadius: -12,
    ),
  ];

  // Inner Shadows (for inset effects - can be used with Stack/Container tricks)

  /// Inner Shadow Small
  static const List<BoxShadow> innerShadowSm = [
    BoxShadow(
      color: Color(0x0A000000), // 4% opacity
      offset: Offset(0, 2),
      blurRadius: 4,
      spreadRadius: 0,
    ),
  ];

  /// Inner Shadow Medium
  static const List<BoxShadow> innerShadowMd = [
    BoxShadow(
      color: Color(0x0D000000), // 5% opacity
      offset: Offset(0, 4),
      blurRadius: 6,
      spreadRadius: 0,
    ),
  ];
}