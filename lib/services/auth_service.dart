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
      print('📝 PASO 1/5: Iniciando registro para: ${user.email}');
      
      // 1️⃣ CREAR USUARIO EN SUPABASE AUTH
      final AuthResponse authResponse = await _supabase.auth.signUp(
        email: user.email,
        password: password,
        emailRedirectTo: 'io.supabase.fixgoinnovations://login-callback',
      );

      if (authResponse.user == null) {
        return {
          'success': false,
          'message': 'Error al crear usuario. Verifica tu email.',
          'emailSent': false,
        };
      }

      print('✅ PASO 2/5: Usuario creado en Auth (sin confirmar): ${authResponse.user!.id}');

      // 2️⃣ SUBIR FOTO DE PERFIL (si existe)
      String? photoUrl;
      if (profileImageData != null) {
        try {
          photoUrl = await _storageService.uploadProfilePhoto(
            profileImageData,
            authResponse.user!.id,
          );
          print('✅ PASO 3/5: Foto subida: $photoUrl');
        } catch (e) {
          print('⚠️ Error al subir foto (continuando): $e');
        }
      } else {
        print('ℹ️ PASO 3/5: Sin foto de perfil');
      }

      // 3️⃣ CREAR PERFIL EN BASE DE DATOS
      try {
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
        print('✅ PASO 4/5: Perfil creado en DB: $rpcResult');
      } catch (e) {
        print('❌ Error al crear perfil: $e');
        // No abortamos, el usuario ya está creado en Auth
        // Podría intentar recrear el perfil luego
      }

      // 4️⃣ EMAIL DE CONFIRMACIÓN ENVIADO AUTOMÁTICAMENTE POR SUPABASE
      print('✅ PASO 5/5: Email de confirmación enviado a: ${user.email}');

      return {
        'success': true,
        'message': '✅ Registro exitoso. Revisa tu email para verificar tu cuenta.',
        'emailSent': true,
        'userId': authResponse.user!.id,
        'email': user.email,
        'userType': user.role.name,
        'userName': user.fullName,
      };
      
    } on AuthException catch (e) {
      print('❌ Error de autenticación: ${e.message}');
      return {
        'success': false,
        'message': _handleAuthError(e.message),
        'emailSent': false,
      };
    } catch (e) {
      print('❌ Error inesperado: $e');
      return {
        'success': false,
        'message': 'Error al registrar usuario: ${e.toString()}',
        'emailSent': false,
      };
    }
  }

  // ==================== REENVIAR EMAIL DE CONFIRMACIÓN ====================
  Future<Map<String, dynamic>> resendConfirmationEmail(String email) async {
    try {
      print('📧 Reenviando email de confirmación a: $email');
      
      // Usar el método de Supabase para reenviar OTP
      await _supabase.auth.signUp(
        email: email,
        password: 'temporary_pass_12345', // Temporal, solo para reenviar
        emailRedirectTo: 'io.supabase.fixgoinnovations://login-callback',
      );
      
      print('✅ Email de confirmación reenviado');
      return {
        'success': true,
        'message': '✅ Email reenviado. Revisa tu bandeja de entrada.',
      };
    } on AuthException catch (e) {
      print('❌ Error reenviando email: ${e.message}');
      return {
        'success': false,
        'message': 'Error: ${e.message}',
      };
    } catch (e) {
      print('❌ Error inesperado: $e');
      return {
        'success': false,
        'message': 'Error al reenviar email: ${e.toString()}',
      };
    }
  }

  // ==================== VERIFICAR EMAIL ====================
  Future<bool> isEmailVerified() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) return false;
      
      final isVerified = session.user.emailConfirmedAt != null;
      print('📧 Email verificado: $isVerified');
      return isVerified;
    } catch (e) {
      print('❌ Error verificando email: $e');
      return false;
    }
  }

  // ==================== LOGIN ====================
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('🔐 PASO 1/4: Iniciando login para: $email');
      
      // 1️⃣ AUTENTICAR CON SUPABASE
      final AuthResponse response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return {
          'success': false,
          'message': 'Credenciales incorrectas',
          'emailVerified': false,
        };
      }

      print('✅ PASO 2/4: Usuario autenticado: ${response.user!.id}');

      // 2️⃣ VERIFICAR SI EMAIL ESTÁ CONFIRMADO
      final emailVerified = response.user!.emailConfirmedAt != null;
      print('✅ PASO 3/4: Email verificado: $emailVerified');

      if (!emailVerified) {
        print('⚠️ Email sin confirmar, solicitando verificación');
        return {
          'success': false,
          'message': 'Por favor verifica tu email para continuar',
          'emailVerified': false,
          'requiresVerification': true,
          'email': email,
        };
      }

      // 3️⃣ OBTENER PERFIL DEL USUARIO
      final profileData = await _supabase
          .from('user_profiles')
          .select('*')
          .eq('id', response.user!.id)
          .single();

      print('✅ PASO 4/4: Perfil obtenido: ${profileData['full_name']}');

      // 4️⃣ CREAR MODELO DE USUARIO Y RETORNAR
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
        'emailVerified': true,
      };
      
    } on AuthException catch (e) {
      print('❌ Error de autenticación: ${e.message}');
      return {
        'success': false,
        'message': _handleAuthError(e.message),
        'emailVerified': false,
      };
    } catch (e) {
      print('❌ Error inesperado en login: $e');
      return {
        'success': false,
        'message': 'Error al iniciar sesión: ${e.toString()}',
        'emailVerified': false,
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

  // ==================== ACTUALIZAR PERFIL ====================
  Future<Map<String, dynamic>> updateUserProfile({
    required String userId,
    String? fullName,
    String? phone,
    String? sector,
    String? specialty,
    String? cedula,
    ImageData? profileImageData,
  }) async {
    try {
      print('🔄 Actualizando perfil del usuario: $userId');

      String? photoUrl;
      
      // Subir nueva foto si existe
      if (profileImageData != null) {
        try {
          photoUrl = await _storageService.uploadProfilePhoto(
            profileImageData,
            userId,
          );
          print('✅ Foto actualizada: $photoUrl');
        } catch (e) {
          print('⚠️ Error al subir foto: $e');
          return {
            'success': false,
            'message': 'Error al subir la foto de perfil',
          };
        }
      }

      // Construir map de actualización
      final updateData = <String, dynamic>{};
      if (fullName != null) updateData['full_name'] = fullName;
      if (phone != null) updateData['phone'] = phone;
      if (sector != null) updateData['address'] = sector;
      if (specialty != null) updateData['specialty'] = specialty;
      if (cedula != null) updateData['cedula'] = cedula;
      if (photoUrl != null) updateData['profile_image_url'] = photoUrl;

      if (updateData.isEmpty) {
        return {
          'success': false,
          'message': 'No hay cambios que actualizar',
        };
      }

      // Actualizar en user_profiles
      await _supabase
          .from('user_profiles')
          .update(updateData)
          .eq('id', userId);

      print('✅ Perfil actualizado exitosamente');

      return {
        'success': true,
        'message': 'Perfil actualizado exitosamente',
      };
    } catch (e) {
      print('❌ Error al actualizar perfil: $e');
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  // ==================== CAMBIAR CONTRASEÑA ====================
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
    required String email,
  }) async {
    try {
      print('🔐 Iniciando cambio de contraseña para: $email');

      // 1️⃣ VALIDACIONES
      if (currentPassword.isEmpty) {
        return {
          'success': false,
          'message': 'Debes ingresar tu contraseña actual',
        };
      }

      if (newPassword.isEmpty) {
        return {
          'success': false,
          'message': 'Debes ingresar una nueva contraseña',
        };
      }

      if (confirmPassword.isEmpty) {
        return {
          'success': false,
          'message': 'Debes confirmar tu nueva contraseña',
        };
      }

      if (newPassword.length < 6) {
        return {
          'success': false,
          'message': 'La contraseña debe tener al menos 6 caracteres',
        };
      }

      if (newPassword != confirmPassword) {
        return {
          'success': false,
          'message': 'Las contraseñas no coinciden',
        };
      }

      if (currentPassword == newPassword) {
        return {
          'success': false,
          'message': 'La nueva contraseña debe ser diferente a la actual',
        };
      }

      // 2️⃣ VERIFICAR CONTRASEÑA ACTUAL (Re-autenticar)
      print('🔍 Verificando contraseña actual...');
      try {
        await _supabase.auth.signInWithPassword(
          email: email,
          password: currentPassword,
        );
        print('✅ Contraseña actual verificada');
      } on AuthException catch (e) {
        print('❌ Contraseña actual incorrecta: ${e.message}');
        return {
          'success': false,
          'message': 'Tu contraseña actual es incorrecta',
        };
      }

      // 3️⃣ ACTUALIZAR CONTRASEÑA
      print('🔄 Actualizando contraseña...');
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      print('✅ Contraseña actualizada exitosamente');

      return {
        'success': true,
        'message': 'Contraseña actualizada exitosamente',
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
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  // ==================== ACTUALIZAR CONTRASEÑA (LEGACY) ====================
  Future<Map<String, dynamic>> updatePassword(
    String newPassword,
  ) async {
    try {
      print('🔐 Cambiando contraseña');

      // Validar contraseña
      if (newPassword.length < 6) {
        return {
          'success': false,
          'message': 'La contraseña debe tener al menos 6 caracteres',
        };
      }

      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      print('✅ Contraseña actualizada exitosamente');

      return {
        'success': true,
        'message': 'Contraseña actualizada exitosamente',
      };
    } on AuthException catch (e) {
      print('❌ Error al cambiar contraseña: ${e.message}');
      return {
        'success': false,
        'message': _handleAuthError(e.message),
      };
    } catch (e) {
      print('❌ Error inesperado: $e');
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  // ==================== ELIMINAR CUENTA ====================
  Future<Map<String, dynamic>> deleteAccount(String userId) async {
    try {
      print('🗑️ Eliminando cuenta: $userId');

      // Marcar usuario como eliminado en lugar de borrar
      await _supabase
          .from('user_profiles')
          .update({'is_deleted': true})
          .eq('id', userId);

      // Cerrar sesión
      await logout();

      print('✅ Cuenta eliminada exitosamente');

      return {
        'success': true,
        'message': 'Cuenta eliminada exitosamente',
      };
    } catch (e) {
      print('❌ Error al eliminar cuenta: $e');
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
