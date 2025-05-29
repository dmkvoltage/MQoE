import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(NetworkMonitorApp());
}

class NetworkMonitorApp extends StatelessWidget {
  const NetworkMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Network Monitor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomeScreen(),
    );
  }
}