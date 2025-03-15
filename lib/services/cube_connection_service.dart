import 'package:flutter/foundation.dart';
import 'package:rubiks_cube_analyzer/services/bluetooth_factory.dart';
import '../models/bluetooth_device_info.dart';
import '../models/cube_state.dart';
import '../models/move.dart';
import 'bluetooth_interface.dart';
import 'gan_cube_protocol.dart';

/// GANキューブとの接続を管理するサービス
class CubeConnectionService extends ChangeNotifier {
  final BluetoothInterface _bluetooth;
  final GanCubeProtocol _protocol = GanCubeProtocol();
  
  CubeState? _currentState;
  BluetoothDeviceInfo? _connectedDevice;
  int _batteryLevel = 0;
  bool _isConnected = false;
  bool _isConnecting = false;
  DateTime? _solveStartTime;
  DateTime? _solveEndTime;
  final List<Move> _moveHistory = [];
  
  CubeConnectionService({BluetoothInterface? bluetooth})
    : _bluetooth = bluetooth ?? BluetoothFactory.getInstance(){
    _initializeListeners();
  }

  // 状態の取得
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  CubeState get currentCubeState => CubeState.solved();
  BluetoothDeviceInfo? get connectedDevice => _connectedDevice;
  int get batteryLevel => _batteryLevel;
  List<Move> get moveHistory => List.unmodifiable(_moveHistory);
  DateTime? get solveStartTime => _solveStartTime;
  DateTime? get solveEndTime => _solveEndTime;

  /// リスナーの初期化
  void _initializeListeners() {
    _protocol.onStateUpdate = (state) {
      _currentState = state;
      _checkSolveStatus();
      notifyListeners();
    };

    _protocol.onBatteryUpdate = (level) {
      _batteryLevel = level;
      notifyListeners();
    };

    _protocol.onMoveDetected = (move, timestamp) {
      _moveHistory.add(move);
      notifyListeners();
    };
  }

  /// ソルブの状態をチェック
  void _checkSolveStatus() {
    if (_currentState == null) return;

    // ソルブ開始判定
    if (_solveStartTime == null && !_currentState!.isSolved) {
      _solveStartTime = DateTime.now();
      notifyListeners();
    }
    // ソルブ完了判定
    else if (_solveStartTime != null && _currentState!.isSolved) {
      _solveEndTime = DateTime.now();
      notifyListeners();
    }
  }

  /// ソルブをリセット
  void resetSolve() {
    _solveStartTime = null;
    _solveEndTime = null;
    _moveHistory.clear();
    notifyListeners();
  }

  /// スクランブル手順を生成
  Future<List<Move>> scrambleCube(int moveCount) async {
    if (!_isConnected) return [];

    try {
      // スクランブル手順を生成
      final moves = generateScramble(moveCount);
      
      // 現在の状態を保存
      final prevState = _currentState;
      
      // スクランブルが開始されたことを記録
      resetSolve();
      
      // スクランブル手順をUIに表示するために返す
      return moves;
    } catch (e) {
      debugPrint('スクランブル生成エラー: $e');
      return [];
    }
  }

  /// スクランブル手順を生成
  List<Move> generateScramble(int moveCount) {
    final moves = <Move>[];
    final random = DateTime.now().millisecondsSinceEpoch;
    
    MoveType? lastMove;
    MoveType? secondLastMove;
    
    for (var i = 0; i < moveCount; i++) {
      MoveType move;
      do {
        // 同じ面の連続を避ける
        move = MoveType.values[(random + i * 3) % MoveType.values.length];
      } while (_isInvalidMove(move, lastMove, secondLastMove));
      
      moves.add(Move(
        type: move,
        timestamp: DateTime.now(),
      ));
      
      secondLastMove = lastMove;
      lastMove = move;
    }
    return moves;
  }

