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
    await Get.bottomSheet(
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
                Get.back();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF00B8A9)),
              title: const Text('Gallery'),
              onTap: () {
                Get.back();
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  /// Pick image from camera or gallery
  Future<void> _pickImage(ImageSource source) async {
    try {
      // Request permission for camera if needed
      if (source == ImageSource.camera) {
        final status = await Permission.camera.request();
        if (!status.isGranted) {
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
        final status = await Permission.photos.request();
        if (!status.isGranted && !status.isLimited) {
          // Try alternative permission for older iOS versions
          final status2 = await Permission.storage.request();
          if (!status2.isGranted) {
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

      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85, // Compress to reduce file size
        maxWidth: 1920, // Limit max width
        maxHeight: 1920, // Limit max height
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        
        // Check file size (max 10MB)
        final fileSize = await file.length();
        const maxSize = 10 * 1024 * 1024; // 10MB
        
        if (fileSize > maxSize) {
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

        selectedImage.value = file;
        debugPrint('✅ Image selected: ${file.path}');
      }
    } catch (e) {
      debugPrint('❌ Error picking image: $e');
      Get.snackbar(
        'Error',
        'Failed to pick image. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
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

    // Store image file reference BEFORE clearing (needed for API call)
    final imageFile = hasImage ? selectedImage.value : null;
    
    // Add user message
    final messageText = hasText ? inputMessage.value.trim() : null;
    final imagePath = hasImage ? selectedImage.value!.path : null;
    
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: messageText,
      imagePath: imagePath,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    );

    messages.add(userMessage);
    _saveMessagesToStorage(); // Save to local storage
    _scrollToBottom(); // Scroll to show most recent message

    // Clear input and image (after storing reference)
    inputMessage.value = '';
    messageController.clear();
    selectedImage.value = null;

    // Show typing indicator
    isTyping.value = true;
    isSending.value = hasText;
    isSendingImage.value = hasImage;
    errorMessage.value = '';

    try {
      // Call AI Coach API (supports both text-only and text+image)
      // If image is present, it will be converted to Base64 and included in the request
      final messageToSend = messageText ?? ''; // Use empty string if no text (image-only)
      
      final response = await _aiCoachRepository.getAiCoachReply(
        apiToken: apiToken,
        message: messageToSend,
        imageFile: imageFile,
      );

      if (response.isSuccess && response.data != null) {
        // Extract AI reply from response
        final aiReply = response.data!['ai_coach_reply'] as String?;
        
        if (aiReply != null && aiReply.isNotEmpty) {
          final aiResponse = ChatMessage(
            id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
            text: aiReply,
            sender: MessageSender.ai,
            timestamp: DateTime.now(),
          );

          messages.add(aiResponse);
          _saveMessagesToStorage();
          _scrollToBottom();
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
          _saveMessagesToStorage();
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
        _saveMessagesToStorage();

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
      _saveMessagesToStorage();

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
        'imagePath': message.imagePath, // Save image path
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
                text: messageData['text'] as String?,
                imagePath: messageData['imagePath'] as String?,
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

