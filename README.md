# DOCUMENTACIÓN LOCAL - FIX & GO INNOVATIONS

> CARPETA LOCAL - No subir a GitHub (está en .gitignore)

**Fecha Actualización:** 28 de Enero, 2026  
**Estado Proyecto:** COMPLETADO - Deep Linking + Email + Chat Bilateral Implementado

---

## Contenido de esta carpeta

| Archivo | Propósito |
|---------|----------|
| `FUNCIONES.md` | Todas las funciones de servicios (params, returns, descripción) |
| `KEYS_CONFIG.md` | Keys, URLs, credenciales, configuraciones (PRIVADO) |
| `MODELOS.md` | Estructuras de datos (models) con esquema SQL |
| `SERVICIOS.md` | Servicios principales y sus métodos |
| `URLS_ENDPOINTS.md` | URLs de deep linking, Supabase, endpoints |
| `CHECKLIST_IMPLEMENTACION.md` | Pasos completados y pendientes |
| `AUDITORÍA.md` | Revisión de seguridad, permisos, acceso datos |

---

## Resumen Ejecutivo

### IMPLEMENTADO
- [x] Autenticación con Supabase (email + password)
- [x] Deep Linking Android (HTTPS + custom scheme)
- [x] Confirmación de email con OTP
- [x] Reset de contraseña con OTP
- [x] Chat bilateral (cliente-técnico)
- [x] Confirmación bilateral antes de iniciar chat
- [x] Notificaciones con vibración
- [x] Sistema de pagos (Braintree)
- [x] Cotizaciones
- [x] Solicitudes de servicio con fotos
- [x] GoRouter con 7 rutas

### PENDIENTE
- [ ] Desplegar assetlinks.json en Netlify
- [ ] Generar keystore para release APK
- [ ] Testear deep links en dispositivo
- [ ] Configurar webhooks de pago
- [ ] Deploy a TestFlight (iOS)
- [ ] Deploy a Google Play (Android)

---

## INFORMACIÓN CRÍTICA

### Credenciales (NO COMPARTIR)
- Supabase Keys → Ver `KEYS_CONFIG.md`
- Gmail SMTP → Ver `KEYS_CONFIG.md`
- Braintree API → Ver `KEYS_CONFIG.md`

### URLs Base
- Supabase: `https://tu-proyecto.supabase.co`
- Deep Links: `https://deep-links-gofix.netlify.app`
- Custom Scheme: `fixgo://`

---

## Cómo usar esta documentación

1. **¿Qué hace la función X?**  
   → Lee `FUNCIONES.md`

2. **¿Dónde está la key de API?**  
   → Lee `KEYS_CONFIG.md`

3. **¿Cuál es la estructura de datos?**  
   → Lee `MODELOS.md`

4. **¿Cómo llamar al servicio X?**  
   → Lee `SERVICIOS.md`

5. **¿Cuáles son las URLs?**  
   → Lee `URLS_ENDPOINTS.md`

6. **¿Qué falta implementar?**  
   → Lee `CHECKLIST_IMPLEMENTACION.md`

---

## Stack Tecnológico

**Frontend:** Flutter + Dart  
**Backend:** Supabase (PostgreSQL + Auth)  
**Pagos:** Braintree  
**Storage:** Supabase Storage + Netlify  
**Notificaciones:** Firebase + Local (vibración)  
**Deep Linking:** Android App Links + Custom Scheme  
**Routing:** GoRouter  

---

## Contacto / Notas

- Desarrollador: Mateo Paredes
- Repo: Fix-Go-Innovations
- Issues: Revisar AUDITORÍA.md

**Última actualización documentación:** 28/01/2026

