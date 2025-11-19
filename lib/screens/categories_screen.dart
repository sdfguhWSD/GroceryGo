// ignore_for_file: prefer_const_constructors, use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Added for logout functionality
import 'category_screen.dart';

// Helper function to handle the logout logic
void _logout(BuildContext context) async {
  // Show a professional confirmation dialog before logging out
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      // Improved look: Title with icon a  nd consistent padding
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

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  final List<Map<String, dynamic>> categories = const [
    {
      "title": "Grocery",
      "imagePath": "assets/image/cat1.png",
      "color": Color(0xFFE3F2FD), // Light Blue
    },
    {
      "title": "Fruits",
      "imagePath": "assets/image/cat2.png",
      "color": Color(0xFFFFF3E0), // Light Orange
    },
    {
      "title": "Vegetables",
      "imagePath": "assets/image/cat3.png",
      "color": Color(0xFFE8F5E9), // Light Green
    },
    {
      "title": "Drinks",
      "imagePath": "assets/image/cat4.png",
      "color": Color(0xFFF3E5F5), // Light Purple
    },
    {
      "title": "Dairy & Eggs",
      "imagePath": "assets/image/cat5.png",
      "color": Color(0xFFFFFDE7), // Light Yellow
    },
    {
      "title": "Beauty",
      "imagePath": "assets/image/cat6.png",
      "color": Color(0xFFFCE4EC), // Light Pink
    },
    {
      "title": "Bakery",
      "imagePath": "assets/image/cat7.png",
      "color": Color(0xFFEFEBE9), // Light Brown
    },
    {
      "title": "Meat",
      "imagePath": "assets/image/cat8.png",
      "color": Color(0xFFFFEBEE), // Light Red
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Determine screen size for responsiveness
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate the number of columns based on screen width
        int crossAxisCount;
        if (constraints.maxWidth > 1200) {
          crossAxisCount = 6;
        } else if (constraints.maxWidth > 800) {
          crossAxisCount = 4;
        } else {
          // Mobile size default
          crossAxisCount = 2;
        }

        // Adjust padding based on screen size
        double horizontalPadding = constraints.maxWidth > 600 ? 32.0 : 16.0;

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: const Text('Shop by Category'),
            // 1. Title centered
            centerTitle: true,
            backgroundColor: Colors.green[800],
            foregroundColor: Colors.white,
            elevation: 4,
            shadowColor: Colors.black.withOpacity(0.2),
            // 2. Added logout icon matching home_screen.dart
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.logout_rounded,
                      color: Colors.white, size: 22),
                ),
                onPressed: () => _logout(context),
                tooltip: 'Logout',
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding, vertical: 24.0),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 20, // Increased spacing for better look
                mainAxisSpacing: 20,
                childAspectRatio:
                    0.9, // Slightly taller cards for better image/text fit
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                var category = categories[index];
                String categoryTitle = category['title'];
                String imagePath = category['imagePath'];
                Color categoryColor = category['color'] as Color;

                return CategoryCard(
                  categoryTitle: categoryTitle,
                  imagePath: imagePath,
                  categoryColor: categoryColor,
                );
              },
            ),
          ),
        );
      },
    );
  }
}

// Separate Widget for the Category Card to handle visual appeal
class CategoryCard extends StatelessWidget {
  final String categoryTitle;
  final String imagePath;
  final Color categoryColor;

  const CategoryCard({
    required this.categoryTitle,
    required this.imagePath,
    required this.categoryColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to CategoryScreen, passing the category title.
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryScreen(categoryTitle: categoryTitle),
          ),
        );
      },
      child: Card(
        // Use Card for elevation and shape consistency
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias, // Ensures internal content is clipped
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade100, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image container with colored background
              Expanded(
                flex: 3,
                child: Container(
                  color: categoryColor,
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Image.asset(
                      imagePath,
                      // Scale image size responsively within the fixed grid cell aspect ratio
                      height: 80,
                      width: 80,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              // Title text
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Text(
                      categoryTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[900],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
