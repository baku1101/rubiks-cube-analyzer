import 'dart:async';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus_windows/flutter_blue_plus_windows.dart' as fbpw;
import '../models/bluetooth_device_info.dart';
import '../models/cube_state.dart';
import '../models/move.dart';
import 'bluetooth_service.dart';
import 'cube_state_updater.dart';

class CubeConnectionService extends ChangeNotifier {
  final CubeBluetoothService _bluetoothService;
  
  static const String GAN_SERVICE_UUID = '00000010-0000-fff7-fff6-fff5fff4fff0';
  static const String GAN_CHARACTERISTIC_RX = 'fff5';  // 書き込み用
  static const String GAN_CHARACTERISTIC_TX = 'fff6';  // 通知用

  // キーの初期値を追加
  static const List<List<int>> KEYS = [
    [0xf6, 0xc5, 0xa8, 0x87, 0x99, 0xd3], // v4用
  ];
  
  fbpw.BluetoothService? _ganService;
  StreamSubscription<List<dynamic>>? _cubeDataSubscription;
  List<int>? _decodeKey;
  List<int>? _decodeIv;
  
  bool _isConnecting = false;
  bool _isConfigured = false;
  CubeState _currentCubeState = CubeState.solved();
  final List<Move> _moveHistory = [];
  int _batteryLevel = 0;
  
  DateTime? _connectionStartTime;
  DateTime? _solveStartTime;
  DateTime? _solveEndTime;

  CubeConnectionService(this._bluetoothService);

  // ゲッター
  bool get isConnecting => _isConnecting;
  bool get isConnected => _bluetoothService.isConnected && _isConfigured;
  CubeState get currentCubeState => _currentCubeState;
  List<Move> get moveHistory => List.unmodifiable(_moveHistory);
  DateTime? get connectionStartTime => _connectionStartTime;
  DateTime? get solveStartTime => _solveStartTime;
  DateTime? get solveEndTime => _solveEndTime;
  BluetoothDeviceInfo? get connectedDevice => _bluetoothService.connectedDevice;
  int get batteryLevel => _batteryLevel;

  // キューブに接続
  Future<bool> connectToCube(BluetoothDeviceInfo device) async {
    _isConnecting = true;
    notifyListeners();
    
    try {
      final connected = await _bluetoothService.connectToDevice(device);
      if (!connected) {
        _isConnecting = false;
        notifyListeners();
        return false;
      }
      
      _ganService = await _bluetoothService.discoverService(
        device.nativeDevice,
        GAN_SERVICE_UUID,
      );
      
      if (_ganService == null) {
        await _bluetoothService.disconnect();
        _isConnecting = false;
        notifyListeners();
        return false;
      }

      // MACアドレスからキーを生成
      final deviceId = device.id.replaceAll(':', '').toLowerCase();
      if (!await _initializeKey(deviceId)) {
        debugPrint('キーの初期化に失敗');
        await _bluetoothService.disconnect();
        _isConnecting = false;
        notifyListeners();
        return false;
      }
      
      final dataStream = _bluetoothService.subscribeToCharacteristic(
        _ganService!,
        GAN_CHARACTERISTIC_TX,
      );
      
      if (dataStream == null) {
        await _bluetoothService.disconnect();
        _isConnecting = false;
        notifyListeners();
        return false;
      }
      
      _cubeDataSubscription = dataStream.listen(_processCubeData);
      
      await _sendInitialConfiguration();
      
      _connectionStartTime = DateTime.now();
      _isConnecting = false;
      _isConfigured = true;
      
      _currentCubeState = CubeState.solved();
      _moveHistory.clear();
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('キューブ接続エラー: $e');
      await _bluetoothService.disconnect();
      _isConnecting = false;
      _isConfigured = false;
      notifyListeners();
      return false;
    }
  }

