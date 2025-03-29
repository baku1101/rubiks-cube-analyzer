# GAN UIキューブ V4プロトコル実装計画 (更新版)

## 1. 前提条件と実装方針

### 1.1 実装の優先順位
1. Bluetooth基盤の実装 (インターフェース、Windows実装)
2. 暗号化/復号化処理の実装と検証 (`aes.dart`)
3. コマンド生成の実装 (`command.dart`)
4. レスポンスデータ構造の定義とパーサーの実装 (`response.dart`)
5. プロトコルハンドラの実装 (新規)
6. キューブ状態管理の実装 (将来)
7. エラー処理とリカバリーの実装 (将来)
8. デバッグUIの実装

### 1.2 コアコンポーネント (現状の実装に基づく)
```
lib/
  services/
    bluetooth/
      interface/
        device.dart         # Bluetoothデバイス情報
        service.dart        # Bluetoothサービスインターフェース
      windows/
        service.dart        # Windows向けBluetoothサービス実装
    gan/
      protocol/
        command.dart        # コマンド生成 (CommandBuilder)
        response.dart       # レスポンス定義と解析 (ResponseData派生, ResponseParser)
        README.md           # V4プロトコル仕様書
      crypto/
        aes.dart            # AES暗号化/復号化、キー生成 (AESCipher, KeyGenerator, KeyData)
      # state/ (将来実装)
      #   cube_state.dart
      #   move_tracker.dart
      #   error_handler.dart
      # protocol/handler.dart (将来実装: プロトコルハンドラ)
  ui/
    debug/ # デバッグUI (将来実装)
      # debug_screen.dart
      # connection_view.dart
      # data_view.dart
      # cube_state_view.dart
```

## 2. 実装フェーズ (FINAL_IMPLEMENTATION_PLANに基づく)

### Phase 1: コア機能実装
1.  **Bluetooth基盤実装**
    *   [x] インターフェース定義 (`device.dart`, `service.dart`)
    *   [x] Windows実装 (`windows/service.dart`) - ※UUID等は要設定
2.  **暗号化処理実装**
    *   [x] AES暗号化/復号化 (`AESCipher`)
    *   [x] キー生成処理 (`KeyGenerator`, `KeyData`)
3.  **プロトコル実装 (一部)**
    *   [x] コマンド生成 (`CommandBuilder`)
    *   [x] レスポンス定義と解析 (`ResponseData`派生, `ResponseParser`)
4.  **キューブ状態管理実装** (将来)

### Phase 2: デバッグ機能実装 (将来)
1.  デバイス検出・接続UI
2.  データ送受信表示
3.  キューブ状態表示

## 3. コードスニペット例 (現状の実装に基づく)

### 3.1 暗号化/キー生成 (`aes.dart`)
```dart
// AESCipher クラス
class AESCipher {
  // ... (実装済み)
}

// KeyGenerator クラス
class KeyGenerator {
  static KeyData generateFromMAC(List<int> macAddress) {
    // ... (実装済み、V4仕様に基づく)
  }
}

// KeyData クラス
class KeyData {
  // ... (実装済み)
}
```

### 3.2 コマンド生成 (`command.dart`)
```dart
// CommandBuilder クラス
class CommandBuilder {
  static List<int> createStateRequest() { /* ... 実装済み ... */ }
  static List<int> createBatteryRequest() { /* ... 実装済み ... */ }
  static List<int> createHardwareInfoRequest() { /* ... 実装済み ... */ }
  static List<int> createMoveHistoryRequest(int startCounter, int count) { /* ... 実装済み ... */ }
}
```

### 3.3 レスポンス解析 (`response.dart`)
```dart
// ResponseData 抽象クラスと派生クラス (MoveEvent, CubeStateData, etc.)
// ... (実装済み)

// ResponseParser クラス
class ResponseParser {
  ResponseData parse(Uint8List data) { /* ... 実装済み ... */ }
  int _extractBits(Uint8List data, int startBit, int length) { /* ... 実装済み ... */ }
  // 各モードの解析メソッド (_parseMoveEvent, _parseCubeState, etc.)
  // ... (実装済み)
}
```

### 3.4 プロトコルハンドラ (将来実装例)
```dart
// lib/services/gan/protocol/handler.dart (新規作成想定)
class GanProtocolHandler {
  final BluetoothService _bluetoothService;
  final AESCipher _cipher;
  final ResponseParser _parser = ResponseParser();
  // ... (StreamController, コンストラクタ, _handleRawData, sendCommand など)
}
```

## 4. テスト計画 (更新)

### 4.1 暗号化テスト (`test/services/gan/crypto/aes_test.dart`)
```dart
test('should correctly encrypt and decrypt data', () {
  // ... (実装例は前のdiff参照、要実行)
});
test('should generate correct key and iv from MAC', () {
  // ... (KeyGeneratorのテスト、要実装・実行)
});
```

### 4.2 コマンド生成テスト (`test/services/gan/protocol/command_test.dart`)
```dart
test('should create correct state request command', () {
  // ... (CommandBuilderのテスト、要実装・実行)
});
// 他のコマンドも同様にテスト
```

### 4.3 パーサーテスト (`test/services/gan/protocol/response_parser_test.dart`)
```dart
test('should parse move event correctly', () {
  // V4仕様に基づくモックデータを使用
  // ... (実装例は前のdiff参照、要実装・実行)
});
// 他のレスポンスモードも同様にテスト
```

## 5. マイルストーン (更新)

### 実施済み
- Bluetoothインターフェース定義
- Windows Bluetooth実装 (基本骨格)
- AES暗号化/復号化実装
- キー生成実装
- コマンド生成実装
- レスポンス定義とパーサー実装

### 次のステップ
- Bluetooth実装のUUID設定と動作確認
- 暗号化テストの実装・実行
- コマンド生成テストの実装・実行
- パーサーテストの実装・実行
- プロトコルハンドラの実装
- デバッグUIの実装
- キューブ状態管理、ムーブトラッカー、エラーハンドラの実装 (Phase 1完了後)