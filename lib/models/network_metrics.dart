class NetworkMetrics {
  final String networkType;
  final int signalStrength;
  final double latency;
  final double jitter;
  final double downloadSpeed;
  final double uploadSpeed;
  final String provider;
  final DateTime timestamp;

  NetworkMetrics({
    required this.networkType,
    required this.signalStrength,
    required this.latency,
    required this.jitter,
    required this.downloadSpeed,
    required this.uploadSpeed,
    required this.provider,
    required this.timestamp,
  });

  String get healthStatus {
    if (signalStrength > -70 && latency < 50) return 'Good';
    if (signalStrength > -85 && latency < 100) return 'Fair';
    return 'Poor';
  }
}