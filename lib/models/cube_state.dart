import 'package:flutter/material.dart';

// キューブの面を表す列挙型
enum Face {
  front,  // 前面
  back,   // 後面
  up,     // 上面
  down,   // 下面
  left,   // 左面
  right,  // 右面
}

// キューブの色を定義
class CubeColor {
  static const Color red = Colors.red;     // 前面の色
  static const Color orange = Colors.orange; // 後面の色
  static const Color white = Colors.white;   // 上面の色
  static const Color yellow = Colors.yellow; // 下面の色
  static const Color green = Colors.green;   // 左面の色
  static const Color blue = Colors.blue;     // 右面の色

  static Color getColorForFace(Face face) {
    switch (face) {
      case Face.front: return red;
      case Face.back: return orange;
      case Face.up: return white;
      case Face.down: return yellow;
      case Face.left: return green;
      case Face.right: return blue;
    }
  }

  // V4のカラーインデックスからColorに変換
  static Color fromV4ColorIndex(int index) {
    switch (index) {
      case 0: return white;   // 上面
      case 1: return red;     // 前面
      case 2: return green;   // 左面
      case 3: return orange;  // 後面
      case 4: return blue;    // 右面
      case 5: return yellow;  // 下面
      default: return Colors.grey;
    }
  }
}

// ステッカーを表すクラス
class Sticker {
  final Face face;
  final int row;
  final int col;

  const Sticker(this.face, this.row, this.col);

  @override
  String toString() => '$face[$row][$col]';
}

// キューブの状態を表すクラス
class CubeState {
  final Map<Face, List<List<Color>>> faces;
  final List<int> _corners;  // コーナーの位置と向き
  final List<int> _edges;    // エッジの位置と向き

  CubeState._internal({
    required this.faces,
    List<int>? corners,
    List<int>? edges,
  }) : _corners = corners ?? List.generate(8, (i) => i),
       _edges = edges ?? List.generate(12, (i) => i);

  // 完成状態のキューブを生成
  factory CubeState.solved() {
    return CubeState._internal(
      faces: {
        Face.front: List.generate(3, (_) => List.filled(3, CubeColor.red)),
        Face.back: List.generate(3, (_) => List.filled(3, CubeColor.orange)),
        Face.up: List.generate(3, (_) => List.filled(3, CubeColor.white)),
        Face.down: List.generate(3, (_) => List.filled(3, CubeColor.yellow)),
        Face.left: List.generate(3, (_) => List.filled(3, CubeColor.green)),
        Face.right: List.generate(3, (_) => List.filled(3, CubeColor.blue)),
      },
    );
  }

  // コーナーとエッジの情報から状態を生成
  factory CubeState.fromCornerAndEdge(List<int> corners, List<int> edges) {
    if (corners.length != 8) {
      throw ArgumentError('コーナーデータは8個必要です');
    }
    if (edges.length != 12) {
      throw ArgumentError('エッジデータは12個必要です');
    }

    return CubeState._internal(
      faces: CubeState.solved().faces,  // 一時的な面の状態
      corners: corners,
      edges: edges,
    );
  }

  // V4のデータからキューブの状態を生成
  factory CubeState.fromV4Data(List<int> data) {
    if (data.length < 7) {
      throw ArgumentError('Invalid data length for V4 cube state');
    }

    // V4のデータを解析
    final faces = {
      Face.up: _decodeV4Face(data[0]),
      Face.right: _decodeV4Face(data[1]),
      Face.front: _decodeV4Face(data[2]),
      Face.down: _decodeV4Face(data[3]),
      Face.left: _decodeV4Face(data[4]),
      Face.back: _decodeV4Face(data[5]),
    };

    return CubeState._internal(faces: faces);
  }

  // V4のフェースデータを解析
  static List<List<Color>> _decodeV4Face(int data) {
    final face = List.generate(3, (_) => List<Color>.filled(3, Colors.grey));
    var value = data;

    for (var i = 0; i < 3; i++) {
      for (var j = 0; j < 3; j++) {
        final colorIndex = value & 0x07;
        face[i][j] = CubeColor.fromV4ColorIndex(colorIndex);
        value >>= 3;
      }
    }

    return face;
  }

  // コーナーとエッジの状態を取得
  List<int> get corners => List.unmodifiable(_corners);
  List<int> get edges => List.unmodifiable(_edges);

  // パリティチェック
  bool hasValidParity() {
    var cornerPerm = 0;
    var edgePerm = 0;
    var cornerOri = 0;
    var edgeOri = 0;

    // コーナーのパリティをチェック
    for (var i = 0; i < 8; i++) {
      cornerPerm ^= _corners[i] >> 3;
      cornerOri += _corners[i] & 0x7;
    }
    cornerOri %= 3;

    // エッジのパリティをチェック
    for (var i = 0; i < 12; i++) {
      edgePerm ^= _edges[i] >> 1;
      edgeOri ^= _edges[i] & 0x1;
    }

    // パリティチェック
    return cornerPerm == 0 && cornerOri == 0 && edgePerm == 0 && edgeOri == 0;
  }

  // 指定された面のステッカーの色を取得
  List<List<Color>> getFace(Face face) {
    return faces[face]!;
  }

  // キューブの状態をコピー
  CubeState copy() {
    final newFaces = <Face, List<List<Color>>>{};
    for (final face in faces.entries) {
      newFaces[face.key] = List.generate(
        3,
        (i) => List.from(face.value[i]),
      );
    }
    return CubeState._internal(
      faces: newFaces,
      corners: List.from(_corners),
      edges: List.from(_edges),
    );
  }

  // キューブが完成状態かどうか
  bool get isSolved {
    // 面の状態チェック
    for (final face in faces.entries) {
      final color = face.value[1][1]; // 中央のステッカーの色
      for (var i = 0; i < 3; i++) {
        for (var j = 0; j < 3; j++) {
          if (face.value[i][j] != color) return false;
        }
      }
    }

    // コーナーとエッジの状態チェック
    for (var i = 0; i < 8; i++) {
      if (_corners[i] != i) return false;
    }
    for (var i = 0; i < 12; i++) {
      if (_edges[i] != i) return false;
    }

    return true;
  }

  // 指定された位置のステッカーの色を取得
  Color getColor(Face face, int row, int col) {
    return faces[face]![row][col];
  }

  // 指定された位置のステッカーの色を設定
  void setColor(Face face, int row, int col, Color color) {
    faces[face]![row][col] = color;
  }

  // 面全体の色を設定
  void setFace(Face face, List<List<Color>> colors) {
    faces[face] = colors;
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('CubeState:');
    for (final face in Face.values) {
      buffer.writeln('$face:');
      for (var i = 0; i < 3; i++) {
        buffer.writeln(faces[face]![i].map((c) => _colorToString(c)).join(' '));
      }
    }
    buffer.writeln('Corners: ${_corners.join(', ')}');
    buffer.writeln('Edges: ${_edges.join(', ')}');
    return buffer.toString();
  }

  String _colorToString(Color color) {
    if (color == CubeColor.red) return 'R';
    if (color == CubeColor.orange) return 'O';
    if (color == CubeColor.white) return 'W';
    if (color == CubeColor.yellow) return 'Y';
    if (color == CubeColor.green) return 'G';
    if (color == CubeColor.blue) return 'B';
    return '?';
  }
}