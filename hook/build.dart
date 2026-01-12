import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';

void main(List<String> args) async {
  const version = '3.5.4';
  const sourceCodeUrl = 'https://github.com/openssl/openssl/releases/download/openssl-$version/openssl-$version.tar.gz';
  const openSslDirName = 'openssl-$version';

  await build(args, (input, output) async {
    if (input.config.buildCodeAssets) {
      final workDir = Directory(input.outputDirectory.path);
      // download source code from openssl
      await runProcess('curl', ['-L', sourceCodeUrl, '-o', '$openSslDirName.tar.gz'], workingDirectory: workDir);

      // unzip source code
      await runProcess('tar', ['-xzf', '$openSslDirName.tar.gz'], workingDirectory: workDir);

      final openSslDir = Directory(workDir.uri.resolve(openSslDirName).path);

      // build source code, depends on the OS we are running on
      // Read https://github.com/openssl/openssl/blob/openssl-3.5.4/INSTALL.md#building-openssl
      final configName = resolveConfigName(input.config.code.targetOS, input.config.code.targetArchitecture);
      switch (OS.current) {
        case OS.windows:
          // run ./Configure with the target OS and architecture
          await runProcess('perl', [
            'Configure',
            configName,
            'no-unit-test',
            'no-asm',
            'no-makedepend',
            // needed to build using multiple threads on Windows
            '/FS',
          ], workingDirectory: openSslDir);

          // run jom to build the library
          await runProcess('jom', [
            // TODO: don't know if this is needed
            // 'build_sw',
            '-j',
            '${Platform.numberOfProcessors}',
            '-c',
            'user.openssl:windows_use_jom=True',
          ], workingDirectory: openSslDir);
          break;
        case OS.macOS:
        case OS.linux:
          // run ./Configure with the target OS and architecture
          await runProcess('./Configure', [
            configName,
            'no-unit-test',
            'no-asm',
            'no-makedepend',
          ], workingDirectory: openSslDir);

          // run make
          await runProcess('make', ['-j', '${Platform.numberOfProcessors}'], workingDirectory: openSslDir);
          break;
      }
    }
  });
}

String resolveConfigName(OS os, Architecture architecture) {
  return switch ((os, architecture)) {
    (OS.android, Architecture.arm) => 'android-arm',
    (OS.android, Architecture.arm64) => 'android-arm64',
    (OS.android, Architecture.ia32) => 'android-x86',
    (OS.android, Architecture.x64) => 'android-x86_64',
    (OS.android, Architecture.riscv64) => 'android-riscv64',

    (OS.iOS, Architecture.arm) => 'ios-xcrun',
    (OS.iOS, Architecture.arm64) => 'ios64-xcrun',
    (OS.iOS, Architecture.ia32) => 'iossimulator-i386-xcrun',
    (OS.iOS, Architecture.x64) => 'iossimulator-x86_64-xcrun',

    (OS.macOS, Architecture.arm64) => 'darwin64-arm64',
    (OS.macOS, Architecture.x64) => 'darwin64-x86_64',
    (OS.macOS, Architecture.ia32) => 'darwin-i386',

    (OS.linux, Architecture.arm) => 'linux-armv4',
    (OS.linux, Architecture.arm64) => 'linux-aarch64',
    (OS.linux, Architecture.ia32) => 'linux-x86',
    (OS.linux, Architecture.x64) => 'linux-x86_64',
    (OS.linux, Architecture.riscv32) => 'linux32-riscv32',
    (OS.linux, Architecture.riscv64) => 'linux64-riscv64',

    (OS.windows, Architecture.arm) => 'VC-WIN32-ARM',
    (OS.windows, Architecture.arm64) => 'VC-WIN64-ARM',
    (OS.windows, Architecture.ia32) => 'VC-WIN32',
    (OS.windows, Architecture.x64) => 'VC-WIN64A',

    _ => throw UnsupportedError('Unsupported target combination: ${os.name}-${architecture.name}'),
  };
}

Future<void> runProcess(String executable, List<String> arguments, {Directory? workingDirectory}) async {
  print('----------');
  print('Running `$executable $arguments` in $workingDirectory');
  final processResult = await Process.run(executable, arguments, workingDirectory: workingDirectory?.path);
  print('stdout:');
  print(processResult.stdout);
  if ((processResult.stderr as String).isNotEmpty) {
    print('stderr:');
    print(processResult.stderr);
  }
  if (processResult.exitCode != 0) {
    throw ProcessException(executable, arguments, '', processResult.exitCode);
  }
  print('==========');
}
