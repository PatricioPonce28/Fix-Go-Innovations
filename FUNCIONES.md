# 📋 FUNCIONES PRINCIPALES - FIX & GO INNOVATIONS

---

## 🔐 AuthService (`lib/services/auth_service.dart`)

### 1. **register()**
```dart
Future<Map<String, dynamic>> register(
  UserModel user,
  String password,
  ImageData? profileImageData,
)
```
- **Propósito:** Registrar nuevo usuario (cliente o técnico)
- **Parámetros:**
  - `user` → UserModel con email, fullName, userType, phone
  - `password` → Contraseña (mín 6 caracteres)
  - `profileImageData` → Foto de perfil (opcional)
- **Retorna:** `{success: bool, message: str, emailSent: bool}`
- **Procesa:**
  1. Crea usuario en Supabase Auth
  2. Sube foto a Storage
  3. Crea registro en tabla `users`
  4. Envía email de confirmación
- **Ubicación:** Lines 11-100

---

### 2. **login()**
```dart
Future<Map<String, dynamic>> login(String email, String password)
```
- **Propósito:** Autenticar usuario existente
- **Parámetros:**
  - `email` → Email del usuario
  - `password` → Contraseña
- **Retorna:** `{success: bool, user: UserModel, message: str}`
- **Acciones:**
  - Valida credenciales
  - Verifica email confirmado
  - Retorna datos del usuario
- **Ubicación:** Lines 102-160

---

### 3. **logout()**
```dart
Future<Map<String, dynamic>> logout()
```
- **Propósito:** Cerrar sesión
- **Retorna:** `{success: bool, message: str}`
- **Ubicación:** Lines 162-180

---

### 4. **resetPasswordForEmail()**
```dart
Future<Map<String, dynamic>> resetPasswordForEmail(String email)
```
- **Propósito:** Solicitar reset de contraseña
- **Parámetros:** `email` → Email registrado
- **Retorna:** `{success: bool, message: str}`
- **Flujo:**
  1. Supabase genera token OTP
  2. Envía email con deep link: `https://deep-links-gofix.netlify.app/reset-password?token=XXX&type=recovery`
  3. Usuario hace clic y verifica token
- **Ubicación:** Lines 182-210

---

### 5. **resetPassword()**
```dart
Future<Map<String, dynamic>> resetPassword(
  String email,
  String token,
  String newPassword,
)
```
- **Propósito:** Cambiar contraseña con token OTP
- **Parámetros:**
  - `email` → Email del usuario
  - `token` → Token OTP recibido
  - `newPassword` → Nueva contraseña
- **Retorna:** `{success: bool, message: str}`
- **Ubicación:** Lines 212-250

---

### 6. **verifyOTPToken()**
```dart
Future<Map<String, dynamic>> verifyOTPToken(
  String email,
  String token,
  OtpType type, // recovery o signup
)
```
- **Propósito:** Verificar token OTP (reset o email confirmation)
- **Parámetros:**
  - `email` → Email del usuario
  - `token` → Token OTP
  - `type` → `OtpType.recovery` (reset) o `OtpType.signup` (email)
- **Retorna:** `{success: bool, user: User, message: str}`
- **Ubicación:** Lines 252-290

---

### 7. **resendConfirmationEmail()**
```dart
Future<Map<String, dynamic>> resendConfirmationEmail(String email)
```
- **Propósito:** Reenviar email de confirmación
- **Parámetros:** `email` → Email registrado
- **Retorna:** `{success: bool, message: str}`
- **Ubicación:** Lines 292-320

---

### 8. **updateUserProfile()**
```dart
Future<Map<String, dynamic>> updateUserProfile(
  UserModel updatedUser,
  ImageData? newProfileImage,
)
```
- **Propósito:** Actualizar perfil del usuario
- **Parámetros:**
  - `updatedUser` → Datos actualizados
  - `newProfileImage` → Nueva foto (opcional)
- **Retorna:** `{success: bool, user: UserModel, message: str}`
- **Ubicación:** Lines 322-380

---

### 9. **getCurrentUser()**
```dart
Future<UserModel?> getCurrentUser()
```
- **Propósito:** Obtener usuario autenticado actual
- **Retorna:** `UserModel` o `null` si no autenticado
- **Ubicación:** Lines 382-410

---

