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
      onConfigure: _onConfigure,
    );
  }

  // Configure database (needed for foreign keys and other settings)
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  // Create table
  Future<void> _onCreate(Database db, int version) async {
    print('Creating network_metrics table...');
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        networkType TEXT NOT NULL,
        signalStrength INTEGER NOT NULL,
        latency REAL NOT NULL,
        jitter REAL NOT NULL,
        downloadSpeed REAL NOT NULL,
        uploadSpeed REAL NOT NULL,
        provider TEXT NOT NULL,
        location TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        synced INTEGER DEFAULT 0
      )
    ''');
    
    print('Table created successfully');
  }

  // Check if table exists
  Future<bool> tableExists() async {
    final db = await database;
    
    try {
      final tables = await db.query(
        'sqlite_master',
        where: 'type = ? AND name = ?',
        whereArgs: ['table', _tableName],
      );
      return tables.isNotEmpty;
    } catch (e) {
      print('Error checking table existence: $e');
      return false;
    }
  }

  // Insert network metrics
  Future<int> insertMetrics(NetworkMetrics metrics, String location) async {
    final db = await database;
    
    final data = {
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
    };
    
    try {
      final id = await db.insert(_tableName, data);
      print('Inserted metrics with ID: $id');
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
      print('Retrieved ${result.length} metrics');
      return result;
    } catch (e) {
      print('Error getting metrics: $e');
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
      rethrow;
    }
  }

  // Get unsynced metrics
  Future<List<Map<String, dynamic>>> getUnsyncedMetrics() async {
    final db = await database;
    
    try {
      return await db.query(
        _tableName,
        where: 'synced = ?',
        whereArgs: [0],
      );
    } catch (e) {
      print('Error getting unsynced metrics: $e');
      rethrow;
    }
  }

  // Mark all unsynced as synced
  Future<int> markAllUnsyncedAsSynced() async {
    final db = await database;
    
    try {
      return await db.update(
        _tableName,
        {'synced': 1},
        where: 'synced = ?',
        whereArgs: [0],
      );
    } catch (e) {
      print('Error marking metrics as synced: $e');
      rethrow;
    }
  }

  // Clear all data
  Future<void> clearAllData() async {
    final db = await database;
    
    try {
      await db.delete(_tableName);
      print('All data cleared');
    } catch (e) {
      print('Error clearing data: $e');
      rethrow;
    }
  }
}