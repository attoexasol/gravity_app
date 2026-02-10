import 'dart:io';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/meal_analysis_service.dart';
import '../../../data/model/meal_analysis.dart';

class MealUploadController extends GetxController {
  final MealAnalysisService _mealService = MealAnalysisService();
  final ImagePicker _imagePicker = ImagePicker();

  // State
  final Rx<String?> selectedImagePath = Rx<String?>(null);
  final Rx<MealAnalysis?> analysis = Rx<MealAnalysis?>(null);
  final RxBool isAnalyzing = false.obs;
  final Rx<String?> error = Rx<String?>(null);
  final RxBool showLimitWarning = false.obs;

  /// Optional meal context (max 150 chars). Bound to Review screen text field.
  static const int mealDetailsMaxLength = 150;
  final mealDetailsEditingController = TextEditingController();

  @override
  void onClose() {
    mealDetailsEditingController.dispose();
    super.onClose();
  }

  // Reactive computed properties
  int get remainingAnalyses => _mealService.getRemainingAnalyses();
  UsageStats get usageStats => _mealService.getUsageStats();

  // Trigger observable to force rebuilds when stats are accessed
  final RxInt statsTrigger = 0.obs;

  void _refreshStats() {
    statsTrigger.value = statsTrigger.value + 1;
  }

  /// Select image from camera
  Future<void> selectImageFromCamera() async {
    if (remainingAnalyses <= 0) {
      showLimitWarning.value = true;
      return;
    }

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        _setSelectedImageOnly(File(image.path));
      }
    } catch (e) {
      debugPrint('❌ Camera Error: $e');
      error.value = 'Failed to capture image';
    }
  }

  /// Select image from gallery
  Future<void> selectImageFromGallery() async {
    if (remainingAnalyses <= 0) {
      showLimitWarning.value = true;
      return;
    }

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        _setSelectedImageOnly(File(image.path));
      }
    } catch (e) {
      debugPrint('❌ Gallery Error: $e');
      error.value = 'Failed to select image';
    }
  }

  /// Set selected image in local state only (no upload). User must tap "Analyze Meal" to upload.
  void _setSelectedImageOnly(File imageFile) {
    error.value = null;
    selectedImagePath.value = imageFile.path;
    mealDetailsEditingController.clear();
  }

  /// Called when user taps "Analyze Meal". Uploads image and optional text, then runs AI analysis.
  Future<void> analyzeMeal() async {
    final path = selectedImagePath.value;
    if (path == null) return;
    if (remainingAnalyses <= 0) {
      showLimitWarning.value = true;
      return;
    }

    final imageFile = File(path);
    if (!await imageFile.exists()) {
      error.value = 'Selected image no longer available';
      return;
    }

    error.value = null;
    isAnalyzing.value = true;
    try {
      final details = mealDetailsEditingController.text.trim();
      final result = await _mealService.analyzeMeal(
        imageFile,
        'gemini',
        mealDetails: details.isEmpty ? null : details,
      );
      analysis.value = result;
      _refreshStats();

      if (result.cached) {
        debugPrint('Using cached analysis');
      }
    } catch (e) {
      error.value = e.toString();
    } finally {
      isAnalyzing.value = false;
    }
  }

  /// Clear selected image and optional text; return to upload state.
  void clearSelection() {
    selectedImagePath.value = null;
    mealDetailsEditingController.clear();
    error.value = null;
    analysis.value = null;
  }

  /// Reset to initial state (upload screen)
  void reset() {
    selectedImagePath.value = null;
    mealDetailsEditingController.clear();
    analysis.value = null;
    error.value = null;
  }

  /// Navigate back
  /// Uses Navigator directly to avoid Get.back()'s internal snackbar closing logic
  void navigateBack() {
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
    
    // Fallback: try Get.back() if Navigator fails
    try {
      Get.back();
      debugPrint('✅ Navigated back via Get.back()');
    } catch (e) {
      debugPrint('⚠️ Get.back() also failed: $e - Navigation may have already occurred');
    }
  }

  /// Close limit warning
  void closeLimitWarning() {
    showLimitWarning.value = false;
  }
}
