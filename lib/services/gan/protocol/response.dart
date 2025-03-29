import 'dart:typed_data';
import 'package:collection/collection.dart'; // deepEqualsのために追加

/// GANキューブからのレスポンスデータの基底クラス。
abstract class ResponseData {
  final int mode;
  final int length;
  final Uint8List rawData; // 解析前の生データ（デバッグ用）

  ResponseData(this.mode, this.length, this.rawData);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResponseData &&
          runtimeType == other.runtimeType &&
          mode == other.mode &&
          length == other.length &&
          const DeepCollectionEquality().equals(rawData, other.rawData); // 生データも比較

  @override
  int get hashCode =>
      mode.hashCode ^
      length.hashCode ^
      const DeepCollectionEquality().hash(rawData); // 生データもハッシュに含める

  @override
  String toString() {
    return '$runtimeType{mode: 0x${mode.toRadixString(16)}, length: $length}';
  }
}

/// キューブ移動イベント (モード 0x01)
class MoveEvent extends ResponseData {
  final int timestamp; // ミリ秒単位のタイムスタンプ
  final int moveCounter; // 0-65535? (仕様書では2バイト)
  final int direction; // 0: 時計回り, 1: 反時計回り
  final int axis; // 2:U, 32:R, 8:F, 1:D, 16:L, 4:B (仕様書の値) -> 軸インデックスに変換推奨

  MoveEvent({
    required int mode,
    required int length,
    required Uint8List rawData,
    required this.timestamp,
    required this.moveCounter,
    required this.direction,
    required this.axis,
  }) : super(mode, length, rawData);

  /// 仕様書の軸表現から一般的な軸インデックス (0:U, 1:R, 2:F, 3:D, 4:L, 5:B) に変換します。
  int get axisIndex {
    switch (axis) {
      case 2: return 0; // U
      case 32: return 1; // R
      case 8: return 2; // F
      case 1: return 3; // D
      case 16: return 4; // L
      case 4: return 5; // B
      default: return -1; // 不明な軸
    }
  }

  String get moveString {
    const axes = ['U', 'R', 'F', 'D', 'L', 'B'];
    const directions = ['', "'"]; // 0: 時計回り, 1: 反時計回り

    if (axisIndex == -1) {
      return 'Invalid Move';
    }

    return axes[axisIndex] + directions[direction];
  }

  @override
  String toString() {
    return 'Move: $moveString';  // シンプルな形式で面の回転のみを表示
  }
}

/// キューブ状態 (モード 0xED)
class CubeStateData extends ResponseData {
  final int moveCounter; // 0-65535? (仕様書では2バイト)
  final List<int> cornerPositions; // 7個のコーナーの位置 (0-7)
  final List<int> cornerOrientations; // 7個のコーナーの向き (0-2)
  final List<int> edgePositions; // 11個のエッジの位置 (0-11)
  final List<int> edgeOrientations; // 11個のエッジの向き (0-1)
  // 8番目のコーナーと12番目のエッジはパリティから計算可能

  CubeStateData({
    required int mode,
    required int length,
    required Uint8List rawData,
    required this.moveCounter,
    required this.cornerPositions,
    required this.cornerOrientations,
    required this.edgePositions,
    required this.edgeOrientations,
  }) : super(mode, length, rawData);

   @override
  String toString() {
    return 'CubeStateData{mode: 0x${mode.toRadixString(16)}, length: $length, moveCounter: $moveCounter, corners: $cornerPositions/$cornerOrientations, edges: $edgePositions/$edgeOrientations}';
  }
}

/// 移動履歴 (モード 0xD1)
class MoveHistory extends ResponseData {
  final int startMoveCounter;
  final List<CubeMove> moves; // 解析された移動のリスト

  MoveHistory({
    required int mode,
    required int length,
    required Uint8List rawData,
    required this.startMoveCounter,
    required this.moves,
  }) : super(mode, length, rawData);

   @override
  String toString() {
    return 'MoveHistory{mode: 0x${mode.toRadixString(16)}, length: $length, startCounter: $startMoveCounter, moves: ${moves.length}}';
  }
}

