import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:rubiks_cube_analyzer/services/gan/protocol/command.dart';

void main() {
  // 期待されるコマンド長
  const int expectedCommandLength = 20;

  group('CommandBuilder', () {
    test('createStateRequest should generate correct command', () {
      final command = CommandBuilder.createStateRequest();
      final expected = Uint8List(expectedCommandLength);
      expected[0] = 0xDD;
      expected[1] = 0x04;
      expected[3] = 0xED;

      expect(command, equals(expected));
      expect(command.length, equals(expectedCommandLength));
    });

    test('createBatteryRequest should generate correct command', () {
      final command = CommandBuilder.createBatteryRequest();
      final expected = Uint8List(expectedCommandLength);
      expected[0] = 0xDD;
      expected[1] = 0x04;
      expected[3] = 0xEF;

      expect(command, equals(expected));
      expect(command.length, equals(expectedCommandLength));
    });

    test('createHardwareInfoRequest should generate correct command', () {
      final command = CommandBuilder.createHardwareInfoRequest();
      final expected = Uint8List(expectedCommandLength);
      expected[0] = 0xDF;
      expected[1] = 0x03;

      expect(command, equals(expected));
      expect(command.length, equals(expectedCommandLength));
    });

    group('createMoveHistoryRequest', () {
      test('should generate correct command for valid inputs', () {
        final startCounter = 5; // 例
        final count = 10; // 例
        final command = CommandBuilder.createMoveHistoryRequest(startCounter, count);
        final expected = Uint8List(expectedCommandLength);
        expected[0] = 0xD1;
        expected[1] = 0x04;
        // 仕様書通りのバイト割り当て (要検証)
        expected[2] = startCounter & 0xFF;
        expected[3] = (startCounter >> 8) & 0xFF; // V4では未使用のはず
        expected[4] = count & 0xFF;
        expected[5] = (count >> 8) & 0xFF; // V4では未使用のはず

        // 代替のバイト割り当て (cstimer参考)
        // expected[2] = startCounter;
        // expected[3] = count;

        expect(command, equals(expected));
        expect(command.length, equals(expectedCommandLength));
      });

       test('should throw ArgumentError for invalid startCounter', () {
        expect(() => CommandBuilder.createMoveHistoryRequest(-1, 10), throwsArgumentError);
        expect(() => CommandBuilder.createMoveHistoryRequest(256, 10), throwsArgumentError);
        // 仕様書では奇数/偶数の調整は呼び出し側だが、メソッド内でチェックしても良い
        // expect(() => CommandBuilder.createMoveHistoryRequest(4, 10), throwsArgumentError);
      });

      test('should throw ArgumentError for invalid count', () {
        expect(() => CommandBuilder.createMoveHistoryRequest(5, -1), throwsArgumentError);
        expect(() => CommandBuilder.createMoveHistoryRequest(5, 256), throwsArgumentError);
         // 仕様書では奇数/偶数の調整は呼び出し側だが、メソッド内でチェックしても良い
        // expect(() => CommandBuilder.createMoveHistoryRequest(5, 9), throwsArgumentError);
      });
    });
  });
}