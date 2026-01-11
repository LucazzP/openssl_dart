import 'dart:io';

import 'package:ffigen/ffigen.dart';
import 'package:logging/logging.dart';

void main() {
  final packageRoot = Platform.script.resolve('../');
  final opensslInclude = packageRoot.resolve('src/third_party/openssl/include/');
  // Only expose the public OpenSSL headers; internal crypto headers (e.g.
  // crypto/md32_common.h) expect algorithm-specific macros and fail if parsed
  // standalone.
  final opensslPublic = opensslInclude.resolve('openssl/');
  final logger = Logger('ffigen')..onRecord.listen((record) => print(record.message));

  final headers = <Uri>[];
  final compilerOpts = [...defaultCompilerOpts(logger), '-I${opensslInclude.toFilePath()}'];

  for (final entry in Directory(opensslPublic.path).listSync(recursive: true)) {
    if (entry.path.endsWith('.h')) {
      headers.add(entry.uri);
    }
  }

  FfiGenerator(
    headers: Headers(entryPoints: headers, compilerOptions: compilerOpts),
    functions: Functions.includeSet({
      'EVP_CIPHER_CTX_new',
      'EVP_EncryptInit_ex',
      'EVP_aes_256_cbc',
      'EVP_DecryptInit_ex',
      'EVP_EncryptUpdate',
      'EVP_DecryptUpdate',
      'EVP_EncryptFinal_ex',
      'EVP_DecryptFinal_ex',
      'EVP_CIPHER_CTX_free',
    }),
    macros: Macros.includeSet({'EVP_MAX_BLOCK_LENGTH'}),
    output: Output(
      dartFile: packageRoot.resolve('lib/src/third_party/openssl.g.dart'),
    ),
  ).generate(logger: logger);
}