/// 移動履歴内の単一の移動を表すクラス
class CubeMove {
  final int axis; // 0:D, 1:U, 2:B, 3:F, 4:L, 5:R (仕様書の値) -> 軸インデックスに変換推奨
  final int direction; // 0: 時計回り, 1: 反時計回り

  CubeMove({required this.axis, required this.direction});

  /// 仕様書の軸表現から一般的な軸インデックス (0:U, 1:R, 2:F, 3:D, 4:L, 5:B) に変換します。
  int get axisIndex {
    switch (axis) {
      case 1: return 0; // U
      case 5: return 1; // R
      case 3: return 2; // F
      case 0: return 3; // D
      case 4: return 4; // L
      case 2: return 5; // B
      default: return -1; // 不明な軸
    }
  }

   @override
  String toString() {
    return 'CubeMove{axis: $axis ($axisIndex), dir: $direction}';
  }
}


/// バッテリー情報 (モード 0xEF)
class BatteryInfo extends ResponseData {
  final int level; // バッテリーレベル (0-100)

  BatteryInfo({
    required int mode,
    required int length,
    required Uint8List rawData,
    required this.level,
  }) : super(mode, length, rawData);

   @override
  String toString() {
    return 'BatteryInfo{mode: 0x${mode.toRadixString(16)}, length: $length, level: $level%}';
  }
}

/// 製造日情報 (モード 0xFA)
class ManufacturingDateInfo extends ResponseData {
  final int year;
  final int month;
  final int day;

  ManufacturingDateInfo({
    required int mode,
    required int length,
    required Uint8List rawData,
    required this.year,
    required this.month,
    required this.day,
  }) : super(mode, length, rawData);

   @override
  String toString() {
    return 'ManufacturingDateInfo{mode: 0x${mode.toRadixString(16)}, length: $length, date: $year-$month-$day}';
  }
}

/// ハードウェア名 (モード 0xFC)
class HardwareNameInfo extends ResponseData {
  final String name;

  HardwareNameInfo({
    required int mode,
    required int length,
    required Uint8List rawData,
    required this.name,
  }) : super(mode, length, rawData);

   @override
  String toString() {
    return 'HardwareNameInfo{mode: 0x${mode.toRadixString(16)}, length: $length, name: $name}';
  }
}

/// ソフトウェアバージョン (モード 0xFD)
class SoftwareVersionInfo extends ResponseData {
  final int major;
  final int minor;

  SoftwareVersionInfo({
    required int mode,
    required int length,
    required Uint8List rawData,
    required this.major,
    required this.minor,
  }) : super(mode, length, rawData);

   @override
  String toString() {
    return 'SoftwareVersionInfo{mode: 0x${mode.toRadixString(16)}, length: $length, version: $major.$minor}';
  }
}

/// ハードウェアバージョン (モード 0xFE)
class HardwareVersionInfo extends ResponseData {
  final int major;
  final int minor;

  HardwareVersionInfo({
    required int mode,
    required int length,
    required Uint8List rawData,
    required this.major,
    required this.minor,
  }) : super(mode, length, rawData);

   @override
  String toString() {
    return 'HardwareVersionInfo{mode: 0x${mode.toRadixString(16)}, length: $length, version: $major.$minor}';
  }
}

/// その他のハードウェア情報 (モード 0xFF, 0xF5, 0xF6)
/// 詳細不明なため、生データのみ保持
class OtherHardwareInfo extends ResponseData {
  OtherHardwareInfo({
    required int mode,
    required int length,
    required Uint8List rawData,
  }) : super(mode, length, rawData);
}

/// ジャイロ情報 (モード 0xEC)
/// 詳細不明なため、生データのみ保持
class GyroInfo extends ResponseData {
  GyroInfo({
    required int mode,
    required int length,
    required Uint8List rawData,
  }) : super(mode, length, rawData);
}


/// 不明なレスポンスモードを表す例外。
class UnknownResponseModeException implements Exception {
  final int mode;
  UnknownResponseModeException(this.mode);

