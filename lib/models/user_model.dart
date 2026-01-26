enum UserRole { client, technician, admin }

class UserModel {
  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final String? phone;
  final String? sector; // Cambiado de 'address' a 'sector'
  final String? specialty; // Para técnicos
  final String? cedula; // Para técnicos
  final String? profilePhotoUrl; // URL de la foto
  
  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.phone,
    this.sector,
    this.specialty,
    this.cedula,
    this.profilePhotoUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'],
      role: UserRole.values.firstWhere((e) => e.name == json['role']),
      phone: json['phone'],
      sector: json['address'], // En BD sigue siendo 'address'
      specialty: json['specialty'],
      cedula: json['cedula'],
      profilePhotoUrl: json['profile_image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role.name,
      'phone': phone,
      'address': sector, // En BD se guarda como 'address'
      'specialty': specialty,
      'cedula': cedula,
      'profile_image_url': profilePhotoUrl,
    };
  }
}