import 'device.dart';

/// Bluetoothサービスへのアクセスを提供するインターフェース。
///
/// プラットフォーム固有の実装（Windows、Webなど）は、このインターフェースを実装します。
abstract class BluetoothService {
  /// デバイスから受信したデータのストリーム。
  Stream<List<int>> get dataStream;

  /// 利用可能なBluetoothデバイスのスキャンを開始します。
  Stream<List<BluetoothDevice>> scanDevices();

  /// 指定されたデバイスに接続します。
  Future<void> connect(BluetoothDevice device);

  /// 現在接続されているデバイスから切断します。
  Future<void> disconnect();

  /// 接続されているデバイスにデータを書き込みます。
  Future<void> writeData(List<int> data);
}