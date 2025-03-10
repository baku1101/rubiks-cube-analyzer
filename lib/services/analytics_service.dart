import '../models/move.dart';
import '../models/solve_analysis.dart';

class AnalyticsService {
  // ソルブ分析を行う
  SolveAnalysis analyzeSolve(
    List<Move> moves, 
    DateTime startTime, 
    DateTime endTime
  ) {
    if (moves.isEmpty) {
      return SolveAnalysis(
        solveTime: Duration.zero,
        moves: [],
        tps: 0.0,
        phaseTimings: {},
        redundantMoves: 0,
      );
    }
    
    // 総合的なソルブ時間を計算
    final solveTime = endTime.difference(startTime);
    
    // TPS (Turns Per Second) を計算
    final tps = solveTime.inMilliseconds > 0
        ? (moves.length / (solveTime.inMilliseconds / 1000))
        : 0.0;
    
    // 冗長な操作を検出
    final redundantMoves = _countRedundantMoves(moves);
    
    // ソルブのフェーズを推定
    final phaseTimings = _estimateSolvePhases(moves, startTime, endTime);
    
    return SolveAnalysis(
      solveTime: solveTime,
      moves: moves,
      tps: tps,
      phaseTimings: phaseTimings,
      redundantMoves: redundantMoves,
    );
  }

  // 冗長な操作を数える
  int _countRedundantMoves(List<Move> moves) {
    int redundantCount = 0;
    
    // 連続する逆操作を検出
    for (int i = 0; i < moves.length - 1; i++) {
      final currentMove = moves[i];
      final nextMove = moves[i + 1];
      
      // 同じ面の逆操作を行っているかチェック
      if (nextMove.type == currentMove.type.inverse) {
        redundantCount += 2; // 両方の操作が無駄になる
      }
    }
    
    // 4回連続で同じ面を回転させている場合（例：R R R R）
    for (int i = 0; i < moves.length - 3; i++) {
      if (_isSameFaceMove(moves[i], moves[i + 1]) &&
          _isSameFaceMove(moves[i + 1], moves[i + 2]) &&
          _isSameFaceMove(moves[i + 2], moves[i + 3])) {
        redundantCount += 4; // 4回の操作すべてが無駄
      }
    }
    
    return redundantCount;
  }

  // 2つの操作が同じ面に関するものかチェック
  bool _isSameFaceMove(Move move1, Move move2) {
    // 同じ面の基本操作かどうかを判断
    final face1 = _getFaceFromMove(move1.type);
    final face2 = _getFaceFromMove(move2.type);
    return face1 == face2;
  }

  // 操作から面を抽出
  String _getFaceFromMove(MoveType moveType) {
    final notation = moveType.toString().split('.').last;
    if (notation.startsWith('F')) return 'F';
    if (notation.startsWith('B')) return 'B';
    if (notation.startsWith('U')) return 'U';
    if (notation.startsWith('D')) return 'D';
    if (notation.startsWith('L')) return 'L';
    if (notation.startsWith('R')) return 'R';
    return 'X'; // デフォルト値：不明な面
  }

  // ソルブのフェーズを推定する
  Map<String, Duration> _estimateSolvePhases(
    List<Move> moves,
    DateTime startTime,
    DateTime endTime
  ) {
    // 仮の実装：実際にはより洗練されたアルゴリズムが必要
    // 本来は、特定のパターンを検出してフェーズを推定する
    
    if (moves.isEmpty) return {};
    
    final totalDuration = endTime.difference(startTime).inMilliseconds;
    
    // 単純にソルブを4つのフェーズに分割
    final crossDuration = Duration(milliseconds: totalDuration ~/ 4);
    final f2lDuration = Duration(milliseconds: totalDuration ~/ 2); // 最も長いフェーズ
    final ollDuration = Duration(milliseconds: totalDuration ~/ 8);
    final pllDuration = Duration(milliseconds: totalDuration ~/ 8);
    
    return {
      'Cross': crossDuration,
      'F2L': f2lDuration,
      'OLL': ollDuration,
      'PLL': pllDuration,
    };
  }

  // 特定のアルゴリズムパターンを検出する
  bool detectAlgorithmPattern(List<Move> moves, String algorithmName) {
    // 一般的なアルゴリズムのパターンをここで定義
    final Map<String, List<MoveType>> commonAlgorithms = {
      'Sune': [
        MoveType.R, MoveType.U, MoveType.RPrime,
        MoveType.U, MoveType.R, MoveType.U2, MoveType.RPrime
      ],
      'AntiSune': [
        MoveType.RPrime, MoveType.UPrime, MoveType.R,
        MoveType.UPrime, MoveType.RPrime, MoveType.U2, MoveType.R
      ],
      'T-Perm': [
        MoveType.R, MoveType.U, MoveType.RPrime, MoveType.UPrime,
        MoveType.RPrime, MoveType.F, MoveType.R2, MoveType.UPrime, 
        MoveType.RPrime, MoveType.UPrime, MoveType.R, MoveType.U, 
        MoveType.RPrime, MoveType.FPrime
      ],
      // 他のアルゴリズムも追加可能
    };
    
    // 要求されたアルゴリズムのパターンを取得
    final pattern = commonAlgorithms[algorithmName];
    if (pattern == null) return false;
    
    // 操作のリストからパターンを探す
    final moveTypes = moves.map((m) => m.type).toList();
    for (int i = 0; i <= moveTypes.length - pattern.length; i++) {
      bool matches = true;
      for (int j = 0; j < pattern.length; j++) {
        if (moveTypes[i + j] != pattern[j]) {
          matches = false;
          break;
        }
      }
      if (matches) return true;
    }
    
    return false;
  }

  // ソルブのレベルを評価する
  String evaluateSolveLevel(SolveAnalysis analysis) {
    // TPSに基づいて評価
    final tps = analysis.tps;
    
    if (tps > 8.0) {
      return 'Expert';
    } else if (tps > 5.0) {
      return 'Advanced';
    } else if (tps > 3.0) {
      return 'Intermediate';
    } else if (tps > 1.5) {
      return 'Beginner';
    } else {
      return 'Novice';
    }
  }

  // 改善のためのアドバイスを提供
  List<String> provideImprovement(SolveAnalysis analysis) {
    final List<String> advices = [];
    
    // TPSが低い場合
    if (analysis.tps < 3.0) {
      advices.add('指の動きをスムーズにするためにフィンガートリックを練習しましょう');
    }
    
    // 冗長な操作が多い場合
    if (analysis.redundantMoves > analysis.moves.length * 0.2) {
      advices.add('不必要な操作が多いです。解法を見直して最適化しましょう');
    }
    
    // フェーズごとの改善点
    final phaseTPS = analysis.getPhaseTPS();
    if (phaseTPS['Cross']! < 3.0) {
      advices.add('クロスの解法をもっと効率的にしましょう');
    }
    
    if (phaseTPS['F2L']! < 2.0) {
      advices.add('F2Lのペアを見つける速度を改善しましょう');
    }
    
    if (phaseTPS['OLL']! < 4.0 || phaseTPS['PLL']! < 4.0) {
      advices.add('OLLとPLLのアルゴリズムをもっと練習しましょう');
    }
    
    return advices;
  }
}