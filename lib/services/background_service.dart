// Enhanced background_service.dart with better error handling and debugging

import 'dart:async';
import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/network_metrics.dart';
import 'location_service.dart';
import 'database_helper.dart';

@pragma('vm:entry-point')
class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  static const String notificationChannelId = 'network_monitor_channel';
  static const String notificationId = 'network_monitor_notification';
  static const int _syncInterval = 15; // minutes
  static Timer? _syncTimer;
  static Timer? _metricsTimer;
  static bool _isInitialized = false;
  static DatabaseHelper? _dbHelper;

  Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    // Create notification channel first
    await _createNotificationChannel();

    // Configure Android-specific settings
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: notificationChannelId,
        initialNotificationTitle: 'Network Monitor',
        initialNotificationContent: 'Initializing network monitoring...',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    await setupLocalNotifications();

    // Start the service
    final isRunning = await service.isRunning();
    if (!isRunning) {
      await service.startService();
    }
  }

  // Create notification channel for Android
  Future<void> _createNotificationChannel() async {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      notificationChannelId,
      'Network Monitor Service',
      description:
          'This channel is used for network monitoring service notifications.',
      importance: Importance.low,
      enableLights: false,
      enableVibration: false,
      showBadge: false,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // Initialize local notifications
  Future<void> setupLocalNotifications() async {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    // Ensure Flutter binding is initialized first
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();

    print('🚀 Background service started');

    // Update notification to show starting
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: 'Network Monitor',
        content: 'Starting up...',
      );
    }

    // Add longer delay to ensure everything is properly initialized
    await Future.delayed(const Duration(seconds: 3));

    try {
      await _initializeServices(service);
      await _setupTimers(service);
      _setupMessageHandlers(service);

      print('✅ Background service initialized successfully');
    } catch (e) {
      print('❌ Critical error starting background service: $e');

      // Show error in notification
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: 'Network Monitor Error',
          content:
              'Startup failed: ${e.toString().length > 30 ? '${e.toString().substring(0, 30)}...' : e.toString()}',
        );
      }

      // Don't stop the service, keep retrying
      _retryInitialization(service);
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _initializeServices(ServiceInstance service) async {
    print('🔧 Initializing database and services...');

    // Initialize database helper with retry logic
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries && _dbHelper == null) {
      try {
        _dbHelper = DatabaseHelper.instance;
        await _dbHelper!.database; // Force database creation

        // Verify database is working
        final tableExists = await _dbHelper!.tableExists();
        print('📊 Database table exists: $tableExists');

        if (!tableExists) {
          print('⚠️ Database table doesn\'t exist, attempting to create...');
          await _dbHelper!.database; // This should trigger table creation
          await Future.delayed(const Duration(seconds: 1));

          final tableExistsAfterCreate = await _dbHelper!.tableExists();
          print('📊 Database table created: $tableExistsAfterCreate');
        }

        final metricsCount = await _dbHelper!.getMetricsCount();
        print('📈 Current metrics count: $metricsCount');

        _isInitialized = true;
        break;
      } catch (e) {
        retryCount++;
        print('⚠️ Database initialization attempt $retryCount failed: $e');

        if (retryCount < maxRetries) {
          await Future.delayed(Duration(seconds: retryCount * 2));
        } else {
          throw Exception(
              'Database initialization failed after $maxRetries attempts: $e');
        }
      }
    }

    // Update notification with initialization status
    if (service is AndroidServiceInstance) {
      final metricsCount = await _dbHelper!.getMetricsCount();
      service.setForegroundNotificationInfo(
        title: 'Network Monitor',
        content: 'Services initialized. Total: $metricsCount',
      );
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _setupTimers(ServiceInstance service) async {
    print('⏰ Setting up monitoring timers...');

    // Start periodic data collection (every 2 minutes)
    _metricsTimer?.cancel();
    _metricsTimer = Timer.periodic(const Duration(minutes: 2), (timer) async {
      await _collectMetrics(service);
    });

    // Start periodic sync with remote database (every 15 minutes)
    _syncTimer?.cancel();
    _syncTimer =
        Timer.periodic(Duration(minutes: _syncInterval), (timer) async {
      await _performSync(service);
    });

    print('⏰ Timers configured successfully');
  }

  @pragma('vm:entry-point')
  static void _setupMessageHandlers(ServiceInstance service) {
    // Handle service messages
    service.on('stopService').listen((event) {
      print('🛑 Stop service requested');
      _metricsTimer?.cancel();
      _syncTimer?.cancel();
      service.stopSelf();
    });

    // Handle clear data message
    service.on('clearData').listen((event) async {
      try {
        await _dbHelper?.clearAllData();
        print('🗑️ All data cleared');

        // Update notification
        if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(
            title: 'Network Monitor Active',
            content: 'Data cleared. Starting fresh...',
          );
        }
      } catch (e) {
        print('❌ Error clearing data: $e');
      }
    });

    // Handle manual collection trigger
    service.on('collectNow').listen((event) async {
      print('🔄 Manual collection triggered');
      await _collectMetrics(service);
    });

    print('📡 Message handlers configured');
  }

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

  @pragma('vm:entry-point')
  static Future<void> _performSync(ServiceInstance service) async {
    if (!_isInitialized || _dbHelper == null) {
      print('⚠️ Services not initialized, skipping sync');
      return;
    }

    print('🔄 Starting data sync cycle...');
    try {
      await _syncDataWithRemoteDatabase(_dbHelper!);

      // Update notification after successful sync
      if (service is AndroidServiceInstance) {
        final totalCount = await _dbHelper!.getMetricsCount();
        final unsyncedCount = (await _dbHelper!.getUnsyncedMetrics()).length;
        final now = DateTime.now();
        final timeStr =
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

        service.setForegroundNotificationInfo(
          title: 'Network Monitor Active',
          content:
              'Total: $totalCount | Unsynced: $unsyncedCount | Synced: $timeStr',
        );
      }
    } catch (e) {
      print('❌ Sync error: $e');
    }
  }

  @pragma('vm:entry-point')
  static void _retryInitialization(ServiceInstance service) {
    print('🔄 Setting up retry timer...');

    Timer.periodic(const Duration(minutes: 1), (timer) async {
      if (_isInitialized) {
        timer.cancel();
        return;
      }

      print('🔄 Retrying initialization...');
      try {
        await _initializeServices(service);
        await _setupTimers(service);
        timer.cancel();
        print('✅ Retry successful');
      } catch (e) {
        print('⚠️ Retry failed: $e');

        if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(
            title: 'Network Monitor (Retrying)',
            content: 'Initialization retry failed - will try again...',
          );
        }
      }
    });
  }

  // Generate network metrics directly (no async complications)
  @pragma('vm:entry-point')
  static NetworkMetrics _generateNetworkMetrics() {
    final random = DateTime.now().millisecondsSinceEpoch % 1000;

    // Simulate realistic network conditions
    final networkTypes = ['4G', '5G', 'WiFi', '3G'];
    final providers = ['MTN Cameroon', 'Orange Cameroon', 'Camtel', 'Nexttel'];

    final networkType = networkTypes[random % networkTypes.length];
    final provider = providers[random % providers.length];

    // Generate realistic values based on network type
    int signalStrength;
    double latency;
    double downloadSpeed;
    double uploadSpeed;

    switch (networkType) {
      case '5G':
        signalStrength = -40 - (random % 30); // -40 to -70
        latency = 10 + (random % 20); // 10-30ms
        downloadSpeed = 50 + (random % 150); // 50-200 Mbps
        uploadSpeed = 20 + (random % 80); // 20-100 Mbps
        break;
      case '4G':
        signalStrength = -60 - (random % 40); // -60 to -100
        latency = 20 + (random % 60); // 20-80ms
        downloadSpeed = 10 + (random % 90); // 10-100 Mbps
        uploadSpeed = 5 + (random % 45); // 5-50 Mbps
        break;
      case 'WiFi':
        signalStrength = -30 - (random % 50); // -30 to -80
        latency = 15 + (random % 35); // 15-50ms
        downloadSpeed = 20 + (random % 180); // 20-200 Mbps
        uploadSpeed = 15 + (random % 85); // 15-100 Mbps
        break;
      default: // 3G
        signalStrength = -70 - (random % 30); // -70 to -100
        latency = 100 + (random % 200); // 100-300ms
        downloadSpeed = 1 + (random % 9); // 1-10 Mbps
        uploadSpeed = 0.5 + (random % 4.5); // 0.5-5 Mbps
        break;
    }

    return NetworkMetrics(
      networkType: networkType,
      signalStrength: signalStrength,
      latency: latency.toDouble(),
      jitter: (random % 10).toDouble(), // 0-10ms jitter
      downloadSpeed: downloadSpeed.toDouble(),
      uploadSpeed: uploadSpeed.toDouble(),
      provider: provider,
      timestamp: DateTime.now(),
    );
  }

  @pragma('vm:entry-point')
  static Future<void> _syncDataWithRemoteDatabase(
      DatabaseHelper dbHelper) async {
    try {
      // Get unsynced records
      final unsyncedRecords = await dbHelper.getUnsyncedMetrics();

      print('🔄 Found ${unsyncedRecords.length} unsynced records');

      if (unsyncedRecords.isEmpty) {
        print('✅ No records to sync');
        return;
      }

      // Simulate remote sync
      print('🌐 Simulating remote sync...');
      await Future.delayed(const Duration(seconds: 2));

      // Mark records as synced
      final syncedCount = await dbHelper.markAllUnsyncedAsSynced();
      print('✅ Marked $syncedCount records as synced');

      // Save sync info
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_sync', DateTime.now().toIso8601String());
      await prefs.setInt('last_sync_count', syncedCount);

      print('✅ Data sync completed successfully');
    } catch (e) {
      print('❌ Error syncing data: $e');

      // Save error info
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_sync_error', e.toString());
      await prefs.setString(
          'last_sync_error_time', DateTime.now().toIso8601String());
    }
  }

  // Rest of your existing methods remain the same...
  Future<void> stopService() async {
    final service = FlutterBackgroundService();
    _metricsTimer?.cancel();
    _syncTimer?.cancel();

    if (await service.isRunning()) {
      service.invoke('stopService');
    }
  }

  Future<bool> isServiceRunning() async {
    final service = FlutterBackgroundService();
    return await service.isRunning();
  }

  Future<void> clearAllData() async {
    final service = FlutterBackgroundService();
    if (await service.isRunning()) {
      service.invoke('clearData');
    } else {
      final dbHelper = DatabaseHelper.instance;
      await dbHelper.clearAllData();
    }
  }

  Future<Map<String, dynamic>> getServiceStatus() async {
    final service = FlutterBackgroundService();
    final prefs = await SharedPreferences.getInstance();
    final dbHelper = DatabaseHelper.instance;

    try {
      final totalMetrics = await dbHelper.getMetricsCount();
      final unsyncedMetrics = (await dbHelper.getUnsyncedMetrics()).length;

      return {
        'isRunning': await service.isRunning(),
        'isInitialized': _isInitialized,
        'totalMetrics': totalMetrics,
        'unsyncedMetrics': unsyncedMetrics,
        'syncedMetrics': totalMetrics - unsyncedMetrics,
        'lastSync': prefs.getString('last_sync'),
        'lastSyncCount': prefs.getInt('last_sync_count'),
        'lastSyncError': prefs.getString('last_sync_error'),
        'lastSyncErrorTime': prefs.getString('last_sync_error_time'),
        'tableExists': await dbHelper.tableExists(),
      };
    } catch (e) {
      return {
        'isRunning': await service.isRunning(),
        'isInitialized': _isInitialized,
        'error': e.toString(),
        'lastSync': prefs.getString('last_sync'),
        'lastSyncError': prefs.getString('last_sync_error'),
      };
    }
  }

  // Additional debugging methods
  Future<List<String>> getServiceLogs() async {
    // In a real implementation, you might want to collect logs
    // For now, return basic status info
    final status = await getServiceStatus();
    return [
      'Service Running: ${status['isRunning']}',
      'Initialized: ${status['isInitialized']}',
      'Total Metrics: ${status['totalMetrics']}',
      'Table Exists: ${status['tableExists']}',
      'Last Error: ${status['error'] ?? 'None'}',
    ];
  }

  Future<int> getMetricsCount() async {
    try {
      final dbHelper = DatabaseHelper.instance;
      return await dbHelper.getMetricsCount();
    } catch (e) {
      print('❌ Error getting metrics count: $e');
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> getRecentMetrics({int limit = 10}) async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final allMetrics = await dbHelper.getAllMetrics();

      if (allMetrics.length <= limit) {
        return allMetrics;
      } else {
        return allMetrics.sublist(0, limit);
      }
    } catch (e) {
      print('❌ Error getting recent metrics: $e');
      return [];
    }
  }

  Future<int> getUnsyncedCount() async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final unsyncedMetrics = await dbHelper.getUnsyncedMetrics();
      return unsyncedMetrics.length;
    } catch (e) {
      print('❌ Error getting unsynced count: $e');
      return 0;
    }
  }

  Future<void> triggerSync() async {
    try {
      final dbHelper = DatabaseHelper.instance;
      await _syncDataWithRemoteDatabase(dbHelper);
    } catch (e) {
      print('❌ Error in manual sync: $e');
      rethrow;
    }
  }

  // Method to manually trigger a metric collection (for testing)
  Future<void> triggerMetricCollection() async {
    final service = FlutterBackgroundService();
    if (await service.isRunning()) {
      service.invoke('collectNow');
    }
  }
}