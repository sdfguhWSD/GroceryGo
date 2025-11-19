import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

/// Root widget of the application
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GroceryGo Demo',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Roboto',
      ),
      routes: {
        '/': (context) => const DemoScreen(),
        '/tryOutNow': (context) => const TryOutNowScreen(),
      },
      initialRoute: '/',
    );
  }
}

/// Enhanced DemoScreen with responsive design and professional UI
class DemoScreen extends StatefulWidget {
  const DemoScreen({super.key});

  @override
  State<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int? _hoveredFeatureIndex;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWeb = constraints.maxWidth > 600;
        bool isLargeScreen = constraints.maxWidth > 900;
        double horizontalPadding = isWeb ? 40.0 : 20.0;
        double maxWidth = isLargeScreen ? 1200 : double.infinity;

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: _buildAppBar(context, isWeb),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              child: Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: isWeb ? 32 : 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Promotional Banner with Gradient
                      _buildPromoBanner(isWeb),

                      SizedBox(height: isWeb ? 48 : 32),

                      // Welcome Section
                      _buildWelcomeSection(isWeb),

                      SizedBox(height: isWeb ? 40 : 28),

                      // Features Grid
                      _buildFeaturesGrid(isWeb, isLargeScreen),

                      SizedBox(height: isWeb ? 48 : 32),

                      // Statistics Section
                      _buildStatsSection(isWeb),

                      SizedBox(height: isWeb ? 48 : 32),

                      // Call-to-Action Buttons
                      _buildActionButtons(context, isWeb),

