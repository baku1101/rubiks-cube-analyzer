import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus_windows/flutter_blue_plus_windows.dart' as fbpw;
import '../models/bluetooth_device_info.dart';
import '../models/move.dart';
import 'bluetooth_interface.dart';

/// Windows版Bluetooth実装
class WindowsBluetoothService extends ChangeNotifier implements BluetoothInterface {
  bool _isConnected = false;
  bool _isScanning = false;
  fbpw.BluetoothDevice? _device;
  BluetoothDeviceInfo? _connectedDevice;
  final _scanResults = <BluetoothDeviceInfo>[];
  StreamSubscription<List<fbpw.ScanResult>>? _scanSubscription;
  StreamSubscription? _valueSubscription;
  fbpw.BluetoothAdapterState _adapterState = fbpw.BluetoothAdapterState.unknown;

  /// Windows版Bluetoothがサポートされているかチェック
  static Future<bool> isSupported() async {
    try {
      if (!Platform.isWindows) return false;
      final state = await fbpw.FlutterBluePlus.adapterState.first;
      return state == fbpw.BluetoothAdapterState.on;
    } catch (e) {
      debugPrint('Windows Bluetooth サポートチェックエラー: $e');
      return false;
    }
  }

  WindowsBluetoothService() {
    _initBluetooth();
  }

  void _initBluetooth() {
    fbpw.FlutterBluePlus.adapterState.listen((state) {
      _adapterState = state;
      notifyListeners();
    });
  }

  @override
  bool get isConnected => _isConnected;

  @override
  bool get isScanning => _isScanning;

  @override
  List<BluetoothDeviceInfo> get scanResults => List.unmodifiable(_scanResults);

  @override
  BluetoothDeviceInfo? get connectedDevice => _connectedDevice;

