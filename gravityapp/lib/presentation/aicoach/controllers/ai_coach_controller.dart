import 'package:get/get.dart';
import 'package:flutter/material.dart';

class AiCoachController extends GetxController {
  // Chat messages list
  final RxList<ChatMessage> messages = <ChatMessage>[].obs;

  // Input state
  final RxString inputMessage = ''.obs;
  final RxBool isTyping = false.obs;

  // Text editing controller
  final TextEditingController messageController = TextEditingController();

  // Quick actions
  final List<QuickAction> quickActions = [
    QuickAction(
      icon: Icons.trending_up,
      label: 'Weight Tips',
      gradient: const [Color(0xFFD4AF37), Color(0xFFC9A02C)],
    ),
    QuickAction(
      icon: Icons.water_drop,
      label: 'Hydration',
      gradient: const [Color(0xFF00B8A9), Color(0xFF00A89A)],
    ),
    QuickAction(
      icon: Icons.bedtime,
      label: 'Sleep Better',
      gradient: const [Color(0xFF6C63FF), Color(0xFF5A52E0)],
    ),
    QuickAction(
      icon: Icons.restaurant,
      label: 'Meal Ideas',
      gradient: const [Color(0xFFF9A71F), Color(0xFFF57C00)],
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    _loadInitialMessage();
  }

  @override
  void onClose() {
    messageController.dispose();
    super.onClose();
  }

  void _loadInitialMessage() {
    messages.add(
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: "Hello Sarah! 👋 I'm your AI wellness coach. I'm here to help you reach your health goals. How are you feeling today?",
        sender: MessageSender.ai,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
    );
  }

  void sendMessage() {
    if (inputMessage.value.trim().isEmpty) return;

    // Add user message
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: inputMessage.value.trim(),
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    );

    messages.add(userMessage);

    // Clear input
    final messageText = inputMessage.value.trim();
    inputMessage.value = '';
    messageController.clear();

    // Show typing indicator
    isTyping.value = true;

    // Simulate AI response
    Future.delayed(const Duration(milliseconds: 1500), () {
      final aiResponse = ChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        text: _getAiResponse(messageText),
        sender: MessageSender.ai,
        timestamp: DateTime.now(),
      );

      messages.add(aiResponse);
      isTyping.value = false;
    });
  }

  void handleQuickAction(String label) {
    inputMessage.value = 'Tell me about ${label.toLowerCase()}';
    messageController.text = inputMessage.value;

    // Auto-send after brief delay
    Future.delayed(const Duration(milliseconds: 100), () {
      sendMessage();
    });
  }

  String _getAiResponse(String userMessage) {
    final msg = userMessage.toLowerCase();

    if (msg.contains('weight') || msg.contains('lose')) {
      return "Great question about weight management! Based on your current progress, you're doing well. I recommend focusing on consistent hydration and getting 7-8 hours of sleep. Small, sustainable changes work best! 💪";
    }

    if (msg.contains('sleep')) {
      return "Sleep is crucial for your wellness journey! Try to maintain a consistent bedtime routine, avoid screens 1 hour before bed, and keep your room cool and dark. You're currently averaging 6.5 hours - let's work towards 8 hours! 🌙";
    }

    if (msg.contains('water') || msg.contains('hydration')) {
      return "Hydration is key! You're currently at 1.2L today. I recommend spreading your water intake throughout the day. Try having a glass when you wake up, before meals, and keeping a bottle nearby. Goal: 2.5L daily! 💧";
    }

    if (msg.contains('meal') || msg.contains('food') || msg.contains('eat')) {
      return "Nutrition is essential! Focus on balanced meals with lean proteins, whole grains, and plenty of vegetables. I can analyze your meal photos to provide personalized recommendations. Upload your next meal and I'll help! 🍎";
    }

    if (msg.contains('exercise') || msg.contains('workout') || msg.contains('activity')) {
      return "Physical activity is wonderful for your health! Based on your current activity level, I suggest starting with 30 minutes of moderate exercise 5 times per week. Mix cardio and strength training for best results! 🏃‍♀️";
    }

    if (msg.contains('stress') || msg.contains('anxiety') || msg.contains('mental')) {
      return "Mental health is just as important as physical health! Try incorporating 10 minutes of meditation daily, practice deep breathing exercises, and ensure you're getting quality sleep. I'm here to support you! 🧘‍♀️";
    }

    if (msg.contains('progress') || msg.contains('how am i doing')) {
      return "You're making fantastic progress! You've been consistent with tracking for 7 days straight. Your hydration is improving, and your sleep quality is trending upward. Keep up the great work! 📈";
    }

    // Default response
    return "I'm here to help with your wellness journey! Feel free to ask me about your weight goals, sleep patterns, hydration, nutrition, exercise routines, or mental wellness. What would you like to focus on? 🌟";
  }

  String formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

// Models
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