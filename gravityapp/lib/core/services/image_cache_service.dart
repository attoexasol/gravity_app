import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Service for managing image cache, particularly for profile images
/// Ensures old user's images don't persist when new user logs in
class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();
  factory ImageCacheService() => _instance;
  ImageCacheService._internal();

  /// Clear all cached network images
  /// This is important on logout to prevent old user's images from showing
  static Future<void> clearImageCache() async {
    try {
      // Clear the default cache manager used by CachedNetworkImage
      await DefaultCacheManager().emptyCache();
      
      if (kDebugMode) {
        debugPrint('✅ Image cache cleared successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error clearing image cache: $e');
      }
    }
  }

  /// Clear cache for a specific image URL
  /// Useful when updating a profile image
  static Future<void> clearImageCacheForUrl(String url) async {
    try {
      await DefaultCacheManager().removeFile(url);
      
      if (kDebugMode) {
        debugPrint('✅ Image cache cleared for URL: $url');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error clearing image cache for URL: $e');
      }
    }
  }

  /// Clear all cached images and profile image data
  /// This is the recommended method to call on logout
  static Future<void> clearAllImageData() async {
    try {
      // Clear cached network images
      await clearImageCache();
      
      if (kDebugMode) {
        debugPrint('✅ All image data cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error clearing all image data: $e');
      }
    }
  }
}