  @override
  Future<bool> connectToDevice(BluetoothDeviceInfo device) async {
    try {
      debugPrint('接続開始 - デバイス情報: ${device.toDebugMap()}');

      if (device.platform != BluetoothPlatform.windows) {
        debugPrint('対応していないプラットフォーム: ${device.platform}');
        return false;
      }

      final windowsDevice = device.asWindowsDevice;
      if (windowsDevice == null) {
        debugPrint('Windows用デバイスの取得に失敗');
        return false;
      }

      debugPrint('接続試行中: ${windowsDevice.id} (${windowsDevice.runtimeType})');
      _device = windowsDevice;
      
      await windowsDevice.connect(timeout: const Duration(seconds: 10));
      debugPrint('デバイス接続成功');
      
      _isConnected = true;
      _connectedDevice = device;
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Bluetooth接続エラー: $e');
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    await _valueSubscription?.cancel();
    _valueSubscription = null;

    try {
      if (_device != null) {
        await _device!.disconnect();
      }
    } finally {
      _isConnected = false;
      _connectedDevice = null;
      _device = null;
      notifyListeners();
      debugPrint('デバイスを切断しました');
    }
  }

  @override
  Future<fbpw.BluetoothService?> discoverService(dynamic device, String serviceUuid) async {
    try {
      debugPrint('サービス探索開始: $serviceUuid');
      debugPrint('デバイスの型: ${device.runtimeType}');
      
      final windowsDevice = (device is BluetoothDeviceInfo) 
        ? device.asWindowsDevice 
        : (device is fbpw.BluetoothDevice ? device : null);

      if (windowsDevice == null) {
        debugPrint('有効なWindowsデバイスではありません');
        return null;
      }

      await Future.delayed(const Duration(milliseconds: 500));

      fbpw.BluetoothService? foundService;
      for (var attempt = 1; attempt <= 3; attempt++) {
        final services = await windowsDevice.discoverServices();
        debugPrint('発見されたサービス数: ${services.length}');
        
        for (final service in services) {
          debugPrint('検出されたサービス: ${service.uuid}');
          debugPrint('  特性の数: ${service.characteristics.length}');
          
          if (service.uuid.toString().toUpperCase() == serviceUuid.toUpperCase()) {
            debugPrint('サービスが見つかりました！');
            
            if (service.characteristics.isEmpty && attempt < 3) {
              debugPrint('特性が空のため再探索を試みます (試行 $attempt)');
              await Future.delayed(const Duration(milliseconds: 500));
              continue;
            }
            
            foundService = service;
            break;
          }
        }
        
        if (foundService != null) break;
        
        if (attempt < 3) {
          debugPrint('サービスが見つからないため再探索を試みます (試行 $attempt)');
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      if (foundService == null) {
        debugPrint('サービスが見つかりませんでした: $serviceUuid');
      }

      return foundService;
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
      if (service is! fbpw.BluetoothService) {
        debugPrint('無効なサービスの型: ${service.runtimeType}');
        return null;
      }

      debugPrint('特性を探索中: $characteristicUuid');

      // 特性を探索
      final characteristics = service.characteristics.where((c) {
        final uuid = c.uuid.toString().toUpperCase();
        debugPrint('特性を確認中:');
        debugPrint('  UUID: $uuid');
        debugPrint('  プロパティ: ${c.properties}');
        return uuid == characteristicUuid.toUpperCase();
      }).toList();

      if (characteristics.isEmpty) {
        debugPrint('特性が見つかりません: $characteristicUuid');
        return null;
      }

      final characteristic = characteristics.first;
      debugPrint('特性が見つかりました: ${characteristic.uuid}');

      // 通知を有効化
      characteristic.setNotifyValue(true);
      return characteristic.lastValueStream;
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
      if (service is! fbpw.BluetoothService) {
        debugPrint('無効なサービスの型: ${service.runtimeType}');
        return false;
      }

      final fullUuid = characteristicUuid.length == 4 
        ? '0000$characteristicUuid-0000-1000-8000-00805f9b34fb'
        : characteristicUuid;

      debugPrint('書き込む特性を探索: $fullUuid');

      // 特性を探索
      final characteristics = service.characteristics.where((c) {
        final uuid = c.uuid.toString().toUpperCase();
        debugPrint('特性を確認中:');
        debugPrint('  UUID: $uuid');
        debugPrint('  プロパティ: ${c.properties}');
        return uuid == fullUuid.toUpperCase();
      }).toList();

      if (characteristics.isEmpty) {
        debugPrint('書き込み用特性が見つかりません: $fullUuid');
        return false;
      }

      final characteristic = characteristics.first;
      debugPrint('書き込み用特性が見つかりました: ${characteristic.uuid}');
      debugPrint('書き込むデータ: ${value.map((b) => '0x${b.toRadixString(16)}').join(', ')}');

      await characteristic.write(value);
      debugPrint('データ書き込み成功');
      return true;
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
    notifyListeners();

    try {
      debugPrint('デバイスのスキャンを開始します');
      await fbpw.FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
      
      _scanSubscription = fbpw.FlutterBluePlus.scanResults.listen((results) {
        final newResults = results
          .where((result) => result.device.name.isNotEmpty)
          .map((result) {
            debugPrint('デバイス検出: ${result.device.name} (${result.device.id})');
            return BluetoothDeviceInfo.fromWindowsDevice(result);
          })
          .toList();

        _scanResults
          ..clear()
          ..addAll(newResults);
        
        notifyListeners();
      });

      await Future.delayed(const Duration(seconds: 4));
      await stopScan();
    } catch (e) {
      debugPrint('スキャンエラー: $e');
      _isScanning = false;
      notifyListeners();
    }
  }

  @override
  Future<void> stopScan() async {
    if (!_isScanning) return;

    try {
      await fbpw.FlutterBluePlus.stopScan();
      await _scanSubscription?.cancel();
      _scanSubscription = null;
    } finally {
      _isScanning = false;
      notifyListeners();
      debugPrint('スキャンを停止しました');
    }
  }

  @override
  dynamic getNativeDevice(BluetoothDeviceInfo device) {
    final windowsDevice = device.asWindowsDevice;
    debugPrint('getNativeDevice - 型: ${windowsDevice?.runtimeType}');
    return windowsDevice;
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
    _scanSubscription?.cancel();
    disconnect();
    super.dispose();
  }
}