### 10. **changePassword()**
```dart
Future<Map<String, dynamic>> changePassword(
  String currentPassword,
  String newPassword,
)
```
- **Propósito:** Cambiar contraseña (con contraseña actual)
- **Parámetros:**
  - `currentPassword` → Contraseña actual
  - `newPassword` → Nueva contraseña
- **Retorna:** `{success: bool, message: str}`
- **Ubicación:** Lines 412-460

---

## 💬 ChatService (`lib/services/chat_service.dart`)

### 1. **sendMessage()**
```dart
Future<Map<String, dynamic>> sendMessage(
  String workId,
  String senderId,
  String messageText,
  String messageType = 'text', // text, image, document
  String? mediaUrl,
)
```
- **Propósito:** Enviar mensaje de chat
- **Parámetros:**
  - `workId` → ID del trabajo
  - `senderId` → ID del remitente
  - `messageText` → Contenido del mensaje
  - `messageType` → Tipo de mensaje
  - `mediaUrl` → URL de media (si es imagen/documento)
- **Retorna:** `{success: bool, messageId: str, createdAt: datetime}`
- **Ubicación:** Lines 20-80

---

### 2. **streamChatMessages()**
```dart
Stream<List<ChatMessageModel>> streamChatMessages(String workId)
```
- **Propósito:** Stream en tiempo real de mensajes
- **Parámetros:** `workId` → ID del trabajo
- **Retorna:** `Stream<List<ChatMessageModel>>`
- **Uso:**
  ```dart
  _chatService.streamChatMessages(workId).listen((messages) {
    setState(() => this.messages = messages);
  });
  ```
- **Ubicación:** Lines 82-130

---

### 3. **markAsRead()**
```dart
Future<void> markAsRead(String messageId, String userId)
```
- **Propósito:** Marcar mensaje como leído
- **Parámetros:**
  - `messageId` → ID del mensaje
  - `userId` → ID del usuario que lee
- **Ubicación:** Lines 132-150

---

### 4. **getUnreadCount()**
```dart
Future<int> getUnreadCount(String workId, String userId)
```
- **Propósito:** Contar mensajes no leídos
- **Parámetros:**
  - `workId` → ID del trabajo
  - `userId` → ID del usuario
- **Retorna:** Cantidad de mensajes no leídos
- **Ubicación:** Lines 152-170

---

### 5. **deleteMessage()**
```dart
Future<Map<String, dynamic>> deleteMessage(String messageId, String userId)
```
- **Propósito:** Eliminar un mensaje
- **Parámetros:**
  - `messageId` → ID del mensaje
  - `userId` → ID del propietario (validación)
- **Retorna:** `{success: bool, message: str}`
- **Ubicación:** Lines 172-200

---

### 6. **initializeChatAfterPayment()**
```dart
Future<void> initializeChatAfterPayment(
  String workId,
  String clientId,
  String technicianId,
)
```
- **Propósito:** Enviar mensaje de bienvenida post-pago
- **Parámetros:**
  - `workId` → ID del trabajo
  - `clientId`, `technicianId` → IDs de participantes
- **Mensaje:** "💰 Pago confirmado. El chat está activo. ¡Coordinemos!"
- **Ubicación:** Lines 202-240

---

## 👤 WorkService (`lib/services/work_and_chat_service.dart`)

### 1. **getWorkDetails()**
```dart
Future<Map<String, dynamic>> getWorkDetails(String workId)
```
- **Propósito:** Obtener detalles completos del trabajo
- **Parámetros:** `workId` → ID del trabajo aceptado
- **Retorna:** `Map` con:
  - `client_confirmed_chat` → bool
  - `technician_confirmed_chat` → bool
  - `payment_status` → status del pago
  - `status` → status del trabajo
  - Datos de cliente, técnico, cotización
- **Ubicación:** Lines 50-100

---

### 2. **streamWorkConfirmations()**
```dart
Stream<Map<String, bool>> streamWorkConfirmations(String workId)
```
- **Propósito:** Stream tiempo real de confirmaciones bilaterales
- **Parámetros:** `workId` → ID del trabajo
- **Retorna:** `Stream<{client_confirmed: bool, technician_confirmed: bool}>`
- **Uso:**
  ```dart
  _workService.streamWorkConfirmations(workId).listen((status) {
    if (status['client_confirmed'] && status['technician_confirmed']) {
      // Iniciar chat
    }
  });
  ```
- **Ubicación:** Lines 102-150

---

