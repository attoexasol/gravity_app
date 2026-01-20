import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:gravityapp/data/model/ai_coach.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
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
  final RxBool isSendingImage = false.obs;
  final RxString errorMessage = ''.obs;
  
  // Image picker
  final ImagePicker _imagePicker = ImagePicker();
  final Rx<File?> selectedImage = Rx<File?>(null);
  bool _isPickingImage = false; // Flag to prevent double calls

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
    
    // Validate that stored messages belong to current user
    // If user ID changed (different user logged in), clear old messages
    _validateUserMessages();
    
    // Load saved messages from storage first (fast, immediate UI)
    _loadMessagesFromStorage();
    
    // Fetch chat history from server (async, non-blocking)
    // This ensures messages are restored after reinstall
    // The greeting will be shown in _fetchChatHistoryFromServer() if no messages exist
    _fetchChatHistoryFromServer();
    
    // Jump to bottom immediately after messages are loaded (no animation)
    // This prevents visible scrolling when screen first opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _jumpToBottom();
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

  /// Show image picker bottom sheet
  Future<void> showImagePickerOptions() async {
    // Guard: Prevent opening if controller is disposed
    if (isClosed) return;
    if (!Get.isRegistered<AiCoachController>()) return;

    // Guard: Prevent opening if bottom sheet is already open
    if (Get.isBottomSheetOpen == true) {
      debugPrint('⏸️ Bottom sheet already open, skipping');
      return;
    }

    // Guard: Prevent opening if already picking an image
    if (_isPickingImage == true) {
      debugPrint('⏸️ Already picking image, skipping');
      return;
    }

    // Dismiss keyboard before opening bottom sheet
    FocusManager.instance.primaryFocus?.unfocus();
    messageFocusNode.unfocus();

    // Show bottom sheet and await the selected ImageSource
    final ImageSource? source = await Get.bottomSheet<ImageSource>(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF0A2342).withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF00B8A9)),
              title: const Text('Camera'),
              onTap: () {
                // Use Navigator.pop() instead of Get.back() to avoid snackbar controller error
                try {
                  final context = Get.context;
                  if (context != null && Navigator.of(context).canPop()) {
                    Navigator.of(context).pop(ImageSource.camera);
                  } else {
                    // Fallback to Get.back() if Navigator fails
                    Get.back(result: ImageSource.camera);
                  }
                } catch (e) {
                  // Fallback to Get.back() if Navigator.pop() fails
                  try {
                    Get.back(result: ImageSource.camera);
                  } catch (e2) {
                    debugPrint('⚠️ Failed to close bottom sheet: $e2');
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF00B8A9)),
              title: const Text('Gallery'),
              onTap: () {
                // Use Navigator.pop() instead of Get.back() to avoid snackbar controller error
                try {
                  final context = Get.context;
                  if (context != null && Navigator.of(context).canPop()) {
                    Navigator.of(context).pop(ImageSource.gallery);
                  } else {
                    // Fallback to Get.back() if Navigator fails
                    Get.back(result: ImageSource.gallery);
                  }
                } catch (e) {
                  // Fallback to Get.back() if Navigator.pop() fails
                  try {
                    Get.back(result: ImageSource.gallery);
                  } catch (e2) {
                    debugPrint('⚠️ Failed to close bottom sheet: $e2');
                  }
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );

    // If no source was selected (user dismissed bottom sheet), return
    if (source == null) {
      return;
    }

    // Guard: Check again if controller is still valid
    if (isClosed) return;
    if (!Get.isRegistered<AiCoachController>()) return;

    // Delay to let bottom sheet fully close before opening image picker
    await Future.delayed(const Duration(milliseconds: 180));

    // Guard: Check again after delay
    if (isClosed) return;
    if (!Get.isRegistered<AiCoachController>()) return;

    // Dismiss keyboard again (important after bottom sheet closes)
    FocusManager.instance.primaryFocus?.unfocus();
    messageFocusNode.unfocus();

    // Call _pickImage with the selected source
    await _pickImage(source);
  }

  /// Pick image from camera or gallery
  Future<void> _pickImage(ImageSource source) async {
    // Guard: Prevent execution if controller is disposed
    if (isClosed) return;
    if (!Get.isRegistered<AiCoachController>()) return;

    // Guard: Prevent double calls
    if (_isPickingImage == true) {
      debugPrint('⏸️ Already picking image, skipping duplicate call');
      return;
    }

    // Set flag to prevent double calls
    _isPickingImage = true;

    try {
      // Request permission for camera if needed
      if (source == ImageSource.camera) {
        if (isClosed) return;
        final status = await Permission.camera.request();
        if (!status.isGranted) {
          if (isClosed) return;
          Get.snackbar(
            'Permission Denied',
            'Camera permission is required to take photos.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Get.theme.colorScheme.error,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
          return;
        }
      }

      // Request permission for photos if needed (iOS 14+)
      if (source == ImageSource.gallery) {
        if (isClosed) return;
        final status = await Permission.photos.request();
        if (!status.isGranted && !status.isLimited) {
          // Try alternative permission for older iOS versions
          if (isClosed) return;
          final status2 = await Permission.storage.request();
          if (!status2.isGranted) {
            if (isClosed) return;
            Get.snackbar(
              'Permission Denied',
              'Photo library permission is required to select images.',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Get.theme.colorScheme.error,
              colorText: Colors.white,
              duration: const Duration(seconds: 3),
            );
            return;
          }
        }
      }

      if (isClosed) return;
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85, // Compress to reduce file size
        maxWidth: 1920, // Limit max width
        maxHeight: 1920, // Limit max height
      );

      if (pickedFile != null) {
        if (isClosed) return;
        final file = File(pickedFile.path);
        
        // Check file size (max 10MB)
        final fileSize = await file.length();
        const maxSize = 10 * 1024 * 1024; // 10MB
        
        if (fileSize > maxSize) {
          if (isClosed) return;
          Get.snackbar(
            'Image Too Large',
            'Please select an image smaller than 10MB.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Get.theme.colorScheme.error,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
          return;
        }

        if (isClosed) return;
        
        // Dismiss keyboard after image selection
        FocusManager.instance.primaryFocus?.unfocus();
        messageFocusNode.unfocus();

        selectedImage.value = file;
        debugPrint('✅ Image selected: ${file.path}');
        
        // Send image immediately without showing preview
        // Use a small delay to ensure the image is set before sending
        await Future.delayed(const Duration(milliseconds: 100));
        if (isClosed) return;
        await sendMessage();
      }
    } catch (e) {
      if (isClosed) {
        _isPickingImage = false;
        return;
      }
      if (!Get.isRegistered<AiCoachController>()) {
        _isPickingImage = false;
        return;
      }
      debugPrint('❌ Error picking image: $e');
      Get.snackbar(
        'Error',
        'Failed to pick image. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      // Always reset the flag, even if an error occurred
      _isPickingImage = false;
    }
  }

  /// Remove selected image
  void removeSelectedImage() {
    selectedImage.value = null;
  }

  Future<void> sendMessage() async {
    // Check if there's anything to send
    final hasText = inputMessage.value.trim().isNotEmpty;
    final hasImage = selectedImage.value != null;
    
    if (!hasText && !hasImage) return; // Nothing to send
    if (isSending.value || isSendingImage.value) return; // Prevent duplicate calls
    if (isClosed) return; // Guard against disposed controller

    // Get auth token
    final apiToken = PreferencesService.getAuthToken();
    if (apiToken == null || apiToken.isEmpty) {
      if (isClosed) return;
      errorMessage.value = 'Please login to use AI Coach';
      // Show snackbar synchronously (before async operations)
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

    // Store image file reference BEFORE clearing (needed for API call)
    final imageFile = hasImage ? selectedImage.value : null;
    
    // Add user message (optimistic UI)
    final messageText = hasText ? inputMessage.value.trim() : null;
    final imagePath = hasImage ? selectedImage.value!.path : null;
    
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: messageText,
      imagePath: imagePath,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    );

    if (isClosed) return;
    messages.add(userMessage);
    _saveMessagesToStorage(); // Save to local storage
    _scrollToBottom(); // Scroll to show most recent message

    // Clear input and image (after storing reference)
    if (isClosed) return;
    inputMessage.value = '';
    messageController.clear();
    selectedImage.value = null;

    // Show typing indicator
    if (isClosed) return;
    isTyping.value = true;
    isSending.value = hasText;
    isSendingImage.value = hasImage;
    errorMessage.value = '';

    try {
      // Convert image to base64 if present
      String? imageBase64;
      if (hasImage && imageFile != null) {
        try {
          final imageBytes = await imageFile.readAsBytes();
          
          // Determine image MIME type from file extension
          String mimeType = 'image/png'; // Default
          final extension = imageFile.path.split('.').last.toLowerCase();
          if (extension == 'jpg' || extension == 'jpeg') {
            mimeType = 'image/jpeg';
          } else if (extension == 'png') {
            mimeType = 'image/png';
          } else if (extension == 'gif') {
            mimeType = 'image/gif';
          } else if (extension == 'webp') {
            mimeType = 'image/webp';
          }
          
          // Convert to Base64 with data URI prefix
          final base64Image = base64Encode(imageBytes);
          imageBase64 = 'data:$mimeType;base64,$base64Image';
          debugPrint('✅ Image converted to Base64: ${base64Image.length} chars, MIME: $mimeType');
        } catch (e) {
          debugPrint('⚠️ Error converting image to Base64: $e');
          if (isClosed) return;
          isTyping.value = false;
          isSending.value = false;
          isSendingImage.value = false;
          
          // Add error message to chat
          final errorResponse = ChatMessage(
            id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
            text: 'I couldn\'t analyze that right now. Please try again.',
            sender: MessageSender.ai,
            timestamp: DateTime.now(),
          );
          messages.add(errorResponse);
          _saveMessagesToStorage();
          return;
        }
      }

      // Call AI Coach API
      // Send EITHER message OR imageBase64, never both
      final response = await _aiCoachRepository.getAiCoachReply(
        apiToken: apiToken,
        message: hasText ? messageText : null,
        imageBase64: hasImage ? imageBase64 : null,
      );

      if (isClosed) return;

      if (response.isSuccess && response.data != null) {
        // Extract AI reply from response
        final aiReply = response.data!['ai_coach_reply'] as String?;
        
        // Extract nutrition value if present (image mode response)
        int? nutrition;
        final nutritionValue = response.data!['nutrition'];
        if (nutritionValue != null) {
          // Handle both int and string types from API
          if (nutritionValue is int) {
            nutrition = nutritionValue;
          } else if (nutritionValue is String) {
            nutrition = int.tryParse(nutritionValue);
          } else if (nutritionValue is num) {
            nutrition = nutritionValue.toInt();
          }
          if (nutrition != null) {
            debugPrint('📊 Nutrition value received: $nutrition calories');
          }
        }
        
        if (aiReply != null && aiReply.isNotEmpty) {
          final aiResponse = ChatMessage(
            id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
            text: aiReply,
            sender: MessageSender.ai,
            timestamp: DateTime.now(),
            nutrition: nutrition, // Store nutrition value in message
          );

          messages.add(aiResponse);
          _saveMessagesToStorage();
          _scrollToBottom();
          debugPrint('✅ AI Coach reply added to chat: ${aiReply.length > 50 ? "${aiReply.substring(0, 50)}..." : aiReply}');
        } else {
          // Fallback if ai_coach_reply is missing or empty
          final errorResponse = ChatMessage(
            id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
            text: 'I couldn\'t analyze that right now. Please try again.',
            sender: MessageSender.ai,
            timestamp: DateTime.now(),
          );
          messages.add(errorResponse);
          _saveMessagesToStorage();
          debugPrint('⚠️ AI Coach reply is empty or missing in response');
        }
      } else {
        // API failure - show system message in chat
        if (isClosed) return;
        errorMessage.value = response.message.isNotEmpty 
            ? response.message 
            : 'Failed to get AI response. Please try again.';
        
        // Add error message to chat (no Snackbar after async)
        final errorResponse = ChatMessage(
          id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
          text: 'I couldn\'t analyze that right now. Please try again.',
          sender: MessageSender.ai,
          timestamp: DateTime.now(),
        );
        messages.add(errorResponse);
        _saveMessagesToStorage();
        debugPrint('❌ AI Coach API error: ${errorMessage.value}');
      }
    } catch (e) {
      debugPrint('❌ Error sending message to AI Coach: $e');
      if (isClosed) return;
      
      errorMessage.value = 'An unexpected error occurred. Please try again.';
      
      // Add error message to chat (no Snackbar after async)
      final errorResponse = ChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        text: 'I couldn\'t analyze that right now. Please try again.',
        sender: MessageSender.ai,
        timestamp: DateTime.now(),
      );
      messages.add(errorResponse);
      _saveMessagesToStorage();
    } finally {
      if (isClosed) return;
      isTyping.value = false;
      isSending.value = false;
      isSendingImage.value = false;
    }
  }

  /// Save messages to local storage
  void _saveMessagesToStorage() {
    try {
      final storage = PreferencesService.getStorage();
      final messagesJson = messages.map((message) => {
        'id': message.id,
        'text': message.text,
        'imagePath': message.imagePath, // Save local image path
        'imageUrl': message.imageUrl, // Save network image URL
        'sender': message.sender == MessageSender.user ? 'user' : 'ai',
        'timestamp': message.timestamp.toIso8601String(),
        'nutrition': message.nutrition, // Save nutrition value if present
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
            
            // Extract nutrition value (may be int, string, or null)
            int? nutrition;
            final nutritionValue = messageData['nutrition'];
            if (nutritionValue != null) {
              if (nutritionValue is int) {
                nutrition = nutritionValue;
              } else if (nutritionValue is String) {
                nutrition = int.tryParse(nutritionValue);
              } else if (nutritionValue is num) {
                nutrition = nutritionValue.toInt();
              }
            }
            
            messages.add(
              ChatMessage(
                id: messageData['id'] as String,
                text: messageData['text'] as String?,
                imagePath: messageData['imagePath'] as String?,
                imageUrl: messageData['imageUrl'] as String?,
                sender: sender,
                timestamp: timestamp,
                nutrition: nutrition, // Load nutrition value from storage
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

  /// Jump to bottom immediately (no animation) - used when screen first opens
  void _jumpToBottom() {
    if (!messagesScrollController.hasClients) return;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!messagesScrollController.hasClients) return;
      
      final position = messagesScrollController.position;
      final maxScroll = position.maxScrollExtent;
      
      // Jump to bottom immediately without animation
      messagesScrollController.jumpTo(maxScroll);
    });
  }

  /// Scroll to bottom of messages list to show most recent chat (with animation)
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

  /// Fetch chat history from server
  /// This is called on controller init to restore messages after reinstall
  /// Merges server messages with local messages intelligently
  Future<void> _fetchChatHistoryFromServer() async {
    try {
      // Get auth token
      final apiToken = PreferencesService.getAuthToken();
      if (apiToken == null || apiToken.isEmpty) {
        debugPrint('⚠️ No auth token available, skipping server fetch');
        return;
      }

      debugPrint('🔄 Fetching chat history from server...');
      
      final response = await _aiCoachRepository.getChatHistory(
        apiToken: apiToken,
      );

      if (isClosed) return;

      if (response.isSuccess && response.data != null && response.data!.isNotEmpty) {
        debugPrint('✅ Received ${response.data!.length} messages from server');
        
        // Convert server messages to ChatMessage objects
        final serverMessages = <ChatMessage>[];
        
        for (final messageData in response.data!) {
          try {
            // Parse timestamp (server sends UTC, convert to local time for consistency)
            final createdAtStr = messageData['created_at'] as String?;
            DateTime? timestamp;
            if (createdAtStr != null) {
              final parsed = DateTime.tryParse(createdAtStr);
              if (parsed != null) {
                // Server timestamps are in UTC, convert to local time for display consistency
                timestamp = parsed.toLocal();
              }
            }
            timestamp ??= DateTime.now();

            // Extract nutrition value (handle API typo: "nutration" instead of "nutrition")
            int? nutrition;
            final nutritionValue = messageData['nutration'] ?? messageData['nutrition'];
            if (nutritionValue != null) {
              if (nutritionValue is int) {
                nutrition = nutritionValue;
              } else if (nutritionValue is String) {
                nutrition = int.tryParse(nutritionValue);
              } else if (nutritionValue is num) {
                nutrition = nutritionValue.toInt();
              }
            }

            // Get user message, AI message, and image URL
            final userMessage = messageData['user_message'] as String?;
            final aiMessage = messageData['ai_message'] as String?;
            final imageUrl = messageData['image'] as String?; // API returns "image" field
            final serverId = messageData['id'];

            // For image-only conversations: user_message is null but image exists
            // The image should be associated with the user message, not the AI message
            // Create user message if text is present OR if image exists (image-only conversation)
            if ((userMessage != null && userMessage.isNotEmpty) || (imageUrl != null && userMessage == null)) {
              final userMessageId = 'server_${serverId}_user';
              
              // Check if message already exists (avoid duplicates)
              final userExists = messages.any((m) => m.id == userMessageId);
              if (!userExists) {
                // User message timestamp: slightly before AI message to maintain conversation flow
                final userTimestamp = timestamp.subtract(const Duration(seconds: 1));
                
                serverMessages.add(
                  ChatMessage(
                    id: userMessageId,
                    text: userMessage, // Can be null for image-only messages
                    imageUrl: imageUrl, // Image URL goes to user message (the image they sent)
                    sender: MessageSender.user,
                    timestamp: userTimestamp,
                  ),
                );
                if (userMessage != null && userMessage.isNotEmpty) {
                  debugPrint('📥 Added user message from server: ${userMessage.length > 50 ? "${userMessage.substring(0, 50)}..." : userMessage}');
                } else if (imageUrl != null) {
                  debugPrint('📥 Added user image message from server (image-only)');
                }
              }
            }

            // Create AI message if present (AI message should NOT have the image URL)
            if (aiMessage != null && aiMessage.isNotEmpty) {
              final aiMessageId = 'server_${serverId}_ai';
              
              // Check if message already exists (avoid duplicates)
              final aiExists = messages.any((m) => m.id == aiMessageId);
              if (!aiExists) {
                serverMessages.add(
                  ChatMessage(
                    id: aiMessageId,
                    text: aiMessage,
                    // Note: imageUrl is NOT added to AI message - it belongs to the user message
                    sender: MessageSender.ai,
                    timestamp: timestamp,
                    nutrition: nutrition,
                  ),
                );
                debugPrint('📥 Added AI message from server: ${aiMessage.length > 50 ? "${aiMessage.substring(0, 50)}..." : aiMessage}');
              }
            }
          } catch (e) {
            debugPrint('⚠️ Error parsing server message: $e');
          }
        }

        if (serverMessages.isNotEmpty) {
          // Merge server messages with existing local messages
          // Strategy: 
          // 1. Remove local messages that match server messages (by content and approximate time)
          // 2. Add server messages that don't exist locally
          final existingIds = messages.map((m) => m.id).toSet();
          
          // Find and remove local messages that match server messages
          // This prevents duplicates when the same message exists with different IDs
          final messagesToRemove = <ChatMessage>[];
          for (final serverMsg in serverMessages) {
            // Check if a local message matches this server message
            for (final localMsg in messages) {
              // Skip if local message is already a server message
              if (localMsg.id.startsWith('server_')) continue;
              
              // Match by: same sender, same text (or both null/empty), same image (path or URL), and timestamp within 5 minutes
              final timeDiff = (localMsg.timestamp.difference(serverMsg.timestamp).abs().inMinutes);
              final textMatches = (localMsg.text ?? '') == (serverMsg.text ?? '');
              final senderMatches = localMsg.sender == serverMsg.sender;
              
              // For image messages: match if both have images (either path or URL)
              final imageMatches = (localMsg.hasImage && serverMsg.hasImage) || 
                                   (!localMsg.hasImage && !serverMsg.hasImage);
              
              if (senderMatches && textMatches && imageMatches && timeDiff <= 5) {
                messagesToRemove.add(localMsg);
                debugPrint('🔄 Removing duplicate local message: ${localMsg.id} (matches server: ${serverMsg.id})');
                break; // Found match, move to next server message
              }
            }
          }
          
          // Remove duplicate local messages
          for (final msg in messagesToRemove) {
            messages.remove(msg);
          }
          
          // Add server messages that don't exist locally
          final newMessages = serverMessages.where((m) => !existingIds.contains(m.id)).toList();
          
          if (newMessages.isNotEmpty || messagesToRemove.isNotEmpty) {
            // Add new messages from server
            messages.addAll(newMessages);
            
            // Sort all messages by timestamp (oldest first, newest last)
            messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
            
            // Save merged messages to storage
            _saveMessagesToStorage();
            
            debugPrint('✅ Merged ${newMessages.length} new messages from server');
            if (messagesToRemove.isNotEmpty) {
              debugPrint('🗑️ Removed ${messagesToRemove.length} duplicate local messages');
            }
            debugPrint('📊 Total messages: ${messages.length}');
            
            // Scroll to bottom to show latest messages
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToBottom();
            });
          } else {
            debugPrint('ℹ️ All server messages already exist locally');
          }
        } else {
          debugPrint('ℹ️ No valid messages found in server response');
        }
      } else {
        debugPrint('⚠️ Failed to fetch chat history: ${response.message}');
        // Don't show error to user - local messages are still available
      }
      
      // Show initial greeting ONLY if no messages exist after server fetch completes
      // This ensures greeting doesn't show when real messages are being loaded
      if (messages.isEmpty) {
        _loadInitialMessage();
        _saveMessagesToStorage(); // Save greeting to storage
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    } catch (e) {
      debugPrint('❌ Error fetching chat history from server: $e');
      // Don't show error to user - local messages are still available
      
      // Show greeting if no messages exist even after error
      if (messages.isEmpty) {
        _loadInitialMessage();
        _saveMessagesToStorage();
      }
    }
  }

  /// Validate that stored messages belong to current user
  /// Clears messages if user ID has changed (different user logged in)
  void _validateUserMessages() {
    try {
      final currentUserId = PreferencesService.getUserId();
      final storage = PreferencesService.getStorage();
      final lastUserId = storage.read('ai_coach_last_user_id');
      
      // If user ID exists and has changed, clear old messages
      if (currentUserId != null) {
        if (lastUserId != null && lastUserId != currentUserId) {
          debugPrint('🔄 User ID changed from $lastUserId to $currentUserId - clearing old messages');
          storage.remove(_messagesStorageKey);
          messages.clear();
        }
        // Save current user ID for next validation
        storage.write('ai_coach_last_user_id', currentUserId);
      } else if (lastUserId != null) {
        // Current user ID is null but we have a stored user ID - clear messages
        debugPrint('🔄 User logged out - clearing messages');
        storage.remove(_messagesStorageKey);
        storage.remove('ai_coach_last_user_id');
        messages.clear();
      }
    } catch (e) {
      debugPrint('⚠️ Error validating user messages: $e');
      // On error, clear messages to be safe
      final storage = PreferencesService.getStorage();
      storage.remove(_messagesStorageKey);
      messages.clear();
    }
  }

  /// Extract server message ID from local message ID
  /// Server messages have IDs like "server_4_user" or "server_4_ai"
  /// Returns the numeric ID (e.g., 4) or null if not a server message
  int? _extractServerMessageId(String messageId) {
    try {
      if (messageId.startsWith('server_')) {
        // Extract ID from "server_4_user" or "server_4_ai"
        final parts = messageId.split('_');
        if (parts.length >= 2) {
          final idStr = parts[1];
          return int.tryParse(idStr);
        }
      }
      return null;
    } catch (e) {
      debugPrint('⚠️ Error extracting server message ID: $e');
      return null;
    }
  }

  /// Delete a message (both from server and local storage)
  /// Shows confirmation dialog before deleting
  Future<void> deleteMessage(ChatMessage message) async {
    try {
      // Extract server message ID if this is a server message
      final serverId = _extractServerMessageId(message.id);
      
      // If it's a server message, delete from server first
      if (serverId != null) {
        final apiToken = PreferencesService.getAuthToken();
        if (apiToken != null && apiToken.isNotEmpty) {
          debugPrint('🔄 Deleting message from server (ID: $serverId)...');
          
          final response = await _aiCoachRepository.deleteMessage(
            apiToken: apiToken,
            messageId: serverId,
          );

          if (!response.isSuccess) {
            debugPrint('⚠️ Failed to delete message from server: ${response.message}');
            // Still delete locally even if server deletion fails
            // This ensures UI is updated even if network is down
          } else {
            debugPrint('✅ Message deleted from server successfully');
          }
        } else {
          debugPrint('⚠️ No auth token available, deleting locally only');
        }
      } else {
        debugPrint('ℹ️ Local message (not from server), deleting locally only');
      }

      // For server messages, remove both the user and AI messages with the same server ID
      // This ensures the entire conversation pair is removed from the UI
      if (serverId != null) {
        final userMessageId = 'server_${serverId}_user';
        final aiMessageId = 'server_${serverId}_ai';
        
        final removedCount = messages.length;
        messages.removeWhere((m) => m.id == userMessageId || m.id == aiMessageId);
        final newCount = messages.length;
        final deletedCount = removedCount - newCount;
        
        debugPrint('🗑️ Removed $deletedCount message(s) from UI (user + AI pair for server ID: $serverId)');
      } else {
        // For local messages, just remove the specific message
        messages.removeWhere((m) => m.id == message.id);
        debugPrint('🗑️ Removed local message from UI');
      }
      
      // Save updated messages to storage
      _saveMessagesToStorage();
      
      debugPrint('✅ Message(s) deleted successfully');
      
      // Scroll to maintain position (don't jump to bottom)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (messagesScrollController.hasClients) {
          final position = messagesScrollController.position;
          final currentScroll = position.pixels;
          final maxScroll = position.maxScrollExtent;
          
          // If we're near the bottom, stay at bottom
          // Otherwise, maintain current scroll position
          if (currentScroll >= maxScroll - 100) {
            _scrollToBottom();
          }
        }
      });
    } catch (e) {
      debugPrint('❌ Error deleting message: $e');
      rethrow;
    }
  }

  /// Clear all messages from storage (useful for logout or reset)
  void clearMessages() {
    messages.clear();
    final storage = PreferencesService.getStorage();
    storage.remove(_messagesStorageKey);
    storage.remove('ai_coach_last_user_id'); // Also clear user ID tracking
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
    // Ensure we're working with local time for display
    final localTime = dateTime.isUtc ? dateTime.toLocal() : dateTime;
    final hour = localTime.hour == 0 ? 12 : (localTime.hour > 12 ? localTime.hour - 12 : localTime.hour);
    final minute = localTime.minute.toString().padLeft(2, '0');
    final period = localTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

