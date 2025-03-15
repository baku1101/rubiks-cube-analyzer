import 'package:flutter/material.dart';
import '../models/cube_state.dart';
import '../models/move.dart';

class CubeStateUpdater {
  // 指定された回転をキューブの状態に適用
  static void updateState(CubeState state, MoveType moveType) {
    switch (moveType) {
      case MoveType.U:
        _rotateU(state);
        break;
      case MoveType.UPrime:
        _rotateUPrime(state);
        break;
      case MoveType.U2:
        _rotateU2(state);
        break;
      case MoveType.D:
        _rotateD(state);
        break;
      case MoveType.DPrime:
        _rotateDPrime(state);
        break;
      case MoveType.D2:
        _rotateD2(state);
        break;
      case MoveType.R:
        _rotateR(state);
        break;
      case MoveType.RPrime:
        _rotateRPrime(state);
        break;
      case MoveType.R2:
        _rotateR2(state);
        break;
      case MoveType.L:
        _rotateL(state);
        break;
      case MoveType.LPrime:
        _rotateLPrime(state);
        break;
      case MoveType.L2:
        _rotateL2(state);
        break;
      case MoveType.F:
        _rotateF(state);
        break;
      case MoveType.FPrime:
        _rotateFPrime(state);
        break;
      case MoveType.F2:
        _rotateF2(state);
        break;
      case MoveType.B:
        _rotateB(state);
        break;
      case MoveType.BPrime:
        _rotateBPrime(state);
        break;
      case MoveType.B2:
        _rotateB2(state);
        break;
    }
  }

  // MoveTypeからFaceを取得
  static Face getFaceFromMoveType(MoveType moveType) {
    switch (moveType) {
      case MoveType.U:
      case MoveType.UPrime:
      case MoveType.U2:
        return Face.up;
      case MoveType.D:
      case MoveType.DPrime:
      case MoveType.D2:
        return Face.down;
      case MoveType.R:
      case MoveType.RPrime:
      case MoveType.R2:
        return Face.right;
      case MoveType.L:
      case MoveType.LPrime:
      case MoveType.L2:
        return Face.left;
      case MoveType.F:
      case MoveType.FPrime:
      case MoveType.F2:
        return Face.front;
      case MoveType.B:
      case MoveType.BPrime:
      case MoveType.B2:
        return Face.back;
    }
  }

  // 反対側の面を取得
  static Face getOppositeFace(Face face) {
    switch (face) {
      case Face.front:
        return Face.back;
      case Face.back:
        return Face.front;
      case Face.up:
        return Face.down;
      case Face.down:
        return Face.up;
      case Face.left:
        return Face.right;
      case Face.right:
        return Face.left;
    }
  }

  // 面全体を90度回転（時計回り）
  static void _rotateFaceClockwise(CubeState state, Face face) {
    final faceCopy = List<List<Color>>.from(state.getFace(face));
    
    for (var i = 0; i < 3; i++) {
      for (var j = 0; j < 3; j++) {
        state.setColor(face, j, 2-i, faceCopy[i][j]);
      }
    }
  }

  // 面全体を90度回転（反時計回り）
  static void _rotateFaceCounterClockwise(CubeState state, Face face) {
    final faceCopy = List<List<Color>>.from(state.getFace(face));
    
    for (var i = 0; i < 3; i++) {
      for (var j = 0; j < 3; j++) {
        state.setColor(face, 2-j, i, faceCopy[i][j]);
      }
    }
  }

  // 面全体を180度回転
  static void _rotateFace180(CubeState state, Face face) {
    _rotateFaceClockwise(state, face);
    _rotateFaceClockwise(state, face);
  }

  // U面の回転（時計回り）
  static void _rotateU(CubeState state) {
    _rotateFaceClockwise(state, Face.up);

    final frontRow = List<Color>.from(state.getFace(Face.front)[0]);
    final rightRow = List<Color>.from(state.getFace(Face.right)[0]);
    final backRow = List<Color>.from(state.getFace(Face.back)[0]);
    final leftRow = List<Color>.from(state.getFace(Face.left)[0]);

    state.getFace(Face.front)[0] = rightRow;
    state.getFace(Face.right)[0] = backRow;
    state.getFace(Face.back)[0] = leftRow;
    state.getFace(Face.left)[0] = frontRow;
  }

