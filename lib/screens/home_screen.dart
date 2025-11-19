// ignore_for_file: prefer_const_constructors, use_build_context_synchronously

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import for FirebaseAuth
import '../providers/cart_provider.dart';
import '../widgets/tryitoutnow_button.dart';
import '../widgets/category_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentCarouselIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  int? _hoveredCategoryIndex;
  int? _hoveredFeaturedIndex;

  Future<List<QuerySnapshot<Map<String, dynamic>>>>? _featuredProductsFuture;

  // Get current user ID (must be non-null since app requires auth)
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _featuredProductsFuture = _fetchFeaturedProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- Firestore Logic ---

  // Function to add a product to the user's cart in Firestore
  Future<void> _addToCart(
      BuildContext context, Map<String, dynamic> product) async {
    if (userId == null) {
      // Should not happen if user is signed in, but handle defensively
      _showSnackbar(context, 'Error: User not logged in.', Colors.red);
      return;
    }

    // *** FIX: Ensure the product map contains a reliable 'docId' field.
    // This field is now populated in _buildFeaturedSection.
    final String? productId = product['docId'] as String?;

    if (productId == null) {
      _showSnackbar(context, 'Error: Product ID is missing.', Colors.red);
      return;
    }

    final docRef = FirebaseFirestore.instance
        .collection('carts')
        .doc(userId)
        .collection('items')
        .doc(productId); // *** FIX: Use the reliable Firestore docId ***

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
          'productId': productId, // Store the ID inside the cart item as well
          'name': product['name'],
          'price': product['price'],
          'imageUrl': product['imageUrl'] ?? product['image'],
          'quantity': 1,
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
  // --- End Firestore Logic ---

  // Method to fetch featured products (kept the same)
  Future<List<QuerySnapshot<Map<String, dynamic>>>> _fetchFeaturedProducts() {
    final categories = [
      'Fruits',
      'Dairy & Eggs',
      'Bakery',
      'Drinks',
      'Beauty',
      'Meat',
    ];

    return Future.wait(
      categories
          .map((category) => FirebaseFirestore.instance
              .collection('products')
              .where('category', isEqualTo: category)
              .limit(1)
              .get())
          .toList(),
    );
  }

  // REPLACED _logout with this function to add the confirmation dialog
  void _showLogoutConfirmation(BuildContext context) async {
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
      // Clear cart provider before actual sign out and navigation
      Provider.of<CartProvider>(context, listen: false).clear();
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        // Navigate to the login screen after successful logout
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWeb = constraints.maxWidth > 600;
        bool isLargeScreen = constraints.maxWidth > 900;
        int crossAxisCount = isLargeScreen ? 8 : (isWeb ? 6 : 4);
        double horizontalPadding = isWeb ? 24.0 : 16.0;

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: _buildAppBar(context, isWeb),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Enhanced Search Section
                _buildSearchSection(horizontalPadding),

                SizedBox(height: isWeb ? 32 : 20),

                // Enhanced Carousel Banner
                _buildCarouselBanner(isWeb),

                SizedBox(height: 16),

                // Improved Carousel Indicators
                _buildCarouselIndicators(),

                SizedBox(height: isWeb ? 40 : 28),

                // Categories Section
                _buildCategoriesSection(
                  horizontalPadding,
                  crossAxisCount,
                  isWeb,
                ),

                SizedBox(height: isWeb ? 40 : 28),

                // Featured Products Section
                _buildFeaturedSection(horizontalPadding, isWeb),

                SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isWeb) {
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.shopping_cart_rounded,
                color: Colors.white, size: 24),
          ),
          SizedBox(width: 12),
          const Text(
            'GroceryGo',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      centerTitle: true,
      backgroundColor: Colors.green[800],
      elevation: 0,
      actions: [
        // REMOVED NOTIFICATIONS ICON BUTTON HERE
        IconButton(
          icon: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.logout_rounded, color: Colors.white, size: 22),
          ),
          onPressed: () =>
              _showLogoutConfirmation(context), // UPDATED TO USE CONFIRMATION
          tooltip: 'Logout',
        ),
        SizedBox(width: 16),
      ],
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green[600]!, Colors.green[800]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSection(double horizontalPadding) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[600]!, Colors.green[800]!],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding:
          EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search for products, brands, and more...',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            prefixIcon: Padding(
              padding: EdgeInsets.all(12),
              child: Icon(Icons.search_rounded,
                  color: Colors.green[700], size: 26),
            ),
            contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          ),
          onChanged: (value) {
            // Implement search logic
          },
        ),
      ),
    );
  }

  Widget _buildCarouselBanner(bool isWeb) {
    return CarouselSlider(
      options: CarouselOptions(
        height: isWeb ? 220 : 180,
        autoPlay: true,
        enlargeCenterPage: true,
        viewportFraction: isWeb ? 0.85 : 0.92,
        aspectRatio: 2.0,
        onPageChanged: (index, reason) {
          setState(() {
            _currentCarouselIndex = index;
          });
        },
        enableInfiniteScroll: true,
        autoPlayInterval: Duration(seconds: 4),
        autoPlayCurve: Curves.easeInOutCubic,
      ),
      items: [
        _buildBannerItem(
          title: "50% CASHBACK",
          subtitle: "On Groceries",
          imagePath: "assets/image/gro.png",
          colors: [Colors.green[400]!, Colors.green[600]!],
        ),
        _buildBannerItem(
          title: "Fresh Fruits",
          subtitle: "20% Off Today",
          imagePath: "assets/image/cat2.png",
          colors: [Colors.orange[400]!, Colors.orange[600]!],
        ),
        _buildBannerItem(
          title: "Buy 1 Get 1",
          subtitle: "On Vegetables",
          imagePath: "assets/image/cat3.png",
          colors: [Colors.teal[400]!, Colors.teal[600]!],
        ),
      ],
    );
  }

  Widget _buildBannerItem({
    required String title,
    required String subtitle,
    required String imagePath,
    required List<Color> colors,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors[1].withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              left: -20,
              bottom: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Padding(
                    // FIX: Reduced vertical padding from 24.0 to 16.0
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.1,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.2),
                                offset: Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.95),
                          ),
                        ),
                        SizedBox(height: 16),
                        TryItOutNowButton(),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        imagePath,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarouselIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        3,
        (index) => AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: _currentCarouselIndex == index ? 32 : 8,
          height: 8,
          margin: EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: _currentCarouselIndex == index
                ? Colors.green[700]
                : Colors.grey[300],
            boxShadow: _currentCarouselIndex == index
                ? [
                    BoxShadow(
                      color: Colors.green[700]!.withOpacity(0.4),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : [],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesSection(
    double horizontalPadding,
    int crossAxisCount,
    bool isWeb,
  ) {
    final categories = [
      {
        "title": "Grocery",
        "imagePath": "assets/image/cat1.png",
        "color": Colors.blue[50]
      },
      {
        "title": "Fruits",
        "imagePath": "assets/image/cat2.png",
        "color": Colors.orange[50]
      },
      {
        "title": "Vegetables",
        "imagePath": "assets/image/cat3.png",
        "color": Colors.green[50]
      },
      {
        "title": "Drinks",
        "imagePath": "assets/image/cat4.png",
        "color": Colors.purple[50]
      },
      {
        "title": "Dairy & Eggs",
        "imagePath": "assets/image/cat5.png",
        "color": Colors.yellow[50]
      },
      {
        "title": "Beauty",
        "imagePath": "assets/image/cat6.png",
        "color": Colors.pink[50]
      },
      {
        "title": "Bakery",
        "imagePath": "assets/image/cat7.png",
        "color": Colors.brown[50]
      },
      {
        "title": "Meat",
        "imagePath": "assets/image/cat8.png",
        "color": Colors.red[50]
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Shop by Category',
                    style: TextStyle(
                      fontSize: isWeb ? 26 : 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[900],
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Find what you need',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              if (isWeb)
                TextButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.arrow_forward, size: 18),
                  label: Text('View All'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.green[700],
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: 20),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: isWeb ? 16 : 12,
              crossAxisSpacing: isWeb ? 16 : 12,
              // *** FINAL FIX APPLIED: Reduced aspect ratio from 0.70 to 0.60 to eliminate 19px overflow ***
              childAspectRatio: 0.60,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              bool isHovered = _hoveredCategoryIndex == index;
              return MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) => setState(() => _hoveredCategoryIndex = index),
                onExit: (_) => setState(() => _hoveredCategoryIndex = null),
                child: GestureDetector(
                  onTap: () {
                    // Navigate to category screen
                    Navigator.pushNamed(
                      context,
                      '/category',
                      arguments: categories[index]["title"]!,
                    );
                  },
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    transform: Matrix4.identity()
                      ..scale(isHovered ? 1.05 : 1.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: isHovered
                              ? Colors.green[200]!.withOpacity(0.5)
                              : Colors.grey.withOpacity(0.12),
                          blurRadius: isHovered ? 16 : 8,
                          offset: Offset(0, isHovered ? 6 : 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(isWeb ? 16 : 12),
                          decoration: BoxDecoration(
                            color: categories[index]["color"] as Color?,
                            shape: BoxShape.circle,
                          ),
                          child: Image.asset(
                            categories[index]["imagePath"]! as String,
                            height: isWeb ? 45 : 40,
                            width: isWeb ? 45 : 40,
                            fit: BoxFit.contain,
                          ),
                        ),
                        SizedBox(height: 10),
                        Padding(
                          padding:
                              EdgeInsets.only(left: 6, right: 6, bottom: 8),
                          child: Text(
                            categories[index]["title"]! as String,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isWeb ? 13 : 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedSection(double horizontalPadding, bool isWeb) {
    if (_featuredProductsFuture == null) {
      return SizedBox(
        height: isWeb ? 240 : 210,
        child: Center(child: Text('Initializing products...')),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Featured Products',
                    style: TextStyle(
                      fontSize: isWeb ? 26 : 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[900],
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Handpicked for you',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              if (isWeb)
                TextButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.arrow_forward, size: 18),
                  label: Text('See All'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.green[700],
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: 20),
        FutureBuilder<List<QuerySnapshot<Map<String, dynamic>>>>(
          future: _featuredProductsFuture!,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox(
                height: isWeb ? 240 : 210,
                child: Center(
                  child: CircularProgressIndicator(
                    color: Colors.green[700],
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              return SizedBox(
                height: isWeb ? 240 : 210,
                child: Center(
                  child: Text('Error loading products: ${snapshot.error}'),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return SizedBox(
                height: isWeb ? 240 : 210,
                child: Center(
                  child: Text('No featured products available'),
                ),
              );
            }

            // Extract products from snapshots
            final products = snapshot.data!
                .where((querySnapshot) => querySnapshot.docs.isNotEmpty)
                .map((querySnapshot) {
              final doc = querySnapshot.docs.first;
              // *** FIX: Merge the document ID into the product map
              // This ensures a stable, unique identifier for the cart.
              final productData = doc.data();
              productData['docId'] = doc.id;
              return productData;
            }).toList();

            if (products.isEmpty) {
              return SizedBox(
                height: isWeb ? 240 : 210,
                child: Center(
                  child: Text('No featured products available'),
                ),
              );
            }

            return SizedBox(
              height: isWeb ? 240 : 210,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding:
                    EdgeInsets.symmetric(horizontal: horizontalPadding - 8),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  bool isHovered = _hoveredFeaturedIndex == index;

                  return MouseRegion(
                    cursor: SystemMouseCursors.click,
                    onEnter: (_) =>
                        setState(() => _hoveredFeaturedIndex = index),
                    onExit: (_) => setState(() => _hoveredFeaturedIndex = null),
                    child: GestureDetector(
                      onTap: () {
                        // Optional: Navigate to product detail
                      },
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 200),
                        width: isWeb ? 180 : 150,
                        margin: EdgeInsets.symmetric(horizontal: 8),
                        transform: Matrix4.identity()
                          ..scale(isHovered ? 1.05 : 1.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: isHovered
                                  ? Colors.green[200]!.withOpacity(0.5)
                                  : Colors.grey.withOpacity(0.15),
                              blurRadius: isHovered ? 16 : 10,
                              offset: Offset(0, isHovered ? 6 : 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20)),
                              child: Image.network(
                                product['imageUrl'] ?? product['image'] ?? '',
                                height: isWeb ? 140 : 120,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    height: isWeb ? 140 : 120,
                                    color: Colors.grey[100],
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                            : null,
                                        color: Colors.green[700],
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: isWeb ? 140 : 120,
                                    color: Colors.grey[200],
                                    child: Icon(Icons.image_not_supported,
                                        size: 50, color: Colors.grey[400]),
                                  );
                                },
                              ),
                            ),
                            Padding(
                              // FIX: Reduced vertical padding from 14 to 12.
                              padding: EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product['name'] ?? 'Product',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Colors.grey[800],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '₱${(product['price'] ?? 0).toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green[700],
                                        ),
                                      ),
                                      // === ADD TO CART BUTTON (UPDATED) ===
                                      GestureDetector(
                                        onTap: () =>
                                            _addToCart(context, product),
                                        child: Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.green[700],
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Icon(Icons.add,
                                              color: Colors.white, size: 18),
                                        ),
                                      ),
                                      // ===================================
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
