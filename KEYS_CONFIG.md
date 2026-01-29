# 🔐 KEYS & CONFIGURACIÓN - FIX & GO INNOVATIONS

> ⚠️ **DOCUMENTO CONFIDENCIAL - NUNCA SUBIR A GITHUB**

---

## 🔑 SUPABASE

### URLs Base
```
URL: https://wmznnnvgyqzjqzvuvzya.supabase.co
```

### Keys (DEV)
```
ANON_KEY: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SERVICE_ROLE_KEY: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Ubicación en código
- `.env` → `SUPABASE_URL` y `SUPABASE_ANON_KEY`
- `lib/core/supabase_client.dart` → Inicialización
- `pubspec.yaml` → `supabase_flutter: ^1.10.0`

### Variables de entorno (.env)
```env
SUPABASE_URL=https://wmznnnvgyqzjqzvuvzya.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
FLUTTER_ENV=development
```

---

## 📧 SMTP (EMAIL - GMAIL)

### Configuración Supabase Auth Email

**Email:** `geanatoponce@gmail.com`  
**App Password:** `xxxx xxxx xxxx xxxx` (16 caracteres con espacios)

### Servidor SMTP
```
Host: smtp.gmail.com
Port: 587
Encryption: TLS
Username: geanatoponce@gmail.com
Password: [app-password-de-google]
```

### Ubicación en código
```dart
// lib/services/auth_service.dart - Línea 18-20
final AuthResponse authResponse = await _supabase.auth.signUp(
  email: user.email,
  password: password,
  emailRedirectTo: 'https://deep-links-gofix.netlify.app/confirm-email',
);
```

### URLs de redirect
```
Para confirmación: https://deep-links-gofix.netlify.app/confirm-email?token=XXX&type=signup
Para reset: https://deep-links-gofix.netlify.app/reset-password?token=XXX&type=recovery
```

---

## 💳 BRAINTREE PAYMENT

### API Keys
```
Environment: Sandbox (desarrollo)
Merchant ID: [merchant-id]
Public Key: [public-key]
Private Key: [private-key]
```

### Ubicación en código
```dart
// lib/services/payment_service.dart
static const String BRAINTREE_MERCHANT_ID = '[merchant-id]';
static const String BRAINTREE_PUBLIC_KEY = '[public-key]';
```

### Cliente Token
```dart
// Se obtiene dinamicamente en: 
// lib/services/payment_service.dart -> generateClientToken()
```

---

## 🌐 DEEP LINKING - URLS

### Netlify Domain
```
Domain: https://deep-links-gofix.netlify.app
Status: ✅ Activo
assetlinks.json: /.well-known/assetlinks.json
```

### Rutas configuradas
```
Reset Password:
  HTTPS: https://deep-links-gofix.netlify.app/reset-password?token=ABC&type=recovery
  Custom: fixgo://reset-password?token=ABC

Confirm Email:
  HTTPS: https://deep-links-gofix.netlify.app/confirm-email?token=ABC&type=signup
  Custom: fixgo://confirm-email?token=ABC
```

### Android Configuration
```xml
<!-- Ubicación: android/app/src/main/AndroidManifest.xml -->
<data android:scheme="https" 
      android:host="deep-links-gofix.netlify.app"
      android:pathPrefix="/reset-password" />
<data android:scheme="https" 
      android:host="deep-links-gofix.netlify.app"
      android:pathPrefix="/confirm-email" />
