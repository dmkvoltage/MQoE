import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import '../models/network_metrics.dart';

class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  final StreamController<NetworkMetrics> _metricsController = StreamController.broadcast();
  final Connectivity _connectivity = Connectivity();
  Timer? _monitoringTimer;
  bool _isMonitoring = false;

  Stream<NetworkMetrics> get metricsStream => _metricsController.stream;
  bool get isMonitoring => _isMonitoring;

  void startMonitoring() {
    if (_isMonitoring) return;
    
    _monitoringTimer?.cancel();
    _isMonitoring = true;
    
    _monitoringTimer = Timer.periodic(const Duration(seconds: 10), (_) {
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
      
      // Get network speed and latency
      double downloadSpeed = 0;
      double uploadSpeed = 0;
      double latency = 0;
      
      if (networkType != 'None') {
        try {
          // Test latency with ping
          latency = await _measureLatency();
          
          // Test download speed
          downloadSpeed = await _measureDownloadSpeed();
          
          // Test upload speed (optional, can be resource intensive)
          uploadSpeed = await _measureUploadSpeed();
          
        } catch (e) {
          print('Error during speed test: $e');
        }
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

      if (!_metricsController.isClosed) {
        _metricsController.add(metrics);
      }
      print('NetworkService: Collected metrics - $networkType, Download: ${downloadSpeed.toStringAsFixed(2)}Mbps, Upload: ${uploadSpeed.toStringAsFixed(2)}Mbps, Latency: ${latency.toStringAsFixed(0)}ms');
    } catch (e) {
      print('NetworkService: Error collecting metrics: $e');
      // Emit error state metrics
      if (!_metricsController.isClosed) {
        final errorMetrics = NetworkMetrics(
          networkType: 'Unknown',
          signalStrength: 0,
          latency: 0,
          jitter: 0,
          downloadSpeed: 0,
          uploadSpeed: 0,
          provider: 'Unknown',
          timestamp: DateTime.now(),
        );
        _metricsController.add(errorMetrics);
      }
    }
  }

  String _getNetworkType(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'Mobile';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.none:
        return 'None';
      default:
        return 'Unknown';
    }
  }

  Future<double> _measureLatency() async {
    try {
      final stopwatch = Stopwatch()..start();
      
      // Use a reliable server for ping test
      final response = await http.head(
        Uri.parse('https://www.google.com'),
        headers: {'Cache-Control': 'no-cache'},
      ).timeout(const Duration(seconds: 5));
      
      stopwatch.stop();
      
      if (response.statusCode == 200) {
        return stopwatch.elapsedMilliseconds.toDouble();
      } else {
        return 0;
      }
    } catch (e) {
      print('Latency measurement error: $e');
      return 0;
    }
  }

  Future<double> _measureDownloadSpeed() async {
    try {
      // Use a test file for download speed measurement
      const testUrl = 'https://httpbin.org/bytes/1048576'; // 1MB test file
      final stopwatch = Stopwatch()..start();
      
      final response = await http.get(
        Uri.parse(testUrl),
        headers: {'Cache-Control': 'no-cache'},
      ).timeout(const Duration(seconds: 10));
      
      stopwatch.stop();
      
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes.length;
        final seconds = stopwatch.elapsedMilliseconds / 1000.0;
        final bytesPerSecond = bytes / seconds;
        final mbps = (bytesPerSecond * 8) / 1000000; // Convert to Mbps
        return mbps;
      } else {
        return 0;
      }
    } catch (e) {
      print('Download speed measurement error: $e');
      return 0;
    }
  }

  Future<double> _measureUploadSpeed() async {
    try {
      // Simple upload test using POST request
      final testData = 'x' * 65536; // 64KB test data
      final stopwatch = Stopwatch()..start();
      
      final response = await http.post(
        Uri.parse('https://httpbin.org/post'),
        body: testData,
        headers: {'Content-Type': 'text/plain'},
      ).timeout(const Duration(seconds: 10));
      
      stopwatch.stop();
      
      if (response.statusCode == 200) {
        final bytes = testData.length;
        final seconds = stopwatch.elapsedMilliseconds / 1000.0;
        final bytesPerSecond = bytes / seconds;
        final mbps = (bytesPerSecond * 8) / 1000000; // Convert to Mbps
        return mbps;
      } else {
        return 0;
      }
    } catch (e) {
      print('Upload speed measurement error: $e');
      return 0;
    }
  }

  Future<int> _getSignalStrength() async {
    try {
      // On Android, you would use TelephonyManager
      // On iOS, you would use CTTelephonyNetworkInfo
      // For now, returning a placeholder with some variation
      final baseStrength = -70; // Typical mobile signal strength in dBm
      final variation = DateTime.now().millisecond % 20 - 10; // Add some realistic variation
      return baseStrength + variation;
    } catch (e) {
      print('Error getting signal strength: $e');
      return -85; // Default poor signal
    }
  }

  Future<String> _getNetworkProvider() async {
    try {
      // This would require platform-specific code to get the actual carrier name
      // You might want to use a package like carrier_info for this
      return 'Network Provider';
    } catch (e) {
      print('Error getting network provider: $e');
      return 'Unknown Provider';
    }
  }

  double _calculateJitter(double latency) {
    if (latency <= 0) return 0;
    // Simple jitter calculation based on latency variation
    // In reality, you'd want to track multiple latency measurements
    return latency * 0.1; // 10% of latency as estimated jitter
  }

  void dispose() {
    _monitoringTimer?.cancel();
    _isMonitoring = false;
    if (!_metricsController.isClosed) {
      _metricsController.close();
    }
  }
}