                      SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isWeb) {
    return AppBar(
      automaticallyImplyLeading: false,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.shopping_cart_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
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

  Widget _buildPromoBanner(bool isWeb) {
    return Container(
      padding: EdgeInsets.all(isWeb ? 28 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[400]!, Colors.green[700]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.green[700]!.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
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
          Column(
            children: [
              Icon(
                Icons.local_offer_rounded,
                color: Colors.white,
                size: isWeb ? 48 : 40,
              ),
              const SizedBox(height: 12),
              Text(
                '50% CASHBACK',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isWeb ? 32 : 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.2),
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'ON YOUR FIRST GROCERY ORDER',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isWeb ? 16 : 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.95),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(bool isWeb) {
    return Column(
      children: [
        Text(
          'Welcome to GroceryGo!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isWeb ? 36 : 28,
            fontWeight: FontWeight.bold,
            color: Colors.grey[900],
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Your one-stop solution for fresh groceries delivered to your doorstep',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isWeb ? 18 : 16,
            color: Colors.grey[600],
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesGrid(bool isWeb, bool isLargeScreen) {
    final features = [
      {
        'icon': Icons.local_grocery_store_rounded,
        'title': 'Wide Range of Products',
        'description': '10,000+ products across all categories',
        'color': Colors.blue,
      },
      {
        'icon': Icons.payment_rounded,
        'title': 'Secure Payments',
        'description': 'Multiple payment options with bank-level security',
        'color': Colors.purple,
      },
      {
        'icon': Icons.local_offer_rounded,
        'title': 'Exclusive Discounts',
        'description': 'Daily deals and special member offers',
        'color': Colors.orange,
      },
      {
        'icon': Icons.delivery_dining_rounded,
        'title': 'Fast Delivery',
        'description': 'Same-day delivery available in your area',
        'color': Colors.teal,
      },
      {
        'icon': Icons.track_changes_rounded,
        'title': 'Real-Time Tracking',
        'description': 'Track your order from store to door',
        'color': Colors.indigo,
      },
      {
        'icon': Icons.support_agent_rounded,
        'title': '24/7 Support',
        'description': 'Always here to help you',
        'color': Colors.pink,
      },
    ];

    int crossAxisCount = isLargeScreen ? 3 : (isWeb ? 2 : 1);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: isWeb ? 20 : 16,
        crossAxisSpacing: isWeb ? 20 : 16,
        childAspectRatio: isWeb ? 1.6 : 2.8,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        bool isHovered = _hoveredFeatureIndex == index;

        return MouseRegion(
          onEnter: (_) => setState(() => _hoveredFeatureIndex = index),
          onExit: (_) => setState(() => _hoveredFeatureIndex = null),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            transform: Matrix4.identity()..scale(isHovered ? 1.03 : 1.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: isHovered
                      ? (feature['color'] as Color).withOpacity(0.3)
                      : Colors.grey.withOpacity(0.15),
                  blurRadius: isHovered ? 20 : 10,
                  offset: Offset(0, isHovered ? 8 : 4),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(isWeb ? 20 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (feature['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      feature['icon'] as IconData,
                      color: feature['color'] as Color,
                      size: isWeb ? 28 : 24,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    feature['title'] as String,
                    style: TextStyle(
                      fontSize: isWeb ? 17 : 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[900],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Flexible(
                    child: Text(
                      feature['description'] as String,
                      style: TextStyle(
                        fontSize: isWeb ? 13 : 12,
                        color: Colors.grey[600],
                        height: 1.3,
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
    );
  }

  Widget _buildStatsSection(bool isWeb) {
    final stats = [
      {'value': '50K+', 'label': 'Happy Customers'},
      {'value': '10K+', 'label': 'Products'},
      {'value': '4.8★', 'label': 'Average Rating'},
      {'value': '24/7', 'label': 'Support'},
    ];

    return Container(
      padding: EdgeInsets.all(isWeb ? 32 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Trusted by Thousands',
            style: TextStyle(
              fontSize: isWeb ? 24 : 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: isWeb ? 40 : 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: stats.map((stat) {
              return SizedBox(
                width: isWeb ? 150 : 140,
                child: Column(
                  children: [
                    Text(
                      stat['value']!,
                      style: TextStyle(
                        fontSize: isWeb ? 32 : 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stat['label']!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isWeb ? 14 : 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isWeb) {
    return SizedBox(
      width: double.infinity,
      height: isWeb ? 56 : 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[700],
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: () {
          Navigator.popUntil(
            context,
            ModalRoute.withName('/bottomNav'),
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Get Started',
              style: TextStyle(
                fontSize: isWeb ? 18 : 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Enhanced TryOutNowScreen with modern design
class TryOutNowScreen extends StatefulWidget {
  const TryOutNowScreen({super.key});

  @override
  State<TryOutNowScreen> createState() => _TryOutNowScreenState();
}

class _TryOutNowScreenState extends State<TryOutNowScreen> {
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWeb = constraints.maxWidth > 600;
        bool isLargeScreen = constraints.maxWidth > 900;
        double horizontalPadding = isWeb ? 40.0 : 20.0;
        double maxWidth = isLargeScreen ? 1200 : double.infinity;

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: _buildAppBar(context, isWeb),
          body: SingleChildScrollView(
            child: Center(
              child: Container(
                constraints: BoxConstraints(maxWidth: maxWidth),
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: isWeb ? 32 : 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Hero Banner
                    _buildHeroBanner(isWeb),

                    SizedBox(height: isWeb ? 40 : 28),

                    // Description
                    _buildDescription(isWeb),

                    SizedBox(height: isWeb ? 32 : 24),

                    // Features List
                    _buildFeaturesList(isWeb),

                    SizedBox(height: isWeb ? 40 : 32),

                    // Action Button
                    _buildBackButton(context, isWeb),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isWeb) {
    return AppBar(
      leading: IconButton(
        icon:
            const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Exclusive Features',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 22,
          color: Colors.white,
          letterSpacing: 0.5,
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
    );
  }

  Widget _buildHeroBanner(bool isWeb) {
    return Container(
      padding: EdgeInsets.all(isWeb ? 32 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange[400]!, Colors.deepOrange[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.stars_rounded,
            color: Colors.white,
            size: isWeb ? 56 : 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Explore Exclusive Features!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: isWeb ? 28 : 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Up to 50% Cashback, Personalized Deals, and More!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.95),
              fontSize: isWeb ? 16 : 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(bool isWeb) {
    return Text(
      'Discover all the amazing features designed to make your grocery shopping experience seamless, rewarding, and enjoyable.',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: isWeb ? 17 : 15,
        color: Colors.grey[700],
        height: 1.6,
      ),
    );
  }

  Widget _buildFeaturesList(bool isWeb) {
    final features = [
      {
        'icon': Icons.monetization_on_rounded,
        'title': 'Cashback Deals',
        'description':
            'Enjoy up to 50% cashback on select grocery items. Your cashback is automatically applied at checkout, making savings effortless. Track your earnings in real-time.',
        'color': Colors.amber,
      },
      {
        'icon': Icons.star_rounded,
        'title': 'Loyalty Program',
        'description':
            'Subscribe for exclusive deals and accumulate loyalty points with every purchase. Redeem points for discounts on future orders and unlock VIP perks.',
        'color': Colors.purple,
      },
      {
        'icon': Icons.flash_on_rounded,
        'title': 'Flash Sales',
        'description':
            'Don\'t miss our time-limited flash sales! Enjoy deep discounts with countdown timers. Set alerts to never miss a deal on your favorite products.',
        'color': Colors.red,
      },
      {
        'icon': Icons.person_pin_circle_rounded,
        'title': 'Personalized Suggestions',
        'description':
            'Get AI-powered recommendations based on your shopping history, dietary preferences, and seasonal trends. Discover new products tailored just for you.',
        'color': Colors.blue,
      },
      {
        'icon': Icons.card_giftcard_rounded,
        'title': 'First-Time Bonus',
        'description':
            'New to GroceryGo? Claim a special welcome discount on your first order. Plus, get free delivery on your initial purchase. Welcome to the family!',
        'color': Colors.pink,
      },
      {
        'icon': Icons.account_balance_wallet_rounded,
        'title': 'Cashback Wallet',
        'description':
            'Track and manage all your accumulated cashback in one convenient wallet. Redeem anytime or save for bigger discounts. No expiration dates!',
        'color': Colors.teal,
      },
    ];

    return Column(
      children: features.asMap().entries.map((entry) {
        int index = entry.key;
        Map<String, dynamic> feature = entry.value;
        bool isExpanded = _expandedIndex == index;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: isExpanded
                    ? (feature['color'] as Color).withOpacity(0.2)
                    : Colors.grey.withOpacity(0.12),
                blurRadius: isExpanded ? 16 : 8,
                offset: Offset(0, isExpanded ? 6 : 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                setState(() {
                  _expandedIndex = isExpanded ? null : index;
                });
              },
              child: Padding(
                padding: EdgeInsets.all(isWeb ? 20 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (feature['color'] as Color).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            feature['icon'] as IconData,
                            color: feature['color'] as Color,
                            size: isWeb ? 28 : 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            feature['title'] as String,
                            style: TextStyle(
                              fontSize: isWeb ? 18 : 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[900],
                            ),
                          ),
                        ),
                        Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: Colors.grey[600],
                          size: 28,
                        ),
                      ],
                    ),
                    AnimatedCrossFade(
                      firstChild: const SizedBox(),
                      secondChild: Padding(
                        padding: const EdgeInsets.only(top: 16, left: 56),
                        child: Text(
                          feature['description'] as String,
                          style: TextStyle(
                            fontSize: isWeb ? 15 : 14,
                            color: Colors.grey[700],
                            height: 1.6,
                          ),
                        ),
                      ),
                      crossFadeState: isExpanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 300),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBackButton(BuildContext context, bool isWeb) {
    return SizedBox(
      width: double.infinity,
      height: isWeb ? 56 : 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[700],
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: () => Navigator.pop(context),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.arrow_back_rounded, size: 20),
            const SizedBox(width: 8),
            Text(
              'Back to Demo',
              style: TextStyle(
                fontSize: isWeb ? 18 : 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
