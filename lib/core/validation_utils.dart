/// Utilidades de validación para la aplicación
class ValidationUtils {
  /// Validar email con expresión regular
  static bool isValidEmail(String email) {
    // Expresión regular para validar email
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Obtener mensaje de error para email inválido
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingresa tu email';
    }
    if (!value.contains('@')) {
      return 'El email debe contener @';
    }
    if (!value.contains('.')) {
      return 'El email debe contener un dominio válido';
    }
    if (!isValidEmail(value)) {
      return 'Email inválido. Ej: usuario@ejemplo.com';
    }
    return null;
  }

  /// Validar contraseña
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingresa una contraseña';
    }
    if (value.length < 6) {
      return 'Mínimo 6 caracteres';
    }
    return null;
  }

  /// Validar nombre
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingresa tu nombre completo';
    }
    if (value.length < 3) {
      return 'El nombre debe tener al menos 3 caracteres';
    }
    return null;
  }

  /// Validar teléfono
  static String? validatePhone(String? value) {
    if (value != null && value.isNotEmpty) {
      if (value.length < 7) {
        return 'Teléfono inválido';
      }
    }
    return null;
  }
}
