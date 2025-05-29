import 'package:network_qoe_app/models/network_metrics.dart';

class FeedbackData {
  final String id;
  final int rating;
  final String? description;
  final String? issue;
  final NetworkMetrics metrics;
  final String location;
  final DateTime timestamp;

  FeedbackData({
    required this.id,
    required this.rating,
    this.description,
    this.issue,
    required this.metrics,
    required this.location,
    required this.timestamp,
  });
}