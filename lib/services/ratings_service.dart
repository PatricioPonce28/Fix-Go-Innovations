import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/work_and_chat_models.dart';

class RatingsService {
  final _supabase = Supabase.instance.client;

  // ==================== OBTENER TRABAJOS COMPLETADOS PARA CALIFICAR ====================
  /// Obtiene los trabajos completados de un cliente que aún no ha calificado
  Future<List<AcceptedWork>> getCompletedWorksToRate(String clientId) async {
    try {
      print(
          '[RATINGS] Obteniendo trabajos completados para calificar - Cliente: $clientId');

      final response = await _supabase
          .from('accepted_works')
          .select()
          .eq('client_id', clientId)
          .eq('status', 'completed')
          .isFilter('client_rating', null) // Solo no calificados
          .order('completed_at', ascending: false);

      print(
          '[RATINGS] ✅ ${response.length} trabajos encontrados para calificar');

      return (response as List)
          .map((work) => AcceptedWork.fromJson(work))
          .toList();
    } catch (e) {
      print('❌ Error obteniendo trabajos completados: $e');
      return [];
    }
  }

  // ==================== OBTENER CALIFICACIONES DEL TÉCNICO ====================
  /// Obtiene todas las calificaciones de un técnico
  Future<List<Map<String, dynamic>>> getTechnicianRatings(
      String technicianId) async {
    try {
      print('[RATINGS] Obteniendo calificaciones - Técnico: $technicianId');

      final response = await _supabase
          .from('accepted_works')
          .select('client_rating, client_review, rated_at, client_id')
          .eq('technician_id', technicianId)
          .not('client_rating', 'is', null)
          .order('rated_at', ascending: false);

      print('[RATINGS] ✅ ${response.length} calificaciones encontradas');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error obteniendo calificaciones del técnico: $e');
      return [];
    }
  }

  // ==================== OBTENER ESTADÍSTICAS DE CALIFICACIÓN ====================
  /// Calcula el promedio y cuenta de calificaciones de un técnico
  Future<Map<String, dynamic>> getTechnicianRatingStats(
      String technicianId) async {
    try {
      final ratings = await getTechnicianRatings(technicianId);

      if (ratings.isEmpty) {
        return {
          'average_rating': 0.0,
          'total_ratings': 0,
          'five_star': 0,
          'four_star': 0,
          'three_star': 0,
          'two_star': 0,
          'one_star': 0,
        };
      }

      final ratingsList = ratings
          .where((r) => r['client_rating'] != null)
          .map((r) => (r['client_rating'] as num).toInt())
          .toList();

      if (ratingsList.isEmpty) {
        return {
          'average_rating': 0.0,
          'total_ratings': 0,
          'five_star': 0,
          'four_star': 0,
          'three_star': 0,
          'two_star': 0,
          'one_star': 0,
        };
      }

      final average = ratingsList.reduce((a, b) => a + b) / ratingsList.length;

      return {
        'average_rating': double.parse(average.toStringAsFixed(1)),
        'total_ratings': ratingsList.length,
        'five_star': ratingsList.where((r) => r == 5).length,
        'four_star': ratingsList.where((r) => r == 4).length,
        'three_star': ratingsList.where((r) => r == 3).length,
        'two_star': ratingsList.where((r) => r == 2).length,
        'one_star': ratingsList.where((r) => r == 1).length,
      };
    } catch (e) {
      print('❌ Error calculando estadísticas: $e');
      return {
        'average_rating': 0.0,
        'total_ratings': 0,
      };
    }
  }

  // ==================== GUARDAR CALIFICACIÓN ====================
  /// Guarda la calificación de un cliente para un trabajo
  Future<bool> rateWork({
    required String workId,
    required int rating, // 1-5
    required String? review,
  }) async {
    try {
      if (rating < 1 || rating > 5) {
        throw Exception('Rating debe estar entre 1 y 5');
      }

      print(
          '[RATINGS] Guardando calificación: $rating estrellas - Trabajo: $workId');

      final now = DateTime.now();
      await _supabase.from('accepted_works').update({
        'client_rating': rating,
        'client_review': review ?? '',
        'rated_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      }).eq('id', workId);

      print('[RATINGS] ✅ Calificación guardada exitosamente');
      return true;
    } catch (e) {
      print('❌ Error guardando calificación: $e');
      return false;
    }
  }

  // ==================== OBTENER DETALLES DE TRABAJO PARA CALIFICAR ====================
  /// Obtiene los detalles completos del trabajo y técnico para calificar
  Future<Map<String, dynamic>?> getWorkDetailsForRating(String workId) async {
    try {
      print('[RATINGS] Obteniendo detalles del trabajo: $workId');

      final response = await _supabase.from('accepted_works').select('''
            id,
            request_id,
            quotation_id,
            client_id,
            technician_id,
            payment_amount,
            status,
            started_at,
            completed_at,
            work_notes,
            completion_photos,
            client_rating,
            client_review
          ''').eq('id', workId).single();

      // Obtener datos del técnico
      final technicianResponse = await _supabase
          .from('users')
          .select('id, full_name, profile_photo_url, specialty')
          .eq('id', response['technician_id'])
          .single();

      return {
        'work': response,
        'technician': technicianResponse,
      };
    } catch (e) {
      print('❌ Error obteniendo detalles del trabajo: $e');
      return null;
    }
  }
}
