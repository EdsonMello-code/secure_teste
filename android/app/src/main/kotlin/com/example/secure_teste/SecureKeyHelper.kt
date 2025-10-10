package com.example.secure_teste

import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import java.nio.charset.StandardCharsets
import java.security.KeyPairGenerator
import java.security.KeyStore
import javax.crypto.Cipher

object SecureKeyHelper {

    private const val ANDROID_KEYSTORE = "AndroidKeyStore"
    private const val KEY_ALIAS = "app_device_key"
    private const val TEST_KEY_ALIAS = "test_key_no_auth" // Chave sem autenticação para teste

    /** Remove a(s) chave(s) existente(s) (útil para reset/debug) */
    fun deleteKey() {
        try {
            val keyStore = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }
            if (keyStore.containsAlias(KEY_ALIAS)) {
                keyStore.deleteEntry(KEY_ALIAS)
            }
            if (keyStore.containsAlias(TEST_KEY_ALIAS)) {
                keyStore.deleteEntry(TEST_KEY_ALIAS)
            }
            android.util.Log.d("SECURE", "Key aliases removed from KeyStore")
        } catch (e: Exception) {
            android.util.Log.e("SECURE", "Error deleting keys", e)
        }
    }

    // /** Gera chave SEM autenticação para teste */
    // fun ensureTestKeyAndGetPublicKeyBase64(): String {
    //     val keyStore = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }

    //     if (!keyStore.containsAlias(TEST_KEY_ALIAS)) {
    //         android.util.Log.d("SECURE", "Generating TEST key WITHOUT authentication...")
    //         val kpg = KeyPairGenerator.getInstance(KeyProperties.KEY_ALGORITHM_RSA,
    // ANDROID_KEYSTORE)
    //         val builder = KeyGenParameterSpec.Builder(
    //             TEST_KEY_ALIAS,
    //             KeyProperties.PURPOSE_DECRYPT
    //         ).apply {
    //             setDigests(KeyProperties.DIGEST_SHA256, KeyProperties.DIGEST_SHA1)
    //             // 🔥 SUPORTA TANTO OAEP QUANTO PKCS1!
    //             setEncryptionPaddings(
    //                 KeyProperties.ENCRYPTION_PADDING_RSA_OAEP,
    //                 KeyProperties.ENCRYPTION_PADDING_RSA_PKCS1
    //             )
    //             setKeySize(2048)
    //             // 🔥 SEM AUTENTICAÇÃO para teste
    //             setUserAuthenticationRequired(false)
    //         }

    //         kpg.initialize(builder.build())
    //         kpg.generateKeyPair()
    //         android.util.Log.d("SECURE", "Test KeyPair generated successfully (no auth
    // required)")
    //     }

    //     val publicKey = keyStore.getCertificate(TEST_KEY_ALIAS).publicKey
    //     val publicKeyBase64 = Base64.encodeToString(publicKey.encoded, Base64.NO_WRAP)
    //     android.util.Log.d("SECURE", "Test public key (first 50 chars):
    // ${publicKeyBase64.take(50)}...")
    //     return publicKeyBase64
    // }

    /** Verifica suporte a StrongBox */

    /** Decripta blob Base64 usando BiometricPrompt */
    // fun decryptWithBiometric(
    //     activity: FragmentActivity,
    //     encryptedBase64: String,
    //     onSuccess: (String) -> Unit,
    //     onError: (String) -> Unit
    // ) {
    //     try {
    //         android.util.Log.d("SECURE", "Starting decryption process")
    //         android.util.Log.d("SECURE", "Encrypted blob to decrypt: $encryptedBase64")

    //         val keyStore = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }

    //         // Verificar se a chave existe
    //         if (!keyStore.containsAlias(KEY_ALIAS)) {
    //             return onError("Key alias not found in KeyStore. Please re-register device.")
    //         }

    //         val privateKey = keyStore.getKey(KEY_ALIAS, null)
    //             ?: return onError("Private key not found; re-register device")

    //         android.util.Log.d("SECURE", "Private key found, algorithm: ${privateKey.algorithm}")

    //         // Verificar tamanho do blob
    //         val encryptedBytes = Base64.decode(encryptedBase64, Base64.DEFAULT)
    //         if (encryptedBytes.size != 256) {
    //             return onError("Invalid encrypted blob size: ${encryptedBytes.size} (expected
    // 256)")
    //         }

    //         // 🔥 USANDO PKCS1 que é o que o servidor está enviando
    //         val cipher = Cipher.getInstance("RSA/ECB/PKCS1Padding")
    //         android.util.Log.d("SECURE", "Cipher created: ${cipher.algorithm}")
    //         cipher.init(Cipher.DECRYPT_MODE, privateKey)
    //         android.util.Log.d("SECURE", "Cipher initialized for DECRYPT_MODE")

    //         val cryptoObject = BiometricPrompt.CryptoObject(cipher)
    //         val promptInfo = BiometricPrompt.PromptInfo.Builder()
    //             .setTitle("Authenticate to access secret")
    //             .setSubtitle("Use biometric authentication")
    //             .setNegativeButtonText("Cancel")
    //             .build()

    //         val biometricPrompt = BiometricPrompt(activity, { it.run() }, object :
    //             BiometricPrompt.AuthenticationCallback() {

    //             override fun onAuthenticationSucceeded(result:
    // BiometricPrompt.AuthenticationResult) {
    //                 try {
    //                     val authenticatedCipher = result.cryptoObject?.cipher
    //                         ?: throw IllegalStateException("Cipher missing after auth")

    //                     android.util.Log.d("SECURE", "Decrypting blob: $encryptedBase64")
    //                     val encrypted = Base64.decode(encryptedBase64, Base64.DEFAULT)
    //                     android.util.Log.d("SECURE", "Encrypted bytes length: ${encrypted.size}")

    //                     val plain = authenticatedCipher.doFinal(encrypted)
    //                     android.util.Log.d("SECURE", "Decrypted bytes length: ${plain.size}")

    //                     val secret = String(plain, StandardCharsets.UTF_8)
    //                     android.util.Log.d("SECURE", "Secret decrypted successfully: $secret")
    //                     onSuccess(secret)
    //                 } catch (e: Exception) {
    //                     android.util.Log.e("SECURE", "Decryption error", e)
    //                     onError("Decryption failed: ${e::class.simpleName}:
    // ${e.message}\n${e.stackTraceToString().take(500)}")
    //                 }
    //             }

    //             override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
    //                 onError("Authentication error: $errString")
    //             }
    //         })

    //         biometricPrompt.authenticate(promptInfo, cryptoObject)
    //     } catch (e: Exception) {
    //         android.util.Log.e("SECURE", "Failed to init decryption", e)
    //         onError("Failed to init decryption: ${e::class.simpleName}:
    // ${e.message}\n${e.stackTraceToString().take(500)}")
    //     }
    // }

    private fun isStrongBoxAvailable(context: Context): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            context.packageManager.hasSystemFeature(PackageManager.FEATURE_STRONGBOX_KEYSTORE)
        } else false
    }

    private fun createPairKey(context: Context): Unit {
        android.util.Log.d("SECURE", "Key alias not found, generating new KeyPair...")
        val kpg = KeyPairGenerator.getInstance(KeyProperties.KEY_ALGORITHM_RSA, ANDROID_KEYSTORE)
        val builder =
                KeyGenParameterSpec.Builder(KEY_ALIAS, KeyProperties.PURPOSE_DECRYPT).apply {
                    setDigests(KeyProperties.DIGEST_SHA256, KeyProperties.DIGEST_SHA1)
                    // 🔥 SUPORTA TANTO OAEP QUANTO PKCS1 (igual à chave de teste)
                    setEncryptionPaddings(
                            KeyProperties.ENCRYPTION_PADDING_RSA_OAEP,
                            KeyProperties.ENCRYPTION_PADDING_RSA_PKCS1
                    )
                    setKeySize(2048)
                    // setUserAuthenticationRequired(true)
                    // 🔥 VOLTA PARA AUTENTICAÇÃO A CADA USO (sem timeout)
                    // setUserAuthenticationValidityDurationSeconds(30) // REMOVIDO
                }

        // StrongBox apenas se disponível
        if (isStrongBoxAvailable(context) && Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            try {
                builder.setIsStrongBoxBacked(true)
                android.util.Log.d("SECURE", "StrongBox enabled")
            } catch (e: Exception) {
                android.util.Log.d("SECURE", "StrongBox not available: ${e.message}")
            }
        }

        kpg.initialize(builder.build())
        kpg.generateKeyPair()
        android.util.Log.d("SECURE", "KeyPair generated successfully")
    }

    /** Gera KeyPair se não existir e retorna public key Base64 */
    fun ensureKeyPairAndGetPublicKeyBase64(context: Context): String {
        val keyStore = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }

        if (!keyStore.containsAlias(KEY_ALIAS)) {
            createPairKey(context)
        } else {
            android.util.Log.d("SECURE", "KeyPair already exists, using existing key")
        }

        val publicKey = keyStore.getCertificate(KEY_ALIAS).publicKey
        val publicKeyBase64 = Base64.encodeToString(publicKey.encoded, Base64.NO_WRAP)
        android.util.Log.d("SECURE", "Public key (first 50 chars): ${publicKeyBase64.take(50)}...")
        return publicKeyBase64
    }

    /** Versão sem biometria */
    fun descriptBase64(
            encryptedBase64: String,
    ): String {
        android.util.Log.d("SECURE", "=== TEST DECRYPT WITHOUT BIOMETRIC ===")

        val keyStore = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }

        // Usar a CHAVE PRINCIPAL gerada durante o registro (mesmo par usado pelo servidor)
        val privateKey =
                keyStore.getKey(KEY_ALIAS, null)
                        ?: throw Exception(
                                "Private key not found - ensure key pair exists and device is registered"
                        )

        android.util.Log.d("SECURE", "Test private key algorithm: ${privateKey.algorithm}")
        android.util.Log.d("SECURE", "Test private key format: ${privateKey.format}")

        // Teste diferentes configurações de Cipher - PKCS1 primeiro (compatível com servidor)
        val cipherConfigs =
                listOf(
                        "RSA/ECB/PKCS1Padding", // ← PRIMEIRO: compatível com servidor
                        "RSA/ECB/OAEPPadding", // OAEP com configuração padrão
                        "RSA/ECB/OAEPWithSHA-256AndMGF1Padding",
                        "RSA/ECB/OAEPWithSHA-1AndMGF1Padding",
                        "RSA/None/OAEPWithSHA1AndMGF1Padding",
                        "RSA/None/OAEPWithSHA256AndMGF1Padding"
                )

        val encrypted = Base64.decode(encryptedBase64, Base64.DEFAULT)
        android.util.Log.d("SECURE", "Encrypted bytes size: ${encrypted.size}")
        android.util.Log.d(
                "SECURE",
                "First 10 bytes: ${encrypted.take(10).map { "%02x".format(it) }}"
        )

        var exception: Exception? = null

        var resultDecripted: String = ""

        for (cipherConfig in cipherConfigs) {
            try {
                android.util.Log.d("SECURE", "Trying cipher: $cipherConfig")
                val cipher = Cipher.getInstance(cipherConfig)
                cipher.init(Cipher.DECRYPT_MODE, privateKey)

                val plain = cipher.doFinal(encrypted)
                val result = String(plain, StandardCharsets.UTF_8)
                android.util.Log.d("SECURE", "✅ SUCCESS with $cipherConfig: $result")
                resultDecripted = result
                break
            } catch (e: Exception) {
                android.util.Log.d(
                        "SECURE",
                        "❌ FAILED with $cipherConfig: ${e::class.simpleName}: ${e.message}"
                )
                exception = e
            }
        }

        if (exception != null) {
            return ""
        } else {
            return resultDecripted
        }
    }

    /** Debug: Retorna informações da chave pública para comparar com servidor */
    // fun getKeyDebugInfo(context: Context): Map<String, Any> {
    //     try {
    //         val keyStore = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }

    //         // Se não tem chave, gera uma
    //         if (!keyStore.containsAlias(KEY_ALIAS)) {
    //             android.util.Log.d("SECURE", "No key found, generating new one for debug...")
    //             ensureKeyPairAndGetPublicKeyBase64(context)
    //         }

    //         val certificate = keyStore.getCertificate(KEY_ALIAS)
    //         if (certificate == null) {
    //             return mapOf<String, Any>(
    //                 "error" to "No certificate found after generation",
    //                 "hasAlias" to keyStore.containsAlias(KEY_ALIAS)
    //             )
    //         }

    //         val publicKey = certificate.publicKey
    //         val publicKeyBase64 = Base64.encodeToString(publicKey.encoded, Base64.NO_WRAP)

    //         val keySize = try {
    //             (publicKey as? java.security.interfaces.RSAPublicKey)?.modulus?.bitLength() ?:
    // "unknown"
    //         } catch (e: Exception) {
    //             "error: ${e.message}"
    //         }

    //         return mapOf<String, Any>(
    //             "algorithm" to publicKey.algorithm,
    //             "format" to (publicKey.format ?: "unknown"),
    //             "keySize" to keySize,
    //             "publicKeyBase64" to publicKeyBase64,
    //             "publicKeyLength" to publicKeyBase64.length,
    //             "hasStrongBox" to isStrongBoxAvailable(context),
    //             "aliasExists" to keyStore.containsAlias(KEY_ALIAS)
    //         )
    //     } catch (e: Exception) {
    //         android.util.Log.e("SECURE", "Error in getKeyDebugInfo", e)
    //         return mapOf<String, Any>(
    //             "error" to "${e::class.simpleName}: ${e.message}",
    //             "stackTrace" to e.stackTraceToString().take(300)
    //         )
    //     }
    // }
}
