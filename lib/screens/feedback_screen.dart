//feedback_screen.dart
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/location_service.dart';
import '../models/feedback.dart';
import '../models/network_metrics.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  _FeedbackScreenState createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen>
    with TickerProviderStateMixin {
  final TextEditingController _descriptionController = TextEditingController();
  int _rating = 0;
  String? _selectedIssue;
  bool _isSubmitting = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _submitController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _submitAnimation;

  final List<Map<String, dynamic>> _issues = [
    {'title': 'Slow Internet Speed', 'icon': Icons.speed, 'color': Colors.orange},
    {'title': 'Connection Drops', 'icon': Icons.signal_wifi_off, 'color': Colors.red},
    {'title': 'High Latency', 'icon': Icons.timer, 'color': Colors.amber},
    {'title': 'Poor Call Quality', 'icon': Icons.call_end, 'color': Colors.deepOrange},
    {'title': 'No Signal', 'icon': Icons.signal_cellular_off, 'color': Colors.grey},
    {'title': 'Other', 'icon': Icons.help_outline, 'color': Colors.blue},
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    
    _submitController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.elasticOut));

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.bounceOut),
    );
    
    _submitAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _submitController, curve: Curves.easeInOut),
    );
  }

  void _startAnimations() {
    Future.delayed(Duration(milliseconds: 100), () {
      _fadeController.forward();
    });
    Future.delayed(Duration(milliseconds: 200), () {
      _slideController.forward();
    });
    Future.delayed(Duration(milliseconds: 400), () {
      _scaleController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _submitController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F0F23),
      appBar: _buildAppBar(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F0F23),
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
            ],
          ),
        ),
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.all(20),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  SizedBox(height: 32),
                  _buildRatingSection(),
                  SizedBox(height: 32),
                  _buildIssueSection(),
                  SizedBox(height: 24),
                  _buildDescriptionSection(),
                  SizedBox(height: 32),
                  _buildInfoCard(),
                  SizedBox(height: 32),
                  _buildSubmitButton(),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFF6C63FF).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.feedback, color: Color(0xFF6C63FF), size: 24),
          ),
          SizedBox(width: 12),
          Text(
            'Share Your Experience',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF9F7AEA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF6C63FF).withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'We Value Your Feedback',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Help us improve your network experience',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.star, color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Color(0xFF1E1E3F).withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Color(0xFF6C63FF).withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              'Rate Your Experience',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                bool isSelected = index < _rating;
                return GestureDetector(
                  onTap: () => _animateRating(index + 1),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? Color(0xFF6C63FF).withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isSelected ? Icons.star : Icons.star_border,
                      color: isSelected ? Color(0xFFFFD700) : Colors.grey,
                      size: 36,
                    ),
                  ),
                );
              }),
            ),
            if (_rating > 0)
              Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  _getRatingText(_rating),
                  style: TextStyle(
                    color: Color(0xFF6C63FF),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIssueSection() {
    return Container(
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
              Icon(Icons.warning_amber, color: Color(0xFF6C63FF), size: 20),
              SizedBox(width: 8),
              Text(
                'What went wrong?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Spacer(),
              Text(
                'Optional',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 3,
            ),
            itemCount: _issues.length,
            itemBuilder: (context, index) {
              final issue = _issues[index];
              bool isSelected = _selectedIssue == issue['title'];
              
              return GestureDetector(
                onTap: () => _selectIssue(issue['title']),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? issue['color'].withOpacity(0.2)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected 
                          ? issue['color']
                          : Colors.grey.withOpacity(0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        issue['icon'],
                        color: isSelected ? issue['color'] : Colors.grey,
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          issue['title'],
                          style: TextStyle(
                            color: isSelected ? issue['color'] : Colors.grey,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Container(
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
              Icon(Icons.edit_note, color: Color(0xFF6C63FF), size: 20),
              SizedBox(width: 8),
              Text(
                'Tell us more',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Spacer(),
              Text(
                'Optional',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            style: TextStyle(color: Colors.white),
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Describe your experience in detail...',
              hintStyle: TextStyle(color: Colors.grey),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xFF6C63FF), width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF1E1E3F).withOpacity(0.8),
            Color(0xFF2D2D5F).withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xFF6C63FF).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF6C63FF), size: 20),
              SizedBox(width: 8),
              Text(
                'System Information',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Auto-detected',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ..._buildInfoItems(),
        ],
      ),
    );
  }

  List<Widget> _buildInfoItems() {
    final items = [
      {'icon': Icons.access_time, 'label': 'Timestamp', 'value': DateTime.now().toString().substring(0, 19)},
      {'icon': Icons.location_on, 'label': 'Location', 'value': 'Current Location, City'},
      {'icon': Icons.network_cell, 'label': 'Provider', 'value': 'Carrier Network'},
      {'icon': Icons.signal_cellular_4_bar, 'label': 'Network Type', 'value': '4G'},
    ];

    return items.map((item) => Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFF6C63FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              item['icon'] as IconData,
              color: Color(0xFF6C63FF),
              size: 16,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['label'] as String,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                Text(
                  item['value'] as String,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )).toList();
  }

  Widget _buildSubmitButton() {
    return ScaleTransition(
      scale: _submitAnimation,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: _rating > 0 && !_isSubmitting
              ? LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF9F7AEA)],
                )
              : LinearGradient(
                  colors: [Colors.grey.withOpacity(0.3), Colors.grey.withOpacity(0.3)],
                ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: _rating > 0 && !_isSubmitting
              ? [
                  BoxShadow(
                    color: Color(0xFF6C63FF).withOpacity(0.4),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ]
              : [],
        ),
        child: ElevatedButton(
          onPressed: _rating > 0 && !_isSubmitting ? _submitFeedback : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isSubmitting
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Submitting...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Submit Feedback',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  void _animateRating(int rating) {
    setState(() => _rating = rating);
    _scaleController.reset();
    _scaleController.forward();
  }

  void _selectIssue(String issue) {
    setState(() {
      _selectedIssue = _selectedIssue == issue ? null : issue;
    });
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1: return 'Poor - We\'ll work on it';
      case 2: return 'Fair - Room for improvement';
      case 3: return 'Good - Thanks for the feedback';
      case 4: return 'Very Good - Great to hear!';
      case 5: return 'Excellent - You made our day!';
      default: return '';
    }
  }

  void _submitFeedback() async {
    _submitController.forward().then((_) {
      _submitController.reverse();
    });
    
    setState(() => _isSubmitting = true);

    try {
      final location = await LocationService().getCurrentLocation();
      final metrics = NetworkMetrics(
        networkType: '4G',
        signalStrength: -60,
        latency: 45.0,
        jitter: 2.5,
        downloadSpeed: 25.0,
        uploadSpeed: 12.0,
        provider: 'Carrier Network',
        timestamp: DateTime.now(),
      );

      final feedback = FeedbackData(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        rating: _rating,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        issue: _selectedIssue,
        metrics: metrics,
        location: location,
        timestamp: DateTime.now(),
      );

      await StorageService().saveFeedback(feedback);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Thank you for your feedback! You earned 10 points.',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.all(16),
        ),
      );

      _descriptionController.clear();
      setState(() {
        _rating = 0;
        _selectedIssue = null;
      });

      // Restart animations for reset state
      _startAnimations();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Failed to submit feedback. Please try again.',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.all(16),
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }
}