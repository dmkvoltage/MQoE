import 'dart:async';
import 'dart:math';

import '../models/network_metrics.dart';

class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  final StreamController<NetworkMetrics> _metricsController = StreamController.broadcast();
  Timer? _monitoringTimer;

  Stream<NetworkMetrics> get metricsStream => _metricsController.stream;

  void startMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = Timer.periodic(Duration(seconds: 10), (_) {
      collectMetrics();
    });
  }

  void stopMonitoring() {
    _monitoringTimer?.cancel();
  }

  void collectMetrics() {
    // Simulate network metrics collection
    final metrics = NetworkMetrics(
      networkType: '4G',
      signalStrength: -60 + Random().nextInt(40),
      latency: 20 + Random().nextDouble() * 80,
      jitter: Random().nextDouble() * 10,
      downloadSpeed: 10 + Random().nextDouble() * 90,
      uploadSpeed: 5 + Random().nextDouble() * 45,
      provider: 'Carrier Network',
      timestamp: DateTime.now(),
    );
    
    _metricsController.add(metrics);
  }

  Future<Map<String, double>> performSpeedTest() async {
    // Simulate speed test
    await Future.delayed(Duration(seconds: 3));
    return {
      'download': 50 + Random().nextDouble() * 50,
      'upload': 20 + Random().nextDouble() * 30,
      'ping': 20 + Random().nextDouble() * 60,
    };
  }

  void dispose() {
    _metricsController.close();
    _monitoringTimer?.cancel();
  }


}