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

      // Verificar si ya existe cotización para esta solicitud del mismo técnico
      final existingQuotation = await _supabase
          .from('quotations')
          .select('id, quotation_number')
          .eq('request_id', requestId)
          .eq('technician_id', userId)
          .maybeSingle();

      // Si existe, actualizar; si no, crear
      String quotationNumber;
      if (existingQuotation != null) {
        print(
            '📝 Actualizando cotización existente: ${existingQuotation['quotation_number']}');
        quotationNumber = existingQuotation['quotation_number'];
      } else {
        // Generar número de cotización solo si es nueva
        final quotationNumberResult =
            await _supabase.rpc('generate_quotation_number');
        quotationNumber = quotationNumberResult as String;
        print('✨ Creando nueva cotización: $quotationNumber');
      }

      // Calcular fecha de expiración
      final expiresAt = DateTime.now().add(Duration(days: validityDays));

      // Datos de la cotización
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

      if (existingQuotation != null) {
        // Actualizar cotización existente
        await _supabase
            .from('quotations')
            .update(quotationData)
            .eq('id', existingQuotation['id']);

        print('✅ Cotización actualizada: $quotationNumber');
      } else {
        // Insertar nueva cotización
        await _supabase.from('quotations').insert(quotationData);
        print('✅ Cotización creada: $quotationNumber');
      }

      return {
        'success': true,
        'message': existingQuotation != null
            ? '✅ Cotización actualizada exitosamente'
            : '✅ Cotización enviada exitosamente',
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

          final imageUrls =
              imagesResponse.map((img) => img['image_url'] as String).toList();

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
          .update({'status': 'accepted'}).eq('id', quotationId);
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
          .update({'status': 'rejected'}).eq('id', quotationId);
      return true;
    } catch (e) {
      print('❌ Error al rechazar cotización: $e');
      return false;
    }
  }

// ==================== ACEPTAR COTIZACIÓN CON NAVEGACIÓN ====================
  Future<Map<String, dynamic>> acceptQuotationWithNavigation(
      String quotationId) async {
    try {
      print('🔄 [ACCEPT] Iniciando aceptación de cotización: $quotationId');

      // 1. Obtener datos de la cotización antes de aceptar
      final quotation = await _supabase
          .from('quotations')
          .select('*')
          .eq('id', quotationId)
          .single();

      print('📋 [ACCEPT] Cotización actual:');
      print('  ├─ Status: ${quotation['status']}');
      print('  ├─ Total: \$${quotation['total_amount']}');
      print('  ├─ Request ID: ${quotation['request_id']}');
      print('  ├─ Client ID: ${quotation['client_id']}');
      print('  └─ Technician ID: ${quotation['technician_id']}');

      // 2. Actualizar cotización a aceptada (esto dispara el trigger)
      await _supabase
          .from('quotations')
          .update({'status': 'accepted'}).eq('id', quotationId);

      print('✅ [ACCEPT] Cotización marcada como aceptada en BD');

      // 3. Esperar a que el trigger cree el trabajo (aumentado a 3 segundos)
      print('⏳ [ACCEPT] Esperando que el trigger cree el trabajo...');
      await Future.delayed(const Duration(seconds: 3));

      // 4. Buscar el trabajo creado por el trigger
      print('🔍 [ACCEPT] Buscando trabajo creado...');
      final work = await _supabase
          .from('accepted_works')
          .select('*')
          .eq('quotation_id', quotationId)
          .maybeSingle();

      if (work != null) {
        print('🎉 [ACCEPT] ¡Trabajo encontrado! ID: ${work['id']}');
        print('  ├─ Monto de pago: \$${work['payment_amount']}');
        print('  ├─ Comisión plataforma: \$${work['platform_fee']}');
        print('  └─ Estado de pago: ${work['payment_status']}');

        return {
          'success': true,
          'work': work,
          'message': 'Cotización aceptada. Trabajo creado por trigger.',
        };
      } else {
        throw Exception(
            'El trabajo no se creó tras 3 segundos. El trigger puede no haber funcionado.');
      }
    } catch (e) {
      print('❌ [ACCEPT] Error en trigger: $e');
      print('🛠️ [ACCEPT] Intentando crear trabajo manualmente...');

      try {
        // Obtener datos nuevamente para crear manualmente
        final quotation = await _supabase
            .from('quotations')
            .select('*')
            .eq('id', quotationId)
            .single();

        final totalAmount = (quotation['total_amount'] ?? 0.0) as num;
        final platformFee = (totalAmount * 0.10).toDouble();
        final technicianAmount = (totalAmount - platformFee).toDouble();

        print('📝 [ACCEPT] Creando trabajo manualmente con:');
        print('  ├─ Request: ${quotation['request_id']}');
        print('  ├─ Client: ${quotation['client_id']}');
        print('  ├─ Technician: ${quotation['technician_id']}');
        print('  └─ Monto: \$${totalAmount}');

        final manualWork = await _supabase
            .from('accepted_works')
            .insert({
              'request_id': quotation['request_id'],
              'quotation_id': quotationId,
              'client_id': quotation['client_id'],
              'technician_id': quotation['technician_id'],
              'status': 'pending_payment',
              'payment_amount': totalAmount.toDouble(),
              'platform_fee': platformFee,
              'technician_amount': technicianAmount,
              'payment_status': 'pending',
            })
            .select()
            .single();

        print('✅ [ACCEPT] Trabajo creado manualmente: ${manualWork['id']}');

        return {
          'success': true,
          'work': manualWork,
          'message': 'Trabajo creado manualmente (trigger falló)',
        };
      } catch (e2) {
        print('❌ [ACCEPT] Error también en creación manual: $e2');

        return {
          'success': false,
          'error': 'No se pudo crear el trabajo',
          'message': 'Trigger error: $e | Manual error: $e2',
        };
      }
    }
  }
}
