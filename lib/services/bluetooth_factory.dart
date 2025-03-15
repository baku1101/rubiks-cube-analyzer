import 'package:flutter/foundation.dart';
import 'bluetooth_interface.dart';
import 'web_bluetooth_service.dart';
import 'windows_bluetooth_service.dart';

/// Bluetoothサービスのファクトリクラス
class BluetoothFactory {
  static BluetoothInterface? _instance;

  /// プラットフォームに応じたBluetoothサービスのインスタンスを取得
  static BluetoothInterface getInstance() {
    _instance ??= _createService();
    return _instance!;
  }

  /// プラットフォームに応じたサービスを作成
  static BluetoothInterface _createService() {
    if (kIsWeb) {
      return WebBluetoothService();
    } else if (defaultTargetPlatform == TargetPlatform.windows) {
      return WindowsBluetoothService();
    } else {
      throw UnsupportedError('This platform is not supported');
    }
  }

  /// プラットフォームに応じたBluetoothサービスが利用可能かどうかを確認
  static Future<bool> isSupported() async {
    try {
      if (kIsWeb) {
        return await WebBluetoothService.isSupported();
      } else if (defaultTargetPlatform == TargetPlatform.windows) {
        return await WindowsBluetoothService.isSupported();
      }
      return false;
    } catch (e) {
      debugPrint('Bluetoothサポートチェックエラー: $e');
      return false;
    }
  }

  /// シングルトンインスタンスをクリア（主にテスト用）
  static void reset() {
    _instance = null;
  }
}