  // キーを初期化
  Future<bool> _initializeKey(String deviceId) async {
    try {
      final macBytes = List<int>.filled(6, 0);
      for (var i = 0; i < 6; i++) {
        macBytes[i] = int.parse(deviceId.substring(i * 2, i * 2 + 2), radix: 16);
      }
      
      final baseKey = KEYS[0]; // v4用のキー
      _decodeKey = List<int>.filled(6, 0);
      _decodeIv = List<int>.filled(6, 0);
      
      // キーとIVを生成
      for (var i = 0; i < 6; i++) {
        _decodeKey![i] = (baseKey[i] + macBytes[5 - i]) % 255;
        _decodeIv![i] = (baseKey[i] + macBytes[5 - i]) % 255;
      }
      
      debugPrint('キー初期化成功: ${_decodeKey!.map((e) => e.toRadixString(16)).join(', ')}');
      return true;
    } catch (e) {
      debugPrint('キー初期化エラー: $e');
      return false;
    }
  }

  // データを復号化
  List<int>? _decode(List<int> data) {
    if (_decodeKey == null || _decodeIv == null) return null;
    
    final result = List<int>.from(data);
    final iv = List<int>.from(_decodeIv!);
    
    // 最初の4バイトはヘッダーなので、それ以降を復号化
    for (var i = 0; i < result.length; i++) {
      if (i < 4) {
        // ヘッダー部分はIVのみでXOR
        result[i] ^= iv[i % iv.length];
      } else {
        // データ部分はIVとKeyの両方でXOR
        result[i] ^= iv[i % iv.length] ^ _decodeKey![i % _decodeKey!.length];
      }
    }
    
    return result;
  }

  // キューブからのデータを処理
  void _processCubeData(List<dynamic> data) {
    if (data.isEmpty) return;
    
    try {
      final convertedData = data.cast<int>();
      final decodedData = _decode(convertedData);
      
      if (decodedData == null) {
        debugPrint('データの復号化に失敗');
        return;
      }

      // 受信データのデバッグ出力
      debugPrint('生データ: ${convertedData.map((b) => '0x${b.toRadixString(16)}').join(', ')}');
      debugPrint('復号後: ${decodedData.map((b) => '0x${b.toRadixString(16)}').join(', ')}');
      
      // データ形式のチェック
      if (decodedData.length < 4) {
        debugPrint('データが短すぎます');
        return;
      }

      final header = decodedData[0];
      if (header != 0xDD) {
        debugPrint('無効なヘッダー: 0x${header.toRadixString(16)}');
        return;
      }

      final length = decodedData[1];
      debugPrint('データ長: $length');

      final command = decodedData[3];
      switch (command) {
        case 0x01: // キューブの動き
          if (decodedData.length < 9) {
            debugPrint('移動データが短すぎます');
            return;
          }
          final binaryString = _convertToBinaryString(decodedData.sublist(4, 9));
          _processMovementDataV4(binaryString);
          break;

        case 0xED: // キューブの状態
          if (decodedData.length < 19) {
            debugPrint('キューブ状態データが短すぎます');
            return;
          }
          final binaryString = _convertToBinaryString(decodedData.sublist(4, 19));
          _processCubeStateDataV4(binaryString);
          break;

        case 0xEF: // バッテリー状態
          if (decodedData.length < 5) {
            debugPrint('バッテリーデータが短すぎます');
            return;
          }
          _processBatteryStatusDataV4(decodedData);
          break;

        default:
          debugPrint('未知のコマンド: 0x${command.toRadixString(16)}');
      }
    } catch (e, stackTrace) {
      debugPrint('データ処理エラー: $e');
      debugPrint('スタックトレース: $stackTrace');
    }
  }

