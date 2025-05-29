import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/network_metrics.dart';
import 'network_service.dart';
import 'location_service.dart';

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  static const String notificationChannelId = 'network_monitor_channel';
  static const String notificationId = 'network_monitor_notification';
  static const int _syncInterval = 15; // minutes
  static Timer? _syncTimer;

  Future<void> initializeService() async {
    final service = FlutterBackgroundService();

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
    service.startService();
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
    DartPluginRegistrant.ensureInitialized();

    final Database db = await _initializeDatabase();
    final NetworkService networkService = NetworkService();
    final LocationService locationService = LocationService();

    // Periodic data collection (every 5 minutes)
    Timer.periodic(const Duration(minutes: 5), (timer) async {
      try {
        final location = await locationService.getCurrentLocation();
        final metrics = await _collectNetworkMetrics(networkService);
        
        await _saveMetricsToLocalStorage(db, metrics, location);
        service.invoke('update_notification', {
          'content': 'Last update: ${DateTime.now().toString().split('.')[0]}',
        });

      } catch (e) {
        print('Error collecting metrics: $e');
      }
    });

    // Periodic sync with remote database (every 15 minutes when online)
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(Duration(minutes: _syncInterval), (timer) async {
      await _syncDataWithRemoteDatabase(db);
    });
  }

  static Future<Database> _initializeDatabase() async {
    return openDatabase(
      join(await getDatabasesPath(), 'network_metrics.db'),
      onCreate: (db, version) {
        return db.execute(
          '''CREATE TABLE network_metrics(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            networkType TEXT,
            signalStrength INTEGER,
            latency REAL,
            jitter REAL,
            downloadSpeed REAL,
            uploadSpeed REAL,
            provider TEXT,
            location TEXT,
            timestamp TEXT,
            synced INTEGER DEFAULT 0
          )''',
        );
      },
      version: 1,
    );
  }

  static Future<NetworkMetrics> _collectNetworkMetrics(NetworkService networkService) async {
    networkService.collectMetrics();
    return await networkService.metricsStream.first;
  }

  static Future<void> _saveMetricsToLocalStorage(
    Database db,
    NetworkMetrics metrics,
    String location,
  ) async {
    await db.insert(
      'network_metrics',
      {
        'networkType': metrics.networkType,
        'signalStrength': metrics.signalStrength,
        'latency': metrics.latency,
        'jitter': metrics.jitter,
        'downloadSpeed': metrics.downloadSpeed,
        'uploadSpeed': metrics.uploadSpeed,
        'provider': metrics.provider,
        'location': location,
        'timestamp': metrics.timestamp.toIso8601String(),
        'synced': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> _syncDataWithRemoteDatabase(Database db) async {
    try {
      // Get unsynced records
      final List<Map<String, dynamic>> unsynced = await db.query(
        'network_metrics',
        where: 'synced = ?',
        whereArgs: [0],
      );

      if (unsynced.isEmpty) return;

      // TODO: Implement your remote database sync logic here
      // For example, using Firebase, REST API, etc.

      // Mark records as synced after successful upload
      await db.update(
        'network_metrics',
        {'synced': 1},
        where: 'synced = ?',
        whereArgs: [0],
      );

      // Save last sync time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_sync', DateTime.now().toIso8601String());

    } catch (e) {
      print('Error syncing data: $e');
    }
  }

  Future<void> stopService() async {
    final service = FlutterBackgroundService();
    _syncTimer?.cancel();
    await service.invoke('stopService');
  }
}