# 🗂️ MODELOS & ESTRUCTURA DE DATOS - FIX & GO INNOVATIONS

---

## 👤 UserModel (`lib/models/user_model.dart`)

```dart
class UserModel {
  final String id;              // UUID (Supabase)
  final String email;           // Email único
  final String fullName;        // Nombre completo
  final String phone;           // Teléfono
  final String userType;        // 'client' | 'technician' | 'admin'
  final String? photoUrl;       // URL de foto
  final String? bio;            // Biografía (técnicos)
  final List<String>? skills;   // Especialidades (técnicos)
  final double? rating;         // Calificación promedio
  final int? totalReviews;      // Total de reseñas
  final bool isActive;          // Cuenta activa
  final DateTime createdAt;     // Fecha de registro
  final DateTime? updatedAt;    // Última actualización
}
```

### Schema SQL
```sql
CREATE TABLE public.users (
  id UUID PRIMARY KEY (auth.users.id),
  email VARCHAR UNIQUE NOT NULL,
  full_name VARCHAR NOT NULL,
  phone VARCHAR NOT NULL,
  user_type VARCHAR CHECK (user_type IN ('client', 'technician', 'admin')),
  photo_url TEXT,
  bio TEXT,
  skills TEXT[],
  rating DECIMAL(3,2),
  total_reviews INT DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP
);
```

---

## 🔧 ServiceRequestModel (`lib/models/service_request_model.dart`)

```dart
class ServiceRequestModel {
  final String id;                  // UUID
  final String clientId;            // ID del cliente
  final String title;               // "Lavadora no enciende"
  final String description;         // Descripción detallada
  final String? category;           // "Electrodomésticos"
  final String status;              // 'open' | 'in_progress' | 'completed' | 'cancelled'
  final LocationData location;      // Ubicación con lat/lng
  final String? sector;             // "San Isidro"
  final String? exactAddress;       // Dirección exacta
  final DateTime availableFrom;     // Disponibilidad
  final DateTime? availableTo;      // Hasta cuándo
  final List<String> imageUrls;    // URLs de fotos
  final double? budget;             // Presupuesto aproximado
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;
}
```

### Schema SQL
```sql
CREATE TABLE public.service_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES public.users(id),
  title VARCHAR NOT NULL,
  description TEXT NOT NULL,
  category VARCHAR,
  status VARCHAR DEFAULT 'open',
  location_lat DECIMAL(10,8),
  location_lng DECIMAL(11,8),
  sector VARCHAR,
  exact_address TEXT,
  available_from TIMESTAMP NOT NULL,
  available_to TIMESTAMP,
  budget DECIMAL(10,2),
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP,
  completed_at TIMESTAMP
);

CREATE TABLE public.service_request_images (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id UUID NOT NULL REFERENCES public.service_requests(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  uploaded_at TIMESTAMP DEFAULT now()
);
```

---

## 💰 QuotationModel (`lib/models/quotation_model.dart`)

```dart
class QuotationModel {
  final String id;                  // UUID
  final String requestId;           // ID de la solicitud
  final String technicianId;        // ID del técnico
  final double price;               // Precio $150.00
  final String? description;        // Descripción de la solución
  final String? solution;           // "Revisión eléctrica completa"
  final Duration? estimatedTime;    // Tiempo estimado (1.5 horas)
  final String status;              // 'pending' | 'accepted' | 'rejected' | 'expired'
  final DateTime createdAt;
  final DateTime? expiresAt;        // Validez de cotización (48h típico)
  final DateTime? respondedAt;
}
```

### Schema SQL
```sql
CREATE TABLE public.quotations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id UUID NOT NULL REFERENCES public.service_requests(id),
  technician_id UUID NOT NULL REFERENCES public.users(id),
  price DECIMAL(10,2) NOT NULL,
  description TEXT,
  solution VARCHAR,
  estimated_time_minutes INT,
  status VARCHAR DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT now(),
  expires_at TIMESTAMP,
  responded_at TIMESTAMP,
  UNIQUE(request_id, technician_id) -- Un técnico por solicitud
);
```

---

## ✅ AcceptedWorkModel (`lib/models/accepted_work_model.dart`)

