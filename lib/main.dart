import 'package:flutter/material.dart';
import 'package:secure_teste/secure_service.dart';

void main() => runApp(const SecureApp());

class SecureApp extends StatelessWidget {
  const SecureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '🔐 Secure Device Registration',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SecurePage(),
    );
  }
}

class SecurePage extends StatefulWidget {
  const SecurePage({super.key});

  @override
  _SecurePageState createState() => _SecurePageState();
}

class _SecurePageState extends State<SecurePage> {
  final _service = SecureService();
  final _serverUrlController = TextEditingController(text: 'http://localhost:3000');
  String _status = 'Ready to register device';
  String _secret = '';
  bool _loading = false;

  @override
  void dispose() {
    _serverUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🔐 Secure Registration')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.security, size: 64, color: Colors.blue),
                    const SizedBox(height: 16),
                    Text(
                      'Secure Device Registration',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your secret is protected by biometric authentication\nand hardware-backed encryption',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Server URL Configuration
            TextField(
              controller: _serverUrlController,
              decoration: const InputDecoration(
                labelText: 'Server URL',
                hintText: 'http://localhost:3000',
                prefixIcon: Icon(Icons.link),
                border: OutlineInputBorder(),
              ),
              enabled: !_loading,
            ),

            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: _loading ? null : _registerDevice,
              icon: const Icon(Icons.app_registration),
              label: const Text('📱 Register Device'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _loading ? null : _getSecret,
              icon: const Icon(Icons.fingerprint),
              label: const Text('🔓 Get Secret (Biometric)'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
              ),
            ),

            const SizedBox(height: 24),

            Card(
              color: Colors.grey[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📊 Status:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(_status),
                    if (_secret.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        '🔐 Secret:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          border: Border.all(color: Colors.green[200]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _secret,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            color: Colors.green[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _registerDevice() async {
    setState(() {
      _loading = true;
      _status = 'Registering device...';
    });

    try {
      final serverUrl = _serverUrlController.text.trim();
      if (serverUrl.isEmpty) {
        throw Exception('Please enter a server URL');
      }

      await _service.registerDevice(serverUrl);
      setState(() {
        _status = '✅ Device registered successfully!';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Registration failed: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _getSecret() async {
    setState(() {
      _loading = true;
      _status = 'Requesting biometric authentication...';
      _secret = '';
    });

    try {
      final secret = await _service.getSecret();
      setState(() {
        _status = '✅ Secret retrieved successfully!';
        _secret = secret;
      });
    } catch (e) {
      setState(() {
        _status = '❌ Failed to get secret: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }
}
