const express = require('express');
const bodyParser = require('body-parser');
const crypto = require('crypto');

const app = express();
app.use(bodyParser.json({ limit: '1mb' }));

// Secret to protect per device
const SECRET_TO_PROTECT = "Super sensivel key";
const PORT = 3000;

/**
 * Convert Base64 from Android (DER format) to PEM
 */
function androidBase64ToPem(androidBase64) {
  const derBytes = Buffer.from(androidBase64, 'base64');
  const base64Lines = derBytes.toString('base64').match(/.{1,64}/g).join('\n');
  return `-----BEGIN PUBLIC KEY-----\n${base64Lines}\n-----END PUBLIC KEY-----\n`;
}

/**
 * Convert raw key from iOS to PEM (X.509 DER format)
 */
function iosRawToPem(rawKeyBase64) {
  const rawKeyBytes = Buffer.from(rawKeyBase64, 'base64');
  console.log('🔧 Raw key bytes length:', rawKeyBytes.length);
  
  // Create X.509 SubjectPublicKeyInfo structure
  const algorithmIdentifier = Buffer.from([
    0x30, 0x0d,              // SEQUENCE
    0x06, 0x09,              // OBJECT IDENTIFIER  
    0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01, 0x01, // rsaEncryption OID
    0x05, 0x00               // NULL
  ]);
  
  // Create BIT STRING for the key
  const bitStringLength = rawKeyBytes.length + 1; // +1 for unused bits
  let bitStringHeader;
  
  if (bitStringLength < 128) {
    bitStringHeader = Buffer.from([0x03, bitStringLength, 0x00]);
  } else if (bitStringLength < 256) {
    bitStringHeader = Buffer.from([0x03, 0x81, bitStringLength, 0x00]);
  } else {
    bitStringHeader = Buffer.from([0x03, 0x82, (bitStringLength >> 8) & 0xFF, bitStringLength & 0xFF, 0x00]);
  }
  
  const bitString = Buffer.concat([bitStringHeader, rawKeyBytes]);
  
  // Create main SEQUENCE
  const contentLength = algorithmIdentifier.length + bitString.length;
  let mainSequenceHeader;
  
  if (contentLength < 128) {
    mainSequenceHeader = Buffer.from([0x30, contentLength]);
  } else if (contentLength < 256) {
    mainSequenceHeader = Buffer.from([0x30, 0x81, contentLength]);
  } else {
    mainSequenceHeader = Buffer.from([0x30, 0x82, (contentLength >> 8) & 0xFF, contentLength & 0xFF]);
  }
  
  const derBytes = Buffer.concat([mainSequenceHeader, algorithmIdentifier, bitString]);
  
  console.log('🔧 Constructed DER length:', derBytes.length);
  
  const base64Lines = derBytes.toString('base64').match(/.{1,64}/g).join('\n');
  return `-----BEGIN PUBLIC KEY-----\n${base64Lines}\n-----END PUBLIC KEY-----\n`;
}

/**
 * Test different encryption configurations (for debugging)
 */
function testEncryptionConfigs(pubPem, data) {
  console.log('\n=== TESTING ENCRYPTION CONFIGS ===');
  
  const configs = [
    { name: 'OAEP-SHA256-MGF1-SHA256', options: { padding: crypto.constants.RSA_PKCS1_OAEP_PADDING, oaepHash: 'sha256', mgf1Hash: 'sha256' } },
    { name: 'OAEP-SHA256-MGF1-SHA1', options: { padding: crypto.constants.RSA_PKCS1_OAEP_PADDING, oaepHash: 'sha256', mgf1Hash: 'sha1' } },
    { name: 'OAEP-SHA1-MGF1-SHA1', options: { padding: crypto.constants.RSA_PKCS1_OAEP_PADDING, oaepHash: 'sha1', mgf1Hash: 'sha1' } },
    { name: 'OAEP-DEFAULT', options: { padding: crypto.constants.RSA_PKCS1_OAEP_PADDING } },
    { name: 'PKCS1', options: { padding: crypto.constants.RSA_PKCS1_PADDING } }
  ];

  const results = [];
  
  for (const config of configs) {
    try {
      console.log(`Trying: ${config.name}`);
      const encrypted = crypto.publicEncrypt({ key: pubPem, ...config.options }, Buffer.from(data, 'utf8'));
      const encryptedBase64 = encrypted.toString('base64');
      
      console.log(`✅ ${config.name}: ${encrypted.length} bytes, Base64 length: ${encryptedBase64.length}`);
      console.log(`   First 20 chars: ${encryptedBase64.substring(0, 20)}`);
      
      results.push({
        name: config.name,
        encryptedBase64,
        size: encrypted.length
      });
    } catch (err) {
      console.log(`❌ ${config.name}: ${err.message}`);
    }
  }
  
  return results;
}

