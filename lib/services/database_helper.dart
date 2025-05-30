import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/network_metrics.dart';

class DatabaseHelper {
  static const _databaseName = 'network_metrics.db';
  static const _databaseVersion = 1;
  static const _tableName = 'network_metrics';

  static Database? _database;

  // Singleton pattern
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize database
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);
    
    print('Database path: $path');
    
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) {
        print('Database opened successfully');
      },
    );
  }

  // Create table
  Future<void> _onCreate(Database db, int version) async {
    print('Creating network_metrics table...');
    
    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        networkType TEXT NOT NULL,
        signalStrength INTEGER,
        latency REAL,
        jitter REAL,
        downloadSpeed REAL,
        uploadSpeed REAL,
        provider TEXT,
        location TEXT,
        timestamp TEXT NOT NULL,
        synced INTEGER DEFAULT 0
      )
    ''');
    
    print('Table created successfully');
    
    // Insert a test record to verify table creation
    await _insertTestRecord(db);
  }

  // Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('Upgrading database from version $oldVersion to $newVersion');
    // Handle database schema changes here if needed
  }

  // Insert test record
  Future<void> _insertTestRecord(Database db) async {
    try {
      final testRecord = {
        'networkType': 'Test',
        'signalStrength': -50,
        'latency': 25.0,
        'jitter': 2.0,
        'downloadSpeed': 100.0,
        'uploadSpeed': 50.0,
        'provider': 'Test Provider',
        'location': 'Test Location',
        'timestamp': DateTime.now().toIso8601String(),
        'synced': 0,
      };
      
      final id = await db.insert(_tableName, testRecord);
      print('Test record inserted with ID: $id');
    } catch (e) {
      print('Error inserting test record: $e');
    }
  }

  // Insert network metrics - improved version with better location handling
  Future<int> insertMetrics(NetworkMetrics metrics, [dynamic location]) async {
    final db = await database;
    
    // Handle different location formats
    String locationString = 'Unknown';
    if (location != null) {
      if (location is Map<String, double>) {
        if (location.containsKey('latitude') && location.containsKey('longitude')) {
          locationString = '${location['latitude']!.toStringAsFixed(6)},${location['longitude']!.toStringAsFixed(6)}';
        }
      } else if (location is String && location.isNotEmpty) {
        locationString = location;
      }
    }
    
    final data = {
      'networkType': metrics.networkType,
      'signalStrength': metrics.signalStrength,
      'latency': metrics.latency,
      'jitter': metrics.jitter,
      'downloadSpeed': metrics.downloadSpeed,
      'uploadSpeed': metrics.uploadSpeed,
      'provider': metrics.provider,
      'location': locationString,
      'timestamp': metrics.timestamp.toIso8601String(),
      'synced': 0,
    };
    
    try {
      final id = await db.insert(_tableName, data, conflictAlgorithm: ConflictAlgorithm.replace);
      print('Metrics inserted with ID: $id (Location: $locationString)');
      return id;
    } catch (e) {
      print('Error inserting metrics: $e');
      rethrow;
    }
  }

  // Get all metrics
  Future<List<Map<String, dynamic>>> getAllMetrics() async {
    final db = await database;
    
    try {
      final result = await db.query(
        _tableName,
        orderBy: 'timestamp DESC',
      );
      print('Retrieved ${result.length} metrics records');
      return result;
    } catch (e) {
      print('Error retrieving metrics: $e');
      rethrow;
    }
  }

  // Get recent metrics with limit
  Future<List<Map<String, dynamic>>> getRecentMetrics({int limit = 50}) async {
    final db = await database;
    
    try {
      final result = await db.query(
        _tableName,
        orderBy: 'timestamp DESC',
        limit: limit,
      );
      print('Retrieved ${result.length} recent metrics records');
      return result;
    } catch (e) {
      print('Error retrieving recent metrics: $e');
      rethrow;
    }
  }

  // Get unsynced metrics
  Future<List<Map<String, dynamic>>> getUnsyncedMetrics() async {
    final db = await database;
    
    try {
      final result = await db.query(
        _tableName,
        where: 'synced = ?',
        whereArgs: [0],
        orderBy: 'timestamp ASC',
      );
      print('Retrieved ${result.length} unsynced records');
      return result;
    } catch (e) {
      print('Error retrieving unsynced metrics: $e');
      rethrow;
    }
  }

  // Mark records as synced
  Future<int> markAsSynced(List<int> ids) async {
    final db = await database;
    
    if (ids.isEmpty) {
      print('No IDs provided to mark as synced');
      return 0;
    }
    
    try {
      final batch = db.batch();
      for (final id in ids) {
        batch.update(
          _tableName,
          {'synced': 1},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
      
      final results = await batch.commit();
      final updatedCount = results.length;
      print('Marked $updatedCount records as synced');
      return updatedCount;
    } catch (e) {
      print('Error marking records as synced: $e');
      rethrow;
    }
  }

  // Mark all unsynced records as synced
  Future<int> markAllUnsyncedAsSynced() async {
    final db = await database;
    
    try {
      final updatedCount = await db.update(
        _tableName,
        {'synced': 1},
        where: 'synced = ?',
        whereArgs: [0],
      );
      print('Marked $updatedCount records as synced');
      return updatedCount;
    } catch (e) {
      print('Error marking all records as synced: $e');
      rethrow;
    }
  }

  // Get metrics count
  Future<int> getMetricsCount() async {
    final db = await database;
    
    try {
      final result = await db.rawQuery('SELECT COUNT(*) FROM $_tableName');
      final count = Sqflite.firstIntValue(result) ?? 0;
      print('Total metrics count: $count');
      return count;
    } catch (e) {
      print('Error getting metrics count: $e');
      return 0;
    }
  }

  // Get synced metrics count
  Future<int> getSyncedMetricsCount() async {
    final db = await database;
    
    try {
      final result = await db.rawQuery('SELECT COUNT(*) FROM $_tableName WHERE synced = 1');
      final count = Sqflite.firstIntValue(result) ?? 0;
      print('Synced metrics count: $count');
      return count;
    } catch (e) {
      print('Error getting synced metrics count: $e');
      return 0;
    }
  }

  // Get unsynced metrics count
  Future<int> getUnsyncedMetricsCount() async {
    final db = await database;
    
    try {
      final result = await db.rawQuery('SELECT COUNT(*) FROM $_tableName WHERE synced = 0');
      final count = Sqflite.firstIntValue(result) ?? 0;
      print('Unsynced metrics count: $count');
      return count;
    } catch (e) {
      print('Error getting unsynced metrics count: $e');
      return 0;
    }
  }

  // Clear all data (for debugging)
  Future<void> clearAllData() async {
    final db = await database;
    
    try {
      final deletedCount = await db.delete(_tableName);
      print('Deleted $deletedCount records');
    } catch (e) {
      print('Error clearing data: $e');
      rethrow;
    }
  }

  // Clear old synced data (keep only recent records)
  Future<int> clearOldSyncedData({int keepRecentDays = 7}) async {
    final db = await database;
    
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: keepRecentDays));
      final deletedCount = await db.delete(
        _tableName,
        where: 'synced = 1 AND timestamp < ?',
        whereArgs: [cutoffDate.toIso8601String()],
      );
      print('Deleted $deletedCount old synced records (older than $keepRecentDays days)');
      return deletedCount;
    } catch (e) {
      print('Error clearing old synced data: $e');
      rethrow;
    }
  }

  // Check if table exists
  Future<bool> tableExists() async {
    final db = await database;
    
    try {
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='$_tableName'"
      );
      final exists = result.isNotEmpty;
      print('Table exists: $exists');
      return exists;
    } catch (e) {
      print('Error checking table existence: $e');
      return false;
    }
  }

  // Get database statistics
  Future<Map<String, dynamic>> getDatabaseStats() async {
    try {
      final totalCount = await getMetricsCount();
      final syncedCount = await getSyncedMetricsCount();
      final unsyncedCount = await getUnsyncedMetricsCount();
      
      final db = await database;
      final oldestRecord = await db.query(
        _tableName,
        orderBy: 'timestamp ASC',
        limit: 1,
      );
      
      final newestRecord = await db.query(
        _tableName,
        orderBy: 'timestamp DESC',
        limit: 1,
      );
      
      return {
        'totalCount': totalCount,
        'syncedCount': syncedCount,
        'unsyncedCount': unsyncedCount,
        'syncPercentage': totalCount > 0 ? (syncedCount / totalCount * 100).toStringAsFixed(1) : '0.0',
        'oldestRecord': oldestRecord.isNotEmpty ? oldestRecord.first['timestamp'] : null,
        'newestRecord': newestRecord.isNotEmpty ? newestRecord.first['timestamp'] : null,
        'tableExists': await tableExists(),
      };
    } catch (e) {
      print('Error getting database stats: $e');
      return {
        'error': e.toString(),
        'totalCount': 0,
        'syncedCount': 0,
        'unsyncedCount': 0,
      };
    }
  }

  // Close database
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
      print('Database closed');
    }
  }

  // Reset database (for debugging/testing)
  Future<void> resetDatabase() async {
    try {
      await close();
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, _databaseName);
      await deleteDatabase(path);
      print('Database reset successfully');
    } catch (e) {
      print('Error resetting database: $e');
      rethrow;
    }
  }
}