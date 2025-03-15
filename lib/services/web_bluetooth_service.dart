import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_web_bluetooth/flutter_web_bluetooth.dart';
import '../models/bluetooth_device_info.dart';
import '../models/move.dart';
import 'bluetooth_interface.dart';

/// Web版Bluetooth実装
class WebBluetoothService extends ChangeNotifier implements BluetoothInterface {
  bool _isConnected = false;
  bool _isScanning = false;
  BluetoothDevice? _device;
  BluetoothDeviceInfo? _connectedDevice;
  final List<BluetoothDeviceInfo> _scanResults = [];
  StreamController<List<BluetoothDeviceInfo>>? _scanController;
  StreamSubscription? _valueSubscription;

  @override
  bool get isConnected => _isConnected;

  @override
  bool get isScanning => _isScanning;

  @override
  List<BluetoothDeviceInfo> get scanResults => List.unmodifiable(_scanResults);

  @override
  BluetoothDeviceInfo? get connectedDevice => _connectedDevice;

  /// Web Bluetooth APIがサポートされているかチェック
  static Future<bool> isSupported() async {
    try {
      final supported = await FlutterWebBluetooth.instance.isAvailable.first;
      return supported;
    } catch (e) {
      debugPrint('Web Bluetooth API サポートチェックエラー: $e');
      return false;
    }
  }

