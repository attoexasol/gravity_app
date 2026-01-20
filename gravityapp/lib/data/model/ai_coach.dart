import 'package:flutter/material.dart';
import 'dart:io';

enum MessageSender { user, ai }

class ChatMessage {
  final String id;
  final String? text; // Made optional to support image-only messages
  final String? imagePath; // Local file path for images
  final String? imageUrl; // Network URL for images from server
  final MessageSender sender;
  final DateTime timestamp;
  final int? nutrition; // Nutrition value (calories) from image analysis (image mode only)

  ChatMessage({
    required this.id,
    this.text,
    this.imagePath,
    this.imageUrl,
    required this.sender,
    required this.timestamp,
    this.nutrition,
  });

  // Helper getters
  bool get hasText => text != null && text!.isNotEmpty;
  bool get hasImage => (imagePath != null && imagePath!.isNotEmpty) || (imageUrl != null && imageUrl!.isNotEmpty);
  bool get isEmpty => !hasText && !hasImage;
  bool get hasNutrition => nutrition != null && nutrition! > 0;
}

class QuickAction {
  final IconData icon;
  final String label;
  final List<Color> gradient;

  QuickAction({
    required this.icon,
    required this.label,
    required this.gradient,
  });
}