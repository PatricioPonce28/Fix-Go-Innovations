import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/image_data.dart';
import 'storage_service.dart';

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
      
      // 1. Crear usuario en Supabase Auth
      final AuthResponse authResponse = await _supabase.auth.signUp(
        email: user.email,
        password: password,
      );

      if (authResponse.user == null) {
        return {
          'success': false,
          'message': 'Error al crear usuario. Verifica tu email.',
        };
      }

      print('✅ Usuario creado en Auth: ${authResponse.user!.id}');

      // 2. Subir foto PRIMERO (si existe)
      String? photoUrl;
      if (profileImageData != null) {
        try {
          photoUrl = await _storageService.uploadProfilePhoto(
            profileImageData,
            authResponse.user!.id,
          );
          print('✅ Foto subida: $photoUrl');
        } catch (e) {
          print('⚠️ Error al subir foto: $e');
          // Continuamos sin foto
        }
      }

      // 3. Crear perfil usando función RPC (bypasea RLS)
      final rpcResult = await _supabase.rpc('create_user_profile', params: {
        'user_id': authResponse.user!.id,
        'user_email': user.email,
        'user_full_name': user.fullName,
        'user_phone': user.phone,
        'user_role': user.role.name,
        'user_address': user.sector,
        'user_specialty': user.specialty,
        'user_cedula': user.cedula,
        'user_profile_image_url': photoUrl,
      });

      print('✅ Perfil creado: $rpcResult');

      return {
        'success': true,
        'message': '✅ Registro exitoso. Revisa tu email para verificar tu cuenta.',
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

      // 3. Crear modelo de usuario
      final user = UserModel(
        id: profileData['id'],
        email: profileData['email'],
        fullName: profileData['full_name'],
        role: UserRole.values.firstWhere((e) => e.name == profileData['role']),
        phone: profileData['phone'],
        sector: profileData['address'],
        specialty: profileData['specialty'],
        cedula: profileData['cedula'],
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

      return UserModel(
        id: profileData['id'],
        email: profileData['email'],
        fullName: profileData['full_name'],
        role: UserRole.values.firstWhere((e) => e.name == profileData['role']),
        phone: profileData['phone'],
        sector: profileData['address'],
        specialty: profileData['specialty'],
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
