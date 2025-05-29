import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BackgroundService().initializeService();
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