  @override
  Future<bool> connectToDevice(BluetoothDeviceInfo device) async {
    try {
      _device = device.nativeDevice as BluetoothDevice?;
      
      if (_device == null) {
        debugPrint('デバイスが無効です');
        return false;
      }

      debugPrint('デバイスに接続します: ${_device!.id}');
      
      _isConnected = true;
      _connectedDevice = device;
      notifyListeners();

      debugPrint('デバイスに接続しました');
      return true;
    } catch (e) {
      debugPrint('Bluetooth接続エラー: $e');
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    _valueSubscription?.cancel();
    _valueSubscription = null;

    _isConnected = false;
    _connectedDevice = null;
    _device = null;
    notifyListeners();
    debugPrint('デバイスを切断しました');
  }

  @override
  Future<BluetoothService?> discoverService(dynamic device, String serviceUuid) async {
    try {
      debugPrint('サービスを探索します: $serviceUuid');

      final requestOptions = RequestOptionsBuilder.acceptAllDevices(
        optionalServices: [serviceUuid],
      );

      final selectedDevice = await FlutterWebBluetooth.instance.requestDevice(requestOptions);
      if (selectedDevice == null) {
        debugPrint('デバイスが選択されませんでした');
        return null;
      }

      debugPrint('サービスを探索しました');
      return selectedDevice as BluetoothService;
    } catch (e) {
      debugPrint('サービス探索エラー: $e');
      return null;
    }
  }

  @override
  Stream<List<int>>? subscribeToCharacteristic(
    dynamic service,
    String characteristicUuid,
  ) {
    try {
      if (service is! BluetoothService) {
        return null;
      }

      final controller = StreamController<List<int>>();

      service.getCharacteristic(characteristicUuid).then((characteristic) async {
        if (characteristic != null) {
          debugPrint('通知を開始します: $characteristicUuid');
          await characteristic.startNotifications();
          
          final valueStream = characteristic.value;
          if (valueStream != null) {
            _valueSubscription = valueStream.listen(
              (value) {
                if (value != null) {
                  try {
                    final bytes = _convertToBytes(value);
                    controller.add(bytes);
                    debugPrint('データを受信しました: ${bytes.length} bytes');
                  } catch (e) {
                    debugPrint('データ変換エラー: $e');
                    controller.addError(e);
                  }
                }
              },
              onError: (e) {
                debugPrint('通知エラー: $e');
                controller.addError(e);
              },
            );
          }
        }
      }).catchError((e) {
        debugPrint('キャラクタリスティック取得エラー: $e');
        controller.addError(e);
      });

      return controller.stream;
    } catch (e) {
      debugPrint('通知の購読エラー: $e');
      return null;
    }
  }

  @override
  Future<bool> writeCharacteristic(
    dynamic service,
    String characteristicUuid,
    List<int> value,
  ) async {
    try {
      if (service is! BluetoothService) {
        return false;
      }

      final characteristic = await service.getCharacteristic(characteristicUuid);
      if (characteristic != null) {
        final data = value is Uint8List ? value : Uint8List.fromList(value);
        await characteristic.writeValueWithResponse(data);
        debugPrint('データを送信しました: ${data.length} bytes');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('書き込みエラー: $e');
      return false;
    }
  }

  @override
  Future<void> startScan() async {
    if (_isScanning) {
      await stopScan();
    }

    _isScanning = true;
    _scanResults.clear();
    _scanController = StreamController<List<BluetoothDeviceInfo>>();
    notifyListeners();

    try {
      debugPrint('デバイスのスキャンを開始します');
      final device = await FlutterWebBluetooth.instance.requestDevice(
        RequestOptionsBuilder.acceptAllDevices(
          optionalServices: [BluetoothInterface.GAN_SERVICE_UUID],
        ),
      );

      if (device != null) {
        final deviceInfo = BluetoothDeviceInfo(
          id: device.id,
          name: device.name ?? 'Unknown Device',
          rssi: -1,
          nativeDevice: device,
          platform: BluetoothPlatform.web,
        );
        _scanResults.add(deviceInfo);
        _scanController?.add(_scanResults);
        debugPrint('デバイスを発見しました: ${device.id}');
      }
    } catch (error) {
      debugPrint('スキャンエラー: $error');
      _scanController?.addError(error);
    } finally {
      await stopScan();
    }
  }

  @override
  Future<void> stopScan() async {
    _isScanning = false;
    await _scanController?.close();
    _scanController = null;
    notifyListeners();
    debugPrint('スキャンを停止しました');
  }

  @override
  dynamic getNativeDevice(BluetoothDeviceInfo device) {
    return device.asWebDevice;
  }

  List<int> _convertToBytes(dynamic value) {
    if (value is ByteData) {
      return value.buffer.asUint8List();
    } else if (value is TypedData) {
      return Uint8List.view(value.buffer);
    } else if (value is List<int>) {
      return value;
    }
    throw Exception('Unsupported data type: ${value.runtimeType}');
  }

  @override
  List<int> createV4Command(int command, [List<int>? data]) {
    final packet = [...BluetoothInterface.V4_PREFIX];
    packet[1] = command;
    if (data != null) {
      packet.addAll(data);
    }
    return packet;
  }

  @override
  List<int> createBatteryCommand() {
    return createV4Command(BluetoothInterface.V4_GET_BATTERY);
  }

  @override
  List<int> createCubeStateCommand() {
    return createV4Command(BluetoothInterface.V4_FACE_STATUS);
  }

  @override
  List<int> createScrambleCommand(List<Move> moves) {
    final moveData = <int>[];
    
    // スクランブルムーブをV4形式に変換
    for (final move in moves) {
      final moveCode = _getMoveCode(move.type);
      if (moveCode != null) {
        moveData.add(moveCode);
      }
    }

    return createV4Command(BluetoothInterface.V4_DO_MOVES, moveData);
  }

  /// MoveTypeをV4のムーブコードに変換
  int? _getMoveCode(MoveType type) {
    // GAN V4のムーブコード形式に変換
    // 0: U, 1: U', 2: U2, 3: D, 4: D', 5: D2, ...
    switch (type) {
      case MoveType.U: return 0x00;
      case MoveType.UPrime: return 0x01;
      case MoveType.U2: return 0x02;
      case MoveType.D: return 0x03;
      case MoveType.DPrime: return 0x04;
      case MoveType.D2: return 0x05;
      case MoveType.R: return 0x06;
      case MoveType.RPrime: return 0x07;
      case MoveType.R2: return 0x08;
      case MoveType.L: return 0x09;
      case MoveType.LPrime: return 0x0A;
      case MoveType.L2: return 0x0B;
      case MoveType.F: return 0x0C;
      case MoveType.FPrime: return 0x0D;
      case MoveType.F2: return 0x0E;
      case MoveType.B: return 0x0F;
      case MoveType.BPrime: return 0x10;
      case MoveType.B2: return 0x11;
    }
  }

  @override
  void dispose() {
    _valueSubscription?.cancel();
    stopScan();
    disconnect();
    super.dispose();
  }
}