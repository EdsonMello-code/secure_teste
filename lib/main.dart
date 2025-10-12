import 'package:flutter/material.dart';
import 'package:secure_teste/key_storage.dart';
import 'package:secure_teste/secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: HomePage());
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final KeyManager _keyManager = KeyManager();
  late final SecureStorage? _secureStorage;

  String texto = '';
  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      _secureStorage = SecureStorage(
        sharedPreferences: prefs,
        keyManager: _keyManager,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Exemplo de Armazenamento Seguro')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () async {
              try {
                await _secureStorage!.save('Nome', data: 'Edson');
              } catch (e) {
                print('Erro ao salvar dados: $e');
              }
            },
            child: Text('Salvar Dados'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final data = await _secureStorage!.get('Nome');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Dados recuperados: $data')),
                );
                print('Dados recuperados: $data');
              } catch (e) {
                print('Erro ao recuperar dados: $e');
              }
            },
            child: Text('Obter Dados'),
          ),

          ElevatedButton(
            onPressed: () async {
              try {
                final keyContent = await _secureStorage!.getKeyContent('Nome');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Conteúdo da chave: $keyContent')),
                );

                setState(() {
                  texto = keyContent;
                });
                print('Conteúdo da chave: $keyContent');
              } catch (e) {
                print('Erro ao obter conteúdo da chave: $e');
              }
            },
            child: Text('Obter Conteúdo da Chave'),
          ),

          SelectableText(texto),
        ],
      ),
    );
  }
}
