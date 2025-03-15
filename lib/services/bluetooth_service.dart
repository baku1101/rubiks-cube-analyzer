import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus_windows/flutter_blue_plus_windows.dart' as fbpw;
import '../models/bluetooth_device_info.dart';

class CubeBluetoothService extends ChangeNotifier {
  // UUID定数
  static const String UUID_SUFFIX = '-0000-1000-8000-00805f9b34fb';
  static const String SERVICE_UUID_V4 = '00000010-0000-fff7-fff6-fff5fff4fff0';
  static const String CHARACTERISTIC_UUID_NOTIFY = '0000fff6$UUID_SUFFIX';
  static const String CHARACTERISTIC_UUID_WRITE = '0000fff5$UUID_SUFFIX';

  fbpw.BluetoothDevice? _connectedDevice;
  bool _isScanning = false;
  StreamSubscription<List<fbpw.ScanResult>>? _scanSubscription;
  List<BluetoothDeviceInfo> _scanResults = [];
  fbpw.BluetoothAdapterState _adapterState = fbpw.BluetoothAdapterState.unknown;

  CubeBluetoothService() {
    _initBluetooth();
  }

  // Getters
  bool get isScanning => _isScanning;
  bool get isConnected => _connectedDevice != null;
  List<BluetoothDeviceInfo> get scanResults => List.unmodifiable(_scanResults);
  fbpw.BluetoothAdapterState get adapterState => _adapterState;
  BluetoothDeviceInfo? get connectedDevice => _connectedDevice != null 
    ? BluetoothDeviceInfo(
        nativeDevice: _connectedDevice!,
        name: _connectedDevice!.name,
        id: _connectedDevice!.id.toString(),
        rssi: -50,
      )
    : null;

  // Bluetoothの初期化
  Future<void> _initBluetooth() async {
    fbpw.FlutterBluePlus.adapterState.listen((state) {
      _adapterState = state;
      notifyListeners();
    });
  }

  // スキャンを開始
  Future<void> startScan() async {
    if (_isScanning) return;
    _isScanning = true;
    _scanResults.clear();
    notifyListeners();

    try {
      await fbpw.FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
      
      _scanSubscription = fbpw.FlutterBluePlus.scanResults.listen((results) {
        _scanResults = results
          .where((result) => result.device.name.isNotEmpty)
          .map((result) => BluetoothDeviceInfo.fromWindowsDevice(result))
          .toList();
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

  // スキャンを停止
  Future<void> stopScan() async {
    if (!_isScanning) return;

    try {
      await fbpw.FlutterBluePlus.stopScan();
      await _scanSubscription?.cancel();
      _scanSubscription = null;
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  // デバイスに接続
  Future<bool> connectToDevice(BluetoothDeviceInfo device) async {
    try {
      debugPrint('デバイス接続開始: ${device.name} (${device.id})');
      await device.nativeDevice.connect(timeout: const Duration(seconds: 10));
      _connectedDevice = device.nativeDevice;
      notifyListeners();
      debugPrint('デバイス接続成功');
      return true;
    } catch (e) {
      debugPrint('接続エラー: $e');
      return false;
    }
  }

  // デバイスから切断
  Future<void> disconnect() async {
    if (_connectedDevice == null) return;
    
    try {
      await _connectedDevice!.disconnect();
    } finally {
      _connectedDevice = null;
      notifyListeners();
    }
  }

  // サービスを探索
  Future<fbpw.BluetoothService?> discoverService(
    fbpw.BluetoothDevice device,
    String serviceUuid,
  ) async {
    try {
      debugPrint('探索するサービスUUID: $serviceUuid');
      
      // サービスの探索前に少し待機
      await Future.delayed(const Duration(milliseconds: 500));
      
      fbpw.BluetoothService? foundService;
      for (var attempt = 1; attempt <= 3; attempt++) {
        final services = await device.discoverServices();
        debugPrint('発見されたサービス数: ${services.length}');
        
        // すべてのサービスの情報をデバッグ出力
        for (final service in services) {
          debugPrint('検出されたサービス: ${service.uuid}');
          debugPrint('  特性の数: ${service.characteristics.length}');
          
          // サービスが一致した場合
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

      return foundService;
    } catch (e) {
      debugPrint('サービス探索エラー: $e');
      return null;
    }
  }

  // 特性をサブスクライブ
  Stream<List<int>>? subscribeToCharacteristic(
    fbpw.BluetoothService service,
    String characteristicUuid,
  ) {
    try {
      final fullUuid = characteristicUuid.length == 4 
        ? '0000$characteristicUuid$UUID_SUFFIX'
        : characteristicUuid;
      
      debugPrint('特性を探索中: $fullUuid');
      
      // 特性を探索
      final characteristics = service.characteristics.where((c) {
        final uuid = c.uuid.toString().toUpperCase();
        debugPrint('特性を確認中:');
        debugPrint('  UUID: $uuid');
        debugPrint('  プロパティ: ${c.properties}');
        return uuid == fullUuid.toUpperCase();
      }).toList();

      if (characteristics.isEmpty) {
        debugPrint('特性が見つかりません: $fullUuid');
        return null;
      }

      final characteristic = characteristics.first;
      debugPrint('特性が見つかりました: ${characteristic.uuid}');

      // 通知を有効化
      characteristic.setNotifyValue(true);
      
      // 値の変更をストリームとして返す
      return characteristic.lastValueStream;
    } catch (e) {
      debugPrint('特性サブスクライブエラー: $e');
      return null;
    }
  }

  // 特性に書き込み
  Future<void> writeCharacteristic(
    fbpw.BluetoothService service,
    String characteristicUuid,
    List<int> value,
  ) async {
    try {
      final fullUuid = characteristicUuid.length == 4 
        ? '0000$characteristicUuid$UUID_SUFFIX'
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
        return;
      }

      final characteristic = characteristics.first;
      debugPrint('書き込み用特性が見つかりました: ${characteristic.uuid}');
      debugPrint('書き込むデータ: ${value.map((b) => '0x${b.toRadixString(16)}').join(', ')}');

      await characteristic.write(value);
      debugPrint('データ書き込み成功');
    } catch (e) {
      debugPrint('特性書き込みエラー: $e');
    }
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    disconnect();
    super.dispose();
  }
}