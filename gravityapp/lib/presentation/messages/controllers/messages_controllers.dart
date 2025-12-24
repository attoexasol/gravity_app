import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../data/repositories/messages_repository.dart';
import '../../../core/services/preferences_service.dart';
import '../../../data/model/api_response.dart';

class MessagesController extends GetxController {
  // Repository
  final MessagesRepository _messagesRepository = MessagesRepository();

  // Current view state
  final RxString selectedConversationId = ''.obs;
  final RxString searchQuery = ''.obs;
  final RxString messageInput = ''.obs;
  final RxBool isTyping = false.obs;
  final RxBool isLoadingConversations = false.obs;
  final RxBool isLoadingMessages = false.obs;

  // Text editing controller
  final TextEditingController messageController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController editMessageController = TextEditingController();

  // Edit message state
  final RxString editingMessageId = ''.obs;
  final RxString editMessageText = ''.obs;
  final RxBool isUpdatingMessage = false.obs;
  final RxString updateMessageError = ''.obs;

  // Delete message state
  final RxBool isDeletingMessage = false.obs;
  final RxString deleteMessageError = ''.obs;

  // Conversations list
  final RxList<Conversation> conversations = <Conversation>[].obs;

  // User type and current user ID
  final RxString userType = 'customer'.obs;
  int? _currentUserId;
  
  // Map to store conversation partner user IDs
  final Map<String, int> _conversationUserIds = {};
  
  // Map to store user names
  final Map<int, String> _userNames = {};
  
  // Map to store user profile images
  final Map<int, String> _userProfileImages = {};

  @override
  void onInit() {
    super.onInit();
    _loadUserType();
    _loadCurrentUserId();
    _loadConversations();
  }

  @override
  @override
  void onClose() {
    messageController.dispose();
    searchController.dispose();
    editMessageController.dispose();
    super.onClose();
  }

  void _loadUserType() {
    final storedUserType = PreferencesService.getUserType();
    if (storedUserType != null && storedUserType.isNotEmpty) {
      userType.value = storedUserType.toLowerCase();
    } else {
      userType.value = 'customer'; // Default
    }
    debugPrint('📱 Messages: User type loaded: ${userType.value}');
  }

  void _loadCurrentUserId() {
    _currentUserId = PreferencesService.getUserId();
    debugPrint('📱 Messages: Current user ID: $_currentUserId');
  }

