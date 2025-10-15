import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class SecureService {
  static const _channel = MethodChannel('com.example.secure_teste/keys');
  static const _storage = FlutterSecureStorage();

  Future<void> registerDevice(String serverUrl) async {
    try {
      final publicKeyBase64 = await _channel.invokeMethod<String>(
        'getPublicKey',
      );
      if (publicKeyBase64 == null) {
        throw Exception('Failed to obtain device public key');
      }

      print('📱 Device public key obtained');

      // Register with server
      final response = await http.post(
        Uri.parse('$serverUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'publicKeyBase64': publicKeyBase64}),
      );

      if (response.statusCode != 200) {
        throw Exception('Server registration failed: ${response.body}');
      }

      final responseData = jsonDecode(response.body);
      final encryptedSecret = responseData['encryptedBase64'] as String;

      // Store encrypted secret locally
      await _storage.write(key: 'encrypted_secret', value: encryptedSecret);

      print('✅ Device registered successfully');
      print('📦 Encrypted secret stored locally');
    } catch (e) {
      print('❌ Registration failed: $e');
      rethrow;
    }
  }

  /// 🔓 Get secret with biometric authentication
  ///
  /// Process:
  /// 1. Load encrypted secret from storage
  /// 2. Request biometric authentication
  /// 3. Decrypt using hardware-backed private key
  Future<String> getSecret() async {
    try {
      // Load encrypted secret from storage
      final encryptedSecret = await _storage.read(key: 'encrypted_secret');
      if (encryptedSecret == null) {
        throw Exception('No encrypted secret found. Register device first.');
      }

      print('📦 Encrypted secret loaded from storage');
      print('👆 Requesting biometric authentication...');

      // Decrypt with biometric authentication
      final secret = await _channel.invokeMethod<String>('decryptSecret', {
        'encryptedSecret': encryptedSecret,
      });

      if (secret == null) {
        throw Exception('Decryption failed');
      }

      print('✅ Secret decrypted successfully');
      return secret;
    } catch (e) {
      print('❌ Failed to get secret: $e');
      rethrow;
    }
  }

  /// 🗑️ Reset device registration
  ///
  /// Deletes the RSA key from Android KeyStore and removes the stored
  /// encrypted blob to guarantee the next registration uses a fresh key/blob pair.
  Future<void> resetDevice() async {
    try {
      await _channel.invokeMethod<void>('deleteKey');
      await _storage.delete(key: 'encrypted_secret');
      print('🗑️ Device reset completed');
    } catch (e) {
      print('❌ Reset failed: $e');
      rethrow;
    }
  }
}
