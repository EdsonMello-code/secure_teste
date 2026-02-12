package com.example.secure_teste

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * 🌉 MainActivity - Secure Device Registration Bridge
 *
 * Minimal bridge between Flutter and Android's security features.
 * Provides essential operations for secure key management and encryption.
 */
class MainActivity : FlutterFragmentActivity() {

    private val CHANNEL = "com.example.secure_teste/keys"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call,
                result ->
            when (call.method) {

                // 🔑 Get device public key (generates if needed)
                "getPublicKey" -> {
                    try {
                        val publicKeyBase64 =
                                SecureKeyHelper.ensureKeyPairAndGetPublicKeyBase64(this)

                        if (publicKeyBase64.isEmpty()) {
                            result.error("KEY_ERROR", "Failed to get public key", null)
                            return@setMethodCallHandler
                        }
                        result.success(publicKeyBase64)
                    } catch (e: Exception) {
                        result.error("KEY_ERROR", "Failed to get public key: ${e.message}", null)
                    }
                }

                // 🔓 Decrypt secret with biometric authentication
                "decryptSecret" -> {
                    val encryptedSecret = call.argument<String>("encryptedSecret")

                    if (encryptedSecret == null) {
                        result.error("MISSING_PARAM", "encryptedSecret parameter required", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val plainText = SecureKeyHelper.descriptBase64(encryptedSecret)
                        result.success(plainText)
                    } catch (e: Exception) {
                        result.error("DECRYPT_ERROR", "Failed to decrypt: ${e.message}", null)
                    }
                }

                // 🗑️ Delete device key from Android KeyStore
                "deleteKey" -> {
                    try {
                        SecureKeyHelper.deleteKey()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("DELETE_ERROR", "Failed to delete key: ${e.message}", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
