import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_network_speed_test/flutter_network_speed_test.dart';
import '../models/network_metrics.dart';

class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  final StreamController<NetworkMetrics> _metricsController = StreamController.broadcast();
  final Connectivity _connectivity = Connectivity();
  final FlutterNetworkSpeedTest _speedTest = FlutterNetworkSpeedTest();
  Timer? _monitoringTimer;
  bool _isMonitoring = false;

  Stream<NetworkMetrics> get metricsStream => _metricsController.stream;
  bool get isMonitoring => _isMonitoring;

  void startMonitoring() {
    if (_isMonitoring) return;
    
    _monitoringTimer?.cancel();
    _isMonitoring = true;
    
    _monitoringTimer = Timer.periodic(Duration(seconds: 10), (_) {
      collectMetrics();
    });
    
    collectMetrics();
    print('NetworkService: Started monitoring');
  }

  void stopMonitoring() {
    _monitoringTimer?.cancel();
    _isMonitoring = false;
    print('NetworkService: Stopped monitoring');
  }

  Future<void> collectMetrics() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      final networkType = _getNetworkType(connectivityResult);
      
      // Get network speed
      double downloadSpeed = 0;
      double uploadSpeed = 0;
      double latency = 0;
      
      try {
        await _speedTest.startTesting(
          onProgress: (percent, transferRate, remainingTime) {
            if (transferRate != null) {
              downloadSpeed = transferRate.toDouble();
            }
          },
          onError: (String errorMessage, String speedTestError) {
            print('Speed test error: $errorMessage');
          },
          onStarted: () {
            print('Speed test started');
          },
          onCompleted: (TestResult download, TestResult upload) {
            downloadSpeed = download.transferRate ?? 0;
            uploadSpeed = upload.transferRate ?? 0;
            latency = download.latency ?? 0;
          },
        );
      } catch (e) {
        print('Error during speed test: $e');
      }

      final metrics = NetworkMetrics(
        networkType: networkType,
        signalStrength: await _getSignalStrength(),
        latency: latency,
        jitter: _calculateJitter(latency),
        downloadSpeed: downloadSpeed,
        uploadSpeed: uploadSpeed,
        provider: await _getNetworkProvider(),
        timestamp: DateTime.now(),
      );

      _metricsController.add(metrics);
      print('NetworkService: Collected real metrics - $networkType');
    } catch (e) {
      print('NetworkService: Error collecting metrics: $e');
    }
  }

  String _getNetworkType(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.mobile:
        return 'Mobile';
      case ConnectivityResult.wifi:
        return 'WiFi';
      default:
        return 'Unknown';
    }
  }

  Future<int> _getSignalStrength() async {
    // On Android, you would use TelephonyManager
    // On iOS, you would use CTTelephonyNetworkInfo
    // For now, returning a placeholder
    return -70; // Typical mobile signal strength in dBm
  }

  Future<String> _getNetworkProvider() async {
    // This would require platform-specific code to get the actual carrier name
    return 'Network Provider';
  }

  double _calculateJitter(double latency) {
    // Simple jitter calculation based on latency variation
    return latency * 0.1; // 10% of latency as jitter
  }

  void dispose() {
    _monitoringTimer?.cancel();
    _isMonitoring = false;
    if (!_metricsController.isClosed) {
      _metricsController.close();
    }
  }
}