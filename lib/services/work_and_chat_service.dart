import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/work_and_chat_models.dart';
import '../models/payment_model.dart' as payment_models;
import 'payment_service.dart';

class WorkService {
  final _supabase = Supabase.instance.client;
  late final PaymentService _paymentService;

  WorkService() {
    _paymentService = PaymentService();
  }

  // ==================== OBTENER TRABAJO POR COTIZACIÓN ====================
  Future<AcceptedWork?> getWorkByQuotation(String quotationId) async {
    try {
      final response = await _supabase
          .from('accepted_works')
          .select()
          .eq('quotation_id', quotationId)
          .maybeSingle();

      if (response == null) return null;
      return AcceptedWork.fromJson(response);
    } catch (e) {
      print('❌ Error al obtener trabajo: $e');
      return null;
    }
  }

  // ==================== OBTENER TRABAJOS ACTIVOS DEL CLIENTE ====================
  Future<List<AcceptedWork>> getClientActiveWorks() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('accepted_works')
          .select()
          .eq('client_id', userId)
          .not('status', 'in', '(rated)')
          .order('created_at', ascending: false);

      return response.map((item) => AcceptedWork.fromJson(item)).toList();
    } catch (e) {
      print('❌ Error al obtener trabajos del cliente: $e');
      return [];
    }
  }

  // ==================== OBTENER TRABAJOS ACTIVOS DEL TÉCNICO ====================
  Future<List<AcceptedWork>> getTechnicianActiveWorks() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('accepted_works')
          .select()
          .eq('technician_id', userId)
          .not('status', 'in', '(rated)')
          .order('created_at', ascending: false);

      return response.map((item) => AcceptedWork.fromJson(item)).toList();
    } catch (e) {
      print('❌ Error al obtener trabajos del técnico: $e');
      return [];
    }
  }

  // ==================== OBTENER ESTADÍSTICAS DEL TÉCNICO ====================
  Future<TechnicianStats> getTechnicianStats() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return TechnicianStats(
          totalQuotations: 0,
          acceptedQuotations: 0,
          completedWorks: 0,
        );
      }

      final response = await _supabase.rpc('get_technician_stats',
          params: {'p_technician_id': userId}).single();

      return TechnicianStats.fromJson(response);
    } catch (e) {
      print('❌ Error al obtener estadísticas: $e');
      return TechnicianStats(
        totalQuotations: 0,
        acceptedQuotations: 0,
        completedWorks: 0,
      );
    }
  }

  // ==================== ACTUALIZAR ESTADO DEL TRABAJO ====================
  Future<bool> updateWorkStatus(String workId, WorkStatus newStatus) async {
    try {
      final updates = <String, dynamic>{
        'status': newStatus.name,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Agregar timestamps específicos
      switch (newStatus) {
        case WorkStatus.paid:
          updates['paid_at'] = DateTime.now().toIso8601String();
          break;
        case WorkStatus.in_progress:
          updates['started_at'] = DateTime.now().toIso8601String();
          break;
        case WorkStatus.completed:
          updates['completed_at'] = DateTime.now().toIso8601String();
          break;
        default:
          break;
      }

      await _supabase.from('accepted_works').update(updates).eq('id', workId);

      print('✅ Estado actualizado a: ${newStatus.displayName}');
      return true;
    } catch (e) {
      print('❌ Error al actualizar estado: $e');
      return false;
    }
  }

  // ==================== REGISTRAR PAGO ====================
  Future<bool> registerPayment({
    required String workId,
    required String paymentMethod,
    String? paymentReference,
  }) async {
    try {
      await _supabase.from('accepted_works').update({
        'payment_method': paymentMethod,
        'payment_reference': paymentReference,
        'payment_status': 'completed',
        'paid_at': DateTime.now().toIso8601String(),
        'status': 'paid',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', workId);

      print('✅ Pago registrado');
      return true;
    } catch (e) {
      print('❌ Error al registrar pago: $e');
      return false;
    }
  }

  // ==================== SUBMIT PAYMENT - CREAR TRANSACCIÓN CON BRAINTREE ====================
  Future<payment_models.Payment> submitPayment({
    required String workId,
    required double amount,
  }) async {
    try {
      // Obtener info del trabajo
      final work = await getWorkByQuotation(workId);
      if (work == null) {
        throw Exception('Trabajo no encontrado');
      }

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      // En realidad, el nonce se genera en PaymentScreen después de BraintreeDropIn
      // Este método es para crear el registro de pago
      final payment = payment_models.Payment(
        id: _paymentService.generatePaymentId(),
        workId: workId,
        amount: amount,
        platformFee: amount * 0.10,
        technicianAmount: amount * 0.90,
        status: payment_models.PaymentStatus.pending,
        braintreeNonce: null,
        braintreeTransactionId: null,
        paymentMethod: payment_models.PaymentMethodType.creditCard,
        clientId: userId,
        technicianId: work.technicianId,
        createdAt: DateTime.now(),
      );

      print('✅ Pago iniciado con Braintree: ${payment.id}');
      return payment;
    } catch (e) {
      print('❌ Error al enviar pago: $e');
      rethrow;
    }
  }

  // ==================== UPDATE PAYMENT STATUS ====================
  Future<bool> updatePaymentStatus({
    required String paymentId,
    required payment_models.PaymentStatus newStatus,
    String? failureReason,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': newStatus.toString().split('.').last,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (newStatus == payment_models.PaymentStatus.completed) {
        updates['completed_at'] = DateTime.now().toIso8601String();
      }

      if (failureReason != null && newStatus == payment_models.PaymentStatus.failed) {
        updates['failure_reason'] = failureReason;
      }

      await _supabase.from('payments').update(updates).eq('id', paymentId);

      print('✅ Estado de pago actualizado: ${newStatus.name}');
      return true;
    } catch (e) {
      print('❌ Error al actualizar estado de pago: $e');
      return false;
    }
  }

  // ==================== GET PAYMENT - OBTENER DETALLES DEL PAGO ====================
  Future<payment_models.Payment?> getPayment(String paymentId) async {
    try {
      return await _paymentService.getPayment(paymentId);
    } catch (e) {
      print('❌ Error al obtener pago: $e');
      return null;
    }
  }

  // ==================== GET CLIENT PAYMENTS ====================
  Future<List<payment_models.Payment>> getClientPayments() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      return await _paymentService.getClientPayments(userId);
    } catch (e) {
      print('❌ Error al obtener pagos del cliente: $e');
      return [];
    }
  }

  // ==================== GET TECHNICIAN PAYMENTS ====================
  Future<List<payment_models.Payment>> getTechnicianPayments() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      return await _paymentService.getTechnicianPayments(userId);
    } catch (e) {
      print('❌ Error al obtener pagos del técnico: $e');
      return [];
    }
  }

  // ==================== PROCESS WORK AFTER PAYMENT ====================
  Future<bool> processWorkAfterPayment({
    required String workId,
    required payment_models.Payment payment,
  }) async {
    try {
      // 1. Actualizar estado del trabajo a 'on_way'
      final statusUpdated = await updateWorkStatus(workId, WorkStatus.on_way);
      if (!statusUpdated) {
        throw Exception('No se pudo actualizar el estado del trabajo');
      }

      // 2. Registrar el pago
      final paymentRegistered = await registerPayment(
        workId: workId,
        paymentMethod: payment.paymentMethod.toString().split('.').last,
        paymentReference: payment.braintreeTransactionId,
      );
      if (!paymentRegistered) {
        throw Exception('No se pudo registrar el pago');
      }

      print('✅ Trabajo procesado después del pago');
      return true;
    } catch (e) {
      print('❌ Error al procesar trabajo después del pago: $e');
      return false;
    }
  }

  // ==================== CALIFICAR TRABAJO ====================
  Future<bool> rateWork({
    required String workId,
    required int rating,
    String? review,
  }) async {
    try {
      if (rating < 1 || rating > 5) {
        print('❌ Calificación inválida');
        return false;
      }

      await _supabase.from('accepted_works').update({
        'client_rating': rating,
        'client_review': review,
        'rated_at': DateTime.now().toIso8601String(),
        'status': 'rated',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', workId);

      print('✅ Trabajo calificado: $rating estrellas');
      return true;
    } catch (e) {
      print('❌ Error al calificar: $e');
      return false;
    }
  }

  // ==================== AGREGAR NOTAS DE TRABAJO ====================
  Future<bool> addWorkNotes(String workId, String notes) async {
    try {
      await _supabase.from('accepted_works').update({
        'work_notes': notes,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', workId);

      return true;
    } catch (e) {
      print('❌ Error al agregar notas: $e');
      return false;
    }
  }

  // ==================== OBTENER TRABAJOS QUE NECESITAN ACCIÓN ====================
  Future<List<AcceptedWork>> getClientPendingActions() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      // Trabajos que necesitan: pago, seguimiento, o calificación
      final response = await _supabase
          .from('accepted_works')
          .select('*, service_requests(title)') // Incluir título de la solicitud
          .eq('client_id', userId)
          .inFilter('status', ['pending_payment', 'paid', 'completed'])
          .order('created_at', ascending: false);

      return response.map((item) {
        final work = AcceptedWork.fromJson(item);
        // Si hay título en la solicitud, adjúntalo
        if (item['service_requests'] != null) {
          // Aquí puedes ajustar según tu estructura
        }
        return work;
      }).toList();
    } catch (e) {
      print('❌ Error al obtener acciones pendientes: $e');
      return [];
    }
  }

  Future<List<AcceptedWork>> getTechnicianPendingActions() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      // Trabajos que necesitan: iniciar, en progreso, completar
      final response = await _supabase
          .from('accepted_works')
          .select('*, service_requests(title)')
          .eq('technician_id', userId)
          .inFilter('status', ['paid', 'on_way', 'in_progress'])
          .order('created_at', ascending: false);

      return response.map((item) => AcceptedWork.fromJson(item)).toList();
    } catch (e) {
      print('❌ Error al obtener trabajos técnico: $e');
      return [];
    }
  }

  // ==================== OBTENER DATOS COMPLETOS DEL TRABAJO ====================
  Future<Map<String, dynamic>> getWorkDetails(String workId) async {
    try {
      final response = await _supabase
          .from('accepted_works')
          .select('''
            *,
            service_requests(*),
            quotations(*),
            client_profile:user_profiles!client_id(full_name, phone),
            technician_profile:user_profiles!technician_id(full_name, phone, specialty)
          ''')
          .eq('id', workId)
          .single();

      return response;
    } catch (e) {
      print('❌ Error al obtener detalles: $e');
      return {};
    }
  }

  // ==================== STREAM DE CONFIRMACIONES DE CHAT ====================
  Stream<Map<String, bool>> streamWorkConfirmations(String workId) {
    return _supabase
        .from('accepted_works')
        .stream(primaryKey: ['id'])
        .eq('id', workId)
        .map((data) {
          if (data.isEmpty) return {'client_confirmed': false, 'technician_confirmed': false};
          final work = data.first;
          return {
            'client_confirmed': work['client_confirmed_chat'] ?? false,
            'technician_confirmed': work['technician_confirmed_chat'] ?? false,
          };
        });
  }

  // ==================== CONFIRMAR CHAT LISTO ====================
  Future<bool> confirmChatReady(String workId, {required bool isClient}) async {
    try {
      final fieldName = isClient ? 'client_confirmed_chat' : 'technician_confirmed_chat';

      await _supabase
          .from('accepted_works')
          .update({fieldName: true})
          .eq('id', workId);

      print('✅ [CHAT] ${isClient ? 'Cliente' : 'Técnico'} confirmó chat');
      return true;
    } catch (e) {
      print('❌ Error al confirmar chat: $e');
      return false;
    }
  }

  // ==================== OBTENER DATOS DEL TÉCNICO ====================
  Future<Map<String, dynamic>> getTechnicianData(String technicianId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('full_name, email, phone')
          .eq('id', technicianId)
          .single();

      return response;
    } catch (e) {
      print('❌ Error al obtener datos del técnico: $e');
      return {'full_name': 'Técnico'};
    }
  }
}

