# 🌐 URLs & ENDPOINTS - FIX & GO INNOVATIONS

---

## 🔗 DEEP LINKING

### Domain Principal
```
https://deep-links-gofix.netlify.app
```

### Rutas Configuradas

#### 1. Reset de Contraseña
**HTTPS:**
```
https://deep-links-gofix.netlify.app/reset-password?token=ABC123&type=recovery&email=user@email.com
```

**Custom Scheme:**
```
fixgo://reset-password?token=ABC123&type=recovery
```

**Parámetros:**
- `token` (string) - Token OTP de Supabase
- `type` (string) - Siempre "recovery" para reset
- `email` (string, opcional) - Email del usuario

**Manejador en App:**
```dart
// lib/main.dart - GoRoute /reset-password
GoRoute(
  path: '/reset-password',
  builder: (context, state) {
    final token = state.uri.queryParameters['token'] ?? '';
    final type = state.uri.queryParameters['type'] ?? 'recovery';
    return ResetPasswordScreen(token: token, type: type, isDeepLink: true);
  },
)
```

---

#### 2. Confirmación de Email
**HTTPS:**
```
https://deep-links-gofix.netlify.app/confirm-email?token=XYZ789&type=signup&email=user@email.com
```

**Custom Scheme:**
```
fixgo://confirm-email?token=XYZ789&type=signup
```

**Parámetros:**
- `token` (string) - Token OTP de Supabase
- `type` (string) - Siempre "signup" para email confirmation
- `email` (string, opcional) - Email del usuario

**Manejador en App:**
```dart
// lib/main.dart - GoRoute /confirm-email
GoRoute(
  path: '/confirm-email',
  builder: (context, state) {
    final token = state.uri.queryParameters['token'] ?? '';
    final type = state.uri.queryParameters['type'] ?? 'signup';
    return EmailVerificationScreen(token: token, type: type, isDeepLink: true);
  },
)
```

---

### Android Configuration
```xml
<!-- android/app/src/main/AndroidManifest.xml -->

<!-- Intent Filter HTTPS (App Links) -->
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    
    <!-- Reset Password -->
    <data
        android:scheme="https"
        android:host="deep-links-gofix.netlify.app"
        android:pathPrefix="/reset-password" />
    
    <!-- Confirm Email -->
    <data
        android:scheme="https"
        android:host="deep-links-gofix.netlify.app"
        android:pathPrefix="/confirm-email" />
</intent-filter>

<!-- Intent Filter Custom Scheme (fixgo://) -->
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="fixgo" android:host="reset-password" />
    <data android:scheme="fixgo" android:host="confirm-email" />
</intent-filter>
```

---

## 🔐 SUPABASE ENDPOINTS

### Base URL
```
https://wmznnnvgyqzjqzvuvzya.supabase.co
```

### API Endpoints

#### Authentication
```
POST   /auth/v1/signup                    → Registrar usuario
POST   /auth/v1/token?grant_type=password → Login
POST   /auth/v1/logout                    → Logout
POST   /auth/v1/user                      → Get usuario actual
POST   /auth/v1/user/email                → Cambiar email
POST   /auth/v1/user/password             → Cambiar contraseña
POST   /auth/v1/recover                   → Solicitar reset
POST   /auth/v1/verify                    → Verificar token OTP
```

#### Database (REST)
```
GET    /rest/v1/users                     → Listar usuarios
GET    /rest/v1/users?id=eq.UUID          → Usuario específico
POST   /rest/v1/users                     → Crear usuario
PATCH  /rest/v1/users?id=eq.UUID          → Actualizar usuario
DELETE /rest/v1/users?id=eq.UUID          → Eliminar usuario

GET    /rest/v1/service_requests          → Listar solicitudes
GET    /rest/v1/quotations                → Listar cotizaciones
GET    /rest/v1/accepted_works            → Listar trabajos aceptados
GET    /rest/v1/chat_messages             → Listar mensajes
GET    /rest/v1/payments                  → Listar pagos
GET    /rest/v1/ratings                   → Listar calificaciones
```

#### Storage
```
GET    /storage/v1/object/public/{bucket}/{file}  → Descargar archivo
POST   /storage/v1/object/{bucket}/{path}         → Subir archivo
DELETE /storage/v1/object/{bucket}/{path}         → Eliminar archivo
```

#### Real-time (WebSocket)
```
wss://wmznnnvgyqzjqzvuvzya.supabase.co/realtime/v1
  → Suscripción a cambios en tiempo real
  → Usado por: Chat messages, Work confirmations
```

### Headers Requeridos
```
Authorization: Bearer {JWT_TOKEN}
apikey: {ANON_KEY}
Content-Type: application/json
```

---

## 💳 BRAINTREE ENDPOINTS

### URLs Base
```
Sandbox:    https://api.sandbox.braintreegateway.com
Production: https://api.braintreegateway.com
```

### Endpoints Principales
```
GET    /merchants/{MERCHANT_ID}/client_token              → Generar token cliente
POST   /merchants/{MERCHANT_ID}/transactions              → Crear transacción
GET    /merchants/{MERCHANT_ID}/transactions/{ID}        → Ver transacción
POST   /merchants/{MERCHANT_ID}/transactions/{ID}/void   → Cancelar transacción
POST   /merchants/{MERCHANT_ID}/transactions/{ID}/refund → Reembolsar
```

