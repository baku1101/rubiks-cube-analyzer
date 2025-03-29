import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rubiks_cube_analyzer/services/bluetooth/interface/device.dart';
// import 'package:rubiks_cube_analyzer/ui/debug/debug_screen.dart'; // DebugViewModel をインポート (将来)
import 'package:rubiks_cube_analyzer/ui/debug/debug_screen.dart';

/// Bluetooth接続関連のUIを表示するウィジェット。
class ConnectionView extends StatelessWidget {
  const ConnectionView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<DebugViewModel>(context);
    final isScanning = viewModel.isScanning;
    final scanResults = viewModel.scanResults;
    final connectedDevice = viewModel.connectedDevice;
    final connectionStatus = viewModel.connectionStatus;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('接続状態: $connectionStatus', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              icon: isScanning
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.search),
              label: const Text('スキャン'),
              onPressed: isScanning || connectedDevice != null ? null : () => viewModel.toggleScan(),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.bluetooth_disabled),
              label: const Text('切断'),
              onPressed: connectedDevice == null ? null : () => viewModel.disconnect(),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[100]),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text('検出されたデバイス:'),
        Expanded(
          child: scanResults.isEmpty && !isScanning
              ? const Center(child: Text('デバイスが見つかりません'))
              : ListView.builder(
                  itemCount: scanResults.length,
                  itemBuilder: (context, index) {
                    final device = scanResults[index];
                    return ListTile(
                      title: Text(device.name),
                      subtitle: Text(device.id),
                      onTap: connectedDevice == null ? () => viewModel.connect(device) : null,
                      leading: const Icon(Icons.bluetooth),
                      trailing: connectedDevice?.id == device.id ? const Icon(Icons.check_circle, color: Colors.green) : null,
                    );
                  },
                ),
        ),
      ],
    );
  }
}