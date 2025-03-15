import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import '../models/cube_state.dart';
import '../models/move.dart';
import 'gan_cube_decoder.dart';

/// ハードウェア情報の種類
enum HardwareInfoType {
  productDate,
  hardwareName,
  softwareVersion,
  hardwareVersion,
}

/// ハードウェア情報
class HardwareInfo {
  final HardwareInfoType infoType;
  final int? year;
  final int? month;
  final int? day;
  final String? name;
  final int? major;
  final int? minor;

  HardwareInfo({
    required this.infoType,
    this.year,
    this.month,
    this.day,
    this.name,
    this.major,
    this.minor,
  });

  @override
  String toString() {
    switch (infoType) {
      case HardwareInfoType.productDate:
        return '製造日: $year-$month-$day';
      case HardwareInfoType.hardwareName:
        return 'ハードウェア名: $name';
      case HardwareInfoType.softwareVersion:
        return 'ソフトウェアバージョン: $major.$minor';
      case HardwareInfoType.hardwareVersion:
        return 'ハードウェアバージョン: $major.$minor';
    }
  }
}

/// GANキューブのプロトコル処理
class GanCubeProtocol {
  // パケット定数
  static const int PACKET_PREFIX = 0xDD;
  static const int PACKET_LENGTH = 20;

  // コマンド定数
  static const int CMD_HARDWARE_INFO = 0xDF;  // ハードウェア情報取得
  static const int CMD_GET_DATA = 0x04;       // 状態取得
  static const int CMD_MOVE_HISTORY = 0xD1;   // 移動履歴取得

  // レスポンスモード
  static const int RESP_MOVE = 0x01;
  static const int RESP_FACELETS = 0xED;
  static const int RESP_BATTERY = 0xEF;
  static const int RESP_GYRO = 0xEC;
  static const int RESP_HISTORY = 0xD1;

  // ハードウェア情報モード
  static const List<int> HARDWARE_INFO_MODES = [
    0xF5, 0xF6, 0xFA, 0xFC, 0xFD, 0xFE, 0xFF
  ];

  GanCubeDecoder? _decoder;
  int _prevMoveCnt = -1;
  DateTime? _prevMoveTime;
  int _movesFromLastCheck = 1000;
  final List<_MoveBufferEntry> _moveBuffer = [];
  CubeState? _latestState;

  // コールバック関数
  void Function(int)? onBatteryUpdate;
  void Function(CubeState)? onStateUpdate;
  void Function(Move, int?)? onMoveDetected;
  void Function(HardwareInfo)? onHardwareInfo;

  /// デコーダを初期化
  void initializeDecoder(String macAddress) {
    _decoder = GanCubeDecoder.fromMacAddress(macAddress);
  }

  /// キューブの初期化シーケンスを実行
  Future<void> initialize() async {
    debugPrint('キューブの初期化を開始');
    await Future.delayed(const Duration(milliseconds: 100));
    
    // バッテリー情報を要求
    final batteryCommand = createBatteryCommand();
    debugPrint('バッテリー要求: ${batteryCommand.map((e) => '0x${e.toRadixString(16)}').join(', ')}');

    // ハードウェア情報を要求
    final hardwareCommand = createHardwareCommand();
    debugPrint('ハードウェア要求: ${hardwareCommand.map((e) => '0x${e.toRadixString(16)}').join(', ')}');

    // キューブの状態を要求
    final faceletsCommand = createFaceletsCommand();
    debugPrint('状態要求: ${faceletsCommand.map((e) => '0x${e.toRadixString(16)}').join(', ')}');
  }

  /// バッテリー取得コマンドを生成
  List<int> createBatteryCommand() {
    final command = List<int>.filled(PACKET_LENGTH, 0);
    command[0] = PACKET_PREFIX;
    command[1] = CMD_GET_DATA;
    command[3] = RESP_BATTERY;
    return _decoder?.encode(command) ?? command;
  }

  /// キューブ状態取得コマンドを生成
  List<int> createFaceletsCommand() {
    final command = List<int>.filled(PACKET_LENGTH, 0);
    command[0] = PACKET_PREFIX;
    command[1] = CMD_GET_DATA;
    command[3] = RESP_FACELETS;
    return _decoder?.encode(command) ?? command;
  }

