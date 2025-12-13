import 'package:get/get.dart';
import 'package:flutter/material.dart';

class MessagesController extends GetxController {
  // Current view state
  final RxString selectedConversationId = ''.obs;
  final RxString searchQuery = ''.obs;
  final RxString messageInput = ''.obs;
  final RxBool isTyping = false.obs;

  // Text editing controller
  final TextEditingController messageController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  // Conversations list
  final RxList<Conversation> conversations = <Conversation>[].obs;

  // User type
  final RxString userType = 'customer'.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserType();
    _loadConversations();
  }

  @override
  void onClose() {
    messageController.dispose();
    searchController.dispose();
    super.onClose();
  }

  void _loadUserType() {
    // TODO: Load from PreferencesService or AuthService
    userType.value = 'customer'; // Default
  }

  void _loadConversations() {
    if (userType.value == 'customer') {
      conversations.value = [
        Conversation(
          id: '1',
          name: 'Coach Emily',
          avatar: '👩‍⚕️',
          lastMessage: 'Great job on your water intake today!',
          timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
          unreadCount: 2,
          role: ConversationRole.coach,
          messages: [
            Message(
              id: 'm1',
              senderId: 'coach-emily',
              text: 'Hi Sarah! How are you feeling today?',
              timestamp: DateTime.now().subtract(const Duration(hours: 3)),
              isRead: true,
              isSent: false,
            ),
            Message(
              id: 'm2',
              senderId: 'me',
              text: 'Feeling great! Just finished my morning workout.',
              timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 30)),
              isRead: true,
              isSent: true,
            ),
            Message(
              id: 'm3',
              senderId: 'coach-emily',
              text: "That's wonderful! I noticed you're staying consistent with your hydration. Keep it up! 💧",
              timestamp: DateTime.now().subtract(const Duration(hours: 2)),
              isRead: true,
              isSent: false,
            ),
            Message(
              id: 'm4',
              senderId: 'me',
              text: 'Thank you! The reminders really help.',
              timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
              isRead: true,
              isSent: true,
            ),
            Message(
              id: 'm5',
              senderId: 'coach-emily',
              text: "I reviewed your meal logs from this week. You're doing an amazing job with portion control!",
              timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
              isRead: true,
              isSent: false,
            ),
            Message(
              id: 'm6',
              senderId: 'coach-emily',
              text: 'Great job on your water intake today!',
              timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
              isRead: false,
              isSent: false,
            ),
          ],
        ),
        Conversation(
          id: '2',
          name: 'Coach Marcus',
          avatar: '👨‍⚕️',
          lastMessage: "Let's discuss your meal plan for next week",
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          unreadCount: 0,
          role: ConversationRole.coach,
          messages: [
            Message(
              id: 'm1',
              senderId: 'coach-marcus',
              text: "Good morning! Ready to plan next week's meals?",
              timestamp: DateTime.now().subtract(const Duration(hours: 4)),
              isRead: true,
              isSent: false,
            ),
            Message(
              id: 'm2',
              senderId: 'me',
              text: "Yes! I'd like to add more protein to my diet.",
              timestamp: DateTime.now().subtract(const Duration(hours: 3, minutes: 30)),
              isRead: true,
              isSent: true,
            ),
            Message(
              id: 'm3',
              senderId: 'coach-marcus',
              text: "Perfect! Let's discuss your meal plan for next week. I'll send you some recipes.",
              timestamp: DateTime.now().subtract(const Duration(hours: 2)),
              isRead: true,
              isSent: false,
            ),
          ],
        ),
      ];
    } else {
      // Coach conversations
      conversations.value = [
        Conversation(
          id: '1',
          name: 'Sarah Johnson',
          avatar: '👤',
          lastMessage: 'Thanks for the tips!',
          timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
          unreadCount: 1,
          role: ConversationRole.customer,
          messages: [
            Message(
              id: 'm1',
              senderId: 'me',
              text: "Hi Sarah! I noticed you're doing really well with your sleep tracking.",
              timestamp: DateTime.now().subtract(const Duration(hours: 2)),
              isRead: true,
              isSent: true,
            ),
            Message(
              id: 'm2',
              senderId: 'sarah',
              text: 'Thank you! Your advice about a consistent bedtime routine really helped.',
              timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
              isRead: true,
              isSent: false,
            ),
            Message(
              id: 'm3',
              senderId: 'me',
              text: "That's great to hear! Keep maintaining that routine and you'll see even better results.",
              timestamp: DateTime.now().subtract(const Duration(hours: 1)),
              isRead: true,
              isSent: true,
            ),
            Message(
              id: 'm4',
              senderId: 'sarah',
              text: 'Will do! Also, I tried the meal prep tips you sent.',
              timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
              isRead: true,
              isSent: false,
            ),
            Message(
              id: 'm5',
              senderId: 'sarah',
              text: 'Thanks for the tips!',
              timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
              isRead: false,
              isSent: false,
            ),
          ],
        ),
        Conversation(
          id: '2',
          name: 'Michael Chen',
          avatar: '👤',
          lastMessage: "I'm struggling with sleep tracking",
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
          unreadCount: 3,
          role: ConversationRole.customer,
          messages: [
            Message(
              id: 'm1',
              senderId: 'michael',
              text: 'Hi Coach! I have a question about the app.',
              timestamp: DateTime.now().subtract(const Duration(hours: 2)),
              isRead: true,
              isSent: false,
            ),
            Message(
              id: 'm2',
              senderId: 'michael',
              text: "I'm struggling with sleep tracking. It doesn't seem to sync properly.",
              timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
              isRead: false,
              isSent: false,
            ),
            Message(
              id: 'm3',
              senderId: 'michael',
              text: 'Can you help me troubleshoot?',
              timestamp: DateTime.now().subtract(const Duration(hours: 1)),
              isRead: false,
              isSent: false,
            ),
          ],
        ),
        Conversation(
          id: '3',
          name: 'Emma Davis',
          avatar: '👤',
          lastMessage: 'My weight goal progress is amazing!',
          timestamp: DateTime.now().subtract(const Duration(hours: 5)),
          unreadCount: 0,
          role: ConversationRole.customer,
          messages: [
            Message(
              id: 'm1',
              senderId: 'me',
              text: 'Emma, I wanted to check in on your progress this week.',
              timestamp: DateTime.now().subtract(const Duration(hours: 8)),
              isRead: true,
              isSent: true,
            ),
            Message(
              id: 'm2',
              senderId: 'emma',
              text: "Hi Coach! I'm doing really well!",
              timestamp: DateTime.now().subtract(const Duration(hours: 6)),
              isRead: true,
              isSent: false,
            ),
            Message(
              id: 'm3',
              senderId: 'emma',
              text: 'My weight goal progress is amazing!',
              timestamp: DateTime.now().subtract(const Duration(hours: 5)),
              isRead: true,
              isSent: false,
            ),
          ],
        ),
      ];
    }
  }

  // Filtered conversations based on search
  List<Conversation> get filteredConversations {
    if (searchQuery.value.isEmpty) {
      return conversations;
    }
    return conversations
        .where((conv) =>
        conv.name.toLowerCase().contains(searchQuery.value.toLowerCase()))
        .toList();
  }

  // Get current conversation
  Conversation? get currentConversation {
    if (selectedConversationId.value.isEmpty) return null;
    try {
      return conversations.firstWhere((c) => c.id == selectedConversationId.value);
    } catch (e) {
      return null;
    }
  }

  // Total unread count
  int get totalUnreadCount {
    return conversations.fold(0, (sum, conv) => sum + conv.unreadCount);
  }

  // Select conversation
  void selectConversation(String conversationId) {
    selectedConversationId.value = conversationId;

    // Mark messages as read
    final convIndex = conversations.indexWhere((c) => c.id == conversationId);
    if (convIndex != -1) {
      final conv = conversations[convIndex];
      conversations[convIndex] = conv.copyWith(
        unreadCount: 0,
        messages: conv.messages.map((m) => m.copyWith(isRead: true)).toList(),
      );
    }
  }

  // Close conversation
  void closeConversation() {
    selectedConversationId.value = '';
    messageInput.value = '';
    messageController.clear();
  }

  // Send message
  void sendMessage() {
    if (messageInput.value.trim().isEmpty || selectedConversationId.value.isEmpty) {
      return;
    }

    final convIndex = conversations.indexWhere((c) => c.id == selectedConversationId.value);
    if (convIndex == -1) return;

    final conv = conversations[convIndex];
    final newMessage = Message(
      id: 'm-${DateTime.now().millisecondsSinceEpoch}',
      senderId: 'me',
      text: messageInput.value.trim(),
      timestamp: DateTime.now(),
      isRead: true,
      isSent: true,
    );

    // Update conversation
    conversations[convIndex] = conv.copyWith(
      messages: [...conv.messages, newMessage],
      lastMessage: newMessage.text,
      timestamp: newMessage.timestamp,
    );

    // Clear input
    messageInput.value = '';
    messageController.clear();

    // Simulate typing and response
    isTyping.value = true;
    Future.delayed(const Duration(seconds: 2), () {
      isTyping.value = false;

      final autoReply = Message(
        id: 'm-auto-${DateTime.now().millisecondsSinceEpoch}',
        senderId: 'other',
        text: _getAutoReply(),
        timestamp: DateTime.now(),
        isRead: false,
        isSent: false,
      );

      final currentConvIndex = conversations.indexWhere((c) => c.id == selectedConversationId.value);
      if (currentConvIndex != -1) {
        final currentConv = conversations[currentConvIndex];
        conversations[currentConvIndex] = currentConv.copyWith(
          messages: [...currentConv.messages, autoReply],
          lastMessage: autoReply.text,
          timestamp: autoReply.timestamp,
        );
      }
    });
  }

  String _getAutoReply() {
    final replies = [
      "Thanks for your message! I'll get back to you soon.",
      "That's great to hear! Keep up the good work! 💪",
      "I've received your message and will review it shortly.",
      "Absolutely! I'll help you with that.",
      "Great question! Let me look into that for you.",
    ];
    return replies[DateTime.now().millisecond % replies.length];
  }

  // Format time for conversation list
  String formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }

  // Format time for messages
  String formatMessageTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final hourStr = hour == 0 ? '12' : hour.toString();
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hourStr:$minute $period';
  }
}

