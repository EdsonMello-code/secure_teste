import 'package:secure_teste/key_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageFailure implements Exception {
  final String message;

  const SecureStorageFailure(this.message);
}

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
      final planText = await _keyManager.decrypt(valueEncrypted);

      return planText;
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

  Future<bool> save(String key, {required String data}) async {
    if (key.isEmpty) {
      throw SecureStorageFailure('A chave não pode ser vazia!');
    }

    final publicKey = await _keyManager.getPublicKey();

    if (publicKey == null || publicKey.isEmpty) {
      throw SecureStorageFailure('Erro: chave publica nao gerada!');
    }

    final dataEncrypted = _keyManager.encryptSecretToPKCS1Base64(
      pemPublicKey: publicKey,
      secret: data,
    );

    return await _sharedPreferences.setString(key, dataEncrypted);
  }
}
