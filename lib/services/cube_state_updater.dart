import 'package:flutter/material.dart';
import '../models/cube_state.dart';
import '../models/move.dart';

class CubeStateUpdater {
  // キューブの状態を操作に基づいて更新
  static void updateState(CubeState state, MoveType move) {
    final faces = state.faces;
    
    switch (move) {
      case MoveType.F:
        _rotateFace(faces, Face.front, true);
        _rotateFrontEdges(faces, true);
        break;
      case MoveType.FPrime:
        _rotateFace(faces, Face.front, false);
        _rotateFrontEdges(faces, false);
        break;
      case MoveType.F2:
        _rotateFace(faces, Face.front, true);
        _rotateFrontEdges(faces, true);
        _rotateFace(faces, Face.front, true);
        _rotateFrontEdges(faces, true);
        break;
      case MoveType.B:
        _rotateFace(faces, Face.back, true);
        _rotateBackEdges(faces, true);
        break;
      case MoveType.BPrime:
        _rotateFace(faces, Face.back, false);
        _rotateBackEdges(faces, false);
        break;
      case MoveType.B2:
        _rotateFace(faces, Face.back, true);
        _rotateBackEdges(faces, true);
        _rotateFace(faces, Face.back, true);
        _rotateBackEdges(faces, true);
        break;
      case MoveType.U:
        _rotateFace(faces, Face.up, true);
        _rotateUpEdges(faces, true);
        break;
      case MoveType.UPrime:
        _rotateFace(faces, Face.up, false);
        _rotateUpEdges(faces, false);
        break;
      case MoveType.U2:
        _rotateFace(faces, Face.up, true);
        _rotateUpEdges(faces, true);
        _rotateFace(faces, Face.up, true);
        _rotateUpEdges(faces, true);
        break;
      case MoveType.D:
        _rotateFace(faces, Face.down, true);
        _rotateDownEdges(faces, true);
        break;
      case MoveType.DPrime:
        _rotateFace(faces, Face.down, false);
        _rotateDownEdges(faces, false);
        break;
      case MoveType.D2:
        _rotateFace(faces, Face.down, true);
        _rotateDownEdges(faces, true);
        _rotateFace(faces, Face.down, true);
        _rotateDownEdges(faces, true);
        break;
      case MoveType.L:
        _rotateFace(faces, Face.left, true);
        _rotateLeftEdges(faces, true);
        break;
      case MoveType.LPrime:
        _rotateFace(faces, Face.left, false);
        _rotateLeftEdges(faces, false);
        break;
      case MoveType.L2:
        _rotateFace(faces, Face.left, true);
        _rotateLeftEdges(faces, true);
        _rotateFace(faces, Face.left, true);
        _rotateLeftEdges(faces, true);
        break;
      case MoveType.R:
        _rotateFace(faces, Face.right, true);
        _rotateRightEdges(faces, true);
        break;
      case MoveType.RPrime:
        _rotateFace(faces, Face.right, false);
        _rotateRightEdges(faces, false);
        break;
      case MoveType.R2:
        _rotateFace(faces, Face.right, true);
        _rotateRightEdges(faces, true);
        _rotateFace(faces, Face.right, true);
        _rotateRightEdges(faces, true);
        break;
    }
  }

  // 特定の面を回転させる（時計回りまたは反時計回り）
  static void _rotateFace(Map<Face, List<List<Color>>> faces, Face face, bool clockwise) {
    final currentFace = faces[face]!;
    final size = currentFace.length;
    
    // 面を回転させるための一時的なコピーを作成
    final temp = List.generate(
      size,
      (i) => List.generate(
        size,
        (j) => currentFace[i][j],
      ),
    );
    
    // 新しい配置に更新
    for (int i = 0; i < size; i++) {
      for (int j = 0; j < size; j++) {
        if (clockwise) {
          faces[face]![i][j] = temp[size - j - 1][i];
        } else {
          faces[face]![i][j] = temp[j][size - i - 1];
        }
      }
    }
  }

