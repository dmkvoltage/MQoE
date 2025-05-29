import '../models/feedback.dart';
import '../models/user_data.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  UserData? _userData;

  UserData get userData => _userData ?? UserData(
    id: 'user_001',
    feedbackHistory: [],
    lastSync: DateTime.now(),
  );

  Future<void> saveFeedback(FeedbackData feedback) async {
    // Simulate saving feedback
    await Future.delayed(Duration(milliseconds: 500));
    _userData ??= userData;
    _userData!.feedbackHistory.add(feedback);
    _userData!.addPoints(10); // 10 points for feedback
  }

  Future<void> syncData() async {
    await Future.delayed(Duration(seconds: 2));
    _userData ??= userData;
    // Simulate sync
  }
}