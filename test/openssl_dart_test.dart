import 'dart:convert';

import 'package:openssl_dart/openssl_dart.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {
    final openssl = OpenSSL();

    group('AES', () {
      test('encrypt/decrypt roundtrip', () {
        final key = utf8.encode('Nc92PMoPjcIls5QoXeki5yIPuhjjWMcx');
        final iv = utf8.encode('1234567890123456');
        const message = 'Secret message for AES-256-CBC';
        final plaintext = utf8.encode(message);

        final ciphertext = openssl.aesEncrypt(plaintext, key, iv);
        expect(ciphertext, isNot(equals(plaintext)));
        print('encrypted text: ${base64.encode(ciphertext)}');

        final decrypted = openssl.aesDecrypt(ciphertext, key, iv);
        expect(utf8.decode(decrypted), equals(message));
      });
    });
  });
}
