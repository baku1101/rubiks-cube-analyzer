import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus_windows/flutter_blue_plus_windows.dart';
import '../models/bluetooth_device_info.dart';

class CubeBluetoothService extends ChangeNotifier {
  final Set<BluetoothDeviceInfo> _scanResults = {};
  StreamSubscription? _scanResultsSubscription;
  bool _isScanning = false;
  BluetoothDeviceInfo? _connectedDevice;
  StreamSubscription? _connectionSubscription;
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;

  CubeBluetoothService() {
    FlutterBluePlus.setLogLevel(LogLevel.verbose, color: true);
    _initializeBluetoothState();
  }

  void _initializeBluetoothState() {
    FlutterBluePlus.adapterState.listen((state) {
      _adapterState = state;
      notifyListeners();
    });
  }

  List<BluetoothDeviceInfo> get scanResults => List.unmodifiable(_scanResults.toList());
  BluetoothDeviceInfo? get connectedDevice => _connectedDevice;
  bool get isConnected => _connectedDevice != null;
  bool get isScanning => _isScanning;
  BluetoothAdapterState get adapterState => _adapterState;

  Future<bool> isBluetoothOn() async {
    try {
      final isSupported = await FlutterBluePlus.isSupported;
      if (!isSupported) {
        debugPrint('Bluetoothはこのデバイスでサポートされていません');
        return false;
      }

      return _adapterState == BluetoothAdapterState.on;
    } catch (e) {
      debugPrint('Bluetooth状態確認エラー: $e');
      return false;
    }
  }

  Future<void> startScan() async {
    if (_isScanning) return;

    try {
      _scanResults.clear();
      _isScanning = true;
      notifyListeners();

      await FlutterBluePlus.stopScan();
      
      final scanTimeout = const Duration(seconds: 15);
      _scanResultsSubscription = FlutterBluePlus.scanResults
        .expand((results) => results)
        .listen(
          (result) {
            // 名前が空のデバイスはスキップ
            if (result.device.platformName.isEmpty) return;
            
            final deviceInfo = BluetoothDeviceInfo(
              name: result.device.platformName,
              id: result.device.remoteId.str,
              nativeDevice: result.device,
              rssi: result.rssi,
            );
            
            // デバイス情報を更新または追加
            _scanResults.removeWhere((device) => device.id == deviceInfo.id);
            _scanResults.add(deviceInfo);
            notifyListeners();
          },
          onError: (e) {
            debugPrint('スキャンエラー: $e');
            stopScan();
          }
        );

      await FlutterBluePlus.startScan(
        timeout: scanTimeout,
        // AndroidのScanModeはWindowsでは利用できないため削除
      );
    } catch (e) {
      debugPrint('スキャン開始エラー: $e');
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<void> stopScan() async {
    if (!_isScanning) return;

    try {
      await _scanResultsSubscription?.cancel();
      _scanResultsSubscription = null;
      await FlutterBluePlus.stopScan();
    } catch (e) {
      debugPrint('スキャン停止エラー: $e');
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<bool> connectToDevice(BluetoothDeviceInfo device) async {
    if (_connectedDevice != null) {
      await disconnect();
    }
    
    try {
      await device.nativeDevice.connect(
        timeout: const Duration(seconds: 10),
      );
      
      _connectionSubscription = device.nativeDevice.connectionState.listen(
        (state) {
          if (state == BluetoothConnectionState.disconnected) {
            disconnect();
          }
        },
        onError: (error) {
          debugPrint('接続状態監視エラー: $error');
          disconnect();
        },
      );
      
      _connectedDevice = device;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('デバイス接続エラー: $e');
      return false;
    }
  }

  Future<void> disconnect() async {
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;
    
    if (_connectedDevice != null) {
      try {
        await _connectedDevice!.nativeDevice.disconnect();
      } catch (e) {
        debugPrint('デバイス切断エラー: $e');
      }
      
      _connectedDevice = null;
      notifyListeners();
    }
  }

  Future<BluetoothService?> discoverService(
    BluetoothDevice device, 
    String serviceUuid,
  ) async {
    try {
      // UUIDを正規化
      final normalizedSearchUuid = serviceUuid.replaceAll('-', '').toLowerCase();
      debugPrint('探索するサービスUUID: $normalizedSearchUuid');
      
      // 接続後のサービス検索のために少し待機
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // 最大3回まで試行
      for (var i = 0; i < 3; i++) {
        try {
          final services = await device.discoverServices();
          for (final service in services) {
            final normalizedUuid = service.uuid.str.replaceAll('-', '').toLowerCase();
            debugPrint('検出されたサービス: $normalizedUuid (元のUUID: ${service.uuid.str})');
          }
          
          final service = services.firstWhere(
            (s) => s.uuid.str.replaceAll('-', '').toLowerCase() == normalizedSearchUuid,
            orElse: () => throw Exception('Service not found'),
          );
          
          debugPrint('サービスが見つかりました: ${service.uuid.str}');
          return service;
        } catch (e) {
          if (i == 2) rethrow; // 最後の試行で失敗した場合は例外を投げる
          debugPrint('試行 ${i + 1} 失敗: $e');
          await Future.delayed(const Duration(milliseconds: 500)); // 次の試行までの待機
          continue;
        }
      }
      
      throw Exception('Service not found after retries');
    } catch (e) {
      debugPrint('サービス検索エラー: $e');
      return null;
    }
  }

  Future<bool> writeCharacteristic(
    BluetoothService service,
    String characteristicUuid,
    Uint8List data,
  ) async {
    try {
      final normalizedSearchUuid = characteristicUuid.replaceAll('-', '').toLowerCase();
      final characteristic = service.characteristics.firstWhere(
        (c) => c.uuid.str.replaceAll('-', '').toLowerCase() == normalizedSearchUuid,
      );
      await characteristic.write(data);
      return true;
    } catch (e) {
      debugPrint('特性書き込みエラー: $e');
      return false;
    }
  }

  Stream<List<dynamic>>? subscribeToCharacteristic(
    BluetoothService service,
    String characteristicUuid,
  ) {
    try {
      final normalizedSearchUuid = characteristicUuid.replaceAll('-', '').toLowerCase();
      debugPrint('探索する特性UUID: $normalizedSearchUuid');
      
      debugPrint('利用可能な特性:');
      for (final c in service.characteristics) {
        final normalizedUuid = c.uuid.str.replaceAll('-', '').toLowerCase();
        debugPrint('- $normalizedUuid (元のUUID: ${c.uuid.str})');
      }
      
      final characteristic = service.characteristics.firstWhere(
        (c) => c.uuid.str.replaceAll('-', '').toLowerCase() == normalizedSearchUuid,
      );
      characteristic.setNotifyValue(true);
      return characteristic.lastValueStream;
    } catch (e) {
      debugPrint('特性サブスクライブエラー: $e');
      return null;
    }
  }

  @override
  void dispose() {
    stopScan();
    _scanResultsSubscription?.cancel();
    _connectionSubscription?.cancel();
    super.dispose();
  }
}