  /// 無効な手順かどうかをチェック
  bool _isInvalidMove(MoveType move, MoveType? lastMove, MoveType? secondLastMove) {
    if (lastMove == null) return false;
    
    // 同じ面の連続を避ける
    final currentFace = move.toString().substring(0, 1);
    final lastFace = lastMove.toString().substring(0, 1);
    if (currentFace == lastFace) return true;
    
    // 対面の3手連続を避ける
    if (secondLastMove != null) {
      final secondLastFace = secondLastMove.toString().substring(0, 1);
      if (_isOppositeFaces(currentFace, lastFace) && 
          _isOppositeFaces(lastFace, secondLastFace)) {
        return true;
      }
    }
    
    return false;
  }

  /// 対面かどうかをチェック
  bool _isOppositeFaces(String face1, String face2) {
    const opposites = {
      'U': 'D', 'D': 'U',
      'R': 'L', 'L': 'R',
      'F': 'B', 'B': 'F',
    };
    return opposites[face1] == face2;
  }

  /// キューブに接続
  Future<bool> connectToCube(BluetoothDeviceInfo device) async {
    if (_isConnecting) return false;
    
    try {
      _isConnecting = true;
      notifyListeners();

      // Bluetooth接続を確立
      final success = await _bluetooth.connectToDevice(device);
      if (!success) {
        debugPrint('Bluetooth接続に失敗');
        return false;
      }

      _connectedDevice = device;

      // サービスの検出
      final service = await _bluetooth.discoverService(
        device.nativeDevice, 
        BluetoothInterface.GAN_SERVICE_UUID,
      );
      if (service == null) {
        debugPrint('サービスが見つかりません');
        return false;
      }

      // 通知の購読開始
      final dataStream = _bluetooth.subscribeToCharacteristic(
        service,
        'fff6', // 短縮UUID使用
      );
      if (dataStream == null) {
        debugPrint('通知の購読に失敗');
        return false;
      }

      // データの監視を開始
      dataStream.listen((data) {
        _protocol.processDataPacket(data);
      });

      // デコーダの初期化
      final macAddress = device.id;
      debugPrint('デコーダを初期化: MAC=$macAddress');
       _protocol.initializeDecoder(macAddress);

      // 初期データの要求
      await _requestInitialData();

      _isConnected = true;
      notifyListeners();
      return true;

    } catch (e) {
      debugPrint('接続エラー: $e');
      await disconnect();
      return false;
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  /// キューブから切断
  Future<void> disconnect() async {
    try {
      await _bluetooth.disconnect();
    } finally {
      _isConnected = false;
      _connectedDevice = null;
      _currentState = null;
      _batteryLevel = 0;
      _moveHistory.clear();
      _solveStartTime = null;
      _solveEndTime = null;
      notifyListeners();
    }
  }

  /// 初期データを要求
  Future<void> _requestInitialData() async {
    if (!_isConnected) return;

    try {
      // ハードウェア情報を要求
      final hwCommand = _protocol.createHardwareCommand();
      await _bluetooth.writeCharacteristic(
        _connectedDevice!,
        'fff5', // 短縮UUID使用
        hwCommand,
      );

      // キューブの状態を要求
      requestCubeState();

      // バッテリー残量を要求
      requestBatteryLevel();
    } catch (e) {
      debugPrint('初期データ要求エラー: $e');
    }
  }

  /// バッテリー残量を要求
  Future<void> requestBatteryLevel() async {
    if (!_isConnected) return;

    final command = _protocol.createBatteryCommand();
    await _bluetooth.writeCharacteristic(
      _connectedDevice!,
      'fff5', // 短縮UUID使用
      command,
    );
  }

  /// キューブの状態を要求
  Future<void> requestCubeState() async {
    if (!_isConnected) return;

    final command = _protocol.createFaceletsCommand();
    await _bluetooth.writeCharacteristic(
      _connectedDevice!,
      'fff5', // 短縮UUID使用
      command,
    );
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}