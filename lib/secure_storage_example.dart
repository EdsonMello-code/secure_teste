/// 🔐 Exemplo de Uso do Sistema de Armazenamento Seguro Cross-Platform
///
/// Este exemplo demonstra como usar o SecureStorage customizado que:
/// - 🤖 Android: KeyStore + BiometricPrompt + Criptografia RSA local
/// - 🍎 iOS: Keychain + Secure Enclave + Face ID/Touch ID + Criptografia RSA local
library;

import 'package:flutter/material.dart';
import 'package:secure_teste/key_storage.dart';
import 'package:secure_teste/secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageExample extends StatefulWidget {
  const SecureStorageExample({super.key});

  @override
  _SecureStorageExampleState createState() => _SecureStorageExampleState();
}

class _SecureStorageExampleState extends State<SecureStorageExample> {
  late SecureStorage _secureStorage;
  String _status = 'Inicializando...';
  String _platformInfo = '';
  String _secretValue = '';

  @override
  void initState() {
    super.initState();
    _initializeSecureStorage();
  }

  Future<void> _initializeSecureStorage() async {
    try {
      final sharedPrefs = await SharedPreferences.getInstance();
      final keyManager = KeyManager();

      _secureStorage = SecureStorage(
        sharedPreferences: sharedPrefs,
        keyManager: keyManager,
      );

      final platformInfo = await _secureStorage.getPlatformInfo();

      setState(() {
        _status = 'Pronto para uso';
        _platformInfo = platformInfo;
      });
    } catch (e) {
      setState(() {
        _status = 'Erro na inicialização: $e';
      });
    }
  }

  Future<void> _saveSecret() async {
    try {
      setState(() => _status = 'Salvando dados...');

      final success = await _secureStorage.save(
        'user_secret',
        data: 'Minha informação super secreta! 🔐',
      );

      setState(() {
        _status = success
            ? 'Dados salvos com criptografia!'
            : 'Falha ao salvar';
      });
    } catch (e) {
      setState(() => _status = 'Erro ao salvar: $e');
    }
  }

  Future<void> _loadSecret() async {
    try {
      setState(() => _status = 'Carregando dados (autenticação biométrica)...');

      final secret = await _secureStorage.get('user_secret');

      setState(() {
        _status = 'Dados carregados com sucesso!';
        _secretValue = secret;
      });
    } catch (e) {
      setState(() {
        _status = 'Erro ao carregar: $e';
        _secretValue = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🔐 Secure Storage Demo'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🔍 Informações da Plataforma',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 8),
                    Text(
                      _platformInfo,
                      style: TextStyle(fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📊 Status',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 8),
                    Text(_status),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: _saveSecret,
              icon: Icon(Icons.save),
              label: Text('💾 Salvar Dados Criptografados'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),

            SizedBox(height: 8),

            ElevatedButton.icon(
              onPressed: _loadSecret,
              icon: Icon(Icons.fingerprint),
              label: Text('🔓 Carregar com Biometria'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),

            if (_secretValue.isNotEmpty) ...[
              SizedBox(height: 16),
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🔓 Dados Descriptografados:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SizedBox(height: 8),
                      Text(
                        _secretValue,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            Spacer(),

            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  children: [
                    Text(
                      '🛡️ Segurança Implementada',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Hardware-backed encryption (KeyStore/Keychain)\n'
                      '• Biometric authentication required\n'
                      '• RSA 2048-bit + PKCS#1 padding\n'
                      '• Private keys never leave secure hardware\n'
                      '• Cross-platform compatibility',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
