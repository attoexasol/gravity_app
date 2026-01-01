import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gravityapp/data/model/conversation.dart';
import 'package:gravityapp/data/model/message.dart';
import '../../../data/repositories/messages_repository.dart';
import '../../../core/services/preferences_service.dart';
import '../../../data/model/api_response.dart';
import '../utils/message_utils.dart';

class MessagesController extends GetxController {
  // Repository
  final MessagesRepository _messagesRepository = MessagesRepository();

  // Current view state
  final RxString selectedConversationId = ''.obs;
  final RxString searchQuery = ''.obs;
  final RxString messageInput = ''.obs;
  final RxnInt typingUserId = RxnInt(); // ID of user who is typing (null if no one is typing)
  final RxBool isLoadingConversations = false.obs;
  final RxBool isLoadingMessages = false.obs;

  // Text editing controller
  final TextEditingController messageController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController editMessageController = TextEditingController();
  
  // Focus node for message input field
  final FocusNode messageFocusNode = FocusNode();
  
  // Scroll controller for messages list
  final ScrollController messagesScrollController = ScrollController();
  
  // WhatsApp-like scroll behavior state
  final RxBool isNearBottom = true.obs; // User is within 80px of bottom
  final RxBool hasNewIncomingMessage = false.obs; // New message arrived while scrolled up
  static const double _nearBottomThreshold = 80.0; // 80px threshold like WhatsApp
  
  // Track last received message ID for highlight animation
  final RxString lastReceivedMessageId = ''.obs;

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
  
  // Getter for current user ID (for UI access)
  int? get currentUserId => _currentUserId;
  
  // Map to store conversation partner user IDs
  final Map<String, int> _conversationUserIds = {};
  
  // Map to store user names
  final Map<int, String> _userNames = {};
  
  // Map to store user profile images
  final Map<int, String> _userProfileImages = {};

  // Timer for periodic message polling
  Timer? _messagePollingTimer;
  static const Duration _pollingInterval = Duration(seconds: 3); // Poll every 3 seconds
  
  // Prevent overlapping polling calls
  bool _isPollingInProgress = false;
  
  // Typing indicator debounce timer
  Timer? _typingDebounceTimer;
  static const Duration _typingDebounceDelay = Duration(milliseconds: 500);
  
  // App lifecycle observer for background/foreground handling
  late AppLifecycleObserver _lifecycleObserver;

  @override
  void onInit() {
    super.onInit();
    _loadUserType();
    _loadCurrentUserId();
    _loadConversations();
    _setupLifecycleObserver();
    _setupScrollListener();
    _startMessagePolling();
  }
  
  /// Setup scroll listener to track if user is near bottom
  void _setupScrollListener() {
    messagesScrollController.addListener(_onScroll);
    
    // Listen to keyboard visibility changes to adjust scroll
    messageFocusNode.addListener(_onKeyboardToggle);
  }
  
