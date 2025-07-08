import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/providers/products_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/orders_provider.dart';
import '../../../models/product_model.dart';
import '../../../core/config/supabase_config.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String productId;

  const ProductDetailsScreen({super.key, required this.productId});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  ProductModel? product;
  String? sellerBrandName;
  String sellerStatus = 'offline';
  bool isLoading = true;
  int quantity = 1;
  String? selectedDeliveryLocation;

  final List<String> deliveryLocations = [
    'bbcourt',
    'frontoffice',
    'newhostel',
  ];

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    try {
      final productsProvider = Provider.of<ProductsProvider>(
        context,
        listen: false,
      );
      final loadedProduct = await productsProvider.getProductById(
        widget.productId,
      );

      // Fetch seller brand name and status
      String? brandName;
      String status = 'offline';
      if (loadedProduct != null) {
        final productsProvider = Provider.of<ProductsProvider>(
          context,
          listen: false,
        );

        try {
          final response =
              await SupabaseConfig.client
                  .from('sellers')
                  .select('brand_name')
                  .eq('seller_id', loadedProduct.sellerId)
                  .single();
          brandName = response['brand_name'] as String?;
        } catch (e) {
          print('Error fetching seller brand name: $e');
        }

        // Fetch seller status
        try {
          status = await productsProvider.getSellerStatus(
            loadedProduct.sellerId,
          );
        } catch (e) {
          print('Error fetching seller status: $e');
        }
      }

      setState(() {
        product = loadedProduct;
        sellerBrandName = brandName;
        sellerStatus = status;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading product: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showOrderConfirmation() async {
    if (product == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentCustomer;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to place an order'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if seller is online
    if (sellerStatus.toLowerCase() != 'online') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seller is currently offline. Please try again later.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if enough stock is available
    if (quantity > product!.stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Only ${product!.stock} items available in stock'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if delivery location is selected
    if (selectedDeliveryLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a delivery location'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Cannot dismiss by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.shopping_cart, color: Colors.blue),
              SizedBox(width: 8),
              Text('Confirm Your Order'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '⚠️ IMPORTANT: Once you confirm this order, it cannot be cancelled. Please review your order details carefully.',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Product: ${product!.name}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    if (sellerBrandName != null)
                      Text('Brand: $sellerBrandName'),
                    const SizedBox(height: 4),
                    Text('Quantity: $quantity'),
                    const SizedBox(height: 4),
                    Text(
                      'Price per item: ₹${product!.price.toStringAsFixed(0)}',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Delivery: ${selectedDeliveryLocation!.toUpperCase()}',
                    ),
                    const Divider(),
                    Text(
                      'Total Amount: ₹${(product!.price * quantity).toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Are you sure you want to place this order?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm Order'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _orderProduct();
    }
  }

  Future<void> _orderProduct() async {
    if (product == null) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentCustomer;

      if (currentUser == null) return;

      // Show loading
      setState(() {
        isLoading = true;
      });

      final ordersProvider = Provider.of<OrdersProvider>(
        context,
        listen: false,
      );
      final productsProvider = Provider.of<ProductsProvider>(
        context,
        listen: false,
      );

      // Create order in database
      final success = await ordersProvider.createOrder(
        customerId: currentUser.userId,
        sellerId: product!.sellerId,
        productId: product!.productId,
        quantity: quantity,
        totalPrice: product!.price * quantity,
        deliveryLocation: selectedDeliveryLocation ?? 'bbcourt',
      );

      if (success) {
        // Update product stock
        final newStock = product!.stock - quantity;
        await productsProvider.updateProductStock(product!.productId, newStock);

        // Update local product
        setState(() {
          product = product!.copyWith(stock: newStock);
          quantity = 1; // Reset quantity
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order placed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to place order: ${ordersProvider.errorMessage}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error placing order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        backgroundColor: Colors.blue,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : product == null
              ? const Center(
                child: Text(
                  'Product not found',
                  style: TextStyle(fontSize: 18),
                ),
              )
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Image
                    SizedBox(
                      height: 300,
                      width: double.infinity,
                      child:
                          product!.imageUrl != null &&
                                  product!.imageUrl!.isNotEmpty
                              ? CachedNetworkImage(
                                imageUrl: product!.imageUrl!,
                                fit: BoxFit.cover,
                                placeholder:
                                    (context, url) => Container(
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                errorWidget:
                                    (context, url, error) => Container(
                                      color: Colors.grey[200],
                                      child: const Icon(
                                        Icons.image_not_supported,
                                        size: 60,
                                      ),
                                    ),
                              )
                              : Container(
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.image,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                              ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product Name
                          Text(
                            product!.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Price
                          Text(
                            '₹${product!.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Stock Status
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  product!.isInStock
                                      ? Colors.green
                                      : Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              product!.isInStock ? 'In Stock' : 'Out of Stock',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Seller Brand Name and Status
                          if (sellerBrandName != null)
                            Column(
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'Brand: ',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        sellerBrandName!,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.blue,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Seller Status
                                Row(
                                  children: [
                                    const Text(
                                      'Seller Status: ',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            sellerStatus.toLowerCase() ==
                                                    'online'
                                                ? Colors.green
                                                : Colors.grey,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            sellerStatus.toLowerCase() ==
                                                    'online'
                                                ? 'Online'
                                                : 'Offline',
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
                                const SizedBox(height: 16),
                              ],
                            ),

                          // Description
                          if (product!.description != null &&
                              product!.description!.isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Description',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  product!.description!,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),

                          // Category
                          Row(
                            children: [
                              const Text(
                                'Category: ',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                product!.category,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Available Stock (Dynamic)
                          Row(
                            children: [
                              const Text(
                                'Available: ',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${(product!.stock - quantity).clamp(0, product!.stock)} items',
                                style: TextStyle(
                                  fontSize: 16,
                                  color:
                                      (product!.stock - quantity).clamp(
                                                0,
                                                product!.stock,
                                              ) >
                                              5
                                          ? Colors.green
                                          : (product!.stock - quantity).clamp(
                                                0,
                                                product!.stock,
                                              ) >
                                              0
                                          ? Colors.orange
                                          : Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '(${product!.stock} total)',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Delivery Location Dropdown
                          if (product!.isInStock)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Delivery Location',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: selectedDeliveryLocation,
                                      hint: const Text(
                                        'Select delivery location',
                                      ),
                                      isExpanded: true,
                                      items:
                                          deliveryLocations.map((
                                            String location,
                                          ) {
                                            return DropdownMenuItem<String>(
                                              value: location,
                                              child: Text(
                                                location.toUpperCase(),
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          selectedDeliveryLocation = newValue;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),

                          // Quantity Selector
                          if (product!.isInStock)
                            Column(
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'Quantity: ',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed:
                                          quantity > 1
                                              ? () {
                                                setState(() {
                                                  quantity--;
                                                });
                                              }
                                              : null,
                                      icon: const Icon(Icons.remove),
                                      style: IconButton.styleFrom(
                                        backgroundColor:
                                            quantity > 1
                                                ? Colors.blue[50]
                                                : Colors.grey[100],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        quantity.toString(),
                                        style: const TextStyle(fontSize: 18),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed:
                                          quantity < product!.stock
                                              ? () {
                                                setState(() {
                                                  quantity++;
                                                });
                                              }
                                              : null,
                                      icon: const Icon(Icons.add),
                                      style: IconButton.styleFrom(
                                        backgroundColor:
                                            quantity < product!.stock
                                                ? Colors.blue[50]
                                                : Colors.grey[100],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Stock Status Indicator
                                if (quantity >= product!.stock)
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.orange[50],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.orange[200]!,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.warning_amber,
                                          color: Colors.orange[700],
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'You\'ve selected the maximum available quantity',
                                            style: TextStyle(
                                              color: Colors.orange[700],
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 16),

                                // Total Price
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.blue[200]!,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Total:',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '₹${(product!.price * quantity).toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      bottomNavigationBar:
          product != null && product!.isInStock
              ? Container(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed:
                      sellerStatus.toLowerCase() == 'online'
                          ? _showOrderConfirmation
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        sellerStatus.toLowerCase() == 'online'
                            ? Colors.blue
                            : Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    sellerStatus.toLowerCase() == 'online'
                        ? 'Place Order'
                        : 'Seller Offline - Cannot Order',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
              : null,
    );
  }
}
