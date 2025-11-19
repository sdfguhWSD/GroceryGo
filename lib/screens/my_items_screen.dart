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

  // Proceed with logout only if confirmed and context is still mounted
  if (confirmed == true && context.mounted) {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      // Navigate to the login screen after successful logout
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }
}

class MyItemsScreen extends StatelessWidget {
  const MyItemsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWeb = constraints.maxWidth > 600;
        final horizontalPadding = isWeb ? 32.0 : 16.0;

        // --- User Not Logged In Screen ---
        if (user == null) {
          return Scaffold(
            // Pass context to _buildAppBar
            appBar: _buildAppBar(context, 'My Orders', isWeb),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'Please log in to view your orders.',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your orders are protected and tied to your account.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          );
        }
        // ----------------------------------

        // --- Main Orders Screen ---
        return Scaffold(
          backgroundColor: Colors.grey[50],
          // Pass context to _buildAppBar
          appBar: _buildAppBar(context, 'My Orders', isWeb),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .where('userId', isEqualTo: user.uid)
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                    child: CircularProgressIndicator(color: Colors.green[700]));
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.redAccent),
                        const SizedBox(height: 16),
                        const Text(
                          'Error loading orders',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Details: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_bag_outlined,
                          size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      const Text(
                        'No orders yet.',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your orders will appear here after checkout.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                );
              }

              // The query already has orderBy('timestamp', descending: true)
              // which sorts the documents.
              final orders = snapshot.data!.docs;

              return ListView.builder(
                padding: EdgeInsets.fromLTRB(
                    horizontalPadding, 16, horizontalPadding, 16),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final orderDoc = orders[index];
                  final orderData = orderDoc.data() as Map<String, dynamic>;

                  // Extract order details
                  final orderId = orderDoc.id;
                  final items = orderData['items'] as List<dynamic>? ?? [];
                  // Ensure totalAmount is treated as a double
                  final totalAmount = (orderData['totalAmount'] is int
                          ? (orderData['totalAmount'] as int).toDouble()
                          : orderData['totalAmount'] as double?) ??
                      0.0;
                  final status = orderData['status'] ?? 'Pending';

                  // Get date
                  final timestamp = orderData['timestamp'] as Timestamp?;
                  final orderDate = timestamp?.toDate() ?? DateTime.now();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Center(
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: isWeb ? 800 : double.infinity,
                        ),
                        child: _buildOrderCard(
                          orderId,
                          items,
                          totalAmount,
                          status,
                          orderDate,
                          isWeb,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  // --- Widgets for UI Consistency and Responsiveness ---

  // Updated to accept BuildContext
  PreferredSizeWidget _buildAppBar(
      BuildContext context, String title, bool isWeb) {
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
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 22,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
      centerTitle: true,
      backgroundColor: Colors.green[800],
      elevation: 0,
      // FIX: Wrap BoxDecoration in a Container for flexibleSpace
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green[600]!, Colors.green[800]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      // Consistent spacing on web (original logic for `leading` kept)
      leading: isWeb ? const SizedBox(width: 50) : null,
      // Add logout action
      actions: [
        logoutAction,
        const SizedBox(width: 16), // Standard right padding for the icon
      ],
    );
  }

  Widget _buildOrderCard(
    String orderId,
    List<dynamic> items,
    double totalAmount,
    String status,
    DateTime orderDate,
    bool isWeb,
  ) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ExpansionTile(
        tilePadding:
            EdgeInsets.symmetric(horizontal: 20, vertical: isWeb ? 12 : 8),
        childrenPadding: const EdgeInsets.all(20),
        iconColor: Colors.green[700],
        collapsedIconColor: Colors.grey[600],
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${orderId.substring(0, 8).toUpperCase()}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: Colors.grey[900],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatDate(orderDate),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            _buildStatusChip(status),
          ],
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: isWeb ? 16.0 : 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${items.length} item${items.length != 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '₱${totalAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
        ),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Order Details',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const Divider(height: 24),
              // Order Items List
              ...items.map((item) {
                final itemMap = item as Map<String, dynamic>;
                final name = itemMap['name'] ?? 'Unknown Item';
                final quantity = itemMap['quantity'] ?? 1;
                final price = (itemMap['price'] is int
                        ? (itemMap['price'] as int).toDouble()
                        : itemMap['price'] as double?) ??
                    0.0;
                final itemTotal = price * quantity;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.check_box_outline_blank,
                          size: 16, color: Colors.green[700]),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Qty: $quantity • ₱${price.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '₱${itemTotal.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 8),

              // Total Amount Summary
              const Divider(height: 30, thickness: 1.5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Paid Amount',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    '₱${totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    String displayStatus = status.trim();

    switch (displayStatus.toLowerCase()) {
      case 'completed':
      case 'delivered':
        chipColor = Colors.green;
        break;
      case 'processing':
      case 'shipped':
        chipColor = Colors.blue;
        break;
      case 'cancelled':
        chipColor = Colors.red;
        break;
      default:
        chipColor = Colors.orange;
        displayStatus = 'Pending'; // Default to Pending if unknown
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: chipColor, width: 1.0),
      ),
      child: Text(
        displayStatus.toUpperCase(),
        style: TextStyle(
          color: chipColor,
          fontWeight: FontWeight.w800,
          fontSize: 11,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // --- Original Utility Functions (Kept Intact) ---

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year} at ${_formatTime(date)}';
  }

  String _formatTime(DateTime date) {
    final hour =
        date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
