import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/move.dart';
import '../services/cube_connection_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isScrambling = false;
  List<Move>? _scrambleMoves;

  @override
  Widget build(BuildContext context) {
    final cubeConnectionService = Provider.of<CubeConnectionService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rubik\'s Cube Analyzer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // アプリのロゴやバナー（将来的に追加）
            const SizedBox(height: 40),
            
            // キューブの接続状態に応じた表示
            cubeConnectionService.isConnected
                ? _buildConnectedView(context)
                : _buildDisconnectedView(context),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectedView(BuildContext context) {
    final cubeService = Provider.of<CubeConnectionService>(context);
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 40,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'キューブと接続中',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      _getBatteryIcon(cubeService.batteryLevel),
                      color: _getBatteryColor(cubeService.batteryLevel),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${cubeService.batteryLevel}%',
                      style: TextStyle(
                        color: _getBatteryColor(cubeService.batteryLevel),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 32),
        
        // スクランブルボタン（新しく追加）
        if (!_isScrambling && _scrambleMoves == null)
          ElevatedButton.icon(
            icon: const Icon(Icons.shuffle),
            label: const Text('キューブをスクランブル'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: _startScramble,
          ),
        
        // スクランブルムーブの表示
        if (_isScrambling)
          _buildScramblingView(),
          
        if (_scrambleMoves != null && !_isScrambling)
          _buildScrambleResultView(),
          
        const SizedBox(height: 24),
        
        // 分析ボタン
        ElevatedButton.icon(
          icon: const Icon(Icons.analytics),
          label: const Text('分析を開始'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 16,
            ),
          ),
          onPressed: () {
            // スクランブル状態をリセット
            setState(() {
              _scrambleMoves = null;
            });
            Navigator.pushNamed(context, '/analysis');
          },
        ),
        
        const SizedBox(height: 16),
        
        // 切断ボタン
        OutlinedButton.icon(
          icon: const Icon(Icons.bluetooth_disabled),
          label: const Text('キューブから切断'),
          onPressed: () {
            final cubeService = Provider.of<CubeConnectionService>(context, listen: false);
            cubeService.disconnect();
          },
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

  // スクランブル中の表示
  Widget _buildScramblingView() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('スクランブル中...'),
        ],
      ),
    );
  }

  // スクランブル結果の表示
  Widget _buildScrambleResultView() {
    if (_scrambleMoves == null) return const SizedBox();
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'スクランブル手順:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          
          // スクランブル手順の表示（横スクロール可能）
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _scrambleMoves!.map((move) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      move.notation,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // スクランブルをクリアするボタン
          TextButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('クリア'),
            onPressed: () {
              final cubeService = Provider.of<CubeConnectionService>(context, listen: false);
              cubeService.resetSolve();
              setState(() {
                _scrambleMoves = null;
              });
            },
          ),
        ],
      ),
    );
  }

  // スクランブル処理を開始
  Future<void> _startScramble() async {
    setState(() {
      _isScrambling = true;
    });
    
    try {
      final cubeService = Provider.of<CubeConnectionService>(context, listen: false);
      
      // スクランブル操作の実行（20手のランダムなスクランブル）
      final scrambleMoves = await cubeService.scrambleCube(20);
      
      setState(() {
        _scrambleMoves = scrambleMoves;
        _isScrambling = false;
      });
    } catch (e) {
      setState(() {
        _isScrambling = false;
      });
      
      // エラーメッセージを表示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('スクランブルエラー: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildDisconnectedView(BuildContext context) {
    return Column(
      children: [
        const Icon(
          Icons.bluetooth_disabled,
          color: Colors.grey,
          size: 80,
        ),
        const SizedBox(height: 16),
        const Text(
          'キューブと接続されていません',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'GAN12 UIキューブに接続して、解析を始めましょう',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          icon: const Icon(Icons.bluetooth_searching),
          label: const Text('キューブに接続'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 16,
            ),
          ),
          onPressed: () {
            Navigator.pushNamed(context, '/connect');
          },
        ),
      ],
    );
  }
}