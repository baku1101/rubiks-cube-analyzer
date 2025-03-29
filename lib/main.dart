import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rubiks_cube_analyzer/services/bluetooth/interface/service.dart';
import 'package:rubiks_cube_analyzer/services/bluetooth/windows/service.dart';
import 'package:rubiks_cube_analyzer/ui/debug/debug_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Provider<BluetoothService>(
      create: (_) => WindowsBluetoothService(), // BluetoothService のインスタンスを提供
      child: MaterialApp(
        title: 'Rubik\'s Cube Analyzer',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const DebugScreen(), // デバッグ画面をホームに設定
      ),
    );
  }
}