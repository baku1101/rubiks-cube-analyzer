// キューブの各面に対応する色を表す列挙型
enum Color {
  white,
  yellow,
  red,
  orange,
  green,
  blue,
}

// キューブの面を表す列挙型
enum Face {
  front, // 前
  back,  // 後
  up,    // 上
  down,  // 下
  left,  // 左
  right, // 右
}

// キューブの状態を表すクラス
class CubeState {
  // 各面の色の配置
  // 3x3の行列で表現（0,0が左上、2,2が右下）
  final Map<Face, List<List<Color>>> faces;
  
  // コンストラクタ
  CubeState({required this.faces});
  
  // 完全に揃った状態のキューブを作成
  factory CubeState.solved() {
    // 各面に一色を埋めた状態を作成
    return CubeState(
      faces: {
        Face.front: _createFaceWithColor(Color.red),
        Face.back: _createFaceWithColor(Color.orange),
        Face.up: _createFaceWithColor(Color.white),
        Face.down: _createFaceWithColor(Color.yellow),
        Face.left: _createFaceWithColor(Color.green),
        Face.right: _createFaceWithColor(Color.blue),
      },
    );
  }
  
  // 単一の色で構成された面を作成するヘルパーメソッド
  static List<List<Color>> _createFaceWithColor(Color color) {
    return List.generate(
      3, // 3行
      (_) => List.generate(
        3, // 3列
        (_) => color, // すべてのセルに同じ色
      ),
    );
  }
  
  // 特定の面の状態を取得
  List<List<Color>> getFace(Face face) {
    return faces[face]!;
  }
  
  // キューブが解けているかチェック
  bool isSolved() {
    // 各面がすべて同じ色で構成されているかをチェック
    for (final face in Face.values) {
      final faceColors = faces[face]!;
      final centerColor = faceColors[1][1]; // 中央のピースの色
      
      // 面の各ピースをチェック
      for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
          if (faceColors[i][j] != centerColor) {
            return false; // 一つでも違う色があれば未完成
          }
        }
      }
    }
    
    return true; // すべての面がそれぞれ単一の色で構成されていれば完成
  }
  
  // 現在の状態のディープコピーを作成
  CubeState copy() {
    // 各面のディープコピーを作成
    final copiedFaces = <Face, List<List<Color>>>{};
    
    for (final entry in faces.entries) {
      final face = entry.key;
      final faceColors = entry.value;
      
      // 面のディープコピー
      copiedFaces[face] = List.generate(
        3,
        (i) => List.generate(
          3,
          (j) => faceColors[i][j],
        ),
      );
    }
    
    return CubeState(faces: copiedFaces);
  }
}