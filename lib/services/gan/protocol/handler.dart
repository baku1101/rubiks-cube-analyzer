import 'dart:async';
import 'dart:typed_data';

import 'package:rubiks_cube_analyzer/services/bluetooth/interface/service.dart';
import 'package:rubiks_cube_analyzer/services/gan/crypto/aes.dart';
import 'package:rubiks_cube_analyzer/services/gan/protocol/command.dart';
import 'package:rubiks_cube_analyzer/services/gan/protocol/response.dart';

/// GANキューブV4プロトコルハンドラー。
///
/// BluetoothServiceからの生データを受信し、復号化、解析し、ResponseDataをストリームで提供します。
class GanProtocolHandler {
  final BluetoothService _bluetoothService;
  final GanAes128 _cipher;
  final ResponseParser _parser = ResponseParser();
  final StreamController<ResponseData> _responseController = StreamController.broadcast();

  /// 解析されたレスポンスデータのストリーム。
  Stream<ResponseData> get responseStream => _responseController.stream;

  /// コンストラクタ。BluetoothServiceとMACアドレスを必要とします。
  GanProtocolHandler(this._bluetoothService, String macAddress)
      : _cipher = _initializeCipher(macAddress) {
    _bluetoothService.dataStream.listen(_handleRawData);
  }

  // GanAes128 を初期化するヘルパーメソッド
  static GanAes128 _initializeCipher(String macAddress) {
    final keyData = KeyGenerator.generateFromMAC(macAddress);
    return GanAes128(keyData.key, keyData.iv);
  }

  /// BluetoothServiceから受信した生データを処理します。
  void _handleRawData(List<int> rawData) {
    Uint8List? decrypted;
    try {
      if (rawData.isEmpty) {
        return;
      }
      
      decrypted = _cipher.decrypt(rawData);
      final response = _parser.parse(decrypted);
      
      if (response is MoveEvent) {
        print('👉 ${response}');
      } else if (response is CubeStateData) {
        print('📊 ${response}');
      }
      _responseController.add(response);

    } catch (e, stackTrace) {
      print('❌ Error: $e');

      // DataParsingException または UnknownResponseModeException の場合は、エラーをそのままストリームに流す
      if (e is DataParsingException || e is UnknownResponseModeException) {
        _responseController.addError(e);
      }
      // TODO: より詳細なエラー処理
    }
  }

  /// 指定されたコマンドを暗号化してBluetoothServiceに送信します。
  Future<void> sendCommand(List<int> command) async {
    final encrypted = _cipher.encrypt(command);
    await _bluetoothService.writeData(encrypted);
  }

  /// 状態取得リクエストを送信します。
  Future<void> requestState() async {
    await sendCommand(CommandBuilder.createStateRequest());
  }

  /// バッテリー情報取得リクエストを送信します。
  Future<void> requestBattery() async {
    await sendCommand(CommandBuilder.createBatteryRequest());
  }

  /// リソースを解放します。
  void dispose() {
    _responseController.close();
  }
}