### 3. **confirmChatBilateral()**
```dart
Future<Map<String, dynamic>> confirmChatBilateral(
  String workId,
  String userId,
  String userType, // 'client' o 'technician'
)
```
- **Propósito:** Confirmar participación en chat
- **Parámetros:**
  - `workId` → ID del trabajo
  - `userId` → ID del usuario confirmando
  - `userType` → Tipo de usuario
- **Retorna:** `{success: bool, bothConfirmed: bool, message: str}`
- **Ubicación:** Lines 152-210

---

### 4. **acceptQuotation()**
```dart
Future<Map<String, dynamic>> acceptQuotation(
  String quotationId,
  String clientId,
)
```
- **Propósito:** Cliente acepta cotización (crea trabajo aceptado)
- **Parámetros:**
  - `quotationId` → ID de la cotización
  - `clientId` → ID del cliente
- **Retorna:** `{success: bool, workId: str, message: str}`
- **Crea:** Registro en `accepted_works`
- **Ubicación:** Lines 212-280

---

### 5. **startWork()**
```dart
Future<Map<String, dynamic>> startWork(
  String workId,
  String technicianId,
)
```
- **Propósito:** Técnico marca trabajo como iniciado
- **Parámetros:**
  - `workId` → ID del trabajo
  - `technicianId` → ID del técnico
- **Retorna:** `{success: bool, message: str}`
- **Actualiza:** `status = 'in_progress'`
- **Ubicación:** Lines 282-320

---

### 6. **completeWork()**
```dart
Future<Map<String, dynamic>> completeWork(
  String workId,
  String technicianId,
  String description, // Descripción del trabajo realizado
)
```
- **Propósito:** Técnico marca trabajo como completado
- **Parámetros:**
  - `workId` → ID del trabajo
  - `technicianId` → ID del técnico
  - `description` → Detalles del trabajo realizado
- **Retorna:** `{success: bool, message: str}`
- **Actualiza:** `status = 'completed'`
- **Ubicación:** Lines 322-370

---

## 💳 PaymentService (`lib/services/payment_service.dart`)

### 1. **generateClientToken()**
```dart
Future<String> generateClientToken()
```
- **Propósito:** Generar token cliente para UI de pago
- **Retorna:** Token para Braintree Drop-in
- **Ubicación:** Lines 30-80

---

### 2. **createPayment()**
```dart
Future<Map<String, dynamic>> createPayment(
  String workId,
  double amount,
  String nonce, // Token de Braintree
  String paymentMethod, // 'credit_card', 'paypal', etc
)
```
- **Propósito:** Procesar pago con Braintree
- **Parámetros:**
  - `workId` → ID del trabajo
  - `amount` → Monto a cobrar
  - `nonce` → Token de pago de Braintree
  - `paymentMethod` → Método usado
- **Retorna:** `{success: bool, transactionId: str, message: str}`
- **Crea:** Registro en tabla `payments`
- **Ubicación:** Lines 82-150

---

### 3. **getPaymentHistory()**
```dart
Future<List<PaymentModel>> getPaymentHistory(String userId)
```
- **Propósito:** Obtener historial de pagos del usuario
- **Parámetros:** `userId` → ID del usuario
- **Retorna:** Lista de `PaymentModel`
- **Ubicación:** Lines 152-200

---

## 📍 LocationService (`lib/services/location_service.dart`)

### 1. **getCurrentLocation()**
```dart
Future<LocationData?> getCurrentLocation()
```
- **Propósito:** Obtener ubicación GPS actual
- **Retorna:** `LocationData` con lat, lng o null si error
- **Permisos:** Requiere `ACCESS_FINE_LOCATION`
- **Ubicación:** Lines 20-80

---

### 2. **getLocationFromAddress()**
```dart
Future<LocationData?> getLocationFromAddress(String address)
```
- **Propósito:** Geocodificar dirección a coordenadas
- **Parámetros:** `address` → Dirección textual
- **Retorna:** `LocationData` con lat, lng
- **Ubicación:** Lines 82-140

---

### 3. **getAddressFromLocation()**
```dart
Future<String?> getAddressFromLocation(double lat, double lng)
```
- **Propósito:** Reverse geocode coordenadas a dirección
- **Parámetros:**
  - `lat` → Latitud
  - `lng` → Longitud
- **Retorna:** Dirección legible
- **Ubicación:** Lines 142-200

---

## 📸 StorageService (`lib/services/storage_service.dart`)

