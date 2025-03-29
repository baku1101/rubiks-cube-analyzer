# ファイル構造の新しい設計

## 1. プロジェクトのレイヤー構造

```
lib/
├── models/                  # データモデル
│   ├── bluetooth/          # Bluetooth関連のモデル
│   │   ├── device.dart     # デバイス情報
│   │   └── service.dart    # サービス情報
│   └── cube/              # キューブ関連のモデル
│       ├── state.dart     # キューブの状態
│       ├── move.dart      # 移動情報
│       └── solve.dart     # ソルブ情報
│
├── services/               # ビジネスロジック
│   ├── bluetooth/         # Bluetooth基盤
│   │   ├── interface/     # プラットフォーム非依存のインターフェース
│   │   │   ├── device.dart
│   │   │   └── service.dart
│   │   ├── web/          # Web実装
│   │   │   └── service.dart
│   │   └── windows/      # Windows実装
│   │       └── service.dart
│   │
│   └── cube/            # キューブ制御
│       ├── gan/         # GANキューブ固有の実装
│       │   ├── protocol/   # プロトコル実装
│       │   │   ├── command.dart
│       │   │   ├── response.dart
│       │   │   └── parser.dart
│       │   └── crypto/     # 暗号化処理
│       │       ├── aes.dart
│       │       └── utils.dart
│       └── core/        # 共通機能
│           ├── state_manager.dart
│           └── move_tracker.dart
│
├── ui/                  # UI層
│   ├── screens/        # 画面
│   └── widgets/        # 再利用可能なウィジェット
│
└── utils/              # ユーティリティ
    ├── bit_utils.dart  # ビット操作
    └── logger.dart     # ログ機能
```

## 2. 責務の分離

### 2.1 Bluetoothレイヤー
- プラットフォーム固有の実装を分離
- 共通インターフェースの提供
- デバイス探索と接続管理

### 2.2 キューブレイヤー
- プロトコル実装の分離
- 暗号化処理の分離
- 状態管理と移動追跡

### 2.3 UIレイヤー
- プレゼンテーションロジックの分離
- 再利用可能なウィジェットの整理

## 3. インターフェース設計

### 3.1 Bluetoothインターフェース
```dart
// lib/services/bluetooth/interface/service.dart
abstract class BluetoothService {
  Stream<List<int>> get dataStream;
  Stream<List<BluetoothDevice>> scanDevices(); // 追加
  Future<void> connect(BluetoothDevice device);
  Future<void> disconnect();
  Future<void> writeData(List<int> data);
}
```

### 3.2 キューブインターフェース
```dart
// lib/services/cube/interface.dart
abstract class CubeService {
  Stream<CubeState> get stateStream;
  Future<void> connect();
  Future<void> disconnect();
  Future<void> requestState();
}
```

## 4. データフロー

```
Bluetooth層
   ↑↓
プロトコル層
   ↑↓
状態管理層
   ↑↓
UI層
```

## 5. テスト構造

```
test/
├── services/
│   ├── bluetooth/      # Bluetoothテスト
│   └── cube/          # キューブテスト
├── models/            # モデルテスト
└── ui/               # UIテスト
```

## 6. 実装優先順位

1. Bluetoothインターフェースの整理
2. GANプロトコルの移行
3. 状態管理の実装
4. UI層の調整

## 7. マイグレーション計画

### Phase 1: インターフェースの整理
1. 新しいディレクトリ構造の作成
2. 基本インターフェースの移行
3. 既存コードの段階的な移行

### Phase 2: 実装の移行
1. Bluetooth実装の移行
2. プロトコル実装の移行
3. 状態管理の移行

### Phase 3: テストの再構築
1. テストディレクトリの整理
2. テストケースの移行
3. 新規テストの追加