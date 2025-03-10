import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/solve_analysis.dart';
import '../services/analytics_service.dart';
import '../services/cube_connection_service.dart';
import '../widgets/cube_view_widget.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({Key? key}) : super(key: key);

  @override
  _AnalysisScreenState createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  SolveAnalysis? _analysis;
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // タブを4つに変更
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runAnalysis();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 解法の分析を実行
  void _runAnalysis() {
    final cubeService = Provider.of<CubeConnectionService>(context, listen: false);
    final analyticsService = Provider.of<AnalyticsService>(context, listen: false);
    
    final moves = cubeService.moveHistory;
    final startTime = cubeService.solveStartTime;
    final endTime = cubeService.solveEndTime ?? DateTime.now();
    
    if (startTime != null && moves.isNotEmpty) {
      setState(() {
        _isAnalyzing = true;
      });
      
      // 分析を実行
      final analysis = analyticsService.analyzeSolve(
        moves,
        startTime,
        endTime,
      );
      
      setState(() {
        _analysis = analysis;
        _isAnalyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('解法分析'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '概要'),
            Tab(text: 'キューブ'),  // 新しいタブ
            Tab(text: '操作履歴'),
            Tab(text: 'アドバイス'),
          ],
        ),
      ),
      body: _isAnalyzing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('解法を分析しています...'),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSummaryTab(),
                _buildCubeTab(),  // 新しいタブの内容
                _buildMovesTab(),
                _buildAdviceTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        tooltip: '新しいソルブを開始',
        child: const Icon(Icons.refresh),
        onPressed: () {
          // キューブの状態をリセット
          Provider.of<CubeConnectionService>(context, listen: false).resetSolve();
          
          // 前の画面に戻る
          Navigator.pop(context);
        },
      ),
    );
  }

  // キューブの表示タブ
  Widget _buildCubeTab() {
    final cubeService = Provider.of<CubeConnectionService>(context);
    final currentCubeState = cubeService.currentCubeState;
    
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 利用可能な幅に基づいてキューブの面サイズを計算
          final faceSize = constraints.maxWidth > 400 ? 100.0 : 80.0;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'キューブの現在の状態',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                
                // キューブ表示ウィジェット
                Center(
                  child: CubeViewWidget(
                    cubeState: currentCubeState,
                    faceSize: faceSize,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // キューブが解かれているかどうかの表示
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: currentCubeState.isSolved() 
                        ? Colors.green.shade100 
                        : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        currentCubeState.isSolved() 
                            ? Icons.check_circle 
                            : Icons.error,
                        color: currentCubeState.isSolved() 
                            ? Colors.green 
                            : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        currentCubeState.isSolved() 
                            ? 'キューブは解かれています' 
                            : 'キューブはまだ解かれていません',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: currentCubeState.isSolved() 
                              ? Colors.green 
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryTab() {
    if (_analysis == null) {
      return const Center(
        child: Text('解法データがありません。キューブを解いてください。'),
      );
    }

    final solveTime = _analysis!.solveTime;
    final minutes = solveTime.inMinutes;
    final seconds = (solveTime.inSeconds % 60);
    final milliseconds = (solveTime.inMilliseconds % 1000) ~/ 10;
    
    final timeString = '$minutes:${seconds.toString().padLeft(2, '0')}.${milliseconds.toString().padLeft(2, '0')}';
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'ソルブタイム',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    timeString,
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          const Text(
            '統計情報',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          _buildStatItem('総操作数', '${_analysis!.moves.length}手'),
          _buildStatItem('TPS (1秒あたりの操作数)', '${_analysis!.tps.toStringAsFixed(2)} 回/秒'),
          _buildStatItem('冗長な操作', '${_analysis!.redundantMoves}手'),
          _buildStatItem('効率', '${(_analysis!.efficiency * 100).toStringAsFixed(0)}%'),
          
          const SizedBox(height: 24),
          
          const Text(
            'フェーズ別タイミング',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          ..._analysis!.phaseTimings.entries.map((entry) {
            final phaseName = entry.key;
            final duration = entry.value;
            final percentage = (duration.inMilliseconds / solveTime.inMilliseconds * 100).toStringAsFixed(1);
            
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        phaseName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: LinearProgressIndicator(
                        value: duration.inMilliseconds / solveTime.inMilliseconds,
                        backgroundColor: Colors.grey.shade300,
                        color: _getColorForPhase(phaseName),
                        minHeight: 15,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '$percentage%',
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForPhase(String phase) {
    switch (phase) {
      case 'Cross':
        return Colors.blue;
      case 'F2L':
        return Colors.green;
      case 'OLL':
        return Colors.orange;
      case 'PLL':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildMovesTab() {
    if (_analysis == null || _analysis!.moves.isEmpty) {
      return const Center(
        child: Text('操作履歴がありません。'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _analysis!.moves.length,
      itemBuilder: (context, index) {
        final move = _analysis!.moves[index];
        final formattedTime = '${index + 1}.';
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Text(
                  formattedTime,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  move.notation,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(_getDescriptionForMove(move.type)),
            ],
          ),
        );
      },
    );
  }

  String _getDescriptionForMove(type) {
    // 各操作タイプに対する説明
    final descriptions = {
      'F': '前面を時計回りに回転',
      'F2': '前面を180度回転',
      'FPrime': '前面を反時計回りに回転',
      'B': '背面を時計回りに回転',
      'B2': '背面を180度回転',
      'BPrime': '背面を反時計回りに回転',
      'U': '上面を時計回りに回転',
      'U2': '上面を180度回転',
      'UPrime': '上面を反時計回りに回転',
      'D': '下面を時計回りに回転',
      'D2': '下面を180度回転',
      'DPrime': '下面を反時計回りに回転',
      'L': '左面を時計回りに回転',
      'L2': '左面を180度回転',
      'LPrime': '左面を反時計回りに回転',
      'R': '右面を時計回りに回転',
      'R2': '右面を180度回転',
      'RPrime': '右面を反時計回りに回転',
    };
    
    final key = type.toString().split('.').last;
    return descriptions[key] ?? '不明な操作';
  }

  Widget _buildAdviceTab() {
    if (_analysis == null) {
      return const Center(
        child: Text('解法データがありません。キューブを解いてください。'),
      );
    }
    
    final analyticsService = Provider.of<AnalyticsService>(context, listen: false);
    final advices = analyticsService.provideImprovement(_analysis!);
    final skillLevel = analyticsService.evaluateSolveLevel(_analysis!);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // スキルレベルの表示
          Card(
            elevation: 4,
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'あなたのレベル',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    skillLevel,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          const Text(
            '改善のためのアドバイス',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          if (advices.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '素晴らしい解法です！特に改善点はありません。',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            )
          else
            ...advices.map((advice) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lightbulb,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          advice,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}