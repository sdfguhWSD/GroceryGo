import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'providers/cart_provider.dart';
import 'providers/order_provider.dart';
import 'screens/loadingscreen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/bottom_nav_screen.dart';
import 'screens/demo_screen.dart';
import 'screens/category_screen.dart';
import 'admin/admin_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase - MUST succeed before app runs
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const GroceryGo());
}

class GroceryGo extends StatelessWidget {
  const GroceryGo({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: MaterialApp(
        title: 'GroceryGo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.green,
          useMaterial3: true,
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        initialRoute: '/loading',
        routes: {
          '/loading': (context) => const GroceryGoLoadingScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/bottomNav': (context) => const BottomNavScreen(),
          '/demo': (context) => const DemoScreen(),
          '/admin': (context) => const AdminDashboardScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/category') {
            final categoryTitle = settings.arguments as String?;

            if (categoryTitle == null) {
              return MaterialPageRoute(
                builder: (context) => Scaffold(
                  appBar: AppBar(title: const Text('Error')),
                  body: const Center(
                    child: Text('Category not found'),
                  ),
                ),
              );
            }

            return MaterialPageRoute(
              builder: (context) =>
                  CategoryScreen(categoryTitle: categoryTitle),
            );
          }

          return null;
        },
        onUnknownRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      'Page not found',
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 8),
                    TextButton(
                      onPressed: () =>
                          Navigator.pushReplacementNamed(context, '/loading'),
                      child: Text('Go to Home'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
