import 'dart:async';

import 'package:flutter_blue_plus_windows/flutter_blue_plus_windows.dart' as blue;
import 'package:rubiks_cube_analyzer/services/bluetooth/interface/device.dart';
import 'package:rubiks_cube_analyzer/services/bluetooth/interface/service.dart';

/// Windowsプラットフォーム向けのBluetoothサービス実装。
class WindowsBluetoothService implements BluetoothService {
  blue.BluetoothDevice? _connectedDevice;
  StreamSubscription<List<int>>? _dataSubscription;
  final StreamController<List<int>> _dataStreamController =
      StreamController.broadcast();

  @override
  Stream<List<int>> get dataStream => _dataStreamController.stream;

  @override
  Stream<List<BluetoothDevice>> scanDevices() {
    // スキャン結果を変換するためのStreamController
    final StreamController<List<BluetoothDevice>> controller =
        StreamController();

    // FlutterBluePlusのスキャンを開始
    blue.FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    // スキャン結果をリッスンし、変換してコントローラーに追加
    final subscription = blue.FlutterBluePlus.scanResults.listen((results) {
      final devices = results
          .map((result) {
                final remoteIdStr = result.device.remoteId.toString();
                return BluetoothDevice(
                id: remoteIdStr, // id にも remoteId を使う (または適切な一意ID)
                name: result.device.platformName.isNotEmpty
                    ? result.device.platformName
                    : 'Unknown Device',
                remoteId: remoteIdStr, // remoteId を渡す
              );
          })
          .toList();
      controller.add(devices);
    });

    // スキャンが停止したらコントローラーを閉じる
    blue.FlutterBluePlus.isScanning.where((isScanning) => !isScanning).first.then((_) {
      subscription.cancel();
      controller.close();
    });

    return controller.stream;
  }


  @override
  Future<void> connect(BluetoothDevice device) async {
    // FlutterBluePlusのデバイスオブジェクトを取得
    // 注意: この実装はデバイスIDがMACアドレスであることを前提としています。
    //       実際のID形式に合わせて調整が必要な場合があります。
    final targetDevice = await _findDeviceById(device.id);

    if (targetDevice == null) {
      throw Exception('Device not found: ${device.id}');
    }

    try {
      await targetDevice.connect();
      _connectedDevice = targetDevice;
      await _discoverServicesAndSubscribe();
    } catch (e) {
      print('Error connecting to device: $e');
      rethrow;
    }
  }

  Future<blue.BluetoothDevice?> _findDeviceById(String id) async {
     // 現在接続されているデバイスをチェック
    final connected = blue.FlutterBluePlus.connectedDevices;
    for (var d in connected) {
      if (d.remoteId.toString() == id) {
        return d;
      }
    }

    // スキャンしてデバイスを見つける
    blue.FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    await for (var results in blue.FlutterBluePlus.scanResults) {
      for (var result in results) {
        if (result.device.remoteId.toString() == id) {
          blue.FlutterBluePlus.stopScan();
          return result.device;
        }
      }
    }
    blue.FlutterBluePlus.stopScan();
    return null; // 見つからなかった場合
  }


  Future<void> _discoverServicesAndSubscribe() async {
    if (_connectedDevice == null) return;

    final services = await _connectedDevice!.discoverServices();
    for (var service in services) {
      for (var characteristic in service.characteristics) {
        print('Service UUID: ${service.uuid}, Characteristic UUID: ${characteristic.uuid}, Properties: ${characteristic.properties}'); // ログ追加
        // GAN Cube V4 Service UUID: 00000010-0000-fff7-fff6-fff5fff4fff0
        // GAN Cube V4 Read Characteristic UUID: fff6
        // GAN Cube V4 Write Characteristic UUID: fff5
        if (characteristic.uuid.toString() == "fff6") { // Read Characteristic (fff6)
        //final isNotify = characteristic.properties.notify;
        //if (isNotify) {
           // notify可能なキャラクタリスティックが見つかった場合
          if (!characteristic.isNotifying) {
            try {
              await characteristic.setNotifyValue(true);
              _dataSubscription = characteristic.lastValueStream.listen((value) {
                 _dataStreamController.add(value);
              });
              print('Subscribed to characteristic: ${characteristic.uuid}');
              // 最初のNotify可能なキャラクタリスティックにのみ登録する場合
               return;
            } catch (e) {
              print('Error setting notify value for ${characteristic.uuid}: $e');
            }
          }
        //}
        }
      }
    }
     print('No suitable characteristic found for notification.');
  }

  @override
  Future<void> disconnect() async {
    await _dataSubscription?.cancel();
    _dataSubscription = null;
    await _connectedDevice?.disconnect();
    _connectedDevice = null;
    print('Disconnected from device.');
  }

  @override
  Future<void> writeData(List<int> data) async {
    if (_connectedDevice == null) {
      throw Exception('Not connected to any device.');
    }

    final services = await _connectedDevice!.discoverServices();
     for (var service in services) {
      for (var characteristic in service.characteristics) {
         // GAN Cube V4 Write Characteristic UUID: fff5
        if (characteristic.uuid.toString() == "fff5") { // Write Characteristic (fff5)
          print('Found Write Characteristic: ${characteristic.uuid}'); // ログ追加
        final canWrite = characteristic.properties.write || characteristic.properties.writeWithoutResponse;
        if (canWrite) {
          try {
            await characteristic.write(data, withoutResponse: characteristic.properties.writeWithoutResponse);
             print('Data written to ${characteristic.uuid}');
            // 最初の書き込み可能なキャラクタリスティックに書き込んだら終了
            return;
          } catch (e) {
             print('Error writing data to ${characteristic.uuid}: $e');
             // 次の書き込み可能なキャラクタリスティックを試す
          }
        }
        }
      }
    }
     throw Exception('No suitable characteristic found for writing.');
  }
}