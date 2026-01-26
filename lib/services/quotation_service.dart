import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/quotation_model.dart';
import '../models/service_request_model.dart';

class QuotationService {
  final _supabase = Supabase.instance.client;

  // ==================== CREAR COTIZACIÓN ====================
  Future<Map<String, dynamic>> createQuotation({
    required String requestId,
    required String clientId,
    required String technicianName,
    String? technicianRuc,
    required String solutionTitle,
    required String workDescription,
    String? includedMaterials,
    required String estimatedLabor,
    String? specialConditions,
    required double materialsSubtotal,
    required double laborSubtotal,
    required double taxAmount,
    required double totalAmount,
    required String estimatedTime,
    String? warrantyOffered,
    int validityDays = 7,
    String? additionalNotes,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return {'success': false, 'message': 'Usuario no autenticado'};
      }

      // Generar número de cotización
      final quotationNumberResult = await _supabase.rpc('generate_quotation_number');
      final quotationNumber = quotationNumberResult as String;

      // Calcular fecha de expiración
      final expiresAt = DateTime.now().add(Duration(days: validityDays));

      // Crear cotización
      final quotationData = {
        'request_id': requestId,
        'technician_id': userId,
        'client_id': clientId,
        'technician_name': technicianName,
        'technician_ruc': technicianRuc,
        'quotation_number': quotationNumber,
        'solution_title': solutionTitle,
        'work_description': workDescription,
        'included_materials': includedMaterials,
        'estimated_labor': estimatedLabor,
        'special_conditions': specialConditions,
        'materials_subtotal': materialsSubtotal,
        'labor_subtotal': laborSubtotal,
        'tax_amount': taxAmount,
        'total_amount': totalAmount,
        'estimated_time': estimatedTime,
        'warranty_offered': warrantyOffered,
        'validity_days': validityDays,
        'additional_notes': additionalNotes,
        'expires_at': expiresAt.toIso8601String(),
        'status': 'pending',
      };

      await _supabase.from('quotations').insert(quotationData);

      print('✅ Cotización creada: $quotationNumber');

      return {
        'success': true,
        'message': '✅ Cotización enviada exitosamente',
        'quotation_number': quotationNumber,
      };
    } catch (e) {
      print('❌ Error al crear cotización: $e');
      return {
        'success': false,
        'message': 'Error al crear cotización: ${e.toString()}',
      };
    }
  }

  // ==================== OBTENER SOLICITUDES DISPONIBLES PARA TÉCNICO ====================
  Future<List<ServiceRequest>> getAvailableRequests() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      // Obtener solicitudes pendientes que no hayan sido cotizadas por este técnico
      final response = await _supabase
          .from('service_requests')
          .select('*')
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      final requests = <ServiceRequest>[];
      for (var item in response) {
        // Verificar si ya cotizó esta solicitud
        final alreadyQuoted = await _supabase
            .from('quotations')
            .select('id')
            .eq('request_id', item['id'])
            .eq('technician_id', userId)
            .maybeSingle();

        // Solo mostrar si no ha cotizado
        if (alreadyQuoted == null) {
          // Obtener imágenes
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
      }

      return requests;
    } catch (e) {
      print('❌ Error al obtener solicitudes: $e');
      return [];
    }
  }

  // ==================== OBTENER COTIZACIONES DEL TÉCNICO ====================
  Future<List<Quotation>> getTechnicianQuotations() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('quotations')
          .select('*')
          .eq('technician_id', userId)
          .order('created_at', ascending: false);

      return response.map((item) => Quotation.fromJson(item)).toList();
    } catch (e) {
      print('❌ Error al obtener cotizaciones: $e');
      return [];
    }
  }

  // ==================== OBTENER COTIZACIONES PARA UNA SOLICITUD (CLIENTE) ====================
  Future<List<Quotation>> getQuotationsForRequest(String requestId) async {
    try {
      final response = await _supabase
          .from('quotations')
          .select('*')
          .eq('request_id', requestId)
          .order('created_at', ascending: false);

      return response.map((item) => Quotation.fromJson(item)).toList();
    } catch (e) {
      print('❌ Error al obtener cotizaciones: $e');
      return [];
    }
  }

  // ==================== ACEPTAR COTIZACIÓN (CLIENTE) ====================
  Future<bool> acceptQuotation(String quotationId) async {
    try {
      await _supabase
          .from('quotations')
          .update({'status': 'accepted'})
          .eq('id', quotationId);
      return true;
    } catch (e) {
      print('❌ Error al aceptar cotización: $e');
      return false;
    }
  }

  // ==================== RECHAZAR COTIZACIÓN (CLIENTE) ====================
  Future<bool> rejectQuotation(String quotationId) async {
    try {
      await _supabase
          .from('quotations')
          .update({'status': 'rejected'})
          .eq('id', quotationId);
      return true;
    } catch (e) {
      print('❌ Error al rechazar cotización: $e');
      return false;
    }
  }
}