/**
 * Device registration endpoint
 * 
 * Receives the device's public key, encrypts the secret, and returns it
 */
app.post('/register', (req, res) => {
  try {
    const { publicKeyBase64 } = req.body;
    if (!publicKeyBase64) return res.status(400).json({ error: 'publicKeyBase64 required' });

    console.log('\n=== REGISTER REQUEST ===');
    console.log('Public key length:', publicKeyBase64.length);
    console.log('Public key (first 50 chars):', publicKeyBase64.substring(0, 50));
    console.log('Secret to encrypt:', SECRET_TO_PROTECT);
    console.log('Secret length:', SECRET_TO_PROTECT.length);
    
    let pubPem;
    let platformType = 'Android';
    
    // Check if this is iOS raw format
    if (publicKeyBase64.startsWith('IOS_RAW:')) {
      platformType = 'iOS';
      const rawKeyBase64 = publicKeyBase64.substring(8); // Remove "IOS_RAW:" prefix
      console.log('🍎 Detected iOS raw key format');
      console.log('Raw key length:', rawKeyBase64.length);
      
      // Convert iOS raw key to proper PEM format
      pubPem = iosRawToPem(rawKeyBase64);
    } else {
      // Android format
      console.log('🤖 Detected Android DER format');
      pubPem = androidBase64ToPem(publicKeyBase64);
    }
    
    console.log('PEM format (first 100 chars):', pubPem.substring(0, 100));
    console.log('Platform detected:', platformType);

    // (Optional) Log all configurations for diagnostics
    const encryptionResults = testEncryptionConfigs(pubPem, SECRET_TO_PROTECT);

    // Use PKCS1 as the final configuration for the app
    const encrypted = crypto.publicEncrypt(
      { key: pubPem, padding: crypto.constants.RSA_PKCS1_PADDING },
      Buffer.from(SECRET_TO_PROTECT, 'utf8')
    );
    const encryptedBase64 = encrypted.toString('base64');

    console.log('\n=== USING FORCED CONFIG ===');
    console.log('Selected: PKCS1');
    console.log('Encrypted size:', encrypted.length);

    return res.json({ 
      encryptedBase64,
      debug: {
        mode: 'PKCS1',
        allConfigs: encryptionResults,
        secretLength: SECRET_TO_PROTECT.length,
        publicKeyLength: publicKeyBase64.length
      }
    });
  } catch (err) {
    console.error('Encryption error:', err);
    return res.status(500).json({ error: 'server error', detail: err.message });
  }
});

/**
 * Test multiple encryption configurations endpoint
 */
app.post('/test-configs', (req, res) => {
  try {
    const { publicKeyBase64 } = req.body;
    if (!publicKeyBase64) return res.status(400).json({ error: 'publicKeyBase64 required' });

    const pubPem = androidBase64ToPem(publicKeyBase64);
    const encryptionResults = testEncryptionConfigs(pubPem, SECRET_TO_PROTECT);
    
    return res.json({ 
      configs: encryptionResults,
      secret: SECRET_TO_PROTECT 
    });
  } catch (err) {
    console.error('Test configs error:', err);
    return res.status(500).json({ error: 'server error', detail: err.message });
  }
});

/**
 * Simple endpoint to return the secret (for testing only)
 */
app.post('/get-secret', (req, res) => {
  return res.json({ secret: SECRET_TO_PROTECT });
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Debug Server listening on :${PORT}`);
  console.log('Available endpoints:');
  console.log('  POST /register - Normal registration');
  console.log('  POST /test-configs - Test all encryption configs');
  console.log('  POST /get-secret - Get plain secret');
});