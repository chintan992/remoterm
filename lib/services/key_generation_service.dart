import 'dart:io';
import 'package:path_provider/path_provider.dart';

class SSHKeyGenerationResult {
  final String privateKey;
  final String publicKey;

  SSHKeyGenerationResult({required this.privateKey, required this.publicKey});
}

class KeyGenerationService {
  /// Generates an Ed25519 SSH keypair using the system's `ssh-keygen` command.
  /// Throws an exception if `ssh-keygen` is not available or if generating fails.
  Future<SSHKeyGenerationResult> generateEd25519Key() async {
    final tempDir = await getTemporaryDirectory();
    final tempFileName = 'id_ed25519_${DateTime.now().millisecondsSinceEpoch}';
    final tempFilePath =
        '${tempDir.path}${Platform.pathSeparator}$tempFileName';

    try {
      // Run ssh-keygen. -t ed25519 specifies type, -f specifies file, -N '' sets empty passphrase,
      // -q for quiet mode.
      final result = await Process.run('ssh-keygen', [
        '-t',
        'ed25519',
        '-f',
        tempFilePath,
        '-N',
        '',
        '-q',
      ]);

      if (result.exitCode != 0) {
        throw Exception('Failed to generate SSH key: ${result.stderr}');
      }

      final privateKeyFile = File(tempFilePath);
      final publicKeyFile = File('$tempFilePath.pub');

      if (!await privateKeyFile.exists() || !await publicKeyFile.exists()) {
        throw Exception('Key files were not generated properly.');
      }

      final privateKey = await privateKeyFile.readAsString();
      final publicKey = await publicKeyFile.readAsString();

      // Clean up files immediately
      await privateKeyFile.delete();
      await publicKeyFile.delete();

      return SSHKeyGenerationResult(
        privateKey: privateKey,
        publicKey: publicKey,
      );
    } catch (e) {
      // Try cleaning up in case of error
      final privateKeyFile = File(tempFilePath);
      final publicKeyFile = File('$tempFilePath.pub');
      if (await privateKeyFile.exists()) await privateKeyFile.delete();
      if (await publicKeyFile.exists()) await publicKeyFile.delete();

      rethrow;
    }
  }
}
