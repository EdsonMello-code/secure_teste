import 'package:encrypt/encrypt.dart';
import 'package:flutter/services.dart';
import 'package:pointycastle/export.dart';

class KeyFailure implements Exception {
  final String message;

  const KeyFailure(this.message);
}

class KeyManager {
  final _channel = MethodChannel('com.example.secure_teste/keys');

  Future<String?> getPublicKey() async {
    try {
      final publicKeyBase64 = await _channel.invokeMethod<String>(
        'getPublicKey',
      );
      if (publicKeyBase64 == null || publicKeyBase64.isEmpty) {
        throw KeyFailure('Error: chave publica nao gerada!');
      }
      return _androidBase64ToPem(publicKeyBase64);
    } on PlatformException catch (e) {
      throw KeyFailure(e.message ?? '');
    }
  }

  Future<String> decrypt(String? encryptedSecret) async {
    try {
      if (encryptedSecret == null) {
        throw KeyFailure('No encrypted secret found. Register device first.');
      }

      final plainText = await _channel.invokeMethod<String>('decryptSecret', {
        'encryptedSecret': encryptedSecret,
      });

      if (plainText == null) {
        throw Exception('Decryption failed');
      }
      return plainText;
    } catch (e) {
      rethrow;
    }
  }

  String _androidBase64ToPem(String androidBase64) {
    final base64Lines = androidBase64
        .replaceAllMapped(RegExp(r'.{1,64}'), (match) => '${match.group(0)}\n')
        .trimRight();

    return '-----BEGIN PUBLIC KEY-----\n$base64Lines\n-----END PUBLIC KEY-----\n';
  }

  // ✨ VERSÃO SIMPLIFICADA COM ENCRYPT PACKAGE
  String encryptSecretToPKCS1Base64({
    required String pemPublicKey,
    required String secret,
  }) {
    try {
      // Cria parser RSA do package encrypt
      final parser = RSAKeyParser();
      final asymmetricKey = parser.parse(pemPublicKey);

      // Converte para RSAPublicKey (tipo esperado pelo RSA constructor)
      final publicKey = RSAPublicKey(asymmetricKey.n!, asymmetricKey.exponent!);

      // Cria encrypter com RSA PKCS1
      final encrypter = Encrypter(RSA(publicKey: publicKey));

      // Criptografa
      final encrypted = encrypter.encrypt(secret);

      return encrypted.base64;
    } catch (e) {
      throw KeyFailure('Encryption failed: $e');
    }
  }
}
