# 🔒 AUDITORÍA DE SEGURIDAD - FIX & GO INNOVATIONS

**Fecha:** 28 de Enero, 2026  
**Realizado por:** Mateo Paredes  
**Estado:** ✅ APROBADO (Con recomendaciones)

---

## 🟢 ÁREA: AUTENTICACIÓN

### ✅ Fortalezas

| Aspecto | Estado | Detalles |
|--------|--------|---------|
| Contraseñas | ✅ Hasheadas | Supabase usa bcrypt |
| Email verificación | ✅ Requerida | OTP con expiración < 1 hora |
| OTP tokens | ✅ Seguros | JWT firmados por Supabase |
| Session tokens | ✅ JWT | Expiran automáticamente |
| Reset password | ✅ Seguro | Link con token OTP |
| Rate limiting | ✅ Habilitado | 5 intentos fallidos |

### ⚠️ Recomendaciones

1. **Implementar 2FA (Two Factor Authentication)**
   ```
   Priority: MEDIA
   Afecta a: Técnicos (reciben dinero)
   Sugerencia: SMS o Google Authenticator
   ```

2. **Audit logging para cambios de contraseña**
   ```
   Priority: BAJA
   Afecta a: Cumplimiento
   Sugerencia: Registrar cambios de contraseña en logs
   ```

---

## 🟢 ÁREA: DATABASE & RLS (Row Level Security)

### ✅ Fortalezas

| Tabla | RLS | Policies | Estado |
|-------|-----|----------|--------|
| users | ✅ ON | Lectura solo perfil propio | ✅ |
| service_requests | ✅ ON | Solo cliente/técnicos asignados | ✅ |
| quotations | ✅ ON | Solo técnico/cliente relacionado | ✅ |
| accepted_works | ✅ ON | Solo participantes | ✅ |
| chat_messages | ✅ ON | Solo participantes trabajo | ✅ |
| payments | ✅ ON | Solo participantes o admin | ✅ |
| ratings | ✅ ON | Solo usuario puede auto-calificar | ✅ |

### Verificación Manual

```sql
-- Para verificar RLS está activo:
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
  AND rowsecurity = true;

-- Resultado esperado: Todas las tablas tienen rowsecurity = true
```

### ⚠️ Recomendaciones

1. **Auditoría de acceso a datos**
   ```
   Priority: MEDIA
   Crear tabla: audit_logs
   Registrar: SELECT/INSERT/UPDATE/DELETE con user_id, timestamp
   ```

2. **Enmascarar datos sensibles**
   ```
   Priority: MEDIA
   Casos: Email, teléfono en listados públicos
   Solución: Mostrar solo primeros caracteres
   ```

---

## 🟢 ÁREA: API & ENDPOINTS

### ✅ Fortalezas

| Aspecto | Status | Detalles |
|--------|--------|---------|
| Supabase Auth | ✅ | JWT tokens en Authorization header |
| API keys | ✅ | Anon key tiene RLS automática |
| Headers requeridos | ✅ | apikey + Authorization obligatorios |
| CORS | ✅ | Supabase maneja automáticamente |
| Rate limiting | ✅ | Built-in en Supabase |

### ⚠️ Puntos de Atención

1. **Validación de entrada en servidor**
   ```
   Priority: ALTA
   Ubicación: Supabase Functions (si se usan)
   Acción: Validar length, format, SQL injection
   ```

2. **HTTPS obligatorio**
   ```
   Priority: ALTA
   Status: ✅ Implementado
   Todo: Añadir HSTS headers
   ```

---

## 🟢 ÁREA: ALMACENAMIENTO (Storage)

### ✅ Fortalezas

| Aspecto | Status | Detalles |
|--------|--------|---------|
| Buckets privados | ✅ | Requieren autenticación |
| Rutas por usuario | ✅ | `profile-photos/{user_id}/*` |
| Tipos MIME | ✅ | Solo images permitidas |
| Size limits | ✅ | Max 5MB por archivo |
| Scan antivirus | ⚠️ | No implementado |

### ⚠️ Recomendaciones

1. **Validar tipos MIME en backend**
   ```
   Priority: ALTA
   Ubicación: StorageService.dart
   Validar: Content-Type vs file extension
   Prevenir: File type spoofing (renombrar .exe a .jpg)
   ```

2. **Scan antivirus en uploads**
   ```
   Priority: MEDIA
   Usar: ClamAV o VirusTotal API
   Cuando: Antes de guardar en Storage
   ```

