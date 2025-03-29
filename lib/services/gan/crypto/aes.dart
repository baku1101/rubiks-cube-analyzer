import 'dart:typed_data';
import 'package:meta/meta.dart';
import 'package:lzstring/lzstring.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'dart:convert';




/// AES-128暗号化/復号化処理を提供します。
/// GANキューブ特有の処理を含みます。
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

  /// シフトテーブル (逆順) - 旧実装に合わせて const を削除
  static final List<int> shiftTabInv = [0, 13, 10, 7, 4, 1, 14, 11, 8, 5, 2, 15, 12, 9, 6, 3];

  /// xtime テーブル
  static final List<int> xtime = List<int>.filled(256, 0);

  /// 拡張鍵 (176バイト)
  late final Uint8List _expandedKey;

  /// IV (初期化ベクトル) - GANキューブ特有
  final List<int> iv;

  /// 初期化フラグ
  static bool _initialized = false;

  /// 静的初期化処理
  static void _initialize() {
    if (_initialized) return;

    // 逆S-boxを構築
    for (var i = 0; i < 256; i++) {
      sBoxInv[sBox[i]] = i;
    }

    // xtimeテーブルを構築 (旧実装と同じロジック)
    for (var i = 0; i < 128; i++) {
      xtime[i] = i << 1;
      xtime[128 + i] = (i << 1) ^ 0x1b;
    }

    _initialized = true;
  }

  /// コンストラクタ - 16バイトの鍵と16バイトのIVを受け取る
  GanAes128(List<int> keyBytes, this.iv) {
    if (keyBytes.length != 16) {
      throw ArgumentError('Key must be 16 bytes long.');
    }
    if (iv.length != 16) {
      throw ArgumentError('IV must be 16 bytes long.');
    }
    _initialize();

    // 鍵拡張処理 (16バイト -> 176バイト) - 現在の実装を維持
    _expandedKey = Uint8List(176);
    _expandedKey.setRange(0, 16, keyBytes);

    var rcon = 1;
    for (var i = 16; i < 176; i += 4) {
      List<int> tmp = _expandedKey.sublist(i - 4, i);
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
        _expandedKey[i + j] = _expandedKey[i - 16 + j] ^ tmp[j];
      }
    }
  }

  // --- AESコア処理 (Uint8List を受け取り、Uint8List を返すように調整) ---

  /// RoundKeyの追加
  void _addRoundKey(Uint8List state, int round) {
    final offset = round * 16;
    for (var i = 0; i < 16; i++) {
      state[i] ^= _expandedKey[offset + i];
    }
  }

  /// SubBytes
  void _subBytes(Uint8List state) {
    for (var i = 0; i < 16; i++) {
      state[i] = sBox[state[i]];
    }
  }

  /// Inverse SubBytes
  void _invSubBytes(Uint8List state) {
    for (var i = 0; i < 16; i++) {
      state[i] = sBoxInv[state[i]];
    }
  }

  /// ShiftRows
  void _shiftRows(Uint8List state) {
    final tmp = Uint8List.fromList(state);
    state[1] = tmp[5]; state[2] = tmp[10]; state[3] = tmp[15];
    state[5] = tmp[9]; state[6] = tmp[14]; state[7] = tmp[3];
    state[9] = tmp[13]; state[10] = tmp[2]; state[11] = tmp[7];
    state[13] = tmp[1]; state[14] = tmp[6]; state[15] = tmp[11];
  }

  /// Inverse ShiftRows
  void _invShiftRows(Uint8List state) {
    final tmp = Uint8List.fromList(state);
    state[1] = tmp[13]; state[2] = tmp[10]; state[3] = tmp[7];
    state[5] = tmp[1]; state[6] = tmp[14]; state[7] = tmp[11];
    state[9] = tmp[5]; state[10] = tmp[2]; state[11] = tmp[15];
    state[13] = tmp[9]; state[14] = tmp[6]; state[15] = tmp[3];
  }

  /// MixColumns
  void _mixColumns(Uint8List state) {
    for (var i = 0; i < 16; i += 4) {
      var s0 = state[i + 0];
      var s1 = state[i + 1];
      var s2 = state[i + 2];
      var s3 = state[i + 3];
      var h = s0 ^ s1 ^ s2 ^ s3;
      state[i + 0] ^= h ^ xtime[s0 ^ s1];
      state[i + 1] ^= h ^ xtime[s1 ^ s2];
      state[i + 2] ^= h ^ xtime[s2 ^ s3];
      state[i + 3] ^= h ^ xtime[s3 ^ s0];
    }
  }

  /// Inverse MixColumns
  void _invMixColumns(Uint8List state) {
    for (var i = 0; i < 16; i += 4) {
      var s0 = state[i + 0];
      var s1 = state[i + 1];
      var s2 = state[i + 2];
      var s3 = state[i + 3];
      var h = s0 ^ s1 ^ s2 ^ s3;
      var xh = xtime[h];
      var h1 = xtime[xtime[xh ^ s0 ^ s2]] ^ h;
      var h2 = xtime[xtime[xh ^ s1 ^ s3]] ^ h;
      state[i + 0] ^= h1 ^ xtime[s0 ^ s1];
      state[i + 1] ^= h2 ^ xtime[s1 ^ s2];
      state[i + 2] ^= h1 ^ xtime[s2 ^ s3];
      state[i + 3] ^= h2 ^ xtime[s3 ^ s0];
    }
  }

  /// 16バイトのブロックを暗号化する (ECBモード相当)
  // @visibleForTesting // アンダースコアを削除するためコメントアウト
  Uint8List encryptBlock(Uint8List block) { // アンダースコアを削除
    if (block.length != 16) {
      // 16バイト未満の場合はパディングが必要だが、GANの実装ではそのまま処理している可能性
      // ここではエラーとせず、ブロックをコピーして処理する
      final paddedBlock = Uint8List(16);
      paddedBlock.setRange(0, block.length, block);
      block = paddedBlock;
      // throw ArgumentError('Block must be 16 bytes long for encryption.');
    }
    final state = Uint8List.fromList(block);

    _addRoundKey(state, 0); // Initial round key

    for (var round = 1; round < 10; round++) {
      _subBytes(state);
      _shiftRows(state);
      _mixColumns(state);
      _addRoundKey(state, round);
    }

    _subBytes(state);
    _shiftRows(state);
    _addRoundKey(state, 10); // Final round key

    return state;
  }
