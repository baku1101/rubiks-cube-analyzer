import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rubiks_cube_analyzer/models/cube_state.dart';

void main() {
  group('CubeState Tests', () {
    test('Should create solved cube state', () {
      final solved = CubeState.solved();
      
      // 各面の色が正しいことを確認
      expect(solved.getFace(Face.front).every((row) => 
        row.every((color) => color == CubeColor.red)), isTrue);
      expect(solved.getFace(Face.back).every((row) => 
        row.every((color) => color == CubeColor.orange)), isTrue);
      expect(solved.getFace(Face.up).every((row) => 
        row.every((color) => color == CubeColor.white)), isTrue);
      expect(solved.getFace(Face.down).every((row) => 
        row.every((color) => color == CubeColor.yellow)), isTrue);
      expect(solved.getFace(Face.left).every((row) => 
        row.every((color) => color == CubeColor.green)), isTrue);
      expect(solved.getFace(Face.right).every((row) => 
        row.every((color) => color == CubeColor.blue)), isTrue);

      // ソルブ状態であることを確認
      expect(solved.isSolved, isTrue);
    });

    test('Should detect unsolved state', () {
      final scrambled = CubeState.solved();
      scrambled.setColor(Face.front, 0, 0, CubeColor.blue);
      expect(scrambled.isSolved, isFalse);
    });

    test('Should copy cube state correctly', () {
      final original = CubeState.solved();
      final copy = original.copy();

      // 同じ状態であることを確認
      for (final face in Face.values) {
        for (var i = 0; i < 3; i++) {
          for (var j = 0; j < 3; j++) {
            expect(copy.getColor(face, i, j), equals(original.getColor(face, i, j)));
          }
        }
      }

      // コピーを変更しても元の状態に影響しないことを確認
      copy.setColor(Face.front, 0, 0, CubeColor.blue);
      expect(original.getColor(Face.front, 0, 0), equals(CubeColor.red));
      expect(copy.getColor(Face.front, 0, 0), equals(CubeColor.blue));
    });

    test('Should parse V4 data correctly', () {
      // テスト用のV4データを作成（各面が単色の状態）
      final v4Data = [
        0x00000000, // Up面（白）
        0x24924924, // Right面（青）
        0x12492492, // Front面（赤）
        0x36DB6DB6, // Down面（黄）
        0x24924924, // Left面（緑）
        0x1B6DB6DB, // Back面（オレンジ）
        0x00        // チェックサム
      ];

      final state = CubeState.fromV4Data(v4Data);
      expect(state, isNotNull);

      // 各面の色が正しく解析されているか確認
      void checkFaceColor(Face face, Color expectedColor) {
        final faceData = state.getFace(face);
        for (var row in faceData) {
          for (var color in row) {
            expect(color, equals(expectedColor));
          }
        }
      }

      checkFaceColor(Face.up, CubeColor.white);
      checkFaceColor(Face.right, CubeColor.blue);
      checkFaceColor(Face.front, CubeColor.red);
      checkFaceColor(Face.down, CubeColor.yellow);
      checkFaceColor(Face.left, CubeColor.green);
      checkFaceColor(Face.back, CubeColor.orange);
    });
  });
}