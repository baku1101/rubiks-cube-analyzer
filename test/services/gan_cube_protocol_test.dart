import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:rubiks_cube_analyzer/models/cube_state.dart';
import 'package:rubiks_cube_analyzer/models/move.dart';
import 'package:rubiks_cube_analyzer/services/gan_cube_decoder.dart';
import 'package:rubiks_cube_analyzer/services/gan_cube_protocol.dart';

import 'gan_cube_protocol_test.mocks.dart';

@GenerateMocks([GanCubeDecoder])
void main() {
  late GanCubeProtocol protocol;
  late MockGanCubeDecoder mockDecoder;

  setUp(() {
    mockDecoder = MockGanCubeDecoder();
    protocol = GanCubeProtocol();
  });

  group('コマンド生成', () {
    test('バッテリー取得コマンドが正しい形式で生成される', () {
      final command = protocol.createBatteryCommand();

      expect(command[0], equals(0xDD));  // prefix
      expect(command[1], equals(0x04));  // command type
      expect(command[3], equals(0xEF));  // battery response mode
      expect(command.length, equals(20));
    });

    test('キューブ状態取得コマンドが正しい形式で生成される', () {
      final command = protocol.createFaceletsCommand();

      expect(command[0], equals(0xDD));  // prefix
      expect(command[1], equals(0x04));  // command type
      expect(command[3], equals(0xED));  // facelets response mode
      expect(command.length, equals(20));
    });

    test('ハードウェア情報取得コマンドが正しい形式で生成される', () {
      final command = protocol.createHardwareCommand();

      expect(command[0], equals(0xDF));  // hardware info command
      expect(command[1], equals(0x03));  // sub command
      expect(command.length, equals(20));
    });
  });

  group('データ解析', () {
    test('バッテリーレベルが正しく解析される', () {
      // Arrange
      const expectedLevel = 85;
      int? receivedLevel;
      protocol.onBatteryUpdate = (level) => receivedLevel = level;

      final data = List<int>.filled(20, 0);
      data[0] = 0xEF;  // battery response mode
      data[1] = 0x01;  // length
      data[7] = expectedLevel;  // battery level

      when(mockDecoder.decode(any)).thenReturn(data);

      // Act
      protocol.processDataPacket(data);

      // Assert
      expect(receivedLevel, equals(expectedLevel));
    });

    test('移動イベントが正しく解析される', () {
      // Arrange
      Move? receivedMove;
      int? receivedTimestamp;
      protocol.onMoveDetected = (move, timestamp) {
        receivedMove = move;
        receivedTimestamp = timestamp;
      };

      final data = List<int>.filled(20, 0);
      data[0] = 0x01;  // move event
      data[1] = 0x01;  // length
      data[7] = 0x02;  // U move
      data[8] = 0x00;  // normal direction
      data[4] = 0x12;  // timestamp (part 1)
      data[5] = 0x34;  // timestamp (part 2)

      when(mockDecoder.decode(any)).thenReturn(data);

      // Act
      protocol.processDataPacket(data);

      // Assert
      expect(receivedMove, isNotNull);
      expect(receivedMove?.type, equals(MoveType.U));
      expect(receivedTimestamp, isNotNull);
    });
  });

  group('ハードウェア情報', () {
    test('製造日が正しく解析される', () {
      // Arrange
      HardwareInfo? receivedInfo;
      protocol.onHardwareInfo = (info) => receivedInfo = info;

      final data = List<int>.filled(20, 0);
      data[0] = 0xFA;  // product date mode
      data[1] = 0x01;  // length
      data[3] = 2023;  // year
      data[4] = 12;    // month
      data[5] = 25;    // day

      when(mockDecoder.decode(any)).thenReturn(data);

      // Act
      protocol.processDataPacket(data);

      // Assert
      expect(receivedInfo?.infoType, equals(HardwareInfoType.productDate));
      expect(receivedInfo?.year, equals(2023));
      expect(receivedInfo?.month, equals(12));
      expect(receivedInfo?.day, equals(25));
    });

    test('ソフトウェアバージョンが正しく解析される', () {
      // Arrange
      HardwareInfo? receivedInfo;
      protocol.onHardwareInfo = (info) => receivedInfo = info;

      final data = List<int>.filled(20, 0);
      data[0] = 0xFD;  // software version mode
      data[1] = 0x01;  // length
      data[3] = 0x12;  // major = 1, minor = 2

      when(mockDecoder.decode(any)).thenReturn(data);

      // Act
      protocol.processDataPacket(data);

      // Assert
      expect(receivedInfo?.infoType, equals(HardwareInfoType.softwareVersion));
      expect(receivedInfo?.major, equals(1));
      expect(receivedInfo?.minor, equals(2));
    });
  });
}