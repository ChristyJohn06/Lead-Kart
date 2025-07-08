import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import 'initial_screen.dart';
import '../../customer/screens/customer_home_screen.dart';
import '../../seller/screens/seller_home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Defer initialization until after the build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  _initializeApp() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Initialize auth state
    await authProvider.initialize();

    // Wait for 2 seconds for splash effect
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Navigate based on auth state
    if (authProvider.isAuthenticated) {
      if (authProvider.userType == UserType.customer) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
        );
      } else if (authProvider.userType == UserType.seller) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SellerHomeScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const InitialScreen()),
        );
      }
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const InitialScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo/Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(60),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.shopping_cart,
                size: 60,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 30),
            // App Name
            const Text(
              'LEAD Kart',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'College E-Commerce Platform',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 50),
            // Loading indicator
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}