/// 16バイトのブロックを復号する (ECBモード相当)
// @visibleForTesting // アンダースコアを削除するためコメントアウト
Uint8List decryptBlock(Uint8List block) { // アンダースコアを削除
   if (block.length != 16) {
    // 16バイト未満の場合はエラーとするか、パディングを仮定するか
      // 16バイト未満の場合はエラーとするか、パディングを仮定するか
      // GANの実装に合わせて、ブロックをコピーして処理
       final paddedBlock = Uint8List(16);
       paddedBlock.setRange(0, block.length, block);
       block = paddedBlock;
      // throw ArgumentError('Block must be 16 bytes long for decryption.');
    }
    final state = Uint8List.fromList(block);

    _addRoundKey(state, 10); // Final round key (inverse order)

    for (var round = 9; round >= 1; round--) {
      _invShiftRows(state);
      _invSubBytes(state);
      _addRoundKey(state, round);
      _invMixColumns(state);
    }

    _invShiftRows(state);
    _invSubBytes(state);
    _addRoundKey(state, 0); // Initial round key

    return state;
  }

  // --- GANキューブ特有の暗号化/復号化処理 (旧実装のロジックを再現) ---

  /// GANキューブ形式でのデータ暗号化 (旧実装 gan_aes128.dart の encrypt を再現)
  Uint8List encrypt(List<int> data) {
    if (data.isEmpty) return Uint8List(0);

    final result = Uint8List.fromList(data);
    final dataLength = result.length;

    // 1. 先頭16バイトをIVとXOR
    final xorLength = dataLength < 16 ? dataLength : 16;
    for (var i = 0; i < xorLength; i++) {
      result[i] ^= iv[i];
    }

    // 2. データ全体をAES暗号化 (ECBモードで各ブロックを処理)
    //    旧実装の encryptBytes は List<int> を直接変更していた。
    //    ここでは _encryptBlock を使い、結果を result に書き戻す。
    final encryptedTemp = Uint8List(dataLength);
    for (int i = 0; i < dataLength; i += 16) {
      final end = (i + 16 <= dataLength) ? i + 16 : dataLength;
      // encryptBlock は16バイトを期待するため、必要ならパディングする
      final blockToEncrypt = Uint8List(16);
      blockToEncrypt.setRange(0, end - i, result.sublist(i, end));
      final encryptedBlock = encryptBlock(blockToEncrypt); // メソッド名を変更済み
      // 結果を一時バッファにコピー
      encryptedTemp.setRange(i, end, encryptedBlock.sublist(0, end - i));
    }
    // 一時バッファの内容を result にコピー
    result.setRange(0, dataLength, encryptedTemp);


    // 3. データ長が16バイトを超える場合、末尾16バイトに特殊処理
    if (dataLength > 16) {
      final offset = dataLength - 16;
      // 暗号化されたデータの末尾16バイトを取り出す
      final block = Uint8List.fromList(result.sublist(offset));

      // 末尾ブロックをIVとXOR
      for (var i = 0; i < 16; i++) {
        block[i] ^= iv[i];
      }

      // 再度暗号化
      final encryptedBlock = encryptBlock(block); // メソッド名を変更

      // 結果を元のデータに戻す
      result.setRange(offset, dataLength, encryptedBlock);
    }

    return result;
  }

  /// GANキューブ形式でのデータ復号 (旧実装 gan_aes128.dart の decrypt を再現)
  Uint8List decrypt(List<int> data) {
    if (data.isEmpty) return Uint8List(0);

    // データをUint8Listに変換して操作
    final result = Uint8List.fromList(data);
    final dataLength = result.length;

    // 1. データ長が16バイトを超える場合の特殊処理
    if (dataLength > 16) {
      final offset = dataLength - 16;
      // 末尾16バイトを復号
      final block = decryptBlock(result.sublist(offset)); // メソッド名を変更

      // IVとXORして元のデータ(result)に戻す
      for (var i = 0; i < 16; i++) {
        result[i + offset] = block[i] ^ iv[i];
      }
    }

    // 2. 全体を復号 (ECBモードで各ブロックを処理)
    //    旧実装や cstimer のように、result 配列を直接変更する。
    for (int i = 0; i < dataLength; i += 16) {
        final end = (i + 16 <= dataLength) ? i + 16 : dataLength;
        // decryptBlock は16バイトを期待するため、必要ならパディングする
        final blockToDecrypt = Uint8List(16);
        blockToDecrypt.setRange(0, end - i, result.sublist(i, end));
        final decryptedBlock = decryptBlock(blockToDecrypt); // メソッド名を変更
        // 復号結果を result 配列の該当箇所に直接書き戻す
        result.setRange(i, end, decryptedBlock.sublist(0, end - i));
    }

    // 3. 復号されたデータ(result)の先頭16バイトをIVとXOR
    final xorLength = dataLength < 16 ? dataLength : 16;
    for (var i = 0; i < xorLength; i++) {
      result[i] = result[i] ^ iv[i]; // result 配列を直接変更
    }

    return result; // 変更された result 配列を返す
  }
}

