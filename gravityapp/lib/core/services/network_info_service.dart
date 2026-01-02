import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../utils/safe_logger.dart';

/// Network Info Service - Checks device connectivity status
class NetworkInfoService {
  static final NetworkInfoService _instance = NetworkInfoService._internal();
  factory NetworkInfoService() => _instance;
  NetworkInfoService._internal();

  final Connectivity _connectivity = Connectivity();

  /// Check if device has an active internet connection
  /// Returns true if connected (WiFi, mobile data, ethernet, etc.)
  /// Returns false if no connection available
  Future<bool> hasConnection() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      
      // Check if any connection type is available
      final hasConnection = connectivityResult.isNotEmpty &&
          connectivityResult.any((result) => 
            result != ConnectivityResult.none
          );
      
      SafeLogger.log('📡 Network Status: ${hasConnection ? "Connected" : "Disconnected"}');
      SafeLogger.log('📡 Connection Types: $connectivityResult');
      
      return hasConnection;
    } catch (e) {
      SafeLogger.error('Network check error: $e');
      // On error, assume no connection to be safe
      return false;
    }
  }

  /// Get current connectivity result (for detailed status if needed)
  Future<List<ConnectivityResult>> getConnectivityResult() async {
    try {
      return await _connectivity.checkConnectivity();
    } catch (e) {
      SafeLogger.error('Get connectivity result error: $e');
      return [ConnectivityResult.none];
    }
  }
}

