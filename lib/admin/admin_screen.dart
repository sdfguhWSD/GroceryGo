// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  // Hardcoded categories list
  final List<String> _categories = [
    'Grocery',
    'Fruits',
    'Vegetables',
    'Drinks',
    'Dairy & Eggs',
    'Beauty',
    'Bakery',
    'Meat'
  ];

  // Cloudinary credentials
  final String cloudinaryCloudName = 'dzvhd3ipg';
  final String cloudinaryApiKey = '776745665314531';
  final String cloudinaryUploadPreset =
      'ml_default'; // You may need to create an unsigned upload preset

  // Controllers for adding products
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _productPriceController = TextEditingController();
  final TextEditingController _productQuantityController =
      TextEditingController();
  String _selectedCategory = 'Grocery';

  // Image handling
  XFile? _selectedImage;
  String? _uploadedImageUrl;
  bool _isUploading = false;

  @override
  void dispose() {
    _productNameController.dispose();
    _productPriceController.dispose();
    _productQuantityController.dispose();
    super.dispose();
  }

  // REPLACE the existing _logout() method inside _AdminDashboardScreenState class with this:
  void _logout() async {
    // Show a professional confirmation dialog before logging out
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
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
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Log Out'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green[700],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 15),
      ),
    );

    // Proceed with logout only if confirmed and context is still mounted
    if (confirmed == true && context.mounted) {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  // Image picker method
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = image;
          _uploadedImageUrl = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  // Upload image to Cloudinary
  Future<String?> _uploadToCloudinary(XFile image) async {
    try {
      setState(() {
        _isUploading = true;
      });

      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudinaryCloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', url);

      // Add upload preset for unsigned upload
      request.fields['upload_preset'] =
          'grocerygo_products'; // Create this in Cloudinary dashboard
      request.fields['folder'] = 'grocerygo/products';

      // Add the image file
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: image.name,
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath('file', image.path),
        );
      }

      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);
      final jsonResponse = json.decode(responseString);

      setState(() {
        _isUploading = false;
      });

      if (response.statusCode == 200) {
        return jsonResponse['secure_url'];
      } else {
        throw Exception('Upload failed: ${jsonResponse['error']['message']}');
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWeb = constraints.maxWidth > 900;

        return Scaffold(
          backgroundColor: Colors.grey[50],
          body: Row(
            children: [
              // Side Navigation (Desktop)
              if (isWeb) _buildSideNav(),

              // Main Content
              Expanded(
                child: Column(
                  children: [
                    _buildTopBar(isWeb),
                    Expanded(
                      child: _buildMainContent(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Bottom Navigation (Mobile)
          bottomNavigationBar: !isWeb ? _buildBottomNav() : null,
          floatingActionButton: _selectedIndex == 1
              ? FloatingActionButton.extended(
                  onPressed: () {
                    _showAddProductDialog();
                  },
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  icon: Icon(Icons.add),
                  label: Text('Add Product'),
                )
              : null,
        );
      },
    );
  }

  Widget _buildSideNav() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[600]!, Colors.green[800]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(24),
            child: Row(
              children: [
                Icon(Icons.shopping_cart_rounded,
                    color: Colors.white, size: 32),
                SizedBox(width: 12),
                Text(
                  'GroceryGo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Divider(color: Colors.white24, thickness: 1),
          SizedBox(height: 16),
          _buildNavItem(0, Icons.dashboard, 'Dashboard'),
          _buildNavItem(1, Icons.inventory_2, 'Products'),
          _buildNavItem(2, Icons.people, 'Users'),
          _buildNavItem(3, Icons.shopping_bag, 'Orders'),
          Spacer(),
          Padding(
            padding: EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _logout,
              icon: Icon(Icons.logout),
              label: Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400],
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String title) {
    bool isSelected = _selectedIndex == index;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedIndex = index;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withOpacity(0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? Colors.white.withOpacity(0.3)
                    : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 24),
                SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: Colors.green[700],
        unselectedItemColor: Colors.grey[600],
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        backgroundColor: Colors.transparent,
        items: [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2), label: 'Products'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag), label: 'Orders'),
        ],
      ),
    );
  }

  Widget _buildTopBar(bool isWeb) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (!isWeb) // Mobile/Narrow View Title
            Row(
              children: [
                Icon(Icons.shopping_cart_rounded,
                    color: Colors.green[700], size: 28),
                SizedBox(width: 8),
                Text(
                  'Admin Panel',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          if (isWeb) // Web/Wide View Title
            Text(
              _getPageTitle(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          Spacer(),
          IconButton(
            icon: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  Icon(Icons.logout_rounded, color: Colors.red[700], size: 22),
            ),
            onPressed: _logout, // REMOVED: () => _logout(context)
            tooltip: 'Logout',
          ),
        ],
      ),
    );
  }

  String _getPageTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Products Management';
      case 2:
        return 'Users Management';
      case 3:
        return 'Orders Management';
      default:
        return 'Dashboard';
    }
  }

  Widget _buildMainContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return _buildProducts();
      case 2:
        return _buildUsers();
      case 3:
        return _buildOrders();
      default:
        return _buildDashboard();
    }
  }

  // Dashboard
  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overview',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = constraints.maxWidth > 900 ? 3 : 2;
              return GridView.count(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _buildStatCard(
                    'Total Users',
                    Icons.people,
                    Colors.blue,
                    _firestore.collection('users'),
                  ),
                  _buildStatCard(
                    'Total Products',
                    Icons.inventory_2,
                    Colors.green,
                    _firestore.collection('products'),
                  ),
                  _buildStaticStatCard(
                    'Categories',
                    Icons.category,
                    Colors.purple,
                    _categories.length,
                  ),
                ],
              );
            },
          ),
          SizedBox(height: 32),
          Text(
            'Recent Orders',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 16),
          _buildRecentOrders(),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, IconData icon, Color color,
      CollectionReference collection) {
    return StreamBuilder<QuerySnapshot>(
      stream: collection.snapshots(),
      builder: (context, snapshot) {
        int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
        return Container(
          // FIX: Reduced padding from 20 to 16 to save vertical space and fix overflow
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // FIX: Reduced font size from 30 to 24 to fix the overflow
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStaticStatCard(
      String title, IconData icon, Color color, int count) {
    return Container(
      // FIX: Reduced padding from 20 to 16 to save vertical space and fix overflow
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // FIX: Reduced font size from 30 to 24 to fix the overflow
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Fixed Recent Orders Widget
  Widget _buildRecentOrders() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('orders')
          .orderBy('timestamp', descending: true) // Changed from 'createdAt'
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          print('Error loading recent orders: ${snapshot.error}');
          return Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Error: ${snapshot.error}',
              style: TextStyle(color: Colors.red[700]),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState('No orders yet');
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: snapshot.data!.docs.length,
            separatorBuilder: (context, index) => Divider(height: 1),
            itemBuilder: (context, index) {
              var order = snapshot.data!.docs[index];
              return ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.shopping_bag, color: Colors.green[700]),
                ),
                title: Text('Order #${order.id.substring(0, 8)}'),
                subtitle: Text(order['status'] ?? 'Pending'),
                trailing: Text(
                  '\$${order['totalAmount']?.toStringAsFixed(2) ?? '0.00'}', // Changed from 'total'
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Products Management
  Widget _buildProducts() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('products').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState('No products available. Add one now!');
        }

        return GridView.builder(
          padding: EdgeInsets.all(24),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 300,
            childAspectRatio: 0.75,
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var product = snapshot.data!.docs[index];
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                    child: product['imageUrl'] != null
                        ? Image.network(
                            product['imageUrl'],
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 150,
                                color: Colors.grey[200],
                                child: Icon(Icons.image,
                                    size: 50, color: Colors.grey[400]),
                              );
                            },
                          )
                        : Container(
                            height: 150,
                            color: Colors.grey[200],
                            child: Icon(Icons.image,
                                size: 50, color: Colors.grey[400]),
                          ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['name'] ?? 'Unknown',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  product['category'] ?? '',
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Qty: ${product['quantity'] ?? 0}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '\$${product['price']?.toStringAsFixed(2) ?? '0.00'}',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit,
                                        color: Colors.blue[600]),
                                    onPressed: () {
                                      _showEditProductDialog(
                                          product.id,
                                          product.data()
                                              as Map<String, dynamic>);
                                    },
                                    tooltip: 'Edit Product',
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      _deleteProduct(product.id);
                                    },
                                    tooltip: 'Delete Product',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Users Management
  Widget _buildUsers() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState('No users registered yet');
        }

        return ListView.builder(
          padding: EdgeInsets.all(24),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var user = snapshot.data!.docs[index];
            String userRole = user['role'] ?? 'Customer';
            return Container(
              margin: EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      userRole == 'Admin' ? Colors.red[100] : Colors.blue[100],
                  child: Icon(Icons.person,
                      color: userRole == 'Admin'
                          ? Colors.red[700]
                          : Colors.blue[700]),
                ),
                title: Text(
                  user['fullName'] ?? 'User Name N/A',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user['email'] ?? 'Email N/A'),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: userRole == 'Admin'
                                ? Colors.red[50]
                                : Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            userRole,
                            style: TextStyle(
                              fontSize: 12,
                              color: userRole == 'Admin'
                                  ? Colors.red[700]
                                  : Colors.blue[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'ID: ${user.id.substring(0, 8)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    _deleteUser(user.id);
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Orders Management - FIXED VERSION
  Widget _buildOrders() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('orders')
          .orderBy('timestamp', descending: true) // Changed from 'createdAt'
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          print('Error loading orders: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                SizedBox(height: 16),
                Text(
                  'Error loading orders',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState('No orders yet');
        }

        return ListView.builder(
          padding: EdgeInsets.all(24),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var order = snapshot.data!.docs[index];
            String currentStatus = order['status'] ?? 'Pending';
            String userId = order['userId'] ?? '';

            return Container(
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ExpansionTile(
                leading: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getStatusColor(currentStatus).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.shopping_bag,
                      color: _getStatusColor(currentStatus)),
                ),
                title: Text(
                  'Order #${order.id.substring(0, 8)}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Container(
                  margin: EdgeInsets.only(top: 8),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(currentStatus).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    currentStatus,
                    style: TextStyle(
                      color: _getStatusColor(currentStatus),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${order['totalAmount']?.toStringAsFixed(2) ?? '0.00'}', // Changed from 'total'
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _formatDate(
                          order['timestamp']), // Changed from 'createdAt'
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                children: [
                  // Use FutureBuilder to fetch user address
                  FutureBuilder<DocumentSnapshot?>(
                    future: _getUserAddress(userId),
                    builder: (context, addressSnapshot) {
                      return Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildOrderDetail(
                                'Customer ID', order['userId'] ?? 'Unknown'),
                            _buildOrderDetail(
                                'Order Date',
                                order['timestamp']
                                        ?.toDate()
                                        .toString()
                                        .split(' ')[0] ??
                                    'N/A'),
                            _buildOrderDetail('Payment Method',
                                order['paymentMethod'] ?? 'N/A'),

                            // Display user address if available
                            if (addressSnapshot.connectionState ==
                                ConnectionState.waiting)
                              Padding(
                                padding: EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 120,
                                      child: Text(
                                        'Delivery Address:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                  ],
                                ),
                              )
                            else if (addressSnapshot.hasData &&
                                addressSnapshot.data != null)
                              _buildOrderDetail(
                                  'Delivery Address',
                                  _formatAddress(addressSnapshot.data!.data()
                                      as Map<String, dynamic>))
                            else
                              _buildOrderDetail(
                                  'Delivery Address', 'No address found'),

                            SizedBox(height: 16),

                            // Order Items
                            if (order['items'] != null &&
                                (order['items'] as List).isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Order Items:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[700],
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  ...(order['items'] as List).map((item) {
                                    return Container(
                                      margin: EdgeInsets.only(bottom: 8),
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item['name'] ??
                                                      'Unknown Product',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  'Qty: ${item['quantity'] ?? 0}',
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            '\$${(item['price'] ?? 0).toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  SizedBox(height: 16),
                                ],
                              ),

                            // Status Selector
                            Text(
                              'Update Status:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildStatusChip(
                                    order.id, 'Pending', currentStatus),
                                _buildStatusChip(
                                    order.id, 'Processing', currentStatus),
                                _buildStatusChip(
                                    order.id, 'Shipped', currentStatus),
                                _buildStatusChip(
                                    order.id, 'Delivered', currentStatus),
                                _buildStatusChip(
                                    order.id, 'Completed', currentStatus),
                                _buildStatusChip(
                                    order.id, 'Cancelled', currentStatus),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Helper method to fetch user address
  Future<DocumentSnapshot?> _getUserAddress(String userId) async {
    try {
      // Query addresses collection for this user
      QuerySnapshot addressQuery = await _firestore
          .collection('addresses')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (addressQuery.docs.isNotEmpty) {
        return addressQuery.docs.first;
      }
      return null;
    } catch (e) {
      print('Error fetching address: $e');
      return null;
    }
  }

  // Helper method to format address
  String _formatAddress(Map<String, dynamic> addressData) {
    List<String> addressParts = [];

    if (addressData['street'] != null &&
        addressData['street'].toString().isNotEmpty) {
      addressParts.add(addressData['street']);
    }
    if (addressData['label'] != null &&
        addressData['label'].toString().isNotEmpty) {
      addressParts.add(addressData['label']);
    }
    if (addressData['city'] != null &&
        addressData['city'].toString().isNotEmpty) {
      addressParts.add(addressData['city']);
    }
    if (addressData['province'] != null &&
        addressData['province'].toString().isNotEmpty) {
      addressParts.add(addressData['province']);
    }
    if (addressData['zipCode'] != null &&
        addressData['zipCode'].toString().isNotEmpty) {
      addressParts.add(addressData['zipCode']);
    }
    if (addressData['phone'] != null &&
        addressData['phone'].toString().isNotEmpty) {
      addressParts.add('Phone: ${addressData['phone']}');
    }

    return addressParts.isNotEmpty
        ? addressParts.join(', ')
        : 'Address not available';
  }

  Widget _buildStatusChip(String orderId, String status, String currentStatus) {
    bool isSelected = status == currentStatus;
    Color statusColor = _getStatusColor(status);
    return InkWell(
      onTap: () {
        _updateOrderStatus(orderId, status);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? statusColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? statusColor : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              Padding(
                padding: EdgeInsets.only(right: 6),
                child: Icon(
                  Icons.check_circle,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            Text(
              status,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[800],
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Processing':
        return Colors.blue;
      case 'Shipped':
        return Colors.indigo;
      case 'Delivered':
        return Colors.green;
      case 'Completed':
        return Colors.purple;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 80, color: Colors.grey[300]),
            SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      DateTime dateTime;
      if (timestamp is Timestamp) {
        dateTime = timestamp.toDate();
      } else if (timestamp is String) {
        dateTime = DateTime.parse(timestamp);
      } else {
        return 'Invalid Date';
      }
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return 'Invalid Date';
    }
  }

  Widget _buildOrderDetail(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Product CRUD Operations
  void _showAddProductDialog() {
    // Reset controllers before opening
    _productNameController.clear();
    _productPriceController.clear();
    _productQuantityController.clear();
    _selectedImage = null;
    _uploadedImageUrl = null;
    _selectedCategory = _categories.first;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.add_shopping_cart, color: Colors.green[700]),
              ),
              SizedBox(width: 12),
              Text(
                'Add New Product',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Container(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(
                    'Product Name *',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: _productNameController,
                    decoration: InputDecoration(
                      hintText: 'Enter product name',
                      prefixIcon: Icon(Icons.shopping_bag_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                  SizedBox(height: 20),

                  // Price and Quantity Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Price *',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: 8),
                            TextField(
                              controller: _productPriceController,
                              decoration: InputDecoration(
                                hintText: '0.00',
                                prefixIcon: Icon(Icons.attach_money),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              keyboardType: TextInputType.numberWithOptions(
                                  decimal: true),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quantity *',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: 8),
                            TextField(
                              controller: _productQuantityController,
                              decoration: InputDecoration(
                                hintText: '0',
                                prefixIcon: Icon(Icons.inventory_2_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Category Dropdown
                  Text(
                    'Category *',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.category_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    items: _categories.map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setDialogState(() {
                        _selectedCategory = newValue!;
                      });
                    },
                  ),
                  SizedBox(height: 20),

                  // Image Upload
                  Text(
                    'Product Image *',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      await _pickImage();
                      setDialogState(() {});
                    },
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      child: _selectedImage != null
                          ? Stack(
                              children: [
                                Positioned.fill(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: kIsWeb
                                        ? Image.network(
                                            _selectedImage!.path,
                                            width: double.infinity,
                                            height: double.infinity,
                                            fit: BoxFit.cover,
                                          )
                                        : Image.file(
                                            File(_selectedImage!.path),
                                            width: double.infinity,
                                            height: double.infinity,
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: CircleAvatar(
                                    backgroundColor: Colors.red,
                                    child: IconButton(
                                      icon: Icon(Icons.close,
                                          color: Colors.white, size: 20),
                                      onPressed: () {
                                        setDialogState(() {
                                          _selectedImage = null;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.cloud_upload_outlined,
                                    size: 60, color: Colors.grey[400]),
                                SizedBox(height: 12),
                                Text(
                                  'Click to upload image',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'PNG, JPG up to 10MB',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  if (_isUploading)
                    Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.grey[200],
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.green[700]!),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isUploading ? null : () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _isUploading
                  ? null
                  : () async {
                      if (_productNameController.text.isEmpty ||
                          _productPriceController.text.isEmpty ||
                          _productQuantityController.text.isEmpty ||
                          _selectedImage == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Please fill all fields and select an image'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      // Upload image to Cloudinary
                      String? imageUrl =
                          await _uploadToCloudinary(_selectedImage!);
                      if (imageUrl != null) {
                        _uploadedImageUrl = imageUrl;
                        _addProduct();
                        if (mounted) Navigator.pop(context);
                      }
                    },
              icon: Icon(Icons.add_box_outlined),
              label: Text('Add Product'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProductDialog(
      String productId, Map<String, dynamic> productData) {
    // Initialize controllers with existing data
    _productNameController.text = productData['name'] ?? '';
    _productPriceController.text =
        productData['price']?.toStringAsFixed(2) ?? '0.00';
    _productQuantityController.text =
        productData['quantity']?.toString() ?? '0';
    _selectedCategory = productData['category'] ?? _categories.first;
    _uploadedImageUrl = productData['imageUrl']; // Use existing image URL
    _selectedImage = null; // No new image selected initially

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.edit, color: Colors.blue[700]),
              ),
              SizedBox(width: 12),
              Text(
                'Edit Product',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Container(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(
                    'Product Name *',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: _productNameController,
                    decoration: InputDecoration(
                      hintText: 'Enter product name',
                      prefixIcon: Icon(Icons.shopping_bag_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                  SizedBox(height: 20),

                  // Price and Quantity Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Price *',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: 8),
                            TextField(
                              controller: _productPriceController,
                              decoration: InputDecoration(
                                hintText: '0.00',
                                prefixIcon: Icon(Icons.attach_money),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              keyboardType: TextInputType.numberWithOptions(
                                  decimal: true),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quantity *',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: 8),
                            TextField(
                              controller: _productQuantityController,
                              decoration: InputDecoration(
                                hintText: '0',
                                prefixIcon: Icon(Icons.inventory_2_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Category Dropdown
                  Text(
                    'Category *',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.category_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    items: _categories.map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setDialogState(() {
                        _selectedCategory = newValue!;
                      });
                    },
                  ),
                  SizedBox(height: 20),

                  // Image Upload/Preview
                  Text(
                    'Product Image',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      await _pickImage();
                      setDialogState(() {});
                    },
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      child: _selectedImage != null
                          ? Stack(
                              children: [
                                Positioned.fill(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: kIsWeb
                                        ? Image.network(
                                            _selectedImage!.path,
                                            width: double.infinity,
                                            height: double.infinity,
                                            fit: BoxFit.cover,
                                          )
                                        : Image.file(
                                            File(_selectedImage!.path),
                                            width: double.infinity,
                                            height: double.infinity,
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: CircleAvatar(
                                    backgroundColor: Colors.red,
                                    child: IconButton(
                                      icon: Icon(Icons.close,
                                          color: Colors.white, size: 20),
                                      onPressed: () {
                                        setDialogState(() {
                                          _selectedImage = null;
                                          _uploadedImageUrl =
                                              productData['imageUrl'];
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : _uploadedImageUrl != null
                              ? Stack(
                                  children: [
                                    Positioned.fill(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          _uploadedImageUrl!,
                                          width: double.infinity,
                                          height: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Container(
                                              height: 150,
                                              color: Colors.grey[200],
                                              child: Icon(Icons.image,
                                                  size: 50,
                                                  color: Colors.grey[400]),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: CircleAvatar(
                                        backgroundColor: Colors.red,
                                        child: IconButton(
                                          icon: Icon(Icons.close,
                                              color: Colors.white, size: 20),
                                          onPressed: () {
                                            setDialogState(() {
                                              _uploadedImageUrl = null;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.cloud_upload_outlined,
                                        size: 60, color: Colors.grey[400]),
                                    SizedBox(height: 12),
                                    Text(
                                      'Click to upload new image',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'PNG, JPG up to 10MB',
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                    ),
                  ),
                  if (_isUploading)
                    Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.grey[200],
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.green[700]!),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isUploading ? null : () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _isUploading
                  ? null
                  : () async {
                      if (_productNameController.text.isEmpty ||
                          _productPriceController.text.isEmpty ||
                          _productQuantityController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Please fill all required fields'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      // Upload new image if selected
                      if (_selectedImage != null) {
                        String? imageUrl =
                            await _uploadToCloudinary(_selectedImage!);
                        if (imageUrl != null) {
                          _uploadedImageUrl = imageUrl;
                        } else {
                          // Failed to upload new image, stop update
                          return;
                        }
                      }

                      _updateProduct(productId, productData);
                      if (mounted) Navigator.pop(context);
                    },
              icon: Icon(Icons.save),
              label: Text('Save Changes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addProduct() async {
    try {
      double price = double.parse(_productPriceController.text);
      int quantity = int.parse(_productQuantityController.text);

      await _firestore.collection('products').add({
        'name': _productNameController.text,
        'price': price,
        'quantity': quantity,
        'category': _selectedCategory,
        'imageUrl': _uploadedImageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Product added successfully'),
              ],
            ),
            backgroundColor: Colors.green[700],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding product: $e')),
        );
      }
    }
  }

  Future<void> _updateProduct(
      String productId, Map<String, dynamic> productData) async {
    try {
      double price = double.parse(_productPriceController.text);
      int quantity = int.parse(_productQuantityController.text);

      await _firestore.collection('products').doc(productId).update({
        'name': _productNameController.text,
        'price': price,
        'quantity': quantity,
        'category': _selectedCategory,
        'imageUrl': _uploadedImageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Product updated successfully'),
              ],
            ),
            backgroundColor: Colors.blue[600],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating product: $e')),
        );
      }
    }
  }

  Future<void> _deleteProduct(String productId) async {
    final confirm = await _showConfirmDialog(
        'Delete Product', 'Are you sure you want to delete this product?');
    if (confirm == true) {
      try {
        await _firestore.collection('products').doc(productId).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Product deleted successfully'),
                ],
              ),
              backgroundColor: Colors.green[700],
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting product: $e')),
          );
        }
      }
    }
  }

  // User CRUD Operations
  Future<void> _deleteUser(String userId) async {
    final confirm = await _showConfirmDialog(
        'Delete User', 'Are you sure you want to delete this user?');
    if (confirm == true) {
      try {
        // Note: For full security, Firebase Auth deletion should be done via a Cloud Function
        await _firestore.collection('users').doc(userId).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('User deleted successfully'),
                ],
              ),
              backgroundColor: Colors.green[700],
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting user: $e')),
          );
        }
      }
    }
  }

  // Order CRUD Operations
  Future<void> _updateOrderStatus(String orderId, String status) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order status updated to $status')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating order: $e')),
        );
      }
    }
  }

  Future<bool?> _showConfirmDialog(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
