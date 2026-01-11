import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:logging/logging.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    if (input.config.buildCodeAssets == false) {
      // If code assets should not be built, skip the build.
      return;
    }

    final cBuilder = CBuilder.library(
      name: 'openssl3',
      assetName: 'src/third_party/openssl3.g.dart',
      sources: ['third_party/openssl/openssl3.c'],
      defines: {
        if (input.config.code.targetOS == OS.windows)
          // Ensure symbols are exported in dll.
          'SQLITE_API': '__declspec(dllexport)',
      },
    );
    await cBuilder.run(
      input: input,
      output: output,
      logger: Logger('')
        ..level = Level.ALL
        ..onRecord.listen((record) => print(record.message)),
    );
  });
}
