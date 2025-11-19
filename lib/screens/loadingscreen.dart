import 'package:flutter/material.dart';
import 'dart:async';

// GroceryGo Loading Screen
class GroceryGoLoadingScreen extends StatefulWidget {
  const GroceryGoLoadingScreen({Key? key}) : super(key: key);

  @override
  State<GroceryGoLoadingScreen> createState() => _GroceryGoLoadingScreenState();
}

class _GroceryGoLoadingScreenState extends State<GroceryGoLoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _dotsController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Fade animation for logo
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    // Scale animation for logo
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Dots animation (continuous loop)
    _dotsController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat();

    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _fadeController.forward();
    _scaleController.forward();

    // Wait for 3 seconds then fade out
    await Future.delayed(const Duration(milliseconds: 3000));

    if (mounted) {
      // Fade out animation before navigation
      await _fadeController.reverse();

      // Navigate with smooth fade transition
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWeb = size.width > 600;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF4CAF50), // Green
              const Color(0xFF66BB6A),
              const Color(0xFF81C784),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Animated Logo and Title
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      children: [
                        // Shopping Cart Icon
                        Container(
                          padding: EdgeInsets.all(isWeb ? 32 : 24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.shopping_cart_rounded,
                            size: isWeb ? 80 : 60,
                            color: const Color(0xFF4CAF50),
                          ),
                        ),

                        SizedBox(height: isWeb ? 32 : 24),

                        // App Title
                        Text(
                          'GroceryGo',
                          style: TextStyle(
                            fontSize: isWeb ? 48 : 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.3),
                                offset: const Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: isWeb ? 12 : 8),

                        // Tagline
                        Text(
                          'Your Smart Shopping Companion',
                          style: TextStyle(
                            fontSize: isWeb ? 18 : 14,
                            color: Colors.white.withOpacity(0.9),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                // Animated Loading Dots (Facebook style)
                _buildLoadingDots(),

                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _dotsController,
          builder: (context, child) {
            // Calculate delay for each dot
            final delay = index * 0.2;

            // Create bounce animation for each dot
            final adjustedValue = (_dotsController.value - delay) % 1.0;

            // Scale factor for bounce effect
            double scale = 1.0;
            if (adjustedValue < 0.5) {
              scale = 1.0 + (adjustedValue * 0.8); // Bounce up
            } else {
              scale = 1.4 - ((adjustedValue - 0.5) * 0.8); // Bounce down
            }

            return Transform.translate(
              offset: Offset(0, -10 * (scale - 1.0)),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
