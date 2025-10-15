import 'dart:convert';

import 'package:secure_teste/key_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageFailure implements Exception {
  final String message;

  const SecureStorageFailure(this.message);
}

/// 🔐 SecureStorage - Sistema de Armazenamento Seguro Cross-Platform
///
/// Implementação customizada que demonstra como integrar:
///
/// **🤖 Android:**
/// - KeyStore hardware-backed
/// - Criptografia RSA local (PKCS#1)
/// - BiometricPrompt para autenticação
///
/// **🍎 iOS:**
/// - Keychain + Secure Enclave
/// - Chaves protegidas por biometria (Face ID/Touch ID)
/// - Descriptografia hardware-backed
///
/// **💾 Armazenamento:**
/// - SharedPreferences para dados criptografados
/// - Chaves privadas nunca saem do hardware seguro
/// - Cada plataforma usa seu mecanismo nativo
class SecureStorage {
  final SharedPreferences _sharedPreferences;
  final KeyManager _keyManager;

  const SecureStorage({
    required SharedPreferences sharedPreferences,
    required KeyManager keyManager,
  }) : _sharedPreferences = sharedPreferences,
       _keyManager = keyManager;

  Future<String> get(String key) async {
    final isContainKey = _sharedPreferences.containsKey(key);

    if (!isContainKey) {
      throw SecureStorageFailure('Conteudo da chave $key não existente!');
    }

    final String valueEncrypted = _sharedPreferences.getString(key)!;

    try {
      // ✨ VERIFICAÇÃO DE PLATAFORMA PARA DESCRIPTOGRAFIA
      final publicKey = await _keyManager.getPublicKey();

      if (publicKey != null && publicKey.startsWith('IOS_RAW:')) {
        // ✨ iOS: Descriptografia é feita via hardware (Keychain + biometria)
        print('📱 iOS detected: using hardware decryption');
        final planText = await _keyManager.decrypt(valueEncrypted);
        return planText;
      } else {
        // ✨ Android: Descriptografia é feita via hardware (KeyStore + biometria)
        print('🤖 Android detected: using hardware decryption');
        final planText = await _keyManager.decrypt(valueEncrypted);
        return planText;
      }
    } on KeyFailure catch (e) {
      throw SecureStorageFailure(e.message);
    }
  }

  Future<String> getKeyContent(String key) async {
    final isContainKey = _sharedPreferences.containsKey(key);

    if (!isContainKey) {
      throw SecureStorageFailure('Conteudo da chave $key não existente!');
    }

    return _sharedPreferences.getString(key)!;
  }

  /// 🔍 Método utilitário para verificar a plataforma baseada na chave
  Future<String> getPlatformInfo() async {
    try {
      final publicKey = await _keyManager.getPublicKey();

      if (publicKey == null) {
        return 'Nenhuma chave encontrada';
      }

      if (publicKey.startsWith('IOS_RAW:')) {
        return '📱 iOS - Keychain + Secure Enclave + Face ID/Touch ID';
      } else if (publicKey.startsWith('-----BEGIN PUBLIC KEY-----')) {
        return '🤖 Android - KeyStore + TEE + BiometricPrompt';
      } else {
        return '❓ Formato de chave desconhecido';
      }
    } catch (e) {
      return 'Erro ao detectar plataforma: $e';
    }
  }

  Future<bool> save(String key, {required String data}) async {
    if (key.isEmpty) {
      throw SecureStorageFailure('A chave não pode ser vazia!');
    }

    final publicKey = await _keyManager.getPublicKey();

    if (publicKey == null || publicKey.isEmpty) {
      throw SecureStorageFailure('Erro: chave publica nao gerada!');
    }

    // ✨ CRIPTOGRAFIA LOCAL PARA AMBAS AS PLATAFORMAS
    String dataEncrypted;

    try {
      if (publicKey.startsWith('IOS_RAW:')) {
        // ✨ iOS: Converter raw key para PEM e criptografar localmente
        print(
          '📱 iOS detected: converting raw key to PEM for local encryption',
        );

        final rawKeyBase64 = publicKey.substring(8); // Remove "IOS_RAW:" prefix
        final pemKey = _convertIosRawKeyToPem(rawKeyBase64);

        dataEncrypted = _keyManager.encryptSecretToPKCS1Base64(
          publicKeyData: pemKey,
          secret: data,
        );
      } else {
        // ✨ Android: Criptografia local usando chave PEM
        print('🤖 Android detected: using PEM key for local encryption');
        dataEncrypted = _keyManager.encryptSecretToPKCS1Base64(
          publicKeyData: publicKey,
          secret: data,
        );
      }

      return await _sharedPreferences.setString(key, dataEncrypted);
    } catch (e) {
      throw SecureStorageFailure('Erro na criptografia: $e');
    }
  }

  /// 🔧 Converte chave raw do iOS para formato PEM
  String _convertIosRawKeyToPem(String rawKeyBase64) {
    try {
      // Decodifica o raw key
      final rawKeyBytes = base64Decode(rawKeyBase64);

      // Constrói o DER header para RSA public key
      final derHeader = [
        0x30, 0x82, 0x01, 0x22, // SEQUENCE (290 bytes)
        0x30, 0x0d, // SEQUENCE (13 bytes)
        0x06, 0x09, // OBJECT IDENTIFIER (9 bytes)
        0x2a,
        0x86,
        0x48,
        0x86,
        0xf7,
        0x0d,
        0x01,
        0x01,
        0x01, // RSA encryption OID
        0x05, 0x00, // NULL
        0x03, 0x82, 0x01, 0x0f, // BIT STRING (271 bytes)
        0x00, // Unused bits
      ];

      // Combina header + raw key
      final derBytes = [...derHeader, ...rawKeyBytes];

      // Converte para Base64 e formata como PEM
      final derBase64 = base64Encode(derBytes);
      final pemLines = derBase64
          .replaceAllMapped(
            RegExp(r'.{1,64}'),
            (match) => '${match.group(0)}\n',
          )
          .trimRight();

      final pemKey =
          '-----BEGIN PUBLIC KEY-----\n$pemLines\n-----END PUBLIC KEY-----\n';

      print('✅ iOS raw key converted to PEM successfully');
      return pemKey;
    } catch (e) {
      throw SecureStorageFailure('Erro na conversão da chave iOS: $e');
    }
  }
}
