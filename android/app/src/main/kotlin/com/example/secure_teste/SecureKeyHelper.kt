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

    /** Remove the key from KeyStore (useful for reset/debug) */
    fun deleteKey() {
        try {
            val keyStore = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }
            if (keyStore.containsAlias(KEY_ALIAS)) {
                keyStore.deleteEntry(KEY_ALIAS)
            }
            android.util.Log.d("SECURE", "Key alias removed from KeyStore")
        } catch (e: Exception) {
            android.util.Log.e("SECURE", "Error deleting key", e)
        }
    }

    private fun isStrongBoxAvailable(context: Context): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            context.packageManager.hasSystemFeature(PackageManager.FEATURE_STRONGBOX_KEYSTORE)
        } else false
    }

    private fun createPairKey(context: Context) {
        android.util.Log.d("SECURE", "Key alias not found, generating new KeyPair...")
        val kpg = KeyPairGenerator.getInstance(KeyProperties.KEY_ALGORITHM_RSA, ANDROID_KEYSTORE)
        val builder =
                KeyGenParameterSpec.Builder(KEY_ALIAS, KeyProperties.PURPOSE_DECRYPT).apply {
                    setDigests(KeyProperties.DIGEST_SHA256, KeyProperties.DIGEST_SHA1)
                    setEncryptionPaddings(
                            KeyProperties.ENCRYPTION_PADDING_RSA_OAEP,
                            KeyProperties.ENCRYPTION_PADDING_RSA_PKCS1
                    )
                    setKeySize(2048)
                }

        // Enable StrongBox if available for enhanced security
        if (isStrongBoxAvailable(context) && Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            try {
                builder.setIsStrongBoxBacked(true)
                android.util.Log.d("SECURE", "StrongBox enabled for enhanced security")
            } catch (e: Exception) {
                android.util.Log.d("SECURE", "StrongBox not available: ${e.message}")
            }
        }

        kpg.initialize(builder.build())
        kpg.generateKeyPair()
        android.util.Log.d("SECURE", "KeyPair generated successfully")
    }

    /** Generate KeyPair if it doesn't exist and return public key in Base64 */
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

    /** Decrypt Base64 encrypted secret without biometric authentication (for testing) */
    fun descriptBase64(encryptedBase64: String): String {
        android.util.Log.d("SECURE", "=== DECRYPT WITHOUT BIOMETRIC ===")

        val keyStore = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }

        val privateKey =
                keyStore.getKey(KEY_ALIAS, null)
                        ?: throw Exception(
                                "Private key not found - ensure key pair exists and device is registered"
                        )

        android.util.Log.d("SECURE", "Private key algorithm: ${privateKey.algorithm}")
        android.util.Log.d("SECURE", "Private key format: ${privateKey.format}")

        // Try different cipher configurations - PKCS1 first (compatible with server)
        val cipherConfigs =
                listOf(
                        "RSA/ECB/PKCS1Padding",
                        "RSA/ECB/OAEPPadding",
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

        for (cipherConfig in cipherConfigs) {
            try {
                android.util.Log.d("SECURE", "Trying cipher: $cipherConfig")
                val cipher = Cipher.getInstance(cipherConfig)
                cipher.init(Cipher.DECRYPT_MODE, privateKey)

                val plain = cipher.doFinal(encrypted)
                val result = String(plain, StandardCharsets.UTF_8)
                android.util.Log.d("SECURE", "✅ SUCCESS with $cipherConfig: $result")
                return result
            } catch (e: Exception) {
                android.util.Log.d(
                        "SECURE",
                        "❌ FAILED with $cipherConfig: ${e::class.simpleName}: ${e.message}"
                )
            }
        }

        throw Exception("Failed to decrypt with any cipher configuration")
    }
}