  Future<void> _loadConversations() async {
    if (_currentUserId == null) {
      debugPrint('❌ Messages: No user ID found');
      return;
    }

    try {
      isLoadingConversations.value = true;
      
      // Determine which role to fetch (opposite of current user)
      final targetRole = userType.value == 'customer' ? 'coach' : 'customer';
      
      debugPrint('📱 Messages: Loading $targetRole users for ${userType.value}');

      // Try to get list of users (coaches or customers)
      final usersResponse = await _messagesRepository.getAllUsers(role: targetRole);
      
      if (usersResponse.isSuccess && usersResponse.data != null && usersResponse.data!.isNotEmpty) {
        // Load conversations for each user
        final List<Conversation> loadedConversations = [];
        
        for (final userData in usersResponse.data!) {
          final otherUserId = userData['id'] ?? userData['user_id'];
          if (otherUserId == null) continue;
          
          final otherUserIdInt = otherUserId is int ? otherUserId : int.tryParse(otherUserId.toString());
          if (otherUserIdInt == null) continue;
          
          // Load messages for this user
          await _loadConversationForUser(otherUserIdInt, userData);
        }
      } else {
        debugPrint('⚠️ Messages: No users found or API error. Building conversations from existing messages...');
        // If we can't get users list, we'll build conversations from messages
        // This would require getting all messages and extracting unique user IDs
        // For now, show empty state
        conversations.value = [];
      }
    } catch (e) {
      debugPrint('❌ Messages: Error loading conversations: $e');
      Get.snackbar(
        'Error',
        'Failed to load conversations. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoadingConversations.value = false;
    }
  }

  Future<void> _loadConversationForUser(int otherUserId, Map<String, dynamic>? userData) async {
    try {
      // Get messages with this user
      final messagesResponse = await _messagesRepository.getAllMessages(otherUserId: otherUserId);
      
      if (messagesResponse.isSuccess && messagesResponse.data != null) {
        final allMessages = messagesResponse.data!;
        
        // Filter messages to only include messages between current user and otherUserId
        // A message belongs to this conversation if:
        // - from_user_id is current user AND to_user_id is otherUserId, OR
        // - from_user_id is otherUserId AND to_user_id is current user
        final filteredMessages = allMessages.where((msg) {
          // Handle both API response formats: direct fields or nested user objects
          final fromUserId = msg['from_user_id'] ?? msg['from_user']?['id'];
          final toUserId = msg['to_user_id'] ?? msg['to_user']?['id'];
          
          // Convert to integers for comparison
          int? fromUserIdInt;
          int? toUserIdInt;
          
          if (fromUserId is int) {
            fromUserIdInt = fromUserId;
          } else if (fromUserId != null) {
            fromUserIdInt = int.tryParse(fromUserId.toString());
          }
          
          if (toUserId is int) {
            toUserIdInt = toUserId;
          } else if (toUserId != null) {
            toUserIdInt = int.tryParse(toUserId.toString());
          }
          
          // If we can't parse user IDs or current user ID is null, skip this message
          if (fromUserIdInt == null || toUserIdInt == null || _currentUserId == null) {
            return false;
          }
          
          // Message is part of this conversation if it's between current user and otherUserId
          final isFromCurrentToOther = fromUserIdInt == _currentUserId && toUserIdInt == otherUserId;
          final isFromOtherToCurrent = fromUserIdInt == otherUserId && toUserIdInt == _currentUserId;
          
          return isFromCurrentToOther || isFromOtherToCurrent;
        }).toList();
        
        debugPrint('📱 Filtered ${filteredMessages.length} messages for conversation with user $otherUserId (from ${allMessages.length} total)');
        
        // Extract user name from userData or messages
        String userName = _extractUserName(userData, filteredMessages, otherUserId);
        String? profileImage = _extractProfileImage(userData, filteredMessages, otherUserId);
        
        // Map messages to Message models
        final mappedMessages = filteredMessages.map((msg) => _mapApiMessageToMessage(msg)).toList();
        
        // Sort messages by timestamp
        mappedMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        
        // Determine last message and timestamp
        String lastMessageText = 'No messages yet';
        DateTime lastTimestamp = DateTime.now();
        int unreadCount = 0;
        
        if (mappedMessages.isNotEmpty) {
          final lastMsg = mappedMessages.last;
          lastMessageText = lastMsg.text;
          lastTimestamp = lastMsg.timestamp;
          
          // Count unread messages (messages not sent by current user and not read)
          unreadCount = mappedMessages.where((m) => !m.isSent && !m.isRead).length;
        }
        
        // Create conversation
        final conversationId = 'conv_$otherUserId';
        _conversationUserIds[conversationId] = otherUserId;
        _userNames[otherUserId] = userName;
        if (profileImage != null && profileImage.isNotEmpty) {
          _userProfileImages[otherUserId] = profileImage;
        }
        
        final conversation = Conversation(
          id: conversationId,
          name: userName,
          avatar: _getAvatarForUser(otherUserId, profileImage),
          lastMessage: lastMessageText,
          timestamp: lastTimestamp,
          unreadCount: unreadCount,
          role: userType.value == 'customer' ? ConversationRole.coach : ConversationRole.customer,
          messages: mappedMessages,
        );
        
        // Add or update conversation
        final existingIndex = conversations.indexWhere((c) => c.id == conversationId);
        if (existingIndex != -1) {
          conversations[existingIndex] = conversation;
        } else {
          conversations.add(conversation);
        }
      } else if (userData != null) {
        // No messages yet, but create empty conversation
        final userName = _extractUserName(userData, [], otherUserId);
        String? profileImage = _extractProfileImage(userData, [], otherUserId);
        
        final conversationId = 'conv_$otherUserId';
        _conversationUserIds[conversationId] = otherUserId;
        _userNames[otherUserId] = userName;
        if (profileImage != null && profileImage.isNotEmpty) {
          _userProfileImages[otherUserId] = profileImage;
        }
        
        final conversation = Conversation(
          id: conversationId,
          name: userName,
          avatar: _getAvatarForUser(otherUserId, profileImage),
          lastMessage: 'No messages yet',
          timestamp: DateTime.now(),
          unreadCount: 0,
          role: userType.value == 'customer' ? ConversationRole.coach : ConversationRole.customer,
          messages: [],
        );
        
        conversations.add(conversation);
      }
    } catch (e) {
      debugPrint('❌ Messages: Error loading conversation for user $otherUserId: $e');
    }
  }

  String _extractUserName(Map<String, dynamic>? userData, List<Map<String, dynamic>> messages, int userId) {
    // Try to get name from userData first
    if (userData != null) {
      final name = userData['name'] ?? userData['user_name'] ?? userData['full_name'];
      if (name != null && name.toString().isNotEmpty) {
        debugPrint('👤 Messages: User name from userData for user $userId: $name');
        return name.toString();
      }
    }
    
    // Try to extract from messages
    for (final msg in messages) {
      // Check from_user
      final fromUserId = msg['from_user_id'] ?? msg['from_user']?['id'];
      if (fromUserId == userId) {
        final name = msg['from_user']?['name'] ?? msg['from_user']?['user_name'] ?? msg['from_user_name'];
        if (name != null && name.toString().isNotEmpty) {
          debugPrint('👤 Messages: User name from message (from_user) for user $userId: $name');
          return name.toString();
        }
      }
      // Check to_user
      final toUserId = msg['to_user_id'] ?? msg['to_user']?['id'];
      if (toUserId == userId) {
        final name = msg['to_user']?['name'] ?? msg['to_user']?['user_name'] ?? msg['to_user_name'];
        if (name != null && name.toString().isNotEmpty) {
          debugPrint('👤 Messages: User name from message (to_user) for user $userId: $name');
          return name.toString();
        }
      }
    }
    
    debugPrint('⚠️ Messages: No user name found for user $userId, using fallback');
    // Fallback
    return 'User $userId';
  }

  String? _extractProfileImage(Map<String, dynamic>? userData, List<Map<String, dynamic>> messages, int userId) {
    // Try to get profile image from userData first
    if (userData != null) {
      final profileImage = userData['profile_image'] ?? userData['profile_image_url'];
      if (profileImage != null && profileImage.toString().isNotEmpty) {
        debugPrint('📸 Messages: Profile image from userData for user $userId: $profileImage');
        return profileImage.toString();
      }
    }
    
    // Try to extract from messages
    for (final msg in messages) {
      // Check from_user
      final fromUserId = msg['from_user_id'] ?? msg['from_user']?['id'];
      if (fromUserId == userId) {
        final profileImage = msg['from_user']?['profile_image'] ?? msg['from_user']?['profile_image_url'];
        if (profileImage != null && profileImage.toString().isNotEmpty) {
          debugPrint('📸 Messages: Profile image from message (from_user) for user $userId: $profileImage');
          return profileImage.toString();
        }
      }
      // Check to_user
      final toUserId = msg['to_user_id'] ?? msg['to_user']?['id'];
      if (toUserId == userId) {
        final profileImage = msg['to_user']?['profile_image'] ?? msg['to_user']?['profile_image_url'];
        if (profileImage != null && profileImage.toString().isNotEmpty) {
          debugPrint('📸 Messages: Profile image from message (to_user) for user $userId: $profileImage');
          return profileImage.toString();
        }
      }
    }
    
    debugPrint('⚠️ Messages: No profile image found for user $userId, using default avatar');
    // Fallback - return null, will use default avatar
    return null;
  }

  Message _mapApiMessageToMessage(Map<String, dynamic> json) {
    final messageId = json['id']?.toString() ?? json['message_id']?.toString() ?? '';
    final fromUserId = json['from_user_id'] ?? json['from_user']?['id'] ?? json['from_user_id'];
    final messageText = json['message'] ?? json['message_content'] ?? json['text'] ?? '';
    
    // Determine if message is sent by current user
    final isSent = fromUserId == _currentUserId;
    
    // Parse timestamp and convert to local time
    DateTime timestamp = DateTime.now();
    if (json['created_at'] != null) {
      try {
        final parsedTime = DateTime.parse(json['created_at'].toString());
        // Convert UTC to local time if the timestamp is in UTC
        timestamp = parsedTime.isUtc ? parsedTime.toLocal() : parsedTime;
      } catch (e) {
        debugPrint('⚠️ Messages: Error parsing timestamp: $e');
        timestamp = DateTime.now(); // Fallback to current time
      }
    }
    
    return Message(
      id: messageId,
      senderId: fromUserId?.toString() ?? 'unknown',
      text: messageText.toString(),
      timestamp: timestamp,
      isRead: json['is_read'] ?? json['read'] ?? false,
      isSent: isSent,
    );
  }

  String _getAvatarForUser(int userId, String? profileImage) {
    if (profileImage != null && profileImage.isNotEmpty) {
      // Construct full URL if it's a relative path
      if (profileImage.startsWith('http://') || profileImage.startsWith('https://')) {
        return profileImage;
      } else {
        // Construct full URL for relative paths
        return 'https://gravity.attoexasolutions.com/storage/$profileImage';
      }
    }
    // Generate a simple emoji-based avatar based on user ID
    final emojis = ['👤', '👨', '👩', '👨‍⚕️', '👩‍⚕️', '🧑', '🧑‍⚕️'];
    return emojis[userId % emojis.length];
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

  // Get current conversation (reactive)
  Conversation? get currentConversation {
    if (selectedConversationId.value.isEmpty) return null;
    try {
      // Access conversations.value to make it reactive
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
    
    // Reload messages for this conversation
    final otherUserId = _conversationUserIds[conversationId];
    if (otherUserId != null) {
      _loadConversationForUser(otherUserId, null);
    }
  }

  // Close conversation
  void closeConversation() {
    selectedConversationId.value = '';
    messageInput.value = '';
    messageController.clear();
  }

  // Send message
  Future<void> sendMessage() async {
    if (messageInput.value.trim().isEmpty || selectedConversationId.value.isEmpty) {
      return;
    }

    final apiToken = PreferencesService.getAuthToken();
    if (apiToken == null || apiToken.isEmpty) {
      Get.snackbar(
        'Error',
        'Session expired. Please login again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    final otherUserId = _conversationUserIds[selectedConversationId.value];
    if (otherUserId == null) {
      Get.snackbar(
        'Error',
        'Invalid conversation. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    final convIndex = conversations.indexWhere((c) => c.id == selectedConversationId.value);
    if (convIndex == -1) return;

    final messageText = messageInput.value.trim();
    final messageContent = messageText; // Use same text for both fields

    // Create optimistic message
    final tempMessageId = 'temp-${DateTime.now().millisecondsSinceEpoch}';
    final optimisticMessage = Message(
      id: tempMessageId,
      senderId: _currentUserId?.toString() ?? 'me',
      text: messageText,
      timestamp: DateTime.now(),
      isRead: true,
      isSent: true,
    );

    // Update UI optimistically
    final conv = conversations[convIndex];
    final updatedConv = conv.copyWith(
      messages: [...conv.messages, optimisticMessage],
      lastMessage: optimisticMessage.text,
      timestamp: optimisticMessage.timestamp,
    );
    conversations[convIndex] = updatedConv;
    debugPrint('📤 Optimistic message added. Total messages: ${updatedConv.messages.length}');

    // Clear input immediately
    messageInput.value = '';
    messageController.clear();

    try {
      // Send to API
      final response = await _messagesRepository.createMessage(
        apiToken: apiToken,
        toUserId: otherUserId,
        message: messageText,
        messageContent: messageContent,
      );

      if (response.isSuccess && response.data != null) {
        // Replace optimistic message with real message from API
        final apiMessage = _mapApiMessageToMessage(response.data!);
        final currentConv = conversations[convIndex];
        final updatedMessages = currentConv.messages.map((m) {
          return m.id == tempMessageId ? apiMessage : m;
        }).toList();

        final finalConv = currentConv.copyWith(
          messages: updatedMessages,
          lastMessage: apiMessage.text,
          timestamp: apiMessage.timestamp,
        );
        conversations[convIndex] = finalConv;

        debugPrint('✅ Message sent successfully. Total messages: ${finalConv.messages.length}');
      } else {
        // Remove optimistic message on failure
        final currentConv = conversations[convIndex];
        final updatedMessages = currentConv.messages.where((m) => m.id != tempMessageId).toList();
        conversations[convIndex] = currentConv.copyWith(messages: updatedMessages);
        debugPrint('❌ Message send failed. Removed optimistic message.');

        Get.snackbar(
          'Error',
          response.message.isNotEmpty ? response.message : 'Failed to send message',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      debugPrint('❌ Error sending message: $e');
      
      // Remove optimistic message on error
      final currentConv = conversations[convIndex];
      final updatedMessages = currentConv.messages.where((m) => m.id != tempMessageId).toList();
      conversations[convIndex] = currentConv.copyWith(messages: updatedMessages);
      debugPrint('❌ Removed optimistic message due to error.');

      Get.snackbar(
        'Error',
        'Failed to send message. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
        duration: const Duration(seconds: 2),
      );
    }
  }

  // Reload conversations
  Future<void> reloadConversations() async {
    conversations.clear();
    _conversationUserIds.clear();
    _userNames.clear();
    await _loadConversations();
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

  // Format time for messages - shows actual time or relative time for recent messages
  String formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    
    // For messages sent less than 1 minute ago, show "Just now"
    if (diff.inSeconds < 60) {
      return 'Just now';
    }
    
    // For messages sent today, show time in 12-hour format
    if (dateTime.year == now.year && 
        dateTime.month == now.month && 
        dateTime.day == now.day) {
      final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
      final hourStr = hour.toString();
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = dateTime.hour >= 12 ? 'PM' : 'AM';
      return '$hourStr:$minute $period';
    }
    
    // For messages sent yesterday, show "Yesterday" with time
    final yesterday = now.subtract(const Duration(days: 1));
    if (dateTime.year == yesterday.year && 
        dateTime.month == yesterday.month && 
        dateTime.day == yesterday.day) {
      final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
      final hourStr = hour.toString();
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = dateTime.hour >= 12 ? 'PM' : 'AM';
      return 'Yesterday $hourStr:$minute $period';
    }
    
    // For older messages, show date and time
    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = monthNames[dateTime.month - 1];
    final day = dateTime.day;
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final hourStr = hour.toString();
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    
    // If same year, show month and day only
    if (dateTime.year == now.year) {
      return '$month $day, $hourStr:$minute $period';
    }
    
    // Otherwise show full date
    return '$month $day, ${dateTime.year} $hourStr:$minute $period';
  }

  // Check if message belongs to current user
  bool isCurrentUserMessage(Message message) {
    return message.isSent;
  }

  // Show message actions (edit/delete) bottom sheet
  void showMessageActions(String conversationId, Message message) {
    if (!isCurrentUserMessage(message)) return;

    Get.bottomSheet(
      Builder(
        builder: (BuildContext bottomSheetContext) {
          return Container(
            padding: EdgeInsets.all(24.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A2342).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                SizedBox(height: 24.h),
                ListTile(
                  leading: const Icon(Icons.edit, color: Color(0xFF00B8A9)),
                  title: const Text('Edit Message'),
                  onTap: () {
                    Navigator.of(bottomSheetContext).pop();
                    // Small delay to ensure bottom sheet closes before opening edit mode
                    Future.delayed(const Duration(milliseconds: 100), () {
                      startEditMessage(conversationId, message);
                    });
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Color(0xFFE53935)),
                  title: const Text('Delete Message'),
                  onTap: () {
                    Navigator.of(bottomSheetContext).pop();
                    // Small delay to ensure bottom sheet closes before opening confirmation dialog
                    Future.delayed(const Duration(milliseconds: 100), () {
                      showDeleteMessageConfirmation(conversationId, message);
                    });
                  },
                ),
                SizedBox(height: 16.h),
              ],
            ),
          );
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
    );
  }

  // Start editing a message
  void startEditMessage(String conversationId, Message message) {
    editingMessageId.value = message.id;
    editMessageText.value = message.text;
    editMessageController.text = message.text;
    updateMessageError.value = '';
  }

  // Close edit message mode
  void closeEditMessage() {
    editingMessageId.value = '';
    editMessageText.value = '';
    editMessageController.clear();
    updateMessageError.value = '';
  }

  // Update a message
  Future<bool> updateMessage(String conversationId) async {
    if (editMessageText.value.trim().isEmpty) return false;
    if (editingMessageId.value.isEmpty) return false;

    isUpdatingMessage.value = true;
    updateMessageError.value = '';

    try {
      final apiToken = PreferencesService.getAuthToken();
      if (apiToken == null || apiToken.isEmpty) {
        updateMessageError.value = 'Authentication required. Please login again.';
        debugPrint('❌ UpdateMessage Error: No auth token found');
        isUpdatingMessage.value = false;
        return false;
      }

      final messageId = int.tryParse(editingMessageId.value);
      if (messageId == null) {
        updateMessageError.value = 'Invalid message ID';
        isUpdatingMessage.value = false;
        return false;
      }

      debugPrint('🔄 Updating message via API...');
      debugPrint('   - Message ID: $messageId');
      debugPrint('   - New text: ${editMessageText.value}');

      final response = await _messagesRepository.updateMessage(
        apiToken: apiToken,
        messageId: messageId,
        message: editMessageText.value.trim(),
        messageContent: editMessageText.value.trim(),
      );

      if (response.isSuccess) {
        debugPrint('✅ Message updated successfully');

        // Update message in conversation
        final convIndex = conversations.indexWhere((c) => c.id == conversationId);
        if (convIndex != -1) {
          final conv = conversations[convIndex];
          final messageIndex = conv.messages.indexWhere((m) => m.id == editingMessageId.value);
          if (messageIndex != -1) {
            final updatedMessages = [...conv.messages];
            updatedMessages[messageIndex] = updatedMessages[messageIndex].copyWith(
              text: editMessageText.value.trim(),
            );
            conversations[convIndex] = conv.copyWith(messages: updatedMessages);
          }
        }

        // Close edit mode
        closeEditMessage();

        Get.snackbar(
          'Success',
          response.message.isNotEmpty ? response.message : 'Message updated successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF00B8A9),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );

        return true;
      } else {
        updateMessageError.value = response.message.isNotEmpty
            ? response.message
            : 'Failed to update message';
        debugPrint('❌ Failed to update message: ${response.message}');

        Get.snackbar(
          'Error',
          updateMessageError.value,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFE53935),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );

        return false;
      }
    } catch (e) {
      updateMessageError.value = 'An error occurred while updating message';
      debugPrint('❌ Error updating message: $e');

      Get.snackbar(
        'Error',
        updateMessageError.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE53935),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      return false;
    } finally {
      isUpdatingMessage.value = false;
    }
  }

  // Show delete message confirmation dialog
  void showDeleteMessageConfirmation(String conversationId, Message message) {
    Get.dialog(
      Builder(
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            title: Text(
              'Delete Message',
              style: TextStyle(
                color: const Color(0xFF0A2342),
                fontWeight: FontWeight.bold,
                fontSize: 18.sp,
              ),
            ),
            content: Text(
              'Are you sure you want to delete this message? This action cannot be undone.',
              style: TextStyle(
                color: const Color(0xFF0A2342),
                fontSize: 14.sp,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: const Color(0xFF0A2342).withOpacity(0.6),
                    fontSize: 14.sp,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  // Small delay to ensure dialog closes before deleting
                  Future.delayed(const Duration(milliseconds: 100), () {
                    deleteMessage(conversationId, message);
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'Delete',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ],
          );
        },
      ),
      barrierDismissible: true,
    );
  }

  // Delete a message
  Future<bool> deleteMessage(String conversationId, Message message) async {
    isDeletingMessage.value = true;
    deleteMessageError.value = '';

    try {
      final messageId = int.tryParse(message.id);
      if (messageId == null) {
        deleteMessageError.value = 'Invalid message ID';
        isDeletingMessage.value = false;
        return false;
      }

      debugPrint('🔄 Deleting message via API...');
      debugPrint('   - Message ID: $messageId');

      final response = await _messagesRepository.deleteMessage(
        messageId: messageId,
      );

      if (response.isSuccess) {
        debugPrint('✅ Message deleted successfully');

        // Remove message from conversation
        final convIndex = conversations.indexWhere((c) => c.id == conversationId);
        if (convIndex != -1) {
          final conv = conversations[convIndex];
          final updatedMessages = conv.messages.where((m) => m.id != message.id).toList();
          
          // Update last message if needed
          String lastMessageText = 'No messages yet';
          DateTime lastTimestamp = DateTime.now();
          if (updatedMessages.isNotEmpty) {
            final lastMsg = updatedMessages.last;
            lastMessageText = lastMsg.text;
            lastTimestamp = lastMsg.timestamp;
          }

          conversations[convIndex] = conv.copyWith(
            messages: updatedMessages,
            lastMessage: lastMessageText,
            timestamp: lastTimestamp,
          );
        }

        Get.snackbar(
          'Success',
          response.message.isNotEmpty ? response.message : 'Message deleted successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF00B8A9),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );

        return true;
      } else {
        deleteMessageError.value = response.message.isNotEmpty
            ? response.message
            : 'Failed to delete message';
        debugPrint('❌ Failed to delete message: ${response.message}');

        Get.snackbar(
          'Error',
          deleteMessageError.value,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFE53935),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );

        return false;
      }
    } catch (e) {
      deleteMessageError.value = 'An error occurred while deleting message';
      debugPrint('❌ Error deleting message: $e');

      Get.snackbar(
        'Error',
        deleteMessageError.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE53935),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      return false;
    } finally {
      isDeletingMessage.value = false;
    }
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
