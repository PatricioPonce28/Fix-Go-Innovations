import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? email;
  final String? token;
  final String? type; // 'recovery', 'signup', etc
  final bool isDeepLink; // Flag para saber si vino por deep link

  const ResetPasswordScreen({
    super.key,
    this.email,
    this.token,
    this.type = 'recovery',
    this.isDeepLink = false,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _authService = AuthService();
  final _supabase = Supabase.instance.client;
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  String? _errorMessage;
  String? _successMessage;
  bool _tokenVerified = false;

  @override
  void initState() {
    super.initState();
    // Si viene por deep link, verificar el token con Supabase
    if (widget.isDeepLink && widget.token != null && widget.token!.isNotEmpty) {
      _verifyTokenWithSupabase();
    } else {
      _tokenVerified = true; // Si no es deep link, permiter cambio directo
    }
  }

  /// 🔐 Verificar token con Supabase (para deep links)
  Future<void> _verifyTokenWithSupabase() async {
    try {
      debugPrint('🔍 Verificando token: ${widget.token}');
      
      // Verificar OTP token con Supabase
      final response = await _supabase.auth.verifyOTP(
        token: widget.token!,
        type: OtpType.recovery,
        email: widget.email,
      );

      if (response.user != null) {
        setState(() {
          _tokenVerified = true;
          _successMessage = '✅ Token verificado. Ahora puedes cambiar tu contraseña.';
        });
        debugPrint('✅ Token verificado exitosamente');
      }
    } catch (e) {
      debugPrint('❌ Error verificando token: $e');
      setState(() {
        _tokenVerified = false;
        _errorMessage = 'Token inválido o expirado. Por favor intenta de nuevo.';
      });
    }
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    setState(() => _errorMessage = null);

    // Validar que token esté verificado si es deep link
    if (widget.isDeepLink && !_tokenVerified) {
      setState(() => _errorMessage = 'El token no ha sido verificado. Por favor intenta de nuevo.');
      return;
    }

    if (_newPasswordController.text.isEmpty) {
      setState(() => _errorMessage = 'Por favor ingresa tu nueva contraseña');
      return;
    }

    if (_confirmPasswordController.text.isEmpty) {
      setState(() => _errorMessage = 'Por favor confirma tu contraseña');
      return;
    }

    if (_newPasswordController.text.length < 6) {
      setState(() => _errorMessage = 'La contraseña debe tener al menos 6 caracteres');
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Las contraseñas no coinciden');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 🔐 Si viene por deep link, usar Supabase directamente (ya tiene sesión)
      if (widget.isDeepLink && widget.token != null) {
        debugPrint('🔄 Actualizando contraseña vía deep link...');
        await _supabase.auth.updateUser(
          UserAttributes(password: _newPasswordController.text),
        );
        debugPrint('✅ Contraseña actualizada por deep link');
      } else {
        // 🔑 Si no es deep link, usar updatePassword estándar
        debugPrint('🔄 Actualizando contraseña directamente...');
        final result = await _authService.updatePassword(_newPasswordController.text);
        if (!result['success']) {
          throw Exception(result['message']);
        }
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
      
      setState(() => _successMessage = '✅ Contraseña actualizada exitosamente');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Contraseña actualizada exitosamente'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      _newPasswordController.clear();
      _confirmPasswordController.clear();

      // Volver a login después de 2 segundos
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('❌ Error al actualizar contraseña: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      
      setState(() => _errorMessage = 'Error: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool showPassword,
    required VoidCallback onToggleVisibility,
  }) {
    return TextField(
      controller: controller,
      obscureText: !showPassword,
      enabled: !_isLoading,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(showPassword ? Icons.visibility : Icons.visibility_off),
          onPressed: onToggleVisibility,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restablecer Contraseña'),
        elevation: 0,
        backgroundColor: Colors.blue[600],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  size: 40,
                  color: Colors.green[600],
                ),
              ),
            ),
            const SizedBox(height: 32),

            const Text(
              'Restablecer tu Contraseña',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              'Ingresa tu nueva contraseña para acceder nuevamente',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            // 🔗 Token Verification Status (para Deep Links)
            if (widget.isDeepLink)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _tokenVerified ? Colors.green[50] : Colors.orange[50],
                  border: Border.all(
                    color: _tokenVerified ? Colors.green : Colors.orange,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _tokenVerified ? Icons.verified : Icons.info,
                      color: _tokenVerified ? Colors.green : Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _tokenVerified 
                          ? '✅ Token verificado. Puedes cambiar tu contraseña.'
                          : '⏳ Verificando token...',
                        style: TextStyle(
                          fontSize: 12,
                          color: _tokenVerified ? Colors.green[700] : Colors.orange[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 32),

            if (_errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            if (_errorMessage != null) const SizedBox(height: 16),

            if (_successMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _successMessage!,
                        style: TextStyle(color: Colors.green[800]),
                      ),
                    ),
                  ],
                ),
              ),
            if (_successMessage != null) const SizedBox(height: 16),

            _buildPasswordField(
              controller: _newPasswordController,
              label: 'Nueva Contraseña',
              hint: 'Ingresa tu nueva contraseña',
              showPassword: _showNewPassword,
              onToggleVisibility: () {
                setState(() => _showNewPassword = !_showNewPassword);
              },
            ),
            const SizedBox(height: 16),

            _buildPasswordField(
              controller: _confirmPasswordController,
              label: 'Confirmar Contraseña',
              hint: 'Confirma tu contraseña',
              showPassword: _showConfirmPassword,
              onToggleVisibility: () {
                setState(() => _showConfirmPassword = !_showConfirmPassword);
              },
            ),
            const SizedBox(height: 24),

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
                  Text(
                    'Requisitos:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildRequirement('Mínimo 6 caracteres'),
                  _buildRequirement('Las contraseñas deben coincidir'),
                ],
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleResetPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Restablecer Contraseña',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                border: Border.all(color: Colors.orange[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange[600],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Este enlace solo es válido durante 24 horas. Después deberás solicitar uno nuevo.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirement(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            size: 16,
            color: Colors.blue[600],
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue[700],
            ),
          ),
        ],
      ),
    );
  }
}