  /// ハードウェア情報取得コマンドを生成
  List<int> createHardwareCommand() {
    final command = List<int>.filled(PACKET_LENGTH, 0);
    command[0] = CMD_HARDWARE_INFO;
    command[1] = 0x03;
    return _decoder?.encode(command) ?? command;
  }

  /// 移動履歴取得コマンドを生成
  List<int> createMoveHistoryCommand(int startMove, int count) {
    // 奇数から開始するように調整
    if (startMove % 2 == 0) {
      startMove = (startMove - 1) & 0xFF;
    }
    // 偶数個になるように調整
    if (count % 2 == 1) count++;
    // 255->0のサイクルを超えないように制限
    count = count.clamp(0, startMove + 1);

    final command = List<int>.filled(PACKET_LENGTH, 0);
    command[0] = CMD_MOVE_HISTORY;
    command[1] = CMD_GET_DATA;
    command[2] = startMove;
    command[4] = count;
    return _decoder?.encode(command) ?? command;
  }

  /// データパケットを解析（CubeConnectionServiceから呼び出される）
  void processDataPacket(List<int> data) {
    parseV4Data(data);
  }

  /// データパケットを解析（gancube.jsのparseV4Data関数に対応）
  void parseV4Data(List<int> data) {
    // debugPrint('=== データ受信開始 ===');
    // debugPrint('生データ (${data.length} bytes): ${data.map((e) => '0x${e.toRadixString(16).padLeft(2, '0')}').join(', ')}');
    
    final decodedData = _decoder?.decode(data) ?? data;
    // debugPrint('デコード後 (${decodedData.length} bytes): ${decodedData.map((e) => '0x${e.toRadixString(16).padLeft(2, '0')}').join(', ')}');

    final now = DateTime.now();

    try {
      // バイナリ文字列に変換（JavaScript実装と同じ方法）
      final binStr = decodedData.map((byte) {
        final bin = (byte + 256).toRadixString(2);
        return bin.substring(1).padLeft(8, '0');  // 8ビットに正規化
      }).join('');
      
      // debugPrint('バイナリ文字列 (${binStr.length} bits): $binStr');
      
      final mode = _getBitsFromString(binStr, 0, 8);
      final length = _getBitsFromString(binStr, 8, 8);
      // debugPrint('モード: 0x${mode.toRadixString(16).padLeft(2, '0')}, 長さ: $length');

      switch (mode) {
        case RESP_MOVE:
          _prevMoveTime = now;
          final moveCnt = _getBitsFromString(binStr, 48, 16);
          
          debugPrint('移動イベント受信: prev=$_prevMoveCnt current=$moveCnt');
          
          if (moveCnt == _prevMoveCnt || _prevMoveCnt == -1) {
            return;
          }

          final timestamp = _getBitsFromString(binStr, 16, 40);
          final power = _getBitsFromString(binStr, 64, 2);
          final axisValue = _getBitsFromString(binStr, 66, 6);
          debugPrint('移動イベント: count=$moveCnt, timestamp=$timestamp, power=$power, axisValue=0x${axisValue.toRadixString(16)}');
          
          final axis = [2, 32, 8, 1, 16, 4].indexOf(axisValue);
          if (axis == -1) {
            debugPrint('無効な軸データ: 0x${axisValue.toRadixString(16)}');
            return;
          }

          final move = _createMove(axis, power);
          _moveBuffer.add(_MoveBufferEntry(
            moveCnt: moveCnt,
            move: move,
            timestamp: timestamp,
          ));

          debugPrint('移動をバッファに追加: $moveCnt $move $timestamp');
          _evictMoveBuffer(true);
          break;

        case RESP_FACELETS:
          final moveCnt = _getBitsFromString(binStr, 16, 16);
          debugPrint('キューブ状態イベント: moveCnt=$moveCnt');
          
          if (_prevMoveCnt != -1) {
            if (_prevMoveTime != null && now.difference(_prevMoveTime!).inMilliseconds > 500) {
              final diff = (moveCnt - _prevMoveCnt) & 0xFF;
              if (diff > 0) {
                debugPrint('キューブの状態が最後の記録された移動より先にあります: $_prevMoveCnt -> $moveCnt');
                if (moveCnt != 0) {
                  final startMoveCnt = _moveBuffer.isNotEmpty ? 
                    _moveBuffer[0].moveCnt : (moveCnt + 1) & 0xFF;
                  _requestMissingMoves(startMoveCnt, diff + 1);
                }
              }
            }
            return;
          }

          debugPrint('キューブ状態イベントを処理: $_prevMoveCnt $moveCnt');
          _processFaceletData(binStr);
          break;

        case RESP_BATTERY:
          _processBatteryData(binStr, length);
          break;

        case RESP_HISTORY:
          final startMove = _getBitsFromString(binStr, 16, 8);
          final moveCount = (length - 1) * 2;
          debugPrint('移動履歴イベント: startMove=$startMove, count=$moveCount');
          _processMoveHistory(binStr, startMove, moveCount);
          break;
        
        case RESP_GYRO:
        // ジャイロデータは一旦無視(常に来るので)
          break;

        default:
          if (HARDWARE_INFO_MODES.contains(mode)) {
            debugPrint('ハードウェア情報: 0x${mode.toRadixString(16)}');
            _processHardwareInfo(binStr, mode, length);
          } else {
            debugPrint('未知のイベント: モード=0x${mode.toRadixString(16)}, データ長=$length');
            debugPrint('データ全体: ${binStr.substring(0, math.min(32, binStr.length))}...');
          }
      }
    } catch (e, stackTrace) {
      debugPrint('データ解析エラー: $e');
      debugPrint('スタックトレース: $stackTrace');
    }
    // debugPrint('=== データ受信終了 ===\n');
  }

