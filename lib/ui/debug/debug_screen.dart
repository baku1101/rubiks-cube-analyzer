import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rubiks_cube_analyzer/services/bluetooth/interface/service.dart';
import 'package:rubiks_cube_analyzer/services/gan/protocol/response.dart'; // ResponseData をインポート
import 'package:rubiks_cube_analyzer/services/gan/protocol/handler.dart'; // GanProtocolHandler をインポート
import 'package:rubiks_cube_analyzer/services/bluetooth/interface/device.dart'; // BluetoothDevice をインポート
import 'dart:async'; // StreamSubscription をインポート
// import 'package:rubiks_cube_analyzer/services/gan/protocol/handler.dart'; // プロトコルハンドラ (将来)
// import 'package:rubiks_cube_analyzer/services/gan/state/cube_state.dart'; // キューブ状態 (将来)

import 'connection_view.dart';
import 'data_view.dart';
import 'cube_state_view.dart';

/// デバッグ画面の状態とロジックを管理するViewModel。
class DebugViewModel extends ChangeNotifier {
  final BluetoothService bluetoothService;
  // final GanProtocolHandler protocolHandler; // 将来追加
  // CubeState? cubeState; // 将来追加

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  List<BluetoothDevice> _scanResults = [];
  List<BluetoothDevice> get scanResults => List.unmodifiable(_scanResults); // 外部変更不可

  BluetoothDevice? _connectedDevice;
  BluetoothDevice? get connectedDevice => _connectedDevice;

  String _connectionStatus = "未接続";
  String get connectionStatus => _connectionStatus;

  GanProtocolHandler? _protocolHandler;

  final List<String> _dataLogs = [];
  List<String> get dataLogs => List.unmodifiable(_dataLogs);

  StreamSubscription? _scanSubscription;
  StreamSubscription? _dataSubscription;

  DebugViewModel(this.bluetoothService) {
    // dataStream をリッスン開始
    _dataSubscription = bluetoothService.dataStream.listen(_onDataReceived);
    // _protocolHandler?.responseStream.listen(...); // プロトコルハンドラからのレスポンスをリッスン (将来)
    // protocolHandler.stateStream.listen(...);
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _dataSubscription?.cancel();
    _protocolHandler?.dispose();
    // 必要であれば bluetoothService.disconnect() も呼ぶ
    super.dispose();
  }

  /// デバイススキャンを開始/停止します。
  Future<void> toggleScan() async {
    if (_isScanning) {
      // TODO: flutter_blue_plus に stopScan があれば呼び出す
      // await bluetoothService.stopScan(); // 仮
      _scanSubscription?.cancel();
      _isScanning = false;
      _connectionStatus = _connectedDevice == null ? "未接続" : "${_connectedDevice!.name} に接続済み";
      notifyListeners();
    } else {
      _isScanning = true;
      _scanResults = [];
      _connectionStatus = "スキャン中...";
      notifyListeners();

      _scanSubscription = bluetoothService.scanDevices().listen(
        (devices) {
          _scanResults = devices;
          notifyListeners();
        },
        onDone: () {
          _isScanning = false;
          _connectionStatus = "デバイスを選択してください";
          notifyListeners();
        },
        onError: (error) {
          _isScanning = false;
          _connectionStatus = "スキャンエラー: $error";
          _addDataLog("スキャンエラー: $error");
          notifyListeners();
        },
      );
    }
  }

  /// 指定されたデバイスに接続します。
  Future<void> connect(BluetoothDevice device) async {
    if (_connectedDevice != null || _isScanning) return;

    _connectionStatus = "${device.name} に接続中...";
    notifyListeners();

    try {
      await bluetoothService.connect(device);
      _connectedDevice = device;
        // 接続成功時にプロトコルハンドラを初期化
        _protocolHandler = GanProtocolHandler(bluetoothService, device.remoteId);
        _protocolHandler?.responseStream.listen(_onResponseParsed); // 解析済みレスポンスをリッスン
      _connectionStatus = "${device.name} に接続済み";
      _addDataLog("${device.name} に接続しました。");
      // 再度 dataStream をリッスン開始 (接続後にストリームが変わる場合があるため)
      _dataSubscription?.cancel();
      _dataSubscription = bluetoothService.dataStream.listen(_onDataReceived);
    } catch (e) {
      _connectionStatus = "接続エラー: $e";
      _addDataLog("接続エラー (${device.name}): $e");
    } finally {
      notifyListeners();
    }
  }

