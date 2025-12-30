import 'package:flutter/material.dart';

enum MessageSender { user, ai }

class ChatMessage {
  final String id;
  final String text;
  final MessageSender sender;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
  });
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