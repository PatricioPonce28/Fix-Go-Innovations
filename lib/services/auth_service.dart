import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import 'storage_service.dart';
import '../models/image_data.dart'; // Import the correct file where ImageData is defined, adjust the path as needed

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final StorageService _storageService = StorageService();

  // ==================== REGISTRO ====================
  Future<Map<String, dynamic>> register(
    UserModel user,
    String password,
    ImageData? profileImageData,
  ) async {
    try {
      print('📝 Iniciando registro para: ${user.email}');
      
      // 1. PRIMERO subir la foto (sin autenticación)
      String? photoUrl;
      if (profileImageData != null) {
        try {
          // Generar nombre temporal único
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final fileName = 'temp_${timestamp}_${profileImageData.name}';
          
          await _supabase.storage
            .from('profile-images')
            .uploadBinary(
              fileName,
              profileImageData.bytes,
              fileOptions: FileOptions(
                contentType: 'image/jpeg',
                upsert: false,
              ),
            );

          photoUrl = _supabase.storage
            .from('profile-images')
            .getPublicUrl(fileName);
          
          print('✅ Foto subida: $photoUrl');
        } catch (e) {
          print('❌ Error al subir foto: $e');
          // Continuamos sin foto si falla
        }
      }

      // 2. Preparar metadata para el trigger
      final metadata = {
        'full_name': user.fullName,
        'role': user.role.name,
        'phone': user.phone,
        'address': user.sector, // Se guarda como 'address' en BD
        if (user.specialty != null) 'specialty': user.specialty,
        if (user.cedula != null) 'cedula': user.cedula,
        if (photoUrl != null) 'profile_image_url': photoUrl,
      };

      print('📤 Registrando usuario con metadata: $metadata');

      // 3. Crear usuario en Supabase Auth
      // El trigger creará el perfil cuando confirme email
      final AuthResponse authResponse = await _supabase.auth.signUp(
        email: user.email,
        password: password,
        data: metadata,
      );

      if (authResponse.user == null) {
        return {
          'success': false,
          'message': 'Error al crear usuario. Verifica tu email.',
        };
      }

      print('✅ Usuario creado en Auth: ${authResponse.user!.id}');

      // 4. Si es técnico, guardar datos adicionales para crear después
      // (Se crearán cuando confirme el email)
      if (user.role == UserRole.technician && user.specialty != null) {
        print('ℹ️ Técnico registrado. Los datos se completarán al confirmar email.');
      }

      return {
        'success': true,
        'message': '✅ Cuenta creada. Revisa tu email para confirmar tu cuenta.',
      };
      
    } on AuthException catch (e) {
      print('❌ Error de autenticación: ${e.message}');
      return {
        'success': false,
        'message': _handleAuthError(e.message),
      };
    } catch (e) {
      print('❌ Error inesperado: $e');
      return {
        'success': false,
        'message': 'Error al registrar usuario: ${e.toString()}',
      };
    }
  }

  // ==================== COMPLETAR PERFIL DE TÉCNICO ====================
  // Esta función se llama después del primer login
  Future<void> _completeTechnicianProfile(String userId, String specialty) async {
    try {
      // Buscar o crear la especialidad
      final specialtyResponse = await _supabase
          .from('specialties')
          .select('id')
          .eq('name', specialty)
          .maybeSingle();

      int? specialtyId = specialtyResponse?['id'];

      // Si no existe la especialidad, crearla
      if (specialtyId == null) {
        final newSpecialty = await _supabase
            .from('specialties')
            .insert({'name': specialty})
            .select('id')
            .single();
        specialtyId = newSpecialty['id'];
      }

      // Verificar si ya existe la relación
      final existingRelation = await _supabase
          .from('technician_specialties')
          .select('id')
          .eq('technician_id', userId)
          .maybeSingle();

      if (existingRelation == null) {
        // Asociar técnico con especialidad
        await _supabase.from('technician_specialties').insert({
          'technician_id': userId,
          'specialty_id': specialtyId,
          'experience_years': 0,
        });

        // Crear registro de verificación pendiente
        final existingVerification = await _supabase
            .from('technician_verification')
            .select('id')
            .eq('technician_id', userId)
            .maybeSingle();

        if (existingVerification == null) {
          await _supabase.from('technician_verification').insert({
            'technician_id': userId,
            'status': 'pending',
          });
        }

        print('✅ Datos de técnico completados');
      }
    } catch (e) {
      print('⚠️ Error al completar perfil de técnico: $e');
      // No lanzamos error para no bloquear el login
    }
  }

  // ==================== LOGIN ====================
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('🔐 Iniciando login para: $email');
      
      // 1. Autenticar con Supabase
      final AuthResponse response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return {
          'success': false,
          'message': 'Credenciales incorrectas',
        };
      }

      print('✅ Usuario autenticado: ${response.user!.id}');

      // 2. Obtener perfil del usuario
      final profileData = await _supabase
          .from('user_profiles')
          .select('*')
          .eq('id', response.user!.id)
          .single();

      print('✅ Perfil obtenido: ${profileData['full_name']}');

      // 3. Si es técnico, obtener especialidades y completar perfil si falta
      String? specialty;
      String? cedula = profileData['cedula'];
      
      if (profileData['role'] == 'technician') {
        final techSpecialties = await _supabase
            .from('technician_specialties')
            .select('specialty_id, specialties(name)')
            .eq('technician_id', response.user!.id)
            .maybeSingle();

        if (techSpecialties != null) {
          specialty = techSpecialties['specialties']['name'];
        } else {
          // Si no tiene especialidad en la tabla pero sí en metadata, completar
          specialty = profileData['specialty'];
          if (specialty != null) {
            await _completeTechnicianProfile(response.user!.id, specialty);
          }
        }
      }

      // 4. Crear modelo de usuario
      final user = UserModel(
        id: profileData['id'],
        email: profileData['email'],
        fullName: profileData['full_name'],
        role: UserRole.values.firstWhere((e) => e.name == profileData['role']),
        phone: profileData['phone'],
        sector: profileData['address'],
        specialty: specialty ?? profileData['specialty'],
        cedula: cedula,
        profilePhotoUrl: profileData['profile_image_url'],
      );

      return {
        'success': true,
        'message': 'Login exitoso',
        'user': user,
      };
      
    } on AuthException catch (e) {
      print('❌ Error de autenticación: ${e.message}');
      return {
        'success': false,
        'message': _handleAuthError(e.message),
      };
    } catch (e) {
      print('❌ Error inesperado en login: $e');
      return {
        'success': false,
        'message': 'Error al iniciar sesión: ${e.toString()}',
      };
    }
  }

  // ==================== OBTENER USUARIO ACTUAL ====================
  Future<UserModel?> getCurrentUser() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) return null;

      final profileData = await _supabase
          .from('user_profiles')
          .select('*')
          .eq('id', session.user.id)
          .single();

      String? specialty;
      if (profileData['role'] == 'technician') {
        final techSpecialties = await _supabase
            .from('technician_specialties')
            .select('specialty_id, specialties(name)')
            .eq('technician_id', session.user.id)
            .maybeSingle();

        if (techSpecialties != null) {
          specialty = techSpecialties['specialties']['name'];
        } else {
          specialty = profileData['specialty'];
        }
      }

      return UserModel(
        id: profileData['id'],
        email: profileData['email'],
        fullName: profileData['full_name'],
        role: UserRole.values.firstWhere((e) => e.name == profileData['role']),
        phone: profileData['phone'],
        sector: profileData['address'],
        specialty: specialty,
        cedula: profileData['cedula'],
        profilePhotoUrl: profileData['profile_image_url'],
      );
    } catch (e) {
      print('❌ Error al obtener usuario actual: $e');
      return null;
    }
  }

  // ==================== LOGOUT ====================
  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
      print('✅ Sesión cerrada correctamente');
    } catch (e) {
      print('❌ Error al cerrar sesión: $e');
      rethrow;
    }
  }

  // ==================== VERIFICAR SI ESTÁ AUTENTICADO ====================
  bool isAuthenticated() {
    return _supabase.auth.currentSession != null;
  }

  // ==================== OBTENER SESIÓN ACTUAL ====================
  Session? getCurrentSession() {
    return _supabase.auth.currentSession;
  }

  // ==================== RESETEAR CONTRASEÑA ====================
  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      return {
        'success': true,
        'message': 'Revisa tu email para restablecer tu contraseña',
      };
    } on AuthException catch (e) {
      return {
        'success': false,
        'message': _handleAuthError(e.message),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  // ==================== STREAM DE CAMBIOS DE AUTH ====================
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // ==================== MANEJAR ERRORES ====================
  String _handleAuthError(String error) {
    final errorLower = error.toLowerCase();
    
    if (errorLower.contains('already registered') || 
        errorLower.contains('already been registered') ||
        errorLower.contains('user already registered')) {
      return 'Este email ya está registrado';
    }
    if (errorLower.contains('invalid login credentials') || 
        errorLower.contains('invalid credentials')) {
      return 'Email o contraseña incorrectos';
    }
    if (errorLower.contains('email not confirmed')) {
      return 'Debes confirmar tu email antes de iniciar sesión. Revisa tu correo.';
    }
    if (errorLower.contains('password')) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    if (errorLower.contains('email')) {
      return 'Email inválido';
    }
    
    return error;
  }
}