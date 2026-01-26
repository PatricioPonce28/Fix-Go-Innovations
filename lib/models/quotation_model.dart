class Quotation {
  final String id;
  final String requestId;
  final String technicianId;
  final String clientId;
  
  // Información del técnico
  final String technicianName;
  final String? technicianRuc;
  final String quotationNumber;
  
  // Detalle del trabajo
  final String solutionTitle;
  final String workDescription;
  final String? includedMaterials;
  final String estimatedLabor;
  final String? specialConditions;
  
  // Costos
  final double materialsSubtotal;
  final double laborSubtotal;
  final double taxAmount;
  final double totalAmount;
  
  // Notas
  final String estimatedTime;
  final String? warrantyOffered;
  final int validityDays;
  final String? additionalNotes;
  
  // Estado
  final QuotationStatus status;
  
  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? expiresAt;

  Quotation({
    required this.id,
    required this.requestId,
    required this.technicianId,
    required this.clientId,
    required this.technicianName,
    this.technicianRuc,
    required this.quotationNumber,
    required this.solutionTitle,
    required this.workDescription,
    this.includedMaterials,
    required this.estimatedLabor,
    this.specialConditions,
    required this.materialsSubtotal,
    required this.laborSubtotal,
    required this.taxAmount,
    required this.totalAmount,
    required this.estimatedTime,
    this.warrantyOffered,
    required this.validityDays,
    this.additionalNotes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.expiresAt,
  });

  factory Quotation.fromJson(Map<String, dynamic> json) {
    return Quotation(
      id: json['id'],
      requestId: json['request_id'],
      technicianId: json['technician_id'],
      clientId: json['client_id'],
      technicianName: json['technician_name'],
      technicianRuc: json['technician_ruc'],
      quotationNumber: json['quotation_number'],
      solutionTitle: json['solution_title'],
      workDescription: json['work_description'],
      includedMaterials: json['included_materials'],
      estimatedLabor: json['estimated_labor'],
      specialConditions: json['special_conditions'],
      materialsSubtotal: (json['materials_subtotal'] ?? 0).toDouble(),
      laborSubtotal: json['labor_subtotal'].toDouble(),
      taxAmount: (json['tax_amount'] ?? 0).toDouble(),
      totalAmount: json['total_amount'].toDouble(),
      estimatedTime: json['estimated_time'],
      warrantyOffered: json['warranty_offered'],
      validityDays: json['validity_days'] ?? 7,
      additionalNotes: json['additional_notes'],
      status: QuotationStatus.values.firstWhere(
        (e) => e.name == json['status'],
      ),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'request_id': requestId,
      'technician_id': technicianId,
      'client_id': clientId,
      'technician_name': technicianName,
      'technician_ruc': technicianRuc,
      'quotation_number': quotationNumber,
      'solution_title': solutionTitle,
      'work_description': workDescription,
      'included_materials': includedMaterials,
      'estimated_labor': estimatedLabor,
      'special_conditions': specialConditions,
      'materials_subtotal': materialsSubtotal,
      'labor_subtotal': laborSubtotal,
      'tax_amount': taxAmount,
      'total_amount': totalAmount,
      'estimated_time': estimatedTime,
      'warranty_offered': warrantyOffered,
      'validity_days': validityDays,
      'additional_notes': additionalNotes,
      'status': status.name,
    };
  }

  // Helper para verificar si está expirada
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  // Helper para días restantes
  int get daysRemaining {
    if (expiresAt == null) return validityDays;
    final diff = expiresAt!.difference(DateTime.now());
    return diff.inDays.clamp(0, validityDays);
  }
}

enum QuotationStatus {
  pending,
  accepted,
  rejected,
  expired,
}

extension QuotationStatusExtension on QuotationStatus {
  String get displayName {
    switch (this) {
      case QuotationStatus.pending:
        return 'Pendiente';
      case QuotationStatus.accepted:
        return 'Aceptada';
      case QuotationStatus.rejected:
        return 'Rechazada';
      case QuotationStatus.expired:
        return 'Expirada';
    }
  }
}