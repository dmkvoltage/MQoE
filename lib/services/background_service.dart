import 'dart:async';
import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/network_metrics.dart';
import 'location_service.dart';
import 'database_helper.dart';
import 'network_service.dart';

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
  static NetworkService? _networkService;

  Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    await _createNotificationChannel();

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

    final isRunning = await service.isRunning();
    if (!isRunning) {
      await service.startService();
    }
  }

  Future<void> _createNotificationChannel() async {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      notificationChannelId,
      'Network Monitor Service',
      description: 'This channel is used for network monitoring service notifications.',
      importance: Importance.low,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

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
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();

    print('🚀 Background service started');

    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: 'Network Monitor',
        content: 'Starting up...',
      );
    }

    await Future.delayed(const Duration(seconds: 3));

    try {
      await _initializeServices(service);
      await _setupTimers(service);
      _setupMessageHandlers(service);

      print('✅ Background service initialized successfully');
    } catch (e) {
      print('❌ Critical error starting background service: $e');

      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: 'Network Monitor Error',
          content: 'Startup failed: ${e.toString().length > 30 ? '${e.toString().substring(0, 30)}...' : e.toString()}',
        );
      }

      _retryInitialization(service);
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _initializeServices(ServiceInstance service) async {
    print('🔧 Initializing services...');

    _dbHelper = DatabaseHelper.instance;
    await _dbHelper!.database;

    _networkService = NetworkService();
    _networkService!.startMonitoring();

    final tableExists = await _dbHelper!.tableExists();
    if (!tableExists) {
      print('⚠️ Creating database table...');
      await _dbHelper!.database;
      
      final tableExistsAfterCreate = await _dbHelper!.tableExists();
      print('📊 Database table created: $tableExistsAfterCreate');
    }

    _isInitialized = true;

    if (service is AndroidServiceInstance) {
      final metricsCount = await _dbHelper!.getMetricsCount();
      service.setForegroundNotificationInfo(
        title: 'Network Monitor',
        content: 'Monitoring active - $metricsCount records',
      );
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _setupTimers(ServiceInstance service) async {
    print('⏰ Setting up monitoring timers...');

    _metricsTimer?.cancel();
    _metricsTimer = Timer.periodic(const Duration(minutes: 2), (timer) async {
      await _collectMetrics(service);
    });

    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(Duration(minutes: _syncInterval), (timer) async {
      await _performSync(service);
    });

    print('⏰ Timers configured successfully');
  }

  @pragma('vm:entry-point')
  static void _setupMessageHandlers(ServiceInstance service) {
    service.on('stopService').listen((event) {
      print('🛑 Stop service requested');
      _metricsTimer?.cancel();
      _syncTimer?.cancel();
      _networkService?.stopMonitoring();
      service.stopSelf();
    });

    service.on('clearData').listen((event) async {
      try {
        await _dbHelper?.clearAllData();
        print('🗑️ All data cleared');

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

    service.on('collectNow').listen((event) async {
      print('🔄 Manual collection triggered');
      await _collectMetrics(service);
    });

    print('📡 Message handlers configured');
  }

  @pragma('vm:entry-point')
  static Future<void> _collectMetrics(ServiceInstance service) async {
    if (!_isInitialized || _dbHelper == null || _networkService == null) {
      print('⚠️ Services not initialized, skipping collection');
      return;
    }

    try {
      print('📊 Starting metrics collection cycle...');

      String locationString = 'Unknown';
      try {
        final locationService = LocationService();
        locationString = await locationService.getCurrentLocation();
      } catch (e) {
        print('⚠️ Location error: $e');
      }

      final metrics = await _networkService!.getCurrentMetrics();
      print('📶 Collected metrics: ${metrics.networkType}');

      final id = await _dbHelper!.insertMetrics(metrics, locationString);
      print('💾 Saved metrics with ID: $id');

      if (service is AndroidServiceInstance) {
        final count = await _dbHelper!.getMetricsCount();
        service.setForegroundNotificationInfo(
          title: 'Network Monitor Active',
          content: '${metrics.networkType} | ${metrics.downloadSpeed.toStringAsFixed(1)} Mbps ↓ | ${metrics.uploadSpeed.toStringAsFixed(1)} Mbps ↑',
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
      final unsyncedRecords = await _dbHelper!.getUnsyncedMetrics();
      print('🔄 Found ${unsyncedRecords.length} unsynced records');

      if (unsyncedRecords.isNotEmpty) {
        // Here you would implement your sync logic with a remote server
        await Future.delayed(const Duration(seconds: 2));
        final syncedCount = await _dbHelper!.markAllUnsyncedAsSynced();
        print('✅ Marked $syncedCount records as synced');

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_sync', DateTime.now().toIso8601String());
        await prefs.setInt('last_sync_count', syncedCount);
      }

      if (service is AndroidServiceInstance) {
        final totalCount = await _dbHelper!.getMetricsCount();
        service.setForegroundNotificationInfo(
          title: 'Network Monitor Active',
          content: 'Records: $totalCount | Last sync: ${DateTime.now().hour}:${DateTime.now().minute}',
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

  Future<void> stopService() async {
    final service = FlutterBackgroundService();
    _metricsTimer?.cancel();
    _syncTimer?.cancel();
    _networkService?.stopMonitoring();

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
        'tableExists': await dbHelper.tableExists(),
      };
    } catch (e) {
      return {
        'isRunning': await service.isRunning(),
        'isInitialized': _isInitialized,
        'error': e.toString(),
        'lastSync': prefs.getString('last_sync'),
      };
    }
  }
}