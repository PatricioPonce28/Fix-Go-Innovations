// lib/core/supabase_client.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient? _clientInstance;

  Future<void> initialize() async {
    try {
      print('Inicializando Supabase...');

      // Validar configuración
      SupabaseConfig.validateConfig();

      // Configurar Supabase con las credenciales
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
      );

      _clientInstance = Supabase.instance.client;
      print('✅ Supabase cliente inicializado');

      // Configurar listeners de autenticación
      _setupAuthListeners();

      // Probar conexión básica
      await _testConnection();
    } catch (e, stackTrace) {
      print('❌ Error crítico inicializando Supabase: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  void _setupAuthListeners() {
    // Listener para cambios en estado de autenticación
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      print('🔐 Cambio en autenticación: $event');
      if (session != null) {
        print('👤 Usuario autenticado: ${session.user.email}');
      } else {
        print('👤 Usuario no autenticado');
      }
    });
  }

  Future<void> _testConnection() async {
    try {
      print('📡 Probando conexión a Supabase...');

      // Intentar una consulta simple para verificar conexión
      final response = await _clientInstance!
          .from('user_profiles')
          .select('count')
          .limit(1)
          .maybeSingle()
          .timeout(const Duration(seconds: 10))
          .catchError((e) {
        print('⚠️  Error en consulta de prueba: $e');
        return null;
      });

      if (response != null) {
        print('✅ Conexión a Supabase establecida correctamente');
      } else {
        print(
            '⚠️  Conexión establecida, pero la tabla user_profiles puede no existir');
      }
    } catch (e) {
      print('⚠️  Error en prueba de conexión: $e');
      // No relanzamos el error para que la app pueda iniciar
    }
  }

  // Getter para acceder al cliente
  SupabaseClient get client {
    if (_clientInstance == null) {
      throw Exception(
          'Supabase no inicializado. Llama a initialize() primero.');
    }
    return _clientInstance!;
  }

  // Acceso estático rápido
  static SupabaseClient get instance => SupabaseService().client;

  // Métodos helpers para acceso rápido
  static SupabaseClient get supabase => instance;

  // Verificar si está autenticado
  bool get isAuthenticated {
    try {
      return _clientInstance?.auth.currentSession != null;
    } catch (e) {
      return false;
    }
  }

  // Obtener usuario actual
  User? get currentUser {
    try {
      return _clientInstance?.auth.currentUser;
    } catch (e) {
      return null;
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    try {
      await _clientInstance?.auth.signOut();
      print('✅ Sesión cerrada correctamente');
    } catch (e) {
      print('❌ Error cerrando sesión: $e');
      rethrow;
    }
  }
}

// Instancia global para fácil acceso
final supabaseClient = Supabase.instance.client;