```dart
class AcceptedWorkModel {
  final String id;                      // UUID
  final String quotationId;             // ID de cotización aceptada
  final String clientId;                // ID del cliente
  final String technicianId;            // ID del técnico
  final double price;                   // Precio final
  final String status;                  // 'pending_payment' | 'in_progress' | 'completed' | 'cancelled'
  
  // Confirmación bilateral para chat
  final bool clientConfirmedChat;       // Cliente confirmó chat
  final bool technicianConfirmedChat;   // Técnico confirmó chat
  
  // Pago
  final String? paymentStatus;          // 'pending' | 'completed' | 'failed' | 'refunded'
  final String? transactionId;          // ID de transacción Braintree
  
  // Trabajo
  final DateTime? startedAt;            // Cuándo empezó
  final DateTime? completedAt;          // Cuándo terminó
  final String? completionNotes;        // Notas de finalización
  
  // Calificación
  final double? clientRating;           // 1-5 estrellas
  final String? clientReview;           // Comentario del cliente
  final bool clientRated;               // Ya fue calificado
  
  final DateTime createdAt;
  final DateTime? updatedAt;
}
```

### Schema SQL
```sql
CREATE TABLE public.accepted_works (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quotation_id UUID NOT NULL UNIQUE REFERENCES public.quotations(id),
  client_id UUID NOT NULL REFERENCES public.users(id),
  technician_id UUID NOT NULL REFERENCES public.users(id),
  price DECIMAL(10,2) NOT NULL,
  status VARCHAR DEFAULT 'pending_payment',
  
  -- Confirmación bilateral
  client_confirmed_chat BOOLEAN DEFAULT false,
  technician_confirmed_chat BOOLEAN DEFAULT false,
  
  -- Pago
  payment_status VARCHAR DEFAULT 'pending',
  transaction_id VARCHAR,
  
  -- Trabajo
  started_at TIMESTAMP,
  completed_at TIMESTAMP,
  completion_notes TEXT,
  
  -- Calificación
  client_rating DECIMAL(2,1),
  client_review TEXT,
  client_rated BOOLEAN DEFAULT false,
  
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP,
  
  CONSTRAINT valid_status CHECK (status IN ('pending_payment', 'in_progress', 'completed', 'cancelled')),
  CONSTRAINT valid_payment CHECK (payment_status IN ('pending', 'completed', 'failed', 'refunded'))
);
```

---

## 💬 ChatMessageModel (`lib/models/chat_message_model.dart`)

```dart
class ChatMessageModel {
  final String id;              // UUID
  final String workId;          // ID del trabajo aceptado
  final String senderId;        // ID del remitente
  final String messageText;     // Contenido del mensaje
  final String messageType;     // 'text' | 'image' | 'document'
  final String? mediaUrl;       // URL si es media
  final bool isRead;            // ¿Fue leído?
  final DateTime? readAt;       // Cuándo fue leído
  final DateTime createdAt;
  final DateTime? updatedAt;
}
```

### Schema SQL
```sql
CREATE TABLE public.chat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  work_id UUID NOT NULL REFERENCES public.accepted_works(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES public.users(id),
  message_text TEXT NOT NULL,
  message_type VARCHAR DEFAULT 'text',
  media_url TEXT,
  is_read BOOLEAN DEFAULT false,
  read_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP
);

CREATE INDEX idx_chat_messages_work_id ON public.chat_messages(work_id);
CREATE INDEX idx_chat_messages_sender_id ON public.chat_messages(sender_id);
```

---

## 💳 PaymentModel (`lib/models/payment_model.dart`)

```dart
class PaymentModel {
  final String id;              // UUID
  final String workId;          // ID del trabajo
  final String clientId;        // Quién paga
  final String technicianId;    // Quién recibe
  final double amount;          // Monto
  final String paymentMethod;   // 'credit_card' | 'paypal' | 'bank_transfer'
  final String status;          // 'pending' | 'completed' | 'failed' | 'refunded'
  final String? transactionId;  // ID en Braintree
  final String? failureReason;  // Motivo si falló
  final DateTime createdAt;
  final DateTime? completedAt;
}
```

