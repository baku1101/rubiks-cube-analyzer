import 'dart:typed_data';

/// GAN Cubeの通信プロトコルで使用されるAES-128暗号化の実装
class GanAes128 {
  /// Substitution Box (S-box)
  static final List<int> sBox = [
    0x63, 0x7c, 0x77, 0x7b, 0xf2, 0x6b, 0x6f, 0xc5, 0x30, 0x01, 0x67, 0x2b,
    0xfe, 0xd7, 0xab, 0x76, 0xca, 0x82, 0xc9, 0x7d, 0xfa, 0x59, 0x47, 0xf0,
    0xad, 0xd4, 0xa2, 0xaf, 0x9c, 0xa4, 0x72, 0xc0, 0xb7, 0xfd, 0x93, 0x26,
    0x36, 0x3f, 0xf7, 0xcc, 0x34, 0xa5, 0xe5, 0xf1, 0x71, 0xd8, 0x31, 0x15,
    0x04, 0xc7, 0x23, 0xc3, 0x18, 0x96, 0x05, 0x9a, 0x07, 0x12, 0x80, 0xe2,
    0xeb, 0x27, 0xb2, 0x75, 0x09, 0x83, 0x2c, 0x1a, 0x1b, 0x6e, 0x5a, 0xa0,
    0x52, 0x3b, 0xd6, 0xb3, 0x29, 0xe3, 0x2f, 0x84, 0x53, 0xd1, 0x00, 0xed,
    0x20, 0xfc, 0xb1, 0x5b, 0x6a, 0xcb, 0xbe, 0x39, 0x4a, 0x4c, 0x58, 0xcf,
    0xd0, 0xef, 0xaa, 0xfb, 0x43, 0x4d, 0x33, 0x85, 0x45, 0xf9, 0x02, 0x7f,
    0x50, 0x3c, 0x9f, 0xa8, 0x51, 0xa3, 0x40, 0x8f, 0x92, 0x9d, 0x38, 0xf5,
    0xbc, 0xb6, 0xda, 0x21, 0x10, 0xff, 0xf3, 0xd2, 0xcd, 0x0c, 0x13, 0xec,
    0x5f, 0x97, 0x44, 0x17, 0xc4, 0xa7, 0x7e, 0x3d, 0x64, 0x5d, 0x19, 0x73,
    0x60, 0x81, 0x4f, 0xdc, 0x22, 0x2a, 0x90, 0x88, 0x46, 0xee, 0xb8, 0x14,
    0xde, 0x5e, 0x0b, 0xdb, 0xe0, 0x32, 0x3a, 0x0a, 0x49, 0x06, 0x24, 0x5c,
    0xc2, 0xd3, 0xac, 0x62, 0x91, 0x95, 0xe4, 0x79, 0xe7, 0xc8, 0x37, 0x6d,
    0x8d, 0xd5, 0x4e, 0xa9, 0x6c, 0x56, 0xf4, 0xea, 0x65, 0x7a, 0xae, 0x08,
    0xba, 0x78, 0x25, 0x2e, 0x1c, 0xa6, 0xb4, 0xc6, 0xe8, 0xdd, 0x74, 0x1f,
    0x4b, 0xbd, 0x8b, 0x8a, 0x70, 0x3e, 0xb5, 0x66, 0x48, 0x03, 0xf6, 0x0e,
    0x61, 0x35, 0x57, 0xb9, 0x86, 0xc1, 0x1d, 0x9e, 0xe1, 0xf8, 0x98, 0x11,
    0x69, 0xd9, 0x8e, 0x94, 0x9b, 0x1e, 0x87, 0xe9, 0xce, 0x55, 0x28, 0xdf,
    0x8c, 0xa1, 0x89, 0x0d, 0xbf, 0xe6, 0x42, 0x68, 0x41, 0x99, 0x2d, 0x0f,
    0xb0, 0x54, 0xbb, 0x16
  ];

  /// Inverse S-box
  static final List<int> sBoxInv = List<int>.filled(256, 0);

  /// シフトテーブル (逆順)
  static const List<int> shiftTabInv = [0, 13, 10, 7, 4, 1, 14, 11, 8, 5, 2, 15, 12, 9, 6, 3];

  /// xtime テーブル
  static final List<int> xtime = List<int>.filled(256, 0);

  /// 拡張鍵
  late final List<int> key;

  /// IV (初期化ベクトル)
  List<int>? iv;

  /// 初期化フラグ
  static bool _initialized = false;

  /// 初期化処理
  static void _initialize() {
    if (_initialized) return;

    // 逆S-boxを構築
    for (var i = 0; i < 256; i++) {
      sBoxInv[sBox[i]] = i;
    }

    // xtimeテーブルを構築
    for (var i = 0; i < 128; i++) {
      xtime[i] = i << 1;
      xtime[128 + i] = (i << 1) ^ 0x1b;
    }

    _initialized = true;
  }

  /// コンストラクタ - 16バイトの鍵を受け取る
  GanAes128(List<int> keyBytes) {
    _initialize();
    
    // 鍵拡張処理
    key = List<int>.from(keyBytes);
    var rcon = 1;
    
    for (var i = 16; i < 176; i += 4) {
      var tmp = key.sublist(i - 4, i);
      if (i % 16 == 0) {
        // RotWord + SubBytes + Rcon
        tmp = [
          sBox[tmp[1]] ^ rcon,
          sBox[tmp[2]],
          sBox[tmp[3]],
          sBox[tmp[0]]
        ];
        rcon = xtime[rcon];
      }
      
      for (var j = 0; j < 4; j++) {
        key.add(key[i - 16 + j] ^ tmp[j]);
      }
    }
  }