  /// バイナリ文字列から指定範囲のビットを取得
  int _getBitsFromString(String binStr, int start, int length) {
    if (start + length > binStr.length) {
      throw RangeError('指定された範囲がバイナリ文字列の長さを超えています');
    }
    final bits = binStr.substring(start, start + length);
    return int.parse(bits, radix: 2);
  }

  /// バッテリー情報を処理
  void _processBatteryData(String binStr, int length) {
    try {
      final batteryLevel = _getBitsFromString(binStr, 8 + length * 8, 8);
      debugPrint('バッテリー残量: $batteryLevel%');
      onBatteryUpdate?.call(batteryLevel);
    } catch (e) {
      debugPrint('バッテリーデータ処理エラー: $e');
    }
  }

  /// キューブの状態データを処理
  void _processFaceletData(String binStr) {
    try {
      final cornerData = List<int>.filled(8, 0);
      final edgeData = List<int>.filled(12, 0);

      // コーナー情報の解析（パリティチェック付き）
      var cchk = 0xf00;
      for (var i = 0; i < 7; i++) {
        final perm = _getBitsFromString(binStr, 32 + i * 3, 3);
        final ori = _getBitsFromString(binStr, 53 + i * 2, 2);
        cchk -= ori << 3;
        cchk ^= perm;
        cornerData[i] = (ori << 3) | perm;
      }
      cornerData[7] = (cchk & 0xff8) % 24 | (cchk & 0x7);

      // エッジ情報の解析（パリティチェック付き）
      var echk = 0;
      for (var i = 0; i < 11; i++) {
        final perm = _getBitsFromString(binStr, 69 + i * 4, 4);
        final ori = _getBitsFromString(binStr, 113 + i, 1);
        echk ^= (perm << 1) | ori;
        edgeData[i] = (perm << 1) | ori;
      }
      edgeData[11] = echk;

      final state = CubeState.fromCornerAndEdge(cornerData, edgeData);
      _latestState = state;
      onStateUpdate?.call(state);

    } catch (e) {
      debugPrint('キューブ状態データ処理エラー: $e');
    }
  }

