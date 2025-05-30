// Previous background_service.dart content remains the same, but update the _collectMetrics method:

  @pragma('vm:entry-point')
  static Future<void> _collectMetrics(ServiceInstance service) async {
    if (!_isInitialized || _dbHelper == null) {
      print('⚠️ Services not initialized, skipping collection');
      return;
    }

    try {
      print('📊 Starting metrics collection cycle...');

      // Get location
      String locationString = 'Unknown';
      try {
        final locationService = LocationService();
        locationString = await locationService.getCurrentLocation().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            print('⏰ Location timeout, using default');
            return 'Unknown Location';
          },
        );
      } catch (e) {
        print('⚠️ Location error: $e');
      }

      // Generate metrics
      final metrics = _generateNetworkMetrics();
      print('📶 Generated metrics: ${metrics.networkType}');

      // Save to database
      final id = await _dbHelper!.insertMetrics(metrics, locationString);
      print('💾 Saved metrics with ID: $id');

      // Update notification
      if (service is AndroidServiceInstance) {
        final count = await _dbHelper!.getMetricsCount();
        service.setForegroundNotificationInfo(
          title: 'Network Monitor Active',
          content: 'Monitoring network (${count} records)',
        );
      }

    } catch (e) {
      print('❌ Error collecting metrics: $e');
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: 'Network Monitor Error',
          content: 'Error collecting metrics',
        );
      }
    }
  }