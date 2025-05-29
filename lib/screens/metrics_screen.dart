import 'package:flutter/material.dart';

class MetricsScreen extends StatelessWidget {
  const MetricsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Metrics'),
      ),
      body: const Center(
        child: Text('Metrics Screen - Placeholder'),
      ),
    );
  }
}