// ignore_for_file: prefer_const_constructors, use_key_in_widget_constructors, unused_element, library_private_types_in_public_api, avoid_print

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- Helper Model to represent a fully populated Cart Item ---
class CartItemModel {
  final String docId;
  final String productId;
  final String name;
  final double price;
  final String? imageUrl;
  final int quantity;
  bool isSelected;

  CartItemModel({
    required this.docId,
    required this.productId,
    required this.name,
    required this.price,
    this.imageUrl,
    required this.quantity,
    this.isSelected = false,
  });
}

class CartScreen extends StatefulWidget {
  CartScreen({super.key});

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Future<Map<String, Map<String, dynamic>>>? _productsFuture;

  Set<String> selectedItemIds = <String>{};
  bool selectAll = false;
  bool _isProcessing = false; // Prevent multiple submissions

  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _productsFuture = _fetchAllProducts();
  }

  Future<Map<String, Map<String, dynamic>>> _fetchAllProducts() async {
    try {
      final productSnapshot = await _firestore.collection('products').get();
      final Map<String, Map<String, dynamic>> products = {};

      for (var doc in productSnapshot.docs) {
        products[doc.id] = doc.data() as Map<String, dynamic>;
      }
      return products;
    } catch (e) {
      print('Error fetching all products: $e');
      return {};
    }
  }

  void _toggleItemSelection(String docId) {
    setState(() {
      if (selectedItemIds.contains(docId)) {
        selectedItemIds.remove(docId);
      } else {
        selectedItemIds.add(docId);
      }
    });
  }

  void _toggleSelectAll(List<CartItemModel> items) {
    setState(() {
      if (selectAll) {
        selectedItemIds.clear();
        selectAll = false;
      } else {
        selectedItemIds = items.map((item) => item.docId).toSet();
        selectAll = true;
      }
    });
  }

  // Enhanced Payment Method Selection Dialog
  Future<void> _showPaymentMethodDialog(BuildContext context,
      List<CartItemModel> selectedItems, double totalAmount) async {
    String? selectedPaymentMethod;

    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(Icons.payment, color: Colors.green[700], size: 28),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Select Payment Method',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Order Summary with enhanced styling
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green[50]!, Colors.green[100]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green[200]!, width: 1),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.shopping_cart,
                                      color: Colors.green[700], size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    '${selectedItems.length} item${selectedItems.length > 1 ? 's' : ''}',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.green[700],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '₱${totalAmount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),

                    // Section Title
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Choose your payment method:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    SizedBox(height: 12),

                    // Payment Method Options
                    _PaymentMethodTile(
                      icon: Icons.money,
                      title: 'Cash on Delivery',
                      subtitle: 'Pay when you receive your order',
                      value: 'Cash on Delivery',
                      groupValue: selectedPaymentMethod,
                      onChanged: (value) {
                        setDialogState(() {
                          selectedPaymentMethod = value;
                        });
                      },
                    ),
                    SizedBox(height: 12),
                    _PaymentMethodTile(
                      icon: Icons.account_balance_wallet,
                      title: 'GCash',
                      subtitle: 'Pay instantly via GCash wallet',
                      value: 'GCash',
                      groupValue: selectedPaymentMethod,
                      onChanged: (value) {
                        setDialogState(() {
                          selectedPaymentMethod = value;
                        });
                      },
                    ),
                    SizedBox(height: 12),
                    _PaymentMethodTile(
                      icon: Icons.paypal,
                      title: 'PayPal',
                      subtitle: 'Secure payment with PayPal',
                      value: 'PayPal',
                      groupValue: selectedPaymentMethod,
                      onChanged: (value) {
                        setDialogState(() {
                          selectedPaymentMethod = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: selectedPaymentMethod != null
                      ? () {
                          // FIXED: Close dialog first, then proceed with checkout
                          Navigator.of(dialogContext).pop();

                          // Add a small delay to ensure dialog closes properly
                          Future.delayed(Duration(milliseconds: 150), () {
                            if (context.mounted) {
                              _checkoutTransaction(
                                context,
                                selectedItems,
                                totalAmount,
                                selectedPaymentMethod!,
                              );
                            }
                          });
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    elevation: selectedPaymentMethod != null ? 3 : 0,
                  ),
                  icon: Icon(
                    Icons.check_circle,
                    color: selectedPaymentMethod != null
                        ? Colors.white
                        : Colors.grey[600],
                    size: 20,
                  ),
                  label: Text(
                    'Place Order',
                    style: TextStyle(
                      color: selectedPaymentMethod != null
                          ? Colors.white
                          : Colors.grey[600],
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Checkout Transaction - includes payment method and delivery address
  // Checkout Transaction - FINAL FIXED VERSION
  Future<void> _checkoutTransaction(
    BuildContext context,
    List<CartItemModel> selectedItems,
    double totalAmount,
    String paymentMethod,
  ) async {
    // Prevent multiple submissions
    if (_isProcessing) return;

    final userId = currentUserId;
    if (userId == null) {
      _showMessage(context, 'Error: User not logged in!', isError: true);
      return;
    }

    if (selectedItems.isEmpty) {
      _showMessage(context, 'Please select at least one item to checkout',
          isError: true);
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    // Store context and create a completer to track dialog state
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // Show loading dialog and store whether it was shown
    navigator.push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        barrierColor: Colors.black54,
        pageBuilder: (_, __, ___) => WillPopScope(
          onWillPop: () async => false,
          child: Center(
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      color: Colors.green[700],
                      strokeWidth: 3,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Processing order...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    try {
      // Perform checkout with timeout
      await _performCheckout(userId, selectedItems, totalAmount, paymentMethod)
          .timeout(Duration(seconds: 15));

      // Close loading dialog
      navigator.pop();

      // Clear selection
      if (mounted) {
        setState(() {
          selectedItemIds.clear();
          selectAll = false;
          _isProcessing = false;
        });
      }

      // Show success message
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Order placed!\n$paymentMethod • ₱${totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green[700],
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      // Close loading dialog
      navigator.pop();

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }

      print('Checkout failed: $e');

      // Show error message
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  e.toString().contains('TimeoutException')
                      ? 'Request timeout. Please check your internet connection.'
                      : e.toString().replaceAll('Exception:', '').trim(),
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red[700],
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Helper method to show messages safely
  void _showMessage(BuildContext context, String message,
      {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[700] : Colors.orange[700],
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Separate method for the actual checkout logic
  Future<void> _performCheckout(
    String userId,
    List<CartItemModel> selectedItems,
    double totalAmount,
    String paymentMethod,
  ) async {
    // Parallel execution for faster processing
    final results = await Future.wait([
      // Fetch address
      _firestore
          .collection('addresses')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get()
          .timeout(Duration(seconds: 5)),
      // Fetch all product snapshots in parallel
      Future.wait(selectedItems.map((item) => _firestore
          .collection('products')
          .doc(item.productId)
          .get()
          .timeout(Duration(seconds: 5)))),
    ]);

    final addressSnapshot = results[0] as QuerySnapshot;
    final productSnapshots = results[1] as List<DocumentSnapshot>;

    // Check if address exists
    if (addressSnapshot.docs.isEmpty) {
      throw Exception('Please add a delivery address before placing an order');
    }

    // Build product snapshots map
    final Map<String, DocumentSnapshot> productSnapshotsMap = {};
    for (int i = 0; i < selectedItems.length; i++) {
      productSnapshotsMap[selectedItems[i].productId] = productSnapshots[i];
    }

    // Validate stock availability
    for (final item in selectedItems) {
      final productSnapshot = productSnapshotsMap[item.productId];

      if (productSnapshot == null || !productSnapshot.exists) {
        throw Exception('Product ${item.name} not found!');
      }

      final productData = productSnapshot.data() as Map<String, dynamic>?;
      final currentStock = (productData?['quantity'] as num?)?.toInt() ?? 0;

      if (currentStock < item.quantity) {
        throw Exception(
            'Insufficient stock for ${item.name}. Available: $currentStock');
      }
    }

    // Perform the transaction with timeout
    await _firestore.runTransaction(
      (transaction) async {
        final now = Timestamp.now();

        // Create order
        final orderRef = _firestore.collection('orders').doc();
        transaction.set(orderRef, {
          'userId': userId,
          'totalAmount': totalAmount,
          'timestamp': now,
          'status': 'Pending',
          'paymentMethod': paymentMethod,
          'items': selectedItems
              .map((item) => {
                    'productId': item.productId,
                    'name': item.name,
                    'price': item.price,
                    'quantity': item.quantity,
                  })
              .toList(),
        });

        // Update inventory and remove cart items
        final cartDocRef = _firestore.collection('carts').doc(userId);

        for (final item in selectedItems) {
          final productRef =
              _firestore.collection('products').doc(item.productId);
          final productSnapshot = productSnapshotsMap[item.productId]!;
          final productData = productSnapshot.data() as Map<String, dynamic>?;
          final currentStock = (productData?['quantity'] as num?)?.toInt() ?? 0;

          transaction
              .update(productRef, {'quantity': currentStock - item.quantity});
          transaction.delete(cartDocRef.collection('items').doc(item.docId));
        }
      },
      timeout: Duration(seconds: 8),
    );
  }

  // Shows payment method dialog
  void _proceedToPayment(BuildContext context, List<CartItemModel> allItems) {
    // Filter only selected items
    final selectedItems =
        allItems.where((item) => selectedItemIds.contains(item.docId)).toList();

    // Calculate total for selected items only
    final totalAmount = selectedItems.fold<double>(
      0.0,
      (sum, item) => sum + (item.price * item.quantity),
    );

    // Show payment method selection dialog
    _showPaymentMethodDialog(context, selectedItems, totalAmount);
  }

  Future<void> _updateQuantity(String docId, int newQuantity) async {
    final userId = currentUserId;
    if (userId == null) return;

    if (newQuantity <= 0) {
      await _removeItem(docId);
      return;
    }

    try {
      await _firestore
          .collection('carts')
          .doc(userId)
          .collection('items')
          .doc(docId)
          .update({'quantity': newQuantity});
      print('Updated quantity for $docId to $newQuantity');
    } catch (e) {
      print('Error updating quantity: $e');
    }
  }

  Future<void> _removeItem(String docId) async {
    final userId = currentUserId;
    if (userId == null) return;
    try {
      await _firestore
          .collection('carts')
          .doc(userId)
          .collection('items')
          .doc(docId)
          .delete();

      setState(() {
        selectedItemIds.remove(docId);
      });

      print('Removed item $docId from cart');
    } catch (e) {
      print('Error removing item: $e');
    }
  }

  // New method to handle logout with professional confirmation
  void _logout(BuildContext context) async {
    // Show a professional confirmation dialog before logging out
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        // Improved look: Title with icon and consistent padding
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Colors.deepOrange, size: 28),
            SizedBox(width: 12),
            Text(
              'Confirm Logout',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        content: const Text(
          'You will be signed out of your account. Do you wish to proceed?',
          style: TextStyle(fontSize: 16, color: Colors.black87),
        ),
        actions: [
          // Cancel Button (TextButton, less emphasis)
          TextButton(
            onPressed: () {
              // Dismiss dialog, return false (not confirmed)
              Navigator.of(ctx).pop(false);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[700],
            ),
            child: const Text('Cancel'),
          ),
          // Logout Button (ElevatedButton/FilledButton, primary action emphasis)
          FilledButton.icon(
            onPressed: () {
              // Dismiss dialog, return true (confirmed)
              Navigator.of(ctx).pop(true);
            },
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Log Out'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green[700], // Matches app bar color
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // Rounded dialog corners
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 15),
      ),
    );

    // Proceed with logout only if confirmed and context is still mounted
    if (confirmed == true && context.mounted) {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        // Navigate to the login screen after successful logout
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = currentUserId;

    // --- Helper function for the common AppBar ---
    AppBar _buildCartAppBar({
      required String title,
      required Color backgroundColor,
      List<Widget>? actions,
      bool? centerTitle,
    }) {
      return AppBar(
        title: Text(title),
        // Set centerTitle to true as requested
        centerTitle: centerTitle ?? true,
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: actions,
      );
    }

    final logoutAction = IconButton(
      icon: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.logout_rounded, color: Colors.white, size: 22),
      ),
      onPressed: () => _logout(context),
      tooltip: 'Logout',
    );

    if (userId == null) {
      return Scaffold(
        appBar: _buildCartAppBar(
          title: 'Your Cart',
          backgroundColor: Colors.green[700]!,
          actions: [logoutAction, SizedBox(width: 16)],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 80, color: Colors.grey[400]),
              SizedBox(height: 16),
              Text(
                'Please log in to view your cart.',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return FutureBuilder<Map<String, Map<String, dynamic>>>(
      future: _productsFuture,
      builder: (context, productSnapshot) {
        if (productSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: _buildCartAppBar(
              title: 'Your Cart',
              backgroundColor: Colors.green[700]!,
              actions: [logoutAction, SizedBox(width: 16)],
            ),
            body: Center(
                child: CircularProgressIndicator(color: Colors.green[700])),
          );
        }

        if (productSnapshot.hasError || !productSnapshot.hasData) {
          return Scaffold(
            appBar: _buildCartAppBar(
              title: 'Your Cart',
              backgroundColor: Colors.red[700]!,
              actions: [logoutAction, SizedBox(width: 16)],
            ),
            body: Center(
                child:
                    Text('Error loading products: ${productSnapshot.error}')),
          );
        }

        final productCatalog = productSnapshot.data!;

        return Scaffold(
          appBar: _buildCartAppBar(
            title: 'Your Cart',
            backgroundColor: Colors.green[700]!,
            actions: [logoutAction, SizedBox(width: 16)],
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('carts')
                .doc(userId)
                .collection('items')
                .snapshots(),
            builder: (context, cartSnapshot) {
              if (cartSnapshot.connectionState == ConnectionState.waiting) {
                return Center(
                    child: CircularProgressIndicator(color: Colors.green[700]));
              }

              if (cartSnapshot.hasError) {
                return Center(
                    child: Text('Error loading cart: ${cartSnapshot.error}'));
              }

              final cartItemsDocs = cartSnapshot.data?.docs ?? [];
              final List<CartItemModel> finalCartItems = [];
              double selectedTotal = 0;

              for (var doc in cartItemsDocs) {
                final cartData = doc.data() as Map<String, dynamic>;
                final docId = doc.id;
                final productId = cartData['productId'] as String?;
                final quantity = (cartData['quantity'] as num?)?.toInt() ?? 1;

                if (productId != null &&
                    productCatalog.containsKey(productId)) {
                  final productData = productCatalog[productId]!;

                  final name =
                      productData['name'] as String? ?? 'Unknown Product';
                  final price =
                      (productData['price'] as num?)?.toDouble() ?? 0.0;
                  final imageUrl = productData['imageUrl'] as String?;

                  final cartItem = CartItemModel(
                    docId: docId,
                    productId: productId,
                    name: name,
                    price: price,
                    imageUrl: imageUrl,
                    quantity: quantity,
                    isSelected: selectedItemIds.contains(docId),
                  );

                  finalCartItems.add(cartItem);

                  if (selectedItemIds.contains(docId)) {
                    selectedTotal += cartItem.price * cartItem.quantity;
                  }
                } else {
                  print('Product ID $productId not found in catalog.');
                }
              }

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && finalCartItems.isNotEmpty) {
                  final shouldSelectAll =
                      selectedItemIds.length == finalCartItems.length;
                  if (selectAll != shouldSelectAll) {
                    setState(() {
                      selectAll = shouldSelectAll;
                    });
                  }
                }
              });

              if (finalCartItems.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined,
                          size: 80, color: Colors.green[300]),
                      SizedBox(height: 16),
                      Text(
                        'Your cart is empty!',
                        style: TextStyle(fontSize: 20, color: Colors.grey[700]),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Time to start shopping.',
                        style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.grey[100],
                    child: Row(
                      children: [
                        Checkbox(
                          value: selectAll,
                          onChanged: (value) =>
                              _toggleSelectAll(finalCartItems),
                          activeColor: Colors.green[700],
                        ),
                        Text(
                          'Select All',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Spacer(),
                        Text(
                          '${selectedItemIds.length} of ${finalCartItems.length} selected',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: finalCartItems.length,
                      itemBuilder: (context, index) {
                        final item = finalCartItems[index];

                        return _CartItemWidget(
                          docId: item.docId,
                          name: item.name,
                          price: item.price,
                          imageUrl: item.imageUrl,
                          quantity: item.quantity,
                          isSelected: selectedItemIds.contains(item.docId),
                          onToggleSelection: () =>
                              _toggleItemSelection(item.docId),
                          onUpdateQuantity: _updateQuantity,
                          onRemoveItem: _removeItem,
                        );
                      },
                    ),
                  ),
                  _CheckoutBottomBar(
                    totalAmount: selectedTotal,
                    selectedCount: selectedItemIds.length,
                    onProceedToPayment: () =>
                        _proceedToPayment(context, finalCartItems),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

// Enhanced Payment Method Tile Widget
class _PaymentMethodTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final String? groupValue;
  final ValueChanged<String?> onChanged;

  const _PaymentMethodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;

    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.green[700]! : Colors.grey[300]!,
            width: isSelected ? 2.5 : 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? Colors.green[50] : Colors.white,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            // Custom Radio Button
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.green[700]! : Colors.grey[400]!,
                  width: 2,
                ),
                color: isSelected ? Colors.green[700] : Colors.transparent,
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
            SizedBox(width: 12),
            // Icon
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.green[100] : Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.green[700] : Colors.grey[600],
                size: 26,
              ),
            ),
            SizedBox(width: 14),
            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.green[700] : Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            // Selected Indicator
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Colors.green[700],
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

// --- Helper Widget for a single Cart Item ---
class _CartItemWidget extends StatelessWidget {
  final String docId;
  final String name;
  final double price;
  final String? imageUrl;
  final int quantity;
  final bool isSelected;
  final VoidCallback onToggleSelection;
  final Function(String, int) onUpdateQuantity;
  final Function(String) onRemoveItem;

  const _CartItemWidget({
    required this.docId,
    required this.name,
    required this.price,
    this.imageUrl,
    required this.quantity,
    required this.isSelected,
    required this.onToggleSelection,
    required this.onUpdateQuantity,
    required this.onRemoveItem,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: isSelected
            ? BorderSide(color: Colors.green[700]!, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: isSelected,
              onChanged: (value) => onToggleSelection(),
              activeColor: Colors.green[700],
            ),
            SizedBox(width: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 70,
                height: 70,
                color: Colors.grey[200],
                child: imageUrl != null && imageUrl!.isNotEmpty
                    ? Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.fastfood, size: 35, color: Colors.grey),
                      )
                    : Icon(Icons.shopping_bag_outlined,
                        size: 35, color: Colors.grey),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    '₱${price.toStringAsFixed(2)} / unit',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      _QuantityButton(
                        icon: Icons.remove,
                        onTap: () => onUpdateQuantity(docId, quantity - 1),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          '$quantity',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      _QuantityButton(
                        icon: Icons.add,
                        onTap: () => onUpdateQuantity(docId, quantity + 1),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₱${(price * quantity).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.green[700],
                  ),
                ),
                SizedBox(height: 8),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red[400]),
                  onPressed: () => onRemoveItem(docId),
                  tooltip: 'Remove from cart',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- Simple Quantity Button ---
class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QuantityButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: Colors.green[700]),
      ),
    );
  }
}

// --- Checkout Bottom Bar ---
class _CheckoutBottomBar extends StatelessWidget {
  final double totalAmount;
  final int selectedCount;
  final VoidCallback onProceedToPayment;

  const _CheckoutBottomBar({
    required this.totalAmount,
    required this.selectedCount,
    required this.onProceedToPayment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selectedCount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '$selectedCount item${selectedCount > 1 ? 's' : ''} selected',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total:',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF424242))),
              Text('₱${totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700])),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: selectedCount > 0 ? onProceedToPayment : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 5,
              ),
              child: Text(
                selectedCount > 0
                    ? 'Proceed to Payment ($selectedCount item${selectedCount > 1 ? 's' : ''})'
                    : 'Select items to checkout',
                style: TextStyle(
                  fontSize: 18,
                  color: selectedCount > 0 ? Colors.white : Colors.grey[600],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
