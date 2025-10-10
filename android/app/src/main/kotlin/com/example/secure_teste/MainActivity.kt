package com.example.secure_teste

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * 🌉 Clean MainActivity - Secure Device Registration Bridge
 *
 * Minimal bridge between Flutter and Android's security features. Supports only essential
 * operations for production use.
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
                            result.error("Error kkk", "Failed to get public key:", null)
                        }
                        result.success(publicKeyBase64)
                    } catch (e: Exception) {
                        result.error("KEY_ERROR", "Failed to get public key: ${e.message}", null)
                    }
                }

                // 🔓 Decrypt secret with biometric authentication
                "decryptSecret" -> {
                    val encryptedSecret = call.argument<String>("encryptedSecret")

                    android.util.Log.d("Teste", encryptedSecret ?: "")

                    if (encryptedSecret == null) {
                        result.error("MISSING_PARAM", "encryptedSecret parameter required", null)
                        return@setMethodCallHandler
                    }

                    val planText = SecureKeyHelper.descriptBase64(encryptedSecret)

                    result.success(planText)
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
