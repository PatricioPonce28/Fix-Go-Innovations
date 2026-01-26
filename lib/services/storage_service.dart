import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../models/image_data.dart';

class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  // Tomar foto con la cámara (funciona en móvil y web)
  Future<ImageData?> takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (photo == null) return null;
      
      final bytes = await photo.readAsBytes();
      return ImageData(bytes: bytes, name: photo.name);
    } catch (e) {
      print('❌ Error al tomar foto: $e');
      return null;
    }
  }

  // Elegir foto de la galería (funciona en móvil y web)
  Future<ImageData?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return null;
      
      final bytes = await image.readAsBytes();
      return ImageData(bytes: bytes, name: image.name);
    } catch (e) {
      print('❌ Error al elegir foto: $e');
      return null;
    }
  }

  // Subir foto de perfil (funciona con bytes, compatible con web y móvil)
  Future<String?> uploadProfilePhoto(ImageData imageData, String userId) async {
    try {
      print('📤 Subiendo foto de perfil...');

      final String fileName = '$userId/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Subir archivo usando bytes
      await _supabase.storage
          .from('profile-photos')
          .uploadBinary(
            fileName,
            imageData.bytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );

      // Obtener URL pública
      final String publicUrl = _supabase.storage
          .from('profile-photos')
          .getPublicUrl(fileName);

      print('✅ Foto subida: $publicUrl');
      return publicUrl;
      
    } catch (e) {
      print('❌ Error al subir foto: $e');
      return null;
    }
  }

  // Eliminar foto de perfil
  Future<bool> deleteProfilePhoto(String userId, String photoUrl) async {
    try {
      // Extraer el nombre del archivo de la URL
      final uri = Uri.parse(photoUrl);
      final pathSegments = uri.pathSegments;
      
      // Buscar el segmento que contiene el userId
      int userIdIndex = -1;
      for (int i = 0; i < pathSegments.length; i++) {
        if (pathSegments[i] == userId) {
          userIdIndex = i;
          break;
        }
      }
      
      if (userIdIndex == -1 || userIdIndex + 1 >= pathSegments.length) {
        print('❌ No se pudo extraer el nombre del archivo');
        return false;
      }
      
      final fileName = pathSegments[userIdIndex + 1];
      
      await _supabase.storage
          .from('profile-photos')
          .remove(['$userId/$fileName']);

      print('✅ Foto eliminada');
      return true;
    } catch (e) {
      print('❌ Error al eliminar foto: $e');
      return false;
    }
  }
}