// Models
enum ConversationRole { customer, coach }

class Conversation {
  final String id;
  final String name;
  final String avatar;
  final String lastMessage;
  final DateTime timestamp;
  final int unreadCount;
  final ConversationRole role;
  final List<Message> messages;

  Conversation({
    required this.id,
    required this.name,
    required this.avatar,
    required this.lastMessage,
    required this.timestamp,
    required this.unreadCount,
    required this.role,
    required this.messages,
  });

  Conversation copyWith({
    String? id,
    String? name,
    String? avatar,
    String? lastMessage,
    DateTime? timestamp,
    int? unreadCount,
    ConversationRole? role,
    List<Message>? messages,
  }) {
    return Conversation(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      lastMessage: lastMessage ?? this.lastMessage,
      timestamp: timestamp ?? this.timestamp,
      unreadCount: unreadCount ?? this.unreadCount,
      role: role ?? this.role,
      messages: messages ?? this.messages,
    );
  }
}

class Message {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool isRead;
  final bool isSent;

  Message({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    required this.isRead,
    required this.isSent,
  });

  Message copyWith({
    String? id,
    String? senderId,
    String? text,
    DateTime? timestamp,
    bool? isRead,
    bool? isSent,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      isSent: isSent ?? this.isSent,
    );
  }
}