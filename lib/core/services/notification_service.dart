import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class NotificationService {
  static bool _isInitialized = false;
  static RealtimeChannel? _customerOrdersChannel;
  static RealtimeChannel? _sellerOrdersChannel;
  static RealtimeChannel? _productsChannel;

  // Flutter Local Notifications instance
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Global key for showing snackbars
  static GlobalKey<ScaffoldMessengerState>? _scaffoldMessengerKey;

  /// Initialize notification service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      requestCriticalPermission: true,
      requestProvisionalPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions for iOS (critical for iOS notifications)
    await _requestPermissions();

    _isInitialized = true;
    print('✅ NotificationService initialized with system notifications');
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    print('📱 Notification tapped: ${response.payload}');
    // TODO: Navigate to relevant screen based on payload
  }

  /// Request notification permissions (especially for iOS)
  static Future<void> _requestPermissions() async {
    print('🔐 Requesting notification permissions...');

    final iosPlugin =
        _localNotifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();

    if (iosPlugin != null) {
      print('📱 Requesting iOS notification permissions...');
      final granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
        critical: true,
      );
      print('📱 iOS notification permissions granted: $granted');

      if (granted != true) {
        print(
          '⚠️ iOS notification permissions denied - notifications may not work',
        );
      }
    }

    final androidPlugin =
        _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidPlugin != null) {
      print('🤖 Requesting Android notification permissions...');
      final granted = await androidPlugin.requestNotificationsPermission();
      print('🤖 Android notification permissions granted: $granted');
    }
  }

  /// Set scaffold messenger key for showing snackbars
  static void setScaffoldMessengerKey(GlobalKey<ScaffoldMessengerState> key) {
    _scaffoldMessengerKey = key;
  }

  /// Show system notification (appears in notification bar)
  static Future<void> showSystemNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    // Always log to console for debugging
    print('🔔 SYSTEM NOTIFICATION ATTEMPT: $title - $body');

    const androidDetails = AndroidNotificationDetails(
      'leadkart_orders',
      'LEAD Kart Orders',
      channelDescription: 'Notifications for order updates and alerts',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
      sound: null, // Use default system sound (fixes sound resource error)
      showWhen: true,
      when: null,
      usesChronometer: false,
      onlyAlertOnce: false,
      autoCancel: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
      badgeNumber: 1,
      subtitle: 'LEAD Kart',
      threadIdentifier: 'leadkart_notifications',
      categoryIdentifier: 'leadkart_category',
      interruptionLevel: InterruptionLevel.active,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      print('📤 Sending notification with ID: $notificationId');

      await _localNotifications.show(
        notificationId,
        title,
        body,
        details,
        payload: payload,
      );

      print('✅ System notification sent successfully with ID: $notificationId');

      // Additional debug: Check if notifications are enabled
      await _checkNotificationStatus();
    } catch (e) {
      print('❌ Failed to show system notification: $e');
      print('📋 Stack trace: ${StackTrace.current}');
    }
  }

  /// Check notification status for debugging
  static Future<void> _checkNotificationStatus() async {
    try {
      final androidPlugin =
          _localNotifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      if (androidPlugin != null) {
        final enabled = await androidPlugin.areNotificationsEnabled();
        print('🔍 Android notifications enabled: $enabled');
      }

      final iosPlugin =
          _localNotifications
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >();

      if (iosPlugin != null) {
        final settings = await iosPlugin.checkPermissions();
        print('🔍 iOS notification settings: $settings');
      }

      // List pending notifications
      final pendingNotifications =
          await _localNotifications.pendingNotificationRequests();
      print('📋 Pending notifications: ${pendingNotifications.length}');

      // List active notifications
      final activeNotifications =
          await _localNotifications.getActiveNotifications();
      print('🔔 Active notifications: ${activeNotifications.length}');
    } catch (e) {
      print('⚠️ Could not check notification status: $e');
    }
  }

  /// Show notification (both system and in-app)
  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    // Show system notification (notification bar)
    await showSystemNotification(title: title, body: body, payload: payload);

    // Also show in-app snackbar if app is open
    try {
      _scaffoldMessengerKey?.currentState?.showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(body, style: const TextStyle(color: Colors.white)),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print('⚠️ Could not show snackbar notification: $e');
    }
  }

  /// Setup order notifications for customers
  static void setupCustomerOrderNotifications(String customerId) {
    print('🔧 Setting up customer notifications for: $customerId');

    // Dispose existing channel
    if (_customerOrdersChannel != null) {
      SupabaseConfig.client.removeChannel(_customerOrdersChannel!);
    }

    _customerOrdersChannel =
        SupabaseConfig.client
            .channel('customer_orders_$customerId')
            .onPostgresChanges(
              event: PostgresChangeEvent.update,
              schema: 'public',
              table: 'orders',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'customer_id',
                value: customerId,
              ),
              callback: (payload) {
                print(
                  '📦 Customer order update received: ${payload.newRecord}',
                );

                try {
                  final newRecord = payload.newRecord;
                  final oldRecord = payload.oldRecord;

                  // Check if status changed
                  final newStatus = newRecord['status']?.toString() ?? '';
                  final oldStatus = oldRecord['status']?.toString() ?? '';

                  if (newStatus != oldStatus && newStatus.isNotEmpty) {
                    final productName =
                        newRecord['product_name']?.toString() ?? 'Your order';

                    String title = 'Order Update';
                    String body = _getOrderUpdateMessage(
                      newStatus,
                      productName,
                    );

                    if (body.isNotEmpty) {
                      showNotification(
                        title: title,
                        body: body,
                        payload: 'order_${newRecord['order_id'] ?? ''}',
                      );
                    }
                  }
                } catch (e) {
                  print('❌ Error processing customer order notification: $e');
                }
              },
            )
            .subscribe();

    print('✅ Customer order notifications channel subscribed');
  }

  /// Setup order notifications for sellers
  static void setupSellerOrderNotifications(String sellerId) {
    print('🔧 Setting up seller order notifications for: $sellerId');

    // Dispose existing channel
    if (_sellerOrdersChannel != null) {
      SupabaseConfig.client.removeChannel(_sellerOrdersChannel!);
    }

    _sellerOrdersChannel =
        SupabaseConfig.client
            .channel('seller_orders_$sellerId')
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'orders',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'seller_id',
                value: sellerId,
              ),
              callback: (payload) async {
                print('🛒 New order received: ${payload.newRecord}');

                try {
                  final newRecord = payload.newRecord;
                  final productName =
                      newRecord['product_name']?.toString() ??
                      'Unknown Product';
                  final quantity = newRecord['quantity'] ?? 1;
                  final customerId = newRecord['customer_id']?.toString();

                  // Fetch customer name from users table
                  String customerName = 'Customer';
                  if (customerId != null) {
                    try {
                      final response =
                          await SupabaseConfig.client
                              .from('users')
                              .select('username')
                              .eq('user_id', customerId)
                              .single();
                      customerName =
                          response['username']?.toString() ?? 'Customer';
                    } catch (e) {
                      print('⚠️ Could not fetch customer name: $e');
                    }
                  }

                  showNotification(
                    title: 'New Order Received! 🛒',
                    body: '$customerName ordered $quantity x $productName',
                    payload: 'new_order_${newRecord['order_id'] ?? ''}',
                  );
                } catch (e) {
                  print('❌ Error processing new order notification: $e');
                }
              },
            )
            .subscribe();

    print('✅ Seller order notifications channel subscribed');
  }

  /// Setup low stock notifications for sellers
  static void setupLowStockNotifications(String sellerId) {
    print('🔧 Setting up low stock notifications for: $sellerId');

    // Dispose existing channel
    if (_productsChannel != null) {
      SupabaseConfig.client.removeChannel(_productsChannel!);
    }

    _productsChannel =
        SupabaseConfig.client
            .channel('seller_products_$sellerId')
            .onPostgresChanges(
              event: PostgresChangeEvent.update,
              schema: 'public',
              table: 'products',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'seller_id',
                value: sellerId,
              ),
              callback: (payload) {
                print('📊 Product stock updated: ${payload.newRecord}');

                try {
                  final newRecord = payload.newRecord;
                  final stock = newRecord['stock'] ?? 0;
                  final productName =
                      newRecord['name']?.toString() ?? 'Product';

                  // Alert when stock is low (less than 5)
                  if (stock < 5 && stock > 0) {
                    showNotification(
                      title: 'Low Stock Alert ⚠️',
                      body: '$productName has only $stock items left',
                      payload: 'low_stock_${newRecord['product_id'] ?? ''}',
                    );
                  } else if (stock == 0) {
                    showNotification(
                      title: 'Out of Stock ❌',
                      body: '$productName is now out of stock',
                      payload: 'out_of_stock_${newRecord['product_id'] ?? ''}',
                    );
                  }
                } catch (e) {
                  print('❌ Error processing low stock notification: $e');
                }
              },
            )
            .subscribe();

    print('✅ Low stock notifications channel subscribed');
  }

  /// Cleanup notification channels
  static void dispose() {
    print('🧹 Cleaning up notification channels...');

    if (_customerOrdersChannel != null) {
      SupabaseConfig.client.removeChannel(_customerOrdersChannel!);
      _customerOrdersChannel = null;
    }
    if (_sellerOrdersChannel != null) {
      SupabaseConfig.client.removeChannel(_sellerOrdersChannel!);
      _sellerOrdersChannel = null;
    }
    if (_productsChannel != null) {
      SupabaseConfig.client.removeChannel(_productsChannel!);
      _productsChannel = null;
    }

    print('✅ All notification channels cleaned up');
  }

  /// Test notification method - call this to test if system notifications work
  static Future<void> testSystemNotification() async {
    print('🧪 Testing system notification...');
    await showSystemNotification(
      title: 'Test Notification 🧪',
      body:
          'If you see this in your notification bar, system notifications are working!',
      payload: 'test_notification',
    );
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Debug method to check if notifications are set up
  static void debugStatus() {
    print('🔍 Notification Service Debug Status:');
    print('  - Initialized: $_isInitialized');
    print(
      '  - Customer Orders Channel: ${_customerOrdersChannel != null ? "Active" : "Inactive"}',
    );
    print(
      '  - Seller Orders Channel: ${_sellerOrdersChannel != null ? "Active" : "Inactive"}',
    );
    print(
      '  - Products Channel: ${_productsChannel != null ? "Active" : "Inactive"}',
    );
    print(
      '  - Scaffold Messenger: ${_scaffoldMessengerKey != null ? "Set" : "Not Set"}',
    );
  }

  static String _getOrderUpdateMessage(String status, String productName) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'Your order for $productName has been confirmed!';
      case 'delivered':
        return 'Your order for $productName has been delivered!';
      default:
        return 'Your order for $productName has been updated to $status';
    }
  }
}