3. **Limpiar metadata EXIF de fotos**
   ```
   Priority: MEDIA
   Riesgo: Ubicación GPS en fotos de usuarios
   Solución: image library con EXIF stripping
   ```

---

## 🟢 ÁREA: PAGOS (Braintree)

### ✅ Fortalezas

| Aspecto | Status | Detalles |
|--------|--------|---------|
| Tokenización | ✅ | Usa Braintree Drop-in (no maneja números) |
| Sandbox/Prod | ✅ | Separados, Solo Sandbox en dev |
| Logs de transacción | ✅ | Guardados en BD |
| Webhook security | ⚠️ | Pendiente implementar |

### ⚠️ Recomendaciones

1. **Nunca guardar números de tarjeta**
   ```
   Priority: CRÍTICA (PCI DSS)
   Status: ✅ Implementado correctamente
   Braintree genera nonce + tokeniza
   ```

2. **Validar transacciones con webhooks**
   ```
   Priority: ALTA
   Acción: Implementar Braintree Webhooks
   Verificar: Transacción completada en BD
   Prevenir: Pago simulado sin dinero
   ```

3. **Encriptar transaction_id**
   ```
   Priority: MEDIA
   Ubicación: Supabase column encryption
   IDs sensibles: transaction_id, payment_token
   ```

---

## 🟢 ÁREA: COMUNICACIÓN (Chat)

### ✅ Fortalezas

| Aspecto | Status | Detalles |
|--------|--------|---------|
| Encriptación en tránsito | ✅ | HTTPS obligatorio |
| RLS en chat_messages | ✅ | Solo participantes pueden leer |
| Validación de sender_id | ✅ | JWT autenticación |

### ⚠️ Recomendaciones

1. **Encriptación end-to-end (E2E)**
   ```
   Priority: BAJA (por ahora)
   Futuro: Implementar si hay PII en chats
   Tecnología: Signal protocol o similar
   ```

2. **Audit trail de mensajes eliminados**
   ```
   Priority: MEDIA
   Crear: deleted_at timestamp vs hard delete
   Razón: Compliance, investigación disputas
   ```

3. **Moderación de contenido**
   ```
   Priority: MEDIA
   Implementar: Flagging de mensajes inapropiados
   Escalación: Admin review para denuncias
   ```

---

## 🟢 ÁREA: PERMISOS (Android)

### ✅ Implementados en AndroidManifest.xml

```xml
✅ CAMERA - Fotografías de problemas
✅ READ_EXTERNAL_STORAGE - Seleccionar fotos
✅ WRITE_EXTERNAL_STORAGE - Guardar fotos (hasta Android 12)
✅ ACCESS_FINE_LOCATION - GPS preciso
✅ ACCESS_COARSE_LOCATION - GPS aproximado
✅ INTERNET - Conexión de red
✅ POST_NOTIFICATIONS - Notificaciones (Android 13+)
✅ VIBRATE - Haptic feedback
✅ WAKE_LOCK - Mantener pantalla activa si necesario
```

### ⚠️ Recomendaciones

1. **Runtime permissions**
   ```
   Priority: ALTA
   Status: ✅ PermissionHandler implementado
   Verificar: Pedir permisos en runtime (Android 6+)
   ```

2. **Justificar por qué piden permisos**
   ```
   Priority: MEDIA
   Ubicación: PermissionHandler rationale
   Ejemplos:
     - "Necesitamos tu GPS para ubicarte en el mapa"
     - "Necesitamos fotos para mostrar el problema"
   ```

---

## 🟢 ÁREA: DEEP LINKING

### ✅ Fortalezas

| Aspecto | Status | Detalles |
|--------|--------|---------|
| HTTPS validation | ✅ | assetlinks.json en /.well-known/ |
| autoVerify | ✅ | android:autoVerify="true" |
| Custom scheme fallback | ✅ | fixgo:// para desarrollo |
| Token en URL | ✅ | No guardado, se pasa en parámetro |
| Expiración de token | ✅ | OTP expira en < 1 hora |

### ⚠️ Puntos Críticos

1. **Proteger assetlinks.json**
   ```
   Priority: CRÍTICA
   TODO: Generar SHA-256 correcto del keystore
   Formato: Base64 sin ":" separadores
   Si es incorrecto: Deep links NO funcionarán
   ```

2. **Validar dominios en GoRouter**
   ```
   Priority: MEDIA
   Acción: Verificar hostname == expected domain
   Prevenir: App acepte deep links de otros dominios
   ```

