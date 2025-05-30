import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_helper.dart';

class ViewLogsScreen extends StatefulWidget {
  const ViewLogsScreen({super.key});

  @override
  _ViewLogsScreenState createState() => _ViewLogsScreenState();
}

class _ViewLogsScreenState extends State<ViewLogsScreen> {
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Check if table exists first
      final dbHelper = DatabaseHelper.instance;
      final tableExists = await dbHelper.tableExists();
      print('Table exists: $tableExists');

      // Get all metrics
      final logs = await dbHelper.getAllMetrics();
      print('Loaded ${logs.length} logs');

      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading logs: $e';
      });
      print('Error loading logs: $e');
    }
  }

  Future<void> _insertTestData() async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final db = await dbHelper.database;
      
      // Insert multiple test records
      for (int i = 0; i < 3; i++) {
        await db.insert('network_metrics', {
          'networkType': i == 0 ? 'WiFi' : i == 1 ? '4G' : '5G',
          'signalStrength': -50 - (i * 10),
          'latency': 25.0 + (i * 5),
          'jitter': 2.0 + i,
          'downloadSpeed': 100.0 - (i * 20),
          'uploadSpeed': 50.0 - (i * 10),
          'provider': 'Provider ${i + 1}',
          'location': 'Location ${i + 1}',
          'timestamp': DateTime.now().subtract(Duration(minutes: i * 30)).toIso8601String(),
          'synced': 0,
        });
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test data inserted successfully')),
      );
      
      _loadLogs();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error inserting test data: $e')),
      );
    }
  }

  Future<void> _clearAllData() async {
    try {
      final dbHelper = DatabaseHelper.instance;
      await dbHelper.clearAllData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All data cleared successfully')),
      );
      
      _loadLogs();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error clearing data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Network Logs',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              switch (value) {
                case 'refresh':
                  _loadLogs();
                  break;
                case 'test_data':
                  _insertTestData();
                  break;
                case 'clear_data':
                  _showClearDataDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('Refresh'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'test_data',
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline),
                    SizedBox(width: 8),
                    Text('Add Test Data'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_data',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Clear All Data', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6C63FF),
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.withOpacity(0.7),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error Loading Logs',
                        style: TextStyle(
                          color: Colors.red.withOpacity(0.9),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: _loadLogs,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C63FF),
                            ),
                            child: const Text('Retry'),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: _insertTestData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            child: const Text('Add Test Data'),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              : _logs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 64,
                            color: Colors.white.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No logs available yet',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Network monitoring will start collecting data in the background',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _insertTestData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C63FF),
                            ),
                            child: const Text('Add Test Data'),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E3F),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF6C63FF).withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Logs: ${_logs.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Last Updated: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _logs.length,
                            itemBuilder: (context, index) {
                              final log = _logs[index];
                              final timestamp = DateTime.parse(log['timestamp']);
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E1E3F),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF6C63FF).withOpacity(0.3),
                                  ),
                                ),
                                child: ExpansionTile(
                                  title: Text(
                                    DateFormat('MMM dd, yyyy HH:mm').format(timestamp),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    log['location'] ?? 'Unknown location',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                  ),
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6C63FF).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.network_check,
                                      color: const Color(0xFF6C63FF),
                                      size: 24,
                                    ),
                                  ),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        children: [
                                          _buildMetricRow(
                                            'Network Type',
                                            log['networkType'] ?? 'Unknown',
                                            Icons.cell_tower,
                                          ),
                                          _buildMetricRow(
                                            'Provider',
                                            log['provider'] ?? 'Unknown',
                                            Icons.business,
                                          ),
                                          _buildMetricRow(
                                            'Signal Strength',
                                            '${log['signalStrength'] ?? 0} dBm',
                                            Icons.signal_cellular_alt,
                                          ),
                                          _buildMetricRow(
                                            'Latency',
                                            '${(log['latency'] ?? 0.0).toStringAsFixed(2)} ms',
                                            Icons.timer,
                                          ),
                                          _buildMetricRow(
                                            'Jitter',
                                            '${(log['jitter'] ?? 0.0).toStringAsFixed(2)} ms',
                                            Icons.waves,
                                          ),
                                          _buildMetricRow(
                                            'Download Speed',
                                            '${(log['downloadSpeed'] ?? 0.0).toStringAsFixed(2)} Mbps',
                                            Icons.download,
                                          ),
                                          _buildMetricRow(
                                            'Upload Speed',
                                            '${(log['uploadSpeed'] ?? 0.0).toStringAsFixed(2)} Mbps',
                                            Icons.upload,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E3F),
        title: const Text('Clear All Data', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to clear all network logs? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearAllData();
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: const Color(0xFF6C63FF),
          ),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}