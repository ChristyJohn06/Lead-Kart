import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/providers/orders_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/services/whatsapp_service.dart';
import '../../../../models/order_model.dart';
import '../../../../core/config/supabase_config.dart';
import 'package:intl/intl.dart';

class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> {
  String _selectedFilter = 'All';
  final List<String> _filterOptions = [
    'All',
    'Pending',
    'Confirmed',
    'Delivered',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.currentCustomer != null) {
        Provider.of<OrdersProvider>(
          context,
          listen: false,
        ).fetchCustomerOrders(authProvider.currentCustomer!.userId);
      }
    });
  }

  List<OrderModel> _getFilteredOrders(List<OrderModel> orders) {
    if (_selectedFilter == 'All') {
      return orders;
    }
    return orders.where((order) {
      return order.status.toLowerCase() == _selectedFilter.toLowerCase();
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: Colors.blue,
        automaticallyImplyLeading: false,
      ),
      body: Consumer2<OrdersProvider, AuthProvider>(
        builder: (context, ordersProvider, authProvider, child) {
          if (authProvider.currentCustomer == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.login, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Please log in to view your orders',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          if (ordersProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final filteredOrders = _getFilteredOrders(
            ordersProvider.customerOrders,
          );

          return RefreshIndicator(
            onRefresh: () async {
              await ordersProvider.fetchCustomerOrders(
                authProvider.currentCustomer!.userId,
              );
            },
            child: Column(
              children: [
                // Filter Section
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Filter Orders',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children:
                              _filterOptions.map((filter) {
                                final isSelected = _selectedFilter == filter;
                                final orderCount =
                                    filter == 'All'
                                        ? ordersProvider.customerOrders.length
                                        : ordersProvider.customerOrders
                                            .where(
                                              (order) =>
                                                  order.status.toLowerCase() ==
                                                  filter.toLowerCase(),
                                            )
                                            .length;

                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedFilter = filter;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            isSelected
                                                ? Colors.blue
                                                : Colors.grey[200],
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color:
                                              isSelected
                                                  ? Colors.blue
                                                  : Colors.grey[300]!,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            filter,
                                            style: TextStyle(
                                              color:
                                                  isSelected
                                                      ? Colors.white
                                                      : Colors.black87,
                                              fontWeight:
                                                  isSelected
                                                      ? FontWeight.w600
                                                      : FontWeight.normal,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  isSelected
                                                      ? Colors.white
                                                          .withOpacity(0.2)
                                                      : Colors.grey[400],
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              orderCount.toString(),
                                              style: TextStyle(
                                                color:
                                                    isSelected
                                                        ? Colors.white
                                                        : Colors.black87,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),

                // Orders List
                Expanded(
                  child:
                      filteredOrders.isEmpty
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _selectedFilter == 'All'
                                      ? Icons.shopping_bag_outlined
                                      : _selectedFilter == 'Pending'
                                      ? Icons.access_time
                                      : _selectedFilter == 'Confirmed'
                                      ? Icons.check_circle_outline
                                      : Icons.delivery_dining,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _selectedFilter == 'All'
                                      ? 'No orders yet'
                                      : 'No ${_selectedFilter.toLowerCase()} orders',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _selectedFilter == 'All'
                                      ? 'Start shopping to see your orders here'
                                      : 'Orders with ${_selectedFilter.toLowerCase()} status will appear here',
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          )
                          : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredOrders.length,
                            itemBuilder: (context, index) {
                              final order = filteredOrders[index];
                              return OrderCard(order: order);
                            },
                          ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  final OrderModel order;

  const OrderCard({super.key, required this.order});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.access_time;
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'delivered':
        return Icons.delivery_dining;
      default:
        return Icons.help_outline;
    }
  }

  String _formatDeliveryLocation(String location) {
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

  Future<void> _messageSellerOnWhatsApp(BuildContext context) async {
    String? sellerPhone = order.sellerPhone;

    // If seller phone is not available, try to fetch it from the seller table
    if (sellerPhone == null || sellerPhone.isEmpty) {
      print(
        '🔍 Seller phone not found in order, fetching from sellers table...',
      );

      try {
        final response =
            await SupabaseConfig.client
                .from('sellers')
                .select('phone')
                .eq('seller_id', order.sellerId)
                .single();

        sellerPhone = response['phone'] as String?;
        print('📱 Fetched seller phone: $sellerPhone');
      } catch (e) {
        print('❌ Error fetching seller phone: $e');
      }
    }

    // Check if seller has phone number
    if (sellerPhone == null || sellerPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seller phone number not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Get customer name from auth provider
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final customerName =
        authProvider.currentCustomer?.name ??
        authProvider.currentCustomer?.username ??
        'Customer';

    // Generate message
    final message = WhatsAppService.generateOrderMessage(
      customerName: customerName,
      orderId: order.orderId,
      productName: order.productName,
      quantity: order.quantity,
      totalPrice: order.totalPrice,
      deliveryLocation: order.deliveryLocation,
      status: order.status,
    );

    // Show loading indicator
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Opening WhatsApp...'),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.blue,
        ),
      );
    }

    // Check if WhatsApp is available first
    final isWhatsAppAvailable = await WhatsAppService.isWhatsAppInstalled();

    if (!isWhatsAppAvailable) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'WhatsApp not found. Install WhatsApp or use phone number below:',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Copy Phone',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('📞 Seller: $sellerPhone'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 3),
                  ),
                );
              },
            ),
          ),
        );
      }
      return;
    }

    // Send WhatsApp message
    final success = await WhatsAppService.sendMessage(
      phoneNumber: sellerPhone,
      message: message,
    );

    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('WhatsApp opened successfully! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Failed to open WhatsApp. Here\'s the phone number:',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Show Phone',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('📞 Call Seller: $sellerPhone'),
                    backgroundColor: Colors.blue,
                    duration: const Duration(seconds: 4),
                  ),
                );
              },
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.orderId.substring(0, 6).toUpperCase()}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(order.status),
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        order.status.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Product Info
            Text(
              order.productName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            // Order Details
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.numbers,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Qty: ${order.quantity}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.store, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Seller: ${order.sellerName}',
                              style: const TextStyle(color: Colors.grey),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      // Delivery Location
                      if (order.deliveryLocation != null &&
                          order.deliveryLocation!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Drop: ${_formatDeliveryLocation(order.deliveryLocation!)}',
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${order.totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      DateFormat('MMM dd, HH:mm').format(order.createdAt),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),

            // Pending order notice (only for pending orders)
            if (order.status.toLowerCase() == 'pending') ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange.shade600,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'If this order is not confirmed within 2 minutes, please contact the seller.',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // WhatsApp Message Button (only for non-delivered orders)
            if (order.status.toLowerCase() != 'delivered') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _messageSellerOnWhatsApp(context),
                  icon: const Icon(
                    Icons.message,
                    size: 18,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Message Seller on WhatsApp',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366), // WhatsApp green
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
