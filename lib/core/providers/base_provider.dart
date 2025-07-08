import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Base provider class with safe notifyListeners implementation
/// and common error handling functionality
abstract class BaseProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Safely calls notifyListeners with exception handling
  /// Uses post-frame callback to avoid build-time exceptions
  void safeNotifyListeners() {
    try {
      // Check if we can safely notify listeners
      if (!hasListeners) return;

      // Use post frame callback if called during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          if (hasListeners) {
            notifyListeners();
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Deferred notifyListeners error: $e');
          }
        }
      });
    } catch (e) {
      // Handle the case where notifyListeners is called after dispose
      if (kDebugMode) {
        debugPrint('Error in notifyListeners: $e');
      }
    }
  }

  /// Sets loading state and notifies listeners safely
  void setLoading(bool loading) {
    _isLoading = loading;
    safeNotifyListeners();
  }

  /// Sets error message and notifies listeners safely
  void setError(String? error) {
    _errorMessage = error;
    safeNotifyListeners();
  }

  /// Clears error message and notifies listeners safely
  void clearError() {
    _errorMessage = null;
    safeNotifyListeners();
  }

  /// Override dispose to add safety checks
  @override
  void dispose() {
    try {
      super.dispose();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error disposing provider: $e');
      }
    }
  }
}