### Drop-in UI (Flutter)
```dart
// lib/services/payment_service.dart
final clientToken = await generateClientToken();
// Pasar token a Braintree Drop-in UI
```

---

## 📬 EMAIL TEMPLATES

### Reset Password Email
**Template:** `password_reset`
```
De: geanatoponce@gmail.com
Asunto: Recupera tu contraseña en Fix&Go Innovations
Link: {{ .ConfirmationURL }}
→ Se convierte en:
   https://deep-links-gofix.netlify.app/reset-password?token=XXX&type=recovery
```

### Email Confirmation
**Template:** `confirmation`
```
De: geanatoponce@gmail.com
Asunto: Confirma tu email en Fix&Go Innovations
Link: {{ .ConfirmationURL }}
→ Se convierte en:
   https://deep-links-gofix.netlify.app/confirm-email?token=XXX&type=signup
```

---

## 🚀 RUTAS DISPONIBLES (GoRouter)

```dart
// lib/main.dart - Router configuration

GoRoute(path: '/',                  → LoginScreen)
GoRoute(path: '/login',             → LoginScreen)
GoRoute(path: '/forgot-password',   → ForgotPasswordScreen)
GoRoute(path: '/reset-password',    → ResetPasswordScreen + deep link)
GoRoute(path: '/confirm-email',     → EmailVerificationScreen + deep link)
GoRoute(path: '/change-password',   → ChangePasswordScreen)
GoRoute(path: '/help-support',      → HelpSupportScreen)
```

---

## 📊 FLUJO DE URLs

### Flujo 1: Nuevo Usuario - Registro
```
1. Usuario toca "Registrarse"
   ↓
2. Pantalla: SignupScreen
   ↓
3. Ingresa: email, password, nombre, tipo (cliente/técnico)
   ↓
4. App llama: AuthService.register()
   ↓
5. Supabase envía email a: geanatoponce@gmail.com
   ↓
6. Email contiene link:
   https://deep-links-gofix.netlify.app/confirm-email?token=ABC&type=signup
   ↓
7. Usuario toca link en email
   ↓
8. Android intent-filter intercepta
   ↓
9. GoRouter navega a: /confirm-email?token=ABC
   ↓
10. EmailVerificationScreen recibe token
   ↓
11. App verifica token: verifyOTP(token: token, type: OtpType.signup)
   ↓
12. ✅ Email confirmado → Redirige a /login
```

---

### Flujo 2: Usuario Olvida Contraseña
```
1. Usuario en LoginScreen toca "Olvidé mi contraseña"
   ↓
2. Navega a: /forgot-password
   ↓
3. ForgotPasswordScreen pide email
   ↓
4. App llama: AuthService.resetPasswordForEmail(email)
   ↓
5. Supabase genera OTP y envía email
   ↓
6. Email contiene link:
   https://deep-links-gofix.netlify.app/reset-password?token=XYZ&type=recovery
   ↓
7. Usuario toca link
   ↓
8. Android intercepta y GoRouter navega a: /reset-password?token=XYZ
   ↓
9. ResetPasswordScreen recibe token
   ↓
10. App verifica token: verifyOTP(token: token, type: OtpType.recovery)
   ↓
11. Usuario ingresa nueva contraseña
   ↓
12. App llama: AuthService.resetPassword(email, token, newPassword)
   ↓
13. ✅ Contraseña actualizada → Redirige a /login
```

---

## 🔒 QUERY PARAMETERS

### En Deep Links
```
Formato: https://domain/path?param1=value1&param2=value2

Reset Password:
  ?token=XXX&type=recovery&email=user@example.com

Confirm Email:
  ?token=YYY&type=signup&email=user@example.com
```

### Extracción en Flutter
```dart
// GoRouter extrae automáticamente
final token = state.uri.queryParameters['token'] ?? '';
final type = state.uri.queryParameters['type'] ?? '';
final email = state.uri.queryParameters['email'] ?? '';
```

---

## 🔍 Verificar URLs Funcionando

### Android - Probar Deep Link
```bash
# Reset Password
adb shell am start -W -a android.intent.action.VIEW \
  -d "https://deep-links-gofix.netlify.app/reset-password?token=test123&type=recovery" \
  com.fixgo.innovations

# Confirm Email
adb shell am start -W -a android.intent.action.VIEW \
  -d "fixgo://confirm-email?token=test456&type=signup" \
  com.fixgo.innovations
```

### Verificar assetlinks.json
```bash
# Verificar que está accesible
curl https://deep-links-gofix.netlify.app/.well-known/assetlinks.json

# Debe retornar JSON con:
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.fixgo.innovations",
    "sha256_cert_fingerprints": ["AA:BB:CC:..."]
  }
}]
```

---

## 📋 Resumen de URLs

| Componente | URL |
|-----------|-----|
| Base Netlify | https://deep-links-gofix.netlify.app |
| Reset Password | /reset-password?token=X&type=recovery |
| Confirm Email | /confirm-email?token=X&type=signup |
| assetlinks.json | /.well-known/assetlinks.json |
| Custom Scheme | fixgo://reset-password o fixgo://confirm-email |
| Supabase API | https://wmznnnvgyqzjqzvuvzya.supabase.co/rest/v1 |
| Braintree Sandbox | https://api.sandbox.braintreegateway.com |

---

**✅ URLs documentadas: 30+**

