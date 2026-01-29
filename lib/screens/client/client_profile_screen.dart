import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/image_data.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../auth/login_screen.dart';

class ClientProfileScreen extends StatefulWidget {
  final UserModel user;

  const ClientProfileScreen({super.key, required this.user});

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  final _authService = AuthService();
  final _storageService = StorageService();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _sectorController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = false;
  ImageData? _newProfileImage;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user.fullName;
    _phoneController.text = widget.user.phone ?? '';
    _sectorController.text = widget.user.sector ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _sectorController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
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
                  setState(() => _newProfileImage = imageData);
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
                  setState(() => _newProfileImage = imageData);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);

    try {
      String? newPhotoUrl;

      // Si hay una nueva foto, subirla
      if (_newProfileImage != null) {
        print('[SAVE PROFILE] Subiendo foto de perfil...');

        try {
          // Subir a Storage (parámetro: imageData, userId)
          newPhotoUrl = await _storageService.uploadProfilePhoto(
            _newProfileImage!,
            widget.user.id,
          );

          print('[SAVE PROFILE] Foto subida: $newPhotoUrl');
        } catch (uploadError) {
          print('❌ Error subiendo foto: $uploadError');
          // Continuar sin foto si hay error
        }
      }

      // Actualizar datos del usuario en Supabase
      print('[SAVE PROFILE] Actualizando perfil en BD...');
      await _authService.updateUserProfile(
        userId: widget.user.id,
        fullName: _nameController.text,
        phone: _phoneController.text,
        sector: _sectorController.text,
      );

      print('[SAVE PROFILE] ✅ Perfil actualizado correctamente');
      setState(() {
        _isEditing = false;
        _isLoading = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Perfil actualizado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('❌ Error guardando perfil: $e');
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

  void _logout() {
    _authService.logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _newProfileImage = null;
                  _nameController.text = widget.user.fullName;
                  _phoneController.text = widget.user.phone ?? '';
                  _sectorController.text = widget.user.sector ?? '';
                });
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Foto de perfil
            GestureDetector(
              onTap: _isEditing ? _pickProfileImage : null,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.blue,
                    backgroundImage: _newProfileImage != null
                        ? MemoryImage(_newProfileImage!.bytes)
                        : (widget.user.profilePhotoUrl != null
                            ? NetworkImage(widget.user.profilePhotoUrl!)
                                as ImageProvider
                            : null),
                    child: _newProfileImage == null &&
                            widget.user.profilePhotoUrl == null
                        ? Text(
                            widget.user.fullName[0].toUpperCase(),
                            style: const TextStyle(
                                fontSize: 40, color: Colors.white),
                          )
                        : null,
                  ),
                  if (_isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Campos de información
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      enabled: _isEditing,
                      decoration: const InputDecoration(
                        labelText: 'Nombre Completo',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller:
                          TextEditingController(text: widget.user.email),
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _phoneController,
                      enabled: _isEditing,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono',
                        prefixIcon: Icon(Icons.phone),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _sectorController,
                      enabled: _isEditing,
                      decoration: const InputDecoration(
                        labelText: 'Sector',
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Botón guardar (solo si está editando)
            if (_isEditing)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Guardar Cambios'),
                ),
              ),

            if (!_isEditing) ...[
              // Opciones adicionales
              ListTile(
                leading: const Icon(Icons.security),
                title: const Text('Cambiar Contraseña'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pushNamed(context, '/change_password');
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Ayuda y Soporte'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pushNamed(context, '/help_support');
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Cerrar Sesión',
                    style: TextStyle(color: Colors.red)),
                onTap: _logout,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
