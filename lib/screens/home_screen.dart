import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dashboard_screen.dart';
import 'feedback_screen.dart';
import 'speed_test_screen.dart';
import 'rewards_screen.dart';
import 'settings_screen.dart';
import '../widgets/navigation_bar.dart';
import '../services/network_service.dart';
import '../models/network_metrics.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  final NetworkService _networkService = NetworkService();
  NetworkMetrics? currentMetrics;

  late AnimationController _pulseController;
  late AnimationController _rotationController;

  final List<Widget> _screens = [
    HomePage(),
    DashboardScreen(),
    FeedbackScreen(),
    SpeedTestScreen(),
    RewardsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _networkService.startMonitoring();
    _networkService.metricsStream.listen((metrics) {
      setState(() {
        currentMetrics = metrics;
      });
    });
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      duration: Duration(seconds: 10),
      vsync: this,
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: CustomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _networkService.stopMonitoring();
    super.dispose();
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late AnimationController _waveController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _waveController = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.bounceOut));

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _waveAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.linear),
    );
  }

  void _startAnimations() {
    Future.delayed(Duration(milliseconds: 100), () => _fadeController.forward());
    Future.delayed(Duration(milliseconds: 300), () => _slideController.forward());
    Future.delayed(Duration(milliseconds: 500), () => _scaleController.forward());
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F0F23),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F0F23),
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0E3460),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAppBar(),
                    SizedBox(height: 40),
                    _buildHeroSection(),
                    SizedBox(height: 40),
                    _buildNetworkStatusCard(),
                    SizedBox(height: 32),
                    _buildStatsGrid(),
                    SizedBox(height: 32),
                    _buildQuickActions(),
                    SizedBox(height: 32),
                    _buildInsightsCard(),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SlideTransition(
      position: _slideAnimation,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good Morning 👋',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              Text(
                'Network Monitor',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SettingsScreen()),
            ),
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFF6C63FF).withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Color(0xFF6C63FF).withOpacity(0.3),
                ),
              ),
              child: Icon(
                Icons.settings,
                color: Color(0xFF6C63FF),
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF6C63FF),
              Color(0xFF9F7AEA),
              Color(0xFF4F46E5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF6C63FF).withOpacity(0.4),
              blurRadius: 30,
              offset: Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                ),
                AnimatedBuilder(
                  animation: _waveAnimation,
                  builder: (context, child) {
                    return CustomPaint(
                      size: Size(120, 120),
                      painter: WavePainter(_waveAnimation.value),
                    );
                  },
                ),
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.network_check,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            Text(
              'Network Monitoring',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Know Your Network. Improve Your Experience.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkStatusCard() {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Color(0xFF1E1E3F).withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Color(0xFF6C63FF).withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.signal_cellular_4_bar,
                        color: Colors.green,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Network Status',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green, Colors.teal],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Excellent',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatusItem(
                    'Provider',
                    'Carrier Network',
                    Icons.business,
                    Color(0xFF6C63FF),
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey.withOpacity(0.3),
                ),
                Expanded(
                  child: _buildStatusItem(
                    'Type',
                    '5G',
                    Icons.network_cell,
                    Color(0xFF9F7AEA),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = [
      {'title': 'Download', 'value': '45.2', 'unit': 'Mbps', 'icon': Icons.download, 'color': Color(0xFF00D4AA)},
      {'title': 'Upload', 'value': '12.8', 'unit': 'Mbps', 'icon': Icons.upload, 'color': Color(0xFF6C63FF)},
      {'title': 'Latency', 'value': '28', 'unit': 'ms', 'icon': Icons.timer, 'color': Color(0xFFFF6B6B)},
      {'title': 'Jitter', 'value': '2.1', 'unit': 'ms', 'icon': Icons.graphic_eq, 'color': Color(0xFFFFB84D)},
    ];

    return SlideTransition(
      position: _slideAnimation,
      child: GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.3,
        ),
        itemCount: stats.length,
        itemBuilder: (context, index) {
          final stat = stats[index];
          return Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFF1E1E3F).withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: (stat['color'] as Color).withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (stat['color'] as Color).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        stat['icon'] as IconData,
                        color: stat['color'] as Color,
                        size: 20,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Good',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                Spacer(),
                Text(
                  stat['title'] as String,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      stat['value'] as String,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 4),
                    Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Text(
                        stat['unit'] as String,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

Widget _buildQuickActions() {
  return SlideTransition(
    position: _slideAnimation,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Give Feedback',
                Icons.feedback,
                LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF9F7AEA)]),
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => FeedbackScreen()),
                  );
                },
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildActionButton(
                'Speed Test',
                Icons.speed,
                LinearGradient(colors: [Color(0xFF00D4AA), Color(0xFF0099CC)]),
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SpeedTestScreen()),
                  );
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'View Reports',
                Icons.analytics,
                LinearGradient(colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)]),
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DashboardScreen()),
                  );
                },
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildActionButton(
                'Rewards',
                Icons.card_giftcard,
                LinearGradient(colors: [Color(0xFFFFB84D), Color(0xFFFFD93D)]),
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RewardsScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

  Widget _buildActionButton(String title, IconData icon, Gradient gradient, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsCard() {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Color(0xFF1E1E3F).withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Color(0xFF6C63FF).withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF00D4AA).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.lightbulb,
                    color: Color(0xFF00D4AA),
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Network Insights',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.trending_up, color: Colors.green, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your network performance is 23% better than average in your area.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  final double animation;

  WavePainter(this.animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 4;

    for (int i = 0; i < 3; i++) {
      final currentRadius = radius + (i * 10) + (animation * 20);
      canvas.drawCircle(center, currentRadius, paint);
    }
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) => oldDelegate.animation != animation;
}