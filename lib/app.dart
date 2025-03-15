
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rubiks_cube_analyzer/services/bluetooth_factory.dart';
import 'package:rubiks_cube_analyzer/services/bluetooth_interface.dart';
import 'services/cube_connection_service.dart';
import 'services/bluetooth_service.dart'; // ← これを忘れずに
import 'screens/home_screen.dart';
import 'screens/connection_screen.dart';
import 'screens/analysis_screen.dart';
import 'screens/settings_screen.dart';

class RubiksCubeAnalyzerApp extends StatelessWidget {
  const RubiksCubeAnalyzerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<BluetoothInterface>(
          create: (_) => BluetoothFactory.getInstance(),
        ),
        ChangeNotifierProvider<CubeConnectionService>(
          create: (_) => CubeConnectionService(),
        ),
      ],
      child: MaterialApp(
        title: 'Rubik\'s Cube Analyzer',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const HomeScreen(),
          '/connect': (context) => const ConnectionScreen(),
          '/analysis': (context) => const AnalysisScreen(),
          '/settings': (context) => const SettingsScreen(),
        },
      ),
    );
  }
}