import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/image_data.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../core/validation_utils.dart';
import 'registration_confirmation_screen.dart';

class RegisterTechnicianScreen extends StatefulWidget {
  const RegisterTechnicianScreen({super.key});

  @override
  State<RegisterTechnicianScreen> createState() => _RegisterTechnicianScreenState();
}

class _RegisterTechnicianScreenState extends State<RegisterTechnicianScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cedulaController = TextEditingController();
  final _otherSpecialtyController = TextEditingController();
  final _authService = AuthService();
  final _storageService = StorageService();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  ImageData? _profileImageData;
  String? _selectedSpecialty;
  bool _showOtherSpecialty = false;

  final List<String> _specialties = [
    'Plomero',
    'Electricista',
    'Cerrajero',
    'Albañil',
    'Carpintero',
    'Pintor',
    'Técnico de Aires Acondicionados',
    'Mecánico',
    'Otro',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _cedulaController.dispose();
    _otherSpecialtyController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tomar foto'),
              onTap: () async {
                Navigator.pop(context);
                final imageData = await _storageService.takePhoto();
                if (imageData != null) {
                  setState(() => _profileImageData = imageData);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Elegir de galería'),
              onTap: () async {
                Navigator.pop(context);
                final imageData = await _storageService.pickImageFromGallery();
                if (imageData != null) {
                  setState(() => _profileImageData = imageData);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_profileImageData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, toma una foto de perfil'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Determinar la especialidad final
      final String finalSpecialty = _showOtherSpecialty
          ? _otherSpecialtyController.text.trim()
          : _selectedSpecialty!;

      final tempUser = UserModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        email: _emailController.text.trim(),
        fullName: _nameController.text.trim(),
        role: UserRole.technician,
        phone: _phoneController.text.trim(),
        specialty: finalSpecialty,
        cedula: _cedulaController.text.trim(),
      );

      final result = await _authService.register(
        tempUser,
        _passwordController.text,
        _profileImageData, // Ahora usa ImageData directamente
      );

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (result['success']) {
        // Mostrar pantalla de confirmación
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => RegistrationConfirmationScreen(
              email: _emailController.text.trim(),
              userType: 'technician',
              userName: _nameController.text.trim(),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Técnico'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: size.width > 600 ? 100 : 24,
            vertical: 24,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Foto de perfil
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[200],
                        border: Border.all(color: Colors.orange, width: 3),
                      ),
                      child: _profileImageData != null
                          ? ClipOval(
                              child: Image.memory(
                                _profileImageData!.bytes,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt, size: 40, color: Colors.grey[600]),
                                const SizedBox(height: 8),
                                Text(
                                  'Tomar foto',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Toca para tomar tu foto de perfil',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa tu nombre completo';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                    hintText: 'usuario@ejemplo.com',
                  ),
                  validator: ValidationUtils.validateEmail,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa una contraseña';
                    }
                    if (value.length < 6) {
                      return 'Mínimo 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirmar contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Confirma tu contraseña';
                    }
                    if (value != _passwordController.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    prefixIcon: Icon(Icons.phone_outlined),
                    hintText: 'Ej: 0999999999',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa tu teléfono';
                    }
                    if (value.length < 10) {
                      return 'Teléfono inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _cedulaController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Cédula de Identidad',
                    prefixIcon: Icon(Icons.badge_outlined),
                    hintText: 'Ej: 1234567890',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa tu cédula';
                    }
                    if (value.length != 10) {
                      return 'La cédula debe tener 10 dígitos';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _selectedSpecialty,
                  decoration: const InputDecoration(
                    labelText: 'Especialidad',
                    prefixIcon: Icon(Icons.work_outline),
                  ),
                  items: _specialties.map((specialty) {
                    return DropdownMenuItem(
                      value: specialty,
                      child: Text(specialty),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSpecialty = value;
                      _showOtherSpecialty = value == 'Otro';
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Selecciona una especialidad';
                    }
                    return null;
                  },
                ),
                
                if (_showOtherSpecialty) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _otherSpecialtyController,
                    decoration: const InputDecoration(
                      labelText: 'Especifica tu especialidad',
                      prefixIcon: Icon(Icons.edit_outlined),
                      hintText: 'Ej: Jardinero, Técnico de piscinas',
                    ),
                    validator: (value) {
                      if (_showOtherSpecialty && (value == null || value.isEmpty)) {
                        return 'Especifica tu especialidad';
                      }
                      return null;
                    },
                  ),
                ],
                
                const SizedBox(height: 32),

                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Registrarse',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}