  /// ハードウェア情報を処理
  void _processHardwareInfo(String binStr, int mode, int length) {
    try {
      switch (mode) {
        case 0xFA:  // 製造日
          final year = _getBitsFromString(binStr, 24, 16);
          final month = _getBitsFromString(binStr, 40, 8);
          final day = _getBitsFromString(binStr, 48, 8);
          debugPrint('製造日: $year-$month-$day');
          onHardwareInfo?.call(HardwareInfo(
            infoType: HardwareInfoType.productDate,
            year: year,
            month: month,
            day: day,
          ));
          break;

        case 0xFC:  // ハードウェア名
          var hwName = '';
          for (var i = 0; i < length - 1; i++) {
            final charCode = _getBitsFromString(binStr, 24 + i * 8, 8);
            hwName += String.fromCharCode(charCode);
          }
          debugPrint('ハードウェア名: $hwName');
          onHardwareInfo?.call(HardwareInfo(
            infoType: HardwareInfoType.hardwareName,
            name: hwName,
          ));
          break;

        case 0xFD:  // ソフトウェアバージョン
          final swMajor = _getBitsFromString(binStr, 24, 4);
          final swMinor = _getBitsFromString(binStr, 28, 4);
          debugPrint('ソフトウェアバージョン: $swMajor.$swMinor');
          onHardwareInfo?.call(HardwareInfo(
            infoType: HardwareInfoType.softwareVersion,
            major: swMajor,
            minor: swMinor,
          ));
          break;

        case 0xFE:  // ハードウェアバージョン
          final hwMajor = _getBitsFromString(binStr, 24, 4);
          final hwMinor = _getBitsFromString(binStr, 28, 4);
          debugPrint('ハードウェアバージョン: $hwMajor.$hwMinor');
          onHardwareInfo?.call(HardwareInfo(
            infoType: HardwareInfoType.hardwareVersion,
            major: hwMajor,
            minor: hwMinor,
          ));
          break;
      }
    } catch (e) {
      debugPrint('ハードウェア情報処理エラー: $e');
    }
  }

  /// 移動履歴を処理
  void _processMoveHistory(String binStr, int startMove, int moveCount) {
    try {
      for (var i = 0; i < moveCount; i++) {
        final axis = _getBitsFromString(binStr, 24 + i * 4, 3);
        final power = _getBitsFromString(binStr, 27 + i * 4, 1);
        
        if (axis < 6) {
          final moveCnt = (startMove - i) & 0xFF;
          final move = _createMove(axis, power);
          _addMoveToBuffer(moveCnt, move, null);
        }
      }
      _evictMoveBuffer(false);
    } catch (e) {
      debugPrint('移動履歴処理エラー: $e');
    }
  }

  /// 移動バッファの処理
  void _evictMoveBuffer(bool requestLostMoves) {
    while (_moveBuffer.isNotEmpty) {
      final diff = (_moveBuffer[0].moveCnt - _prevMoveCnt) & 0xFF;
      if (diff > 1) {
        debugPrint('移動の欠落を検出: $_prevMoveCnt -> ${_moveBuffer[0].moveCnt}');
        if (requestLostMoves) {
          _requestMissingMoves(_moveBuffer[0].moveCnt, diff);
        }
        break;
      } else {
        final entry = _moveBuffer.removeAt(0);
        onMoveDetected?.call(entry.move, entry.timestamp);
        _prevMoveCnt = entry.moveCnt;
      }
    }

    if (_moveBuffer.length > 16) {
      debugPrint('バッファが大きすぎます。強制切断します');
      // TODO: 切断処理の実装
    }
  }

  /// 移動オブジェクトを生成
  Move _createMove(int axis, int power) {
    final face = "URFDLB"[axis];
    final modifier = power == 0 ? '' : (power == 1 ? "'" : '2');
    return Move(
      type: MoveType.values[axis * 3 + power],
      timestamp: DateTime.now(),
    );
  }

  /// 欠落した移動の要求
  void _requestMissingMoves(int startMove, int count) {
    // 上位レイヤーで実装
  }

  /// 移動情報をバッファに追加
  void _addMoveToBuffer(int moveCnt, Move move, int? timestamp) {
    _moveBuffer.add(_MoveBufferEntry(
      moveCnt: moveCnt,
      move: move,
      timestamp: timestamp,
    ));
  }
}

/// 移動バッファのエントリ
class _MoveBufferEntry {
  final int moveCnt;
  final Move move;
  final int? timestamp;

  _MoveBufferEntry({
    required this.moveCnt,
    required this.move,
    this.timestamp,
  });
}