import 'package:flutter_test/flutter_test.dart';
import 'package:rubiks_cube_analyzer/models/cube_state.dart';
import 'package:rubiks_cube_analyzer/models/move.dart';
import 'package:rubiks_cube_analyzer/models/solve_analysis.dart';
import 'package:rubiks_cube_analyzer/services/analytics_service.dart';

void main() {
  group('CubeState Tests', () {
    test('初期状態でソルブされている状態になっていること', () {
      final cubeState = CubeState.solved();
      
      expect(cubeState.isSolved(), isTrue);
      
      // 各面の色が正しいことを確認
      expect(cubeState.getFace(Face.front)[1][1], equals(Color.red));
      expect(cubeState.getFace(Face.back)[1][1], equals(Color.orange));
      expect(cubeState.getFace(Face.up)[1][1], equals(Color.white));
      expect(cubeState.getFace(Face.down)[1][1], equals(Color.yellow));
      expect(cubeState.getFace(Face.left)[1][1], equals(Color.green));
      expect(cubeState.getFace(Face.right)[1][1], equals(Color.blue));
    });
    
    test('copy メソッドが正しく動作すること', () {
      final original = CubeState.solved();
      final copy = original.copy();
      
      // コピーされた状態が元の状態と同じであることを確認
      for (final face in Face.values) {
        for (int i = 0; i < 3; i++) {
          for (int j = 0; j < 3; j++) {
            expect(copy.getFace(face)[i][j], equals(original.getFace(face)[i][j]));
          }
        }
      }
      
      // コピーを変更しても元のオブジェクトに影響がないことを確認
      final modifiedFaces = copy.faces;
      modifiedFaces[Face.front]![0][0] = Color.blue;
      
      expect(copy.getFace(Face.front)[0][0], equals(Color.blue)); // 変更されている
      expect(original.getFace(Face.front)[0][0], equals(Color.red)); // 元のままである
    });
  });
  
  group('Move Tests', () {
    test('操作の表記が正しいこと', () {
      final moveF = Move(type: MoveType.F, timestamp: DateTime.now());
      final moveRPrime = Move(type: MoveType.RPrime, timestamp: DateTime.now());
      final moveU2 = Move(type: MoveType.U2, timestamp: DateTime.now());
      
      expect(moveF.notation, equals('F'));
      expect(moveRPrime.notation, equals('R\''));
      expect(moveU2.notation, equals('U2'));
    });
    
    test('逆操作が正しく計算されること', () {
      expect(MoveType.F.inverse, equals(MoveType.FPrime));
      expect(MoveType.RPrime.inverse, equals(MoveType.R));
      expect(MoveType.U2.inverse, equals(MoveType.U2)); // 180度回転は自分自身が逆操作
    });
  });
  
  group('Analytics Service Tests', () {
    test('TPSが正しく計算されること', () {
      final analyticsService = AnalyticsService();
      
      final startTime = DateTime.now();
      final endTime = startTime.add(const Duration(seconds: 10));
      
      final moves = List.generate(
        20,
        (i) => Move(
          type: i % 2 == 0 ? MoveType.R : MoveType.L,
          timestamp: startTime.add(Duration(milliseconds: i * 500)),
        ),
      );
      
      final analysis = analyticsService.analyzeSolve(moves, startTime, endTime);
      
      // 20手 ÷ 10秒 = 2.0 TPS
      expect(analysis.tps, closeTo(2.0, 0.1));
    });
    
    test('空のムーブリストの場合に正しく処理されること', () {
      final analyticsService = AnalyticsService();
      
      final startTime = DateTime.now();
      final endTime = startTime.add(const Duration(seconds: 5));
      
      final analysis = analyticsService.analyzeSolve([], startTime, endTime);
      
      expect(analysis.solveTime.inSeconds, equals(5));
      expect(analysis.tps, equals(0.0));
      expect(analysis.moves.isEmpty, isTrue);
      expect(analysis.redundantMoves, equals(0));
    });
    
    test('冗長な操作が正しく検出されること', () {
      final analyticsService = AnalyticsService();
      
      final startTime = DateTime.now();
      final timestamp1 = startTime.add(const Duration(milliseconds: 100));
      final timestamp2 = startTime.add(const Duration(milliseconds: 200));
      
      // R, R'の組み合わせ（互いに打ち消しあう）
      final moves = [
        Move(type: MoveType.R, timestamp: timestamp1),
        Move(type: MoveType.RPrime, timestamp: timestamp2),
      ];
      
      final analysis = analyticsService.analyzeSolve(moves, startTime, timestamp2);
      
      // 冗長な操作が2つ検出されるはず（R, R'の両方）
      expect(analysis.redundantMoves, equals(2));
    });
  });
}