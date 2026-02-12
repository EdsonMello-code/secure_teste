# 🔐 Secure Device Registration

A secure device registration system that demonstrates hardware-backed encryption and biometric authentication for mobile applications. This project showcases best practices for protecting sensitive data using device-specific cryptographic keys.

## 🎯 Overview

This application implements a secure device registration flow where:
1. Each device generates a unique RSA key pair in hardware-backed storage
2. The public key is sent to a server
3. The server encrypts a secret using the public key
4. The encrypted secret is stored locally on the device
5. The secret can only be decrypted using biometric authentication

## 🏗️ Architecture

### Components

- **Flutter App**: Cross-platform mobile application (Android & iOS)
- **Node.js Server**: Debug server for device registration and encryption
- **Hardware Security**: 
  - Android: Android KeyStore with optional StrongBox support
  - iOS: Secure Enclave via Keychain

### Security Flow

```
┌─────────────┐         ┌─────────────┐
│   Device    │         │   Server    │
└──────┬──────┘         └──────┬──────┘
       │                       │
       │  1. Generate RSA Key  │
       │     (Hardware-backed) │
       │                       │
       │  2. Send Public Key   │
       ├──────────────────────►│
       │                       │
       │                       │ 3. Encrypt Secret
       │                       │    with Public Key
       │                       │
       │ 4. Return Encrypted   │
       │◄──────────────────────┤
       │                       │
       │ 5. Store Encrypted    │
       │    Secret Locally     │
       │                       │
       │ 6. Decrypt with       │
       │    Biometric Auth     │
       │                       │
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.9.2 or higher)
- Node.js (for the debug server)
- Android Studio (for Android development)
- Xcode (for iOS development)
- A device with biometric authentication capability

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/EdsonMello-code/secure_teste.git
   cd secure_teste
   ```

2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Install Node.js dependencies**
   ```bash
   npm install
   ```

### Running the Application

1. **Start the debug server**
   ```bash
   node server_debug.js
   ```
   
   The server will start on port 3000.

2. **Configure the server URL**
   - For Android Emulator: Use `http://10.0.2.2:3000`
   - For iOS Simulator: Use `http://localhost:3000`
   - For Physical Device: Use your computer's IP address (e.g., `http://192.168.1.100:3000`)

3. **Run the Flutter app**
   ```bash
   flutter run
   ```

## 📱 Usage

### Device Registration

1. Enter the server URL in the text field
2. Tap "📱 Register Device"
3. The app will:
   - Generate a hardware-backed RSA key pair
   - Send the public key to the server
   - Receive and store the encrypted secret

### Retrieving the Secret

1. Tap "🔓 Get Secret (Biometric)"
2. Complete the biometric authentication prompt
3. The app will decrypt and display the secret

## 🔒 Security Features

### Android

- **Android KeyStore**: Hardware-backed key storage
- **StrongBox Support**: Enhanced security on supported devices
- **RSA 2048-bit encryption**: Industry-standard key size
- **Multiple padding modes**: Supports both PKCS1 and OAEP
- **No biometric timeout**: Authentication required for each decryption

### iOS

- **Secure Enclave**: Hardware security module for key storage
- **Keychain Services**: Secure data storage
- **Biometric Authentication**: Face ID or Touch ID required
- **RSA 2048-bit encryption**: Industry-standard key size
- **PKCS1 padding**: Compatible with server encryption

## 🛠️ Development

### Project Structure

```
secure_teste/
├── lib/
│   ├── main.dart              # Flutter app UI
│   └── secure_service.dart    # Security service layer
├── android/
│   └── app/src/main/kotlin/
│       ├── MainActivity.kt    # Android bridge
│       └── SecureKeyHelper.kt # Android KeyStore operations
├── ios/
│   └── Runner/
│       └── AppDelegate.swift  # iOS bridge and Keychain operations
├── server_debug.js            # Node.js debug server
├── pubspec.yaml              # Flutter dependencies
└── package.json              # Node.js dependencies
```

### Key Dependencies

**Flutter:**
- `flutter_secure_storage: ^9.2.4` - Secure local storage
- `http: ^1.5.0` - HTTP client for server communication

**Node.js:**
- `express: ^5.1.0` - Web server framework
- `body-parser: ^2.2.0` - JSON body parsing

## 🧪 Testing

### Manual Testing

1. Test device registration with different server configurations
2. Verify biometric authentication is triggered on secret retrieval
3. Test error handling (network failures, invalid keys, etc.)

### Server Endpoints

- `POST /register` - Register device and get encrypted secret
- `POST /test-configs` - Test multiple encryption configurations
- `POST /get-secret` - Get plain secret (for testing only)

## 🔍 Debugging

The debug server logs detailed information about:
- Key format detection (Android DER vs iOS raw)
- Encryption configuration attempts
- Success/failure of each padding mode
- Key and encrypted data characteristics

## 📝 API Reference

### SecureService (Flutter)

```dart
// Register device with server
Future<void> registerDevice(String serverUrl)

// Get decrypted secret (requires biometric auth)
Future<String> getSecret()

// Reset device registration
Future<void> resetDevice()
```

### Server API

```javascript
POST /register
Body: { publicKeyBase64: string }
Response: { encryptedBase64: string, debug: object }
```

## ⚠️ Security Considerations

- This is a **demonstration project** for educational purposes
- The debug server should **never** be used in production
- Secrets should be rotated regularly in production environments
- Always use HTTPS in production
- Implement proper certificate pinning
- Add rate limiting and authentication to server endpoints

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is provided as-is for educational purposes.

## 👨‍💻 Author

EdsonMello - [GitHub](https://github.com/EdsonMello-code)

## 🙏 Acknowledgments

- Flutter team for the excellent framework
- Android and iOS security teams for hardware-backed security features
- The open-source community for inspiration and best practices