  // 前面のエッジを回転
  static void _rotateFrontEdges(Map<Face, List<List<Color>>> faces, bool clockwise) {
    final size = faces[Face.front]!.length;
    final temp = List<Color>.filled(size, Color.white);
    
    if (clockwise) {
      // 上面の底辺を保存
      for (int i = 0; i < size; i++) {
        temp[i] = faces[Face.up]![size - 1][i];
      }
      
      // 左面の右辺を上面の底辺へ
      for (int i = 0; i < size; i++) {
        faces[Face.up]![size - 1][i] = faces[Face.left]![size - 1 - i][size - 1];
      }
      
      // 下面の上辺を左面の右辺へ
      for (int i = 0; i < size; i++) {
        faces[Face.left]![i][size - 1] = faces[Face.down]![0][i];
      }
      
      // 右面の左辺を下面の上辺へ
      for (int i = 0; i < size; i++) {
        faces[Face.down]![0][i] = faces[Face.right]![size - 1 - i][0];
      }
      
      // 保存した上面の底辺を右面の左辺へ
      for (int i = 0; i < size; i++) {
        faces[Face.right]![i][0] = temp[i];
      }
    } else {
      // 反時計回りの場合は逆の手順
      // 上面の底辺を保存
      for (int i = 0; i < size; i++) {
        temp[i] = faces[Face.up]![size - 1][i];
      }
      
      // 右面の左辺を上面の底辺へ
      for (int i = 0; i < size; i++) {
        faces[Face.up]![size - 1][i] = faces[Face.right]![i][0];
      }
      
      // 下面の上辺を右面の左辺へ
      for (int i = 0; i < size; i++) {
        faces[Face.right]![i][0] = faces[Face.down]![0][size - 1 - i];
      }
      
      // 左面の右辺を下面の上辺へ
      for (int i = 0; i < size; i++) {
        faces[Face.down]![0][i] = faces[Face.left]![i][size - 1];
      }
      
      // 保存した上面の底辺を左面の右辺へ
      for (int i = 0; i < size; i++) {
        faces[Face.left]![i][size - 1] = temp[size - 1 - i];
      }
    }
  }

  // 後面のエッジを回転
  static void _rotateBackEdges(Map<Face, List<List<Color>>> faces, bool clockwise) {
    final size = faces[Face.back]!.length;
    final temp = List<Color>.filled(size, Color.white);
    
    if (clockwise) {
      // 上面の上辺を保存
      for (int i = 0; i < size; i++) {
        temp[i] = faces[Face.up]![0][i];
      }
      
      // 右面の右辺を上面の上辺へ
      for (int i = 0; i < size; i++) {
        faces[Face.up]![0][i] = faces[Face.right]![i][size - 1];
      }
      
      // 下面の底辺を右面の右辺へ
      for (int i = 0; i < size; i++) {
        faces[Face.right]![i][size - 1] = faces[Face.down]![size - 1][size - 1 - i];
      }
      
      // 左面の左辺を下面の底辺へ
      for (int i = 0; i < size; i++) {
        faces[Face.down]![size - 1][i] = faces[Face.left]![i][0];
      }
      
      // 保存した上面の上辺を左面の左辺へ
      for (int i = 0; i < size; i++) {
        faces[Face.left]![i][0] = temp[size - 1 - i];
      }
    } else {
      // 反時計回りの場合は逆の手順
      for (int i = 0; i < size; i++) {
        temp[i] = faces[Face.up]![0][i];
      }
      
      for (int i = 0; i < size; i++) {
        faces[Face.up]![0][i] = faces[Face.left]![i][0];
      }
      
      for (int i = 0; i < size; i++) {
        faces[Face.left]![i][0] = faces[Face.down]![size - 1][size - 1 - i];
      }
      
      for (int i = 0; i < size; i++) {
        faces[Face.down]![size - 1][i] = faces[Face.right]![i][size - 1];
      }
      
      for (int i = 0; i < size; i++) {
        faces[Face.right]![i][size - 1] = temp[i];
      }
    }
  }

