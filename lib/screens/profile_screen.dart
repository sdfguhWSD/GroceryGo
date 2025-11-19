// ignore_for_file: prefer_const_constructors, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Helper function to handle the logout logic
void _logout(BuildContext context) async {
  // Show a professional confirmation dialog before logging out
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      // Improved look: Title with icon and consistent padding
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.deepOrange, size: 28),
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

  // Only proceed with original logout logic if confirmed and context is still mounted
  if (confirmed == true && context.mounted) {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      // Navigate to the login screen after successful logout
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final String? userId = FirebaseAuth.instance.currentUser?.uid;
  final String? userEmail = FirebaseAuth.instance.currentUser?.email;

  Map<String, dynamic>? userData;
  List<Map<String, dynamic>> addresses = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadAddresses();
  }

  Future<void> _loadUserData() async {
    if (userId == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        setState(() {
          userData = doc.data();
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadAddresses() async {
    if (userId == null) return;

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('addresses')
          .where('userId', isEqualTo: userId)
          .get();

      setState(() {
        addresses = querySnapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();
      });
    } catch (e) {
      print('Error loading addresses: $e');
    }
  }

  String _getInitials(String? email) {
    if (email == null || email.isEmpty) return '?';
    return email[0].toUpperCase();
  }

  void _showAddAddressDialog() {
    final formKey = GlobalKey<FormState>();
    final streetController = TextEditingController();
    final cityController = TextEditingController();
    final provinceController = TextEditingController();
    final zipController = TextEditingController();
    final labelController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isWeb = MediaQuery.of(context).size.width > 600;
            return Container(
              width: isWeb ? 500 : double.infinity,
              padding: EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.add_location_alt,
                                color: Colors.green[700], size: 24),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Add New Address',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[900],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24),
                      _buildTextField(
                        controller: labelController,
                        label: 'Address Label',
                        hint: 'e.g., Home, Office',
                        icon: Icons.label_outline,
                      ),
                      SizedBox(height: 16),
                      _buildTextField(
                        controller: phoneController,
                        label: 'Phone Number',
                        hint: 'e.g., +63 912 345 6789',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      SizedBox(height: 16),
                      _buildTextField(
                        controller: streetController,
                        label: 'Street Address',
                        hint: 'House/Unit No., Street Name',
                        icon: Icons.home_outlined,
                      ),
                      SizedBox(height: 16),
                      _buildTextField(
                        controller: cityController,
                        label: 'City',
                        hint: 'Enter city',
                        icon: Icons.location_city_outlined,
                      ),
                      SizedBox(height: 16),
                      _buildTextField(
                        controller: provinceController,
                        label: 'Province',
                        hint: 'Enter province',
                        icon: Icons.map_outlined,
                      ),
                      SizedBox(height: 16),
                      _buildTextField(
                        controller: zipController,
                        label: 'Zip Code',
                        hint: 'Enter zip code',
                        icon: Icons.pin_outlined,
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                side: BorderSide(color: Colors.grey[300]!),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (formKey.currentState!.validate()) {
                                  await _addAddress(
                                    label: labelController.text,
                                    phone: phoneController.text,
                                    street: streetController.text,
                                    city: cityController.text,
                                    province: provinceController.text,
                                    zip: zipController.text,
                                  );
                                  Navigator.pop(context);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[700],
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'Add Address',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.green[700]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green[700]!, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'This field is required';
        }
        return null;
      },
    );
  }

  Future<void> _addAddress({
    required String label,
    required String phone,
    required String street,
    required String city,
    required String province,
    required String zip,
  }) async {
    if (userId == null) return;

    try {
      await FirebaseFirestore.instance.collection('addresses').add({
        'userId': userId,
        'label': label,
        'phone': phone,
        'street': street,
        'city': city,
        'province': province,
        'zipCode': zip,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _loadAddresses();
      _showSnackbar('Address added successfully!', Colors.green);
    } catch (e) {
      _showSnackbar('Failed to add address: $e', Colors.red);
    }
  }

  Future<void> _deleteAddress(String addressId) async {
    try {
      await FirebaseFirestore.instance
          .collection('addresses')
          .doc(addressId)
          .delete();

      _loadAddresses();
      _showSnackbar('Address deleted successfully!', Colors.green);
    } catch (e) {
      _showSnackbar('Failed to delete address: $e', Colors.red);
    }
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWeb = constraints.maxWidth > 600;
        double horizontalPadding = isWeb ? 32.0 : 16.0;

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: _buildAppBar(context, isWeb), // Pass context here
          body: isLoading
              ? Center(
                  child: CircularProgressIndicator(color: Colors.green[700]),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: Column(
                      children: [
                        SizedBox(height: 24),
                        _buildProfileCard(isWeb),
                        SizedBox(height: 24),
                        _buildInfoSection(isWeb),
                        SizedBox(height: 24),
                        _buildAddressSection(isWeb),
                        SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  // Updated to accept BuildContext
  PreferredSizeWidget _buildAppBar(BuildContext context, bool isWeb) {
    // New Logout Action button
    final logoutAction = IconButton(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.logout_rounded, color: Colors.white, size: 22),
      ),
      onPressed: () => _logout(context), // Call the new logout function
      tooltip: 'Logout',
    );

    return AppBar(
      title: Text(
        'My Profile',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
      backgroundColor: Colors.green[800],
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green[600]!, Colors.green[800]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      // Add logout action
      actions: [
        logoutAction,
        const SizedBox(width: 16), // Standard right padding for the icon
      ],
    );
  }

  Widget _buildProfileCard(bool isWeb) {
    String initials = _getInitials(userEmail);
    String displayName =
        userData?['fullName'] ?? userEmail?.split('@')[0] ?? 'User';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[600]!, Colors.green[800]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green[700]!.withOpacity(0.3),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: isWeb ? 100 : 80,
            height: isWeb ? 100 : 80,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initials,
                style: TextStyle(
                  fontSize: isWeb ? 40 : 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ),
          ),
          SizedBox(height: 16),
          Text(
            displayName,
            style: TextStyle(
              fontSize: isWeb ? 24 : 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 4),
          Text(
            userEmail ?? '',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(bool isWeb) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Information',
            style: TextStyle(
              fontSize: isWeb ? 20 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
          ),
          SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: userData?['email'] ?? userEmail ?? 'N/A',
          ),
          SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.person_outline,
            label: 'Full Name',
            value: userData?['fullName'] ?? 'Not provided',
          ),
          SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.admin_panel_settings_outlined,
            label: 'Role',
            value: userData?['role'] ?? 'User',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.green[700], size: 20),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddressSection(bool isWeb) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Delivery Addresses',
                style: TextStyle(
                  fontSize: isWeb ? 20 : 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showAddAddressDialog,
                icon: Icon(Icons.add, size: 18),
                label: Text('Add'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          addresses.isEmpty
              ? _buildEmptyAddressState()
              : ListView.separated(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: addresses.length,
                  separatorBuilder: (context, index) => SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final address = addresses[index];
                    return _buildAddressCard(address, isWeb);
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildEmptyAddressState() {
    return Container(
      padding: EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.location_off_outlined, size: 64, color: Colors.grey[300]),
          SizedBox(height: 16),
          Text(
            'No addresses added yet',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Add your delivery address to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(Map<String, dynamic> address, bool isWeb) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[100]!),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.location_on, color: Colors.green[700], size: 24),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  address['label'] ?? 'Address',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${address['street']}, ${address['city']}, ${address['province']} ${address['zipCode']}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.red[400]),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Text('Delete Address'),
                  content:
                      Text('Are you sure you want to delete this address?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel',
                          style: TextStyle(color: Colors.grey[700])),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteAddress(address['id']);
                      },
                      child: Text('Delete',
                          style: TextStyle(color: Colors.red[600])),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
