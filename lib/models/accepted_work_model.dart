/// 🎯 Modelo de Trabajo Aceptado (accepted_works)
class AcceptedWork {
  final String id;
  final String requestId;
  final String quotationId;
  final String clientId;
  final String technicianId;
  final String status; // 'pending_payment', 'in_progress', 'completed'
  final String? paymentMethod;
  final double paymentAmount;
  final double? platformFee;
  final double? technicianAmount;
  final String? paymentReference;
  final String? paymentStatus; // 'pending', 'completed', 'failed'
  final DateTime? paidAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? estimatedCompletion;
  final String? workNotes;
  final List<String>? completionPhotos;
  final int? clientRating;
  final String? clientReview;
  final DateTime? ratedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? paymentMetadata;
  final Map<String, dynamic>? braintreeDeviceData;
  
  // 🎯 Chat confirmation fields
  final bool? clientConfirmedChat;
  final bool? technicianConfirmedChat;
  final bool? chatInitialized;

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
    this.paymentStatus,
    this.paidAt,
    this.startedAt,
    this.completedAt,
    this.estimatedCompletion,
    this.workNotes,
    this.completionPhotos,
    this.clientRating,
    this.clientReview,
    this.ratedAt,
    required this.createdAt,
    required this.updatedAt,
    this.paymentMetadata,
    this.braintreeDeviceData,
    this.clientConfirmedChat,
    this.technicianConfirmedChat,
    this.chatInitialized,
  });

  /// Convertir de JSON (Supabase)
  factory AcceptedWork.fromJson(Map<String, dynamic> json) {
    return AcceptedWork(
      id: json['id'] as String,
      requestId: json['request_id'] as String,
      quotationId: json['quotation_id'] as String,
      clientId: json['client_id'] as String,
      technicianId: json['technician_id'] as String,
      status: json['status'] as String,
      paymentMethod: json['payment_method'] as String?,
      paymentAmount: (json['payment_amount'] as num).toDouble(),
      platformFee: json['platform_fee'] != null ? (json['platform_fee'] as num).toDouble() : null,
      technicianAmount: json['technician_amount'] != null ? (json['technician_amount'] as num).toDouble() : null,
      paymentReference: json['payment_reference'] as String?,
      paymentStatus: json['payment_status'] as String?,
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at'] as String) : null,
      startedAt: json['started_at'] != null ? DateTime.parse(json['started_at'] as String) : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at'] as String) : null,
      estimatedCompletion: json['estimated_completion'] != null ? DateTime.parse(json['estimated_completion'] as String) : null,
      workNotes: json['work_notes'] as String?,
      completionPhotos: json['completion_photos'] != null ? List<String>.from(json['completion_photos'] as List) : null,
      clientRating: json['client_rating'] as int?,
      clientReview: json['client_review'] as String?,
      ratedAt: json['rated_at'] != null ? DateTime.parse(json['rated_at'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      paymentMetadata: json['payment_metadata'] as Map<String, dynamic>?,
      braintreeDeviceData: json['braintree_device_data'] as Map<String, dynamic>?,
      clientConfirmedChat: json['client_confirmed_chat'] as bool? ?? false,
      technicianConfirmedChat: json['technician_confirmed_chat'] as bool? ?? false,
      chatInitialized: json['chat_initialized'] as bool? ?? false,
    );
  }

  /// Convertir a JSON para Supabase
  Map<String, dynamic> toJson() => {
    'id': id,
    'request_id': requestId,
    'quotation_id': quotationId,
    'client_id': clientId,
    'technician_id': technicianId,
    'status': status,
    'payment_method': paymentMethod,
    'payment_amount': paymentAmount,
    'platform_fee': platformFee,
    'technician_amount': technicianAmount,
    'payment_reference': paymentReference,
    'payment_status': paymentStatus,
    'paid_at': paidAt?.toIso8601String(),
    'started_at': startedAt?.toIso8601String(),
    'completed_at': completedAt?.toIso8601String(),
    'estimated_completion': estimatedCompletion?.toIso8601String(),
    'work_notes': workNotes,
    'completion_photos': completionPhotos,
    'client_rating': clientRating,
    'client_review': clientReview,
    'rated_at': ratedAt?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'payment_metadata': paymentMetadata,
    'braintree_device_data': braintreeDeviceData,
    'client_confirmed_chat': clientConfirmedChat ?? false,
    'technician_confirmed_chat': technicianConfirmedChat ?? false,
    'chat_initialized': chatInitialized ?? false,
  };

  /// copyWith para crear copias con cambios
  AcceptedWork copyWith({
    String? id,
    String? requestId,
    String? quotationId,
    String? clientId,
    String? technicianId,
    String? status,
    String? paymentMethod,
    double? paymentAmount,
    double? platformFee,
    double? technicianAmount,
    String? paymentReference,
    String? paymentStatus,
    DateTime? paidAt,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? estimatedCompletion,
    String? workNotes,
    List<String>? completionPhotos,
    int? clientRating,
    String? clientReview,
    DateTime? ratedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? paymentMetadata,
    Map<String, dynamic>? braintreeDeviceData,
  }) {
    return AcceptedWork(
      id: id ?? this.id,
      requestId: requestId ?? this.requestId,
      quotationId: quotationId ?? this.quotationId,
      clientId: clientId ?? this.clientId,
      technicianId: technicianId ?? this.technicianId,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentAmount: paymentAmount ?? this.paymentAmount,
      platformFee: platformFee ?? this.platformFee,
      technicianAmount: technicianAmount ?? this.technicianAmount,
      paymentReference: paymentReference ?? this.paymentReference,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paidAt: paidAt ?? this.paidAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      estimatedCompletion: estimatedCompletion ?? this.estimatedCompletion,
      workNotes: workNotes ?? this.workNotes,
      completionPhotos: completionPhotos ?? this.completionPhotos,
      clientRating: clientRating ?? this.clientRating,
      clientReview: clientReview ?? this.clientReview,
      ratedAt: ratedAt ?? this.ratedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      paymentMetadata: paymentMetadata ?? this.paymentMetadata,
      braintreeDeviceData: braintreeDeviceData ?? this.braintreeDeviceData,
      clientConfirmedChat: clientConfirmedChat ?? this.clientConfirmedChat,
      technicianConfirmedChat: technicianConfirmedChat ?? this.technicianConfirmedChat,
      chatInitialized: chatInitialized ?? this.chatInitialized,
    );
  }

  /// ¿Está pagado?
  bool get isPaid => paymentStatus == 'completed';

  /// ¿Está en progreso?
  bool get isInProgress => status == 'in_progress';

  /// ¿Está completado?
  bool get isCompleted => status == 'completed';

  /// ¿Fue calificado?
  bool get isRated => clientRating != null;

  @override
  String toString() => 'AcceptedWork(id: $id, status: $status, amount: \$$paymentAmount)';
}
