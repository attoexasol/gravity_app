import 'package:flutter/material.dart';

class OnboardingSlideModel {
  final String title;
  final String subtitle;
  final String description;
  final String? tagline;
  final List<Color> gradientColors;

  const OnboardingSlideModel({
    required this.title,
    required this.subtitle,
    required this.description,
    this.tagline,
    required this.gradientColors,
  });
}
