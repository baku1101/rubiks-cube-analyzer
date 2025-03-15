import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/cube_connection_service.dart';
import '../models/cube_state.dart';
import '../models/move.dart';
import '../widgets/cube_view_widget.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final faceSize = width / 6;
    final cubeState = context.watch<CubeConnectionService>().currentCubeState;
    final moves = context.watch<CubeConnectionService>().moveHistory;
    final solveStartTime = context.watch<CubeConnectionService>().solveStartTime;
    final solveEndTime = context.watch<CubeConnectionService>().solveEndTime;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'キューブの状態',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: CubeViewWidget(
                cubeState: cubeState,
                size: faceSize,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '手順履歴',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildMoveHistory(moves),
            const SizedBox(height: 24),
            const Text(
              'タイム',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildTimeInfo(solveStartTime, solveEndTime),
          ],
        ),
      ),
    );
  }

  Widget _buildMoveHistory(List<Move> moves) {
    if (moves.isEmpty) {
      return const Text('まだ手順はありません');
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: moves.map((move) => Chip(
        label: Text(move.notation),
      )).toList(),
    );
  }

  Widget _buildTimeInfo(DateTime? startTime, DateTime? endTime) {
    if (startTime == null) {
      return const Text('まだ計測を開始していません');
    }

    if (endTime == null) {
      final duration = DateTime.now().difference(startTime);
      return Text('経過時間: ${_formatDuration(duration)}');
    }

    final duration = endTime.difference(startTime);
    return Text('タイム: ${_formatDuration(duration)}');
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final milliseconds = duration.inMilliseconds % 1000;
    
    if (minutes > 0) {
      return '${minutes}:${seconds.toString().padLeft(2, '0')}.${(milliseconds ~/ 10).toString().padLeft(2, '0')}';
    } else {
      return '${seconds}.${(milliseconds ~/ 10).toString().padLeft(2, '0')}';
    }
  }
}