# スマートキューブアプリ アーキテクチャ設計書

## 1. システム概要

現在のアプリケーションは以下の主要コンポーネントで構成されています：

### 1.1 コア機能層
- **Bluetooth通信基盤**
  - BluetoothInterface: デバイス通信の抽象化
  - プラットフォーム別実装（Windows/Web）
  - GAN UIキューブプロトコル対応

- **キューブ状態管理**
  - CubeState: キューブの完全な状態表現
  - 移動検出と履歴管理
  - パリティチェックシステム

- **プロトコル処理**
  - GANプロトコルの実装
  - バッテリー情報管理
  - ハードウェア情報処理

### 1.2 UI層
- **画面構成**
  - ホーム画面：接続管理、基本操作
  - 分析画面：ソルブ状態の可視化
  - 設定画面：環境設定

## 2. 新規要件との統合計画

### 2.1 解析機能の拡張（第1フェーズ）

#### 実装予定の機能
1. **詳細な解析エンジン**
   - TPSの計測と分析
   - ステップ別タイミング分析
   - 非効率パターンの検出

2. **解法別最適化**
   - APBメソッド対応
   - Epidoteメソッド対応
   - パターンデータベースの実装

#### 必要な新規コンポーネント
```dart
lib/
  services/
    solve_analyzer/
      analysis_engine.dart     // 解析コアエンジン
      method_analyzer/
        apb_analyzer.dart      // APB解法分析
        epidote_analyzer.dart  // Epidote解法分析
      pattern_detector.dart    // パターン検出
    
  models/
    analysis/
      solve_stats.dart        // ソルブ統計データ
      step_analysis.dart      // ステップ別分析
      pattern_match.dart      // パターンマッチング結果
```

### 2.2 トレーニングモード実装（第2フェーズ）

#### 実装予定の機能
1. **ステップ別練習**
   - F2L/OLL/PLL練習モード
   - APB/Epidoteステップ練習
   - パターン認識訓練

2. **ガイド機能**
   - 手順アニメーション
   - 指使いガイド
   - 進捗トラッキング

#### 必要な新規コンポーネント
```dart
lib/
  services/
    training/
      training_engine.dart     // トレーニング管理
      progress_tracker.dart    // 進捗追跡
      pattern_generator.dart   // 練習パターン生成
    
  models/
    training/
      exercise.dart           // 練習課題定義
      progress_data.dart      // 進捗データ
      training_config.dart    // トレーニング設定
```

### 2.3 データ管理システム（第3フェーズ）

#### 実装予定の機能
1. **永続化システム**
   - ソルブ履歴保存
   - 統計データ管理
   - 設定保存

2. **同期システム**
   - クラウドバックアップ
   - デバイス間同期
   - エクスポート/インポート

#### 必要な新規コンポーネント
```dart
lib/
  services/
    storage/
      solve_repository.dart    // ソルブデータ管理
      stats_repository.dart    // 統計データ管理
      sync_service.dart       // 同期処理
    
  models/
    storage/
      solve_record.dart       // ソルブ記録
      sync_state.dart         // 同期状態
      export_data.dart        // エクスポートデータ
```

## 3. テスト戦略

### 3.1 単体テスト
- 各コンポーネントの独立したテスト
- モック活用による依存性の分離
- エッジケースの網羅

### 3.2 統合テスト
- コンポーネント間の連携テスト
- E2Eテストの実装
- パフォーマンステスト

### 3.3 テストファイル構成
```dart
test/
  services/
    solve_analyzer/
      analysis_engine_test.dart
      method_analyzer/
        apb_analyzer_test.dart
        epidote_analyzer_test.dart
    training/
      training_engine_test.dart
      progress_tracker_test.dart
  models/
    analysis/
      solve_stats_test.dart
      step_analysis_test.dart
```

## 4. 実装スケジュール

### 4.1 第1フェーズ（1-2ヶ月）
- 解析エンジンの基本実装
- APB/Epidoteメソッド対応
- 基本的なパターン検出

### 4.2 第2フェーズ（2-3ヶ月）
- トレーニングモードの実装
- ガイド機能の実装
- 進捗トラッキングシステム

### 4.3 第3フェーズ（1-2ヶ月）
- データ永続化の実装
- 同期システムの構築
- エクスポート/インポート機能

## 5. 技術的考慮事項

### 5.1 パフォーマンス最適化
- 状態更新の効率化
- メモリ使用量の最適化
- レンダリング最適化

### 5.2 拡張性
- 新解法追加の容易さ
- UI/UXカスタマイズ性
- プラットフォーム依存の最小化

### 5.3 保守性
- コードの模듈化
- ドキュメント整備
- テストカバレッジの維持

## 6. リスク管理

### 6.1 技術的リスク
- Bluetooth接続の安定性
- クロスプラットフォーム互換性
- データ同期の整合性

### 6.2 対策
- エラーハンドリングの強化
- プラットフォームテストの充実
- バックアップ機能の実装