import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/work_and_chat_models.dart';

class WorkService {
  final _supabase = Supabase.instance.client;

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

      return response.count ?? 0;
    } catch (e) {
      print('❌ Error al contar mensajes no leídos: $e');
      return 0;
    }
  }
}
