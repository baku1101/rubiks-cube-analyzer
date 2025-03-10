import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/connection_screen.dart';
import 'screens/analysis_screen.dart';
import 'screens/settings_screen.dart';
import 'services/bluetooth_service.dart';
import 'services/cube_connection_service.dart';

class RubiksCubeAnalyzerApp extends StatelessWidget {
  const RubiksCubeAnalyzerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => CubeBluetoothService(),
        ),
        ChangeNotifierProxyProvider<CubeBluetoothService, CubeConnectionService>(
          create: (context) => CubeConnectionService(
            context.read<CubeBluetoothService>(),
          ),
          update: (context, bluetoothService, previous) => 
            previous ?? CubeConnectionService(bluetoothService),
        ),
      ],
      child: MaterialApp(
        title: 'Rubik\'s Cube Analyzer',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          brightness: Brightness.light,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        darkTheme: ThemeData(
          primarySwatch: Colors.blue,
          brightness: Brightness.dark,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
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