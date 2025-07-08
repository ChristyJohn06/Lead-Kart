import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/products_provider.dart';
import '../../../core/providers/orders_provider.dart';
import 'tabs/my_products_tab.dart';
import 'tabs/seller_orders_tab.dart';
import 'tabs/seller_profile_tab.dart';

class SellerHomeScreen extends StatefulWidget {
  const SellerHomeScreen({super.key});

  @override
  State<SellerHomeScreen> createState() => _SellerHomeScreenState();
}

class _SellerHomeScreenState extends State<SellerHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _tabs = [
    const MyProductsTab(),
    const SellerOrdersTab(),
    const SellerProfileTab(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final productsProvider = Provider.of<ProductsProvider>(
      context,
      listen: false,
    );
    final ordersProvider = Provider.of<OrdersProvider>(context, listen: false);

    if (authProvider.currentSeller != null) {
      // Fetch seller's products and orders
      productsProvider.fetchSellerProducts(
        authProvider.currentSeller!.sellerId,
      );
      ordersProvider.fetchSellerOrders(authProvider.currentSeller!.sellerId);

      // Subscribe to real-time order updates
      ordersProvider.subscribeToOrderUpdates(
        authProvider.currentSeller!.sellerId,
        true,
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'My Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.orange,
        onTap: _onItemTapped,
      ),
    );
  }
}
