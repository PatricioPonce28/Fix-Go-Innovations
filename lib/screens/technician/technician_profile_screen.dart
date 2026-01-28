import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/image_data.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../auth/login_screen.dart';

class TechnicianProfileScreen extends StatefulWidget {
  final UserModel user;

  const TechnicianProfileScreen({super.key, required this.user});

  @override
  State<TechnicianProfileScreen> createState() => _TechnicianProfileScreenState();
}

class _TechnicianProfileScreenState extends State<TechnicianProfileScreen> {
  final _authService = AuthService();
  final _storageService = StorageService();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _cedulaController = TextEditingController();
  
  bool _isEditing = false;
  bool _isLoading = false;
  ImageData? _newProfileImage;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user.fullName;
    _phoneController.text = widget.user.phone ?? '';
    _specialtyController.text = widget.user.specialty ?? '';
    _cedulaController.text = widget.user.cedula ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _specialtyController.dispose();
    _cedulaController.dispose();
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
  // TODO: Implementar actualización de perfil
  await Future.delayed(const Duration(seconds: 1));

  setState(() {
    _isEditing = false;
    _isLoading = false;
  });

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Perfil actualizado correctamente'),
      backgroundColor: Colors.green,
    ),
  );
} catch (e) {
  setState(() => _isLoading = false);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Error: ${e.toString()}'),
      backgroundColor: Colors.red,
    ),
  );
}
}
void _logout() async {
  await _authService.logout(); // ✅ CORRECTO
  if (!mounted) return;
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
_specialtyController.text = widget.user.specialty ?? '';
_cedulaController.text = widget.user.cedula ?? '';
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
backgroundColor: Colors.orange,
backgroundImage: _newProfileImage != null
? MemoryImage(_newProfileImage!.bytes)
: (widget.user.profilePhotoUrl != null
? NetworkImage(widget.user.profilePhotoUrl!) as ImageProvider
: null),
child: _newProfileImage == null && widget.user.profilePhotoUrl == null
? Text(
widget.user.fullName[0].toUpperCase(),
style: const TextStyle(fontSize: 40, color: Colors.white),
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
color: Colors.orange,
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
   // Información del técnico
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
                  controller: TextEditingController(text: widget.user.email),
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
                  controller: _specialtyController,
                  enabled: _isEditing,
                  decoration: const InputDecoration(
                    labelText: 'Especialidad',
                    prefixIcon: Icon(Icons.build),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _cedulaController,
                  enabled: _isEditing,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Cédula',
                    prefixIcon: Icon(Icons.badge),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Guardar Cambios',
                      style: TextStyle(color: Colors.white),
                    ),
            ),
          ),

        if (!_isEditing) ...[
          // Estadísticas
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Estadísticas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _StatRow(
                    icon: Icons.description,
                    label: 'Cotizaciones Enviadas',
                    value: '8',
                  ),
                  const Divider(),
                  _StatRow(
                    icon: Icons.check_circle,
                    label: 'Cotizaciones Aceptadas',
                    value: '3',
                  ),
                  const Divider(),
                  _StatRow(
                    icon: Icons.star,
                    label: 'Calificación Promedio',
                    value: '4.8',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

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
            title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
            onTap: _logout,
          ),
        ],
      ],
    ),
  ),
);
}
}
// ==================== STAT ROW ====================
class _StatRow extends StatelessWidget {
final IconData icon;
final String label;
final String value;
const _StatRow({
required this.icon,
required this.label,
required this.value,
});
@override
Widget build(BuildContext context) {
return Padding(
padding: const EdgeInsets.symmetric(vertical: 8),
child: Row(
children: [
Icon(icon, size: 24, color: Colors.orange),
const SizedBox(width: 16),
Expanded(
child: Text(
label,
style: const TextStyle(fontSize: 15),
),
),
Text(
value,
style: const TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
color: Colors.orange,
),
),
],
),
);
}
}