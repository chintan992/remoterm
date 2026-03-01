import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageException implements Exception {
  final String message;
  final dynamic cause;
  
  SecureStorageException(this.message, [this.cause]);
  
  @override
  String toString() => message;
}

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
            );

  static const String _passwordPrefix = 'ssh_password_';
  static const String _privateKeyPrefix = 'ssh_private_key_';
  static const String _passphrasePrefix = 'ssh_passphrase_';

  Future<void> saveCredential(String connectionId, String password) async {
    try {
      await _storage.write(
        key: '$_passwordPrefix$connectionId',
        value: password,
      );
    } on Exception catch (e) {
      throw SecureStorageException('Failed to save password', e);
    } catch (e) {
      throw SecureStorageException('Failed to save password: $e', e);
    }
  }

  Future<String?> getCredential(String connectionId) async {
    try {
      return await _storage.read(key: '$_passwordPrefix$connectionId');
    } on Exception catch (e) {
      debugPrint('SecureStorage get password error: $e');
      return null;
    } catch (e) {
      debugPrint('SecureStorage get password error: $e');
      return null;
    }
  }

  Future<void> deleteCredential(String connectionId) async {
    try {
      await _storage.delete(key: '$_passwordPrefix$connectionId');
    } on Exception catch (e) {
      debugPrint('SecureStorage delete password error: $e');
    } catch (e) {
      debugPrint('SecureStorage delete password error: $e');
    }
  }

  Future<void> savePrivateKey(String connectionId, String privateKey) async {
    try {
      await _storage.write(
        key: '$_privateKeyPrefix$connectionId',
        value: privateKey,
      );
    } on Exception catch (e) {
      throw SecureStorageException('Failed to save private key', e);
    } catch (e) {
      throw SecureStorageException('Failed to save private key: $e', e);
    }
  }

  Future<String?> getPrivateKey(String connectionId) async {
    try {
      return await _storage.read(key: '$_privateKeyPrefix$connectionId');
    } on Exception catch (e) {
      debugPrint('SecureStorage get private key error: $e');
      return null;
    } catch (e) {
      debugPrint('SecureStorage get private key error: $e');
      return null;
    }
  }

  Future<void> deletePrivateKey(String connectionId) async {
    try {
      await _storage.delete(key: '$_privateKeyPrefix$connectionId');
    } on Exception catch (e) {
      debugPrint('SecureStorage delete private key error: $e');
    } catch (e) {
      debugPrint('SecureStorage delete private key error: $e');
    }
  }

  Future<void> savePassphrase(String connectionId, String passphrase) async {
    try {
      await _storage.write(
        key: '$_passphrasePrefix$connectionId',
        value: passphrase,
      );
    } on Exception catch (e) {
      throw SecureStorageException('Failed to save passphrase', e);
    } catch (e) {
      throw SecureStorageException('Failed to save passphrase: $e', e);
    }
  }

  Future<String?> getPassphrase(String connectionId) async {
    try {
      return await _storage.read(key: '$_passphrasePrefix$connectionId');
    } on Exception catch (e) {
      debugPrint('SecureStorage get passphrase error: $e');
      return null;
    } catch (e) {
      debugPrint('SecureStorage get passphrase error: $e');
      return null;
    }
  }

  Future<void> deletePassphrase(String connectionId) async {
    try {
      await _storage.delete(key: '$_passphrasePrefix$connectionId');
    } on Exception catch (e) {
      debugPrint('SecureStorage delete passphrase error: $e');
    } catch (e) {
      debugPrint('SecureStorage delete passphrase error: $e');
    }
  }

  Future<void> deleteAllCredentials(String connectionId) async {
    await deleteCredential(connectionId);
    await deletePrivateKey(connectionId);
    await deletePassphrase(connectionId);
  }
}
