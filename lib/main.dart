import 'package:flutter/material.dart';
import 'package:flutter_blue_plus_windows/flutter_blue_plus_windows.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // FlutterBluePlusのログレベルを設定
  try {
    FlutterBluePlus.setLogLevel(LogLevel.verbose, color: true);
    debugPrint('Flutter初期化成功');
  } catch (e) {
    debugPrint('[Bluetooth Debug] FlutterBlue初期化エラー: $e');
  }

  runApp(const App());
}