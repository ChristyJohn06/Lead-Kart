import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class WhatsAppService {
  /// Open WhatsApp with a pre-filled message to a specific phone number
  ///
  /// [phoneNumber] - The recipient's phone number (with or without country code)
  /// [message] - The pre-filled message to send
  /// [countryCode] - Optional country code (default is '91' for India)
  static Future<bool> sendMessage({
    required String phoneNumber,
    required String message,
    String countryCode = '91',
  }) async {
    try {
      // Clean the phone number (remove spaces, dashes, etc.)
      String cleanedPhone = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

      // Add country code if not present
      if (!cleanedPhone.startsWith(countryCode)) {
        cleanedPhone = '$countryCode$cleanedPhone';
      }

      // Encode the message for URL
      String encodedMessage = Uri.encodeComponent(message);

      // List of WhatsApp URL schemes to try (in order of preference)
      List<String> whatsappUrls = [];

      if (Platform.isAndroid) {
        // Android-specific schemes
        whatsappUrls.addAll([
          'whatsapp://send?phone=$cleanedPhone&text=$encodedMessage',
          'intent://send?phone=$cleanedPhone&text=$encodedMessage#Intent;scheme=whatsapp;package=com.whatsapp;end',
          'https://api.whatsapp.com/send?phone=$cleanedPhone&text=$encodedMessage',
          'https://wa.me/$cleanedPhone?text=$encodedMessage',
        ]);
      } else if (Platform.isIOS) {
        // iOS-specific schemes
        whatsappUrls.addAll([
          'whatsapp://send?phone=$cleanedPhone&text=$encodedMessage',
          'https://wa.me/$cleanedPhone?text=$encodedMessage',
          'https://api.whatsapp.com/send?phone=$cleanedPhone&text=$encodedMessage',
        ]);
      } else {
        // Web and other platforms
        whatsappUrls.addAll([
          'https://wa.me/$cleanedPhone?text=$encodedMessage',
          'https://api.whatsapp.com/send?phone=$cleanedPhone&text=$encodedMessage',
        ]);
      }

      // Try each URL scheme until one works
      for (String url in whatsappUrls) {
        try {
          if (kDebugMode) {
            print('🔍 Trying WhatsApp URL: $url');
          }

          if (await canLaunchUrl(Uri.parse(url))) {
            await launchUrl(
              Uri.parse(url),
              mode: LaunchMode.externalApplication,
            );
            if (kDebugMode) {
              print('✅ Successfully launched WhatsApp with URL: $url');
            }
            return true;
          }
        } catch (e) {
          if (kDebugMode) {
            print('❌ Failed to launch URL $url: $e');
          }
          continue; // Try next URL
        }
      }

      // If all URLs failed, try opening WhatsApp Business as fallback
      if (Platform.isAndroid) {
        try {
          String businessUrl =
              'intent://send?phone=$cleanedPhone&text=$encodedMessage#Intent;scheme=whatsapp;package=com.whatsapp.w4b;end';
          if (await canLaunchUrl(Uri.parse(businessUrl))) {
            await launchUrl(
              Uri.parse(businessUrl),
              mode: LaunchMode.externalApplication,
            );
            if (kDebugMode) {
              print('✅ Successfully launched WhatsApp Business');
            }
            return true;
          }
        } catch (e) {
          if (kDebugMode) {
            print('❌ Failed to launch WhatsApp Business: $e');
          }
        }
      }

      if (kDebugMode) {
        print('❌ All WhatsApp URL schemes failed');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error launching WhatsApp: $e');
      }
      return false;
    }
  }

  /// Check if WhatsApp is installed on the device
  static Future<bool> isWhatsAppInstalled() async {
    try {
      List<String> testUrls = [];

      if (Platform.isAndroid) {
        testUrls.addAll([
          'whatsapp://send',
          'intent://send#Intent;scheme=whatsapp;package=com.whatsapp;end',
          'intent://send#Intent;scheme=whatsapp;package=com.whatsapp.w4b;end', // WhatsApp Business
        ]);
      } else if (Platform.isIOS) {
        testUrls.addAll(['whatsapp://send']);
      }

      // Add web fallback
      testUrls.add('https://wa.me/');

      // Try each test URL
      for (String url in testUrls) {
        try {
          if (await canLaunchUrl(Uri.parse(url))) {
            if (kDebugMode) {
              print('✅ WhatsApp detected via: $url');
            }
            return true;
          }
        } catch (e) {
          continue; // Try next URL
        }
      }

      if (kDebugMode) {
        print('❌ WhatsApp not detected on device');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking WhatsApp installation: $e');
      }
      return false;
    }
  }

  /// Generate a message for contacting seller about an order
  static String generateOrderMessage({
    required String customerName,
    required String orderId,
    required String productName,
    required int quantity,
    required double totalPrice,
    String? deliveryLocation,
    String? status,
  }) {
    String message = '''Hi! 👋

I'm $customerName and I have a question about my order:

📦 Order ID: #${orderId.substring(0, 6).toUpperCase()}
🛍️ Product: $productName
📊 Quantity: $quantity
💰 Total: ₹${totalPrice.toStringAsFixed(0)}''';

    if (deliveryLocation != null && deliveryLocation.isNotEmpty) {
      String formattedLocation = _formatDeliveryLocation(deliveryLocation);
      message += '\n📍 Delivery: $formattedLocation';
    }

    if (status != null && status.isNotEmpty) {
      message += '\n📋 Status: ${status.toUpperCase()}';
    }

    message += '''

Could you please help me with this order?

Thank you! 🙏''';

    return message;
  }

  /// Generate a simple message for contacting seller
  static String generateSimpleMessage({
    required String customerName,
    required String sellerName,
  }) {
    return '''Hi $sellerName! 👋

I'm $customerName and I'd like to know more about your products.

Thank you! 🙏''';
  }

  /// Format delivery location for display
  static String _formatDeliveryLocation(String location) {
    switch (location.toLowerCase()) {
      case 'bbcourt':
        return 'BB Court';
      case 'frontoffice':
        return 'Front Office';
      case 'newhostel':
        return 'New Hostel';
      default:
        return location.toUpperCase();
    }
  }
}
