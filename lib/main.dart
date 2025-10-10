import 'package:flutter/material.dart';
import 'package:secure_teste/secure_service.dart';

void main() => runApp(SecureApp());

class SecureApp extends StatelessWidget {
  const SecureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '🔐 Secure Device Registration',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: SecurePage(),
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
  String _status = 'Ready to register device';
  String _secret = '';
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('🔐 Secure Registration')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.security, size: 64, color: Colors.blue),
                    SizedBox(height: 16),
                    Text(
                      'Secure Device Registration',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Your secret is protected by biometric authentication\nand hardware-backed encryption',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: _loading ? null : _registerDevice,
              icon: Icon(Icons.app_registration),
              label: Text('📱 Register Device'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _loading ? null : _getSecret,
              icon: Icon(Icons.fingerprint),
              label: Text('🔓 Get Secret (Biometric)'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
              ),
            ),

            SizedBox(height: 24),

            Card(
              color: Colors.grey[50],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📊 Status:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(_status),
                    if (_secret.isNotEmpty) ...[
                      SizedBox(height: 16),
                      Text(
                        '🔐 Secret:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.all(12),
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
              Padding(
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
      // CHANGE THIS IP TO YOUR SERVER
      await _service.registerDevice('http://192.168.1.145:3000');
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
