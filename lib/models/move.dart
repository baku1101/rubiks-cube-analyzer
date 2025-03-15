
// 回転の種類を定義
enum MoveType {
  U,    // 上面時計回り
  UPrime, // 上面反時計回り
  U2,    // 上面180度
  D,    // 下面時計回り
  DPrime, // 下面反時計回り
  D2,    // 下面180度
  R,    // 右面時計回り
  RPrime, // 右面反時計回り
  R2,    // 右面180度
  L,    // 左面時計回り
  LPrime, // 左面反時計回り
  L2,    // 左面180度
  F,    // 前面時計回り
  FPrime, // 前面反時計回り
  F2,    // 前面180度
  B,    // 後面時計回り
  BPrime, // 後面反時計回り
  B2,    // 後面180度
}

// MoveType の拡張メソッド
extension MoveTypeExtension on MoveType {
  // 逆の動きを返す
  MoveType get inverse {
    switch (this) {
      case MoveType.U: return MoveType.UPrime;
      case MoveType.UPrime: return MoveType.U;
      case MoveType.U2: return MoveType.U2;
      case MoveType.D: return MoveType.DPrime;
      case MoveType.DPrime: return MoveType.D;
      case MoveType.D2: return MoveType.D2;
      case MoveType.R: return MoveType.RPrime;
      case MoveType.RPrime: return MoveType.R;
      case MoveType.R2: return MoveType.R2;
      case MoveType.L: return MoveType.LPrime;
      case MoveType.LPrime: return MoveType.L;
      case MoveType.L2: return MoveType.L2;
      case MoveType.F: return MoveType.FPrime;
      case MoveType.FPrime: return MoveType.F;
      case MoveType.F2: return MoveType.F2;
      case MoveType.B: return MoveType.BPrime;
      case MoveType.BPrime: return MoveType.B;
      case MoveType.B2: return MoveType.B2;
    }
  }

  // キューブ記法での表記を返す
  String get notation {
    switch (this) {
      case MoveType.U: return "U";
      case MoveType.UPrime: return "U'";
      case MoveType.U2: return "U2";
      case MoveType.D: return "D";
      case MoveType.DPrime: return "D'";
      case MoveType.D2: return "D2";
      case MoveType.R: return "R";
      case MoveType.RPrime: return "R'";
      case MoveType.R2: return "R2";
      case MoveType.L: return "L";
      case MoveType.LPrime: return "L'";
      case MoveType.L2: return "L2";
      case MoveType.F: return "F";
      case MoveType.FPrime: return "F'";
      case MoveType.F2: return "F2";
      case MoveType.B: return "B";
      case MoveType.BPrime: return "B'";
      case MoveType.B2: return "B2";
    }
  }
}

// 一回の回転を表すクラス
class Move {
  final MoveType type;
  final DateTime timestamp;

  const Move({
    required this.type,
    required this.timestamp,
  });

  // キューブ記法での表記
  String get notation => type.notation;
  
  // 逆の動きを作成
  Move inverse() {
    return Move(
      type: type.inverse,
      timestamp: timestamp,
    );
  }

  @override
  String toString() => notation;
}