  // U面の回転（反時計回り）
  static void _rotateUPrime(CubeState state) {
    _rotateFaceCounterClockwise(state, Face.up);

    final frontRow = List<Color>.from(state.getFace(Face.front)[0]);
    final rightRow = List<Color>.from(state.getFace(Face.right)[0]);
    final backRow = List<Color>.from(state.getFace(Face.back)[0]);
    final leftRow = List<Color>.from(state.getFace(Face.left)[0]);

    state.getFace(Face.front)[0] = leftRow;
    state.getFace(Face.right)[0] = frontRow;
    state.getFace(Face.back)[0] = rightRow;
    state.getFace(Face.left)[0] = backRow;
  }

  static void _rotateU2(CubeState state) {
    _rotateU(state);
    _rotateU(state);
  }

  // D面の回転（時計回り）
  static void _rotateD(CubeState state) {
    _rotateFaceClockwise(state, Face.down);

    final frontRow = List<Color>.from(state.getFace(Face.front)[2]);
    final rightRow = List<Color>.from(state.getFace(Face.right)[2]);
    final backRow = List<Color>.from(state.getFace(Face.back)[2]);
    final leftRow = List<Color>.from(state.getFace(Face.left)[2]);

    state.getFace(Face.front)[2] = leftRow;
    state.getFace(Face.right)[2] = frontRow;
    state.getFace(Face.back)[2] = rightRow;
    state.getFace(Face.left)[2] = backRow;
  }

  static void _rotateDPrime(CubeState state) {
    _rotateFaceCounterClockwise(state, Face.down);

    final frontRow = List<Color>.from(state.getFace(Face.front)[2]);
    final rightRow = List<Color>.from(state.getFace(Face.right)[2]);
    final backRow = List<Color>.from(state.getFace(Face.back)[2]);
    final leftRow = List<Color>.from(state.getFace(Face.left)[2]);

    state.getFace(Face.front)[2] = rightRow;
    state.getFace(Face.right)[2] = backRow;
    state.getFace(Face.back)[2] = leftRow;
    state.getFace(Face.left)[2] = frontRow;
  }

  static void _rotateD2(CubeState state) {
    _rotateD(state);
    _rotateD(state);
  }

  // F面の回転（時計回り）
  static void _rotateF(CubeState state) {
    _rotateFaceClockwise(state, Face.front);

    final tempRow = List<Color>.from(state.getFace(Face.up)[2]);
    
    for (var i = 0; i < 3; i++) {
      state.getFace(Face.up)[2][i] = state.getFace(Face.left)[2-i][2];
      state.getFace(Face.left)[2-i][2] = state.getFace(Face.down)[0][i];
      state.getFace(Face.down)[0][i] = state.getFace(Face.right)[i][0];
      state.getFace(Face.right)[i][0] = tempRow[i];
    }
  }

  static void _rotateFPrime(CubeState state) {
    _rotateFaceCounterClockwise(state, Face.front);

    final tempRow = List<Color>.from(state.getFace(Face.up)[2]);
    
    for (var i = 0; i < 3; i++) {
      state.getFace(Face.up)[2][i] = state.getFace(Face.right)[i][0];
      state.getFace(Face.right)[i][0] = state.getFace(Face.down)[0][i];
      state.getFace(Face.down)[0][i] = state.getFace(Face.left)[2-i][2];
      state.getFace(Face.left)[2-i][2] = tempRow[i];
    }
  }

  static void _rotateF2(CubeState state) {
    _rotateF(state);
    _rotateF(state);
  }

