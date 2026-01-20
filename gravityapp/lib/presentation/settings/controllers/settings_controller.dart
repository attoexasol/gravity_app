import 'dart:io';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:gravityapp/data/model/notification_log.dart';
import 'package:gravityapp/data/model/sync_log.dart';
import 'package:gravityapp/data/model/user_account_info.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../../../core/services/preferences_service.dart';
import '../screens/sections/profile_image_picker_modal.dart';
import '../../../core/services/health_sync_service.dart'
    show HealthSyncService, HealthPlatform, SyncActivity;
import '../../../data/model/health_permissions.dart';
import '../../../data/model/notification_preferences.dart';
import '../../../data/repositories/goals_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../core/services/api_service.dart';
import '../../aicoach/controllers/ai_coach_controller.dart';
import '../../dashboard/controllers/dashboard_controller.dart';

class SettingsController extends GetxController {
  // Services
  final HealthSyncService _healthService = HealthSyncService();
  final GoalsRepository _goalsRepository = GoalsRepository();
  final AuthRepository _authRepository = AuthRepository();
  final ImagePicker _imagePicker = ImagePicker();
  final ApiService _apiService = ApiService();

  // Notification preferences
  final Rx<NotificationPreferences> notificationPrefs =
      NotificationPreferences().obs;

  // Health permissions
  final Rx<HealthPermissions> healthPermissions =
      HealthPermissions.defaultPermissions().obs;

  // UI State
  final RxBool showGoalsEditor = false.obs;
  final RxBool showSyncLogs = false.obs;
  final RxBool showNotificationLogs = false.obs;
  final RxBool isCheckingPermissions = false.obs;
  final RxBool aiFeatures = true.obs;
  final RxBool isLoadingGoals = false.obs;
  final RxBool isUpdatingNotifications = false.obs;
  final RxBool isDeletingAccount = false.obs;

  // Goals
  final RxMap<String, String> goals = <String, String>{
    'currentWeight': '75',
    'targetWeight': '70',
    'stepGoal': '12000',
    'waterIntake': '3',
    'sleepHours': '7-8',
    'aiTone': 'encouraging', // Default AI tone
  }.obs;

  // Sync logs
  final RxList<SyncLog> syncLogs = <SyncLog>[].obs;

  // Notification logs
  final RxList<NotificationLog> notificationLogs = <NotificationLog>[].obs;

  // User account info
  final Rx<UserAccountInfo> user = UserAccountInfo(
    name: 'User',
    email: 'user@example.com',
    initials: 'U',
    profileImagePath: null,
  ).obs;

