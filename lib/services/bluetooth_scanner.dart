import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus_windows/flutter_blue_plus_windows.dart';
import '../models/bluetooth_device_info.dart';

class BluetoothScanner {
  final Set<BluetoothDeviceInfo> _scanResults = {};
  StreamSubscription? _scanResultsSubscription;
  bool _isScanning = false;

  List<BluetoothDeviceInfo> get scanResults => List.unmodifiable(_scanResults.toList());
  bool get isScanning => _isScanning;

  Future<void> startScan() async {
    if (_isScanning) return;

    try {
      _scanResults.clear();
      _isScanning = true;

      // Stop any existing scan
      await FlutterBluePlus.stopScan();
      
      // Set up scan results subscription
      _scanResultsSubscription = FlutterBluePlus.scanResults
        .expand((results) => results) // Flatten the list of scan results
        .listen(
          (result) {
            if (result.device.platformName.isEmpty) return;
            final deviceInfo = BluetoothDeviceInfo.fromWindowsDevice(result);
            _scanResults.removeWhere((device) => device.id == deviceInfo.id);
            _scanResults.add(deviceInfo);
          },
          onError: (e) {
            debugPrint('Scan error: $e');
            stopScan();
          }
        );

      // Start scan with timeout
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
      );
    } catch (e) {
      debugPrint('Error starting scan: $e');
      _isScanning = false;
      rethrow;
    }
  }

  Future<void> stopScan() async {
    if (!_isScanning) return;

    try {
      await _scanResultsSubscription?.cancel();
      _scanResultsSubscription = null;
      await FlutterBluePlus.stopScan();
    } catch (e) {
      debugPrint('Error stopping scan: $e');
      rethrow;
    } finally {
      _isScanning = false;
    }
  }

  void dispose() {
    stopScan();
  }
}