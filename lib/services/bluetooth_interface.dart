import 'package:flutter/foundation.dart';
import '../models/bluetooth_device_info.dart';
import '../models/move.dart';

/// Bluetoothインターフェース
abstract class BluetoothInterface extends ChangeNotifier {
  // GAN V4キューブのUUID定数
  static const String GAN_SERVICE_UUID = '00000010-0000-fff7-fff6-fff5fff4fff0';
  static const String GAN_CHARACTERISTIC_READ = 'fff6';
  static const String GAN_CHARACTERISTIC_WRITE = 'fff5';

  // V4のデータ処理用の定数
  static const List<int> V4_PREFIX = [0xa5, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00];
  static const int V4_GET_VERSION = 0x01;
  static const int V4_GET_STATUS = 0x02;
  static const int V4_GET_BATTERY = 0x0a;
  static const int V4_FACE_STATUS = 0x07;
  static const int V4_DO_MOVES = 0x06;

  /// デバイスが接続されているかどうか
  bool get isConnected;

  /// スキャン中かどうか
  bool get isScanning;

  /// スキャン結果の一覧
  List<BluetoothDeviceInfo> get scanResults;

  /// 接続中のデバイス
  BluetoothDeviceInfo? get connectedDevice;

  /// デバイスのスキャンを開始
  Future<void> startScan();

  /// デバイスのスキャンを停止
  Future<void> stopScan();

  /// デバイスに接続
  Future<bool> connectToDevice(BluetoothDeviceInfo device);

  /// デバイスとの接続を切断
  Future<void> disconnect();

  /// サービスを探索
  Future<dynamic> discoverService(dynamic device, String serviceUuid);

  /// キャラクタリスティックを購読
  Stream<List<int>>? subscribeToCharacteristic(
    dynamic service,
    String characteristicUuid,
  );

  /// キャラクタリスティックに書き込み
  Future<bool> writeCharacteristic(
    dynamic service,
    String characteristicUuid,
    List<int> value,
  );

  /// プラットフォーム固有のデバイスオブジェクトを取得
  dynamic getNativeDevice(BluetoothDeviceInfo device);

  /// V4用コマンドパケットを作成
  List<int> createV4Command(int command, [List<int>? data]) {
    final packet = [...V4_PREFIX];
    packet[1] = command;
    if (data != null) {
      packet.addAll(data);
    }
    return packet;
  }

  /// バッテリー残量取得コマンドを作成
  List<int> createBatteryCommand() {
    return createV4Command(V4_GET_BATTERY);
  }

  /// キューブ状態取得コマンドを作成
  List<int> createCubeStateCommand() {
    return createV4Command(V4_FACE_STATUS);
  }

  /// スクランブルコマンドを作成
  List<int> createScrambleCommand(List<Move> moves) {
    final moveData = <int>[];
    
    // スクランブルムーブをV4形式に変換
    for (final move in moves) {
      final moveCode = _getMoveCode(move.type);
      if (moveCode != null) {
        moveData.add(moveCode);
      }
    }

    return createV4Command(V4_DO_MOVES, moveData);
  }

  /// MoveTypeをV4のムーブコードに変換
  int? _getMoveCode(MoveType type) {
    // GAN V4のムーブコード形式に変換
    // 0: U, 1: U', 2: U2, 3: D, 4: D', 5: D2, ...
    switch (type) {
      case MoveType.U: return 0x00;
      case MoveType.UPrime: return 0x01;
      case MoveType.U2: return 0x02;
      case MoveType.D: return 0x03;
      case MoveType.DPrime: return 0x04;
      case MoveType.D2: return 0x05;
      case MoveType.R: return 0x06;
      case MoveType.RPrime: return 0x07;
      case MoveType.R2: return 0x08;
      case MoveType.L: return 0x09;
      case MoveType.LPrime: return 0x0A;
      case MoveType.L2: return 0x0B;
      case MoveType.F: return 0x0C;
      case MoveType.FPrime: return 0x0D;
      case MoveType.F2: return 0x0E;
      case MoveType.B: return 0x0F;
      case MoveType.BPrime: return 0x10;
      case MoveType.B2: return 0x11;
    }
  }
}
