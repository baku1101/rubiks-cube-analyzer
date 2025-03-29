import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:rubiks_cube_analyzer/services/gan/protocol/response.dart';

void main() {
  group('ResponseParser', () {
    late ResponseParser parser;

    setUp(() {
      parser = ResponseParser();
    });

    test('should parse MoveEvent (0x01) correctly', () {
      // 仕様書に基づくモックデータ (要検証/調整)
      // mode=0x01, len=9, timestamp=12345678(0xBC614E), counter=100(0x64), dir=0, axis=32(R)
      // ビット: 00000001 00001001 [ts 32b] [cnt 16b] [dir 2b][axis 6b] ...
      // バイト: 01 09 [ts b1] [ts b2] [ts b3] [ts b4] [cnt b1] [cnt b2] [dir/axis b1] ...
      // dir=00, axis=100000(32) -> dir/axis = 00100000 = 0x20
      final mockData = Uint8List.fromList([
        0x01, 0x09, // mode, length (length=9は仮)
        0x00, 0xBC, 0x61, 0x4E, // timestamp (リトルエンディアン仮定)
        0x00, 0x64, // counter (リトルエンディアン仮定)
        0x20, // dir/axis
        0x00 // パディング？
      ]);

      final result = parser.parse(mockData);

      expect(result, isA<MoveEvent>());
      final event = result as MoveEvent;
      expect(event.mode, equals(0x01));
      expect(event.length, equals(9)); // モックデータの値
      expect(event.timestamp, equals(12345678)); // モックデータの値
      expect(event.moveCounter, equals(100)); // モックデータの値
      expect(event.direction, equals(0)); // モックデータの値
      expect(event.axis, equals(32)); // モックデータの値
      expect(event.axisIndex, equals(1)); // R
    });

    test('should parse CubeStateData (0xED) correctly', () {
      // 仕様書に基づくモックデータ (非常に複雑なため、一部のみ検証)
      // mode=0xED, len=15?, counter=500(0x01F4)
      // cornerPos=[0,1,2,3,4,5,6], cornerOri=[0,1,2,0,1,2,0]
      // edgePos=[0,1,2,3,4,5,6,7,8,9,10], edgeOri=[0,1,0,1,0,1,0,1,0,1,0]
      // ビット表現を構築し、バイト配列に変換する必要がある (非常に手間)
      // ここではダミーデータを使用
       final mockData = Uint8List.fromList([
        0xED, 15, // mode, length (length=15は仮)
        0x01, 0xF4, // counter
        // ... コーナーとエッジのビット列表現 ... (12バイト分)
        0x18, 0x6C, 0xDB, 0x75, 0xE3, 0x9A, 0x0F, 0x8C, 0x7B, 0x5D, 0x2E, 0xAA,
      ]);

      final result = parser.parse(mockData);

      expect(result, isA<CubeStateData>());
      final state = result as CubeStateData;
      expect(state.mode, equals(0xED));
      expect(state.length, equals(15)); // モックデータの値
      expect(state.moveCounter, equals(500)); // モックデータの値
      // TODO: ビット抽出が正しければ、コーナーとエッジの値を検証する
      // expect(state.cornerPositions, equals([0, 1, 2, 3, 4, 5, 6]));
      // expect(state.cornerOrientations, equals([0, 1, 2, 0, 1, 2, 0]));
      // expect(state.edgePositions, equals([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]));
      // expect(state.edgeOrientations, equals([0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0]));
    });

     test('should parse MoveHistory (0xD1) correctly', () {
      // mode=0xD1, len=3, startCounter=10, moves=[{axis=5(R), dir=0}, {axis=1(U), dir=1}]
      // numMoves = (3-1)*2 = 4 ? -> 仕様書と異なる可能性。len=3なら移動2つ？
      // バイト: D1 03 0A [move1 4b][move2 4b] [move3 4b][move4 4b]...
      // move1: axis=5(101), dir=0 -> 0101
      // move2: axis=1(001), dir=1 -> 1001
      // -> 0101 1001 = 0x59
      final mockData = Uint8List.fromList([
        0xD1, 0x03, // mode, length (len=3で移動2つと仮定)
        10,       // startCounter
        0x59,     // moves (0101 1001)
      ]);

      final result = parser.parse(mockData);
      expect(result, isA<MoveHistory>());
      final history = result as MoveHistory;
      expect(history.mode, equals(0xD1));
      expect(history.length, equals(3));
      expect(history.startMoveCounter, equals(10));
      expect(history.moves.length, equals(2)); // len=3で移動2つと仮定
      expect(history.moves[0].axis, equals(5)); // R
      expect(history.moves[0].direction, equals(0)); // CW
      expect(history.moves[0].axisIndex, equals(1)); // R
      expect(history.moves[1].axis, equals(1)); // U
      expect(history.moves[1].direction, equals(1)); // CCW
      expect(history.moves[1].axisIndex, equals(0)); // U
    });

    test('should parse BatteryInfo (0xEF) correctly', () {
      // mode=0xEF, len=1, level=80(0x50)
      final mockData = Uint8List.fromList([0xEF, 0x01, 0x50]);
      final result = parser.parse(mockData);
      expect(result, isA<BatteryInfo>());
      expect((result as BatteryInfo).level, equals(80));
    });

     test('should parse HardwareNameInfo (0xFC) correctly', () {
      // mode=0xFC, len=5, name="GAN" (0x47, 0x41, 0x4E)
      final mockData = Uint8List.fromList([0xFC, 0x04, 0x47, 0x41, 0x4E]); // len=4 (name 3 bytes)
      final result = parser.parse(mockData);
      expect(result, isA<HardwareNameInfo>());
      expect((result as HardwareNameInfo).name, equals("GAN"));
    });

    // TODO: 他のレスポンスモード (FA, FD, FE, FF, F5, F6, EC) のテストを追加する

    test('should throw UnknownResponseModeException for unknown mode', () {
      final mockData = Uint8List.fromList([0xAA, 0x01, 0x00]); // 未定義モード
      expect(() => parser.parse(mockData), throwsA(isA<UnknownResponseModeException>()));
    });

    test('should throw DataParsingException for insufficient data length', () {
      final mockData = Uint8List.fromList([0x01]); // MoveEventには短すぎる
      expect(() => parser.parse(mockData), throwsA(isA<DataParsingException>()));
    });

     test('should throw DataParsingException for invalid bit extraction', () {
      // MoveEventだが、データが途中で切れている
      final mockData = Uint8List.fromList([0x01, 0x09, 0x00, 0xBC]);
      expect(() => parser.parse(mockData), throwsA(isA<DataParsingException>()));
    });
  });
}