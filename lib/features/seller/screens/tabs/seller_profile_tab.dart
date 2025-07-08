import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../auth/screens/initial_screen.dart';
import '../seller_analytics_screen.dart';

class SellerProfileTab extends StatefulWidget {
  const SellerProfileTab({super.key});

  @override
  State<SellerProfileTab> createState() => _SellerProfileTabState();
}

class _SellerProfileTabState extends State<SellerProfileTab> {
  @override
  void initState() {
    super.initState();
    // Seller notifications setup removed - clean initialization
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Profile'),
        backgroundColor: Colors.orange,
        automaticallyImplyLeading: false,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final seller = authProvider.currentSeller;

          if (seller == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.login, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Please log in to view your profile',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange[400]!, Colors.orange[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.store,
                          size: 48,
                          color: Colors.orange[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        seller.username,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        seller.brandName,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        seller.phone ?? seller.email,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.circle,
                              size: 8,
                              color:
                                  seller.status == 'online'
                                      ? Colors.green
                                      : Colors.grey[300],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              seller.status == 'online' ? 'Online' : 'Offline',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Profile Options
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      SellerProfileMenuItem(
                        icon: Icons.edit,
                        title: 'Edit Profile',
                        subtitle: 'Update your business information',
                        onTap: () {
                          _showEditProfileDialog(context, seller);
                        },
                      ),
                      const Divider(height: 1),
                      SellerProfileMenuItem(
                        icon: Icons.inventory,
                        title: 'My Products',
                        subtitle: 'Manage your product inventory',
                        onTap: () {
                          DefaultTabController.of(context).animateTo(0);
                        },
                      ),
                      const Divider(height: 1),
                      SellerProfileMenuItem(
                        icon: Icons.receipt_long,
                        title: 'Sales History',
                        subtitle: 'View your sales and orders',
                        onTap: () {
                          DefaultTabController.of(context).animateTo(1);
                        },
                      ),
                      const Divider(height: 1),
                      SellerProfileMenuItem(
                        icon: Icons.toggle_on,
                        title: 'Online Status',
                        subtitle: 'Toggle your availability',
                        onTap: () {
                          _toggleOnlineStatus(context, authProvider, seller);
                        },
                      ),
                      const Divider(height: 1),
                      SellerProfileMenuItem(
                        icon: Icons.analytics,
                        title: 'Analytics',
                        subtitle: 'View your business insights',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (context) => const SellerAnalyticsScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      SellerProfileMenuItem(
                        icon: Icons.help,
                        title: 'Help & Support',
                        subtitle: 'Get help or contact support',
                        onTap: () {
                          _showHelpDialog(context);
                        },
                      ),
                      const Divider(height: 1),
                      // Logout Menu Item with Red Styling
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.logout,
                            color: Colors.red[600],
                            size: 24,
                          ),
                        ),
                        title: Text(
                          'Logout',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            color: Colors.red[700],
                          ),
                        ),
                        subtitle: const Text(
                          'Sign out of your seller account',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          final confirmed = await _showLogoutDialog(context);
                          if (confirmed == true) {
                            await authProvider.signOut();
                            if (context.mounted) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (context) => const InitialScreen(),
                                ),
                                (route) => false,
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // App Version
                Text(
                  'LEAD Kart Seller v1.0.0',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, dynamic seller) {
    final usernameController = TextEditingController(text: seller.username);
    final brandController = TextEditingController(text: seller.brandName);
    final phoneController = TextEditingController(text: seller.phone ?? '');

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Seller Profile'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: brandController,
                  decoration: const InputDecoration(
                    labelText: 'Brand Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  // TODO: Implement profile update
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile update coming soon!'),
                    ),
                  );
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  void _toggleOnlineStatus(
    BuildContext context,
    AuthProvider authProvider,
    dynamic seller,
  ) async {
    final newStatus = seller.status == 'online' ? 'offline' : 'online';

    try {
      // TODO: Implement updateSellerStatus method in AuthProvider
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Status toggle coming soon! Would set to ${newStatus.toUpperCase()}',
          ),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Seller Help & Support'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need help with your seller account?',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 16),
                Text('📞 Seller Support: +91 1234567890'),
                SizedBox(height: 8),
                Text('📞 Phone: +91 1234567890'),
                SizedBox(height: 8),
                Text('📧 Email: seller-support@leadkart.com'),
                SizedBox(height: 8),
                Text('🕒 Support Hours: 9 AM - 8 PM'),
                SizedBox(height: 16),
                Text(
                  'Seller Guide:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 8),
                Text('• Add products with clear photos'),
                Text('• Set competitive prices'),
                Text('• Keep your status online'),
                Text('• Respond to orders quickly'),
                Text('• Maintain good product stock'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('About LEAD Kart'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LEAD Kart Seller',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('Version 1.0.0'),
                SizedBox(height: 16),
                Text(
                  'LEAD Kart connects sellers with college students and staff. '
                  'Grow your business by selling food and products directly to customers in your area.',
                ),
                SizedBox(height: 16),
                Text(
                  '🚀 Seller Features:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 8),
                Text('• Manage product inventory'),
                Text('• Real-time order notifications'),
                Text('• Direct order communication'),
                Text('• Sales analytics and insights'),
                Text('• Online/offline status control'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Future<bool?> _showLogoutDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text(
              'Are you sure you want to logout from your seller account?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Logout'),
              ),
            ],
          ),
    );
  }
}

class SellerProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const SellerProfileMenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.orange[600], size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[600], fontSize: 14),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
