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
  
  // Enhanced health status calculation
  String get healthStatus {
    final signalScore = _getSignalScore();
    final latencyScore = _getLatencyScore();
    final speedScore = _getSpeedScore();
    
    final totalScore = (signalScore + latencyScore + speedScore) / 3;
    
    if (totalScore >= 8) return 'Excellent';
    if (totalScore >= 6) return 'Good';
    if (totalScore >= 4) return 'Fair';
    if (totalScore >= 2) return 'Poor';
    return 'Very Poor';
  }
  
  // Get detailed health scores
  Map<String, dynamic> get detailedHealth {
    return {
      'overall': healthStatus,
      'signal': _getSignalDescription(),
      'latency': _getLatencyDescription(),
      'speed': _getSpeedDescription(),
      'scores': {
        'signal': _getSignalScore(),
        'latency': _getLatencyScore(),
        'speed': _getSpeedScore(),
      }
    };
  }
  
  // Signal strength scoring (0-10)
  int _getSignalScore() {
    if (signalStrength > -50) return 10;
    if (signalStrength > -60) return 9;
    if (signalStrength > -70) return 7;
    if (signalStrength > -80) return 5;
    if (signalStrength > -90) return 3;
    if (signalStrength > -100) return 1;
    return 0;
  }
  
  // Latency scoring (0-10)
  int _getLatencyScore() {
    if (latency < 20) return 10;
    if (latency < 40) return 8;
    if (latency < 60) return 6;
    if (latency < 100) return 4;
    if (latency < 200) return 2;
    return 0;
  }
  
  // Speed scoring (0-10) - based on download speed primarily
  int _getSpeedScore() {
    if (downloadSpeed > 100) return 10;
    if (downloadSpeed > 50) return 9;
    if (downloadSpeed > 25) return 7;
    if (downloadSpeed > 10) return 5;
    if (downloadSpeed > 5) return 3;
    if (downloadSpeed > 1) return 1;
    return 0;
  }
  
  // Signal strength description
  String _getSignalDescription() {
    final score = _getSignalScore();
    if (score >= 9) return 'Excellent Signal';
    if (score >= 7) return 'Good Signal';
    if (score >= 5) return 'Fair Signal';
    if (score >= 3) return 'Weak Signal';
    return 'Very Weak Signal';
  }
  
  // Latency description
  String _getLatencyDescription() {
    if (latency < 20) return 'Excellent Latency';
    if (latency < 40) return 'Good Latency';
    if (latency < 60) return 'Fair Latency';
    if (latency < 100) return 'High Latency';
    if (latency < 200) return 'Very High Latency';
    return 'Poor Latency';
  }
  
  // Speed description
  String _getSpeedDescription() {
    if (downloadSpeed > 100) return 'Ultra Fast';
    if (downloadSpeed > 50) return 'Very Fast';
    if (downloadSpeed > 25) return 'Fast';
    if (downloadSpeed > 10) return 'Moderate';
    if (downloadSpeed > 5) return 'Slow';
    if (downloadSpeed > 1) return 'Very Slow';
    return 'Poor Speed';
  }
  
  // Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'networkType': networkType,
      'signalStrength': signalStrength,
      'latency': latency,
      'jitter': jitter,
      'downloadSpeed': downloadSpeed,
      'uploadSpeed': uploadSpeed,
      'provider': provider,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'healthStatus': healthStatus,
    };
  }
  
  // Create from Map (database retrieval)
  factory NetworkMetrics.fromMap(Map<String, dynamic> map) {
    return NetworkMetrics(
      networkType: map['networkType'] ?? 'Unknown',
      signalStrength: map['signalStrength'] ?? -999,
      latency: (map['latency'] ?? 0.0).toDouble(),
      jitter: (map['jitter'] ?? 0.0).toDouble(),
      downloadSpeed: (map['downloadSpeed'] ?? 0.0).toDouble(),
      uploadSpeed: (map['uploadSpeed'] ?? 0.0).toDouble(),
      provider: map['provider'] ?? 'Unknown',
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        map['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
  
  // Convert to JSON for API sync
  Map<String, dynamic> toJson() {
    return {
      'network_type': networkType,
      'signal_strength': signalStrength,
      'latency': latency,
      'jitter': jitter,
      'download_speed': downloadSpeed,
      'upload_speed': uploadSpeed,
      'provider': provider,
      'timestamp': timestamp.toIso8601String(),
      'health_status': healthStatus,
      'detailed_health': detailedHealth,
    };
  }
  
  // Create from JSON (API response)
  factory NetworkMetrics.fromJson(Map<String, dynamic> json) {
    return NetworkMetrics(
      networkType: json['network_type'] ?? 'Unknown',
      signalStrength: json['signal_strength'] ?? -999,
      latency: (json['latency'] ?? 0.0).toDouble(),
      jitter: (json['jitter'] ?? 0.0).toDouble(),
      downloadSpeed: (json['download_speed'] ?? 0.0).toDouble(),
      uploadSpeed: (json['upload_speed'] ?? 0.0).toDouble(),
      provider: json['provider'] ?? 'Unknown',
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
  
  // Copy with method for modifications
  NetworkMetrics copyWith({
    String? networkType,
    int? signalStrength,
    double? latency,
    double? jitter,
    double? downloadSpeed,
    double? uploadSpeed,
    String? provider,
    DateTime? timestamp,
  }) {
    return NetworkMetrics(
      networkType: networkType ?? this.networkType,
      signalStrength: signalStrength ?? this.signalStrength,
      latency: latency ?? this.latency,
      jitter: jitter ?? this.jitter,
      downloadSpeed: downloadSpeed ?? this.downloadSpeed,
      uploadSpeed: uploadSpeed ?? this.uploadSpeed,
      provider: provider ?? this.provider,
      timestamp: timestamp ?? this.timestamp,
    );
  }
  
  // Get network quality category
  NetworkQuality get networkQuality {
    final score = ((_getSignalScore() + _getLatencyScore() + _getSpeedScore()) / 3).round();
    
    if (score >= 8) return NetworkQuality.excellent;
    if (score >= 6) return NetworkQuality.good;
    if (score >= 4) return NetworkQuality.fair;
    if (score >= 2) return NetworkQuality.poor;
    return NetworkQuality.veryPoor;
  }
  
  // Get formatted display strings
  String get formattedSignalStrength => '${signalStrength} dBm';
  String get formattedLatency => '${latency.toStringAsFixed(1)} ms';
  String get formattedJitter => '${jitter.toStringAsFixed(1)} ms';
  String get formattedDownloadSpeed => '${downloadSpeed.toStringAsFixed(1)} Mbps';
  String get formattedUploadSpeed => '${uploadSpeed.toStringAsFixed(1)} Mbps';
  String get formattedTimestamp => 
      '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}/${timestamp.year} '
      '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  
  // Check if metrics indicate a problem
  bool get hasNetworkIssues {
    return signalStrength < -90 || latency > 150 || downloadSpeed < 1;
  }
  
  // Get color code for UI display
  String get statusColor {
    switch (networkQuality) {
      case NetworkQuality.excellent:
        return '#4CAF50'; // Green
      case NetworkQuality.good:
        return '#8BC34A'; // Light Green
      case NetworkQuality.fair:
        return '#FFC107'; // Amber
      case NetworkQuality.poor:
        return '#FF9800'; // Orange
      case NetworkQuality.veryPoor:
        return '#F44336'; // Red
    }
  }
  
  // Compare with another NetworkMetrics instance
  NetworkComparison compareWith(NetworkMetrics other) {
    final signalChange = signalStrength - other.signalStrength;
    final latencyChange = latency - other.latency;
    final speedChange = downloadSpeed - other.downloadSpeed;
    
    return NetworkComparison(
      signalChange: signalChange,
      latencyChange: latencyChange,
      speedChange: speedChange,
      improvement: _calculateImprovement(other),
    );
  }
  
  // Calculate overall improvement compared to another metric
  double _calculateImprovement(NetworkMetrics other) {
    final currentScore = (_getSignalScore() + _getLatencyScore() + _getSpeedScore()) / 3;
    final otherScore = (other._getSignalScore() + other._getLatencyScore() + other._getSpeedScore()) / 3;
    return currentScore - otherScore;
  }
  
  // Check if this metric is better than another
  bool isBetterThan(NetworkMetrics other) {
    return _calculateImprovement(other) > 0;
  }
  
  // Get summary for notifications
  String get notificationSummary {
    return '$networkType | ${formattedSignalStrength} | ${formattedLatency} | $healthStatus';
  }
  
  // Get detailed summary for reports
  String get detailedSummary {
    return '''
Network Type: $networkType
Provider: $provider
Signal Strength: $formattedSignalStrength (${_getSignalDescription()})
Latency: $formattedLatency (${_getLatencyDescription()})
Jitter: $formattedJitter
Download Speed: $formattedDownloadSpeed
Upload Speed: $formattedUploadSpeed
Overall Status: $healthStatus
Timestamp: $formattedTimestamp
    '''.trim();
  }
  
  @override
  String toString() {
    return 'NetworkMetrics{networkType: $networkType, signalStrength: $signalStrength, '
           'latency: $latency, downloadSpeed: $downloadSpeed, healthStatus: $healthStatus}';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NetworkMetrics &&
        other.networkType == networkType &&
        other.signalStrength == signalStrength &&
        other.latency == latency &&
        other.jitter == jitter &&
        other.downloadSpeed == downloadSpeed &&
        other.uploadSpeed == uploadSpeed &&
        other.provider == provider &&
        other.timestamp == timestamp;
  }
  
  @override
  int get hashCode {
    return Object.hash(
      networkType,
      signalStrength,
      latency,
      jitter,
      downloadSpeed,
      uploadSpeed,
      provider,
      timestamp,
    );
  }
}

// Enum for network quality categories
enum NetworkQuality {
  excellent,
  good,
  fair,
  poor,
  veryPoor,
}

// Extension for NetworkQuality enum
extension NetworkQualityExtension on NetworkQuality {
  String get displayName {
    switch (this) {
      case NetworkQuality.excellent:
        return 'Excellent';
      case NetworkQuality.good:
        return 'Good';
      case NetworkQuality.fair:
        return 'Fair';
      case NetworkQuality.poor:
        return 'Poor';
      case NetworkQuality.veryPoor:
        return 'Very Poor';
    }
  }
  
  String get description {
    switch (this) {
      case NetworkQuality.excellent:
        return 'Outstanding network performance';
      case NetworkQuality.good:
        return 'Good network performance';
      case NetworkQuality.fair:
        return 'Acceptable network performance';
      case NetworkQuality.poor:
        return 'Poor network performance';
      case NetworkQuality.veryPoor:
        return 'Very poor network performance';
    }
  }
}

// Helper class for network comparison
class NetworkComparison {
  final int signalChange;
  final double latencyChange;
  final double speedChange;
  final double improvement;
  
  NetworkComparison({
    required this.signalChange,
    required this.latencyChange,
    required this.speedChange,
    required this.improvement,
  });
  
  bool get hasImproved => improvement > 0;
  bool get hasWorsened => improvement < 0;
  bool get isStable => improvement.abs() < 0.5;
  
  String get improvementDescription {
    if (hasImproved) return 'Network has improved';
    if (hasWorsened) return 'Network has worsened';
    return 'Network is stable';
  }
}