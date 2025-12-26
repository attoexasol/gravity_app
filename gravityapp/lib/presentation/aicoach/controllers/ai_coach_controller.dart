import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../../../data/repositories/ai_coach_repository.dart';
import '../../../core/services/preferences_service.dart';

class AiCoachController extends GetxController {
  // Repository
  final AiCoachRepository _aiCoachRepository = AiCoachRepository();

  // Chat messages list
  final RxList<ChatMessage> messages = <ChatMessage>[].obs;

  // Scroll controller for messages list
  final ScrollController messagesScrollController = ScrollController();

  // Input state
  final RxString inputMessage = ''.obs;
  final RxBool isTyping = false.obs;
  final RxBool isSending = false.obs;
  final RxString errorMessage = ''.obs;

  // Text editing controller
  final TextEditingController messageController = TextEditingController();
  
  // Focus node to detect TextField focus state
  final FocusNode messageFocusNode = FocusNode();
  
  // Keyboard visibility state (true = keyboard is visible)
  // This will be updated by the screen widget based on MediaQuery.viewInsets
  final RxBool isKeyboardVisible = false.obs;

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

  // Storage key for AI coach messages
  static const String _messagesStorageKey = 'ai_coach_messages';

  @override
  void onInit() {
    super.onInit();
    // Load saved messages from storage, or show initial greeting if none exist
    _loadMessagesFromStorage();
    if (messages.isEmpty) {
      _loadInitialMessage();
    }
    // Scroll to bottom after messages are loaded to show most recent chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void onClose() {
    messageController.dispose();
    messageFocusNode.dispose();
    messagesScrollController.dispose();
    super.onClose();
  }
  
  /// ============================================
  /// ANIMATION STATE COMPUTATION
  /// ============================================
  /// Single source of truth for Quick Actions visibility
  /// Quick Actions are hidden when:
  /// - Keyboard is visible (user is typing)
  /// - AND TextField has focus (user is actively using the input)
  /// 
  /// This ensures Quick Actions only hide when the user is actually typing,
  /// not just when the keyboard happens to be open for other reasons.
  bool get shouldHideQuickActions {
    return isKeyboardVisible.value && messageFocusNode.hasFocus;
  }

  void _loadInitialMessage() {
    // Get logged-in user's name from storage
    final userName = PreferencesService.getUserName() ?? 'there';
    
    messages.add(
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: "Hello $userName! 👋 I'm your AI wellness coach. I'm here to help you reach your health goals. How are you feeling today?",
        sender: MessageSender.ai,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
    );
  }