  /// RoundKeyの追加
  void _addRoundKey(List<int> state, List<int> roundKey) {
    for (var i = 0; i < 16; i++) {
      state[i] ^= roundKey[i];
    }
  }

  /// 逆ShiftRowsとSubBytes、AddRoundKey操作
  void _shiftSubAdd(List<int> state, List<int> roundKey) {
    final stateCopy = List<int>.from(state);
    for (var i = 0; i < 16; i++) {
      state[i] = sBoxInv[stateCopy[shiftTabInv[i]]] ^ roundKey[i];
    }
  }

  /// ShiftRows、SubBytes、AddRoundKey操作
  void _shiftSubAddI(List<int> state, List<int> roundKey) {
    final stateCopy = List<int>.from(state);
    for (var i = 0; i < 16; i++) {
      state[shiftTabInv[i]] = sBox[stateCopy[i] ^ roundKey[i]];
    }
  }

  /// MixColumns操作
  void _mixColumns(List<int> state) {
    for (var i = 0; i < 16; i += 4) {
      final s0 = state[i + 0];
      final s1 = state[i + 1];
      final s2 = state[i + 2];
      final s3 = state[i + 3];
      final h = s0 ^ s1 ^ s2 ^ s3;
      
      state[i + 0] ^= h ^ xtime[s0 ^ s1];
      state[i + 1] ^= h ^ xtime[s1 ^ s2];
      state[i + 2] ^= h ^ xtime[s2 ^ s3];
      state[i + 3] ^= h ^ xtime[s3 ^ s0];
    }
  }

  /// 逆MixColumns操作
  void _mixColumnsInv(List<int> state) {
    for (var i = 0; i < 16; i += 4) {
      final s0 = state[i + 0];
      final s1 = state[i + 1];
      final s2 = state[i + 2];
      final s3 = state[i + 3];
      final h = s0 ^ s1 ^ s2 ^ s3;
      final xh = xtime[h];
      
      final h1 = xtime[xtime[xh ^ s0 ^ s2]] ^ h;
      final h2 = xtime[xtime[xh ^ s1 ^ s3]] ^ h;
      
      state[i + 0] ^= h1 ^ xtime[s0 ^ s1];
      state[i + 1] ^= h2 ^ xtime[s1 ^ s2];
      state[i + 2] ^= h1 ^ xtime[s2 ^ s3];
      state[i + 3] ^= h2 ^ xtime[s3 ^ s0];
    }
  }

  /// ブロックを復号する
  List<int> decryptBytes(Uint8List block) {
    final result = List<int>.from(block);
    
    // 最終ラウンドキーを適用
    _addRoundKey(result, key.sublist(160, 176));
    
    // メインラウンド
    for (var i = 144; i >= 16; i -= 16) {
      _shiftSubAdd(result, key.sublist(i, i + 16));
      _mixColumnsInv(result);
    }
    
    // 初期ラウンド
    _shiftSubAdd(result, key.sublist(0, 16));
    
    return result;
  }

  /// ブロックを暗号化する
  List<int> encryptBytes(Uint8List block) {
    final result = List<int>.from(block);
    
    // 初期ラウンド
    _shiftSubAddI(result, key.sublist(0, 16));
    
    // メインラウンド
    for (var i = 16; i < 160; i += 16) {
      _mixColumns(result);
      _shiftSubAddI(result, key.sublist(i, i + 16));
    }
    
    // 最終ラウンドキーを適用
    _addRoundKey(result, key.sublist(160, 176));
    
    return result;
  }

  /// GANキューブ形式でのデータ暗号化
  Uint8List encrypt(List<int> data) {
    if (data.isEmpty) return Uint8List.fromList(data);
    
    final result = Uint8List.fromList(data);
    final ivData = iv ?? [];
    
    // 最初の16バイトにXOR適用
    for (var i = 0; i < 16 && i < result.length; i++) {
      result[i] ^= (i < ivData.length) ? ivData[i] : 0;
    }
    
    // AES暗号化
    encryptBytes(result);
    
    // データ長が16バイトを超える場合の特殊処理
    if (result.length > 16) {
      final offset = result.length - 16;
      final block = Uint8List.fromList(result.sublist(offset));
      
      // 末尾ブロックにXOR適用
      for (var i = 0; i < 16; i++) {
        block[i] ^= (i < ivData.length) ? ivData[i] : 0;
      }
      
      // 末尾ブロックを暗号化
      final encryptedBlock = encryptBytes(block);
      
      // 結果を元のデータに戻す
      for (var i = 0; i < 16; i++) {
        result[i + offset] = encryptedBlock[i];
      }
    }
    
    return result;
  }

  /// GANキューブ形式でのデータ復号
  Uint8List decrypt(List<int> data) {
    if (data.isEmpty) return Uint8List.fromList(data);
    
    // データをUint8Listに変換
    final result = Uint8List.fromList(data);
    final ivData = iv ?? [];
    
    // データ長が16バイトを超える場合の特殊処理
    if (result.length > 16) {
      final offset = result.length - 16;
      final block = decryptBytes(Uint8List.fromList(result.sublist(offset)));
      
      for (var i = 0; i < 16; i++) {
        result[i + offset] = block[i] ^ ((i < ivData.length) ? ivData[i] : 0);
      }
    }
    
    // 全体を復号
    final decrypted = decryptBytes(result);
    
    // 最初の16バイトにXOR適用
    for (var i = 0; i < 16 && i < decrypted.length; i++) {
      decrypted[i] = decrypted[i] ^ ((i < ivData.length) ? ivData[i] : 0);
    }
    
    return Uint8List.fromList(decrypted);
  }
}