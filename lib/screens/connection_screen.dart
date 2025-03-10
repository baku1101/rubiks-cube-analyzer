import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus_windows/flutter_blue_plus_windows.dart';
import '../services/bluetooth_service.dart';
import '../services/cube_connection_service.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({Key? key}) : super(key: key);

  @override
  _ConnectionScreenState createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  bool _isInitializing = true;
  late final CubeBluetoothService _bluetoothService;

  @override
  void initState() {
    super.initState();
    _bluetoothService = context.read<CubeBluetoothService>();
    _checkBluetoothStatus();
  }

  // Bluetoothの状態を確認
  Future<void> _checkBluetoothStatus() async {
    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  // Bluetoothがオフの場合のウィジェットを表示
  Widget _buildBluetoothOffScreen(BluetoothAdapterState state) {
    String message;
    switch (state) {
      case BluetoothAdapterState.unavailable:
        message = 'Bluetoothはこのデバイスではサポートされていません';
        break;
      case BluetoothAdapterState.unauthorized:
        message = 'Bluetoothの使用が許可されていません';
        break;
      case BluetoothAdapterState.off:
        message = 'Bluetoothがオフになっています。\nWindowsの設定からBluetoothをオンにしてください。';
        break;
      default:
        message = 'Bluetoothの状態: $state';
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.bluetooth_disabled,
            size: 100.0,
            color: Colors.grey,
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            child: const Text('戻る'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bluetoothService = context.watch<CubeBluetoothService>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('キューブに接続'),
      ),
      body: _isInitializing
          ? const Center(child: CircularProgressIndicator())
          : bluetoothService.adapterState != BluetoothAdapterState.on
              ? _buildBluetoothOffScreen(bluetoothService.adapterState)
              : _buildScanningView(),
    );
  }

  Widget _buildScanningView() {
    final bluetoothService = context.watch<CubeBluetoothService>();
    
    return Column(
      children: [
        // ステータスバー
        Container(
          color: Colors.blue.shade100,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                bluetoothService.isScanning
                    ? Icons.bluetooth_searching
                    : Icons.bluetooth,
                color: Colors.blue,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  bluetoothService.isScanning
                      ? 'デバイスをスキャン中...'
                      : 'スキャンを開始',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              if (bluetoothService.isScanning)
                IconButton(
                  icon: const Icon(Icons.stop),
                  tooltip: 'スキャンを停止',
                  onPressed: () {
                    bluetoothService.stopScan();
                  },
                )
              else
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'スキャンを開始',
                  onPressed: () {
                    bluetoothService.startScan();
                  },
                ),
            ],
          ),
        ),

        // デバイスリスト
        Expanded(
          child: bluetoothService.scanResults.isEmpty
              ? _buildEmptyListView()
              : _buildDeviceListView(),
        ),
      ],
    );
  }

  Widget _buildEmptyListView() {
    final bluetoothService = context.watch<CubeBluetoothService>();
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.bluetooth_disabled,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            bluetoothService.isScanning
                ? '周囲のデバイスを検索中...'
                : 'デバイスが見つかりません',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 24),
          if (!bluetoothService.isScanning)
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('再スキャン'),
              onPressed: () {
                bluetoothService.startScan();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDeviceListView() {
    final bluetoothService = context.watch<CubeBluetoothService>();
    final cubeConnectionService = context.watch<CubeConnectionService>();
    
    return ListView.builder(
      itemCount: bluetoothService.scanResults.length,
      itemBuilder: (context, index) {
        final device = bluetoothService.scanResults[index];
        
        return ListTile(
          leading: const Icon(Icons.bluetooth),
          title: Text(device.name.isEmpty ? '不明なデバイス' : device.name),
          subtitle: Text(device.id),
          trailing: cubeConnectionService.isConnecting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.chevron_right),
          onTap: cubeConnectionService.isConnecting
              ? null // 接続中は無効化
              : () async {
                  // キューブへの接続を試みる
                  await bluetoothService.stopScan();
                  
                  final success = await cubeConnectionService.connectToCube(device);
                  
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('キューブに接続しました'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.pop(context); // ホームに戻る
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('接続に失敗しました。もう一度お試しください。'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
        );
      },
    );
  }

  Widget _buildConnectedDeviceInfo(CubeConnectionService cubeService) {
    final device = cubeService.connectedDevice;
    if (device == null) return const SizedBox();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.bluetooth_connected, color: Colors.blue),
              title: Text(device.name),
              subtitle: Text('Signal Strength: ${device.rssi} dBm'),
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                _getBatteryIcon(cubeService.batteryLevel),
                color: _getBatteryColor(cubeService.batteryLevel),
              ),
              title: Text('バッテリー残量: ${cubeService.batteryLevel}%'),
              subtitle: Text(_getBatteryDescription(cubeService.batteryLevel)),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getBatteryIcon(int level) {
    if (level >= 95) return Icons.battery_full;
    if (level >= 85) return Icons.battery_6_bar;
    if (level >= 70) return Icons.battery_5_bar;
    if (level >= 55) return Icons.battery_4_bar;
    if (level >= 40) return Icons.battery_3_bar;
    if (level >= 25) return Icons.battery_2_bar;
    if (level >= 10) return Icons.battery_1_bar;
    return Icons.battery_0_bar;
  }

  Color _getBatteryColor(int level) {
    if (level > 60) return Colors.green;
    if (level > 20) return Colors.orange;
    return Colors.red;
  }

  String _getBatteryDescription(int level) {
    if (level > 60) return '充電は十分です';
    if (level > 20) return '充電が少なくなっています';
    return '充電が必要です';
  }

  @override
  void dispose() {
    _bluetoothService.stopScan();
    super.dispose();
  }
}