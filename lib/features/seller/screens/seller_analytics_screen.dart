import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/orders_provider.dart';
import '../../../core/providers/products_provider.dart';
import '../../../models/order_model.dart';
import '../../../models/product_model.dart';

class SellerAnalyticsScreen extends StatefulWidget {
  const SellerAnalyticsScreen({super.key});

  @override
  State<SellerAnalyticsScreen> createState() => _SellerAnalyticsScreenState();
}

class _SellerAnalyticsScreenState extends State<SellerAnalyticsScreen> {
  String selectedPeriod = '7 Days';
  final List<String> periods = ['7 Days', '30 Days', '90 Days', 'All Time'];

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  void _loadAnalyticsData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final ordersProvider = Provider.of<OrdersProvider>(context, listen: false);
    final productsProvider = Provider.of<ProductsProvider>(
      context,
      listen: false,
    );

    final sellerId = authProvider.currentSeller?.sellerId;
    if (sellerId != null) {
      ordersProvider.fetchSellerOrders(sellerId);
      productsProvider.fetchSellerProducts(sellerId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Analytics'),
        backgroundColor: Colors.orange,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                selectedPeriod = value;
              });
            },
            itemBuilder:
                (context) =>
                    periods.map((period) {
                      return PopupMenuItem(value: period, child: Text(period));
                    }).toList(),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    selectedPeriod,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Consumer3<AuthProvider, OrdersProvider, ProductsProvider>(
        builder: (
          context,
          authProvider,
          ordersProvider,
          productsProvider,
          child,
        ) {
          final seller = authProvider.currentSeller;
          if (seller == null) {
            return const Center(child: Text('Please log in to view analytics'));
          }

          if (ordersProvider.isLoading || productsProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            );
          }

          final orders = ordersProvider.allSellerOrders;
          final products = productsProvider.sellerProducts;
          final analytics = _calculateAnalytics(orders, products);

          return RefreshIndicator(
            onRefresh: () async {
              _loadAnalyticsData();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overview Cards
                  _buildOverviewCards(analytics),
                  const SizedBox(height: 24),

                  // Sales Chart
                  _buildSalesChart(orders),
                  const SizedBox(height: 24),

                  // Order Status Distribution
                  _buildOrderStatusChart(analytics),
                  const SizedBox(height: 24),

                  // Top Products
                  _buildTopProducts(orders, products),
                  const SizedBox(height: 24),

                  // Recent Performance
                  _buildRecentPerformance(analytics),
                  const SizedBox(height: 24),

                  // Financial Summary
                  _buildFinancialSummary(analytics),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Map<String, dynamic> _calculateAnalytics(
    List<OrderModel> orders,
    List<ProductModel> products,
  ) {
    final now = DateTime.now();
    final filteredOrders =
        orders.where((order) {
          switch (selectedPeriod) {
            case '7 Days':
              return order.createdAt.isAfter(
                now.subtract(const Duration(days: 7)),
              );
            case '30 Days':
              return order.createdAt.isAfter(
                now.subtract(const Duration(days: 30)),
              );
            case '90 Days':
              return order.createdAt.isAfter(
                now.subtract(const Duration(days: 90)),
              );
            default:
              return true;
          }
        }).toList();

    final totalRevenue = filteredOrders.fold<double>(
      0,
      (sum, order) => sum + order.totalPrice,
    );
    final totalOrders = filteredOrders.length;
    final completedOrders =
        filteredOrders.where((o) => o.status == 'Delivered').length;
    final pendingOrders =
        filteredOrders.where((o) => o.status == 'Pending').length;
    final averageOrderValue =
        totalOrders > 0 ? totalRevenue / totalOrders : 0.0;

    // Product analytics
    final totalProducts = products.length;
    final activeProducts = products.where((p) => p.stock > 0).length;
    final lowStockProducts =
        products.where((p) => p.stock <= 5 && p.stock > 0).length;
    final outOfStockProducts = products.where((p) => p.stock == 0).length;

    // Order status distribution
    final statusCounts = <String, int>{};
    for (final order in filteredOrders) {
      statusCounts[order.status] = (statusCounts[order.status] ?? 0) + 1;
    }

    // Daily sales for chart
    final dailySales = <String, double>{};
    for (final order in filteredOrders) {
      final dateKey = '${order.createdAt.day}/${order.createdAt.month}';
      dailySales[dateKey] = (dailySales[dateKey] ?? 0) + order.totalPrice;
    }

    // Top products by orders
    final productOrderCounts = <String, int>{};
    for (final order in filteredOrders) {
      final productId = order.productId;
      if (productId != null) {
        productOrderCounts[productId] =
            (productOrderCounts[productId] ?? 0) + order.quantity;
      }
    }

    return {
      'totalRevenue': totalRevenue,
      'totalOrders': totalOrders,
      'completedOrders': completedOrders,
      'pendingOrders': pendingOrders,
      'averageOrderValue': averageOrderValue,
      'totalProducts': totalProducts,
      'activeProducts': activeProducts,
      'lowStockProducts': lowStockProducts,
      'outOfStockProducts': outOfStockProducts,
      'statusCounts': statusCounts,
      'dailySales': dailySales,
      'productOrderCounts': productOrderCounts,
      'completionRate':
          totalOrders > 0 ? (completedOrders / totalOrders * 100) : 0,
    };
  }

  Widget _buildOverviewCards(Map<String, dynamic> analytics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Business Overview',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildMetricCard(
              title: 'Total Revenue',
              value: '₹${analytics['totalRevenue'].toStringAsFixed(0)}',
              icon: Icons.currency_rupee,
              color: Colors.green,
              trend: '+12%',
            ),
            _buildMetricCard(
              title: 'Total Orders',
              value: '${analytics['totalOrders']}',
              icon: Icons.shopping_cart,
              color: Colors.blue,
              trend: '+8%',
            ),
            _buildMetricCard(
              title: 'Avg Order Value',
              value: '₹${analytics['averageOrderValue'].toStringAsFixed(0)}',
              icon: Icons.trending_up,
              color: Colors.orange,
              trend: '+5%',
            ),
            _buildMetricCard(
              title: 'Success Rate',
              value: '${analytics['completionRate'].toStringAsFixed(1)}%',
              icon: Icons.check_circle,
              color: Colors.purple,
              trend: '+3%',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? trend,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    trend,
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesChart(List<OrderModel> orders) {
    final dailySales = <String, double>{};
    final now = DateTime.now();

    // Get sales for last 7 days
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = '${date.day}/${date.month}';
      dailySales[dateKey] = 0;
    }

    for (final order in orders) {
      if (order.createdAt.isAfter(now.subtract(const Duration(days: 7)))) {
        final dateKey = '${order.createdAt.day}/${order.createdAt.month}';
        if (dailySales.containsKey(dateKey)) {
          dailySales[dateKey] = dailySales[dateKey]! + order.totalPrice;
        }
      }
    }

    final maxValue =
        dailySales.values.isEmpty
            ? 100.0
            : dailySales.values.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sales Trend (Last 7 Days)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children:
                  dailySales.entries.map((entry) {
                    final height =
                        maxValue > 0 ? (entry.value / maxValue * 150) : 0.0;
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '₹${entry.value.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 10),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 30,
                          height: height,
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(entry.key, style: const TextStyle(fontSize: 10)),
                      ],
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatusChart(Map<String, dynamic> analytics) {
    final statusCounts = analytics['statusCounts'] as Map<String, int>;
    final totalOrders = analytics['totalOrders'] as int;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Status Distribution',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (totalOrders == 0)
            const Center(
              child: Text(
                'No orders in selected period',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ...statusCounts.entries.map((entry) {
              final percentage = (entry.value / totalOrders * 100);
              final color = _getStatusColor(entry.key);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '${entry.value} (${percentage.toStringAsFixed(1)}%)',
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildTopProducts(
    List<OrderModel> orders,
    List<ProductModel> products,
  ) {
    final productOrderCounts = <String, int>{};
    for (final order in orders) {
      final productId = order.productId;
      if (productId != null) {
        productOrderCounts[productId] =
            (productOrderCounts[productId] ?? 0) + order.quantity;
      }
    }

    final sortedProducts =
        productOrderCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    final topProducts = sortedProducts.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Selling Products',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (topProducts.isEmpty)
            const Center(
              child: Text(
                'No product sales data available',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ...topProducts.asMap().entries.map((entry) {
              final index = entry.key;
              final productId = entry.value.key;
              final orderCount = entry.value.value;

              final product = products.firstWhere(
                (p) => p.productId == productId,
                orElse:
                    () => ProductModel(
                      productId: productId,
                      sellerId: '',
                      name: 'Unknown Product',
                      description: '',
                      price: 0,
                      category: '',
                      stock: 0,
                      imageUrl: '',
                      createdAt: DateTime.now(),
                    ),
              );

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '₹${product.price.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '$orderCount sold',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildRecentPerformance(Map<String, dynamic> analytics) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Product Performance',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPerformanceMetric(
                  'Active Products',
                  '${analytics['activeProducts']}',
                  Icons.inventory,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPerformanceMetric(
                  'Low Stock',
                  '${analytics['lowStockProducts']}',
                  Icons.warning,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPerformanceMetric(
                  'Out of Stock',
                  '${analytics['outOfStockProducts']}',
                  Icons.remove_circle,
                  Colors.red,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPerformanceMetric(
                  'Total Products',
                  '${analytics['totalProducts']}',
                  Icons.category,
                  Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetric(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary(Map<String, dynamic> analytics) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange[400]!, Colors.orange[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Financial Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Revenue',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  Text(
                    '₹${analytics['totalRevenue'].toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Avg Order Value',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  Text(
                    '₹${analytics['averageOrderValue'].toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white30),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFinancialMetric('Orders', '${analytics['totalOrders']}'),
              _buildFinancialMetric(
                'Completed',
                '${analytics['completedOrders']}',
              ),
              _buildFinancialMetric('Pending', '${analytics['pendingOrders']}'),
              _buildFinancialMetric(
                'Success Rate',
                '${analytics['completionRate'].toStringAsFixed(1)}%',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialMetric(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

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
}
