import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus_windows/flutter_blue_plus_windows.dart' as fbpw;
import 'package:flutter_web_bluetooth/flutter_web_bluetooth.dart';

/// Bluetoothデバイスのプラットフォーム種別
enum BluetoothPlatform {
  web,
  windows,
  unknown,
}

/// Bluetoothデバイス情報を管理するモデル
class BluetoothDeviceInfo {
  final String id;
  final String name;
  final int rssi;
  final dynamic nativeDevice;
  final BluetoothPlatform platform;

  const BluetoothDeviceInfo({
    required this.id,
    required this.name,
    required this.rssi,
    required this.nativeDevice,
    this.platform = BluetoothPlatform.unknown,
  });

  /// Windows用デバイスからインスタンスを生成
  factory BluetoothDeviceInfo.fromWindowsDevice(fbpw.ScanResult scanResult) {
    final device = scanResult.device;
    debugPrint('Windows用デバイス生成: ${device.id}, type: ${device.runtimeType}');
    debugPrint('デバイス情報: name=${device.name}, properties=${device.services}');

    final info = BluetoothDeviceInfo(
      id: device.id.id,
      name: device.name,
      rssi: scanResult.rssi,
      nativeDevice: device,
      platform: BluetoothPlatform.windows,
    );

    debugPrint('生成されたデバイス情報: ${info.toDebugMap()}');
    return info;
  }

  /// Windows用デバイスを直接指定してインスタンスを生成
  factory BluetoothDeviceInfo.fromWindowsDeviceDirect(fbpw.BluetoothDevice device, {int rssi = -1}) {
    debugPrint('Windows用デバイス直接生成: ${device.id}, type: ${device.runtimeType}');
    return BluetoothDeviceInfo(
      id: device.id.id,
      name: device.name,
      rssi: rssi,
      nativeDevice: device,
      platform: BluetoothPlatform.windows,
    );
  }

  /// Web用デバイスからインスタンスを生成
  factory BluetoothDeviceInfo.fromWebDevice(BluetoothDevice device) {
    return BluetoothDeviceInfo(
      id: device.id,
      name: device.name ?? 'Unknown Device',
      rssi: -1, // Web Bluetooth APIではRSSIを取得できない
      nativeDevice: device,
      platform: BluetoothPlatform.web,
    );
  }

  /// プラットフォーム固有のデバイスクラスを取得
  T? getPlatformDevice<T>() {
    if (nativeDevice is T) {
      return nativeDevice as T;
    }
    return null;
  }

  /// Windowsデバイスとして取得
  fbpw.BluetoothDevice? get asWindowsDevice {
    if (platform == BluetoothPlatform.windows) {
      debugPrint('Windows用デバイスを取得: type=${nativeDevice.runtimeType}');
      if (nativeDevice is fbpw.BluetoothDevice) {
        return nativeDevice as fbpw.BluetoothDevice;
      }
      debugPrint('無効なWindowsデバイス型: ${nativeDevice.runtimeType}');
    }
    return null;
  }

  /// Webデバイスとして取得
  BluetoothDevice? get asWebDevice {
    return platform == BluetoothPlatform.web
        ? nativeDevice as BluetoothDevice
        : null;
  }

  /// デバッグ情報の取得
  Map<String, dynamic> toDebugMap() {
    return {
      'id': id,
      'name': name,
      'rssi': rssi,
      'platform': platform.toString(),
      'nativeDeviceType': nativeDevice.runtimeType.toString(),
      'nativeDeviceHashCode': nativeDevice.hashCode,
    };
  }

  /// プラットフォーム固有のデータ書き込みメソッド
  Future<bool> writeData(String serviceUuid, String characteristicUuid, List<int> data) async {
    try {
      if (platform == BluetoothPlatform.web) {
        final webDevice = asWebDevice;
        if (webDevice != null) {
          // Web用の実装
          final requestDevice = await FlutterWebBluetooth.instance.requestDevice(
            RequestOptionsBuilder.acceptAllDevices(
              optionalServices: [serviceUuid],
            ),
          );

          // GATTサーバーに接続
          final server = requestDevice.gatt;
          if (server == null) return false;

          // サービスを取得
          final service = await server.getPrimaryService(serviceUuid);

          // キャラクタリスティックを取得して書き込み
          final characteristic = await service.getCharacteristic(characteristicUuid);

          await characteristic.writeValue(Uint8List.fromList(data));
          return true;
        }
      } else if (platform == BluetoothPlatform.windows) {
        final windowsDevice = asWindowsDevice;
        if (windowsDevice != null) {
          debugPrint('Windows用デバイス書き込み: $windowsDevice');
          // TODO: Windows用の書き込み処理を実装
          return false;
        }
      }
      return false;
    } catch (e) {
      debugPrint('データ書き込みエラー: $e');
      return false;
    }
  }

  @override
  String toString() {
    return 'BluetoothDeviceInfo(id: $id, name: $name, rssi: $rssi, platform: $platform)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BluetoothDeviceInfo && 
           other.id == id && 
           other.platform == platform;
  }

  @override
  int get hashCode => Object.hash(id, platform);

  BluetoothDeviceInfo copyWith({
    String? id,
    String? name,
    int? rssi,
    dynamic nativeDevice,
    BluetoothPlatform? platform,
  }) {
    return BluetoothDeviceInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      rssi: rssi ?? this.rssi,
      nativeDevice: nativeDevice ?? this.nativeDevice,
      platform: platform ?? this.platform,
    );
  }
}