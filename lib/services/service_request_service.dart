import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/service_request_model.dart';
import '../models/image_data.dart';

class ServiceRequestService {
  final _supabase = Supabase.instance.client;

  // ==================== CREAR SOLICITUD ====================
  Future<Map<String, dynamic>> createRequest({
    required String title,
    required String description,
    required ServiceType serviceType,
    required String sector,
    required String exactLocation,
    DateTime? availabilityDate,
    String? availabilityTime,
    List<ImageData>? images,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return {'success': false, 'message': 'Usuario no autenticado'};
      }

      // 1. Crear solicitud
      final requestData = {
        'client_id': userId,
        'title': title,
        'description': description,
        'service_type': serviceType.name,
        'sector': sector,
        'exact_location': exactLocation,
        'availability_date': availabilityDate?.toIso8601String(),
        'availability_time': availabilityTime,
        'status': 'pending',
      };

      final response = await _supabase
          .from('service_requests')
          .insert(requestData)
          .select()
          .single();

      final requestId = response['id'];
      print('✅ Solicitud creada: $requestId');

      // 2. Subir imágenes si existen
      if (images != null && images.isNotEmpty) {
        await _uploadRequestImages(requestId, images);
      }

      return {
        'success': true,
        'message': '✅ Solicitud creada exitosamente',
        'request_id': requestId,
      };
    } catch (e) {
      print('❌ Error al crear solicitud: $e');
      return {
        'success': false,
        'message': 'Error al crear solicitud: ${e.toString()}',
      };
    }
  }

  // ==================== SUBIR IMÁGENES ====================
  Future<void> _uploadRequestImages(String requestId, List<ImageData> images) async {
    for (int i = 0; i < images.length; i++) {
      final image = images[i];
      final fileName = '${requestId}_${i}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Subir a Storage
      await _supabase.storage
          .from('service-request-images')
          .uploadBinary(fileName, image.bytes);

      // Obtener URL pública
      final imageUrl = _supabase.storage
          .from('service-request-images')
          .getPublicUrl(fileName);

      // Guardar en BD
      await _supabase.from('service_request_images').insert({
        'request_id': requestId,
        'image_url': imageUrl,
      });
    }
  }

  // ==================== OBTENER SOLICITUDES DEL CLIENTE ====================
  Future<List<ServiceRequest>> getClientRequests() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('service_requests')
          .select('*')
          .eq('client_id', userId)
          .order('created_at', ascending: false);

      final requests = <ServiceRequest>[];
      for (var item in response) {
        // Obtener imágenes para cada solicitud
        final imagesResponse = await _supabase
            .from('service_request_images')
            .select('image_url')
            .eq('request_id', item['id']);

        final imageUrls = imagesResponse
            .map((img) => img['image_url'] as String)
            .toList();

        requests.add(ServiceRequest.fromJson({
          ...item,
          'image_urls': imageUrls,
        }));
      }

      return requests;
    } catch (e) {
      print('❌ Error al obtener solicitudes: $e');
      return [];
    }
  }

  // ==================== ACTUALIZAR SOLICITUD ====================
  Future<bool> updateRequest(String requestId, Map<String, dynamic> updates) async {
    try {
      await _supabase
          .from('service_requests')
          .update(updates)
          .eq('id', requestId);
      return true;
    } catch (e) {
      print('❌ Error al actualizar solicitud: $e');
      return false;
    }
  }

  // ==================== ELIMINAR SOLICITUD ====================
  Future<bool> deleteRequest(String requestId) async {
    try {
      await _supabase
          .from('service_requests')
          .delete()
          .eq('id', requestId);
      return true;
    } catch (e) {
      print('❌ Error al eliminar solicitud: $e');
      return false;
    }
  }
}