  @override
  String toString() => 'Unknown response mode: 0x${mode.toRadixString(16)}';
}

/// データ解析エラーを表す例外。
class DataParsingException implements Exception {
  final String message;
  DataParsingException(this.message);

  @override
  String toString() => 'Data parsing error: $message';
}


/// GANキューブからのレスポンスデータを解析します。
class ResponseParser {
  /// バイト配列データを対応するResponseDataオブジェクトに解析します。
  ///
  /// データは復号化されている必要があります。
  ResponseData parse(Uint8List data) {
    if (data.isEmpty) {
      throw DataParsingException('Received empty data.');
    }

    final mode = data[0];
    // 長さチェックを追加
    if (data.length < 2) {
       throw DataParsingException('Data too short for mode 0x${mode.toRadixString(16)}. Length: ${data.length}');
    }
    final length = data[1]; // 仕様書によるとバイト1が長さ

    // データ全体の長さがヘッダーで示される長さと一致するか確認
    // 注意: 仕様書の「長さ」がペイロードのみを指すのか、ヘッダーを含むのか要確認。
    //       ここではペイロードの長さ（ヘッダーバイトを除く）と仮定してチェックする。
    //       例: モード0x01の場合、length=9ならデータ全体は10バイトのはず。
    // if (data.length != length + 1) { // ペイロード長の場合
    // if (data.length != length) { // 全体長の場合
    //   throw DataParsingException('Data length mismatch for mode 0x${mode.toRadixString(16)}. Expected: $length, Actual: ${data.length}');
    // }
    // → length の解釈が不明確なため、一旦長さチェックは緩めにしておく

    try {
      switch (mode) {
        case 0x01:
          return _parseMoveEvent(data, length);
        case 0xED:
          return _parseCubeState(data, length);
        case 0xD1:
          return _parseMoveHistory(data, length);
        case 0xEF:
          return _parseBatteryInfo(data, length);
        case 0xFA:
          return _parseManufacturingDateInfo(data, length);
        case 0xFC:
          return _parseHardwareNameInfo(data, length);
        case 0xFD:
          return _parseSoftwareVersionInfo(data, length);
        case 0xFE:
          return _parseHardwareVersionInfo(data, length);
        case 0xFF:
        case 0xF5:
        case 0xF6:
          return OtherHardwareInfo(mode: mode, length: length, rawData: data);
        case 0xEC:
          return GyroInfo(mode: mode, length: length, rawData: data);
        default:
          throw UnknownResponseModeException(mode);
      }
    } on UnknownResponseModeException { // UnknownResponseModeException はそのまま再スロー
      rethrow;
    } catch (e) {
      // 解析中のエラーをキャッチして詳細情報と共に再スロー
      throw DataParsingException('Failed to parse mode 0x${mode.toRadixString(16)}: $e');
    }
  }

  /// ビット単位でデータを抽出するヘルパー関数。
  ///
  /// [data] バイト配列データ。
  /// [startBit] 抽出開始ビット位置 (0から)。
  /// [length] 抽出するビット長。
  int _extractBits(Uint8List data, int startBit, int length) {
    int value = 0;
    for (int i = 0; i < length; i++) {
      int currentBitPos = startBit + i;
      int byteIndex = currentBitPos ~/ 8;
      int bitInByte = 7 - (currentBitPos % 8); // MSB first

      if (byteIndex >= data.length) {
         throw DataParsingException('Attempted to read beyond data bounds. Byte index: $byteIndex, Data length: ${data.length}');
      }

      if ((data[byteIndex] >> bitInByte) & 1 == 1) {
        value |= (1 << (length - 1 - i)); // MSB firstで値を構築
      }
    }
    return value;
  }

