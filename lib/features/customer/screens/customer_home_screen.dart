import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/products_provider.dart';
import '../../../core/providers/orders_provider.dart';
import 'tabs/home_tab.dart';
import 'tabs/orders_tab.dart';
import 'tabs/profile_tab.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _tabs = [
    const HomeTab(),
    const OrdersTab(),
    const ProfileTab(),
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

    // Fetch initial data
    productsProvider.fetchProducts();

    if (authProvider.currentCustomer != null) {
      final customerId = authProvider.currentCustomer!.userId;

      // Fetch orders
      ordersProvider.fetchCustomerOrders(customerId);

      // Subscribe to real-time order updates
      ordersProvider.subscribeToOrderUpdates(customerId, false);
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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Orders',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}