// ==================== SERVICIO DE CHAT ====================
class ChatService {
  final _supabase = Supabase.instance.client;

  // ==================== ENVIAR MENSAJE ====================
  Future<bool> sendMessage({
    required String workId,
    required String messageText,
    MessageType messageType = MessageType.text,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase.from('chat_messages').insert({
        'work_id': workId,
        'sender_id': userId,
        'message_text': messageText,
        'message_type': messageType.name,
      });

      print('✅ Mensaje enviado');
      return true;
    } catch (e) {
      print('❌ Error al enviar mensaje: $e');
      return false;
    }
  }

  // ==================== OBTENER MENSAJES ====================
  Future<List<ChatMessage>> getMessages(String workId) async {
    try {
      final response = await _supabase
          .from('chat_messages')
          .select()
          .eq('work_id', workId)
          .order('created_at', ascending: true);

      return response.map((item) => ChatMessage.fromJson(item)).toList();
    } catch (e) {
      print('❌ Error al obtener mensajes: $e');
      return [];
    }
  }

  // ==================== SUSCRIBIRSE A MENSAJES EN TIEMPO REAL ====================
  RealtimeChannel subscribeToMessages({
    required String workId,
    required Function(ChatMessage) onNewMessage,
  }) {
    final channel = _supabase.channel('chat_$workId').onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'work_id',
            value: workId,
          ),
          callback: (payload) {
            final message = ChatMessage.fromJson(payload.newRecord);
            onNewMessage(message);
          },
        );

    channel.subscribe();
    return channel;
  }

  // ==================== MARCAR MENSAJES COMO LEÍDOS ====================
  Future<void> markMessagesAsRead(String workId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from('chat_messages')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('work_id', workId)
          .neq('sender_id', userId)
          .eq('is_read', false);
    } catch (e) {
      print('❌ Error al marcar mensajes como leídos: $e');
    }
  }

  // ==================== CONTAR MENSAJES NO LEÍDOS ====================
  Future<int> getUnreadCount(String workId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      final response = await _supabase
          .from('chat_messages')
          .select('id')
          .eq('work_id', workId)
          .neq('sender_id', userId)
          .eq('is_read', false)
          .count(CountOption.exact);

      return response.count;
    } catch (e) {
      print('❌ Error al contar mensajes no leídos: $e');
      return 0;
    }
  }
}
