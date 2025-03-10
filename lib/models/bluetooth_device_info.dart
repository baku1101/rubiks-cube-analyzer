import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as FlutterBluePlus;
import 'package:flutter_blue_plus_windows/flutter_blue_plus_windows.dart' as FlutterBluePlusWindows;

class BluetoothDeviceInfo {
  final String name;
  final String id;
  final dynamic nativeDevice; // WindowsまたはAndroid/iOSのデバイスオブジェクト
  final int rssi;

  BluetoothDeviceInfo({
    required this.name,
    required this.id,
    required this.nativeDevice,
    required this.rssi,
  });

  bool get isConnectable => true;

  // プラットフォーム固有のデバイスオブジェクトを取得
  T getNativeDevice<T>() {
    if (T == FlutterBluePlusWindows.BluetoothDevice && Platform.isWindows) {
      return nativeDevice as T;
    } else if (T == FlutterBluePlus.BluetoothDevice && !Platform.isWindows) {
      return nativeDevice as T;
    }
    throw UnsupportedError('Unsupported platform or device type');
  }

  // ファクトリーメソッド - Windows用デバイス作成
  factory BluetoothDeviceInfo.fromWindowsDevice(FlutterBluePlusWindows.ScanResult result) {
    return BluetoothDeviceInfo(
      name: result.device.platformName,
      id: result.device.remoteId.str,
      nativeDevice: result.device,
      rssi: result.rssi,
    );
  }

  // ファクトリーメソッド - Android/iOS用デバイス作成
  factory BluetoothDeviceInfo.fromMobileDevice(FlutterBluePlus.ScanResult result) {
    return BluetoothDeviceInfo(
      name: result.device.platformName,
      id: result.device.remoteId.str,
      nativeDevice: result.device,
      rssi: result.rssi,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BluetoothDeviceInfo && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'BluetoothDeviceInfo(name: $name, id: $id, rssi: $rssi)';
}