// ==================== TRABAJO ACEPTADO ====================
class AcceptedWork {
  final String id;
  final String requestId;
  final String quotationId;
  final String clientId;
  final String technicianId;
  
  // Estados
  final WorkStatus status;
  
  // Información de pago
  final String? paymentMethod;
  final double paymentAmount;
  final double? platformFee;
  final double? technicianAmount;
  final String? paymentReference;
  final PaymentStatus paymentStatus;
  final DateTime? paidAt;
  
  // Progreso
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? estimatedCompletion;
  
  // Notas y evidencia
  final String? workNotes;
  final List<String> completionPhotos;
  
  // Calificación
  final int? clientRating;
  final String? clientReview;
  final DateTime? ratedAt;
  
  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  AcceptedWork({
    required this.id,
    required this.requestId,
    required this.quotationId,
    required this.clientId,
    required this.technicianId,
    required this.status,
    this.paymentMethod,
    required this.paymentAmount,
    this.platformFee,
    this.technicianAmount,
    this.paymentReference,
    required this.paymentStatus,
    this.paidAt,
    this.startedAt,
    this.completedAt,
    this.estimatedCompletion,
    this.workNotes,
    this.completionPhotos = const [],
    this.clientRating,
    this.clientReview,
    this.ratedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AcceptedWork.fromJson(Map<String, dynamic> json) {
    return AcceptedWork(
      id: json['id'],
      requestId: json['request_id'],
      quotationId: json['quotation_id'],
      clientId: json['client_id'],
      technicianId: json['technician_id'],
      status: WorkStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => WorkStatus.pending_payment,
      ),
      paymentMethod: json['payment_method'],
      paymentAmount: (json['payment_amount'] as num).toDouble(),
      platformFee: json['platform_fee'] != null 
          ? (json['platform_fee'] as num).toDouble() 
          : null,
      technicianAmount: json['technician_amount'] != null
          ? (json['technician_amount'] as num).toDouble()
          : null,
      paymentReference: json['payment_reference'],
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == json['payment_status'],
        orElse: () => PaymentStatus.pending,
      ),
      paidAt: json['paid_at'] != null 
          ? DateTime.parse(json['paid_at']) 
          : null,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'])
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      estimatedCompletion: json['estimated_completion'] != null
          ? DateTime.parse(json['estimated_completion'])
          : null,
      workNotes: json['work_notes'],
      completionPhotos: json['completion_photos'] != null
          ? List<String>.from(json['completion_photos'])
          : [],
      clientRating: json['client_rating'],
      clientReview: json['client_review'],
      ratedAt: json['rated_at'] != null
          ? DateTime.parse(json['rated_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'request_id': requestId,
      'quotation_id': quotationId,
      'client_id': clientId,
      'technician_id': technicianId,
      'status': status.name,
      'payment_method': paymentMethod,
      'payment_amount': paymentAmount,
      'platform_fee': platformFee,
      'technician_amount': technicianAmount,
      'payment_reference': paymentReference,
      'payment_status': paymentStatus.name,
      'paid_at': paidAt?.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'estimated_completion': estimatedCompletion?.toIso8601String(),
      'work_notes': workNotes,
      'completion_photos': completionPhotos,
      'client_rating': clientRating,
      'client_review': clientReview,
      'rated_at': ratedAt?.toIso8601String(),
    };
  }
}

// ==================== ENUMS ====================
enum WorkStatus {
  pending_payment,
  paid,
  on_way,
  in_progress,
  completed,
  rated,
}

enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
}

extension WorkStatusExtension on WorkStatus {
  String get displayName {
    switch (this) {
      case WorkStatus.pending_payment:
        return 'Pendiente de Pago';
      case WorkStatus.paid:
        return 'Pagado';
      case WorkStatus.on_way:
        return 'En Camino';
      case WorkStatus.in_progress:
        return 'En Progreso';
      case WorkStatus.completed:
        return 'Completado';
      case WorkStatus.rated:
        return 'Calificado';
    }
  }

  String get icon {
    switch (this) {
      case WorkStatus.pending_payment:
        return '💳';
      case WorkStatus.paid:
        return '✅';
      case WorkStatus.on_way:
        return '🚗';
      case WorkStatus.in_progress:
        return '🔧';
      case WorkStatus.completed:
        return '✔️';
      case WorkStatus.rated:
        return '⭐';
    }
  }
}

extension PaymentStatusExtension on PaymentStatus {
  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pendiente';
      case PaymentStatus.processing:
        return 'Procesando';
      case PaymentStatus.completed:
        return 'Completado';
      case PaymentStatus.failed:
        return 'Fallido';
    }
  }
}

// ==================== MENSAJE DE CHAT ====================
class ChatMessage {
  final String id;
  final String workId;
  final String senderId;
  final String messageText;
  final MessageType messageType;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.workId,
    required this.senderId,
    required this.messageText,
    required this.messageType,
    required this.isRead,
    this.readAt,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      workId: json['work_id'],
      senderId: json['sender_id'],
      messageText: json['message_text'],
      messageType: MessageType.values.firstWhere(
        (e) => e.name == json['message_type'],
        orElse: () => MessageType.text,
      ),
      isRead: json['is_read'] ?? false,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'work_id': workId,
      'sender_id': senderId,
      'message_text': messageText,
      'message_type': messageType.name,
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
    };
  }

  // Helper para verificar si es mensaje del sistema
  bool get isSystemMessage => 
      senderId == '00000000-0000-0000-0000-000000000000';
}

enum MessageType {
  text,
  image,
  location,
  system,
}

// ==================== ESTADÍSTICAS DEL TÉCNICO ====================
class TechnicianStats {
  final int totalQuotations;
  final int acceptedQuotations;
  final int completedWorks;
  final double? averageRating;

  TechnicianStats({
    required this.totalQuotations,
    required this.acceptedQuotations,
    required this.completedWorks,
    this.averageRating,
  });

  factory TechnicianStats.fromJson(Map<String, dynamic> json) {
    return TechnicianStats(
      totalQuotations: json['total_quotations'] ?? 0,
      acceptedQuotations: json['accepted_quotations'] ?? 0,
      completedWorks: json['completed_works'] ?? 0,
      averageRating: json['average_rating'] != null
          ? (json['average_rating'] as num).toDouble()
          : null,
    );
  }
}

// ==================== TRABAJO CON DETALLES (para UI) ====================
class WorkWithDetails {
  final AcceptedWork work;
  final String clientName;
  final String technicianName;
  final String requestTitle;
  final String requestDescription;

  WorkWithDetails({
    required this.work,
    required this.clientName,
    required this.technicianName,
    required this.requestTitle,
    required this.requestDescription,
  });
}