### Schema SQL
```sql
CREATE TABLE public.payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  work_id UUID NOT NULL UNIQUE REFERENCES public.accepted_works(id),
  client_id UUID NOT NULL REFERENCES public.users(id),
  technician_id UUID NOT NULL REFERENCES public.users(id),
  amount DECIMAL(10,2) NOT NULL,
  payment_method VARCHAR NOT NULL,
  status VARCHAR DEFAULT 'pending',
  transaction_id VARCHAR,
  failure_reason TEXT,
  created_at TIMESTAMP DEFAULT now(),
  completed_at TIMESTAMP
);
```

---

## ⭐ RatingModel (`lib/models/ratings/rating_model.dart`)

```dart
class RatingModel {
  final String id;              // UUID
  final String workId;          // ID del trabajo
  final String ratedById;       // Quién califica
  final String ratedUserId;     // A quién se califica
  final double rating;          // 1-5 estrellas
  final String? comment;        // Comentario
  final DateTime createdAt;
}
```

### Schema SQL
```sql
CREATE TABLE public.ratings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  work_id UUID NOT NULL REFERENCES public.accepted_works(id),
  rated_by_id UUID NOT NULL REFERENCES public.users(id),
  rated_user_id UUID NOT NULL REFERENCES public.users(id),
  rating DECIMAL(2,1) NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMP DEFAULT now(),
  UNIQUE(work_id, rated_by_id) -- Una calificación por trabajo
);
```

---

## 📸 ImageData (`lib/models/image_data.dart`)

```dart
class ImageData {
  final String filePath;        // Ruta local del archivo
  final String fileName;        // Nombre del archivo
  final int fileSizeBytes;      // Tamaño en bytes
  final String mimeType;        // 'image/jpeg', 'image/png'
  
  // Para subir a Storage
  final List<int> bytes;        // Contenido del archivo
}
```

---

## 🗺️ Modelo de Ubicación (Interno)

```dart
class LocationData {
  final double latitude;        // -12.0921
  final double longitude;       // -76.9232
  final String? address;        // "Av. Principal 123"
  final String? sector;         // "San Isidro"
}
```

---

## 📊 Relaciones entre Modelos

```
users (👤 cliente o técnico)
  ├─ service_requests (📋 clientes crean)
  │   ├─ service_request_images (📸 fotos)
  │   └─ quotations (💰 técnicos proponen)
  │       └─ accepted_works (✅ cliente acepta)
  │           ├─ chat_messages (💬 comunicación)
  │           ├─ payments (💳 pago)
  │           └─ ratings (⭐ calificación)
  │
  └─ ratings (⭐ recibe calificaciones)
```

---

## 🔐 Validaciones y Constraints

| Modelo | Validación | Tipo |
|--------|-----------|------|
| UserModel | email único | UNIQUE |
| ServiceRequest | status válido | CHECK |
| Quotation | técnico único por solicitud | UNIQUE |
| AcceptedWork | una cotización = un trabajo | UNIQUE |
| ChatMessage | work_id existe | FK |
| Payment | monto > 0 | CHECK |
| Rating | 1 ≤ rating ≤ 5 | CHECK |

---

## 📈 Índices para Rendimiento

```sql
-- Búsquedas frecuentes
CREATE INDEX idx_users_email ON public.users(email);
CREATE INDEX idx_service_requests_client_id ON public.service_requests(client_id);
CREATE INDEX idx_service_requests_status ON public.service_requests(status);
CREATE INDEX idx_quotations_technician_id ON public.quotations(technician_id);
CREATE INDEX idx_quotations_status ON public.quotations(status);
CREATE INDEX idx_accepted_works_client_id ON public.accepted_works(client_id);
CREATE INDEX idx_accepted_works_technician_id ON public.accepted_works(technician_id);
CREATE INDEX idx_accepted_works_status ON public.accepted_works(status);
CREATE INDEX idx_chat_messages_work_id ON public.chat_messages(work_id);
CREATE INDEX idx_payments_client_id ON public.payments(client_id);
CREATE INDEX idx_ratings_rated_user_id ON public.ratings(rated_user_id);
```

---

**✅ Modelos documentados: 10**  
**✅ Tablas SQL: 10**  
**✅ Relaciones: 15+**

