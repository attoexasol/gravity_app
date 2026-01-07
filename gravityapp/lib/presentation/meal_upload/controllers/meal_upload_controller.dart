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
        await _handleImageSelect(File(image.path));
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
        await _handleImageSelect(File(image.path));
      }
    } catch (e) {
      debugPrint('❌ Gallery Error: $e');
      error.value = 'Failed to select image';
    }
  }

  /// Handle image selection and analysis
  Future<void> _handleImageSelect(File imageFile) async {
    if (remainingAnalyses <= 0) {
      showLimitWarning.value = true;
      return;
    }

    error.value = null;
    selectedImagePath.value = imageFile.path;

    // Analyze meal
    isAnalyzing.value = true;
    try {
      final result = await _mealService.analyzeMeal(imageFile, 'gemini');
      analysis.value = result;
      _refreshStats(); // Refresh stats after analysis

      if (result.cached) {
        debugPrint('Using cached analysis');
      }
    } catch (e) {
      error.value = e.toString();
      selectedImagePath.value = null;
    } finally {
      isAnalyzing.value = false;
    }
  }

  /// Reset to initial state
  void reset() {
    selectedImagePath.value = null;
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
