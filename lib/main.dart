import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/config/supabase_config.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/products_provider.dart';
import 'core/providers/orders_provider.dart';
import 'features/auth/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await SupabaseConfig.initialize();

  runApp(const LeadKartApp());
}

class LeadKartApp extends StatelessWidget {
  const LeadKartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductsProvider()),
        ChangeNotifierProvider(create: (_) => OrdersProvider()),
      ],
      child: MaterialApp(
        title: 'LEAD Kart',
        debugShowCheckedModeBanner: false,
        theme: _buildLiquidGlassTheme(),
        home: const SplashScreen(),
      ),
    );
  }

  ThemeData _buildLiquidGlassTheme() {
    return ThemeData(
      primarySwatch: Colors.blue,
      fontFamily: 'Roboto',
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }
}
