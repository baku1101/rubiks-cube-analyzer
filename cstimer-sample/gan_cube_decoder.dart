import 'package:encrypt/encrypt.dart' as encrypt;
import 'dart:typed_data';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:lzstring/lzstring.dart';
import 'gan_aes128.dart';

class GanCubeDecoder {
  final List<int> keyData;
  final List<int> ivData;
  late final GanAes128 _cipher;
  
  GanCubeDecoder(this.keyData, this.ivData) {
    _cipher = GanAes128(keyData);
    _cipher.iv = ivData;
  }

  // MACアドレスを直接受け取るファクトリコンストラクタ
  factory GanCubeDecoder.fromMacAddress(String macAddress, {int ver = 0}) {
    // MACアドレスからバイトに変換
    final List<int> macBytes = [];
    for (int i = 0; i < 6; i++) {
      macBytes.add(int.parse(macAddress.substring(i * 3, i * 3 + 2), radix: 16));
    }
    
    // キーとIVを生成
    final keyIv = _getKeyFromMacSync(macBytes, ver: ver);
    
    // 生成したキーとIVでインスタンスを作成
    return GanCubeDecoder(keyIv[0], keyIv[1]);
  }
  
  // MACアドレスからキーとIVを生成する静的メソッド（同期版）
  static List<List<int>> _getKeyFromMacSync(List<int> macBytes, {int ver = 0}) {
    // CSTimerから取得した暗号化キーのデータ
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
        debugPrint('キーまたはIVの解凍に失敗しました');
        return [List<int>.filled(16, 0), List<int>.filled(16, 0)];
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
      
      debugPrint('生成されたキー: ${key.map((e) => e.toRadixString(16).padLeft(2, '0')).join(', ')}');
      debugPrint('生成されたIV: ${iv.map((e) => e.toRadixString(16).padLeft(2, '0')).join(', ')}');
      
      return [key, iv];
    } catch (e) {
      debugPrint('キー生成エラー: $e');
      // エラー時にはダミーのキーとIVを返す
      return [List<int>.filled(16, 0), List<int>.filled(16, 0)];
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
      debugPrint('LZString解凍エラー: $e');
      return '';
    }
  }
    // 暗号化メソッド
  Uint8List? encode(List<int> data) {
    try {
      return _cipher.encrypt(data);
    } catch (e, stackTrace) {
      debugPrint('暗号化エラー: $e');
      debugPrint('スタックトレース: $stackTrace');
      return null;
    }
  }
  
  // 復号メソッド
  Uint8List? decode(List<int> data) {
    try {
      return _cipher.decrypt(data);
    } catch (e, stackTrace) {
      debugPrint('復号エラー: $e');
      debugPrint('スタックトレース: $stackTrace');
      return null;
    }
  }

}