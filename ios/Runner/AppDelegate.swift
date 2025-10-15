import Flutter
import UIKit
import Security
import LocalAuthentication

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
    let keyChannel = FlutterMethodChannel(name: "com.example.secure_teste/keys",
                                         binaryMessenger: controller.binaryMessenger)
    
    keyChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      self?.handleKeyMethod(call: call, result: result)
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func handleKeyMethod(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPublicKey":
      handleGetPublicKey(result: result)
    case "decryptSecret":
      if let args = call.arguments as? [String: Any],
         let encryptedSecret = args["encryptedSecret"] as? String {
        handleDecryptSecret(encryptedSecret: encryptedSecret, result: result)
      } else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing encryptedSecret", details: nil))
      }
    case "deleteKey":
      handleDeleteKey(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  // MARK: - Keychain Implementation
  
  private static let keyAlias = "secure_teste_rsa_key"
  private static let keychainService = "com.example.secure_teste.keychain"
  
  private func handleGetPublicKey(result: @escaping FlutterResult) {
    do {
      // Check if key already exists
      if let existingPublicKey = try getExistingPublicKey() {
        print("📱 Using existing RSA key pair")
        result(existingPublicKey)
        return
      }
      
      // Generate new key pair
      print("🔑 Generating new RSA key pair...")
      let publicKeyBase64 = try generateRSAKeyPair()
      result(publicKeyBase64)
      
    } catch {
      print("❌ Error getting public key: \(error)")
      result(FlutterError(code: "KEY_ERROR", 
                        message: "Failed to get public key: \(error.localizedDescription)", 
                        details: nil))
    }
  }
  
  private func getExistingPublicKey() throws -> String? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassKey,
      kSecAttrApplicationTag as String: Self.keyAlias.data(using: .utf8)!,
      kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
      kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
      kSecReturnRef as String: true
    ]
    
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    
    if status == errSecSuccess, let publicKey = item {
      return try exportPublicKey(publicKey as! SecKey)
    } else if status == errSecItemNotFound {
      return nil
    } else {
      throw KeychainError.failedToRetrieveKey(status)
    }
  }
  
  private func generateRSAKeyPair() throws -> String {
    // Create access control for biometric authentication
    guard let accessControl = SecAccessControlCreateWithFlags(
      kCFAllocatorDefault,
      kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
      [.privateKeyUsage, .biometryAny],
      nil
    ) else {
      throw KeychainError.failedToCreateAccessControl
    }
    
    // Key generation parameters using modern API
    let keyAttributes: [String: Any] = [
      kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
      kSecAttrKeySizeInBits as String: 2048,
      kSecAttrIsPermanent as String: true,
      kSecAttrApplicationTag as String: Self.keyAlias.data(using: .utf8)!,
      kSecAttrAccessControl as String: accessControl
    ]
    
    var error: Unmanaged<CFError>?
    guard let privateKey = SecKeyCreateRandomKey(keyAttributes as CFDictionary, &error) else {
      throw KeychainError.failedToGenerateKeyPair(error?.takeRetainedValue())
    }
    
    // Get the corresponding public key
    guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
      throw KeychainError.failedToGetPublicKey
    }
    
    print("✅ RSA key pair generated successfully using modern API")
    return try exportPublicKey(publicKey)
  }
  
  private func exportPublicKey(_ publicKey: SecKey) throws -> String {
    var error: Unmanaged<CFError>?
    guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &error) else {
      throw KeychainError.failedToExportPublicKey(error?.takeRetainedValue())
    }
    
    let keyData = publicKeyData as Data
    
    // Debug: print raw key info
    print("📏 Raw iOS key data length: \(keyData.count)")
    print("📱 First 20 bytes: \(keyData.prefix(20).map { String(format: "%02x", $0) }.joined())")
    
    // For now, just send the raw key data with a special prefix to identify iOS format
    let base64Key = keyData.base64EncodedString()
    let iosKey = "IOS_RAW:" + base64Key
    
    print("� Sending iOS raw key format")
    return iosKey
  }
  
  

  private func handleDecryptSecret(encryptedSecret: String, result: @escaping FlutterResult) {
    do {
      // Get private key from keychain
      let privateKey = try getPrivateKey()
      
      // Decode base64 encrypted data
      guard let encryptedData = Data(base64Encoded: encryptedSecret) else {
        throw KeychainError.invalidBase64Data
      }
      
      print("👆 Requesting biometric authentication for decryption...")
      
      // Decrypt with biometric authentication
      var error: Unmanaged<CFError>?
      guard let decryptedData = SecKeyCreateDecryptedData(
        privateKey,
        .rsaEncryptionPKCS1,
        encryptedData as CFData,
        &error
      ) else {
        throw KeychainError.failedToDecrypt(error?.takeRetainedValue())
      }
      
      guard let decryptedString = String(data: decryptedData as Data, encoding: .utf8) else {
        throw KeychainError.failedToDecodeDecryptedData
      }
      
      print("✅ Secret decrypted successfully")
      result(decryptedString)
      
    } catch {
      print("❌ Decryption failed: \(error)")
      result(FlutterError(code: "DECRYPT_ERROR", 
                        message: "Failed to decrypt secret: \(error.localizedDescription)", 
                        details: nil))
    }
  }
  
  private func getPrivateKey() throws -> SecKey {
    let query: [String: Any] = [
      kSecClass as String: kSecClassKey,
      kSecAttrApplicationTag as String: Self.keyAlias.data(using: .utf8)!,
      kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
      kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
      kSecReturnRef as String: true,
      kSecUseOperationPrompt as String: "🔐 Autentique-se para descriptografar os dados"
    ]
    
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    
    guard status == errSecSuccess, let privateKey = item else {
      throw KeychainError.failedToRetrievePrivateKey(status)
    }
    
    return privateKey as! SecKey
  }
  
  private func handleDeleteKey(result: @escaping FlutterResult) {
    do {
      try deleteKeyPair()
      print("🗑️ RSA key pair deleted from keychain")
      result(nil)
    } catch {
      print("❌ Failed to delete key: \(error)")
      result(FlutterError(code: "DELETE_ERROR", 
                        message: "Failed to delete key: \(error.localizedDescription)", 
                        details: nil))
    }
  }
  
  private func deleteKeyPair() throws {
    // Delete private key
    let privateKeyQuery: [String: Any] = [
      kSecClass as String: kSecClassKey,
      kSecAttrApplicationTag as String: Self.keyAlias.data(using: .utf8)!,
      kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
      kSecAttrKeyClass as String: kSecAttrKeyClassPrivate
    ]
    
    let privateKeyStatus = SecItemDelete(privateKeyQuery as CFDictionary)
    if privateKeyStatus != errSecSuccess && privateKeyStatus != errSecItemNotFound {
      throw KeychainError.failedToDeletePrivateKey(privateKeyStatus)
    }
    
    // Delete public key
    let publicKeyQuery: [String: Any] = [
      kSecClass as String: kSecClassKey,
      kSecAttrApplicationTag as String: Self.keyAlias.data(using: .utf8)!,
      kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
      kSecAttrKeyClass as String: kSecAttrKeyClassPublic
    ]
    
    let publicKeyStatus = SecItemDelete(publicKeyQuery as CFDictionary)
    if publicKeyStatus != errSecSuccess && publicKeyStatus != errSecItemNotFound {
      throw KeychainError.failedToDeletePublicKey(publicKeyStatus)
    }
  }
}

