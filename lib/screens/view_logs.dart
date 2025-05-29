import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';

class ViewLogsScreen extends StatefulWidget {
  const ViewLogsScreen({super.key});

  @override
  _ViewLogsScreenState createState() => _ViewLogsScreenState();
}

class _ViewLogsScreenState extends State<ViewLogsScreen> {
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final Database db = await openDatabase(
      join(await getDatabasesPath(), 'network_metrics.db'),
      version: 1,
    );

    final List<Map<String, dynamic>> logs = await db.query(
      'network_metrics',
      orderBy: 'timestamp DESC',
    );

    setState(() {
      _logs = logs;
      _isLoading = false;
    });
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
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadLogs();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6C63FF),
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
                                log['location'],
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
                                        log['networkType'],
                                        Icons.cell_tower,
                                      ),
                                      _buildMetricRow(
                                        'Provider',
                                        log['provider'],
                                        Icons.business,
                                      ),
                                      _buildMetricRow(
                                        'Signal Strength',
                                        '${log['signalStrength']} dBm',
                                        Icons.signal_cellular_alt,
                                      ),
                                      _buildMetricRow(
                                        'Latency',
                                        '${log['latency'].toStringAsFixed(2)} ms',
                                        Icons.timer,
                                      ),
                                      _buildMetricRow(
                                        'Jitter',
                                        '${log['jitter'].toStringAsFixed(2)} ms',
                                        Icons.waves,
                                      ),
                                      _buildMetricRow(
                                        'Download Speed',
                                        '${log['downloadSpeed'].toStringAsFixed(2)} Mbps',
                                        Icons.download,
                                      ),
                                      _buildMetricRow(
                                        'Upload Speed',
                                        '${log['uploadSpeed'].toStringAsFixed(2)} Mbps',
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
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}