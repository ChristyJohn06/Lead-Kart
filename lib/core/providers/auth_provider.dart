import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../../models/user_model.dart';
import '../../models/seller_model.dart';

enum UserType { customer, seller, none }

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _currentUser;
  UserModel? _currentCustomer;
  SellerModel? _currentSeller;
  UserType _userType = UserType.none;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  User? get currentUser => _currentUser;
  UserModel? get currentCustomer => _currentCustomer;
  SellerModel? get currentSeller => _currentSeller;
  UserType get userType => _userType;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  void _setLoading(bool loading) {
    _isLoading = loading;
    _safeNotifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    _safeNotifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    _safeNotifyListeners();
  }

  void _safeNotifyListeners() {
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

  // Initialize auth state
  Future<void> initialize() async {
    _setLoading(true);
    try {
      _currentUser = _authService.currentUser;
      if (_currentUser != null) {
        await _loadUserData();
      }
    } catch (e) {
      _setError(e.toString());
    }
    _setLoading(false);
  }

  // Load user/seller data
  Future<void> _loadUserData() async {
    try {
      // Check if customer
      if (await _authService.isCustomer()) {
        _currentCustomer = await _authService.getUserData();
        _userType = UserType.customer;

        // Setup customer notifications
        if (_currentCustomer != null) {
          NotificationService.setupCustomerOrderNotifications(
            _currentCustomer!.userId,
          );
        }
      }
      // Check if seller
      else if (await _authService.isSeller()) {
        _currentSeller = await _authService.getSellerData();
        _userType = UserType.seller;

        // Setup seller notifications
        if (_currentSeller != null) {
          NotificationService.setupSellerOrderNotifications(
            _currentSeller!.sellerId,
          );
          NotificationService.setupLowStockNotifications(
            _currentSeller!.sellerId,
          );
        }
      }
      _safeNotifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Customer signup
  Future<bool> signUpCustomer({
    required String email,
    required String password,
    required String username,
    required String userType,
    String? phone,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _authService.signUpCustomer(
        email: email,
        password: password,
        username: username,
        userType: userType,
        phone: phone,
      );

      if (result.success) {
        _currentUser = result.user;
        await _loadUserData();
        _setLoading(false);
        return true;
      } else {
        _setError(result.message);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Seller signup
  Future<bool> signUpSeller({
    required String email,
    required String password,
    required String username,
    required String brandName,
    String? phone,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _authService.signUpSeller(
        email: email,
        password: password,
        username: username,
        brandName: brandName,
        phone: phone,
      );

      if (result.success) {
        _currentUser = result.user;
        await _loadUserData();
        _setLoading(false);
        return true;
      } else {
        _setError(result.message);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Sign in
  Future<bool> signIn({required String email, required String password}) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _authService.signIn(
        email: email,
        password: password,
      );

      if (result.success) {
        _currentUser = result.user;
        await _loadUserData();
        _setLoading(false);
        return true;
      } else {
        _setError(result.message);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    _setLoading(true);
    try {
      // Cleanup notifications
      NotificationService.dispose();

      await _authService.signOut();
      _currentUser = null;
      _currentCustomer = null;
      _currentSeller = null;
      _userType = UserType.none;
      _setError(null);
    } catch (e) {
      _setError(e.toString());
    }
    _setLoading(false);
  }

  // Delete account
  Future<bool> deleteAccount() async {
    _setLoading(true);
    try {
      bool success = false;
      if (_userType == UserType.customer) {
        success = await _authService.deleteUserAccount();
      } else if (_userType == UserType.seller) {
        success = await _authService.deleteSellerAccount();
      }

      if (success) {
        _currentUser = null;
        _currentCustomer = null;
        _currentSeller = null;
        _userType = UserType.none;
        _setError(null);
      }

      _setLoading(false);
      return success;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Update seller status
  Future<void> updateSellerStatus(String status) async {
    if (_currentSeller == null) return;

    try {
      await Supabase.instance.client
          .from('sellers')
          .update({'status': status})
          .eq('seller_id', _currentSeller!.sellerId);

      _currentSeller = _currentSeller!.copyWith(status: status);
      _safeNotifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }
}