  // B面の回転（時計回り）
  static void _rotateB(CubeState state) {
    _rotateFaceClockwise(state, Face.back);

    final tempRow = List<Color>.from(state.getFace(Face.up)[0]);
    
    for (var i = 0; i < 3; i++) {
      state.getFace(Face.up)[0][i] = state.getFace(Face.right)[i][2];
      state.getFace(Face.right)[i][2] = state.getFace(Face.down)[2][i];
      state.getFace(Face.down)[2][i] = state.getFace(Face.left)[2-i][0];
      state.getFace(Face.left)[2-i][0] = tempRow[i];
    }
  }

  static void _rotateBPrime(CubeState state) {
    _rotateFaceCounterClockwise(state, Face.back);

    final tempRow = List<Color>.from(state.getFace(Face.up)[0]);
    
    for (var i = 0; i < 3; i++) {
      state.getFace(Face.up)[0][i] = state.getFace(Face.left)[2-i][0];
      state.getFace(Face.left)[2-i][0] = state.getFace(Face.down)[2][i];
      state.getFace(Face.down)[2][i] = state.getFace(Face.right)[i][2];
      state.getFace(Face.right)[i][2] = tempRow[i];
    }
  }

  static void _rotateB2(CubeState state) {
    _rotateB(state);
    _rotateB(state);
  }

  // R面の回転（時計回り）
  static void _rotateR(CubeState state) {
    _rotateFaceClockwise(state, Face.right);

    final tempCol = [
      state.getFace(Face.up)[0][2],
      state.getFace(Face.up)[1][2],
      state.getFace(Face.up)[2][2],
    ];
    
    for (var i = 0; i < 3; i++) {
      state.getFace(Face.up)[i][2] = state.getFace(Face.front)[i][2];
      state.getFace(Face.front)[i][2] = state.getFace(Face.down)[i][2];
      state.getFace(Face.down)[i][2] = state.getFace(Face.back)[2-i][0];
      state.getFace(Face.back)[2-i][0] = tempCol[i];
    }
  }

  static void _rotateRPrime(CubeState state) {
    _rotateFaceCounterClockwise(state, Face.right);

    final tempCol = [
      state.getFace(Face.up)[0][2],
      state.getFace(Face.up)[1][2],
      state.getFace(Face.up)[2][2],
    ];
    
    for (var i = 0; i < 3; i++) {
      state.getFace(Face.up)[i][2] = state.getFace(Face.back)[2-i][0];
      state.getFace(Face.back)[2-i][0] = state.getFace(Face.down)[i][2];
      state.getFace(Face.down)[i][2] = state.getFace(Face.front)[i][2];
      state.getFace(Face.front)[i][2] = tempCol[i];
    }
  }

  static void _rotateR2(CubeState state) {
    _rotateR(state);
    _rotateR(state);
  }

  // L面の回転（時計回り）
  static void _rotateL(CubeState state) {
    _rotateFaceClockwise(state, Face.left);

    final tempCol = [
      state.getFace(Face.up)[0][0],
      state.getFace(Face.up)[1][0],
      state.getFace(Face.up)[2][0],
    ];
    
    for (var i = 0; i < 3; i++) {
      state.getFace(Face.up)[i][0] = state.getFace(Face.back)[2-i][2];
      state.getFace(Face.back)[2-i][2] = state.getFace(Face.down)[i][0];
      state.getFace(Face.down)[i][0] = state.getFace(Face.front)[i][0];
      state.getFace(Face.front)[i][0] = tempCol[i];
    }
  }

  static void _rotateLPrime(CubeState state) {
    _rotateFaceCounterClockwise(state, Face.left);

    final tempCol = [
      state.getFace(Face.up)[0][0],
      state.getFace(Face.up)[1][0],
      state.getFace(Face.up)[2][0],
    ];
    
    for (var i = 0; i < 3; i++) {
      state.getFace(Face.up)[i][0] = state.getFace(Face.front)[i][0];
      state.getFace(Face.front)[i][0] = state.getFace(Face.down)[i][0];
      state.getFace(Face.down)[i][0] = state.getFace(Face.back)[2-i][2];
      state.getFace(Face.back)[2-i][2] = tempCol[i];
    }
  }

  static void _rotateL2(CubeState state) {
    _rotateL(state);
    _rotateL(state);
  }
}