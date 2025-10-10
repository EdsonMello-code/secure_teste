# 🚀 Quick Start Guide - Secure Device Registration

## 📋 **Resumo da Técnica**

Esta implementação demonstra como proteger segredos sensíveis em dispositivos móveis usando:
- 🔐 **RSA + Android KeyStore** (hardware-backed)
- 👆 **Autenticação biométrica** obrigatória
- 🌐 **Servidor stateless** (não armazena segredos por dispositivo)

## ⚡ **Setup Rápido (5 minutos)**

### 1️⃣ **Servidor**
```bash
# Instalar dependências
npm install express

# Iniciar servidor
node server_minimal.js
```
*Servidor rodará na porta 3000*

### 2️⃣ **Flutter App**
```bash
# Adicionar dependências
flutter pub add flutter_secure_storage http

# Substituir main.dart
cp lib/main_minimal.dart lib/main.dart

# IMPORTANTE: Atualizar IP do servidor no código
# Linha 108: 'http://SEU_IP:3000'

# Rodar app
flutter run
```

### 3️⃣ **Android KeyStore Helper**
```bash
# Copiar helper para projeto
cp android/app/src/main/kotlin/.../SecureKeyHelperMinimal.kt .
cp android/app/src/main/kotlin/.../MainActivityMinimal.kt .

# Atualizar imports no MainActivity
```

---

## 🎯 **Teste da Implementação**

1. **📱 Register Device**: Gera chave RSA + envia para servidor
2. **🔓 Get Secret**: Autentica biometria + decripta segredo  
3. **🗑️ Reset Device**: Limpa chaves + recomeça processo

---

## 🔍 **Verificação de Segurança**

### ✅ **Checklist de Funcionamento**
- [ ] Chave RSA gerada no Android KeyStore
- [ ] Servidor recebe chave pública
- [ ] Segredo criptografado com PKCS1
- [ ] Blob armazenado localmente (criptografado)
- [ ] Biometria solicita autenticação
- [ ] Segredo descriptografado com sucesso

### 🔐 **Verificação de Logs**
```bash
# Android logs
adb logcat -s SecureKeyHelper

# Servidor logs
node server_minimal.js
# Deve mostrar: "Secret encrypted successfully"
```

---

## 📊 **Arquivos da Implementação**

```
projeto/
├── 📱 Flutter
│   ├── lib/main_minimal.dart              # App completo
│   └── lib/secure_service.dart            # Service isolado
├── 🤖 Android  
│   ├── SecureKeyHelperMinimal.kt          # Crypto + biometria
│   └── MainActivityMinimal.kt             # Bridge Flutter
├── 🌐 Servidor
│   └── server_minimal.js                  # Node.js server
└── 📚 Docs
    ├── README_SECURE_TECHNIQUE.md         # Documentação completa
    └── QUICK_START.md                     # Este arquivo
```

---

## 🛠️ **Customização**

### **Mudar o segredo protegido:**
```javascript
// server_minimal.js linha 16
const SENSITIVE_SECRET = "SEU_SEGREDO_AQUI";
```

### **Configurar servidor:**
```javascript
// Mudar porta
const PORT = 8080;

// Adicionar HTTPS
app.use(express.static('public'));
```

### **Customizar biometria:**
```kotlin
// SecureKeyHelperMinimal.kt
.setTitle("Seu Título Personalizado")
.setSubtitle("Sua mensagem")
```

---

## ⚠️ **Troubleshooting**

### **❌ "No public key obtained"**
- Verificar se dispositivo tem biometria configurada
- Testar em dispositivo real (não emulador)
- Limpar storage: `flutter clean`

### **❌ "Server registration failed"**
- Verificar IP do servidor no código
- Confirmar que servidor está rodando
- Testar: `curl http://SEU_IP:3000/health`

### **❌ "Authentication failed"**
- Configurar biometria no dispositivo
- Tentar diferentes tipos (digital, face, etc.)
- Verificar logs: `adb logcat -s BiometricPrompt`

---

## 🔒 **Segurança em Produção**

### **Obrigatório implementar:**
- 🌐 **HTTPS**: Nunca usar HTTP em produção
- 📱 **Certificate pinning**: Prevenir MITM
- 🔐 **Key attestation**: Verificar integridade do hardware
- 📊 **Logging**: Monitorar tentativas de acesso

### **Opcional (mais segurança):**
- 🔄 **Key rotation**: Renovar chaves periodicamente
- 🛡️ **Rate limiting**: Limitar tentativas de registro
- 📍 **Geolocation**: Validar localização do dispositivo
- ⏰ **TTL**: Expirar segredos após tempo definido

---

## 📈 **Casos de Uso Reais**

- 🏦 **Banking**: API keys para transações
- 🏥 **Healthcare**: Chaves de acesso a dados médicos  
- 🏢 **Enterprise**: Certificados corporativos
- 🔐 **Auth**: Tokens de autenticação
- 📱 **IoT**: Device-to-device pairing

---

*💡 Esta implementação segue padrões de segurança usados por apps bancários e empresariais críticos.*