// MARK: - Error Types

enum KeychainError: Error, LocalizedError {
  case failedToCreateAccessControl
  case failedToGenerateKeyPair(CFError?)
  case failedToGetPublicKey
  case failedToExportPublicKey(CFError?)
  case failedToRetrieveKey(OSStatus)
  case failedToRetrievePrivateKey(OSStatus)
  case failedToDecrypt(CFError?)
  case failedToDeletePrivateKey(OSStatus)
  case failedToDeletePublicKey(OSStatus)
  case invalidBase64Data
  case failedToDecodeDecryptedData
  
  var errorDescription: String? {
    switch self {
    case .failedToCreateAccessControl:
      return "Failed to create access control for biometric authentication"
    case .failedToGenerateKeyPair(let error):
      return "Failed to generate RSA key pair: \(error?.localizedDescription ?? "Unknown error")"
    case .failedToGetPublicKey:
      return "Failed to get public key from private key"
    case .failedToExportPublicKey(let error):
      return "Failed to export public key: \(error?.localizedDescription ?? "Unknown error")"
    case .failedToRetrieveKey(let status):
      return "Failed to retrieve key from keychain (status: \(status))"
    case .failedToRetrievePrivateKey(let status):
      return "Failed to retrieve private key from keychain (status: \(status))"
    case .failedToDecrypt(let error):
      return "Failed to decrypt data: \(error?.localizedDescription ?? "Unknown error")"
    case .failedToDeletePrivateKey(let status):
      return "Failed to delete private key (status: \(status))"
    case .failedToDeletePublicKey(let status):
      return "Failed to delete public key (status: \(status))"
    case .invalidBase64Data:
      return "Invalid base64 encrypted data"
    case .failedToDecodeDecryptedData:
      return "Failed to decode decrypted data as UTF-8 string"
    }
  }
}