  Future<void> sendMessage() async {
    if (inputMessage.value.trim().isEmpty) return;
    if (isSending.value) return; // Prevent duplicate calls

    // Get auth token
    final apiToken = PreferencesService.getAuthToken();
    if (apiToken == null || apiToken.isEmpty) {
      errorMessage.value = 'Please login to use AI Coach';
      Get.snackbar(
        'Authentication Required',
        'Please login to use AI Coach',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    // Add user message
    final messageText = inputMessage.value.trim();
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: messageText,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    );

    messages.add(userMessage);
    _saveMessagesToStorage(); // Save to local storage
    _scrollToBottom(); // Scroll to show most recent message

    // Clear input
    inputMessage.value = '';
    messageController.clear();

    // Show typing indicator
    isTyping.value = true;
    isSending.value = true;
    errorMessage.value = '';

    try {
      // Call AI Coach API
      final response = await _aiCoachRepository.getAiCoachReply(
        apiToken: apiToken,
        message: messageText,
      );

      if (response.isSuccess && response.data != null) {
        // Extract AI reply from response
        // API Response format: { "success": true, "data": { "from_user": number, "user_message": string, "ai_coach_reply": string } }
        final aiReply = response.data!['ai_coach_reply'] as String?;
        
        if (aiReply != null && aiReply.isNotEmpty) {
          final aiResponse = ChatMessage(
            id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
            text: aiReply,
            sender: MessageSender.ai,
            timestamp: DateTime.now(),
          );

          messages.add(aiResponse);
          _saveMessagesToStorage(); // Save to local storage
          _scrollToBottom(); // Scroll to show most recent message
          debugPrint('✅ AI Coach reply added to chat: ${aiReply.substring(0, aiReply.length > 50 ? 50 : aiReply.length)}...');
        } else {
          // Fallback if ai_coach_reply is missing or empty
          final errorResponse = ChatMessage(
            id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
            text: 'I apologize, but I couldn\'t generate a response. Please try again.',
            sender: MessageSender.ai,
            timestamp: DateTime.now(),
          );
          messages.add(errorResponse);
          _saveMessagesToStorage(); // Save to local storage
          debugPrint('⚠️ AI Coach reply is empty or missing in response');
        }
      } else {
        // Show error message
        errorMessage.value = response.message.isNotEmpty 
            ? response.message 
            : 'Failed to get AI response. Please try again.';
        
        // Add error message to chat
        final errorResponse = ChatMessage(
          id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
          text: 'Sorry, I encountered an error. Please try again.',
          sender: MessageSender.ai,
          timestamp: DateTime.now(),
        );
        messages.add(errorResponse);
        _saveMessagesToStorage(); // Save to local storage

        Get.snackbar(
          'Error',
          errorMessage.value,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      debugPrint('❌ Error sending message to AI Coach: $e');
      errorMessage.value = 'An unexpected error occurred. Please try again.';
      
      // Add error message to chat
      final errorResponse = ChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        text: 'Sorry, I encountered an error. Please try again.',
        sender: MessageSender.ai,
        timestamp: DateTime.now(),
      );
      messages.add(errorResponse);
      _saveMessagesToStorage(); // Save to local storage

      Get.snackbar(
        'Error',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isTyping.value = false;
      isSending.value = false;
    }
  }

  /// Save messages to local storage
  void _saveMessagesToStorage() {
    try {
      final storage = PreferencesService.getStorage();
      final messagesJson = messages.map((message) => {
        'id': message.id,
        'text': message.text,
        'sender': message.sender == MessageSender.user ? 'user' : 'ai',
        'timestamp': message.timestamp.toIso8601String(),
      }).toList();
      
      storage.write(_messagesStorageKey, jsonEncode(messagesJson));
      debugPrint('✅ Saved ${messages.length} AI Coach messages to storage');
    } catch (e) {
      debugPrint('⚠️ Error saving AI Coach messages to storage: $e');
    }
  }

  /// Load messages from local storage
  void _loadMessagesFromStorage() {
    try {
      final storage = PreferencesService.getStorage();
      final messagesJsonString = storage.read(_messagesStorageKey) as String?;
      
      if (messagesJsonString != null && messagesJsonString.isNotEmpty) {
        final messagesJson = jsonDecode(messagesJsonString) as List<dynamic>;
        messages.clear();
        
        for (final messageData in messagesJson) {
          if (messageData is Map<String, dynamic>) {
            final sender = messageData['sender'] == 'user' 
                ? MessageSender.user 
                : MessageSender.ai;
            final timestamp = DateTime.parse(messageData['timestamp'] as String);
            
            messages.add(
              ChatMessage(
                id: messageData['id'] as String,
                text: messageData['text'] as String,
                sender: sender,
                timestamp: timestamp,
              ),
            );
          }
        }
        
        // Sort messages by timestamp (oldest first, newest last) to ensure chronological order
        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        
        messages.refresh();
        debugPrint('✅ Loaded ${messages.length} AI Coach messages from storage');
      } else {
        debugPrint('ℹ️ No saved AI Coach messages found in storage');
      }
    } catch (e) {
      debugPrint('⚠️ Error loading AI Coach messages from storage: $e');
      // If loading fails, ensure messages list is empty so initial message can be shown
      messages.clear();
    }
  }

  /// Scroll to bottom of messages list to show most recent chat
  void _scrollToBottom() {
    if (!messagesScrollController.hasClients) return;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!messagesScrollController.hasClients) return;
      
      final position = messagesScrollController.position;
      final maxScroll = position.maxScrollExtent;
      
      // Scroll to bottom to show most recent messages
      messagesScrollController.animateTo(
        maxScroll,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  /// Clear all messages from storage (useful for logout or reset)
  void clearMessages() {
    messages.clear();
    final storage = PreferencesService.getStorage();
    storage.remove(_messagesStorageKey);
    debugPrint('✅ Cleared AI Coach messages from storage');
  }

  void handleQuickAction(String label) {
    // Map quick action labels to appropriate messages
    String message;
    switch (label.toLowerCase()) {
      case 'weight tips':
        message = 'Give me weight management tips';
        break;
      case 'hydration':
        message = 'Tell me about hydration';
        break;
      case 'sleep better':
        message = 'How can I sleep better?';
        break;
      case 'meal ideas':
        message = 'Give me meal ideas';
        break;
      default:
        message = 'Tell me about ${label.toLowerCase()}';
    }

    inputMessage.value = message;
    messageController.text = inputMessage.value;

    // Auto-send after brief delay
    Future.delayed(const Duration(milliseconds: 100), () {
      sendMessage();
    });
  }

  // Removed _getAiResponse - now using API instead of mock responses

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