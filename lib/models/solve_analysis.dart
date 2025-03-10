import 'move.dart';

// ルービックキューブの解法分析結果を表すクラス
class SolveAnalysis {
  // 解法にかかった時間
  final Duration solveTime;
  
  // 解法中のすべての操作（時系列順）
  final List<Move> moves;
  
  // 解法のTPS (Turns Per Second、1秒あたりの操作数)
  final double tps;
  
  // フェーズ別の所要時間
  // 例: {'Cross': Duration(...), 'F2L': Duration(...), ...}
  final Map<String, Duration> phaseTimings;
  
  // 冗長な操作の数（例: R R'のように互いに打ち消し合う操作）
  final int redundantMoves;

  SolveAnalysis({
    required this.solveTime,
    required this.moves,
    required this.tps,
    required this.phaseTimings,
    required this.redundantMoves,
  });
  
  // 解法の効率を計算
  // 冗長な操作が少ないほど効率が高い（1.0が最高）
  double get efficiency {
    if (moves.isEmpty) return 1.0;
    
    final effectiveMoves = moves.length - redundantMoves;
    return effectiveMoves / moves.length;
  }
  
  // フェーズごとのTPSを計算
  Map<String, double> getPhaseTPS() {
    final result = <String, double>{};
    
    // 各フェーズのTPS計算のためのムーブ数をカウント
    final phaseMoveCounts = <String, int>{};
    
    // 単純化のために、均等に各フェーズにムーブを割り当てる
    final totalPhaseTime = phaseTimings.values.fold<Duration>(
      Duration.zero,
      (prev, curr) => prev + curr,
    );
    
    if (totalPhaseTime.inMilliseconds == 0) {
      // フェーズ情報がない場合は空のマップを返す
      return {};
    }
    
    // 各フェーズの相対的な時間比率に基づいてムーブを割り当て
    for (final phase in phaseTimings.keys) {
      final phaseRatio = phaseTimings[phase]!.inMilliseconds / 
                       totalPhaseTime.inMilliseconds;
      phaseMoveCounts[phase] = (moves.length * phaseRatio).round();
    }
    
    // 各フェーズのTPSを計算
    for (final phase in phaseTimings.keys) {
      final phaseDurationSec = phaseTimings[phase]!.inMilliseconds / 1000;
      final moveCount = phaseMoveCounts[phase] ?? 0;
      
      result[phase] = phaseDurationSec > 0 ? moveCount / phaseDurationSec : 0.0;
    }
    
    return result;
  }
}