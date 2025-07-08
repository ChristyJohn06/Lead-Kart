import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/orders_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/services/whatsapp_service.dart';
import '../../../../models/order_model.dart';

class SellerOrdersTab extends StatefulWidget {
  const SellerOrdersTab({super.key});

  @override
  State<SellerOrdersTab> createState() => _SellerOrdersTabState();
}

class _SellerOrdersTabState extends State<SellerOrdersTab> {
  String _selectedStatusFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _refreshOrders();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshOrders() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final ordersProvider = Provider.of<OrdersProvider>(context, listen: false);

    if (authProvider.currentSeller != null) {
      await ordersProvider.fetchSellerOrders(
        authProvider.currentSeller!.sellerId,
      );
      // Reapply the current filter after refreshing
      ordersProvider.setOrderStatusFilter(_selectedStatusFilter);
    }
  }

  List<OrderModel> _getFilteredOrders(List<OrderModel> statusFilteredOrders) {
    // Apply search on top of the already status-filtered orders
    if (_searchQuery.isEmpty) {
      return statusFilteredOrders;
    }

    return statusFilteredOrders.where((order) {
      // Search by order ID (first 6 characters)
      final shortOrderId = order.orderId.substring(0, 6).toLowerCase();
      final productName = order.productName.toLowerCase();
      final customerName = (order.customerName ?? '').toLowerCase();
      final customerIdShort = order.customerId.substring(0, 6).toLowerCase();

      return shortOrderId.contains(_searchQuery) ||
          productName.contains(_searchQuery) ||
          customerName.contains(_searchQuery) ||
          customerIdShort.contains(_searchQuery);
    }).toList();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
  }

  Widget _buildEmptyOrdersState() {
    final isFiltered = _selectedStatusFilter != 'All';
    final isSearching = _searchQuery.isNotEmpty;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            Icon(
              isSearching ? Icons.search_off : Icons.filter_list_off,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 24),
            Text(
              isSearching
                  ? 'No matching orders'
                  : 'No $_selectedStatusFilter orders',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? 'No orders found for "$_searchQuery"'
                  : 'No orders found with "$_selectedStatusFilter" status',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isSearching) ...[
                  OutlinedButton.icon(
                    onPressed: _clearSearch,
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear Search'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                if (isFiltered)
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedStatusFilter = 'All';
                      });
                      Provider.of<OrdersProvider>(
                        context,
                        listen: false,
                      ).setOrderStatusFilter('All');
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Show All'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.receipt_long,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Orders',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        automaticallyImplyLeading: false,
      ),
      body: Consumer2<OrdersProvider, AuthProvider>(
        builder: (context, ordersProvider, authProvider, child) {
          if (authProvider.currentSeller == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.login, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Please log in to view orders',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          if (ordersProvider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading orders...',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          if (ordersProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${ordersProvider.errorMessage}',
                    style: const TextStyle(fontSize: 16, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshOrders,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final statusFilteredOrders =
              ordersProvider
                  .sellerOrders; // This is already status-filtered by provider
          final orders = _getFilteredOrders(
            statusFilteredOrders,
          ); // Apply search on top
          final allOrders =
              ordersProvider.allSellerOrders; // All unfiltered orders

          if (allOrders.isEmpty) {
            // No orders at all
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 120,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No orders yet',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Customer orders will appear here',
                    style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Order Statistics
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.orange, Colors.deepOrange],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _buildOrderStatistics(ordersProvider),
              ),

              // Search Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by Order ID, Product, or Customer...',
                    prefixIcon: const Icon(Icons.search, color: Colors.orange),
                    suffixIcon:
                        _searchQuery.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: _clearSearch,
                            )
                            : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.orange,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Status Filter
              Container(
                height: 50,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children:
                        ['All', 'Pending', 'Confirmed', 'Delivered'].map((
                          status,
                        ) {
                          final isSelected = _selectedStatusFilter == status;
                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedStatusFilter = status;
                                });
                                ordersProvider.setOrderStatusFilter(status);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? Colors.orange
                                          : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? Colors.orange
                                            : Colors.grey[300]!,
                                  ),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    color:
                                        isSelected
                                            ? Colors.white
                                            : Colors.grey[700],
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Search Results Info
              if (_searchQuery.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: Colors.orange[600], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Found ${orders.length} order${orders.length == 1 ? '' : 's'} for "$_searchQuery"',
                        style: TextStyle(
                          color: Colors.orange[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

              if (_searchQuery.isNotEmpty) const SizedBox(height: 16),

              // Orders List
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshOrders,
                  color: Colors.orange,
                  child:
                      orders.isEmpty
                          ? _buildEmptyOrdersState()
                          : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: orders.length,
                            itemBuilder: (context, index) {
                              final order = orders[index];
                              return SellerOrderCard(
                                order: order,
                                onStatusUpdate: _refreshOrders,
                              );
                            },
                          ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOrderStatistics(OrdersProvider ordersProvider) {
    final stats = ordersProvider.getOrderStatistics();
    final totalSales = ordersProvider.getTotalSales();

    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              Text(
                '${stats['total'] ?? 0}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Text(
                'Total Orders',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                '${stats['pending'] ?? 0}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Text(
                'Pending',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                '${stats['delivered'] ?? 0}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Text(
                'Delivered',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                '₹${totalSales.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Text(
                'Total Sales',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SellerOrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onStatusUpdate;

  const SellerOrderCard({
    super.key,
    required this.order,
    required this.onStatusUpdate,
  });

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

  List<String> _getNextStatuses(String currentStatus) {
    switch (currentStatus.toLowerCase()) {
      case 'pending':
        return ['Confirmed'];
      case 'confirmed':
        return ['Delivered'];
      default:
        return [];
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

  Future<void> _messageCustomerOnWhatsApp(BuildContext context) async {
    String? customerPhone = order.customerPhone;

    // Check if customer has phone number
    if (customerPhone == null || customerPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer phone number not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Get seller name from auth provider
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final sellerName =
        authProvider.currentSeller?.brandName ??
        authProvider.currentSeller?.username ??
        'Seller';

    // Generate message for customer
    final message =
        'Hi! This is $sellerName regarding your order #${order.orderId.substring(0, 6).toUpperCase()} for ${order.productName}. '
        'Status: ${order.status}. Please let me know if you have any questions about your order.';

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
                    content: Text('📞 Customer: $customerPhone'),
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
      phoneNumber: customerPhone,
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
                    content: Text('📞 Call Customer: $customerPhone'),
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

  Future<void> _updateOrderStatus(
    BuildContext context,
    String newStatus,
  ) async {
    final ordersProvider = Provider.of<OrdersProvider>(context, listen: false);

    final success = await ordersProvider.updateOrderStatus(
      order.orderId,
      newStatus,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Order status updated to $newStatus'
                : 'Failed to update order status: ${ordersProvider.errorMessage}',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success) {
        onStatusUpdate();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
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
                    horizontal: 10,
                    vertical: 6,
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
            Row(
              children: [
                const Icon(Icons.shopping_bag, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.productName.isNotEmpty
                        ? order.productName
                        : 'Product Name',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Customer Info
            Row(
              children: [
                const Icon(Icons.person, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Customer ID: ${order.customerId.substring(0, 6).toUpperCase()}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Delivery Location and Customer Details
            if (order.deliveryLocation != null &&
                order.deliveryLocation!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with location icon
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.local_shipping,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Delivery Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Delivery Location
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 18,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Drop Point: ${_formatDeliveryLocation(order.deliveryLocation!)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),

                    // Customer Details
                    if (order.customerName != null ||
                        order.customerPhone != null) ...[
                      const SizedBox(height: 8),
                      const Divider(color: Colors.orange, thickness: 0.5),
                      const SizedBox(height: 8),

                      // Customer Name
                      if (order.customerName != null &&
                          order.customerName!.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(
                              Icons.person,
                              size: 18,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Customer: ${order.customerName!}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                      ],

                      // Customer Phone
                      if (order.customerPhone != null &&
                          order.customerPhone!.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(
                              Icons.phone,
                              size: 18,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Phone: ${order.customerPhone!}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Quantity and Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.shopping_cart,
                      size: 20,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Qty: ${order.quantity}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                Text(
                  '₹${order.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Date
            Row(
              children: [
                const Icon(Icons.access_time, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  DateFormat('MMM dd, yyyy - hh:mm a').format(order.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),

            // WhatsApp Message Button (for pending and confirmed orders)
            if ((order.status.toLowerCase() == 'pending' ||
                    order.status.toLowerCase() == 'confirmed') &&
                order.customerPhone != null &&
                order.customerPhone!.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _messageCustomerOnWhatsApp(context),
                  icon: const Icon(
                    Icons.message,
                    size: 18,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Message Customer on WhatsApp',
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

            // Action Buttons
            if (_getNextStatuses(order.status).isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children:
                    _getNextStatuses(order.status).map((status) {
                      return Expanded(
                        child: Container(
                          margin: EdgeInsets.only(
                            right:
                                _getNextStatuses(order.status).last == status
                                    ? 0
                                    : 8,
                          ),
                          child: ElevatedButton(
                            onPressed:
                                () => _updateOrderStatus(context, status),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  status == 'Cancelled'
                                      ? Colors.red
                                      : _getStatusColor(status),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              status,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
