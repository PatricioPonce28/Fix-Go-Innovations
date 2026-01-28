import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final String userType;
  final String userName;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    required this.userType,
    required this.userName,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _supabase = Supabase.instance.client;
  final _authService = AuthService();
  
  bool _isLoading = false;
  bool _isVerified = false;
  bool _showResendOption = false;
  int _checkCount = 0;
  static const int _maxChecks = 30;

  @override
  void initState() {
    super.initState();
    _startVerificationCheck();
  }

  void _startVerificationCheck() {
    _checkEmailVerification();
  }

  Future<void> _checkEmailVerification() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);

    try {
      await Future.delayed(const Duration(seconds: 2));

      final session = _supabase.auth.currentSession;
      
      print('🔍 Intento de verificación #$_checkCount');
      print('📧 Email confirmado: ${session?.user.emailConfirmedAt}');

      if (session != null && session.user.emailConfirmedAt != null) {
        print('✅ EMAIL VERIFICADO EXITOSAMENTE');
        
        setState(() {
          _isVerified = true;
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Email verificado correctamente'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            Navigator.pop(context, true);
          }
        }
      } else {
        _checkCount++;
        
        if (_checkCount < _maxChecks) {
          setState(() => _isLoading = false);
          
          if (_checkCount > 6) {
            setState(() => _showResendOption = true);
          }
          
          await Future.delayed(const Duration(seconds: 10));
          if (mounted) {
            _startVerificationCheck();
          }
        } else {
          print('❌ Máximo de intentos alcanzado');
          setState(() {
            _isLoading = false;
            _showResendOption = true;
          });
        }
      }
    } catch (e) {
      print('❌ Error verificando email: $e');
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    setState(() => _isLoading = true);

    try {
      final result = await _authService.resendConfirmationEmail(widget.email);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: result['success'] ? Colors.green : Colors.red,
          ),
        );
      }

      if (result['success']) {
        setState(() {
          _isLoading = false;
          _showResendOption = false;
          _checkCount = 0;
        });

        _startVerificationCheck();
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Verificar Email'),
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              _isVerified
                  ? Icon(
                      Icons.check_circle,
                      size: 100,
                      color: Colors.green[600],
                    )
                  : Icon(
                      Icons.mail_outline,
                      size: 100,
                      color: Colors.blue[600],
                    ),
              const SizedBox(height: 24),

              Text(
                _isVerified ? '✅ Email Verificado' : '📧 Verifica tu Email',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              Text(
                _isVerified
                    ? 'Tu email ha sido verificado correctamente. Serás redirigido a continuación.'
                    : 'Hemos enviado un enlace de verificación a:\n\n${widget.email}\n\nRevisa tu email (incluida la carpeta de spam) y haz clic en el enlace para verificar tu cuenta.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              if (_isLoading)
                Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(
                      'Verificando tu email...',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Intento $_checkCount/$_maxChecks',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 24),

              if (_showResendOption && !_isVerified)
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _resendVerificationEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '🔄 Reenviar Email de Verificación',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              if (!_isVerified) const SizedBox(height: 24),

              if (!_isVerified)
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Volver al Login'),
                ),

              const SizedBox(height: 40),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  border: Border.all(color: Colors.blue[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Consejos de verificación',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '• Revisa la carpeta de spam\n'
                      '• Espera a que llegue el email\n'
                      '• El enlace es válido por 24 horas\n'
                      '• Haz clic en "Reenviar" si no recibes nada',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[800],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
