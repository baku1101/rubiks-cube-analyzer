import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rubiks_cube_analyzer/services/gan/protocol/response.dart'; // CubeStateData をインポート
import 'package:rubiks_cube_analyzer/ui/debug/debug_screen.dart'; // DebugViewModel をインポート

/// キューブの状態を表示するウィジェット。
class CubeStateView extends StatelessWidget {
  const CubeStateView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<DebugViewModel>(context);
    // final cubeState = viewModel.cubeState; // TODO: ViewModel に CubeState を追加
    final moveCounter = 500; // 仮
    final cornerPositions = [0, 1, 2, 3, 4, 5, 6]; // 仮
    final cornerOrientations = [0, 1, 2, 0, 1, 2, 0]; // 仮
    final edgePositions = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]; // 仮
    final edgeOrientations = [0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0]; // 仮

    // --- 仮表示 ---
    // final moveCounter = cubeState?.moveCounter ?? -1; // TODO: ViewModel に CubeState を追加
    // final cornerPositions = cubeState?.cornerPositions ?? []; // TODO: ViewModel に CubeState を追加
    // final cornerOrientations = cubeState?.cornerOrientations ?? []; // TODO: ViewModel に CubeState を追加
    // final edgePositions = cubeState?.edgePositions ?? []; // TODO: ViewModel に CubeState を追加
    // final edgeOrientations = cubeState?.edgeOrientations ?? []; // TODO: ViewModel に CubeState を追加
    // --- 仮表示ここまで ---

    return SingleChildScrollView( // 内容が多い場合にスクロール可能にする
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('キューブ状態', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('ムーブカウンター: $moveCounter'),
          const SizedBox(height: 8), // TODO: ViewModel に CubeState を追加したら表示
          _buildStateTable('コーナー', cornerPositions, cornerOrientations),
          const SizedBox(height: 8),
          _buildStateTable('エッジ', edgePositions, edgeOrientations),
          // TODO: 将来的に3D表示などを追加する
        ],
      ),
    );
  }

  /// ピースの位置と向きを表示するテーブルを作成するヘルパーウィジェット。
  Widget _buildStateTable(String title, List<int> positions, List<int> orientations) {
    // positions と orientations の長さが異なる場合のエラーハンドリング (仮)
    final int count = positions.length < orientations.length ? positions.length : orientations.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$title:', style: const TextStyle(fontWeight: FontWeight.bold)),
        Table(
          border: TableBorder.all(color: Colors.grey),
          columnWidths: const {
            0: IntrinsicColumnWidth(), // Index列
            1: IntrinsicColumnWidth(), // Position列
            2: IntrinsicColumnWidth(), // Orientation列
          },
          children: [
            // ヘッダー行
            const TableRow(
              decoration: BoxDecoration(color: Colors.black12),
              children: [
                Padding(padding: EdgeInsets.all(4.0), child: Text('Index', textAlign: TextAlign.center)),
                Padding(padding: EdgeInsets.all(4.0), child: Text('Pos', textAlign: TextAlign.center)),
                Padding(padding: EdgeInsets.all(4.0), child: Text('Ori', textAlign: TextAlign.center)),
              ],
            ),
            // データ行
            for (int i = 0; i < count; i++)
              TableRow(
                children: [
                  Padding(padding: const EdgeInsets.all(4.0), child: Text('$i', textAlign: TextAlign.center)),
                  Padding(padding: const EdgeInsets.all(4.0), child: Text('${positions[i]}', textAlign: TextAlign.center)),
                  Padding(padding: const EdgeInsets.all(4.0), child: Text('${orientations[i]}', textAlign: TextAlign.center)),
                ],
              ),
          ],
        ),
      ],
    );
  }
}