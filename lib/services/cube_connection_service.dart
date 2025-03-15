import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/bluetooth_device_info.dart';
import '../models/cube_state.dart';
import '../models/move.dart';
import 'bluetooth_factory.dart' as bf;
import 'bluetooth_interface.dart';

/// キューブの接続状態
enum CubeConnectionState {
  /// 未接続
  disconnected,
  /// 接続中
  connecting,
  /// 接続済み
  connected,
  /// エラー
  error,
}

/// キューブの状態管理サービス
class CubeConnectionService extends ChangeNotifier {
  final BluetoothInterface _bluetoothService;
  CubeConnectionState _connectionState = CubeConnectionState.disconnected;
  String? _errorMessage;
  BluetoothDeviceInfo? _connectedDevice;
  dynamic _service;
  StreamSubscription? _notificationSubscription;

  // キューブの状態管理
  CubeState _currentCubeState = CubeState.solved();
  List<Move> _moveHistory = [];
  DateTime? _solveStartTime;
  DateTime? _solveEndTime;
  int _batteryLevel = 0;
  bool _isConnecting = false;

  /// キューブの接続状態
  CubeConnectionState get connectionState => _connectionState;

  /// エラーメッセージ
  String? get errorMessage => _errorMessage;

  /// 接続中のデバイス
  BluetoothDeviceInfo? get connectedDevice => _connectedDevice;

  /// キューブの現在の状態
  CubeState get currentCubeState => _currentCubeState;

  /// 移動履歴
  List<Move> get moveHistory => List.unmodifiable(_moveHistory);

  /// ソルブ開始時間
  DateTime? get solveStartTime => _solveStartTime;

  /// ソルブ終了時間
  DateTime? get solveEndTime => _solveEndTime;

  /// バッテリー残量
  int get batteryLevel => _batteryLevel;

  /// 接続中かどうか
  bool get isConnecting => _isConnecting;

  /// 接続済みかどうか
  bool get isConnected => _connectionState == CubeConnectionState.connected;

  /// コンストラクタ
  CubeConnectionService({BluetoothInterface? bluetoothService}) 
    : _bluetoothService = bluetoothService ?? bf.BluetoothFactory.getInstance();

  /// Bluetoothがサポートされているかチェック
  static Future<bool> isSupported() {
    return bf.BluetoothFactory.isSupported();
  }

  /// キューブの接続を開始
  Future<bool> connectToCube(BluetoothDeviceInfo device) async {
    try {
      _connectionState = CubeConnectionState.connecting;
      _isConnecting = true;
      _errorMessage = null;
      notifyListeners();

      final connected = await _bluetoothService.connectToDevice(device);
      if (!connected) {
        throw Exception('キューブとの接続に失敗しました');
      }

      // GAN Cubeのサービスを取得
      _service = await _bluetoothService.discoverService(
        device,
        BluetoothInterface.GAN_SERVICE_UUID,
      );

      if (_service == null) {
        throw Exception('GAN Cubeのサービスが見つかりません');
      }

      // 通知を購読
      final notificationStream = _bluetoothService.subscribeToCharacteristic(
        _service,
        BluetoothInterface.GAN_CHARACTERISTIC_READ,
      );

      if (notificationStream == null) {
        throw Exception('通知の購読に失敗しました');
      }

      _notificationSubscription = notificationStream.listen(
        _handleCubeState,
        onError: _handleError,
      );

      _connectionState = CubeConnectionState.connected;
      _connectedDevice = device;
      _isConnecting = false;
      
      // バッテリー残量を取得
      await _requestBatteryLevel();

      notifyListeners();
      return true;
    } catch (e) {
      _handleError(e);
      return false;
    }
  }

  /// キューブとの接続を切断
  Future<void> disconnect() async {
    await _notificationSubscription?.cancel();
    _notificationSubscription = null;
    await _bluetoothService.disconnect();
    _service = null;
    _connectedDevice = null;
    _connectionState = CubeConnectionState.disconnected;
    _currentCubeState = CubeState.solved();
    _moveHistory.clear();
    _solveStartTime = null;
    _solveEndTime = null;
    _batteryLevel = 0;
    _isConnecting = false;
    notifyListeners();
  }

