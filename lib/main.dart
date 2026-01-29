import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'core/supabase_client.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/auth/email_verification_screen.dart';
import 'screens/help/help_support_screen.dart';
import 'screens/profile/change_password_screen.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('es_ES', null); 
  
  try {
    // 1. Cargar variables de entorno
    await dotenv.load(fileName: '.env');
    print('✅ Variables de entorno cargadas');
    
    // 2. Inicializar Supabase
    await SupabaseService().initialize();
    print('✅ Supabase conectado exitosamente');
    
    runApp(const MyApp());
  } catch (e, stackTrace) {
    print('Error crítico en inicialización: $e');
    print('Stack trace: $stackTrace');
    
    // Mostrar pantalla de error
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Error de Configuración',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 🔗 GoRouter Setup with Deep Link Support
    final router = GoRouter(
      routes: [
        // 🏠 Home/Login Route
        GoRoute(
          path: '/',
          builder: (context, state) => const LoginScreen(),
        ),
        
        // 🔐 Login Route
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        
        // ❓ Forgot Password Route
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        
        // 🔗 DEEP LINK: Reset Password Route
        // Handles: https://vercel-deeplink.vercel.app/reset-password?token=XXX&type=recovery
        // Also handles: fixgo://reset-password?token=XXX
        GoRoute(
          path: '/reset-password',
          builder: (context, state) {
            // Extract token from query parameters
            final token = state.uri.queryParameters['token'] ?? 
                         state.uri.queryParameters['access_token'] ?? '';
            final type = state.uri.queryParameters['type'] ?? 'recovery';
            
            debugPrint('🔗 Deep Link URI: ${state.uri}');
            debugPrint('🔐 Token: $token, Type: $type');
            
            return ResetPasswordScreen(
              token: token,
              type: type,
              isDeepLink: true,
            );
          },
        ),
        
        // 🔗 DEEP LINK: Confirm Email Route
        // Handles: https://vercel-deeplink.vercel.app/confirm-email?token=XXX&type=signup
        // Also handles: fixgo://confirm-email?token=XXX
        GoRoute(
          path: '/confirm-email',
          builder: (context, state) {
            // Extract token from query parameters
            final token = state.uri.queryParameters['token'] ?? 
                         state.uri.queryParameters['access_token'] ?? '';
            final type = state.uri.queryParameters['type'] ?? 'signup';
            
            debugPrint('🔗 Deep Link URI: ${state.uri}');
            debugPrint('📧 Token: $token, Type: $type');
            
            return EmailVerificationScreen(
              token: token,
              type: type,
              isDeepLink: true,
            );
          },
        ),
        
        // 🔑 Change Password Route
        GoRoute(
          path: '/change-password',
          builder: (context, state) => const ChangePasswordScreen(),
        ),
        
        // ❓ Help & Support Route
        GoRoute(
          path: '/help-support',
          builder: (context, state) => const HelpSupportScreen(),
        ),
      ],
      
      // Handle deep links and redirects
      redirect: (context, state) {
        debugPrint('📍 GoRouter Redirect: ${state.uri}');
        return null;
      },
    );
    
    return MaterialApp.router(
      title: 'Fix&Go Innovations',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
          ),
        ),
      ),
    );
  }
}