  /// 移動イベント (0x01) を解析します。
  MoveEvent _parseMoveEvent(Uint8List data, int length) {
     // 期待される最小長をチェック
    if (data.length < 10) { // mode(1) + len(1) + timestamp(4) + counter(2) + dir/axis(1) = 9バイト -> 仕様書では72bit = 9バイトだが、cstimerは10バイト？
       throw DataParsingException('Insufficient data length for MoveEvent. Expected at least 10 bytes, got ${data.length}');
    }
    return MoveEvent(
      mode: 0x01,
      length: length,
      rawData: data,
      timestamp: _extractBits(data, 16, 32), // 仕様書では4バイト=32ビット
      moveCounter: _extractBits(data, 48, 16), // 仕様書では2バイト=16ビット
      direction: _extractBits(data, 64, 2), // 仕様書では2ビット
      axis: _extractBits(data, 66, 6), // 仕様書では6ビット
    );
  }

  /// キューブ状態 (0xED) を解析します。
  CubeStateData _parseCubeState(Uint8List data, int length) {
     // 期待される最小長をチェック (124ビット = 15.5バイト -> 16バイト？)
    if (data.length < 16) {
       throw DataParsingException('Insufficient data length for CubeStateData. Expected at least 16 bytes, got ${data.length}');
    }
    List<int> cornerPos = [];
    List<int> cornerOri = [];
    List<int> edgePos = [];
    List<int> edgeOri = [];

    // コーナー位置 (7個 * 3ビット = 21ビット)
    for (int i = 0; i < 7; i++) {
      cornerPos.add(_extractBits(data, 32 + i * 3, 3));
    }
    // コーナー向き (7個 * 2ビット = 14ビット)
    for (int i = 0; i < 7; i++) {
      cornerOri.add(_extractBits(data, 53 + i * 2, 2));
    }
    // エッジ位置 (11個 * 4ビット = 44ビット) - 仕様書ではビット69から
    for (int i = 0; i < 11; i++) {
      edgePos.add(_extractBits(data, 69 + i * 4, 4));
    }
    // エッジ向き (11個 * 1ビット = 11ビット) - 仕様書ではビット113から
    for (int i = 0; i < 11; i++) {
      edgeOri.add(_extractBits(data, 113 + i * 1, 1));
    }

    return CubeStateData(
      mode: 0xED,
      length: length,
      rawData: data,
      moveCounter: _extractBits(data, 16, 16), // 仕様書では2バイト=16ビット
      cornerPositions: cornerPos,
      cornerOrientations: cornerOri,
      edgePositions: edgePos,
      edgeOrientations: edgeOri,
    );
  }

  /// 移動履歴 (0xD1) を解析します。
  MoveHistory _parseMoveHistory(Uint8List data, int length) {
     // 期待される最小長をチェック (mode(1) + len(1) + startCounter(1) = 3バイト)
    if (data.length < 3) {
 // ヘッダ(2) + startCounter(1) の最小長
       throw DataParsingException('Insufficient data length for MoveHistory. Expected at least 3 bytes, got ${data.length}');
    }
    final startCounter = _extractBits(data, 16, 8); // 仕様書では1バイト
    final List<CubeMove> moves = [];
    // 移動データはバイト3から開始 (ビット24から)
    // 各移動は4ビット
    // 移動データのバイト数は data.length - 3
    // 1バイトに2移動入るので、移動数は (data.length - 3) * 2
    int moveDataBytes = data.length - 3;
    int numMoves = moveDataBytes * 2;

    for (int i = 0; i < numMoves; i++) {
      int moveData = _extractBits(data, 24 + i * 4, 4);
      moves.add(CubeMove(
        axis: moveData & 0x07, // 下位3ビットが軸
        direction: (moveData >> 3) & 0x01, // 最上位ビットが方向
      ));
    }

    return MoveHistory(
      mode: 0xD1,
      length: length,
      rawData: data,
      startMoveCounter: startCounter,
      moves: moves,
    );
  }

