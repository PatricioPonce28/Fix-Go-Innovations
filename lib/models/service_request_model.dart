class ServiceRequest {
  final String id;
  final String clientId;
  final String title;
  final String description;
  final ServiceType serviceType;
  final String sector;
  final String exactLocation;
  final DateTime? availabilityDate;
  final String? availabilityTime;
  final RequestStatus status;
  final String? assignedTechnicianId;
  final List<String> imageUrls;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final int? quotationsCount; // ← AGREGAR ESTE CAMPO

  ServiceRequest({
    required this.id,
    required this.clientId,
    required this.title,
    required this.description,
    required this.serviceType,
    required this.sector,
    required this.exactLocation,
    this.availabilityDate,
    this.availabilityTime,
    required this.status,
    this.assignedTechnicianId,
    this.imageUrls = const [],
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.quotationsCount, // ← AGREGAR ESTE CAMPO
  });

  factory ServiceRequest.fromJson(Map<String, dynamic> json) {
    return ServiceRequest(
      id: json['id'],
      clientId: json['client_id'],
      title: json['title'],
      description: json['description'],
      serviceType: ServiceType.values.firstWhere(
        (e) => e.name == json['service_type'],
      ),
      sector: json['sector'],
      exactLocation: json['exact_location'],
      availabilityDate: json['availability_date'] != null
          ? DateTime.parse(json['availability_date'])
          : null,
      availabilityTime: json['availability_time'],
      status: RequestStatus.values.firstWhere(
        (e) => e.name == json['status'],
      ),
      assignedTechnicianId: json['assigned_technician_id'],
      imageUrls: json['image_urls'] != null 
          ? List<String>.from(json['image_urls']) 
          : [],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      quotationsCount: json['quotations_count'], // ← AGREGAR ESTE CAMPO
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'title': title,
      'description': description,
      'service_type': serviceType.name,
      'sector': sector,
      'exact_location': exactLocation,
      'availability_date': availabilityDate?.toIso8601String(),
      'availability_time': availabilityTime,
      'status': status.name,
      'assigned_technician_id': assignedTechnicianId,
      'quotations_count': quotationsCount, // ← AGREGAR ESTE CAMPO
    };
  }
}

enum ServiceType {
  emergency,
  new_installation,
}

enum RequestStatus {
  pending,
  assigned,
  in_progress,
  completed,
  cancelled,
}

extension ServiceTypeExtension on ServiceType {
  String get displayName {
    switch (this) {
      case ServiceType.emergency:
        return 'Emergencia';
      case ServiceType.new_installation:
        return 'Instalación Nueva';
    }
  }
}

extension RequestStatusExtension on RequestStatus {
  String get displayName {
    switch (this) {
      case RequestStatus.pending:
        return 'Pendiente';
      case RequestStatus.assigned:
        return 'Asignado';
      case RequestStatus.in_progress:
        return 'En Progreso';
      case RequestStatus.completed:
        return 'Completado';
      case RequestStatus.cancelled:
        return 'Cancelado';
    }
  }
}