import 'package:flutter/material.dart';
import 'dart:io';

enum MessageSender { user, ai }

class ChatMessage {
  final String id;
  final String? text; // Made optional to support image-only messages
  final String? imagePath; // Local file path for images
  final MessageSender sender;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    this.text,
    this.imagePath,
    required this.sender,
    required this.timestamp,
  });

  // Helper getters
  bool get hasText => text != null && text!.isNotEmpty;
  bool get hasImage => imagePath != null && imagePath!.isNotEmpty;
  bool get isEmpty => !hasText && !hasImage;
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