  // 上面のエッジを回転
  static void _rotateUpEdges(Map<Face, List<List<Color>>> faces, bool clockwise) {
    final size = faces[Face.up]!.length;
    final temp = List<Color>.filled(size, Color.white);
    
    if (clockwise) {
      // 前面の上辺を保存
      for (int i = 0; i < size; i++) {
        temp[i] = faces[Face.front]![0][i];
      }
      
      // 右面の上辺を前面の上辺へ
      for (int i = 0; i < size; i++) {
        faces[Face.front]![0][i] = faces[Face.right]![0][i];
      }
      
      // 後面の上辺を右面の上辺へ
      for (int i = 0; i < size; i++) {
        faces[Face.right]![0][i] = faces[Face.back]![0][i];
      }
      
      // 左面の上辺を後面の上辺へ
      for (int i = 0; i < size; i++) {
        faces[Face.back]![0][i] = faces[Face.left]![0][i];
      }
      
      // 保存した前面の上辺を左面の上辺へ
      for (int i = 0; i < size; i++) {
        faces[Face.left]![0][i] = temp[i];
      }
    } else {
      // 反時計回りの場合は逆の手順
      for (int i = 0; i < size; i++) {
        temp[i] = faces[Face.front]![0][i];
      }
      
      for (int i = 0; i < size; i++) {
        faces[Face.front]![0][i] = faces[Face.left]![0][i];
      }
      
      for (int i = 0; i < size; i++) {
        faces[Face.left]![0][i] = faces[Face.back]![0][i];
      }
      
      for (int i = 0; i < size; i++) {
        faces[Face.back]![0][i] = faces[Face.right]![0][i];
      }
      
      for (int i = 0; i < size; i++) {
        faces[Face.right]![0][i] = temp[i];
      }
    }
  }

  // 下面のエッジを回転
  static void _rotateDownEdges(Map<Face, List<List<Color>>> faces, bool clockwise) {
    final size = faces[Face.down]!.length;
    final temp = List<Color>.filled(size, Color.white);
    
    if (clockwise) {
      // 前面の底辺を保存
      for (int i = 0; i < size; i++) {
        temp[i] = faces[Face.front]![size - 1][i];
      }
      
      // 左面の底辺を前面の底辺へ
      for (int i = 0; i < size; i++) {
        faces[Face.front]![size - 1][i] = faces[Face.left]![size - 1][i];
      }
      
      // 後面の底辺を左面の底辺へ
      for (int i = 0; i < size; i++) {
        faces[Face.left]![size - 1][i] = faces[Face.back]![size - 1][i];
      }
      
      // 右面の底辺を後面の底辺へ
      for (int i = 0; i < size; i++) {
        faces[Face.back]![size - 1][i] = faces[Face.right]![size - 1][i];
      }
      
      // 保存した前面の底辺を右面の底辺へ
      for (int i = 0; i < size; i++) {
        faces[Face.right]![size - 1][i] = temp[i];
      }
    } else {
      // 反時計回りの場合は逆の手順
      for (int i = 0; i < size; i++) {
        temp[i] = faces[Face.front]![size - 1][i];
      }
      
      for (int i = 0; i < size; i++) {
        faces[Face.front]![size - 1][i] = faces[Face.right]![size - 1][i];
      }
      
      for (int i = 0; i < size; i++) {
        faces[Face.right]![size - 1][i] = faces[Face.back]![size - 1][i];
      }
      
      for (int i = 0; i < size; i++) {
        faces[Face.back]![size - 1][i] = faces[Face.left]![size - 1][i];
      }
      
      for (int i = 0; i < size; i++) {
        faces[Face.left]![size - 1][i] = temp[i];
      }
    }
  }