  // バイト配列をバイナリ文字列に変換
  String _convertToBinaryString(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(2).padLeft(8, '0')).join('');
  }

  // キューブから切断
  Future<void> disconnect() async {
    _cubeDataSubscription?.cancel();
    _cubeDataSubscription = null;
    _ganService = null;
    _isConfigured = false;
    _connectionStartTime = null;
    _solveStartTime = null;
    _solveEndTime = null;
    
    await _bluetoothService.disconnect();
    notifyListeners();
  }

  // 初期設定コマンドをキューブに送信
  Future<void> _sendInitialConfiguration() async {
    if (_ganService == null) return;
    
    // キューブの状態を要求
    await _requestFacelets();
    // バッテリー状態を要求
    await _requestBattery();
  }

  // キューブの状態を要求
  Future<void> _requestFacelets() async {
    if (_ganService == null) return;
    
    final req = Uint8List.fromList([
      0xDD, // コマンドヘッダー
      0x04, // データ長
      0x00, // 予約
      0xED, // コマンドタイプ（キューブの状態要求）
    ]);
    await _bluetoothService.writeCharacteristic(
      _ganService!,
      GAN_CHARACTERISTIC_RX,
      req,
    );
  }

  // バッテリー状態を要求
  Future<void> _requestBattery() async {
    if (_ganService == null) return;
    
    final req = Uint8List.fromList([
      0xDD, // コマンドヘッダー
      0x04, // データ長
      0x00, // 予約
      0xEF, // コマンドタイプ（バッテリー状態要求）
    ]);
    await _bluetoothService.writeCharacteristic(
      _ganService!,
      GAN_CHARACTERISTIC_RX,
      req,
    );
  }

  // V4移動データを処理
  void _processMovementDataV4(String binaryData) {
    try {
      final power = int.parse(binaryData.substring(64, 66), radix: 2);
      final encodedAxis = int.parse(binaryData.substring(66, 72), radix: 2);
      
      // 軸のマッピング [2, 32, 8, 1, 16, 4] -> [U, R, F, D, L, B]
      final axisMap = [2, 32, 8, 1, 16, 4];
      final axis = axisMap.indexOf(encodedAxis);
      
      if (axis == -1) {
        debugPrint('無効な軸データ: 0x${encodedAxis.toRadixString(16)}');
        return;
      }

      // パワーに基づいて回転方向を決定
      // 0: 時計回り（標準）
      // 1: 反時計回り
      // 2: 180度回転
      MoveType? moveType;
      switch (axis) {
        case 0: // U
          moveType = power == 0 ? MoveType.U : (power == 1 ? MoveType.UPrime : MoveType.U2);
          break;
        case 1: // R
          moveType = power == 0 ? MoveType.R : (power == 1 ? MoveType.RPrime : MoveType.R2);
          break;
        case 2: // F
          moveType = power == 0 ? MoveType.F : (power == 1 ? MoveType.FPrime : MoveType.F2);
          break;
        case 3: // D
          moveType = power == 0 ? MoveType.D : (power == 1 ? MoveType.DPrime : MoveType.D2);
          break;
        case 4: // L
          moveType = power == 0 ? MoveType.L : (power == 1 ? MoveType.LPrime : MoveType.L2);
          break;
        case 5: // B
          moveType = power == 0 ? MoveType.B : (power == 1 ? MoveType.BPrime : MoveType.B2);
          break;
      }

      if (moveType != null) {
        debugPrint('移動検出: ${moveType.toString()}');
        _processMove(moveType);
      }
    } catch (e) {
      debugPrint('移動データ処理エラー: $e');
    }
  }

  // V4キューブ状態データを処理
  void _processCubeStateDataV4(String binaryData) {
    try {
      // コーナーの位置と向きを解析
      var cchk = 0xf00;
      final corners = List<int>.filled(8, 0);
      final edges = List<int>.filled(12, 0);
      
      // コーナーの処理
      for (var i = 0; i < 7; i++) {
        final perm = int.parse(binaryData.substring(32 + i * 3, 35 + i * 3), radix: 2);
        final ori = int.parse(binaryData.substring(53 + i * 2, 55 + i * 2), radix: 2);
        cchk -= ori << 3;
        cchk ^= perm;
        corners[i] = (ori << 3) | perm;
      }
      
      // パリティチェックに基づいて最後のコーナーを計算
      corners[7] = (cchk & 0xff8) % 24 | (cchk & 0x7);

      // エッジの処理
      var echk = 0xf00;
      for (var i = 0; i < 11; i++) {
        final perm = int.parse(binaryData.substring(i * 4, (i + 1) * 4), radix: 2);
        final ori = (perm & 0x8) >> 3;
        echk -= ori << 3;
        echk ^= perm & 0x7;
        edges[i] = (ori << 3) | (perm & 0x7);
      }
      
      // パリティチェックに基づいて最後のエッジを計算
      edges[11] = (echk & 0xff8) % 24 | (echk & 0x7);

      // キューブの状態を更新
      _currentCubeState = _createStateFromPieces(corners, edges);
      notifyListeners();
      debugPrint('キューブの状態を更新: $_currentCubeState');

    } catch (e) {
      debugPrint('キューブ状態データ処理エラー: $e');
    }
  }

  // コーナーとエッジのデータからキューブの状態を作成
  CubeState _createStateFromPieces(List<int> corners, List<int> edges) {
    // 面の色を初期化
    final faces = {
      Face.front: List.generate(3, (_) => List.filled(3, Color.red)),
      Face.back: List.generate(3, (_) => List.filled(3, Color.orange)),
      Face.up: List.generate(3, (_) => List.filled(3, Color.white)),
      Face.down: List.generate(3, (_) => List.filled(3, Color.yellow)),
      Face.left: List.generate(3, (_) => List.filled(3, Color.green)),
      Face.right: List.generate(3, (_) => List.filled(3, Color.blue)),
    };

    // コーナーの色を更新
    for (var i = 0; i < corners.length; i++) {
      final corner = corners[i];
      final position = corner & 0x7;
      final orientation = corner >> 3 & 0x3;
      _updateCornerColors(faces, position, orientation);
    }

    // エッジの色を更新
    for (var i = 0; i < edges.length; i++) {
      final edge = edges[i];
      final position = edge & 0x7;
      final orientation = edge >> 3 & 0x1;
      _updateEdgeColors(faces, position, orientation);
    }

    return CubeState(faces: faces);
  }

  void _updateEdgeColors(Map<Face, List<List<Color>>> faces, int position, int orientation) {
    // エッジの位置に応じたステッカーの色を定義
    final edgeDefinitions = [
      // UF (白赤)
      [
        Sticker(Face.up, 2, 1),    // 白
        Sticker(Face.front, 0, 1), // 赤
      ],
      // UR (白青)
      [
        Sticker(Face.up, 1, 2),    // 白
        Sticker(Face.right, 0, 1), // 青
      ],
      // UB (白橙)
      [
        Sticker(Face.up, 0, 1),    // 白
        Sticker(Face.back, 0, 1),  // 橙
      ],
      // UL (白緑)
      [
        Sticker(Face.up, 1, 0),    // 白
        Sticker(Face.left, 0, 1),  // 緑
      ],
      // DF (黄赤)
      [
        Sticker(Face.down, 0, 1),  // 黄
        Sticker(Face.front, 2, 1), // 赤
      ],
      // DR (黄青)
      [
        Sticker(Face.down, 1, 2),  // 黄
        Sticker(Face.right, 2, 1), // 青
      ],
      // DB (黄橙)
      [
        Sticker(Face.down, 2, 1),  // 黄
        Sticker(Face.back, 2, 1),  // 橙
      ],
      // DL (黄緑)
      [
        Sticker(Face.down, 1, 0),  // 黄
        Sticker(Face.left, 2, 1),  // 緑
      ],
      // FR (赤青)
      [
        Sticker(Face.front, 1, 2), // 赤
        Sticker(Face.right, 1, 0), // 青
      ],
      // FL (赤緑)
      [
        Sticker(Face.front, 1, 0), // 赤
        Sticker(Face.left, 1, 2),  // 緑
      ],
      // BR (橙青)
      [
        Sticker(Face.back, 1, 0),  // 橙
        Sticker(Face.right, 1, 2), // 青
      ],
      // BL (橙緑)
      [
        Sticker(Face.back, 1, 2),  // 橙
        Sticker(Face.left, 1, 0),  // 緑
      ],
    ];

    // この位置のエッジ定義を取得
    final edgeDef = edgeDefinitions[position];
    
    // 各ステッカーの色を向きに応じて更新
    for (var i = 0; i < 2; i++) {
      final colorIndex = (i + orientation) % 2;
      final sticker = edgeDef[i];
      final colorSticker = edgeDef[colorIndex];
      final color = _getColorForFace(colorSticker.face);
      faces[sticker.face]![sticker.row][sticker.col] = color;
    }
  }

  // コーナーデータからキューブの状態を作成
  CubeState _createStateFromCorners(List<int> corners) {
    // コーナーの配置を基にキューブの状態を作成
    // corners: 各要素は(向き << 3 | 位置)のフォーマット

    // 面の色を初期化
    final faces = {
      Face.front: List.generate(3, (_) => List.filled(3, Color.red)),
      Face.back: List.generate(3, (_) => List.filled(3, Color.orange)),
      Face.up: List.generate(3, (_) => List.filled(3, Color.white)),
      Face.down: List.generate(3, (_) => List.filled(3, Color.yellow)),
      Face.left: List.generate(3, (_) => List.filled(3, Color.green)),
      Face.right: List.generate(3, (_) => List.filled(3, Color.blue)),
    };

    // コーナーの位置と向きに基づいて色を更新
    for (var i = 0; i < corners.length; i++) {
      final corner = corners[i];
      final position = corner & 0x7;        // 下位3ビットが位置
      final orientation = corner >> 3 & 0x3; // 次の2ビットが向き

      // コーナーの3つのステッカーの色を更新
      _updateCornerColors(faces, position, orientation);
    }

    return CubeState(faces: faces);
  }

  void _updateCornerColors(Map<Face, List<List<Color>>> faces, int position, int orientation) {
    // コーナーの位置に応じたステッカーの色を定義
    final cornerDefinitions = [
      // ULF (白緑赤)
      [
        Sticker(Face.up, 2, 0),    // 白
        Sticker(Face.left, 0, 2),  // 緑
        Sticker(Face.front, 0, 0), // 赤
      ],
      // URF (白赤青)
      [
        Sticker(Face.up, 2, 2),    // 白
        Sticker(Face.right, 0, 0), // 青
        Sticker(Face.front, 0, 2), // 赤
      ],
      // ULB (白緑橙)
      [
        Sticker(Face.up, 0, 0),    // 白
        Sticker(Face.left, 0, 0),  // 緑
        Sticker(Face.back, 0, 2),  // 橙
      ],
      // URB (白青橙)
      [
        Sticker(Face.up, 0, 2),    // 白
        Sticker(Face.right, 0, 2), // 青
        Sticker(Face.back, 0, 0),  // 橙
      ],
      // DLF (黄緑赤)
      [
        Sticker(Face.down, 0, 0),  // 黄
        Sticker(Face.left, 2, 2),  // 緑
        Sticker(Face.front, 2, 0), // 赤
      ],
      // DRF (黄赤青)
      [
        Sticker(Face.down, 0, 2),  // 黄
        Sticker(Face.right, 2, 0), // 青
        Sticker(Face.front, 2, 2), // 赤
      ],
      // DLB (黄緑橙)
      [
        Sticker(Face.down, 2, 0),  // 黄
        Sticker(Face.left, 2, 0),  // 緑
        Sticker(Face.back, 2, 2),  // 橙
      ],
      // DRB (黄青橙)
      [
        Sticker(Face.down, 2, 2),  // 黄
        Sticker(Face.right, 2, 2), // 青
        Sticker(Face.back, 2, 0),  // 橙
      ],
    ];

    // この位置のコーナー定義を取得
    final cornerDef = cornerDefinitions[position];
    
    // 各ステッカーの色を向きに応じて更新
    for (var i = 0; i < 3; i++) {
      final colorIndex = (i + orientation) % 3;
      final sticker = cornerDef[i];
      final colorSticker = cornerDef[colorIndex];
      final color = _getColorForFace(colorSticker.face);
      faces[sticker.face]![sticker.row][sticker.col] = color;
    }
  }

  void _processMove(MoveType moveType) {
    final move = Move(
      type: moveType,
      timestamp: DateTime.now(),
    );
    
    _moveHistory.add(move);
    
    final newState = _currentCubeState.copy();
    CubeStateUpdater.updateState(newState, moveType);
    _currentCubeState = newState;
    
    debugPrint('現在の状態: $_currentCubeState');
    debugPrint('移動履歴: ${_moveHistory.map((m) => m.type).join(', ')}');
    
    if (_solveStartTime == null && _moveHistory.length == 1) {
      _solveStartTime = DateTime.now();
      debugPrint('ソルブ開始: $_solveStartTime');
    } else if (_currentCubeState.isSolved() && _solveStartTime != null && _solveEndTime == null) {
      _solveEndTime = DateTime.now();
      debugPrint('ソルブ完了: $_solveEndTime');
    }
    
    notifyListeners();
  }

  Color _getColorForFace(Face face) {
    switch (face) {
      case Face.front: return Color.red;
      case Face.back: return Color.orange;
      case Face.up: return Color.white;
      case Face.down: return Color.yellow;
      case Face.left: return Color.green;
      case Face.right: return Color.blue;
    }
  }

  void _processBatteryStatusDataV4(List<int> data) {
    if (data.length < 5) return;
    
    try {
      // バッテリー値は5バイト目に格納されている
      _batteryLevel = data[4];
      debugPrint('バッテリーレベル更新: $_batteryLevel%');
      notifyListeners();
    } catch (e) {
      debugPrint('バッテリー状態データ処理エラー: $e');
    }
  }

  // 解き始めをリセット
  void resetSolve() {
    _solveStartTime = null;
    _solveEndTime = null;
    _moveHistory.clear();
    _currentCubeState = CubeState.solved();
    notifyListeners();
  }

  // キューブをランダムにスクランブル
  Future<List<Move>> scrambleCube(int moveCount) async {
    final possibleMoves = [
      MoveType.F, MoveType.FPrime, MoveType.F2,
      MoveType.B, MoveType.BPrime, MoveType.B2,
      MoveType.U, MoveType.UPrime, MoveType.U2,
      MoveType.D, MoveType.DPrime, MoveType.D2,
      MoveType.L, MoveType.LPrime, MoveType.L2,
      MoveType.R, MoveType.RPrime, MoveType.R2,
    ];

    final random = Random();
    final scrambleMoves = <Move>[];
    MoveType? lastMove;
    MoveType? secondLastMove;
    
    for (int i = 0; i < moveCount; i++) {
      MoveType move;
      
      do {
        move = possibleMoves[random.nextInt(possibleMoves.length)];
        
        if (lastMove != null) {
          final lastFace = CubeStateUpdater.getFaceFromMoveType(lastMove);
          final currentFace = CubeStateUpdater.getFaceFromMoveType(move);
          
          if (lastFace == currentFace) continue;
          
          if (secondLastMove != null) {
            final secondLastFace = CubeStateUpdater.getFaceFromMoveType(secondLastMove);
            if (lastFace == CubeStateUpdater.getOppositeFace(currentFace) && 
                secondLastFace == currentFace) {
              continue;
            }
          }
        }
        
        break;
      } while (true);
      
      final timestamp = DateTime.now().add(Duration(milliseconds: i * 100));
      final scrambleMove = Move(type: move, timestamp: timestamp);
      
      scrambleMoves.add(scrambleMove);
      
      final newState = _currentCubeState.copy();
      CubeStateUpdater.updateState(newState, move);
      _currentCubeState = newState;
      
      secondLastMove = lastMove;
      lastMove = move;
    }
    
    _moveHistory.clear();
    _solveStartTime = null;
    _solveEndTime = null;
    
    notifyListeners();
    return scrambleMoves;
  }

  @override
  void dispose() {
    _cubeDataSubscription?.cancel();
    super.dispose();
  }
}

// Stickerクラスを追加
class Sticker {
  final Face face;
  final int row;
  final int col;

  const Sticker(this.face, this.row, this.col);
}