/// キーとIVのペアを保持します。
class KeyData {
  final List<int> key;
  final List<int> iv;

  KeyData({required this.key, required this.iv});
}

/// MACアドレスからAESキーとIVを生成します。
///
/// これはGANキューブ特有のキー生成アルゴリズムです。
/// 参考: https://github.com/cs0x7f/cstimer/blob/master/src/js/bluetooth/gancube.js#L70
class KeyGenerator {
  static KeyData generateFromMAC(String macAddress, {int ver = 0}) {
    // MACアドレスからバイトに変換
    final List<int> macBytes = [];
    for (int i = 0; i < 6; i++) {
      macBytes.add(int.parse(macAddress.substring(i * 3, i * 3 + 2), radix: 16));
    }

    const kKeys = [
      "NoRgnAHANATADDWJYwMxQOxiiEcfYgSK6Hpr4TYCs0IG1OEAbDszALpA",
      "NoNg7ANATFIQnARmogLBRUCs0oAYN8U5J45EQBmFADg0oJAOSlUQF0g",
      "NoRgNATGBs1gLABgQTjCeBWSUDsYBmKbCeMADjNnXxHIoIF0g",
      "NoRg7ANAzBCsAMEAsioxBEIAc0Cc0ATJkgSIYhXIjhMQGxgC6QA",
      "NoVgNAjAHGBMYDYCcdJgCwTFBkYVgAY9JpJYUsYBmAXSA",
      "NoRgNAbAHGAsAMkwgMyzClH0LFcArHnAJzIqIBMGWEAukA"
    ];
       try {
      // バージョンに応じたキーとIVのインデックスを計算
      final keyIndex = 2 + ver * 2;
      final ivIndex = 3 + ver * 2;
      
      // LZStringの同期バージョンを使用（同期的に処理）
      final keyJson = _decompressSync(kKeys[keyIndex]);
      final ivJson = _decompressSync(kKeys[ivIndex]);
      
      // 解凍に失敗した場合
      if (keyJson.isEmpty || ivJson.isEmpty) {
        print('キーまたはIVの解凍に失敗しました');
        return KeyData(key: List<int>.filled(16, 0), iv: List<int>.filled(16, 0));
      }
      
      // JSONとしてパース
      final List<dynamic> keyData = jsonDecode(keyJson);
      final List<dynamic> ivData = jsonDecode(ivJson);
      
      // int型のリストに変換
      final List<int> key = keyData.cast<int>();
      final List<int> iv = ivData.cast<int>();
      
      // MACアドレスを使ってキーとIVを修正
      for (var i = 0; i < 6; i++) {
        key[i] = (key[i] + macBytes[5 - i]) % 255;
        iv[i] = (iv[i] + macBytes[5 - i]) % 255;
      }
      
      print('生成されたキー: ${key.map((e) => e.toRadixString(16).padLeft(2, '0')).join(', ')}');
      print('生成されたIV: ${iv.map((e) => e.toRadixString(16).padLeft(2, '0')).join(', ')}');
      
      return KeyData(key: key, iv: iv);
    } catch (e) {
      print('キー生成エラー: $e');
      // エラー時にはダミーのキーとIVを返す
      return KeyData(key: List<int>.filled(16, 0), iv: List<int>.filled(16, 0));
    }
  }
    // LZString復号を同期的に行うヘルパーメソッド
  static String _decompressSync(String input) {
    try {
      // JavaScript版と同等のロジックを実装
      final result = LZString.decompressFromBase64Sync(
        input.replaceAll('-', '+').replaceAll('_', '/')
      );
      return result ?? '';
    } catch (e) {
      return '';
    }
  }
}