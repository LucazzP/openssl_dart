import 'dart:ffi' as ffi;
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'third_party/openssl.g.dart' as openssl;

class OpenSSL {
  static final OpenSSL _instance = OpenSSL._();
  factory OpenSSL() => _instance;
  OpenSSL._();

  Uint8List aesEncrypt(Uint8List plaintext, Uint8List key, Uint8List iv) {
    return _aes(plaintext, key, iv, encrypt: true);
  }

  Uint8List aesDecrypt(Uint8List ciphertext, Uint8List key, Uint8List iv) {
    return _aes(ciphertext, key, iv, encrypt: false);
  }

  Uint8List _aes(Uint8List input, Uint8List key, Uint8List iv, {required bool encrypt}) {
    if (key.length != 32) {
      throw ArgumentError.value(key.length, 'key', 'Key must be 32 bytes for AES-256-CBC');
    }

    if (iv.length != 16) {
      throw ArgumentError.value(iv.length, 'iv', 'IV must be 16 bytes for AES-256-CBC');
    }

    final ctx = openssl.EVP_CIPHER_CTX_new();
    if (ctx == ffi.nullptr) throw StateError('Failed to create EVP_CIPHER_CTX');

    final inPtr = malloc<ffi.Uint8>(input.isEmpty ? 1 : input.length);
    final keyPtr = malloc<ffi.Uint8>(key.length);
    final ivPtr = malloc<ffi.Uint8>(iv.length);
    final outPtr = malloc<ffi.Uint8>(input.length + openssl.EVP_MAX_BLOCK_LENGTH);
    final outLenPtr = malloc<ffi.Int>();

    try {
      inPtr.asTypedList(input.length).setAll(0, input);
      keyPtr.asTypedList(key.length).setAll(0, key);
      ivPtr.asTypedList(iv.length).setAll(0, iv);

      final initResult = encrypt
          ? openssl.EVP_EncryptInit_ex(
              ctx,
              openssl.EVP_aes_256_cbc(),
              ffi.nullptr,
              keyPtr.cast<ffi.UnsignedChar>(),
              ivPtr.cast<ffi.UnsignedChar>(),
            )
          : openssl.EVP_DecryptInit_ex(
              ctx,
              openssl.EVP_aes_256_cbc(),
              ffi.nullptr,
              keyPtr.cast<ffi.UnsignedChar>(),
              ivPtr.cast<ffi.UnsignedChar>(),
            );
      _checkResult(initResult, 'init');

      final updateResult = encrypt
          ? openssl.EVP_EncryptUpdate(
              ctx,
              outPtr.cast<ffi.UnsignedChar>(),
              outLenPtr,
              inPtr.cast<ffi.UnsignedChar>(),
              input.length,
            )
          : openssl.EVP_DecryptUpdate(
              ctx,
              outPtr.cast<ffi.UnsignedChar>(),
              outLenPtr,
              inPtr.cast<ffi.UnsignedChar>(),
              input.length,
            );
      _checkResult(updateResult, 'update');

      var outLen = outLenPtr.value;

      final finalResult = encrypt
          ? openssl.EVP_EncryptFinal_ex(ctx, outPtr.elementAt(outLen).cast<ffi.UnsignedChar>(), outLenPtr)
          : openssl.EVP_DecryptFinal_ex(ctx, outPtr.elementAt(outLen).cast<ffi.UnsignedChar>(), outLenPtr);
      _checkResult(finalResult, 'final');

      outLen += outLenPtr.value;

      return Uint8List.fromList(outPtr.asTypedList(outLen));
    } finally {
      malloc.free(inPtr);
      malloc.free(keyPtr);
      malloc.free(ivPtr);
      malloc.free(outPtr);
      malloc.free(outLenPtr);
      openssl.EVP_CIPHER_CTX_free(ctx);
    }
  }

  void _checkResult(int result, String step) {
    if (result != 1) throw StateError('OpenSSL AES $step step failed, result: $result');
  }
}