  /// バッテリー情報 (0xEF) を解析します。
  BatteryInfo _parseBatteryInfo(Uint8List data, int length) {
     // 期待される最小長をチェック (mode(1) + len(1) + level(1) = 3バイト)
    if (data.length < 3) {
       throw DataParsingException('Insufficient data length for BatteryInfo. Expected at least 3 bytes, got ${data.length}');
    }
    // 仕様書ではレベルは最後のバイトにある
    int levelByteIndex = 1 + length; // mode(1) + length(1) + payload(length) -> 最後のバイトは index length+1
    if (data.length <= levelByteIndex) {
         // length がペイロード長を示すと仮定し、レベルは data[1+length] = data[2] (length=1の場合) にあるとする
         levelByteIndex = 1 + length;
         if (data.length <= levelByteIndex) {
            throw DataParsingException('Insufficient data length for BatteryInfo level. Expected at least ${levelByteIndex + 1} bytes, got ${data.length}');
         }
    }
    // 仕様書ではビット(8+長さ*8)-(15+長さ*8)となっているが、これは最後のバイトを指すと思われる
    // length=1 の場合、レベルは data[2] (ビット16から) と仮定
    int level = _extractBits(data, 16, 8);

    return BatteryInfo(
      mode: 0xEF,
      length: length,
      rawData: data,
      level: level,
    );
  }

  /// 製造日情報 (0xFA) を解析します。
  ManufacturingDateInfo _parseManufacturingDateInfo(Uint8List data, int length) {
     // 期待される最小長をチェック (mode(1) + len(1) + year(2) + month(1) + day(1) = 6バイト)
    if (data.length < 6) {
       throw DataParsingException('Insufficient data length for ManufacturingDateInfo. Expected at least 6 bytes, got ${data.length}');
    }
    return ManufacturingDateInfo(
      mode: 0xFA,
      length: length,
      rawData: data,
      year: _extractBits(data, 16, 16), // 2バイト
      month: _extractBits(data, 32, 8), // 1バイト
      day: _extractBits(data, 40, 8), // 1バイト
    );
  }

  /// ハードウェア名 (0xFC) を解析します。
  HardwareNameInfo _parseHardwareNameInfo(Uint8List data, int length) {
     // 期待される最小長をチェック (mode(1) + len(1) = 2バイト)
    if (data.length < 2 + (length -1) ) { // ヘッダ2バイト + ペイロード(length-1)バイト
       throw DataParsingException('Insufficient data length for HardwareNameInfo. Expected at least ${2 + length -1} bytes, got ${data.length}');
    }
    // 名前はバイト2から開始 (ビット16から)
    // 長さは length - 1 バイト
    List<int> nameBytes = [];
    for (int i = 0; i < length - 1; i++) {
      nameBytes.add(_extractBits(data, 16 + i * 8, 8));
    }
    String name = String.fromCharCodes(nameBytes);

    return HardwareNameInfo(
      mode: 0xFC,
      length: length,
      rawData: data,
      name: name,
    );
  }

  /// ソフトウェアバージョン (0xFD) を解析します。
  SoftwareVersionInfo _parseSoftwareVersionInfo(Uint8List data, int length) {
     // 期待される最小長をチェック (mode(1) + len(1) + major(0.5) + minor(0.5) = 3バイト)
    if (data.length < 3) {
       throw DataParsingException('Insufficient data length for SoftwareVersionInfo. Expected at least 3 bytes, got ${data.length}');
    }
    return SoftwareVersionInfo(
      mode: 0xFD,
      length: length,
      rawData: data,
      major: _extractBits(data, 16, 4), // 4ビット
      minor: _extractBits(data, 20, 4), // 4ビット
    );
  }

  /// ハードウェアバージョン (0xFE) を解析します。
  HardwareVersionInfo _parseHardwareVersionInfo(Uint8List data, int length) {
     // 期待される最小長をチェック (mode(1) + len(1) + major(0.5) + minor(0.5) = 3バイト)
    if (data.length < 3) {
       throw DataParsingException('Insufficient data length for HardwareVersionInfo. Expected at least 3 bytes, got ${data.length}');
    }
    return HardwareVersionInfo(
      mode: 0xFE,
      length: length,
      rawData: data,
      major: _extractBits(data, 16, 4), // 4ビット
      minor: _extractBits(data, 20, 4), // 4ビット
    );
  }
}