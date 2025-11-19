import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // REQUIRED for Firestore
import 'package:firebase_auth/firebase_auth.dart'; // REQUIRED for User ID
// import 'package:provider/provider.dart'; // Unused - removed in previous step
// import '../providers/cart_provider.dart'; // Unused - removed in previous step

class CategoryScreen extends StatelessWidget {
  final String categoryTitle;
  final String? userId; // Field to hold the user ID

  // IMPORTANT: Removed 'const' keyword and initialized userId at runtime
  CategoryScreen({super.key, required this.categoryTitle})
      : userId = FirebaseAuth.instance.currentUser?.uid;

  // --- Firestore Logic ---

  // Simple method to display a message to the user
  void _showSnackbar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(milliseconds: 1500),
      ),
    );
  }

  // Function to add a product to the user's cart in Firestore
  Future<void> _addToCart(
      BuildContext context, Map<String, dynamic> product) async {
    if (userId == null) {
      _showSnackbar(context, 'Error: User not logged in.', Colors.red);
      return;
    }

    // Use the product ID from Firestore document ID
    final String productId = product['id'] as String? ?? product['name'];
    final docRef = FirebaseFirestore.instance
        .collection('carts')
        .doc(userId)
        .collection('items')
        .doc(productId);

    try {
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        // If the item exists, increment the quantity
        final currentQuantity = docSnapshot.data()?['quantity'] as int? ?? 0;
        await docRef.update({'quantity': currentQuantity + 1});
        _showSnackbar(
            context, 'Increased quantity of ${product['name']}', Colors.orange);
      } else {
        // If the item does not exist, create a new document
        await docRef.set({
          'productId': productId,
          'name': product['name'],
          'price': product['price'],
          'imageUrl': product['imageUrl'] ?? product['image'],
          'quantity': 1, // Start with 1
          'addedAt': FieldValue.serverTimestamp(),
        });
        _showSnackbar(
            context, '${product['name']} added to cart!', Colors.green);
      }
    } catch (e) {
      _showSnackbar(context, 'Failed to add item to cart: $e', Colors.red);
      print('Firestore error: $e');
    }
  }

  // --- End Firestore Logic ---

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: Text(categoryTitle),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection('products')
            .where('category', isEqualTo: categoryTitle)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: Colors.green[700],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                  SizedBox(height: 16),
                  Text(
                    'Error loading products',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_basket_outlined,
                      size: 80, color: Colors.grey[300]),
                  SizedBox(height: 16),
                  Text(
                    'No products in this category',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          var products = snapshot.data!.docs;

          return ListView.builder(
            itemCount: products.length,
            padding: EdgeInsets.all(8),
            itemBuilder: (context, index) {
              var product = products[index];
              Map<String, dynamic> productData =
                  product.data() as Map<String, dynamic>;

              String productId = product.id; // Get the Firestore document ID
              String productName = productData['name'] ?? 'Unknown Product';
              double productPrice = productData['price']?.toDouble() ?? 0.0;
              String imageUrl = productData['imageUrl'] ?? '';
              int quantity = productData['quantity'] ?? 0;

              // Combined product map required by _addToCart
              final productMap = {
                ...productData,
                'id': productId,
              };

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.all(12),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[200],
                                child: Icon(
                                  Icons.image,
                                  color: Colors.grey[400],
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[100],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.green[700],
                                  ),
                                ),
                              );
                            },
                          )
                        : Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.image,
                              color: Colors.grey[400],
                            ),
                          ),
                  ),
                  title: Text(
                    productName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4),
                      Text(
                        '₱${productPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Stock: $quantity',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  trailing: Container(
                    decoration: BoxDecoration(
                      color: quantity > 0 ? Colors.green[700] : Colors.grey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.add_shopping_cart),
                      color: Colors.white,
                      onPressed: quantity > 0
                          ? () {
                              // *** UPDATED: Call the Firestore function ***
                              _addToCart(context, productMap);
                            }
                          : null,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