  /// Handle keyboard show/hide to adjust scroll position
  void _onKeyboardToggle() {
    if (messageFocusNode.hasFocus) {
      // Keyboard is opening - scroll to bottom after a short delay
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 300), () {
          scrollToBottom(smooth: true, force: true);
        });
      });
    }
  }
  
  /// Handle scroll position changes to track if user is near bottom
  void _onScroll() {
    if (!messagesScrollController.hasClients) return;
    
    final position = messagesScrollController.position;
    final maxScroll = position.maxScrollExtent;
    final currentScroll = position.pixels;
    final distanceFromBottom = maxScroll - currentScroll;
    
    // Update isNearBottom state (within 80px threshold)
    final wasNearBottom = isNearBottom.value;
    final nowNearBottom = distanceFromBottom <= _nearBottomThreshold;
    
    if (wasNearBottom != nowNearBottom) {
      isNearBottom.value = nowNearBottom;
      
      // If user scrolled back to bottom, clear new message flag
      if (nowNearBottom && hasNewIncomingMessage.value) {
        hasNewIncomingMessage.value = false;
      }
    }
  }
  
  /// Setup app lifecycle observer to handle background/foreground
  void _setupLifecycleObserver() {
    _lifecycleObserver = AppLifecycleObserver(
      onPaused: () {
        debugPrint('📱 Messages: App paused - stopping polling');
        _stopMessagePolling();
      },
      onResumed: () {
        debugPrint('📱 Messages: App resumed - restarting polling');
        _startMessagePolling();
      },
    );
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    _stopMessagePolling();
    _stopTypingDebounce();
    messagesScrollController.removeListener(_onScroll);
    messageController.dispose();
    searchController.dispose();
    editMessageController.dispose();
    messageFocusNode.dispose();
    messagesScrollController.dispose();
    super.onClose();
  }
  
  /// Handle typing input changes
  /// IMPORTANT: Does NOT set typingUserId when current user types
  /// typingUserId should ONLY be set when OTHER user is typing (from backend/sockets)
  /// Current user NEVER sees their own typing indicator
  void handleTyping(String value) {
    // Update message input value
    messageInput.value = value;
    
    // If input is empty, clear any existing typing state
    if (value.trim().isEmpty) {
      _stopTypingDebounce();
      // Only clear typingUserId if it was set for current user (shouldn't happen, but safety check)
      // In normal flow, typingUserId should only be set by backend when other user types
      typingUserId.value = null;
      return;
    }
    
    // DO NOT set typingUserId when current user types
    // typingUserId should only be set when we receive typing signal from OTHER user (backend/sockets)
    // This ensures current user NEVER sees their own typing indicator
  }
  
  /// Stop typing debounce timer
  void _stopTypingDebounce() {
    _typingDebounceTimer?.cancel();
    _typingDebounceTimer = null;
  }
  
  /// Stop typing indicator (called when message is sent or conversation is closed)
  void stopTyping() {
    _stopTypingDebounce();
    typingUserId.value = null;
  }

  /// Scroll to bottom of messages list (WhatsApp-like behavior)
  /// Only auto-scrolls if user is near bottom (within 80px)
  /// If user is scrolled up, sets hasNewIncomingMessage flag instead
  void scrollToBottom({bool smooth = true, bool force = false}) {
    if (!messagesScrollController.hasClients) return;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!messagesScrollController.hasClients) return;
      
      final position = messagesScrollController.position;
      final maxScroll = position.maxScrollExtent;
      final currentScroll = position.pixels;
      final distanceFromBottom = maxScroll - currentScroll;
      
      // If forced (user clicked scroll button), always scroll
      if (force) {
        if (smooth) {
          messagesScrollController.animateTo(
            maxScroll,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          messagesScrollController.jumpTo(maxScroll);
        }
        // Clear new message flag when user manually scrolls
        hasNewIncomingMessage.value = false;
        isNearBottom.value = true;
        return;
      }
      
      // Auto-scroll ONLY if user is near bottom (within 80px threshold)
      if (distanceFromBottom <= _nearBottomThreshold) {
        if (smooth) {
          messagesScrollController.animateTo(
            maxScroll,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          // Use jumpTo for instant scroll when user is already near bottom
          messagesScrollController.jumpTo(maxScroll);
        }
        // Clear new message flag since we're auto-scrolling
        hasNewIncomingMessage.value = false;
      } else {
        // User is scrolled up - don't auto-scroll
        // The caller should set hasNewIncomingMessage if there are new messages
        debugPrint('📱 Messages: User scrolled up (${distanceFromBottom.toStringAsFixed(0)}px from bottom), not auto-scrolling');
      }
    });
  }
  
  /// Manually scroll to bottom (called when user clicks scroll button)
  void scrollToBottomManually() {
    scrollToBottom(smooth: true, force: true);
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
      
      // Clear existing conversations to start fresh
      conversations.clear();
      
      // Remove any conversations with the current user (cleanup)
      _removeConversationsWithCurrentUser();
      
      // Determine which role to fetch (opposite of current user)
      final targetRole = userType.value == 'customer' ? 'coach' : 'customer';
      
      debugPrint('📱 Messages: Loading $targetRole users for ${userType.value}');

      // Try to get list of users (coaches or customers)
      final usersResponse = await _messagesRepository.getAllUsers(role: targetRole);
      
      if (usersResponse.isSuccess && usersResponse.data != null && usersResponse.data!.isNotEmpty) {
        // Load conversations for each user (don't sort during loading)
        // IMPORTANT: Filter out the current user and filter by role to prevent showing wrong role profiles
        for (final userData in usersResponse.data!) {
          final otherUserId = userData['id'] ?? userData['user_id'];
          if (otherUserId == null) continue;
          
          final otherUserIdInt = otherUserId is int ? otherUserId : int.tryParse(otherUserId.toString());
          if (otherUserIdInt == null) continue;
          
          // Skip if this is the current user (prevent showing own profile)
          if (otherUserIdInt == _currentUserId) {
            debugPrint('⏭️ Messages: Skipping current user (ID: $otherUserIdInt) from conversation list');
            continue;
          }
          
          // CRITICAL: Verify user role matches target role (client-side filtering)
          // This ensures only the correct role profiles are shown even if API returns wrong data
          final userRole = _extractUserRole(userData);
          if (!_isValidRoleForUser(userRole, targetRole)) {
            debugPrint('⏭️ Messages: Skipping user (ID: $otherUserIdInt) - Role mismatch. User role: $userRole, Expected: $targetRole');
            continue;
          }
          
          // Load messages for this user (pass false to skip individual sorting)
          await _loadConversationForUser(otherUserIdInt, userData, sortImmediately: false);
        }
        
        // Sort conversations by most recent message after ALL conversations are loaded
        // This ensures proper sorting on app restart
        _sortConversationsByTimestamp();
        
        // Final cleanup: Remove any conversations with current user or incorrect role (safety checks)
        _removeConversationsWithCurrentUser();
        _removeConversationsWithIncorrectRole();
        
        debugPrint('✅ Loaded and sorted ${conversations.length} conversations');
        
        // Refresh unread counts using getSingleMessage API in the background
        // This ensures accurate unread counts are displayed on initial load
        // Note: getSingleMessage marks messages as read, but this is acceptable
        // since the user is viewing the messages page (they've "seen" the messages)
        _refreshUnreadCountsAfterInitialLoad();
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

  /// Refresh unread counts after initial load using getSingleMessage API
  /// This ensures accurate unread counts are displayed on initial load
  /// Note: getSingleMessage marks messages as read, but this is acceptable UX
  /// since viewing the messages page means the user has "seen" the messages
  Future<void> _refreshUnreadCountsAfterInitialLoad() async {
    if (conversations.isEmpty) return;
    
    final apiToken = PreferencesService.getAuthToken();
    if (apiToken == null || apiToken.isEmpty) {
      debugPrint('⚠️ Messages: No API token available for refreshing unread counts');
      return;
    }
    
    debugPrint('🔄 Refreshing unread counts for ${conversations.length} conversations using getSingleMessage...');
    
    // Refresh unread counts for each conversation in the background
    // Use getSingleMessage to get accurate is_read status
    for (int i = 0; i < conversations.length; i++) {
      final conversation = conversations[i];
      final otherUserId = _conversationUserIds[conversation.id];
      
      if (otherUserId != null) {
        // Add small delay between requests to avoid overwhelming the server
        if (i > 0) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
        
        // Refresh unread count for this conversation
        _refreshUnreadCountForConversation(otherUserId, conversation.id, apiToken);
      }
    }
    
    debugPrint('✅ Finished refreshing unread counts for all conversations');
  }
  
  /// Refresh unread count for a single conversation using getSingleMessage API
  /// This updates the unread count with accurate is_read status
  Future<void> _refreshUnreadCountForConversation(
    int otherUserId,
    String conversationId,
    String apiToken,
  ) async {
    try {
      // Skip if conversation is currently open (already being refreshed by polling)
      if (selectedConversationId.value == conversationId) {
        return;
      }
      
      // Use getSingleMessage to get accurate is_read status
      final messagesResponse = await _messagesRepository.getSingleMessage(
        apiToken: apiToken,
        toUserId: otherUserId,
      );
      
      if (messagesResponse.isSuccess && messagesResponse.data != null) {
        final allMessages = messagesResponse.data!;
        
        // Safety guard
        if (_currentUserId == null) {
          debugPrint('⚠️ Messages: Current user ID is null, cannot refresh unread count');
          return;
        }
        
        // Filter messages using MessageUtils
        final filteredMessages = MessageUtils.filterConversationMessages(
          allMessages,
          _currentUserId!,
          otherUserId,
        );
        
        // Map messages and calculate unread count using MessageUtils
        // IMPORTANT: The API response contains is_read status BEFORE marking as read
        // So we can calculate accurate unread count from the response
        final mappedMessages = filteredMessages
            .map((msg) => MessageUtils.mapApiMessage(msg, _currentUserId))
            .toList();
        
        // Remove duplicates before calculating unread count
        final uniqueMessages = MessageUtils.removeDuplicateMessages(mappedMessages);
        
        // Calculate unread count using MessageUtils
        // The is_read field in the response reflects the status before getSingleMessage marks them as read
        final unreadCount = MessageUtils.calculateUnreadCount(uniqueMessages);
        
        // Update conversation with new unread count
        final convIndex = conversations.indexWhere((c) => c.id == conversationId);
        if (convIndex != -1) {
          final existingConv = conversations[convIndex];
          
          // Only update if unread count changed
          if (existingConv.unreadCount != unreadCount) {
            conversations[convIndex] = existingConv.copyWith(unreadCount: unreadCount);
            // Only refresh if count actually changed
            conversations.refresh();
            debugPrint('✅ Updated unread count for conversation $conversationId: $unreadCount (was ${existingConv.unreadCount})');
          }
        }
      }
    } catch (e) {
      // Silently fail - don't spam logs
      debugPrint('⚠️ Error refreshing unread count for conversation $conversationId (silent): $e');
    }
  }

  /// Remove any conversations with the current user (cleanup method)
  void _removeConversationsWithCurrentUser() {
    if (_currentUserId == null) return;
    
    final conversationsToRemove = <String>[];
    for (final conversation in conversations) {
      final otherUserId = _conversationUserIds[conversation.id];
      if (otherUserId == _currentUserId) {
        conversationsToRemove.add(conversation.id);
        debugPrint('🗑️ Messages: Removing conversation with current user (ID: $otherUserId)');
      }
    }
    
    for (final conversationId in conversationsToRemove) {
      conversations.removeWhere((c) => c.id == conversationId);
      _conversationUserIds.remove(conversationId);
    }
    
    if (conversationsToRemove.isNotEmpty) {
      conversations.refresh();
      debugPrint('✅ Messages: Removed ${conversationsToRemove.length} conversation(s) with current user');
    }
  }

  /// Remove conversations with incorrect roles (cleanup method)
  /// Ensures only conversations with the correct role are shown
  void _removeConversationsWithIncorrectRole() {
    final targetRole = userType.value == 'customer' ? 'coach' : 'customer';
    final expectedRole = targetRole == 'coach' ? ConversationRole.coach : ConversationRole.customer;
    
    final conversationsToRemove = <String>[];
    for (final conversation in conversations) {
      if (conversation.role != expectedRole) {
        conversationsToRemove.add(conversation.id);
        debugPrint('🗑️ Messages: Removing conversation with incorrect role. Conversation role: ${conversation.role}, Expected: $expectedRole');
      }
    }
    
    for (final conversationId in conversationsToRemove) {
      conversations.removeWhere((c) => c.id == conversationId);
      _conversationUserIds.remove(conversationId);
    }
    
    if (conversationsToRemove.isNotEmpty) {
      conversations.refresh();
      debugPrint('✅ Messages: Removed ${conversationsToRemove.length} conversation(s) with incorrect role');
    }
  }

  Future<void> _loadConversationForUser(int otherUserId, Map<String, dynamic>? userData, {bool sortImmediately = true}) async {
    // Prevent creating conversation with self
    if (_currentUserId == null) {
      debugPrint('❌ Messages: Current user ID is null, cannot load conversation for user $otherUserId.');
      return;
    }
    
    if (otherUserId == _currentUserId) {
      debugPrint('⏭️ Messages: Skipping conversation creation for current user (ID: $otherUserId)');
      return;
    }
    
    try {
      // Get messages with this user using getAllMessages
      // Note: getAllMessages might not return accurate is_read status
      // We'll refresh unread counts after initial load using getSingleMessage
      final messagesResponse = await _messagesRepository.getAllMessages(otherUserId: otherUserId);
      
      if (messagesResponse.isSuccess && messagesResponse.data != null) {
        final allMessages = messagesResponse.data!;
        
        // Filter messages using MessageUtils (handles all user ID parsing)
        final filteredMessages = MessageUtils.filterConversationMessages(
          allMessages,
          _currentUserId!,
          otherUserId,
        );
        
        // Additional role verification (if role data is available in messages)
        final targetRole = userType.value == 'customer' ? 'coach' : 'customer';
        final roleVerifiedMessages = filteredMessages.where((msg) {
          // Try to extract role from message if available
          final fromUserId = MessageUtils.extractFromUserId(msg);
          final isFromOtherToCurrent = fromUserId == otherUserId;
          
          if (isFromOtherToCurrent) {
            final fromUser = msg['from_user'];
            if (fromUser is Map<String, dynamic>) {
              final otherUserRole = _extractUserRole(fromUser);
              if (otherUserRole.isNotEmpty && !_isValidRoleForUser(otherUserRole, targetRole)) {
                debugPrint('⏭️ Messages: Skipping message - Role mismatch. User role: $otherUserRole, Expected: $targetRole');
                return false;
              }
            }
          } else {
            final toUser = msg['to_user'];
            if (toUser is Map<String, dynamic>) {
              final otherUserRole = _extractUserRole(toUser);
              if (otherUserRole.isNotEmpty && !_isValidRoleForUser(otherUserRole, targetRole)) {
                debugPrint('⏭️ Messages: Skipping message - Role mismatch. User role: $otherUserRole, Expected: $targetRole');
                return false;
              }
            }
          }
          return true;
        }).toList();
        
        debugPrint('📱 Filtered ${roleVerifiedMessages.length} messages for conversation with user $otherUserId (from ${allMessages.length} total)');
        
        // Extract user name from userData, cached name, or messages
        String userName;
        if (userData != null) {
          userName = _extractUserName(userData, roleVerifiedMessages, otherUserId);
        } else if (_userNames.containsKey(otherUserId)) {
          // Use cached name if available
          userName = _userNames[otherUserId]!;
          debugPrint('👤 Messages: Using cached user name for user $otherUserId: $userName');
        } else {
          // Try to extract from messages
          userName = _extractUserName(null, roleVerifiedMessages, otherUserId);
        }
        
        // Extract profile image from userData, cached image, or messages
        String? profileImage;
        if (userData != null) {
          profileImage = _extractProfileImage(userData, roleVerifiedMessages, otherUserId);
        } else if (_userProfileImages.containsKey(otherUserId)) {
          // Use cached profile image if available
          profileImage = _userProfileImages[otherUserId];
          debugPrint('📸 Messages: Using cached profile image for user $otherUserId');
        } else {
          // Try to extract from messages
          profileImage = _extractProfileImage(null, roleVerifiedMessages, otherUserId);
        }
        
        // Map messages to Message models using MessageUtils
        final mappedMessages = roleVerifiedMessages
            .map((msg) => MessageUtils.mapApiMessage(msg, _currentUserId))
            .toList();
        
        // Remove duplicates and sort messages by timestamp
        final uniqueMessages = MessageUtils.removeDuplicateMessages(mappedMessages);
        final sortedMessages = MessageUtils.sortMessagesByTimestamp(uniqueMessages);
        
        // Determine last message and timestamp
        String lastMessageText = 'No messages yet';
        DateTime lastTimestamp = DateTime.now();
        
        // If conversation is currently open, mark all received messages as read
        final conversationId = 'conv_$otherUserId';
        final isConversationOpen = selectedConversationId.value == conversationId;
        final finalMessages = isConversationOpen
            ? sortedMessages.map((m) {
                // Mark received messages as read when conversation is open
                if (!m.isSent && !m.isRead) {
                  return m.copyWith(isRead: true);
                }
                return m;
              }).toList()
            : sortedMessages;
        
        int unreadCount = 0;
        
        if (finalMessages.isNotEmpty) {
          final lastMsg = finalMessages.last;
          lastMessageText = lastMsg.text;
          lastTimestamp = lastMsg.timestamp;
          
          // Calculate unread count using MessageUtils
          unreadCount = MessageUtils.calculateUnreadCount(finalMessages);
        }
        
        // Create conversation (conversationId already declared above)
        _conversationUserIds[conversationId] = otherUserId;
        
        // Always update cached name and profile image (in case we got better data)
        _userNames[otherUserId] = userName;
        if (profileImage != null && profileImage.isNotEmpty) {
          _userProfileImages[otherUserId] = profileImage;
        }
        
        // Get existing conversation to preserve name if we have a cached one that's better
        final existingIndex = conversations.indexWhere((c) => c.id == conversationId);
        String finalUserName = userName;
        String? finalProfileImage = profileImage;
        
        // If we're reloading and have an existing conversation, preserve the name if it's not a fallback
        if (existingIndex != -1) {
          final existingConv = conversations[existingIndex];
          // Only use existing name if current extraction resulted in fallback (User XX)
          if (userName.startsWith('User ') && existingConv.name.isNotEmpty && !existingConv.name.startsWith('User ')) {
            finalUserName = existingConv.name;
            debugPrint('👤 Messages: Preserving existing conversation name: $finalUserName');
          }
          // Preserve existing avatar if we don't have a better one
          if ((profileImage == null || profileImage.isEmpty) && existingConv.avatar.isNotEmpty && !existingConv.avatar.contains('👤')) {
            finalProfileImage = existingConv.avatar;
            debugPrint('📸 Messages: Preserving existing conversation avatar');
          }
        }
        
        final conversation = Conversation(
          id: conversationId,
          name: finalUserName,
          avatar: _getAvatarForUser(otherUserId, finalProfileImage),
          lastMessage: lastMessageText,
          timestamp: lastTimestamp,
          unreadCount: unreadCount,
          role: userType.value == 'customer' ? ConversationRole.coach : ConversationRole.customer,
          messages: finalMessages,
        );
        
        // Add or update conversation
        if (existingIndex != -1) {
          conversations[existingIndex] = conversation;
        } else {
          conversations.add(conversation);
        }
        
        // Sort conversations by most recent message (Messenger-like behavior)
        // Only sort immediately if not during initial load
        if (sortImmediately) {
          _sortConversationsByTimestamp();
        }
      } else if (userData != null) {
        // No messages yet, but create empty conversation
        String userName;
        if (_userNames.containsKey(otherUserId)) {
          // Use cached name if available
          userName = _userNames[otherUserId]!;
          debugPrint('👤 Messages: Using cached user name for empty conversation with user $otherUserId: $userName');
        } else {
          userName = _extractUserName(userData, [], otherUserId);
        }
        
        String? profileImage;
        if (_userProfileImages.containsKey(otherUserId)) {
          // Use cached profile image if available
          profileImage = _userProfileImages[otherUserId];
          debugPrint('📸 Messages: Using cached profile image for empty conversation with user $otherUserId');
        } else {
          profileImage = _extractProfileImage(userData, [], otherUserId);
        }
        
        final conversationId = 'conv_$otherUserId';
        _conversationUserIds[conversationId] = otherUserId;
        _userNames[otherUserId] = userName;
        if (profileImage != null && profileImage.isNotEmpty) {
          _userProfileImages[otherUserId] = profileImage;
        }
        
        // For empty conversations, use a very old timestamp so they appear at the bottom
        final conversation = Conversation(
          id: conversationId,
          name: userName,
          avatar: _getAvatarForUser(otherUserId, profileImage),
          lastMessage: 'No messages yet',
          timestamp: DateTime(1970, 1, 1), // Use very old timestamp for empty conversations
          unreadCount: 0,
          role: userType.value == 'customer' ? ConversationRole.coach : ConversationRole.customer,
          messages: [],
        );
        
        conversations.add(conversation);
        
        // Sort conversations by most recent message (Messenger-like behavior)
        // Only sort immediately if not during initial load
        if (sortImmediately) {
          _sortConversationsByTimestamp();
        }
      }
    } catch (e) {
      debugPrint('❌ Messages: Error loading conversation for user $otherUserId: $e');
    }
  }

  /// Sort conversations by timestamp (most recent first) - Messenger-like behavior
  void _sortConversationsByTimestamp() {
    if (conversations.isEmpty) return;
    
    // Create a new sorted list (don't sort in place to ensure GetX detects the change)
    final sortedList = List<Conversation>.from(conversations);
    sortedList.sort((a, b) {
      // Sort by timestamp descending (most recent first)
      return b.timestamp.compareTo(a.timestamp);
    });
    
    // Reassign the entire list to trigger reactive update
    // This ensures GetX detects the change and triggers UI rebuild
    conversations.value = sortedList;
    conversations.refresh(); // Force UI update
    
    debugPrint('🔄 Sorted conversations by timestamp (most recent first) - ${conversations.length} conversations');
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

  /// Map API message to Message model using MessageUtils
  Message _mapApiMessageToMessage(Map<String, dynamic> json) {
    return MessageUtils.mapApiMessage(json, _currentUserId);
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

  /// Extract user role from user data
  /// Checks multiple possible field names: 'role', 'user_type', 'type'
  String _extractUserRole(Map<String, dynamic> userData) {
    final role = userData['role'] ?? 
                 userData['user_type'] ?? 
                 userData['type'] ?? 
                 userData['user_role'] ?? 
                 '';
    return role.toString().toLowerCase().trim();
  }

  /// Check if user role is valid for the current user type
  /// - Customers should only see coaches
  /// - Coaches should only see customers
  bool _isValidRoleForUser(String userRole, String targetRole) {
    // Normalize role strings for comparison
    final normalizedUserRole = userRole.toLowerCase().trim();
    final normalizedTargetRole = targetRole.toLowerCase().trim();
    
    // If role is empty or unknown, we can't verify - skip for safety
    if (normalizedUserRole.isEmpty) {
      debugPrint('⚠️ Messages: User role is empty, skipping for safety');
      return false;
    }
    
    // Check if user role matches target role
    // Support variations: 'coach', 'coaches', 'customer', 'customers'
    final isCoach = normalizedUserRole == 'coach' || normalizedUserRole == 'coaches';
    final isCustomer = normalizedUserRole == 'customer' || normalizedUserRole == 'customers';
    
    final targetIsCoach = normalizedTargetRole == 'coach' || normalizedTargetRole == 'coaches';
    final targetIsCustomer = normalizedTargetRole == 'customer' || normalizedTargetRole == 'customers';
    
    // Match: if target is coach, user should be coach; if target is customer, user should be customer
    if (targetIsCoach && isCoach) return true;
    if (targetIsCustomer && isCustomer) return true;
    
    return false;
  }

  // Filtered conversations based on search and role
  List<Conversation> get filteredConversations {
    // First filter by role (safety check)
    final targetRole = userType.value == 'customer' ? 'coach' : 'customer';
    final roleFilteredConversations = conversations.where((conv) {
      // Verify conversation role matches target role
      final expectedRole = targetRole == 'coach' ? ConversationRole.coach : ConversationRole.customer;
      return conv.role == expectedRole;
    }).toList();
    
    // Then filter by search query if provided
    if (searchQuery.value.isEmpty) {
      return roleFilteredConversations;
    }
    
    return roleFilteredConversations
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
    
    // Reset scroll state when opening new conversation
    hasNewIncomingMessage.value = false;
    isNearBottom.value = true; // Assume at bottom when opening conversation
    
    // Clear any previous highlight animation
    lastReceivedMessageId.value = '';
    
    // Reload messages for this conversation using getSingleMessage API
    // This API will mark messages as read on the server
    final otherUserId = _conversationUserIds[conversationId];
    if (otherUserId != null) {
      _loadConversationForUserWithSingleMessage(otherUserId);
    }
    
    // Restart polling to ensure fresh messages
    _startMessagePolling();
    
    // Scroll to bottom after conversation loads (with delay to ensure ListView is built)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        scrollToBottom(smooth: false, force: true);
      });
    });
  }
  
  /// Load conversation using getSingleMessage API (marks messages as read on server)
  Future<void> _loadConversationForUserWithSingleMessage(int otherUserId) async {
    try {
      final apiToken = PreferencesService.getAuthToken();
      if (apiToken == null || apiToken.isEmpty) {
        debugPrint('⚠️ Messages: No API token available for getSingleMessage');
        // Fallback to regular getAllMessages
        await _loadConversationForUser(otherUserId, null);
        return;
      }

      debugPrint('📤 Messages: Loading conversation with user $otherUserId using getSingleMessage API');
      
      final messagesResponse = await _messagesRepository.getSingleMessage(
        apiToken: apiToken,
        toUserId: otherUserId,
      );

      if (messagesResponse.isSuccess && messagesResponse.data != null) {
        final messages = messagesResponse.data!;
        debugPrint('✅ Messages: Received ${messages.length} messages from getSingleMessage API');
        
        // Process messages and update conversation
        await _processMessagesForConversation(messages, otherUserId, null);
      } else {
        debugPrint('⚠️ Messages: getSingleMessage failed, falling back to getAllMessages');
        // Fallback to regular getAllMessages
        await _loadConversationForUser(otherUserId, null);
      }
    } catch (e) {
      debugPrint('❌ Messages: Error in _loadConversationForUserWithSingleMessage: $e');
      // Fallback to regular getAllMessages
      await _loadConversationForUser(otherUserId, null);
    }
  }
  
  /// Process messages for a conversation (shared logic for both getAllMessages and getSingleMessage)
  /// Uses MessageUtils for all filtering, mapping, and unread count calculations
  Future<void> _processMessagesForConversation(
    List<Map<String, dynamic>> allMessages,
    int otherUserId,
    Map<String, dynamic>? userData,
  ) async {
    // Safety guard: prevent processing messages for self
    if (_currentUserId == null) {
      debugPrint('❌ Messages: Current user ID is null, cannot process messages');
      return;
    }
    
    if (otherUserId == _currentUserId) {
      debugPrint('⏭️ Messages: Skipping message processing for self (ID: $otherUserId)');
      return;
    }
    
    // Filter messages using MessageUtils
    final filteredMessages = MessageUtils.filterConversationMessages(
      allMessages,
      _currentUserId!,
      otherUserId,
    );
    
    debugPrint('📱 Filtered ${filteredMessages.length} messages for conversation with user $otherUserId (from ${allMessages.length} total)');
    
    // Extract user name and profile image
    String userName;
    if (userData != null) {
      userName = _extractUserName(userData, filteredMessages, otherUserId);
    } else if (_userNames.containsKey(otherUserId)) {
      userName = _userNames[otherUserId]!;
    } else {
      userName = _extractUserName(null, filteredMessages, otherUserId);
    }
    
    String? profileImage;
    if (userData != null) {
      profileImage = _extractProfileImage(userData, filteredMessages, otherUserId);
    } else if (_userProfileImages.containsKey(otherUserId)) {
      profileImage = _userProfileImages[otherUserId];
    } else {
      profileImage = _extractProfileImage(null, filteredMessages, otherUserId);
    }
    
    // Map messages to Message models using MessageUtils
    final mappedMessages = filteredMessages
        .map((msg) => MessageUtils.mapApiMessage(msg, _currentUserId))
        .toList();
    
    // Remove duplicates and sort messages by timestamp
    final uniqueMessages = MessageUtils.removeDuplicateMessages(mappedMessages);
    final sortedMessages = MessageUtils.sortMessagesByTimestamp(uniqueMessages);
    
    // Determine last message and timestamp
    String lastMessageText = 'No messages yet';
    DateTime lastTimestamp = DateTime.now();
    
    // Calculate unread count using MessageUtils
    // The getSingleMessage API should have already marked messages as read on the server
    final conversationId = 'conv_$otherUserId';
    final isConversationOpen = selectedConversationId.value == conversationId;
    
    // If conversation is open, all received messages should be marked as read
    // But we still count based on the is_read field from the API
    final unreadCount = isConversationOpen
        ? 0 // If conversation is open, unread count should be 0 (messages are marked as read)
        : MessageUtils.calculateUnreadCount(sortedMessages);
    
    if (sortedMessages.isNotEmpty) {
      final lastMsg = sortedMessages.last;
      lastMessageText = lastMsg.text;
      lastTimestamp = lastMsg.timestamp;
    }
    
    // Update cached data
    _conversationUserIds[conversationId] = otherUserId;
    _userNames[otherUserId] = userName;
    if (profileImage != null && profileImage.isNotEmpty) {
      _userProfileImages[otherUserId] = profileImage;
    }
    
    // Get existing conversation to preserve name if we have a cached one that's better
    final existingIndex = conversations.indexWhere((c) => c.id == conversationId);
    String finalUserName = userName;
    String? finalProfileImage = profileImage;
    
    if (existingIndex != -1) {
      final existingConv = conversations[existingIndex];
      if (userName.startsWith('User ') && existingConv.name.isNotEmpty && !existingConv.name.startsWith('User ')) {
        finalUserName = existingConv.name;
      }
      if ((profileImage == null || profileImage.isEmpty) && existingConv.avatar.isNotEmpty && !existingConv.avatar.contains('👤')) {
        finalProfileImage = existingConv.avatar;
      }
    }
    
    final conversation = Conversation(
      id: conversationId,
      name: finalUserName,
      avatar: _getAvatarForUser(otherUserId, finalProfileImage),
      lastMessage: lastMessageText,
      timestamp: lastTimestamp,
      unreadCount: unreadCount,
      role: userType.value == 'customer' ? ConversationRole.coach : ConversationRole.customer,
      messages: sortedMessages,
    );
    
    // Add or update conversation
    if (existingIndex != -1) {
      conversations[existingIndex] = conversation;
      // Only refresh if conversation actually changed
      conversations.refresh();
    } else {
      conversations.add(conversation);
      // New conversation added, refresh needed
      conversations.refresh();
    }
    
    // Sort conversations by most recent message
    _sortConversationsByTimestamp();
    
    debugPrint('✅ Messages: Updated conversation $conversationId. Unread count: $unreadCount');
  }

  // Close conversation
  void closeConversation() {
    selectedConversationId.value = '';
    messageInput.value = '';
    messageController.clear();
    stopTyping(); // Stop typing indicator when closing conversation
    // Restart polling for conversation list view (refresh all conversations)
    _startMessagePolling();
  }

  /// Start periodic polling for new messages
  /// Ensures only ONE timer exists and prevents overlapping calls
  void _startMessagePolling() {
    _stopMessagePolling(); // Stop any existing timer
    
    _messagePollingTimer = Timer.periodic(_pollingInterval, (timer) async {
      // Prevent overlapping polling calls
      if (_isPollingInProgress) {
        debugPrint('⏭️ Messages: Skipping polling - previous call still in progress');
        return;
      }
      
      try {
        _isPollingInProgress = true;
        
        // If a conversation is selected, refresh messages for that conversation
        if (selectedConversationId.value.isNotEmpty) {
          final conversationId = selectedConversationId.value;
          final otherUserId = _conversationUserIds[conversationId];
          
          if (otherUserId != null) {
            // Silently refresh messages (don't show loading indicator)
            await _refreshMessagesForConversation(otherUserId);
          }
        } else {
          // If no conversation is selected, refresh all conversations to update last messages
          await _refreshAllConversations();
        }
      } catch (e) {
        // Log error but continue polling
        debugPrint('⚠️ Error in polling callback (continuing): $e');
      } finally {
        _isPollingInProgress = false;
      }
    });
    
    debugPrint('🔄 Started message polling (every ${_pollingInterval.inSeconds}s)');
  }

  /// Refresh all conversations to update last messages and unread counts (for conversation list view)
  Future<void> _refreshAllConversations() async {
    try {
      bool anyUpdated = false;
      // Refresh each conversation's last message and unread count
      for (int i = 0; i < conversations.length; i++) {
        final conversation = conversations[i];
        final otherUserId = _conversationUserIds[conversation.id];
        if (otherUserId != null) {
          // Add small delay between requests to avoid overwhelming the server
          if (i > 0) {
            await Future.delayed(const Duration(milliseconds: 100));
          }
          
          final wasUpdated = await _refreshConversationLastMessage(otherUserId, conversation.id);
          if (wasUpdated) {
            anyUpdated = true;
          }
        }
      }
      // Sort once after all updates (more efficient than sorting after each update)
      // Note: Individual conversations also sort immediately when last message changes
      if (anyUpdated) {
        _sortConversationsByTimestamp();
        debugPrint('🔄 Refreshed all conversations: ${conversations.length} conversations updated');
      }
    } catch (e) {
      debugPrint('⚠️ Error refreshing conversations (silent): $e');
    }
  }

  /// Refresh only the last message and unread count for a conversation (lighter operation)
  /// Uses getAllMessages API for regular polling (doesn't mark messages as read)
  /// Only getSingleMessage is used when conversation is actually opened
  /// Returns true if the conversation was updated, false otherwise
  Future<bool> _refreshConversationLastMessage(int otherUserId, String conversationId) async {
    try {
      // Skip if conversation is currently open (already being refreshed by polling)
      if (selectedConversationId.value == conversationId) {
        return false;
      }
      
      // Use getAllMessages for regular polling (doesn't mark messages as read)
      // This ensures badges don't disappear until conversation is actually opened
      final messagesResponse = await _messagesRepository.getAllMessages(otherUserId: otherUserId);
      
      if (messagesResponse.isSuccess && messagesResponse.data != null) {
        final allMessages = messagesResponse.data!;
        
        // Safety guard
        if (_currentUserId == null) {
          debugPrint('⚠️ Messages: Current user ID is null, cannot refresh conversation');
          return false;
        }
        
        // Filter messages using MessageUtils
        final filteredMessages = MessageUtils.filterConversationMessages(
          allMessages,
          _currentUserId!,
          otherUserId,
        );
        
        if (filteredMessages.isNotEmpty) {
          // Map and sort messages using MessageUtils
          final mappedMessages = filteredMessages
              .map((msg) => MessageUtils.mapApiMessage(msg, _currentUserId))
              .toList();
          final uniqueMessages = MessageUtils.removeDuplicateMessages(mappedMessages);
          final sortedMessages = MessageUtils.sortMessagesByTimestamp(uniqueMessages);
          
          final lastMsg = sortedMessages.last;
          final convIndex = conversations.indexWhere((c) => c.id == conversationId);
          
          if (convIndex != -1) {
            final existingConv = conversations[convIndex];
            
            // Check for new messages from the other user (not sent by current user)
            // This is the ONLY reliable way to detect new unread messages during polling
            final existingMessageIds = existingConv.messages.map((m) => m.id).toSet();
            final newMessages = sortedMessages.where((m) => !existingMessageIds.contains(m.id)).toList();
            final newUnreadMessages = newMessages.where((m) => !m.isSent).toList();
            
            // Calculate unread count:
            // - Always increment for new messages from other user (regardless of is_read from getAllMessages)
            // - Never decrease during polling (preserve badges until conversation is opened)
            // - Only decrease when conversation is actually opened (handled by getSingleMessage)
            final newUnreadCount = newUnreadMessages.isNotEmpty
                ? existingConv.unreadCount + newUnreadMessages.length
                : existingConv.unreadCount; // Preserve existing count if no new messages
            
            // Determine if we need to update (last message changed OR unread count increased)
            final lastMessageChanged = lastMsg.text != existingConv.lastMessage || 
                                     lastMsg.timestamp != existingConv.timestamp;
            final unreadCountIncreased = newUnreadCount > existingConv.unreadCount;
            final shouldUpdate = lastMessageChanged || unreadCountIncreased;
            
            if (shouldUpdate) {
              conversations[convIndex] = existingConv.copyWith(
                lastMessage: lastMsg.text,
                timestamp: lastMsg.timestamp,
                unreadCount: newUnreadCount,
              );
              
              // Only refresh if conversation actually changed
              conversations.refresh();
              
              // Sort immediately if last message changed (Messenger behavior: move to top)
              if (lastMessageChanged) {
                _sortConversationsByTimestamp();
              }
              
              debugPrint('✅ Updated conversation $conversationId: unreadCount=$newUnreadCount (was ${existingConv.unreadCount}, newUnread=${newUnreadMessages.length}), lastMessage="${lastMsg.text}"');
              
              return true;
            }
          }
        }
      }
      return false;
    } catch (e) {
      // Silently fail
      debugPrint('⚠️ Error refreshing conversation last message (silent): $e');
      return false;
    }
  }

  /// Stop periodic polling
  void _stopMessagePolling() {
    _messagePollingTimer?.cancel();
    _messagePollingTimer = null;
    debugPrint('⏹️ Stopped message polling');
  }

  /// Refresh messages for a conversation without showing loading state
  /// IMPORTANT: This method is called from polling and should ONLY use getAllMessages
  /// getSingleMessage is ONLY used when conversation is explicitly opened (selectConversation)
  Future<void> _refreshMessagesForConversation(int otherUserId) async {
    try {
      // Safety guard
      if (_currentUserId == null) {
        debugPrint('⚠️ Messages: Current user ID is null, cannot refresh messages');
        return;
      }
      
      if (otherUserId == _currentUserId) {
        debugPrint('⏭️ Messages: Skipping refresh for self (ID: $otherUserId)');
        return;
      }
      
      // ALWAYS use getAllMessages during polling (never use getSingleMessage here)
      // getSingleMessage is only used when conversation is explicitly opened
      final messagesResponse = await _messagesRepository.getAllMessages(otherUserId: otherUserId);
      
      if (messagesResponse.isSuccess && messagesResponse.data != null) {
        final allMessages = messagesResponse.data!;
        
        // Filter messages using MessageUtils
        final filteredMessages = MessageUtils.filterConversationMessages(
          allMessages,
          _currentUserId!,
          otherUserId,
        );
        
        // Map, remove duplicates, and sort messages using MessageUtils
        final mappedMessages = filteredMessages
            .map((msg) => MessageUtils.mapApiMessage(msg, _currentUserId))
            .toList();
        final uniqueMessages = MessageUtils.removeDuplicateMessages(mappedMessages);
        final sortedMessages = MessageUtils.sortMessagesByTimestamp(uniqueMessages);
        
        // Get conversation ID
        final conversationId = 'conv_$otherUserId';
        final convIndex = conversations.indexWhere((c) => c.id == conversationId);
        
        if (convIndex != -1) {
          final existingConv = conversations[convIndex];
          
          // Check for new messages (by ID) - prevent duplicates
          final existingMessageIds = existingConv.messages.map((m) => m.id).toSet();
          final newMessages = sortedMessages.where((m) => !existingMessageIds.contains(m.id)).toList();
          
          // Check for updated messages (same ID but different content or timestamp)
          final updatedMessages = <Message>[];
          final existingMessagesMap = <String, Message>{};
          for (final msg in existingConv.messages) {
            existingMessagesMap[msg.id] = msg;
          }
          
          for (final newMsg in sortedMessages) {
            if (existingMessagesMap.containsKey(newMsg.id)) {
              final existingMsg = existingMessagesMap[newMsg.id]!;
              // Check if message content or timestamp changed (indicates edit)
              if (existingMsg.text != newMsg.text || 
                  existingMsg.timestamp != newMsg.timestamp) {
                updatedMessages.add(newMsg);
              }
            }
          }
          
          // Update if we have new messages, updated messages, or count changed
          if (newMessages.isNotEmpty || 
              updatedMessages.isNotEmpty || 
              sortedMessages.length != existingConv.messages.length) {
            // Update conversation with refreshed messages
            final lastMsg = sortedMessages.isNotEmpty ? sortedMessages.last : null;
            
            // If conversation is currently open, mark new received messages as read immediately
            final isConversationOpen = selectedConversationId.value == conversationId;
            final finalMessages = isConversationOpen
                ? sortedMessages.map((m) {
                    // Mark new received messages as read when conversation is open
                    if (!m.isSent && newMessages.any((nm) => nm.id == m.id)) {
                      return m.copyWith(isRead: true);
                    }
                    return m;
                  }).toList()
                : sortedMessages;
            
            // Calculate unread count using MessageUtils
            final unreadCount = MessageUtils.calculateUnreadCount(finalMessages);
            
            // Determine if last message changed (for sorting)
            final lastMessageChanged = lastMsg != null && 
                                     (lastMsg.text != existingConv.lastMessage || 
                                      lastMsg.timestamp != existingConv.timestamp);
            
            // Update conversation
            conversations[convIndex] = existingConv.copyWith(
              messages: finalMessages,
              lastMessage: lastMsg?.text ?? existingConv.lastMessage,
              timestamp: lastMsg?.timestamp ?? existingConv.timestamp,
              unreadCount: unreadCount,
              // Preserve name and avatar
            );
            
            // Only refresh if conversation actually changed
            conversations.refresh();
            
            // Sort immediately if last message changed (Messenger behavior: move to top)
            if (lastMessageChanged) {
              _sortConversationsByTimestamp();
            }
            
            // Handle new incoming messages (WhatsApp-like behavior)
            if (newMessages.isNotEmpty) {
              final incomingMessages = newMessages.where((m) => !m.isSent).toList();
              
              if (isConversationOpen) {
                debugPrint('✅ Messages: Marked ${incomingMessages.length} new received messages as read (conversation is open)');
              }
              
              // If there are incoming messages, check if we should auto-scroll or show flag
              if (incomingMessages.isNotEmpty) {
                // Track last received message ID for highlight animation
                // Use the most recent incoming message
                final mostRecentIncoming = incomingMessages.last;
                lastReceivedMessageId.value = mostRecentIncoming.id;
                
                // Clear highlight after animation duration (800ms)
                Future.delayed(const Duration(milliseconds: 800), () {
                  if (lastReceivedMessageId.value == mostRecentIncoming.id) {
                    lastReceivedMessageId.value = '';
                  }
                });
                
                // Check if user is near bottom - if not, set flag instead of scrolling
                if (!isNearBottom.value) {
                  hasNewIncomingMessage.value = true;
                  debugPrint('📱 Messages: New incoming message(s) arrived, user is scrolled up - showing scroll indicator');
                } else {
                  // User is near bottom, auto-scroll
                  scrollToBottom(smooth: true);
                }
              } else {
                // Only sent messages (user's own), always scroll
                scrollToBottom(smooth: true);
              }
              
              debugPrint('🔄 Refreshed messages: Found ${newMessages.length} new message(s), ${updatedMessages.length} updated message(s)');
            } else if (updatedMessages.isNotEmpty) {
              debugPrint('🔄 Refreshed messages: Found ${newMessages.length} new message(s), ${updatedMessages.length} updated message(s)');
            }
          }
        }
      }
    } catch (e) {
      // Silently fail - don't spam logs with polling errors
      debugPrint('⚠️ Error refreshing messages (silent): $e');
    }
  }

  // Send message
  Future<void> sendMessage() async {
    // Safety guards
    if (messageInput.value.trim().isEmpty || selectedConversationId.value.isEmpty) {
      return;
    }
    
    if (_currentUserId == null) {
      debugPrint('❌ Messages: Current user ID is null, cannot send message');
      Get.snackbar(
        'Error',
        'User session invalid. Please login again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
        duration: const Duration(seconds: 2),
      );
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
    
    // Prevent sending message to self
    if (otherUserId == _currentUserId) {
      debugPrint('❌ Messages: Cannot send message to self (User ID: $otherUserId)');
      Get.snackbar(
        'Error',
        'Cannot send message to yourself.',
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
    // Prevent duplicate message IDs
    final existingMessageIds = conv.messages.map((m) => m.id).toSet();
    if (existingMessageIds.contains(tempMessageId)) {
      debugPrint('⚠️ Messages: Duplicate message ID detected, skipping optimistic update');
      return;
    }
    final updatedMessages = [...conv.messages, optimisticMessage];
    
    // Recalculate unread count using MessageUtils (sent messages don't count as unread)
    final unreadCount = MessageUtils.calculateUnreadCount(updatedMessages);
    
    final updatedConv = conv.copyWith(
      messages: updatedMessages,
      lastMessage: optimisticMessage.text,
      timestamp: optimisticMessage.timestamp,
      unreadCount: unreadCount,
    );
    
    // Update conversation and force immediate UI refresh
    conversations[convIndex] = updatedConv;
    conversations.refresh(); // Force GetX to detect the change immediately
    
    // Sort conversations by most recent message (Messenger-like behavior) - real-time
    _sortConversationsByTimestamp();
    
    // Always scroll for sent messages (user's own messages) - force scroll
    scrollToBottom(smooth: false, force: true);
    
    debugPrint('📤 Optimistic message added. Total messages: ${updatedConv.messages.length}');

    // Clear input immediately and stop typing indicator
    messageInput.value = '';
    messageController.clear();
    stopTyping();

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
        final apiMessage = MessageUtils.mapApiMessage(response.data!, _currentUserId);
        final currentConv = conversations[convIndex];
        
        // Check for duplicate message ID (shouldn't happen, but safety guard)
        final existingMessageIds = currentConv.messages.map((m) => m.id).toSet();
        if (existingMessageIds.contains(apiMessage.id) && apiMessage.id != tempMessageId) {
          debugPrint('⚠️ Messages: Duplicate message ID from API, removing optimistic message only');
          final updatedMessages = currentConv.messages.where((m) => m.id != tempMessageId).toList();
          conversations[convIndex] = currentConv.copyWith(messages: updatedMessages);
          conversations.refresh();
          return;
        }
        
        final updatedMessages = currentConv.messages.map((m) {
          return m.id == tempMessageId ? apiMessage : m;
        }).toList();
        
        // Remove duplicates (safety guard)
        final uniqueMessages = MessageUtils.removeDuplicateMessages(updatedMessages);

        // Recalculate unread count using MessageUtils (sent messages don't count as unread)
        final unreadCount = MessageUtils.calculateUnreadCount(uniqueMessages);
        
        // Preserve conversation name and avatar when updating
        final finalConv = currentConv.copyWith(
          messages: uniqueMessages,
          lastMessage: apiMessage.text,
          timestamp: apiMessage.timestamp,
          unreadCount: unreadCount,
          // Keep existing name and avatar - don't overwrite
        );
        // Update conversation and force immediate UI refresh
        conversations[convIndex] = finalConv;
        conversations.refresh(); // Force GetX to detect the change immediately
        
        // Sort conversations by most recent message (Messenger-like behavior) - real-time
        _sortConversationsByTimestamp();
        
        // Always scroll for sent messages (user's own messages) - force scroll
        scrollToBottom(smooth: false, force: true);

        debugPrint('✅ Message sent successfully. Total messages: ${finalConv.messages.length}');
        debugPrint('   - Conversation name preserved: ${finalConv.name}');
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
    _userProfileImages.clear();
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
            
            // Parse is_read from API response if available
            bool? isRead;
            if (response.data != null) {
              final isReadValue = response.data!['is_read'];
              if (isReadValue != null) {
                if (isReadValue is bool) {
                  isRead = isReadValue;
                } else if (isReadValue is int) {
                  isRead = isReadValue == 1;
                } else if (isReadValue is String) {
                  isRead = isReadValue == '1' || isReadValue.toLowerCase() == 'true';
                }
              }
            }
            
            final updatedMessage = updatedMessages[messageIndex].copyWith(
              text: editMessageText.value.trim(),
              timestamp: DateTime.now(), // Update timestamp to reflect edit time
              isRead: isRead ?? updatedMessages[messageIndex].isRead, // Preserve existing isRead if not in response
            );
            updatedMessages[messageIndex] = updatedMessage;
            
            // If this is the last message, update conversation timestamp and last message
            final isLastMessage = messageIndex == updatedMessages.length - 1;
            final newTimestamp = isLastMessage ? updatedMessage.timestamp : conv.timestamp;
            final newLastMessage = isLastMessage ? updatedMessage.text : conv.lastMessage;
            
            conversations[convIndex] = conv.copyWith(
              messages: updatedMessages,
              lastMessage: newLastMessage,
              timestamp: newTimestamp,
            );
            
            // Sort conversations by most recent message (Messenger-like behavior)
            _sortConversationsByTimestamp();
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
          
          // Save current scroll position before updating
          double? savedScrollPosition;
          if (messagesScrollController.hasClients) {
            savedScrollPosition = messagesScrollController.position.pixels;
          }
          
          final updatedMessages = conv.messages.where((m) => m.id != message.id).toList();
          
          // Find the index of the deleted message to adjust scroll position
          final deletedIndex = conv.messages.indexWhere((m) => m.id == message.id);
          
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
          
          // Sort conversations by most recent message (Messenger-like behavior)
          _sortConversationsByTimestamp();
          
          // Restore scroll position after update (preserve position when deleting)
          if (savedScrollPosition != null && messagesScrollController.hasClients) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (messagesScrollController.hasClients) {
                // Adjust scroll position: if deleted message was above current view, 
                // we need to account for its height. For simplicity, just restore the position.
                // If the deleted message was below current view, position stays the same.
                final newMaxScroll = messagesScrollController.position.maxScrollExtent;
                final adjustedPosition = savedScrollPosition! > newMaxScroll 
                    ? newMaxScroll 
                    : savedScrollPosition;
                messagesScrollController.jumpTo(adjustedPosition);
              }
            });
          }
        }
        
        // Unfocus text field and close keyboard after deleting message
        messageFocusNode.unfocus();

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

/// App lifecycle observer to handle background/foreground transitions
class AppLifecycleObserver extends WidgetsBindingObserver {
  final VoidCallback onPaused;
  final VoidCallback onResumed;

  AppLifecycleObserver({
    required this.onPaused,
    required this.onResumed,
  });

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        onPaused();
        break;
      case AppLifecycleState.resumed:
        onResumed();
        break;
      case AppLifecycleState.hidden:
        // Do nothing for hidden state
        break;
    }
  }
}

