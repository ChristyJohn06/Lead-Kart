import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/cloudinary_config.dart';

class CloudinaryService {
  final Dio _dio = Dio();

  CloudinaryService() {
    // Configure Dio with timeout settings
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.sendTimeout = const Duration(seconds: 30);
  }

  /// Upload image to Cloudinary
  /// Returns the secure URL if successful, null otherwise
  Future<CloudinaryUploadResult> uploadImage(
    File imageFile, {
    String? folder,
    Function(int, int)? onSendProgress,
  }) async {
    try {
      if (kDebugMode) {
        print('📸 Starting image upload to Cloudinary...');
        print('📁 File path: ${imageFile.path}');
        print('📊 File size: ${await imageFile.length()} bytes');
      }

      // Validate file
      if (!await imageFile.exists()) {
        return CloudinaryUploadResult.error('File does not exist');
      }

      final fileSize = await imageFile.length();
      if (fileSize > 10 * 1024 * 1024) {
        // 10MB limit
        return CloudinaryUploadResult.error('File size too large (max 10MB)');
      }

      // Prepare form data
      Map<String, dynamic> formFields = {
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: _generateFileName(imageFile),
        ),
        'upload_preset': CloudinaryConfig.uploadPreset,
      };

      // Add folder if specified
      if (folder != null && folder.isNotEmpty) {
        formFields['folder'] = folder;
      }

      FormData formData = FormData.fromMap(formFields);

      if (kDebugMode) {
        print('🚀 Uploading to: ${CloudinaryConfig.uploadUrl}');
      }

      // Upload with progress tracking
      Response response = await _dio.post(
        CloudinaryConfig.uploadUrl,
        data: formData,
        onSendProgress: onSendProgress,
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (kDebugMode) {
          print('✅ Upload successful!');
          print('🔗 URL: ${data['secure_url']}');
          print('🆔 Public ID: ${data['public_id']}');
        }

        return CloudinaryUploadResult.success(
          url: data['secure_url'],
          publicId: data['public_id'],
          format: data['format'],
          bytes: data['bytes'],
        );
      } else {
        if (kDebugMode) {
          print('❌ Upload failed with status: ${response.statusCode}');
        }
        return CloudinaryUploadResult.error(
          'Upload failed with status: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      String errorMessage = 'Network error occurred';

      if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Connection timeout - please check your internet';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Upload timeout - file might be too large';
      } else if (e.response != null) {
        errorMessage = 'Server error: ${e.response?.statusCode}';
      }

      if (kDebugMode) {
        print('❌ Dio error uploading image: $e');
        print('❌ Error message: $errorMessage');
      }

      return CloudinaryUploadResult.error(errorMessage);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Unexpected error uploading image: $e');
      }
      return CloudinaryUploadResult.error('Unexpected error: $e');
    }
  }

  /// Generate optimized image URL
  String? getOptimizedImageUrl(
    String? originalUrl, {
    int? width,
    int? height,
    String quality = 'auto',
    String format = 'auto',
  }) {
    if (originalUrl == null || originalUrl.isEmpty) return null;

    try {
      // Extract public_id from the URL
      final publicId = CloudinaryConfig.getPublicIdFromUrl(originalUrl);
      if (publicId == null) return originalUrl;

      // Generate optimized URL
      return CloudinaryConfig.getImageUrl(
        publicId,
        width: width,
        height: height,
        quality: quality,
        format: format,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error generating optimized URL: $e');
      }
      return originalUrl;
    }
  }

  /// Get product image URL with optimizations
  String? getProductImageUrl(String? imageUrl, {bool isGrid = false}) {
    if (imageUrl == null || imageUrl.isEmpty) return null;

    final publicId = CloudinaryConfig.getPublicIdFromUrl(imageUrl);
    if (publicId == null) return imageUrl;

    if (isGrid) {
      // Grid view - smaller images for performance
      return CloudinaryConfig.getImageUrl(
        publicId,
        width: 200,
        height: 200,
        quality: 'auto',
        format: 'auto',
      );
    } else {
      // Detail view - larger images
      return CloudinaryConfig.getProductImageUrl(publicId);
    }
  }

  /// Get thumbnail URL
  String? getThumbnailUrl(String? imageUrl, {int size = 100}) {
    if (imageUrl == null || imageUrl.isEmpty) return null;

    final publicId = CloudinaryConfig.getPublicIdFromUrl(imageUrl);
    if (publicId == null) return imageUrl;

    return CloudinaryConfig.getThumbnailUrl(publicId, size: size);
  }

  /// Generate unique filename
  String _generateFileName(File file) {
    final extension = file.path.split('.').last.toLowerCase();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'product_$timestamp.$extension';
  }

  /// Delete image from Cloudinary (requires API key and secret)
  Future<bool> deleteImage(String publicId) async {
    try {
      // Note: This requires API key and secret for authentication
      // For security, this should be done on the server side
      if (kDebugMode) {
        print(
          '🗑️ Delete image functionality requires server-side implementation',
        );
        print('🆔 Public ID to delete: $publicId');
      }

      // Return true for now - implement server-side deletion
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting image: $e');
      }
      return false;
    }
  }
}

/// Result class for Cloudinary upload operations
class CloudinaryUploadResult {
  final bool isSuccess;
  final String? url;
  final String? publicId;
  final String? format;
  final int? bytes;
  final String? error;

  CloudinaryUploadResult._({
    required this.isSuccess,
    this.url,
    this.publicId,
    this.format,
    this.bytes,
    this.error,
  });

  factory CloudinaryUploadResult.success({
    required String url,
    required String publicId,
    String? format,
    int? bytes,
  }) {
    return CloudinaryUploadResult._(
      isSuccess: true,
      url: url,
      publicId: publicId,
      format: format,
      bytes: bytes,
    );
  }

  factory CloudinaryUploadResult.error(String error) {
    return CloudinaryUploadResult._(isSuccess: false, error: error);
  }
}
