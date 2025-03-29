import 'dart:typed_data';

/// GANキューブV4に送信するコマンドを生成します。
///
/// コマンドは20バイトの配列として生成され、送信前に暗号化される必要があります。
class CommandBuilder {
  /// キューブの状態取得リクエストコマンドを生成します。
  static List<int> createStateRequest() {
    final command = Uint8List(20);
    command[0] = 0xDD; // ヘッダー
    command[1] = 0x04; // 長さ
    command[3] = 0xED; // サブコマンド
    // 残りは0埋め
    return command.toList();
  }

  /// バッテリー残量取得リクエストコマンドを生成します。
  static List<int> createBatteryRequest() {
    final command = Uint8List(20);
    command[0] = 0xDD; // ヘッダー
    command[1] = 0x04; // 長さ
    command[3] = 0xEF; // サブコマンド
    // 残りは0埋め
    return command.toList();
  }

  /// ハードウェア情報取得リクエストコマンドを生成します。
  static List<int> createHardwareInfoRequest() {
    final command = Uint8List(20);
    command[0] = 0xDF; // ヘッダー
    command[1] = 0x03; // 長さ
    // バイト3は使用しない
    // 残りは0埋め
    return command.toList();
  }

  /// 移動履歴取得リクエストコマンドを生成します。
  ///
  /// [startCounter] 開始する移動カウンター値 (0-255)。
  /// [count] 取得する移動数 (0-255)。
  ///
  /// 注意: 仕様書に基づき、送信前に startCounter は奇数に、count は偶数に調整されるべきですが、
  ///       このメソッドでは調整を行いません。呼び出し側で調整するか、
  ///       プロトコルハンドラ層で調整することを推奨します。
  ///       また、カウンター循環領域をまたぐリクエストは避ける必要があります。
  static List<int> createMoveHistoryRequest(int startCounter, int count) {
    if (startCounter < 0 || startCounter > 255) {
      throw ArgumentError('Start counter must be between 0 and 255.');
    }
    if (count < 0 || count > 255) {
      throw ArgumentError('Count must be between 0 and 255.');
    }

    final command = Uint8List(20);
    command[0] = 0xD1; // ヘッダー
    command[1] = 0x04; // 長さ
    // バイト2-3: 開始ムーブカウンター (リトルエンディアン)
    command[2] = startCounter & 0xFF;
    command[3] = (startCounter >> 8) & 0xFF; // V4では1バイトのみ使用？仕様書確認要
    // バイト4-5: 移動数 (リトルエンディアン)
    command[4] = count & 0xFF;
    command[5] = (count >> 8) & 0xFF; // V4では1バイトのみ使用？仕様書確認要

    // 仕様書ではバイト2-3が開始カウンター、4-5が移動数となっているが、
    // cstimerの実装や他の情報源と照らし合わせると、
    // バイト2が開始カウンター、バイト3が移動数の可能性が高い。要検証。
    // 一旦、仕様書通りに実装しておく。
    // command[2] = startCounter;
    // command[3] = count;

    // 残りは0埋め
    return command.toList();
  }

  // TODO: 必要に応じて他のコマンド生成メソッドを追加します。
}