<data android:scheme="fixgo" android:host="reset-password" />
<data android:scheme="fixgo" android:host="confirm-email" />
```

---

## 📱 ANDROID KEYSTORE

### Para Desarrollo (debug.keystore)
```
Ubicación: android/app/debug.keystore
Contraseña: android
Alias: androiddebugkey
```

### Para Producción (release.keystore)
```
Ubicación: android/app/release.keystore
Contraseña: [secura-passphrase]
Alias: fix-go-key
SHA-256: [fingerprint-release]
```

### Generar SHA-256 (para assetlinks.json)
```bash
cd android/app
keytool -list -v -keystore release.keystore -alias fix-go-key
# Copiar el SHA-256
```

---

## 🎯 CONFIGURACIÓN POR AMBIENTE

### DEVELOPMENT
```env
FLUTTER_ENV=development
SUPABASE_URL=https://wmznnnvgyqzjqzvuvzya.supabase.co
DEEP_LINK_DOMAIN=https://deep-links-gofix.netlify.app
BRAINTREE_ENV=SANDBOX
```

### PRODUCTION
```env
FLUTTER_ENV=production
SUPABASE_URL=https://wmznnnvgyqzjqzvuvzya.supabase.co
DEEP_LINK_DOMAIN=https://deep-links-gofix.netlify.app
BRAINTREE_ENV=PRODUCTION (cambiar cuando esté listo)
```

---

## 📋 TABLAS SUPABASE

### Esquema Principal
```
1. auth.users (Supabase Auth)
   - email, password hash, email_confirmed_at, metadata

2. public.users
   - id, email, full_name, phone, photo_url, user_type (client|technician|admin)

3. public.service_requests
   - id, client_id, title, description, location, status, created_at

4. public.service_request_images
   - id, request_id, image_url, uploaded_at

5. public.quotations
   - id, request_id, technician_id, price, description, status, created_at

6. public.accepted_works
   - id, quotation_id, client_id, technician_id, status (pending_payment|in_progress|completed)
   - client_confirmed_chat, technician_confirmed_chat, payment_status

7. public.chat_messages
   - id, work_id, sender_id, message_text, message_type (text|image|document)
   - is_read, read_at, created_at

8. public.payments
   - id, work_id, amount, payment_method, transaction_id, status, created_at

9. public.ratings
   - id, work_id, rated_by, rated_user, rating (1-5), comment, created_at
```

---

## 🔒 PERMISOS & POLÍTICAS

### Row Level Security (RLS) en Supabase
```sql
-- Users: Solo puede ver su propio perfil
SELECT * FROM users WHERE id = auth.uid()

-- Service Requests: Solo cliente y técnicos asignados
SELECT * FROM service_requests 
WHERE client_id = auth.uid() 
   OR id IN (SELECT request_id FROM quotations WHERE technician_id = auth.uid())

-- Chat Messages: Solo participantes del trabajo
SELECT * FROM chat_messages 
WHERE work_id IN (
  SELECT id FROM accepted_works 
  WHERE client_id = auth.uid() OR technician_id = auth.uid()
)

-- Payments: Solo financiero y usuarios del trabajo
SELECT * FROM payments 
WHERE work_id IN (
  SELECT id FROM accepted_works 
  WHERE client_id = auth.uid() OR technician_id = auth.uid()
)
```

---

## 🚨 CHECKLIST DE SEGURIDAD

- [ ] Keys de Supabase NO están en código (están en .env)
- [ ] .env está en .gitignore
- [ ] App Password de Gmail NO está en código
- [ ] Braintree keys están en environment variables
- [ ] RLS está habilitado en todas las tablas
- [ ] Solo autenticados pueden acceder a datos
- [ ] Las contraseñas se hashean en Supabase
- [ ] Los tokens OTP expiran en < 1 hora
- [ ] Email confirmations habilitadas
- [ ] Rate limiting en login (5 intentos)

---

## 📞 REFERENCIAS RÁPIDAS

**Generar OTP:**
```dart
await _supabase.auth.signInWithOtp(email: email);
```

**Verificar OTP:**
```dart
await _supabase.auth.verifyOTP(
  token: token,
  type: OtpType.recovery, // recovery o signup
  email: email,
);
```

**Enviar email reset:**
```dart
await _supabase.auth.resetPasswordForEmail(email);
```

**Upload a Storage:**
```dart
await _supabase.storage.from('bucket_name').upload('path/file', data);
```

---

**⚠️ IMPORTANTE:** Este archivo NO debe ser versionado. Está en `.gitignore`.