  /// 現在接続中のデバイスから切断します。
  Future<void> disconnect() async {
    if (_connectedDevice == null) return;

    final deviceName = _connectedDevice!.name;
    _connectionStatus = "$deviceName から切断中...";
    notifyListeners();

    try {
      await bluetoothService.disconnect();
      _connectedDevice = null;
      _connectionStatus = "未接続";
      _addDataLog("$deviceName から切断しました。");
      _dataSubscription?.cancel(); // データ受信停止
    } catch (e) {
      _connectionStatus = "切断エラー: $e";
      _addDataLog("切断エラー ($deviceName): $e");
    } finally {
      notifyListeners();
    }
  }

  /// データを送信します (暗号化前のコマンド)。
  Future<void> sendCommand(List<int> command) async {
    if (_connectedDevice == null) {
      _addDataLog("エラー: データ送信試行時、未接続です。");
      notifyListeners();
      return;
    }
    // TODO: プロトコルハンドラ経由で暗号化して送信する
    // await protocolHandler.sendCommand(command);
    _addDataLog("送信 (Cmd): ${command.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(' ')}");
    // 仮実装: BluetoothServiceに直接書き込む (暗号化なし)
    try {
      await _protocolHandler!.sendCommand(command);
      _addDataLog("送信 (Raw): ${command.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(' ')}");
    } catch (e) {
      _addDataLog("データ送信エラー: $e");
    }
  }

  /// データログを追加します。
  void _addDataLog(String log) {
    final timestamp = DateTime.now().toString().substring(11, 23); // 時:分:秒.ミリ秒
    _dataLogs.add("[$timestamp] $log");
    // ログが多くなりすぎないように制限 (例: 最新100件)
    if (_dataLogs.length > 100) {
      _dataLogs.removeRange(0, _dataLogs.length - 100);
    }
    notifyListeners(); // UI更新通知
  }

  /// BluetoothService からデータを受信したときの処理。
  void _onDataReceived(List<int> data) {
    // _addDataLog("受信 (Raw): ${data.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(' ')}");
    // TODO: プロトコルハンドラ経由で復号化・解析する
    // protocolHandler.handleRawData(data);
  }

  /// プロトコルハンドラから解析済みデータを受信したときの処理。
  void _onResponseParsed(ResponseData response) {
    _addDataLog("受信 (Parsed): $response");
    // TODO: キューブ状態を更新する
  }

  /// データログをクリアします。
  void clearLogs() {
    _dataLogs.clear();
    notifyListeners();
  }
}


/// デバッグ用のメイン画面ウィジェット。
class DebugScreen extends StatelessWidget {
  const DebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: main.dart などで BluetoothService のインスタンスを提供し、ここで取得する
    //       例: final bluetoothService = WindowsBluetoothService(); // 仮
    //       実際には get_it や riverpod などを使うのが一般的
    final bluetoothService = Provider.of<BluetoothService>(context, listen: false);
 // Provider経由で取得

    // DebugViewModel を Provider で提供
    return ChangeNotifierProvider(
      // create: (_) => DebugViewModel(WindowsBluetoothService()), // 仮のサービスで生成
      create: (_) => DebugViewModel(bluetoothService),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('デバッグ画面'),
          ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- 接続ビュー ---
              Expanded(
                child: Card(
  
                child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ConnectionView(), // ViewModelは内部で Consumer/Selector を使って取得
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // --- データビュー ---
              Expanded(
                flex: 2,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: DataView(), // ViewModelは内部で Consumer/Selector を使って取得
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // --- キューブ状態ビュー ---
              Expanded(
                flex: 1,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CubeStateView(), // ViewModelは内部で Consumer/Selector を使って取得
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}