  /// ソルブをリセット
  void resetSolve() {
    _moveHistory.clear();
    _solveStartTime = null;
    _solveEndTime = null;
    notifyListeners();
  }

  /// スクランブルを実行
  Future<List<Move>> scrambleCube(int moveCount) async {
    if (!isConnected || _service == null) {
      return [];
    }

    final random = Random();
    final baseTypes = [
      MoveType.U, MoveType.D, MoveType.R, 
      MoveType.L, MoveType.F, MoveType.B
    ];
    final moves = <Move>[];
    MoveType? lastMove;

    // スクランブルのムーブを生成
    for (var i = 0; i < moveCount; i++) {
      MoveType moveType;
      do {
        moveType = baseTypes[random.nextInt(baseTypes.length)];
      } while (lastMove != null && moveType.toString()[0] == lastMove.toString()[0]);

      // ランダムに回転方向を決定（通常、逆回転、180度）
      final variation = random.nextInt(3);
      if (variation == 1) {
        moveType = MoveType.values[moveType.index + 1]; // Prime
      } else if (variation == 2) {
        moveType = MoveType.values[moveType.index + 2]; // 2
      }

      moves.add(Move(
        type: moveType,
        timestamp: DateTime.now(),
      ));
      lastMove = moveType;
    }

    // スクランブルを実行
    try {
      final command = _bluetoothService.createScrambleCommand(moves);
      await _bluetoothService.writeCharacteristic(
        _service,
        BluetoothInterface.GAN_CHARACTERISTIC_WRITE,
        command,
      );
      debugPrint('スクランブルを実行: ${moves.map((m) => m.toString()).join(" ")}');
      return moves;
    } catch (e) {
      debugPrint('スクランブル実行エラー: $e');
      return [];
    }
  }

  /// キューブの状態を処理
  void _handleCubeState(List<int> data) {
    try {
      if (data.isEmpty) return;

      // gancube.jsのデータ形式に合わせて解析
      if (data.length >= 7) {
        switch (data[1]) {
          case BluetoothInterface.V4_GET_BATTERY:
            if (data.length >= 8) {
              _batteryLevel = data[7];
              debugPrint('バッテリー残量: $_batteryLevel%');
              notifyListeners();
            }
            break;

          case BluetoothInterface.V4_FACE_STATUS:
            if (data.length >= 14) {
              // 前の状態を保持
              final oldState = _currentCubeState;
              
              // V4のデータ形式に基づいてキューブの状態を更新
              final faceData = data.sublist(7, 14);
              final newState = CubeState.fromV4Data(faceData);
              _currentCubeState = newState;

              // 状態が変化した場合の処理
              if (_solveStartTime == null && !oldState.isSolved) {
                _solveStartTime = DateTime.now();
              }

              if (newState.isSolved && !oldState.isSolved) {
                _solveEndTime = DateTime.now();
                debugPrint('ソルブ完了！ 経過時間: ${_solveEndTime!.difference(_solveStartTime!).inSeconds}秒');
              }

              notifyListeners();
            }
            break;
        }
      }
    } catch (e) {
      debugPrint('キューブの状態解析エラー: $e');
    }
  }

  /// バッテリー残量を要求
  Future<void> _requestBatteryLevel() async {
    try {
      if (_service == null) return;

      final command = _bluetoothService.createBatteryCommand();
      await _bluetoothService.writeCharacteristic(
        _service,
        BluetoothInterface.GAN_CHARACTERISTIC_WRITE,
        command,
      );
    } catch (e) {
      debugPrint('バッテリー残量要求エラー: $e');
    }
  }

  /// エラーを処理
  void _handleError(dynamic error) {
    debugPrint('エラーが発生しました: $error');
    _errorMessage = error.toString();
    _connectionState = CubeConnectionState.error;
    _isConnecting = false;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}