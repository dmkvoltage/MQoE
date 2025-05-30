import 'dart:async';
import 'dart:math';
import '../models/network_metrics.dart';

class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  final StreamController<NetworkMetrics> _metricsController = StreamController.broadcast();
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
    
    // Collect initial metrics immediately
    collectMetrics();
    print('NetworkService: Started monitoring');
  }

  void stopMonitoring() {
    _monitoringTimer?.cancel();
    _isMonitoring = false;
    print('NetworkService: Stopped monitoring');
  }

  void collectMetrics() {
    try {
      final metrics = _generateRealisticMetrics();
      _metricsController.add(metrics);
      print('NetworkService: Generated metrics - ${metrics.networkType}, Signal: ${metrics.signalStrength}dBm');
    } catch (e) {
      print('NetworkService: Error collecting metrics: $e');
      // Add error metrics to keep stream alive
      final errorMetrics = NetworkMetrics(
        networkType: 'Error',
        signalStrength: -999,
        latency: 0.0,
        jitter: 0.0,
        downloadSpeed: 0.0,
        uploadSpeed: 0.0,
        provider: 'Collection Error',
        timestamp: DateTime.now(),
      );
      _metricsController.add(errorMetrics);
    }
  }

  // Generate more realistic network metrics
  NetworkMetrics _generateRealisticMetrics() {
    final random = Random();
    final now = DateTime.now();
    
    // Simulate different network types based on time and random factors
    final networkTypes = ['4G', '5G', 'WiFi', '3G'];
    final providers = ['MTN Cameroon', 'Orange Cameroon', 'Camtel', 'Nexttel', 'WiFi Network'];
    
    final networkType = networkTypes[random.nextInt(networkTypes.length)];
    final provider = providers[random.nextInt(providers.length)];
    
    // Generate realistic values based on network type and location (Buea)
    int signalStrength;
    double latency;
    double downloadSpeed;
    double uploadSpeed;
    double jitter;
    
    switch (networkType) {
      case '5G':
        // 5G values (limited in Cameroon but simulated for future)
        signalStrength = -50 + random.nextInt(20); // -50 to -70 dBm
        latency = 10 + random.nextDouble() * 25; // 10-35ms
        downloadSpeed = 80 + random.nextDouble() * 120; // 80-200 Mbps
        uploadSpeed = 30 + random.nextDouble() * 70; // 30-100 Mbps
        jitter = random.nextDouble() * 5; // 0-5ms
        break;
        
      case '4G':
        // 4G/LTE values (common in Buea urban areas)
        signalStrength = -70 + random.nextInt(30); // -70 to -100 dBm
        latency = 30 + random.nextDouble() * 70; // 30-100ms
        downloadSpeed = 15 + random.nextDouble() * 85; // 15-100 Mbps
        uploadSpeed = 5 + random.nextDouble() * 35; // 5-40 Mbps
        jitter = 2 + random.nextDouble() * 8; // 2-10ms
        break;
        
      case 'WiFi':
        // WiFi values (varies greatly)
        signalStrength = -40 + random.nextInt(50); // -40 to -90 dBm
        latency = 20 + random.nextDouble() * 80; // 20-100ms (considering internet connection)
        downloadSpeed = 5 + random.nextDouble() * 95; // 5-100 Mbps
        uploadSpeed = 2 + random.nextDouble() * 48; // 2-50 Mbps
        jitter = 1 + random.nextDouble() * 15; // 1-16ms
        break;
        
      default: // 3G
        // 3G values (still common in some areas)
        signalStrength = -80 + random.nextInt(25); // -80 to -105 dBm
        latency = 150 + random.nextDouble() * 250; // 150-400ms
        downloadSpeed = 0.5 + random.nextDouble() * 7.5; // 0.5-8 Mbps
        uploadSpeed = 0.2 + random.nextDouble() * 2.8; // 0.2-3 Mbps
        jitter = 10 + random.nextDouble() * 40; // 10-50ms
        break;
    }

    // Add some variability based on time of day (peak hours have worse performance)
    final hour = now.hour;
    double peakFactor = 1.0;
    
    if ((hour >= 7 && hour <= 9) || (hour >= 17 && hour <= 21)) {
      // Peak hours - reduce speeds and increase latency
      peakFactor = 0.7 + random.nextDouble() * 0.2; // 0.7-0.9 factor
      latency *= (1.2 + random.nextDouble() * 0.5); // Increase latency
      jitter *= (1.3 + random.nextDouble() * 0.4); // Increase jitter
    }
    
    downloadSpeed *= peakFactor;
    uploadSpeed *= peakFactor;

    return NetworkMetrics(
      networkType: networkType,
      signalStrength: signalStrength,
      latency: latency,
      jitter: jitter,
      downloadSpeed: downloadSpeed,
      uploadSpeed: uploadSpeed,
      provider: provider,
      timestamp: now,
    );
  }

  // Enhanced speed test with more realistic simulation
  Future<Map<String, double>> performSpeedTest() async {
    print('NetworkService: Starting speed test...');
    
    // Simulate different phases of speed test
    await Future.delayed(Duration(milliseconds: 500)); // Connection phase
    
    final random = Random();
    final baseLatency = 20 + random.nextDouble() * 60;
    
    // Download test
    await Future.delayed(Duration(seconds: 2));
    final downloadSpeed = 10 + random.nextDouble() * 90;
    
    // Upload test  
    await Future.delayed(Duration(seconds: 2));
    final uploadSpeed = 5 + random.nextDouble() * 45;
    
    // Ping test
    await Future.delayed(Duration(milliseconds: 500));
    final pingLatency = baseLatency + (random.nextDouble() * 20 - 10);
    
    final results = {
      'download': downloadSpeed,
      'upload': uploadSpeed,
      'ping': pingLatency,
    };
    
    print('NetworkService: Speed test completed - Down: ${downloadSpeed.toStringAsFixed(1)} Mbps, Up: ${uploadSpeed.toStringAsFixed(1)} Mbps, Ping: ${pingLatency.toStringAsFixed(1)} ms');
    
    return results;
  }

  // Get current network metrics synchronously (for background service)
  NetworkMetrics getCurrentMetrics() {
    return _generateRealisticMetrics();
  }

  // Method to get the latest metrics from the stream (if available)
  NetworkMetrics? getLastMetrics() {
    try {
      // This is a simplified approach - in a real app you might want to cache the last metrics
      return _generateRealisticMetrics();
    } catch (e) {
      print('NetworkService: Error getting last metrics: $e');
      return null;
    }
  }

  // Health check method
  bool isHealthy() {
    return !_metricsController.isClosed;
  }

  void dispose() {
    _monitoringTimer?.cancel();
    _isMonitoring = false;
    if (!_metricsController.isClosed) {
      _metricsController.close();
    }
    print('NetworkService: Disposed');
  }

  // Reset the service (useful for testing)
  void reset() {
    stopMonitoring();
    if (!_metricsController.isClosed) {
      _metricsController.close();
    }
    // Note: You'd need to recreate the StreamController if you want to use it again
    print('NetworkService: Reset completed');
  }
}