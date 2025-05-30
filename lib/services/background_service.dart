//background_service.dart

import 'dart:async';
import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/network_metrics.dart';
import 'network_service.dart';
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
        initialNotificationContent: 'Monitoring network quality...',
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
      description: 'This channel is used for network monitoring service notifications.',
      importance: Importance.low, // Use low importance to avoid intrusive notifications
      enableLights: false,
      enableVibration: false,
      showBadge: false,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
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

    const InitializationSettings initializationSettings = InitializationSettings(
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

    print('Background service started');

    // Add a small delay to ensure everything is properly initialized
    await Future.delayed(const Duration(seconds: 1));

    try {
      // Initialize database helper
      final dbHelper = DatabaseHelper.instance;
      await dbHelper.database; // This will create the database and table if needed
      
      final NetworkService networkService = NetworkService();
      final LocationService locationService = LocationService();

      print('Services initialized successfully');

      // Verify database is working
      final tableExists = await dbHelper.tableExists();
      print('Database table exists: $tableExists');
      
      final metricsCount = await dbHelper.getMetricsCount();
      print('Current metrics count: $metricsCount');

      // Set initial notification for Android
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: 'Network Monitor Starting',
          content: 'Initializing network monitoring...',
        );
      }

      // Handle service messages
      service.on('stopService').listen((event) {
        print('Stop service requested');
        _metricsTimer?.cancel();
        _syncTimer?.cancel();
        service.stopSelf();
      });

      // Handle clear data message
      service.on('clearData').listen((event) async {
        try {
          await dbHelper.clearAllData();
          print('All data cleared');
        } catch (e) {
          print('Error clearing data: $e');
        }
      });

      // Periodic data collection (every 2 minutes for testing)
      _metricsTimer = Timer.periodic(const Duration(minutes: 2), (timer) async {
        try {
          print('Collecting network metrics...');
          
          final location = await locationService.getCurrentLocation();
          print('Location: $location');
          
          final metrics = await _collectNetworkMetrics(networkService);
          print('Metrics collected: ${metrics.networkType}');
          
          // Use DatabaseHelper to insert metrics
          final id = await dbHelper.insertMetrics(metrics, location);
          print('Metrics saved with ID: $id');
          
          // Update notification with current stats
          final totalCount = await dbHelper.getMetricsCount();
          final unsyncedCount = (await dbHelper.getUnsyncedMetrics()).length;
          
          if (service is AndroidServiceInstance) {
            service.setForegroundNotificationInfo(
              title: 'Network Monitor Active',
              content: 'Total: $totalCount | Unsynced: $unsyncedCount | Last: ${DateTime.now().toString().split('.')[0]}',
            );
          }

          print('Metrics collection completed successfully');

        } catch (e) {
          print('Error collecting metrics: $e');
          // Continue running even if one collection fails
          
          // Update notification to show error
          if (service is AndroidServiceInstance) {
            service.setForegroundNotificationInfo(
              title: 'Network Monitor (Error)',
              content: 'Last error: ${DateTime.now().toString().split('.')[0]}',
            );
          }
        }
      });

      // Periodic sync with remote database (every 15 minutes when online)
      _syncTimer?.cancel();
      _syncTimer = Timer.periodic(Duration(minutes: _syncInterval), (timer) async {
        print('Starting data sync...');
        await _syncDataWithRemoteDatabase(dbHelper);
      });

      // Initial notification update
      if (service is AndroidServiceInstance) {
        final totalCount = await dbHelper.getMetricsCount();
        service.setForegroundNotificationInfo(
          title: 'Network Monitor Ready',
          content: 'Monitoring started. Current metrics: $totalCount',
        );
      }

      print('Background service initialized successfully');

    } catch (e) {
      print('Error starting background service: $e');
      
      // Update notification to show initialization error
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: 'Network Monitor Error',
          content: 'Failed to initialize: ${e.toString().substring(0, 50)}...',
        );
      }
    }
  }

  @pragma('vm:entry-point')
  static Future<NetworkMetrics> _collectNetworkMetrics(NetworkService networkService) async {
    // Add timeout to prevent hanging
    final completer = Completer<NetworkMetrics>();
    
    // Start collecting metrics
    networkService.collectMetrics();
    
    // Set up timeout
    Timer(const Duration(seconds: 30), () {
      if (!completer.isCompleted) {
        // Create dummy metrics if timeout occurs
        final dummyMetrics = NetworkMetrics(
          networkType: 'Timeout',
          signalStrength: -999,
          latency: 0.0,
          jitter: 0.0,
          downloadSpeed: 0.0,
          uploadSpeed: 0.0,
          provider: 'Timeout',
          timestamp: DateTime.now(),
        );
        completer.complete(dummyMetrics);
      }
    });
    
    // Listen for metrics
    networkService.metricsStream.first.then((metrics) {
      if (!completer.isCompleted) {
        completer.complete(metrics);
      }
    }).catchError((error) {
      if (!completer.isCompleted) {
        // Create dummy metrics if error occurs
        final dummyMetrics = NetworkMetrics(
          networkType: 'Error',
          signalStrength: -999,
          latency: 0.0,
          jitter: 0.0,
          downloadSpeed: 0.0,
          uploadSpeed: 0.0,
          provider: 'Error: $error',
          timestamp: DateTime.now(),
        );
        completer.complete(dummyMetrics);
      }
    });
    
    return completer.future;
  }

  @pragma('vm:entry-point')
  static Future<void> _syncDataWithRemoteDatabase(DatabaseHelper dbHelper) async {
    try {
      // Get unsynced records using DatabaseHelper
      final unsyncedRecords = await dbHelper.getUnsyncedMetrics();

      print('Found ${unsyncedRecords.length} unsynced records');

      if (unsyncedRecords.isEmpty) {
        print('No records to sync');
        return;
      }

      // For now, simulate successful sync after 2 seconds
      print('Simulating remote sync...');
      await Future.delayed(const Duration(seconds: 2));

      // Mark all unsynced records as synced (for simulation)
      final syncedCount = await dbHelper.markAllUnsyncedAsSynced();
      print('Marked $syncedCount records as synced');

      // Save last sync time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_sync', DateTime.now().toIso8601String());
      await prefs.setInt('last_sync_count', syncedCount);

      print('Data sync completed successfully');

    } catch (e) {
      print('Error syncing data: $e');
      
      // Save sync error info
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_sync_error', e.toString());
      await prefs.setString('last_sync_error_time', DateTime.now().toIso8601String());
    }
  }

  Future<void> stopService() async {
    final service = FlutterBackgroundService();
    _metricsTimer?.cancel();
    _syncTimer?.cancel();
    
    if (await service.isRunning()) {
      service.invoke('stopService');
    }
  }

  // Method to check if service is running
  Future<bool> isServiceRunning() async {
    final service = FlutterBackgroundService();
    return await service.isRunning();
  }

  // Method to clear all data via service
  Future<void> clearAllData() async {
    final service = FlutterBackgroundService();
    if (await service.isRunning()) {
      service.invoke('clearData');
    } else {
      // If service is not running, clear directly
      final dbHelper = DatabaseHelper.instance;
      await dbHelper.clearAllData();
    }
  }

  // Method to get comprehensive service status
  Future<Map<String, dynamic>> getServiceStatus() async {
    final service = FlutterBackgroundService();
    final prefs = await SharedPreferences.getInstance();
    final dbHelper = DatabaseHelper.instance;
    
    try {
      final totalMetrics = await dbHelper.getMetricsCount();
      final unsyncedMetrics = (await dbHelper.getUnsyncedMetrics()).length;
      
      return {
        'isRunning': await service.isRunning(),
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
        'error': e.toString(),
        'lastSync': prefs.getString('last_sync'),
        'lastSyncError': prefs.getString('last_sync_error'),
      };
    }
  }

  // Method to get metrics count from database
  Future<int> getMetricsCount() async {
    try {
      final dbHelper = DatabaseHelper.instance;
      return await dbHelper.getMetricsCount();
    } catch (e) {
      print('Error getting metrics count: $e');
      return 0;
    }
  }

  // Method to get recent metrics for debugging
  Future<List<Map<String, dynamic>>> getRecentMetrics({int limit = 10}) async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final allMetrics = await dbHelper.getAllMetrics();
      
      // Return limited results
      if (allMetrics.length <= limit) {
        return allMetrics;
      } else {
        return allMetrics.sublist(0, limit);
      }
    } catch (e) {
      print('Error getting recent metrics: $e');
      return [];
    }
  }

  // Method to get unsynced metrics count
  Future<int> getUnsyncedCount() async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final unsyncedMetrics = await dbHelper.getUnsyncedMetrics();
      return unsyncedMetrics.length;
    } catch (e) {
      print('Error getting unsynced count: $e');
      return 0;
    }
  }

  // Method to manually trigger sync
  Future<void> triggerSync() async {
    try {
      final dbHelper = DatabaseHelper.instance;
      await _syncDataWithRemoteDatabase(dbHelper);
    } catch (e) {
      print('Error in manual sync: $e');
      rethrow;
    }
  }

  // Method to force restart timers (useful for testing)
  Future<void> restartTimers() async {
    _metricsTimer?.cancel();
    _syncTimer?.cancel();
    
    // Note: This would need to be called from within the service context
    // to properly restart the timers. For external use, consider stopping 
    // and restarting the entire service.
    print('Timers cancelled. Restart service to reinitialize timers.');
  }
}