  // Profile image modal state
  final Rx<String?> tempImagePath = Rx<String?>(null);
  final Rx<Uint8List?> tempImageBytes = Rx<Uint8List?>(null);
  final RxBool isProcessingImage = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
    _fetchUserDataFromAPI(); // Fetch latest user data from API
    _loadSettings();
    _loadGoals();
    _fetchGoalsFromAPI();
    _initializeHealthPermissions();
    _loadSyncLogs();
    _subscribeToSyncActivity();
  }

  @override
  void onReady() {
    super.onReady();
    // Reload user data when page becomes visible to ensure profile image persists
    _loadUserData();
    _fetchUserDataFromAPI(); // Fetch latest user data from API
  }

  /// Fetch user data from API
  Future<void> _fetchUserDataFromAPI() async {
    try {
      debugPrint('🔄 Fetching user data from API...');
      final response = await _authRepository.getSingleUser();

      if (response.isSuccess && response.data != null) {
        final userData = response.data!;
        
        // Update preferences with latest data from API
        if (userData.name.isNotEmpty) {
          await PreferencesService.saveUserName(userData.name);
        }
        if (userData.email.isNotEmpty) {
          await PreferencesService.saveUserEmail(userData.email);
        }
        if (userData.id > 0) {
          await PreferencesService.saveUserId(userData.id);
        }

        // Save profile image if available
        if (userData.profileImage != null && userData.profileImage!.isNotEmpty) {
          final profileImageUrl = userData.profileImage!;
          // Construct full URL if it's a relative path
          final fullImageUrl = profileImageUrl.startsWith('http')
              ? profileImageUrl
              : 'https://gravity.attoexasolutions.com/storage/$profileImageUrl';
          
          PreferencesService.getStorage().write('user_profile_image_url', fullImageUrl);
          debugPrint('✅ Profile image saved from API: $fullImageUrl');
        }

        // Update user reactive value
        final userInitials = UserAccountInfo.generateInitials(userData.name);
        final profileImageUrl = userData.profileImage != null && userData.profileImage!.isNotEmpty
            ? (userData.profileImage!.startsWith('http')
                ? userData.profileImage!
                : 'https://gravity.attoexasolutions.com/storage/${userData.profileImage!}')
            : PreferencesService.getStorage().read('user_profile_image_url') as String?;

        user.value = UserAccountInfo(
          name: userData.name,
          email: userData.email,
          initials: userInitials,
          profileImagePath: profileImageUrl,
        );

        debugPrint('✅ User data loaded from API: ${userData.name} (${userData.email})');
      } else {
        debugPrint('⚠️ Failed to fetch user data from API: ${response.message}');
        // Fallback to loading from storage
        _loadUserData();
      }
    } catch (e) {
      debugPrint('❌ Error fetching user data from API: $e');
      // Fallback to loading from storage
      _loadUserData();
    }
  }

  /// Load user data from storage
  void _loadUserData() {
    final userName = PreferencesService.getUserName() ?? 'User';
    final userEmail = PreferencesService.getUserEmail() ?? 'user@example.com';
    final userInitials = UserAccountInfo.generateInitials(userName);

    // Prefer API URL over local path
    final profileImageUrl =
        PreferencesService.getStorage().read('user_profile_image_url')
            as String?;
    final profileImagePath =
        profileImageUrl ??
        (PreferencesService.getStorage().read('user_profile_image') as String?);

    user.value = UserAccountInfo(
      name: userName,
      email: userEmail,
      initials: userInitials,
      profileImagePath: profileImagePath,
    );
  }

  /// Show profile image modal
  void showProfileImagePickerModal() {
    tempImagePath.value = null;
    tempImageBytes.value = null;
    Get.dialog(
      ProfileImagePickerModal(controller: this),
      barrierDismissible: true,
    );
  }

  /// Close profile image modal
  void closeProfileImageModal() {
    // Reset processing flag first to allow modal to close
    isProcessingImage.value = false;
    
    try {
      Get.closeCurrentSnackbar();
    } catch (e) {
      debugPrint('⚠️ Error closing snackbar: $e');
    }
    try {
      // Use Navigator directly for more reliable closing
      final context = Get.context;
      if (context != null && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        Get.back();
      }
    } catch (e) {
      debugPrint('⚠️ Error navigating back: $e');
      final context = Get.context;
      if (context != null) {
        try {
          Navigator.of(context).pop();
        } catch (e2) {
          debugPrint('⚠️ Navigator.pop() also failed: $e2');
        }
      }
    }
    tempImagePath.value = null;
    tempImageBytes.value = null;
  }

  /// Pick image from camera
  Future<void> pickImageFromCamera() async {
    try {
      debugPrint('📸 Opening camera...');
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
        maxWidth: 2048,
        maxHeight: 2048,
      );

      if (image != null) {
        debugPrint('✅ Image captured: ${image.path}');
        tempImagePath.value = image.path;

        // Load bytes for web compatibility
        try {
          final bytes = await image.readAsBytes();
          tempImageBytes.value = bytes;
          debugPrint('📊 Image size: ${bytes.length} bytes');
        } catch (e) {
          debugPrint('⚠️ Warning: Could not load image bytes: $e');
          // Continue anyway, bytes are optional for mobile
        }
      } else {
        debugPrint('⚠️ User cancelled camera');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Camera Error: $e');
      debugPrint('Stack trace: $stackTrace');

      String errorMessage = 'Failed to capture image. Please try again.';
      if (e.toString().contains('permission')) {
        errorMessage =
            'Camera permission denied. Please grant camera access in settings.';
      } else if (e.toString().contains('not available')) {
        errorMessage = 'Camera is not available on this device.';
      }

      _safeSnackbar(
        title: 'Error',
        message: errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  /// Pick image from gallery
  Future<void> pickImageFromGallery() async {
    try {
      debugPrint('🖼️ Opening gallery...');
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 2048,
        maxHeight: 2048,
      );

      if (image != null) {
        debugPrint('✅ Image selected: ${image.path}');
        tempImagePath.value = image.path;

        // Load bytes for web compatibility
        try {
          final bytes = await image.readAsBytes();
          tempImageBytes.value = bytes;
          debugPrint('📊 Image size: ${bytes.length} bytes');
        } catch (e) {
          debugPrint('⚠️ Warning: Could not load image bytes: $e');
          // Continue anyway, bytes are optional for mobile
        }
      } else {
        debugPrint('⚠️ User cancelled gallery selection');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Gallery Error: $e');
      debugPrint('Stack trace: $stackTrace');

      String errorMessage = 'Failed to pick image. Please try again.';
      if (e.toString().contains('permission')) {
        errorMessage =
            'Gallery permission denied. Please grant gallery access in settings.';
      } else if (e.toString().contains('not available')) {
        errorMessage = 'Gallery is not available on this device.';
      }

      _safeSnackbar(
        title: 'Error',
        message: errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }







/// Resize (if needed) and save profile image WITHOUT cropping
Future<void> saveProfileImage() async {
  if (tempImagePath.value == null && tempImageBytes.value == null) {
    _safeSnackbar(
      title: 'Error',
      message: 'No image selected. Please select an image first.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.withOpacity(0.8),
      colorText: Colors.white,
    );
    return;
  }

  try {
    isProcessingImage.value = true;

    final String? sourcePath = tempImagePath.value;
    final Uint8List? sourceBytes = tempImageBytes.value;

    debugPrint('📸 Saving profile image (no crop)');
    debugPrint('🌐 Is Web: $kIsWeb');

    // =========================
    // WEB (bytes-based)
    // =========================
    if (kIsWeb && sourceBytes != null && sourceBytes.isNotEmpty) {
      debugPrint('🌐 Processing image on web...');

      await _resizeProfileImageBytes(
        sourceBytes,
        saveToFile: false,
      );

      final resizedBytes = tempImageBytes.value;
      if (resizedBytes == null || resizedBytes.isEmpty) {
        throw Exception('Failed to resize image bytes');
      }

      await _uploadProfileImageBytes(resizedBytes);
      
      // Close modal immediately after upload completes
      closeProfileImageModal();
      
      // Show success message after a small delay to ensure modal is closed
      await Future.delayed(const Duration(milliseconds: 100));
      
      _safeSnackbar(
        title: 'Success',
        message: 'Profile image updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF00B8A9).withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    // =========================
    // MOBILE (file-based)
    // =========================
    if (sourcePath == null) {
      throw Exception('Image path is null');
    }

    final sourceFile = File(sourcePath);
    if (!sourceFile.existsSync()) {
      throw Exception('Image file does not exist');
    }

    final fileSize = await sourceFile.length();
    if (fileSize == 0) {
      throw Exception('Image file is empty');
    }

    debugPrint('📊 Original image size: $fileSize bytes');

    // Resize image to standard profile size (400x400)
    String? resizedImagePath;
    try {
      resizedImagePath = await _resizeProfileImage(sourcePath);
    } catch (e) {
      debugPrint('⚠️ Resize failed, using original image');
    }

    final imagePathToUpload = resizedImagePath ?? sourcePath;
    final imageFile = File(imagePathToUpload);

    if (!imageFile.existsSync() || await imageFile.length() == 0) {
      throw Exception('Processed image is invalid');
    }

    debugPrint('📁 Final image path: $imagePathToUpload');

    final token = PreferencesService.getAuthToken();
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token missing');
    }

    debugPrint('⬆️ Uploading profile image...');
    final uploadResponse = await _authRepository.uploadProfileImage(
      token: token,
      imageFile: imageFile,
    );

    if (uploadResponse.isSuccess && uploadResponse.data != null) {
      final profileImageUrl = uploadResponse.data!;

      PreferencesService.getStorage().write(
        'user_profile_image_url',
        profileImageUrl,
      );
      PreferencesService.getStorage().write(
        'user_profile_image',
        imagePathToUpload,
      );

      user.value = user.value.copyWith(
        profileImagePath: profileImageUrl,
      );

      // Close modal immediately after upload completes
      closeProfileImageModal();
      
      // Show success message after a small delay to ensure modal is closed
      await Future.delayed(const Duration(milliseconds: 100));

      _safeSnackbar(
        title: 'Success',
        message: uploadResponse.message.isNotEmpty
            ? uploadResponse.message
            : 'Profile image updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF00B8A9).withOpacity(0.8),
        colorText: Colors.white,
      );
    } else {
      // Fallback: local save only
      PreferencesService.getStorage().write(
        'user_profile_image',
        imagePathToUpload,
      );

      user.value = user.value.copyWith(
        profileImagePath: imagePathToUpload,
      );

      // Close modal immediately even if upload failed
      closeProfileImageModal();
      
      // Show warning message after a small delay to ensure modal is closed
      await Future.delayed(const Duration(milliseconds: 100));

      _safeSnackbar(
        title: 'Warning',
        message: uploadResponse.message.isNotEmpty
            ? uploadResponse.message
            : 'Image saved locally but upload failed',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  } catch (e, stackTrace) {
    debugPrint('❌ Profile image error: $e');
    debugPrint('$stackTrace');

    // Close modal even on error
    closeProfileImageModal();
    
    // Show error message after a small delay to ensure modal is closed
    Future.delayed(const Duration(milliseconds: 100), () {
      _safeSnackbar(
        title: 'Error',
        message: 'Failed to save profile image. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    });
  } finally {
    // Ensure processing flag is reset (closeProfileImageModal already does this, but double-check)
    if (isProcessingImage.value) {
      isProcessingImage.value = false;
    }
  }
}












  // /// Crop and save profile image
  // Future<void> cropAndSaveProfileImage() async {
  //   if (tempImagePath.value == null && tempImageBytes.value == null) {
  //     Get.snackbar(
  //       'Error',
  //       'No image selected. Please select an image first.',
  //       snackPosition: SnackPosition.BOTTOM,
  //       backgroundColor: Colors.red.withOpacity(0.8),
  //       colorText: Colors.white,
  //     );
  //     return;
  //   }

  //   try {
  //     isProcessingImage.value = true;

  //     String? sourcePath = tempImagePath.value;
  //     Uint8List? sourceBytes = tempImageBytes.value;

  //     debugPrint('🔍 Starting crop process...');
  //     debugPrint('📁 Source path: $sourcePath');
  //     debugPrint('📊 Source bytes: ${sourceBytes?.length ?? 0} bytes');
  //     debugPrint('🌐 Is Web: $kIsWeb');

  //     // For web, we need to handle bytes differently
  //     if (kIsWeb && sourceBytes != null && sourceBytes.isNotEmpty) {
  //       // On web, we'll process the image directly without native cropper
  //       // since image_cropper web support is limited
  //       debugPrint('🌐 Processing image on web platform...');
  //       await _resizeProfileImageBytes(sourceBytes, saveToFile: false);

  //       // Get the resized bytes from tempImageBytes
  //       final resizedBytes = tempImageBytes.value;
  //       if (resizedBytes != null && resizedBytes.isNotEmpty) {
  //         await _uploadProfileImageBytes(resizedBytes);
  //       } else {
  //         throw Exception('Failed to process image: Resized bytes are empty');
  //       }
  //       return;
  //     }

  //     // For mobile platforms, use native cropper
  //     if (sourcePath == null) {
  //       throw Exception('Image path is null. Cannot proceed with cropping.');
  //     }

  //     // Verify file exists
  //     final sourceFile = File(sourcePath);
  //     if (!sourceFile.existsSync()) {
  //       throw Exception('Image file does not exist at path: $sourcePath');
  //     }

  //     // Check file size
  //     final fileSize = await sourceFile.length();
  //     if (fileSize == 0) {
  //       throw Exception('Image file is empty (0 bytes)');
  //     }

  //     // Try to read a small portion to verify file is accessible
  //     try {
  //       final testBytes = await sourceFile
  //           .openRead(0, fileSize > 100 ? 100 : fileSize)
  //           .first;
  //       if (testBytes.isEmpty) {
  //         throw Exception('Cannot read image file. File may be corrupted.');
  //       }
  //       debugPrint('✅ File is readable');
  //     } catch (readError) {
  //       debugPrint('❌ Error reading file: $readError');
  //       throw Exception(
  //         'Cannot access image file. Please try selecting the image again.',
  //       );
  //     }

  //     debugPrint('✅ File exists and has $fileSize bytes');
  //     debugPrint('📸 Opening ImageCropper...');

  //     // Build platform-specific UI settings
  //     List<PlatformUiSettings> uiSettings = [];

  //     if (kIsWeb) {
  //       // Web UI settings - use basic settings for web
  //       uiSettings.add(
  //         WebUiSettings(
  //           context: Get.context!,
  //           presentStyle: WebPresentStyle.dialog,
  //         ),
  //       );
  //     } else {
  //       // Mobile UI settings
  //       uiSettings.addAll([
  //         AndroidUiSettings(
  //           toolbarTitle: 'Crop Profile Image',
  //           toolbarColor: const Color(0xFF0A2342),
  //           toolbarWidgetColor: Colors.white,
  //           initAspectRatio: CropAspectRatioPreset.square,
  //           lockAspectRatio: true,
  //           aspectRatioPresets: [CropAspectRatioPreset.square],
  //           hideBottomControls: false,
  //           showCropGrid: true,
  //           cropFrameColor: const Color(0xFF00B8A9),
  //           cropGridColor: const Color(0xFF00B8A9).withOpacity(0.5),
  //           cropGridStrokeWidth: 2,
  //           backgroundColor: Colors.black,
  //         ),
  //         IOSUiSettings(
  //           title: 'Crop Profile Image',
  //           aspectRatioLockEnabled: true,
  //           resetAspectRatioEnabled: false,
  //           aspectRatioPresets: [CropAspectRatioPreset.square],
  //           hidesNavigationBar: false,
  //           rotateButtonsHidden: false,
  //           rotateClockwiseButtonHidden: false,
  //         ),
  //       ]);
  //     }

  //     debugPrint('🎨 UI Settings configured for ${kIsWeb ? "web" : "mobile"}');

  //     // Verify context is available for web
  //     if (kIsWeb) {
  //       final context = Get.context;
  //       if (context == null) {
  //         throw Exception('Context is null. Cannot open image cropper.');
  //       }
  //       debugPrint('✅ Context available for web cropper');
  //     }

  //     // Call ImageCropper with better error handling
  //     CroppedFile? croppedFile;
  //     try {
  //       debugPrint('🔄 Calling ImageCropper.cropImage()...');
  //       debugPrint('📋 Parameters:');
  //       debugPrint('   - sourcePath: $sourcePath');
  //       debugPrint('   - aspectRatio: 1:1');
  //       debugPrint('   - compressFormat: JPG');
  //       debugPrint('   - compressQuality: 90');

  //       croppedFile = await ImageCropper().cropImage(
  //         sourcePath: sourcePath,
  //         aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
  //         uiSettings: uiSettings,
  //         compressFormat: ImageCompressFormat.jpg,
  //         compressQuality: 90,
  //         maxWidth: 800,
  //         maxHeight: 800,
  //       );

  //       if (croppedFile != null) {
  //         debugPrint('✅ ImageCropper returned file: ${croppedFile.path}');
  //       } else {
  //         debugPrint('⚠️ ImageCropper returned null (user may have cancelled)');
  //       }
  //     } catch (cropperError, cropperStack) {
  //       debugPrint('❌ ImageCropper Exception: $cropperError');
  //       debugPrint('Exception type: ${cropperError.runtimeType}');
  //       debugPrint('Stack trace: $cropperStack');

  //       // Re-throw with more context
  //       if (cropperError is PlatformException) {
  //         throw Exception(
  //           'Image cropper platform error: ${cropperError.message}',
  //         );
  //       } else {
  //         throw Exception(
  //           'Failed to open image cropper: ${cropperError.toString()}',
  //         );
  //       }
  //     }

  //     if (croppedFile != null) {
  //       debugPrint('✅ Image cropped successfully');
  //       debugPrint('📁 Cropped path: ${croppedFile.path}');

  //       // Verify cropped file exists
  //       final croppedFileCheck = File(croppedFile.path);
  //       if (!croppedFileCheck.existsSync()) {
  //         throw Exception(
  //           'Cropped file does not exist at: ${croppedFile.path}',
  //         );
  //       }

  //       final croppedFileSize = await croppedFileCheck.length();
  //       if (croppedFileSize == 0) {
  //         throw Exception('Cropped file is empty (0 bytes)');
  //       }

  //       debugPrint('📊 Cropped file size: $croppedFileSize bytes');

  //       // Resize image to fixed size (400x400 pixels for profile picture)
  //       debugPrint('🔄 Resizing image to 400x400...');
  //       String? resizedImagePath;
  //       try {
  //         resizedImagePath = await _resizeProfileImage(croppedFile.path);
  //       } catch (resizeError) {
  //         debugPrint('⚠️ Resize failed, will use cropped image: $resizeError');
  //         // Continue with cropped image if resize fails
  //       }

  //       // Use resized image if available, otherwise use original cropped image
  //       final imagePathToUpload = resizedImagePath ?? croppedFile.path;
  //       debugPrint('📁 Using image path: $imagePathToUpload');
  //       final imageFile = File(imagePathToUpload);

  //       // Verify file exists and has content
  //       if (!imageFile.existsSync()) {
  //         throw Exception(
  //           'Processed image file does not exist at: $imagePathToUpload',
  //         );
  //       }

  //       final fileSize = await imageFile.length();
  //       if (fileSize == 0) {
  //         throw Exception('Processed image file is empty (0 bytes)');
  //       }

  //       debugPrint('📊 Final image size: $fileSize bytes');
  //       debugPrint('📁 Final image path: $imagePathToUpload');

  //       // Get authentication token
  //       final token = PreferencesService.getAuthToken();
  //       if (token == null || token.isEmpty) {
  //         throw Exception(
  //           'Authentication token not found. Please login again.',
  //         );
  //       }

  //       // Upload profile image to API
  //       debugPrint('🔄 Uploading profile image to API...');
  //       final uploadResponse = await _authRepository.uploadProfileImage(
  //         token: token,
  //         imageFile: imageFile,
  //       );

  //       if (uploadResponse.isSuccess && uploadResponse.data != null) {
  //         // Save the API returned profile image URL
  //         final profileImageUrl = uploadResponse.data!;
  //         PreferencesService.getStorage().write(
  //           'user_profile_image_url',
  //           profileImageUrl,
  //         );

  //         // Also save local path for offline display
  //         PreferencesService.getStorage().write(
  //           'user_profile_image',
  //           imagePathToUpload,
  //         );

  //         // Update user info with the API URL
  //         user.value = user.value.copyWith(profileImagePath: profileImageUrl);
  //         debugPrint('✅ Profile image uploaded successfully: $profileImageUrl');

  //         // Close modal
  //         closeProfileImageModal();

  //         Get.snackbar(
  //           'Success',
  //           uploadResponse.message.isNotEmpty
  //               ? uploadResponse.message
  //               : 'Profile image updated successfully',
  //           snackPosition: SnackPosition.BOTTOM,
  //           backgroundColor: const Color(0xFF00B8A9).withOpacity(0.8),
  //           colorText: Colors.white,
  //           duration: const Duration(seconds: 2),
  //         );
  //       } else {
  //         // API upload failed, but save locally as fallback
  //         PreferencesService.getStorage().write(
  //           'user_profile_image',
  //           imagePathToUpload,
  //         );
  //         user.value = user.value.copyWith(profileImagePath: imagePathToUpload);
  //         closeProfileImageModal();

  //         Get.snackbar(
  //           'Warning',
  //           uploadResponse.message.isNotEmpty
  //               ? uploadResponse.message
  //               : 'Profile image saved locally, but upload failed. Please check your connection.',
  //           snackPosition: SnackPosition.BOTTOM,
  //           backgroundColor: Colors.orange.withOpacity(0.8),
  //           colorText: Colors.white,
  //           duration: const Duration(seconds: 3),
  //         );
  //       }
  //     } else {
  //       // User cancelled cropping
  //       debugPrint('⚠️ User cancelled image cropping');
  //       Get.snackbar(
  //         'Cancelled',
  //         'Image cropping was cancelled',
  //         snackPosition: SnackPosition.BOTTOM,
  //         backgroundColor: Colors.grey.withOpacity(0.8),
  //         colorText: Colors.white,
  //         duration: const Duration(seconds: 1),
  //       );
  //     }
  //   } catch (e, stackTrace) {
  //     debugPrint('❌ Error cropping profile image: $e');
  //     debugPrint('Error type: ${e.runtimeType}');
  //     debugPrint('Stack trace: $stackTrace');

  //     // Provide more specific error messages
  //     String errorMessage = 'Failed to process image. Please try again.';
  //     final errorString = e.toString().toLowerCase();

  //     if (errorString.contains('permission') ||
  //         errorString.contains('denied')) {
  //       errorMessage =
  //           'Permission denied. Please grant camera/gallery access in device settings.';
  //     } else if (errorString.contains('token') ||
  //         errorString.contains('auth')) {
  //       errorMessage = 'Authentication error. Please login again.';
  //     } else if (errorString.contains('does not exist') ||
  //         errorString.contains('file')) {
  //       errorMessage =
  //           'Image file error. Please try selecting the image again.';
  //     } else if (errorString.contains('empty') ||
  //         errorString.contains('0 bytes')) {
  //       errorMessage = 'Invalid image file. Please select a different image.';
  //     } else if (errorString.contains('cropper') ||
  //         errorString.contains('crop')) {
  //       errorMessage =
  //           'Failed to open image cropper. Please try again or restart the app.';
  //     } else if (errorString.contains('missingplugin') ||
  //         errorString.contains('gettemporarydirectory')) {
  //       errorMessage =
  //           'Plugin error: Please stop the app completely and rebuild it (not just hot reload). Go to: Run → Stop, then Run → Run again.';
  //     } else if (errorString.contains('plugin') ||
  //         errorString.contains('channel')) {
  //       errorMessage =
  //           'Plugin not initialized. Please stop and rebuild the app completely.';
  //     } else {
  //       // Show the actual error for debugging (first 100 chars)
  //       final detailedError = e.toString();
  //       if (detailedError.length > 100) {
  //         errorMessage = 'Error: ${detailedError.substring(0, 100)}...';
  //       } else {
  //         errorMessage = 'Error: $detailedError';
  //       }
  //     }

  //     Get.snackbar(
  //       'Error',
  //       errorMessage,
  //       snackPosition: SnackPosition.BOTTOM,
  //       backgroundColor: Colors.red.withOpacity(0.8),
  //       colorText: Colors.white,
  //       duration: const Duration(seconds: 4),
  //       mainButton: TextButton(
  //         onPressed: () {
  //           Get.back(); // Close snackbar
  //         },
  //         child: const Text('OK', style: TextStyle(color: Colors.white)),
  //       ),
  //     );
  //   } finally {
  //     isProcessingImage.value = false;
  //   }
  // }

  /// Resize profile image to fixed size (400x400 pixels)
  Future<String?> _resizeProfileImage(String imagePath) async {
    try {
      // Read image file
      final imageBytes = await File(imagePath).readAsBytes();
      return await _resizeProfileImageBytes(
        imageBytes,
        saveToFile: true,
        originalPath: imagePath,
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Error resizing profile image: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Resize profile image bytes to fixed size (400x400 pixels)
  /// Returns file path if saveToFile is true, otherwise returns null
  Future<String?> _resizeProfileImageBytes(
    Uint8List imageBytes, {
    bool saveToFile = false,
    String? originalPath,
  }) async {
    try {
      // Decode image
      final originalImage = img.decodeImage(imageBytes);

      if (originalImage == null) {
        debugPrint('❌ Failed to decode image');
        return null;
      }

      debugPrint(
        '📐 Original image size: ${originalImage.width}x${originalImage.height}',
      );

      // Fixed size for profile picture: 400x400 pixels
      const int targetSize = 400;

      // Calculate if we need to crop first to maintain aspect ratio
      int cropSize;
      int offsetX = 0;
      int offsetY = 0;

      if (originalImage.width > originalImage.height) {
        // Landscape: crop width
        cropSize = originalImage.height;
        offsetX = (originalImage.width - cropSize) ~/ 2;
      } else {
        // Portrait or square: crop height
        cropSize = originalImage.width;
        offsetY = (originalImage.height - cropSize) ~/ 2;
      }

      // Crop to square first if needed
      img.Image? processedImage;
      if (originalImage.width != originalImage.height) {
        processedImage = img.copyCrop(
          originalImage,
          x: offsetX,
          y: offsetY,
          width: cropSize,
          height: cropSize,
        );
        debugPrint('✂️ Cropped to square: ${cropSize}x$cropSize');
      } else {
        processedImage = originalImage;
      }

      // Resize image to fixed square size
      final resizedImage = img.copyResize(
        processedImage,
        width: targetSize,
        height: targetSize,
        interpolation: img.Interpolation.cubic,
      );

      debugPrint(
        '📐 Resized image size: ${resizedImage.width}x${resizedImage.height}',
      );

      // Encode to JPEG with good quality
      final resizedBytes = img.encodeJpg(resizedImage, quality: 90);
      debugPrint('📊 Resized image size: ${resizedBytes.length} bytes');

      if (saveToFile) {
        // Save to temporary directory with fallback
        String? resizedPath;
        try {
          final directory = await getTemporaryDirectory();
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          resizedPath = '${directory.path}/profile_image_$timestamp.jpg';
          final resizedFile = File(resizedPath);
          await resizedFile.writeAsBytes(resizedBytes);
          debugPrint('✅ Image resized and saved to: $resizedPath');
        } catch (e) {
          debugPrint('⚠️ Failed to get temp directory: $e');
          // Fallback: save next to original file if path provided
          if (originalPath != null) {
            try {
              final originalFile = File(originalPath);
              final directory = originalFile.parent;
              final timestamp = DateTime.now().millisecondsSinceEpoch;
              resizedPath = '${directory.path}/profile_image_$timestamp.jpg';
              final resizedFile = File(resizedPath);
              await resizedFile.writeAsBytes(resizedBytes);
              debugPrint(
                '✅ Image resized and saved to (fallback): $resizedPath',
              );
            } catch (fallbackError) {
              debugPrint('❌ Fallback also failed: $fallbackError');
              // Last resort: return original path and let upload handle it
              debugPrint('⚠️ Using original path as fallback');
              return originalPath;
            }
          } else {
            throw Exception(
              'Cannot save resized image: temp directory unavailable and no original path',
            );
          }
        }
        return resizedPath;
      } else {
        // Store bytes for web upload
        tempImageBytes.value = resizedBytes;
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error resizing profile image bytes: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Upload profile image bytes (for web platform)
  Future<void> _uploadProfileImageBytes(Uint8List imageBytes) async {
    try {
      // Get authentication token
      final token = PreferencesService.getAuthToken();
      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found. Please login again.');
      }

      // Save bytes to temporary file for upload with fallback
      File tempFile;
      try {
        final directory = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final tempPath = '${directory.path}/profile_upload_$timestamp.jpg';
        tempFile = File(tempPath);
        await tempFile.writeAsBytes(imageBytes);
        debugPrint('✅ Saved temp file for upload: $tempPath');
      } catch (e) {
        debugPrint('⚠️ Failed to get temp directory for upload: $e');
        // Fallback: try to use app documents directory or current directory
        try {
          if (!kIsWeb) {
            // For mobile, try app documents directory
            final appDir = await getApplicationDocumentsDirectory();
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            final tempPath = '${appDir.path}/profile_upload_$timestamp.jpg';
            tempFile = File(tempPath);
            await tempFile.writeAsBytes(imageBytes);
            debugPrint(
              '✅ Saved temp file to app directory (fallback): $tempPath',
            );
          } else {
            // For web, we might need to use a different approach
            throw Exception(
              'Cannot create temp file on web. Please rebuild the app.',
            );
          }
        } catch (fallbackError) {
          debugPrint('❌ All fallbacks failed: $fallbackError');
          throw Exception(
            'Cannot create temporary file. Please rebuild the app (stop and restart, not just hot reload).',
          );
        }
      }

      debugPrint('🔄 Uploading profile image to API (web)...');
      final uploadResponse = await _authRepository.uploadProfileImage(
        token: token,
        imageFile: tempFile,
      );

      if (uploadResponse.isSuccess && uploadResponse.data != null) {
        // Save the API returned profile image URL
        final profileImageUrl = uploadResponse.data!;
        PreferencesService.getStorage().write(
          'user_profile_image_url',
          profileImageUrl,
        );

        // Update user info with the API URL
        user.value = user.value.copyWith(profileImagePath: profileImageUrl);
        debugPrint('✅ Profile image uploaded successfully: $profileImageUrl');

        // Close modal
        closeProfileImageModal();

        _safeSnackbar(
          title: 'Success',
          message: uploadResponse.message.isNotEmpty
              ? uploadResponse.message
              : 'Profile image updated successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF00B8A9).withOpacity(0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      } else {
        throw Exception(
          uploadResponse.message.isNotEmpty
              ? uploadResponse.message
              : 'Upload failed',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error uploading profile image bytes: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Load settings from storage
  void _loadSettings() {
    // Load notification preferences from storage
    final savedNotifPrefs = PreferencesService.getStorage().read(
      'notification_preferences',
    );
    if (savedNotifPrefs != null) {
      try {
        final prefsMap = jsonDecode(savedNotifPrefs) as Map<String, dynamic>;
        notificationPrefs.value = NotificationPreferences(
          enabled: prefsMap['enabled'] ?? false,
          hydration: prefsMap['hydration'] ?? true,
          meals: prefsMap['meals'] ?? true,
          sleep: prefsMap['sleep'] ?? true,
          exercise: prefsMap['exercise'] ?? true,
          dailySummary: prefsMap['dailySummary'] ?? true,
          weeklySummary: prefsMap['weeklySummary'] ?? true,
          quietHoursEnabled: prefsMap['quietHoursEnabled'] ?? false,
          quietHoursStart: prefsMap['quietHoursStart'] ?? '10:00 PM',
          quietHoursEnd: prefsMap['quietHoursEnd'] ?? '8:00 AM',
        );
      } catch (e) {
        debugPrint('Error loading notification preferences: $e');
      }
    }

    // Load AI features setting
    final aiFeaturesValue = PreferencesService.getStorage().read('ai_features');
    if (aiFeaturesValue != null) {
      aiFeatures.value = aiFeaturesValue as bool;
    }
  }

  /// Load goals from storage
  void _loadGoals() {
    final savedGoals = PreferencesService.getStorage().read('userGoals');
    if (savedGoals != null) {
      try {
        final goalsMap = jsonDecode(savedGoals) as Map<String, dynamic>;
        goals.value = {
          'currentWeight': goalsMap['currentWeight']?.toString() ?? '75',
          'targetWeight': goalsMap['targetWeight']?.toString() ?? '70',
          'stepGoal': goalsMap['stepGoal']?.toString() ?? '12000',
          'waterIntake': goalsMap['waterIntake']?.toString() ?? '3',
          'sleepHours': goalsMap['sleepHours']?.toString() ?? '7-8',
          'aiTone': goalsMap['aiTone']?.toString() ?? 'encouraging',
        };
      } catch (e) {
        debugPrint('Error loading goals: $e');
      }
    }
  }

  /// Fetch goals from API
  Future<void> _fetchGoalsFromAPI() async {
    try {
      isLoadingGoals.value = true;

      // Get token from storage
      final token = PreferencesService.getAuthToken();
      if (token == null || token.isEmpty) {
        debugPrint('⚠️ Token not found, skipping API fetch');
        // Keep existing goals from storage if token is missing
        return;
      }

      final response = await _goalsRepository.getSingleGoal(token: token);

      if (response.isSuccess && response.data != null) {
        final goalData = response.data!;

        // Map API response to goals format
        // Remove "L" from water intake if present for display
        final waterIntake = goalData['daily_water_intake']?.toString() ?? '3';
        final waterIntakeValue = waterIntake
            .replaceAll('L', '')
            .replaceAll('l', '')
            .trim();

        goals.value = {
          'currentWeight': goalData['current_weight']?.toString() ?? '75',
          'targetWeight': goalData['target_weight']?.toString() ?? '70',
          'stepGoal': goalData['step_goal']?.toString() ?? '12000',
          'waterIntake': waterIntakeValue,
          'sleepHours': goalData['sleep_hours']?.toString() ?? '7-8',
          'aiTone': goalData['ai_tone']?.toString() ?? 'encouraging',
        };

        // Also save to local storage
        final goalsMap = Map<String, String>.from(goals);
        PreferencesService.getStorage().write(
          'userGoals',
          jsonEncode(goalsMap),
        );

        debugPrint('✅ Goals loaded from API: $goalsMap');
      } else {
        debugPrint('⚠️ Failed to load goals from API: ${response.message}');
        // Keep existing goals from storage if API fails
      }
    } catch (e) {
      debugPrint('❌ Error fetching goals from API: $e');
      // Keep existing goals from storage if API fails
    } finally {
      isLoadingGoals.value = false;
    }
  }

  /// Initialize health permissions
  void _initializeHealthPermissions() {
    // Check current permissions
    healthPermissions.value = HealthPermissions(
      steps: PermissionStatus.granted, // Default for now
      sleep: PermissionStatus.granted,
      heartRate: PermissionStatus.granted,
      lastChecked: DateTime.now(),
    );
  }

  /// Recheck health permissions
  Future<void> recheckPermissions() async {
    isCheckingPermissions.value = true;
    try {
      // Simulate permission check
      await Future.delayed(const Duration(seconds: 1));

      healthPermissions.value = HealthPermissions(
        steps: PermissionStatus.granted,
        sleep: PermissionStatus.granted,
        heartRate: PermissionStatus.granted,
        lastChecked: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error checking permissions: $e');
    } finally {
      isCheckingPermissions.value = false;
    }
  }

  /// Toggle notification preference
  void toggleNotificationPreference(String key, bool value) {
    final current = notificationPrefs.value;
    NotificationPreferences updated;
    final previousValue = _getPreviousValue(current, key);

    switch (key) {
      case 'enabled':
        updated = current.copyWith(enabled: value);
        break;
      case 'hydration':
        updated = current.copyWith(hydration: value);
        break;
      case 'meals':
        updated = current.copyWith(meals: value);
        break;
      case 'sleep':
        updated = current.copyWith(sleep: value);
        break;
      case 'exercise':
        updated = current.copyWith(exercise: value);
        break;
      case 'dailySummary':
        updated = current.copyWith(dailySummary: value);
        break;
      case 'weeklySummary':
        updated = current.copyWith(weeklySummary: value);
        break;
      case 'quietHoursEnabled':
        updated = current.copyWith(quietHoursEnabled: value);
        break;
      default:
        updated = current;
    }

    notificationPrefs.value = updated;
    _saveNotificationPreferences();
    
    // Sync with backend
    updateNotificationSettings(
      previousValue: previousValue,
      revertedKey: key,
    );
  }

  /// Get previous value for a notification preference key
  bool _getPreviousValue(NotificationPreferences prefs, String key) {
    switch (key) {
      case 'enabled':
        return prefs.enabled;
      case 'hydration':
        return prefs.hydration;
      case 'meals':
        return prefs.meals;
      case 'sleep':
        return prefs.sleep;
      case 'exercise':
        return prefs.exercise;
      case 'dailySummary':
        return prefs.dailySummary;
      case 'weeklySummary':
        return prefs.weeklySummary;
      case 'quietHoursEnabled':
        return prefs.quietHoursEnabled;
      default:
        return false;
    }
  }

  /// Update notification settings on backend
  Future<void> updateNotificationSettings({
    bool? previousValue,
    String? revertedKey,
  }) async {
    if (isUpdatingNotifications.value) {
      // Prevent concurrent updates
      return;
    }

    try {
      isUpdatingNotifications.value = true;

      // Get token from storage
      final token = PreferencesService.getAuthToken();
      if (token == null || token.isEmpty) {
        _safeSnackbar(
          title: 'Error',
          message: 'Authentication token not found. Please login again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
          duration: const Duration(seconds: 4),
        );
        
        // Revert the toggle if we have previous value
        if (previousValue != null && revertedKey != null) {
          _revertNotificationPreference(revertedKey, previousValue);
        }
        return;
      }

      // Get current notification preferences
      final prefs = notificationPrefs.value;

      // Map notification preferences to API format
      final requestBody = {
        'token': token,
        'is_notification_allowed': prefs.enabled ? 1 : 0,
        'is_hydration_notify': prefs.hydration ? 1 : 0,
        'is_meal_notify': prefs.meals ? 1 : 0,
        'is_sleep_notify': prefs.sleep ? 1 : 0,
        'is_excercise_notify': prefs.exercise ? 1 : 0,
        'is_ai_daily_sumery_notify': prefs.dailySummary ? 1 : 0,
        'is_ai_weekly_sumery_notify': prefs.weeklySummary ? 1 : 0,
      };

      debugPrint('🔄 Updating notification settings...');
      debugPrint('📦 Request body: ${jsonEncode(requestBody)}');

      // Make POST request to API
      final response = await _apiService.post(
        '/update_notification',
        body: requestBody,
      );

      // Check response
      final status = response['status'] as bool? ?? false;
      final message = response['message'] as String? ?? '';

      if (status) {
        // Success - update notification preferences with response data if available
        final data = response['data'] as Map<String, dynamic>?;
        if (data != null) {
          notificationPrefs.value = NotificationPreferences(
            enabled: (data['is_notification_allowed'] as int? ?? 0) == 1,
            hydration: (data['is_hydration_notify'] as int? ?? 0) == 1,
            meals: (data['is_meal_notify'] as int? ?? 0) == 1,
            sleep: (data['is_sleep_notify'] as int? ?? 0) == 1,
            exercise: (data['is_excercise_notify'] as int? ?? 0) == 1,
            dailySummary: (data['is_ai_daily_sumery_notify'] as int? ?? 0) == 1,
            weeklySummary: (data['is_ai_weekly_sumery_notify'] as int? ?? 0) == 1,
            quietHoursEnabled: notificationPrefs.value.quietHoursEnabled,
            quietHoursStart: notificationPrefs.value.quietHoursStart,
            quietHoursEnd: notificationPrefs.value.quietHoursEnd,
          );
          _saveNotificationPreferences();
        }

        // Show success snackbar
        _safeSnackbar(
          title: 'Success',
          message: message.isNotEmpty
              ? message
              : 'Notification settings updated successfully.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF00B8A9).withOpacity(0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );

        debugPrint('✅ Notification settings updated successfully');
      } else {
        // API returned error
        throw Exception(message.isNotEmpty ? message : 'Failed to update notification settings');
      }
    } catch (e) {
      debugPrint('❌ Error updating notification settings: $e');

      // Revert the toggle state
      if (previousValue != null && revertedKey != null) {
        _revertNotificationPreference(revertedKey, previousValue);
      }

      // Show error snackbar
      String errorMessage = 'Failed to update notification settings. Please try again.';
      if (e.toString().contains('token') || e.toString().contains('auth')) {
        errorMessage = 'Authentication error. Please login again.';
      } else if (e.toString().contains('network') || e.toString().contains('connection')) {
        errorMessage = 'Network error. Please check your connection and try again.';
      }

      _safeSnackbar(
        title: 'Error',
        message: errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isUpdatingNotifications.value = false;
    }
  }

  /// Revert notification preference to previous value
  void _revertNotificationPreference(String key, bool previousValue) {
    final current = notificationPrefs.value;
    NotificationPreferences updated;

    switch (key) {
      case 'enabled':
        updated = current.copyWith(enabled: previousValue);
        break;
      case 'hydration':
        updated = current.copyWith(hydration: previousValue);
        break;
      case 'meals':
        updated = current.copyWith(meals: previousValue);
        break;
      case 'sleep':
        updated = current.copyWith(sleep: previousValue);
        break;
      case 'exercise':
        updated = current.copyWith(exercise: previousValue);
        break;
      case 'dailySummary':
        updated = current.copyWith(dailySummary: previousValue);
        break;
      case 'weeklySummary':
        updated = current.copyWith(weeklySummary: previousValue);
        break;
      case 'quietHoursEnabled':
        updated = current.copyWith(quietHoursEnabled: previousValue);
        break;
      default:
        updated = current;
    }

    notificationPrefs.value = updated;
    _saveNotificationPreferences();
  }

  /// Save notification preferences
  void _saveNotificationPreferences() {
    final prefs = notificationPrefs.value;
    final prefsMap = {
      'enabled': prefs.enabled,
      'hydration': prefs.hydration,
      'meals': prefs.meals,
      'sleep': prefs.sleep,
      'exercise': prefs.exercise,
      'dailySummary': prefs.dailySummary,
      'weeklySummary': prefs.weeklySummary,
      'quietHoursEnabled': prefs.quietHoursEnabled,
      'quietHoursStart': prefs.quietHoursStart,
      'quietHoursEnd': prefs.quietHoursEnd,
    };
    PreferencesService.getStorage().write(
      'notification_preferences',
      jsonEncode(prefsMap),
    );
  }

  /// Enable notifications
  Future<void> enableNotifications() async {
    // Request notification permission
    // TODO: Implement actual notification permission request
    toggleNotificationPreference('enabled', true);
  }

  /// Save goals
  Future<void> saveGoals() async {
    try {
      isLoadingGoals.value = true;

      // Save to local storage first
      final goalsMap = Map<String, String>.from(goals);
      PreferencesService.getStorage().write('userGoals', jsonEncode(goalsMap));

      // Get token from storage
      final token = PreferencesService.getAuthToken();
      if (token == null || token.isEmpty) {
        _safeSnackbar(
          title: 'Error',
          message: 'Authentication token not found. Please login again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
          duration: const Duration(seconds: 4),
        );
        return;
      }

      // Prepare water intake with "L" suffix for API
      final waterIntake = goals['waterIntake'] ?? '3';
      final waterIntakeWithUnit =
          waterIntake.endsWith('L') || waterIntake.endsWith('l')
          ? waterIntake
          : '$waterIntake L';

      // Get AI tone from goals map, default to 'encouraging' if not set
      final aiTone = goals['aiTone'] ?? 'encouraging';

      // Save to API
      final response = await _goalsRepository.createGoals(
        token: token,
        currentWeight: goals['currentWeight'] ?? '75',
        targetWeight: goals['targetWeight'] ?? '70',
        stepGoal: goals['stepGoal'] ?? '12000',
        dailyWaterIntake: waterIntakeWithUnit,
        sleepHours: goals['sleepHours'] ?? '7-8',
        aiTone: aiTone,
      );

      if (response.isSuccess) {
        showGoalsEditor.value = false;
        
        // Notify DashboardController immediately for real-time updates
        _notifyDashboardGoalsChanged();
        
        _safeSnackbar(
          title: 'Success',
          message: 'Goals saved successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF00B8A9),
          colorText: Colors.white,
        );
      } else {
        // Even if API fails, goals are saved locally, so notify dashboard
        _notifyDashboardGoalsChanged();
        
        _safeSnackbar(
          title: 'Warning',
          message: 'Goals saved locally but failed to sync with server',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint('❌ Error saving goals: $e');
      _safeSnackbar(
        title: 'Error',
        message: 'Failed to save goals. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } finally {
      isLoadingGoals.value = false;
    }
  }

  /// Notify DashboardController that goals have changed
  /// This provides real-time updates without polling
  void _notifyDashboardGoalsChanged() {
    try {
      // Check if DashboardController is registered and notify it
      if (Get.isRegistered<DashboardController>()) {
        final dashboardController = Get.find<DashboardController>();
        dashboardController.notifyGoalsChanged();
        debugPrint('✅ Notified DashboardController of goals change');
      } else {
        debugPrint('ℹ️ DashboardController not registered, will update on next navigation');
      }
    } catch (e) {
      debugPrint('⚠️ Error notifying DashboardController: $e');
      // Non-critical error - goals are saved, dashboard will update when navigated to
    }
  }

  /// Toggle AI features
  void toggleAiFeatures(bool value) {
    aiFeatures.value = value;
    PreferencesService.getStorage().write('ai_features', value);
  }

  /// Get platform name
  String getPlatformName() {
    final platform = _healthService.getMetrics().platform;
    switch (platform) {
      case HealthPlatform.apple:
        return 'Apple Health';
      case HealthPlatform.google:
        return 'Google Fit';
      case HealthPlatform.none:
        return 'Health App';
    }
  }

  /// Load sync logs from storage
  void _loadSyncLogs() {
    try {
      final savedLogs = PreferencesService.getStorage().read('sync_logs');
      if (savedLogs != null) {
        final logsList = jsonDecode(savedLogs) as List<dynamic>;
        syncLogs.value = logsList
            .map(
              (log) => SyncLog(
                status: log['status'] as String,
                timestamp: DateTime.parse(log['timestamp'] as String),
                error: log['error'] as String?,
                metrics: log['metrics'] as Map<String, dynamic>?,
              ),
            )
            .toList();
        // Sort by timestamp (newest first)
        syncLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }
    } catch (e) {
      debugPrint('Error loading sync logs: $e');
    }
  }

  /// Save sync logs to storage
  void _saveSyncLogs() {
    try {
      final logsJson = syncLogs
          .map(
            (log) => {
              'status': log.status,
              'timestamp': log.timestamp.toIso8601String(),
              'error': log.error,
              'metrics': log.metrics,
            },
          )
          .toList();
      PreferencesService.getStorage().write('sync_logs', jsonEncode(logsJson));
    } catch (e) {
      debugPrint('Error saving sync logs: $e');
    }
  }

  /// Subscribe to sync activity from HealthSyncService
  void _subscribeToSyncActivity() {
    _healthService.subscribeToSyncActivity((SyncActivity activity) {
      // Convert SyncActivity to SyncLog
      final log = SyncLog(
        status: activity.status,
        timestamp: activity.timestamp,
        error: activity.error,
        metrics: activity.metrics,
      );
      // Add to beginning of list
      syncLogs.insert(0, log);
      // Keep only last 50 logs
      if (syncLogs.length > 50) {
        syncLogs.removeRange(50, syncLogs.length);
      }
      // Save to storage
      _saveSyncLogs();
    });
  }

  /// Get sync logs
  List<SyncLog> getSyncLogs() {
    return syncLogs.toList();
  }

  /// Get notification logs
  List<NotificationLog> getNotificationLogs() {
    // Return mock logs for now
    return notificationLogs.toList();
  }

  /// Safely show snackbar with overlay check
  void _safeSnackbar({
    required String title,
    required String message,
    SnackPosition snackPosition = SnackPosition.BOTTOM,
    Color? backgroundColor,
    Color? colorText,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (isClosed) return;
    
    try {
      final context = Get.context;
      if (context != null) {
        // Check if overlay is available
        try {
          Overlay.of(context);
          Get.snackbar(
            title,
            message,
            snackPosition: snackPosition,
            backgroundColor: backgroundColor ?? Get.theme.colorScheme.error,
            colorText: colorText ?? Get.theme.colorScheme.onError,
            duration: duration,
          );
        } catch (overlayError) {
          debugPrint('⚠️ Overlay not available for snackbar: $overlayError');
        }
      } else {
        debugPrint('⚠️ Cannot show snackbar - context unavailable');
      }
    } catch (e) {
      debugPrint('⚠️ Error showing snackbar: $e');
    }
  }

  /// Navigate back
  /// Uses Navigator directly to avoid Get.back()'s internal snackbar closing logic
  void navigateBack() {
    // Don't try to close snackbars - Get.back() internally calls closeCurrentSnackbar()
    // which causes LateInitializationError. Use Navigator directly instead.
    
    try {
      final context = Get.context;
      if (context != null && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
        debugPrint('✅ Navigated back via Navigator.pop()');
        return;
      }
    } catch (e) {
      debugPrint('⚠️ Navigator.pop() failed: $e');
    }
    
    // Fallback: try Get.back() if Navigator fails (but this may still cause errors)
    try {
      Get.back();
      debugPrint('✅ Navigated back via Get.back()');
    } catch (e) {
      debugPrint('⚠️ Get.back() also failed: $e - Navigation may have already occurred');
    }
  }

  /// Handle logout - calls API, clears auth data and navigates to login
  /// Preserves onboarding status to prevent it from showing again
  Future<void> handleLogout() async {
    final confirmed = await Get.dialog<bool>(
      _buildLogoutDialog(),
      barrierDismissible: true,
    );

    if (confirmed == true) {
      try {
        // Get token from storage
        final token = PreferencesService.getAuthToken();

        // Call logout API if token exists
        if (token != null && token.isNotEmpty) {
          final response = await _authRepository.logout(token: token);

          if (!response.isSuccess) {
            debugPrint('⚠️ Logout API call failed: ${response.message}');
            // Continue with logout even if API call fails
          }
        }

        // Clear AI Coach messages from storage before clearing auth data
        // This ensures previous user's messages don't show for new user
        if (Get.isRegistered<AiCoachController>()) {
          final aiCoachController = Get.find<AiCoachController>();
          aiCoachController.clearMessages();
          Get.delete<AiCoachController>(force: true);
        } else {
          // If controller doesn't exist, clear messages directly from storage
          final storage = PreferencesService.getStorage();
          storage.remove('ai_coach_messages');
          debugPrint('✅ Cleared AI Coach messages from storage (controller not registered)');
        }

        // Clear authentication data while preserving onboarding status
        // Use clearAuthData() instead of clearAll() to safely preserve onboarding
        await PreferencesService.clearAuthData();

        // Navigate to login screen and clear navigation stack
        Get.offAllNamed('/login');
      } catch (e) {
        debugPrint('❌ Logout Error: $e');

        // Even if API call fails, clear local data and logout
        try {
          // Use clearAuthData() to preserve onboarding
          await PreferencesService.clearAuthData();
          Get.offAllNamed('/login');
        } catch (clearError) {
          debugPrint('❌ Error clearing storage: $clearError');
          _safeSnackbar(
            title: 'Error',
            message: 'Failed to logout. Please try again.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Get.theme.colorScheme.error,
            colorText: Get.theme.colorScheme.onError,
          );
        }
      }
    }
  }

  /// Build logout confirmation dialog
  Widget _buildLogoutDialog() {
    return AlertDialog(
      title: const Text('Logout'),
      content: const Text(
        'Are you sure you want to logout? All your data will be cleared.',
      ),
      actions: [
        TextButton(
          onPressed: () {
            _safeBack(result: false);
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            _safeBack(result: true);
          },
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF00B8A9)),
          child: const Text('Logout'),
        ),
      ],
    );
  }

  /// Safely navigate back, handling snackbar errors
  /// Uses Navigator directly to avoid Get.back()'s internal snackbar closing logic
  void _safeBack({dynamic result}) {
    // Don't try to close snackbars - Get.back() internally calls closeCurrentSnackbar()
    // which causes LateInitializationError. Use Navigator directly instead.
    
    try {
      final context = Get.context;
      if (context != null && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(result);
        debugPrint('✅ Navigated back via Navigator.pop()');
        return;
      }
    } catch (e) {
      debugPrint('⚠️ Navigator.pop() failed: $e');
    }
    
    // Fallback: try Get.back() if Navigator fails (but this may still cause errors)
    try {
      if (Get.isDialogOpen == true) {
        Get.back(result: result);
        debugPrint('✅ Navigated back via Get.back()');
      }
    } catch (e) {
      debugPrint('⚠️ Get.back() also failed: $e - Navigation may have already occurred');
    }
  }

  /// Handle delete account - calls API, clears all storage data and navigates to login
  Future<void> handleDeleteAccount() async {
    if (isDeletingAccount.value) {
      return;
    }

    final confirmed = await Get.dialog<bool>(
      _buildDeleteAccountDialog(),
      barrierDismissible: true,
    );

    if (confirmed == true) {
      try {
        isDeletingAccount.value = true;

        // Get token from storage
        final token = PreferencesService.getAuthToken();
        if (token == null || token.isEmpty) {
          _safeSnackbar(
            title: 'Error',
            message: 'Authentication token not found. Please login again.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Get.theme.colorScheme.error,
            colorText: Get.theme.colorScheme.onError,
            duration: const Duration(seconds: 4),
          );
          return;
        }

        // Prepare request body
        final requestBody = {
          'token': token,
        };

        debugPrint('🔄 Deleting user account...');
        debugPrint('📦 Request body: ${jsonEncode(requestBody)}');

        // Make POST request to API
        final response = await _apiService.post(
          '/user/delete',
          body: requestBody,
        );

        // Check response
        final status = response['status'] as bool? ?? false;
        final message = response['message'] as String? ?? '';

        if (status) {
          // Success - clear all local storage including first-time setup status
          // This ensures that after account deletion, re-sign-up will be treated as first-time
          await PreferencesService.clearAllForAccountDeletion();

          // Show success snackbar
          _safeSnackbar(
            title: 'Success',
            message: message.isNotEmpty
                ? message
                : 'User deleted successfully',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFF00B8A9).withOpacity(0.8),
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );

          debugPrint('✅ User account deleted successfully');

          // Navigate to login screen and clear navigation stack
          await Future.delayed(const Duration(milliseconds: 500));
          Get.offAllNamed('/login');
        } else {
          // API returned error
          throw Exception(
            message.isNotEmpty ? message : 'Failed to delete account',
          );
        }
      } catch (e) {
        debugPrint('❌ Delete Account Error: $e');

        // Show error snackbar
        String errorMessage = 'Failed to delete account. Please try again.';
        if (e.toString().contains('token') || e.toString().contains('auth')) {
          errorMessage = 'Authentication error. Please login again.';
        } else if (e.toString().contains('network') ||
            e.toString().contains('connection')) {
          errorMessage =
              'Network error. Please check your connection and try again.';
        }

        _safeSnackbar(
          title: 'Error',
          message: errorMessage,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
          duration: const Duration(seconds: 4),
        );
      } finally {
        isDeletingAccount.value = false;
      }
    }
  }

  /// Build delete account confirmation dialog
  Widget _buildDeleteAccountDialog() {
    return AlertDialog(
      title: const Text('Delete Account'),
      content: const Text(
        'Are you sure you want to delete your account? This action is permanent and cannot be undone. All your data will be permanently deleted.',
      ),
      actions: [
        TextButton(
          onPressed: () {
            _safeBack(result: false);
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            _safeBack(result: true);
          },
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