  // 左面のエッジを回転
  static void _rotateLeftEdges(Map<Face, List<List<Color>>> faces, bool clockwise) {
    final size = faces[Face.left]!.length;
    final temp = List<Color>.filled(size, Color.white);
    
    if (clockwise) {
      // 上面の左辺を保存
      for (int i = 0; i < size; i++) {
        temp[i] = faces[Face.up]![i][0];
      }
      
      // 前面の左辺を上面の左辺へ
      for (int i = 0; i < size; i++) {
        faces[Face.up]![i][0] = faces[Face.front]![i][0];
      }
      
      // 下面の左辺を前面の左辺へ
      for (int i = 0; i < size; i++) {
        faces[Face.front]![i][0] = faces[Face.down]![i][0];
      }
      
      // 後面の右辺を下面の左辺へ
      for (int i = 0; i < size; i++) {
        faces[Face.down]![i][0] = faces[Face.back]![size - 1 - i][size - 1];
      }
      
      // 保存した上面の左辺を後面の右辺へ
      for (int i = 0; i < size; i++) {
        faces[Face.back]![i][size - 1] = temp[size - 1 - i];
      }
    } else {
      // 反時計回りの場合は逆の手順
      for (int i = 0; i < size; i++) {
        temp[i] = faces[Face.up]![i][0];
      }
      
      for (int i = 0; i < size; i++) {
        faces[Face.up]![i][0] = faces[Face.back]![size - 1 - i][size - 1];
      }
      
      for (int i = 0; i < size; i++) {
        faces[Face.back]![i][size - 1] = faces[Face.down]![size - 1 - i][0];
      }
      
      for (int i = 0; i < size; i++) {
        faces[Face.down]![i][0] = faces[Face.front]![i][0];
      }
      
      for (int i = 0; i < size; i++) {
        faces[Face.front]![i][0] = temp[i];
      }
    }
  }

  // 右面のエッジを回転
  static void _rotateRightEdges(Map<Face, List<List<Color>>> faces, bool clockwise) {
    final size = faces[Face.right]!.length;
    final temp = List<Color>.filled(size, Color.white);
    
    if (clockwise) {
      // 上面の右辺を保存
      for (int i = 0; i < size; i++) {
        temp[i] = faces[Face.up]![i][size - 1];
      }
      
      // 後面の左辺を上面の右辺へ
      for (int i = 0; i < size; i++) {
        faces[Face.up]![i][size - 1] = faces[Face.back]![size - 1 - i][0];
      }
      
      // 下面の右辺を後面の左辺へ
      for (int i = 0; i < size; i++) {
        faces[Face.back]![i][0] = faces[Face.down]![size - 1 - i][size - 1];
      }
      
      // 前面の右辺を下面の右辺へ
      for (int i = 0; i < size; i++) {
        faces[Face.down]![i][size - 1] = faces[Face.front]![i][size - 1];
      }
      
      // 保存した上面の右辺を前面の右辺へ
      for (int i = 0; i < size; i++) {
        faces[Face.front]![i][size - 1] = temp[i];
      }
    } else {
      // 反時計回りの場合は逆の手順
      for (int i = 0; i < size; i++) {
        temp[i] = faces[Face.up]![i][size - 1];
      }
      
      for (int i = 0; i < size; i++) {
        faces[Face.up]![i][size - 1] = faces[Face.front]![i][size - 1];
      }
      
      for (int i = 0; i < size; i++) {
        faces[Face.front]![i][size - 1] = faces[Face.down]![i][size - 1];
      }
      
      for (int i = 0; i < size; i++) {
        faces[Face.down]![i][size - 1] = faces[Face.back]![size - 1 - i][0];
      }
      
      for (int i = 0; i < size; i++) {
        faces[Face.back]![i][0] = temp[size - 1 - i];
      }
    }
  }

  // 操作タイプから面を取得
  static Face getFaceFromMoveType(MoveType moveType) {
    final notationStart = moveType.toString().split('.').last[0];
    switch (notationStart) {
      case 'F': return Face.front;
      case 'B': return Face.back;
      case 'U': return Face.up;
      case 'D': return Face.down;
      case 'L': return Face.left;
      case 'R': return Face.right;
      default: return Face.front;
    }
  }

  // 反対の面を取得
  static Face getOppositeFace(Face face) {
    switch (face) {
      case Face.front: return Face.back;
      case Face.back: return Face.front;
      case Face.up: return Face.down;
      case Face.down: return Face.up;
      case Face.left: return Face.right;
      case Face.right: return Face.left;
    }
  }
}