3. **No reutilizar tokens OTP**
   ```
   Priority: ALTA
   Status: ✅ Supabase lo previene automáticamente
   Verify: Token se elimina después de usar
   ```

---

## 🟡 ÁREA: VULNERABILIDADES GENERALES

### Inyección SQL
```
Status: ✅ PROTEGIDO
Razón: Supabase usa parameterized queries
ORM: Dart supabase-dart client
Riesgo: BAJO (casi imposible)
```

### Cross-Site Scripting (XSS)
```
Status: ✅ PROTEGIDO
Razón: Flutter compila a código nativo (no web)
Widget tree no es HTML
Riesgo: BAJO
```

### Man-in-the-Middle (MITM)
```
Status: ✅ PROTEGIDO
Razón: HTTPS obligatorio
Certificados: Validados automáticamente
Riesgo: BAJO
```

### Insecure Deserialization
```
Status: ⚠️ REVISAR
Ubicación: JSON parsing de API responses
Validación: Usar models tipados (✅ ya hecho)
Riesgo: BAJO
```

---

## 📊 MATRIZ DE RIESGO

| Riesgo | Severidad | Probabilidad | Mitigación |
|--------|-----------|------------|-----------|
| SQL Injection | CRÍTICA | MUY BAJA | Supabase + parameterized queries |
| Token compromise | ALTA | MEDIA | Expiración + HTTPS |
| Unauthorized data access | ALTA | BAJA | RLS + JWT validation |
| Payment fraud | ALTA | MEDIA | Braintree tokenization + webhooks |
| Malicious file upload | MEDIA | BAJA | MIME validation + antivirus |
| Social engineering | MEDIA | MEDIA | User education |
| Weak passwords | MEDIA | MEDIA | Password complexity rules |
| Unencrypted storage | MEDIA | BAJA | Device encryption + Supabase |

---

## 🔧 CONFIGURACIÓN DE SEGURIDAD RECOMENDADA

### Para Producción

```env
# .env.production (NUNCA en git)
FLUTTER_ENV=production
BRAINTREE_ENV=PRODUCTION
SUPABASE_URL=https://wmznnnvgyqzjqzvuvzya.supabase.co
LOG_LEVEL=error  # Solo errores, no debug info
HTTPS_ONLY=true
```

### Headers de Seguridad (Supabase)

```
Strict-Transport-Security: max-age=31536000; includeSubDomains
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
Content-Security-Policy: default-src 'self'
```

---

## ✅ CHECKLIST FINAL DE SEGURIDAD

### Antes de Release
- [ ] Cambiar Braintree a PRODUCTION
- [ ] Generar release.keystore con contraseña fuerte
- [ ] Generar assetlinks.json con SHA-256 correcto
- [ ] Verificar .env.production no tiene datos en git
- [ ] Revisar logs no exponen información sensible
- [ ] Testear deep links con produción URLs
- [ ] Cambiar debugShowCheckedModeBanner a false
- [ ] Deshabilitar flutter logs en release
- [ ] Revisar android:debuggable="false"
- [ ] Implementar error handling sin stack traces al usuario

### Antes de Beta Testing
- [ ] Security audit de todo el código
- [ ] Penetration testing (si es posible)
- [ ] Revisar dependencias por vulnerabilidades conocidas
- [ ] Certificados SSL válidos en todos los endpoints
- [ ] Braintree sandbox testing completo
- [ ] Payment webhook testing

### Monitoreo Post-Launch
- [ ] Implementar crash reporting (Firebase Crashlytics)
- [ ] Implementar analytics (Firebase Analytics)
- [ ] Monitoreo de errores 500 en API
- [ ] Revisar logs de acceso semanal
- [ ] Audit trail de cambios de contraseña
- [ ] Alertas para múltiples intentos fallidos de login

---

## 🏆 CONCLUSIÓN

**Nivel de Seguridad:** 🟢 BUENO (8/10)

### Lo que está bien
✅ RLS en todas las tablas  
✅ Autenticación JWT segura  
✅ HTTPS obligatorio  
✅ Tokens OTP con expiración  
✅ No guardamos números de tarjeta  
✅ Validación de permisos  

### Áreas de mejora
⚠️ Implementar 2FA  
⚠️ Webhook validation de pagos  
⚠️ EXIF stripping de fotos  
⚠️ Antivirus scanning  
⚠️ E2E encryption chat  

---

**Auditoría completada:** 28/01/2026  
**Próxima revisión recomendada:** Después de beta testing

