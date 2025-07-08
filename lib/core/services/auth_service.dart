import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../../models/user_model.dart';
import '../../models/seller_model.dart';

class AuthService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Customer authentication
  Future<AuthResult> signUpCustomer({
    required String email,
    required String password,
    required String username,
    required String userType,
    String? phone,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Insert user data into users table
        final userData = UserModel(
          userId: '',
          authUserId: response.user!.id,
          username: username,
          userType: userType,
          email: email,
          phone: phone,
          name: username, // Use username as display name
          createdAt: DateTime.now(),
        );

        await _supabase.from('users').insert(userData.toInsertJson());

        return AuthResult(
          success: true,
          user: response.user,
          message: 'Customer account created successfully',
        );
      }

      return AuthResult(success: false, message: 'Failed to create account');
    } catch (e) {
      String errorMessage = _parseSignUpError(e.toString());
      return AuthResult(success: false, message: errorMessage);
    }
  }

  // Seller authentication
  Future<AuthResult> signUpSeller({
    required String email,
    required String password,
    required String username,
    required String brandName,
    String? phone,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Insert seller data into sellers table
        final sellerData = SellerModel(
          sellerId: '',
          authUserId: response.user!.id,
          username: username,
          brandName: brandName,
          email: email,
          phone: phone,
          status: 'offline',
          createdAt: DateTime.now(),
        );

        await _supabase.from('sellers').insert(sellerData.toInsertJson());

        return AuthResult(
          success: true,
          user: response.user,
          message: 'Seller account created successfully',
        );
      }

      return AuthResult(success: false, message: 'Failed to create account');
    } catch (e) {
      String errorMessage = _parseSignUpError(e.toString());
      return AuthResult(success: false, message: errorMessage);
    }
  }

  // Sign in
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        return AuthResult(
          success: true,
          user: response.user,
          message: 'Signed in successfully',
        );
      }

      return AuthResult(success: false, message: 'Failed to sign in');
    } catch (e) {
      // Parse Supabase auth errors and return user-friendly messages
      String errorMessage = _parseAuthError(e.toString());
      return AuthResult(success: false, message: errorMessage);
    }
  }

  // Helper method to parse authentication errors into user-friendly messages
  String _parseAuthError(String error) {
    final lowerError = error.toLowerCase();

    if (lowerError.contains('invalid_grant') ||
        lowerError.contains('invalid login credentials') ||
        lowerError.contains('invalid_credentials')) {
      return 'Invalid email or password. Please check your credentials and try again.';
    }

    if (lowerError.contains('email not confirmed') ||
        lowerError.contains('email_not_confirmed')) {
      return 'Please verify your email address before signing in.';
    }

    if (lowerError.contains('user not found') ||
        lowerError.contains('email_not_found')) {
      return 'No account found with this email address.';
    }

    if (lowerError.contains('too many requests') ||
        lowerError.contains('rate_limit')) {
      return 'Too many login attempts. Please wait a moment and try again.';
    }

    if (lowerError.contains('weak password') ||
        lowerError.contains('password')) {
      return 'Password is incorrect. Please try again.';
    }

    if (lowerError.contains('network') || lowerError.contains('connection')) {
      return 'Network error. Please check your internet connection.';
    }

    if (lowerError.contains('email') && lowerError.contains('invalid')) {
      return 'Please enter a valid email address.';
    }

    // Default message for unknown errors
    return 'Login failed. Please check your email and password and try again.';
  }

  // Helper method to parse signup errors into user-friendly messages
  String _parseSignUpError(String error) {
    final lowerError = error.toLowerCase();

    if (lowerError.contains('email already registered') ||
        lowerError.contains('email_already_exists') ||
        lowerError.contains('duplicate') ||
        lowerError.contains('already_exists')) {
      return 'An account with this email already exists. Please use a different email or try logging in.';
    }

    if (lowerError.contains('weak password') ||
        lowerError.contains('password_weak')) {
      return 'Password is too weak. Please use at least 6 characters with numbers and letters.';
    }

    if (lowerError.contains('invalid email') ||
        lowerError.contains('email_invalid')) {
      return 'Please enter a valid email address.';
    }

    if (lowerError.contains('network') || lowerError.contains('connection')) {
      return 'Network error. Please check your internet connection and try again.';
    }

    if (lowerError.contains('rate_limit') || lowerError.contains('too many')) {
      return 'Too many signup attempts. Please wait a moment and try again.';
    }

    // Default message for unknown signup errors
    return 'Account creation failed. Please check your information and try again.';
  }

  // Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Get user data
  Future<UserModel?> getUserData() async {
    if (currentUser == null) return null;

    try {
      final response =
          await _supabase
              .from('users')
              .select()
              .eq('auth_user_id', currentUser!.id)
              .single();

      return UserModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Get seller data
  Future<SellerModel?> getSellerData() async {
    if (currentUser == null) return null;

    try {
      final response =
          await _supabase
              .from('sellers')
              .select()
              .eq('auth_user_id', currentUser!.id)
              .single();

      return SellerModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Check if user is customer
  Future<bool> isCustomer() async {
    if (currentUser == null) return false;

    try {
      final response = await _supabase
          .from('users')
          .select('user_id')
          .eq('auth_user_id', currentUser!.id);

      return response.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Check if user is seller
  Future<bool> isSeller() async {
    if (currentUser == null) return false;

    try {
      final response = await _supabase
          .from('sellers')
          .select('seller_id')
          .eq('auth_user_id', currentUser!.id);

      return response.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Delete user account
  Future<bool> deleteUserAccount() async {
    if (currentUser == null) return false;

    try {
      // Delete from users table (cascade will handle related records)
      await _supabase
          .from('users')
          .delete()
          .eq('auth_user_id', currentUser!.id);

      // Sign out
      await signOut();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Delete seller account
  Future<bool> deleteSellerAccount() async {
    if (currentUser == null) return false;

    try {
      // Delete from sellers table (cascade will handle related records)
      await _supabase
          .from('sellers')
          .delete()
          .eq('auth_user_id', currentUser!.id);

      // Sign out
      await signOut();
      return true;
    } catch (e) {
      return false;
    }
  }
}

class AuthResult {
  final bool success;
  final User? user;
  final String message;

  AuthResult({required this.success, this.user, required this.message});
}