### 1. **uploadProfilePhoto()**
```dart
Future<String> uploadProfilePhoto(ImageData imageData, String userId)
```
- **Propósito:** Subir foto de perfil a Supabase Storage
- **Parámetros:**
  - `imageData` → Datos de la imagen
  - `userId` → ID del usuario
- **Retorna:** URL pública de la imagen
- **Bucket:** `profile-photos`
- **Ubicación:** Lines 20-80

---

### 2. **uploadServiceRequestImages()**
```dart
Future<List<String>> uploadServiceRequestImages(
  List<ImageData> images,
  String requestId,
)
```
- **Propósito:** Subir múltiples fotos de solicitud de servicio
- **Parámetros:**
  - `images` → Lista de imágenes
  - `requestId` → ID de la solicitud
- **Retorna:** Lista de URLs públicas
- **Bucket:** `service-request-images`
- **Ubicación:** Lines 82-150

---

### 3. **deleteFile()**
```dart
Future<void> deleteFile(String bucketName, String filePath)
```
- **Propósito:** Eliminar archivo de Storage
- **Parámetros:**
  - `bucketName` → Nombre del bucket
  - `filePath` → Ruta del archivo
- **Ubicación:** Lines 152-180

---

## 📋 QuotationService (`lib/services/quotation_service.dart`)

### 1. **createQuotation()**
```dart
Future<Map<String, dynamic>> createQuotation(QuotationModel quotation)
```
- **Propósito:** Técnico crea cotización para solicitud
- **Parámetros:** `quotation` → QuotationModel completo
- **Retorna:** `{success: bool, quotationId: str, message: str}`
- **Ubicación:** Lines 20-80

---

### 2. **getQuotation()**
```dart
Future<QuotationModel?> getQuotation(String quotationId)
```
- **Propósito:** Obtener detalles de cotización
- **Parámetros:** `quotationId` → ID de la cotización
- **Retorna:** `QuotationModel` o null
- **Ubicación:** Lines 82-130

---

### 3. **getServiceRequestQuotations()**
```dart
Future<List<QuotationModel>> getServiceRequestQuotations(String requestId)
```
- **Propósito:** Obtener todas las cotizaciones para una solicitud
- **Parámetros:** `requestId` → ID de la solicitud
- **Retorna:** Lista de `QuotationModel`
- **Ubicación:** Lines 132-180

---

### 4. **updateQuotationStatus()**
```dart
Future<Map<String, dynamic>> updateQuotationStatus(
  String quotationId,
  String newStatus, // 'pending', 'accepted', 'rejected', 'expired'
)
```
- **Propósito:** Cambiar estado de cotización
- **Parámetros:**
  - `quotationId` → ID de la cotización
  - `newStatus` → Nuevo estado
- **Retorna:** `{success: bool, message: str}`
- **Ubicación:** Lines 182-220

---

## 📞 NotificationSystemService (`lib/services/notification_system_service.dart`)

### 1. **showQuotationNotification()**
```dart
Future<void> showQuotationNotification(String title, String message)
```
- **Propósito:** Mostrar notificación + vibración (3x) para nueva cotización
- **Ubicación:** Lines 20-60

---

### 2. **showPaymentConfirmedNotification()**
```dart
Future<void> showPaymentConfirmedNotification(String title, String message)
```
- **Propósito:** Notificación + vibración (2x) para pago confirmado
- **Ubicación:** Lines 62-100

---

### 3. **showChatNotification()**
```dart
Future<void> showChatNotification(String title, String message)
```
- **Propósito:** Notificación + vibración (1x) para nuevo mensaje
- **Ubicación:** Lines 102-140

---

### 4. **simpleVibrate()**
```dart
Future<void> simpleVibrate()
```
- **Propósito:** Vibración haptic simple
- **Ubicación:** Lines 142-160

---

---

## 🔑 Resumen de Keys & Parámetros

| Función | Key Principal | Parámetro Crítico |
|---------|---------------|-------------------|
| `register()` | email | password (mín 6) |
| `login()` | email+password | - |
| `resetPassword()` | email+token | OtpType |
| `sendMessage()` | workId | messageType |
| `acceptQuotation()` | quotationId | clientId |
| `createPayment()` | workId | nonce (Braintree) |
| `uploadProfilePhoto()` | userId | ImageData |

---

**✅ Total de funciones documentadas: 40+**

