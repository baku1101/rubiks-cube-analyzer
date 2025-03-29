import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:rubiks_cube_analyzer/services/gan/crypto/aes.dart';

void main() {
  group('KeyGenerator', () {
    test('should generate key and iv from MAC address', () {
      // cstimer/gancube.js の getKeyV2 を参考にした期待値
      final macAddress = [0x11, 0x22, 0x33, 0x44, 0x55, 0x66].join(':');
      final keyData = KeyGenerator.generateFromMAC(macAddress);

      // Base Key: [0x68, 0x92, 0x49, 0x8f, 0xbc, 0xe9, 0x5a, 0x61, 0x4f, 0x89, 0x9c, 0x77, 0x4f, 0x9b, 0x83, 0xca]
      // Base IV:  [0x75, 0x8f, 0xd8, 0x98, 0x4c, 0x83, 0x6f, 0x4d, 0x71, 0x96, 0x4d, 0x71, 0x3d, 0x4a, 0x85, 0x53]
      // MAC (reversed): [0x66, 0x55, 0x44, 0x33, 0x22, 0x11]

      final expectedKey = [
        (0x68 + 0x66) & 0xff, (0x92 + 0x55) & 0xff, (0x49 + 0x44) & 0xff, (0x8f + 0x33) & 0xff, (0xbc + 0x22) & 0xff, (0xe9 + 0x11) & 0xff,
        0x5a, 0x61, 0x4f, 0x89, 0x9c, 0x77, 0x4f, 0x9b, 0x83, 0xca
      ];

      final expectedIv = [
        (0x75 + 0x66) & 0xff, (0x8f + 0x55) & 0xff, (0xd8 + 0x44) & 0xff, (0x98 + 0x33) & 0xff, (0x4c + 0x22) & 0xff, (0x83 + 0x11) & 0xff,
        0x6f, 0x4d, 0x71, 0x96, 0x4d, 0x71, 0x3d, 0x4a, 0x85, 0x53
      ];


      expect(keyData.key, equals(expectedKey), reason: 'Generated key does not match expected value.');
      expect(keyData.iv, equals(expectedIv), reason: 'Generated IV does not match expected value.');
      expect(keyData.key.length, equals(16), reason: 'Key length should be 16 bytes.');
      expect(keyData.iv.length, equals(16), reason: 'IV length should be 16 bytes.');
    });

     test('should throw ArgumentError for invalid MAC address length', () {
      expect(() => KeyGenerator.generateFromMAC([0x11, 0x22, 0x33].map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')),
          throwsArgumentError);
      expect(() => KeyGenerator.generateFromMAC([0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77].map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')),
          throwsArgumentError);
    });
  });

  group('GanAes128', () {
    // テスト用のキーとIV (KeyGeneratorのテストが通ることを前提とする)
    final macBytes = [0x11, 0x22, 0x33, 0x44, 0x55, 0x66];
    final macAddress = macBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':');
    late KeyData keyData;
    late GanAes128 cipher;

    setUpAll(() {
       keyData = KeyGenerator.generateFromMAC(macAddress);
       cipher = GanAes128(keyData.key, keyData.iv); // コンストラクタ名を GanAes128 に変更
    });


    test('should correctly encrypt and decrypt 16 byte data', () {
      final originalData = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]); // 16バイトのデータ
      final encrypted = cipher.encrypt(originalData);
      final decrypted = cipher.decrypt(encrypted);

      // 暗号化後は元データと異なること
      expect(encrypted, isNot(equals(originalData)), reason: 'Encrypted data should differ from original.');
      // 復号化後は元データと一致すること
      expect(decrypted, equals(originalData), reason: 'Decrypted data should match original.');
      // 暗号化後のデータ長は元と同じはず
      expect(encrypted.length, equals(16), reason: 'Encrypted data length should be 16 for 16 byte input.');
      expect(decrypted.length, equals(16), reason: 'Decrypted data length should be 16.');
    });

     test('should correctly encrypt and decrypt 32 byte data', () {
      final originalData = Uint8List.fromList(List.generate(32, (i) => i + 1)); // 32バイト
      final encrypted = cipher.encrypt(originalData);
      final decrypted = cipher.decrypt(encrypted);

      expect(encrypted, isNot(equals(originalData)), reason: 'Encrypted data should differ from original.');
      expect(decrypted, equals(originalData), reason: 'Decrypted data should match original.');
      expect(encrypted.length, equals(32), reason: 'Encrypted data length should be 32 for 32 byte input.');
      expect(decrypted.length, equals(32), reason: 'Decrypted data length should be 32.');
    });

    test('should correctly encrypt and decrypt data lengths not multiple of 16', () {
      final originalData = Uint8List.fromList([1, 2, 3, 4, 5]); // 5バイト
      final encrypted = cipher.encrypt(originalData);
      final decrypted = cipher.decrypt(encrypted);

      expect(encrypted, isNot(equals(originalData)), reason: 'Encrypted data should differ from original.');
      expect(decrypted, equals(originalData), reason: 'Decrypted data should match original.');
      expect(encrypted.length, equals(5), reason: 'Encrypted data length should be 5 for 5 byte input.');
      expect(decrypted.length, equals(5), reason: 'Decrypted data length should be 5.');

      final originalData2 = Uint8List.fromList(List.generate(20, (i) => i + 1)); // 20バイト
      final encrypted2 = cipher.encrypt(originalData2);
      final decrypted2 = cipher.decrypt(encrypted2);

      expect(encrypted2, isNot(equals(originalData2)), reason: 'Encrypted data should differ from original.');
      expect(decrypted2, equals(originalData2), reason: 'Decrypted data should match original.');
      expect(encrypted2.length, equals(20), reason: 'Encrypted data length should be 20 for 20 byte input.');
      expect(decrypted2.length, equals(20), reason: 'Decrypted data length should be 20.');
    });

    // TODO: 既知の暗号化/復号化ペアを用いたテストケースを追加する
    //       (他の実装やツールで生成した値と比較する)
    // test('should match known encrypted value', () {
    //   final knownPlainText = Uint8List.fromList([...]);

    // NIST SP 800-38A F.1.1 AES-128 ECB Encrypt Example
    test('should match NIST AES-128 ECB encrypt vector', () {
      final keyBytes = Uint8List.fromList([
        0x2b, 0x7e, 0x15, 0x16, 0x28, 0xae, 0xd2, 0xa6,
        0xab, 0xf7, 0x15, 0x88, 0x09, 0xcf, 0x4f, 0x3c
      ]);
      final ivBytes = Uint8List.fromList(List.filled(16, 0)); // ECB test, IV not used but required by constructor
      final plainText = Uint8List.fromList([
        0x6b, 0xc1, 0xbe, 0xe2, 0x2e, 0x40, 0x9f, 0x96,
        0xe9, 0x3d, 0x7e, 0x11, 0x73, 0x93, 0x17, 0x2a
      ]);
      final expectedCipherText = Uint8List.fromList([
        0x3a, 0xd7, 0x7b, 0xb4, 0x0d, 0x7a, 0x36, 0x60,
        0xa8, 0x9e, 0xca, 0xf3, 0x24, 0x66, 0xef, 0x97
      ]);

      final testCipher = GanAes128(keyBytes, ivBytes);
      // Access private method for testing (consider making it testable or using a different approach)
      // This requires adjusting the class or using tools like 'test_api' for private access.
      // For now, we call the public encryptBlock method for testing.
      // If not possible, test encrypt() with a known GAN vector if available.
      final encrypted = testCipher.encryptBlock(plainText); // メソッド名を修正

      expect(encrypted, equals(expectedCipherText), reason: 'Encrypted block does not match NIST vector.');
    });

    // NIST SP 800-38A F.1.2 AES-128 ECB Decrypt Example
    test('should match NIST AES-128 ECB decrypt vector', () {
      final keyBytes = Uint8List.fromList([
        0x2b, 0x7e, 0x15, 0x16, 0x28, 0xae, 0xd2, 0xa6,
        0xab, 0xf7, 0x15, 0x88, 0x09, 0xcf, 0x4f, 0x3c
      ]);
      final ivBytes = Uint8List.fromList(List.filled(16, 0)); // ECB test, IV not used
      final cipherText = Uint8List.fromList([
        0x3a, 0xd7, 0x7b, 0xb4, 0x0d, 0x7a, 0x36, 0x60,
        0xa8, 0x9e, 0xca, 0xf3, 0x24, 0x66, 0xef, 0x97
      ]);
      final expectedPlainText = Uint8List.fromList([
        0x6b, 0xc1, 0xbe, 0xe2, 0x2e, 0x40, 0x9f, 0x96,
        0xe9, 0x3d, 0x7e, 0x11, 0x73, 0x93, 0x17, 0x2a
      ]);

      final testCipher = GanAes128(keyBytes, ivBytes);
      // Access private method for testing
      final decrypted = testCipher.decryptBlock(cipherText);

      expect(decrypted, equals(expectedPlainText), reason: 'Decrypted block does not match NIST vector.');
    });

    //   final knownCipherText = Uint8List.fromList([...]);
    //   final encrypted = cipher.encrypt(knownPlainText);
    //   expect(encrypted, equals(knownCipherText));
    // });
    // test('should match known decrypted value', () {
    //   final knownPlainText = Uint8List.fromList([...]);
    //   final knownCipherText = Uint8List.fromList([...]);
    //   final decrypted = cipher.decrypt(knownCipherText);
    //   expect(decrypted, equals(knownPlainText));
    // });
  });
}