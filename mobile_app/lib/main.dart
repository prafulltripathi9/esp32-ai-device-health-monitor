import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/device_provider.dart';
import 'screens/app_shell.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => DeviceProvider(),
        ),
      ],
      child: const ESP32HealthMonitorApp(),
    ),
  );
}

class ESP32HealthMonitorApp extends StatelessWidget {
  const ESP32HealthMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ESP32 AI Device Health Monitor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AppShell(),
    );
  }
}