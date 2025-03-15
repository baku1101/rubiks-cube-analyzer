import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/cube_connection_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: ListView(
        children: [
          const _SettingsSectionHeader(title: '一般設定'),
          
          SwitchListTile(
            title: const Text('操作音'),
            subtitle: const Text('キューブを回転させた時に音を再生します'),
            value: true, // 将来的に設定管理サービスから取得
            onChanged: (value) {
              // 設定を保存
            },
          ),
          
          SwitchListTile(
            title: const Text('振動フィードバック'),
            subtitle: const Text('キューブの操作時に振動フィードバックを提供します'),
            value: false, // 将来的に設定管理サービスから取得
            onChanged: (value) {
              // 設定を保存
            },
          ),
          
          const Divider(),
          
          const _SettingsSectionHeader(title: 'キューブ接続設定'),
          
          ListTile(
            title: const Text('スキャン時間'),
            subtitle: const Text('Bluetoothデバイスのスキャン時間を設定します'),
            trailing: const Text('30秒'),
            onTap: () {
              // スキャン時間設定ダイアログを表示
              _showScanDurationDialog(context);
            },
          ),
          
          const Divider(),
          
          const _SettingsSectionHeader(title: '解法分析設定'),
          
          ListTile(
            title: const Text('標準解法メソッド'),
            subtitle: const Text('解法分析で使用する標準的な解法メソッド'),
            trailing: const Text('CFOP'),
            onTap: () {
              // 解法メソッド選択ダイアログを表示
              _showSolveMethodDialog(context);
            },
          ),
          
          const Divider(),
          
          const _SettingsSectionHeader(title: 'デバイス情報'),
          
          _buildDeviceInfoSection(context),
          
          const Divider(),
          
          // アプリについて
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('アプリについて'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Rubik\'s Cube Analyzer',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2023 All Rights Reserved',
                children: [
                  const Text(
                    'Rubik\'s Cube Analyzerは、GAN12 UI Maglevキューブを使用して、キューブの解法を分析するアプリです。',
                  ),
                ],
              );
            },
          ),
          
          // リセットボタン
          ListTile(
            leading: const Icon(Icons.restore, color: Colors.red),
            title: const Text('設定をリセット', style: TextStyle(color: Colors.red)),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('設定をリセット'),
                  content: const Text('すべての設定を初期値に戻します。この操作は元に戻せません。'),
                  actions: [
                    TextButton(
                      child: const Text('キャンセル'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    TextButton(
                      child: const Text('リセット', style: TextStyle(color: Colors.red)),
                      onPressed: () {
                        // 設定をリセット
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('設定をリセットしました')),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceInfoSection(BuildContext context) {
    final cubeService = Provider.of<CubeConnectionService>(context);
    
    if (!cubeService.isConnected) {
      return const ListTile(
        title: Text('接続されたキューブ'),
        subtitle: Text('キューブが接続されていません'),
        leading: Icon(Icons.bluetooth_disabled),
      );
    }
    
    return Column(
      children: [
        ListTile(
          title: const Text('接続されたキューブ'),
          subtitle: Text(cubeService.connectedDevice?.name ?? 'Unknown Device'),
          leading: const Icon(Icons.bluetooth_connected),
        ),
        
        ListTile(
          title: Text('バッテリー残量: ${cubeService.batteryLevel}%'),
          subtitle: Text(_getBatteryDescription(cubeService.batteryLevel)),
          leading: Icon(
            _getBatteryIcon(cubeService.batteryLevel),
            color: _getBatteryColor(cubeService.batteryLevel),
          ),
        ),
      ],
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

  void _showScanDurationDialog(BuildContext context) {
    final durations = [15, 30, 45, 60];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('スキャン時間'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: durations.length,
            itemBuilder: (context, index) {
              return RadioListTile<int>(
                title: Text('${durations[index]}秒'),
                value: durations[index],
                groupValue: 30, // 将来的に設定から取得
                onChanged: (value) {
                  // 設定を保存
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            child: const Text('キャンセル'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showSolveMethodDialog(BuildContext context) {
    final methods = ['CFOP', 'Roux', 'ZZ', 'Beginner'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('解法メソッド'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: methods.length,
            itemBuilder: (context, index) {
              return RadioListTile<String>(
                title: Text(methods[index]),
                value: methods[index],
                groupValue: 'CFOP', // 将来的に設定から取得
                onChanged: (value) {
                  // 設定を保存
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            child: const Text('キャンセル'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _SettingsSectionHeader extends StatelessWidget {
  final String title;
  
  const _SettingsSectionHeader({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}