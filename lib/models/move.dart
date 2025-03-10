// キューブの操作タイプを表す列挙型
// 各面の回転と、その逆回転、2回転（180度回転）を定義
enum MoveType {
  F, // Front face clockwise
  FPrime, // Front face counter-clockwise (F')
  F2, // Front face 180 degrees (F2)
  
  B, // Back face clockwise
  BPrime, // Back face counter-clockwise (B')
  B2, // Back face 180 degrees (B2)
  
  U, // Up face clockwise
  UPrime, // Up face counter-clockwise (U')
  U2, // Up face 180 degrees (U2)
  
  D, // Down face clockwise
  DPrime, // Down face counter-clockwise (D')
  D2, // Down face 180 degrees (D2)
  
  L, // Left face clockwise
  LPrime, // Left face counter-clockwise (L')
  L2, // Left face 180 degrees (L2)
  
  R, // Right face clockwise
  RPrime, // Right face counter-clockwise (R')
  R2, // Right face 180 degrees (R2)
}

// MoveTypeの拡張機能
extension MoveTypeExtension on MoveType {
  // 逆操作を取得
  MoveType get inverse {
    switch (this) {
      case MoveType.F: return MoveType.FPrime;
      case MoveType.FPrime: return MoveType.F;
      case MoveType.F2: return MoveType.F2; // 180度回転の逆は自分自身
      
      case MoveType.B: return MoveType.BPrime;
      case MoveType.BPrime: return MoveType.B;
      case MoveType.B2: return MoveType.B2;
      
      case MoveType.U: return MoveType.UPrime;
      case MoveType.UPrime: return MoveType.U;
      case MoveType.U2: return MoveType.U2;
      
      case MoveType.D: return MoveType.DPrime;
      case MoveType.DPrime: return MoveType.D;
      case MoveType.D2: return MoveType.D2;
      
      case MoveType.L: return MoveType.LPrime;
      case MoveType.LPrime: return MoveType.L;
      case MoveType.L2: return MoveType.L2;
      
      case MoveType.R: return MoveType.RPrime;
      case MoveType.RPrime: return MoveType.R;
      case MoveType.R2: return MoveType.R2;
    }
  }
  
  // 標準的な表記法を取得
  String get notation {
    switch (this) {
      case MoveType.F: return 'F';
      case MoveType.FPrime: return 'F\'';
      case MoveType.F2: return 'F2';
      
      case MoveType.B: return 'B';
      case MoveType.BPrime: return 'B\'';
      case MoveType.B2: return 'B2';
      
      case MoveType.U: return 'U';
      case MoveType.UPrime: return 'U\'';
      case MoveType.U2: return 'U2';
      
      case MoveType.D: return 'D';
      case MoveType.DPrime: return 'D\'';
      case MoveType.D2: return 'D2';
      
      case MoveType.L: return 'L';
      case MoveType.LPrime: return 'L\'';
      case MoveType.L2: return 'L2';
      
      case MoveType.R: return 'R';
      case MoveType.RPrime: return 'R\'';
      case MoveType.R2: return 'R2';
    }
  }
}

// キューブの一回の操作を表すクラス
class Move {
  final MoveType type; // 操作の種類
  final DateTime timestamp; // 操作が実行された時刻
  
  Move({
    required this.type,
    required this.timestamp,
  });
  
  // 標準的な表記法を取得
  String get notation => type.notation;
}