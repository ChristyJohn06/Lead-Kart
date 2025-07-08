import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/product_model.dart';
import '../config/supabase_config.dart';

class ProductsProvider with ChangeNotifier {
  final SupabaseClient _supabase = SupabaseConfig.client;

  List<ProductModel> _products = [];
  List<ProductModel> _sellerProducts = [];
  List<ProductModel> _filteredProducts = [];
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;

  // Real-time tracking
  Map<String, String> _sellerStatuses = {};
  RealtimeChannel? _sellersChannel;
  RealtimeChannel? _productsChannel;

  // Getters
  List<ProductModel> get products => _filteredProducts;
  List<ProductModel> get sellerProducts => _sellerProducts;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, String> get sellerStatuses => _sellerStatuses;

  void _setLoading(bool loading) {
    _isLoading = loading;
    _safeNotifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    _safeNotifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    _safeNotifyListeners();
  }

  void _safeNotifyListeners() {
    try {
      // Check if we can safely notify listeners
      if (!hasListeners) return;

      // Use post frame callback if called during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          if (hasListeners) {
            notifyListeners();
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Deferred notifyListeners error: $e');
          }
        }
      });
    } catch (e) {
      // Handle the case where notifyListeners is called after dispose
      if (kDebugMode) {
        debugPrint('Error in notifyListeners: $e');
      }
    }
  }

  // Initialize real-time tracking
  void initializeSellerStatusTracking() {
    _setupSellerStatusSubscription();
    _setupProductsSubscription();
    _fetchInitialSellerStatuses();
  }

  // Setup real-time subscription for seller status changes
  void _setupSellerStatusSubscription() {
    print('🔧 Setting up seller status tracking...');

    _sellersChannel =
        _supabase
            .channel('public:sellers')
            .onPostgresChanges(
              event: PostgresChangeEvent.update,
              schema: 'public',
              table: 'sellers',
              callback: (payload) {
                try {
                  final newRecord = payload.newRecord;
                  final sellerId = newRecord['seller_id']?.toString();
                  final status = newRecord['status']?.toString() ?? 'offline';

                  if (sellerId != null) {
                    _sellerStatuses[sellerId] = status;
                    print('📱 Seller status updated: $sellerId -> $status');
                    _safeNotifyListeners();
                  }
                } catch (e) {
                  print('❌ Error processing seller status update: $e');
                }
              },
            )
            .subscribe();

    print('✅ Seller status tracking channel subscribed');
  }

  // Setup real-time subscription for product changes
  void _setupProductsSubscription() {
    print('🔧 Setting up product changes tracking...');

    _productsChannel =
        _supabase
            .channel('public:products')
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'products',
              callback: (payload) {
                try {
                  final newRecord = payload.newRecord;
                  final newProduct = ProductModel.fromJson(newRecord);

                  // Add to main products list
                  _products.insert(0, newProduct);
                  _applyFilters();

                  print('➕ Product added: ${newProduct.name}');
                } catch (e) {
                  print('❌ Error processing product insert: $e');
                }
              },
            )
            .onPostgresChanges(
              event: PostgresChangeEvent.update,
              schema: 'public',
              table: 'products',
              callback: (payload) {
                try {
                  final newRecord = payload.newRecord;
                  final updatedProduct = ProductModel.fromJson(newRecord);

                  // Update in main products list
                  final productIndex = _products.indexWhere(
                    (p) => p.productId == updatedProduct.productId,
                  );
                  if (productIndex != -1) {
                    _products[productIndex] = updatedProduct;
                    _applyFilters();
                  }

                  print('🔄 Product updated: ${updatedProduct.name}');
                } catch (e) {
                  print('❌ Error processing product update: $e');
                }
              },
            )
            .onPostgresChanges(
              event: PostgresChangeEvent.delete,
              schema: 'public',
              table: 'products',
              callback: (payload) {
                try {
                  final oldRecord = payload.oldRecord;
                  final productId = oldRecord['product_id']?.toString();

                  if (productId != null) {
                    // Remove from main products list
                    final removedProduct = _products.firstWhere(
                      (p) => p.productId == productId,
                      orElse:
                          () => ProductModel(
                            productId: productId,
                            name: 'Unknown',
                            price: 0,
                            stock: 0,
                            sellerId: '',
                            category: '',
                            createdAt: DateTime.now(),
                          ),
                    );

                    _products.removeWhere((p) => p.productId == productId);
                    _applyFilters();

                    print('🗑️ Product deleted: ${removedProduct.name}');
                  }
                } catch (e) {
                  print('❌ Error processing product delete: $e');
                }
              },
            )
            .subscribe();

    print('✅ Product changes tracking channel subscribed');
  }

  // Fetch initial seller statuses for all current products
  Future<void> _fetchInitialSellerStatuses() async {
    try {
      // Get unique seller IDs from current products
      final sellerIds = _products.map((p) => p.sellerId).toSet().toList();

      if (sellerIds.isEmpty) return;

      final response = await _supabase
          .from('sellers')
          .select('seller_id, status')
          .inFilter('seller_id', sellerIds);

      for (final seller in response) {
        final sellerId = seller['seller_id']?.toString();
        final status = seller['status']?.toString() ?? 'offline';
        if (sellerId != null) {
          _sellerStatuses[sellerId] = status;
        }
      }

      print(
        '📱 Loaded initial seller statuses: ${_sellerStatuses.length} sellers',
      );
      _safeNotifyListeners();
    } catch (e) {
      print('❌ Error fetching initial seller statuses: $e');
    }
  }

  // Get seller status (now uses cached real-time data)
  String getSellerStatus(String sellerId) {
    return _sellerStatuses[sellerId] ?? 'offline';
  }

  // Fetch all products for customers
  Future<void> fetchProducts() async {
    _setLoading(true);
    try {
      final response = await _supabase
          .from('products')
          .select()
          .order('created_at', ascending: false);

      _products =
          response
              .map<ProductModel>((json) => ProductModel.fromJson(json))
              .toList();
      _applyFilters();

      // Fetch seller statuses after loading products
      await _fetchInitialSellerStatuses();

      _setError(null);
    } catch (e) {
      _setError(e.toString());
    }
    _setLoading(false);
  }

  // Fetch products for a specific seller
  Future<void> fetchSellerProducts(String sellerId) async {
    _setLoading(true);
    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('seller_id', sellerId)
          .order('created_at', ascending: false);

      _sellerProducts =
          response
              .map<ProductModel>((json) => ProductModel.fromJson(json))
              .toList();
      _setError(null);
    } catch (e) {
      _setError(e.toString());
    }
    _setLoading(false);
  }

  // Get product with seller info
  Future<Map<String, dynamic>?> getProductWithSeller(String productId) async {
    try {
      final response =
          await _supabase
              .from('products')
              .select('*, sellers!inner(*)')
              .eq('product_id', productId)
              .single();

      return response;
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  // Add new product
  Future<bool> addProduct(ProductModel product) async {
    _setLoading(true);
    try {
      final response =
          await _supabase
              .from('products')
              .insert(product.toInsertJson())
              .select()
              .single();

      final newProduct = ProductModel.fromJson(response);
      _sellerProducts.insert(0, newProduct);
      _setError(null);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Update product
  Future<bool> updateProduct(ProductModel product) async {
    _setLoading(true);
    try {
      await _supabase
          .from('products')
          .update(product.toInsertJson())
          .eq('product_id', product.productId);

      final index = _sellerProducts.indexWhere(
        (p) => p.productId == product.productId,
      );
      if (index != -1) {
        _sellerProducts[index] = product;
      }

      _setError(null);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Delete product
  Future<bool> deleteProduct(String productId) async {
    _setLoading(true);
    try {
      await _supabase.from('products').delete().eq('product_id', productId);

      _sellerProducts.removeWhere((p) => p.productId == productId);
      _setError(null);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Set category filter
  void setCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
  }

  // Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  // Apply filters and search
  void _applyFilters() {
    _filteredProducts =
        _products.where((product) {
          bool matchesCategory =
              _selectedCategory == 'All' ||
              product.category == _selectedCategory;
          bool matchesSearch =
              _searchQuery.isEmpty ||
              product.name.toLowerCase().contains(_searchQuery.toLowerCase());

          return matchesCategory && matchesSearch;
        }).toList();

    _safeNotifyListeners();
  }

  // Update product stock after order
  Future<void> updateProductStock(String productId, int newStock) async {
    try {
      await _supabase
          .from('products')
          .update({'stock': newStock})
          .eq('product_id', productId);

      // Update local product list
      final productIndex = _products.indexWhere(
        (p) => p.productId == productId,
      );
      if (productIndex != -1) {
        _products[productIndex] = _products[productIndex].copyWith(
          stock: newStock,
        );
        _applyFilters();
      }

      final sellerProductIndex = _sellerProducts.indexWhere(
        (p) => p.productId == productId,
      );
      if (sellerProductIndex != -1) {
        _sellerProducts[sellerProductIndex] =
            _sellerProducts[sellerProductIndex].copyWith(stock: newStock);
        _safeNotifyListeners();
      }
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<ProductModel?> getProductById(String productId) async {
    try {
      final response =
          await _supabase
              .from('products')
              .select()
              .eq('product_id', productId)
              .single();

      return ProductModel.fromJson(response);
    } catch (e) {
      print('Error fetching product: $e');
      return null;
    }
  }

  // Cleanup resources
  @override
  void dispose() {
    if (_sellersChannel != null) {
      _supabase.removeChannel(_sellersChannel!);
      _sellersChannel = null;
      print('🧹 Seller status tracking channel cleaned up');
    }
    if (_productsChannel != null) {
      _supabase.removeChannel(_productsChannel!);
      _productsChannel = null;
      print('🧹 Product changes tracking channel cleaned up');
    }
    super.dispose();
  }
}
