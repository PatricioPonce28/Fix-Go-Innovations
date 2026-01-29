import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/payment_model.dart';

class PaymentService {
  final supabase = Supabase.instance.client;

  // 🔑 Clave de tokenización de Braintree (Sandbox)
  static const String _braintreeTokenizationKey =
      'sandbox_pjypmnzx_54phx4kqg59jj2r8';

  PaymentService() {
    print('✅ PaymentService inicializado con Braintree');
  }

  /// Obtener la tokenization key de Braintree
  static String getTokenizationKey() => _braintreeTokenizationKey;

  /// Generar ID único para pago (métod accesible públicamente)
  String generatePaymentId() {
    return _generatePaymentId();
  }

  /// Crear registro de pago en la BD después de obtener el nonce de Braintree
  Future<Payment> createPaymentRecord({
    required String workId,
    required double amount,
    required String clientId,
    required String technicianId,
    required String braintreeNonce,
    required PaymentMethodType paymentMethod,
    String? deviceData,
  }) async {
    try {
      final platformFee = amount * 0.10; // 10% comisión de plataforma
      final technicianAmount = amount - platformFee;

      final paymentId = _generatePaymentId();

      final payment = Payment(
        id: paymentId,
        workId: workId,
        amount: amount,
        platformFee: platformFee,
        technicianAmount: technicianAmount,
        status: PaymentStatus.pending,
        braintreeNonce: braintreeNonce,
        braintreeTransactionId: null,
        paymentMethod: paymentMethod,
        clientId: clientId,
        technicianId: technicianId,
        createdAt: DateTime.now(),
        deviceData: deviceData,
      );

      // Guardar en Supabase
      await supabase.from('payments').insert(payment.toJson());

      print('✅ Registro de pago creado: $paymentId');
      return payment;
    } catch (e) {
      print('❌ Error al crear registro de pago: $e');
      rethrow;
    }
  }

  /// Confirmar pago después de procesar en el backend
  Future<Payment> confirmPayment({
    required String paymentId,
    required String braintreeTransactionId,
  }) async {
    try {
      await supabase.from('payments').update({
        'status': 'completed',
        'braintree_transaction_id': braintreeTransactionId,
        'completed_at': DateTime.now().toIso8601String(),
      }).eq('id', paymentId);

      // Obtener y retornar pago actualizado
      return await getPayment(paymentId);
    } catch (e) {
      print('❌ Error al confirmar pago: $e');
      rethrow;
    }
  }

  /// Marcar pago como fallido
  Future<void> failPayment({
    required String paymentId,
    required String failureReason,
  }) async {
    try {
      await supabase.from('payments').update({
        'status': 'failed',
        'failure_reason': failureReason,
      }).eq('id', paymentId);

      print('⚠️ Pago marcado como fallido: $paymentId');
    } catch (e) {
      print('❌ Error al marcar pago como fallido: $e');
    }
  }

  /// Obtener detalles del pago
  Future<Payment> getPayment(String paymentId) async {
    try {
      final response =
          await supabase.from('payments').select().eq('id', paymentId).single();

      return Payment.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener pago: $e');
    }
  }

  /// Obtener pagos de un cliente
  Future<List<Payment>> getClientPayments(String clientId) async {
    try {
      final response = await supabase
          .from('payments')
          .select()
          .eq('client_id', clientId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((p) => Payment.fromJson(p as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener pagos del cliente: $e');
    }
  }

  /// Obtener pagos de un técnico
  Future<List<Payment>> getTechnicianPayments(String technicianId) async {
    try {
      final response = await supabase
          .from('payments')
          .select()
          .eq('technician_id', technicianId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((p) => Payment.fromJson(p as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener pagos del técnico: $e');
    }
  }

  /// Obtener pagos por trabajo
  Future<List<Payment>> getWorkPayments(String workId) async {
    try {
      final response =
          await supabase.from('payments').select().eq('work_id', workId);

      return (response as List)
          .map((p) => Payment.fromJson(p as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener pagos del trabajo: $e');
    }
  }

  /// Reembolsar pago
  Future<void> refundPayment({
    required String paymentId,
    String? reason,
  }) async {
    try {
      await supabase.from('payments').update({
        'status': 'refunded',
        'failure_reason': reason ?? 'Reembolso solicitado',
      }).eq('id', paymentId);

      print('✅ Pago reembolsado: $paymentId');
    } catch (e) {
      print('❌ Error al reembolsar pago: $e');
      rethrow;
    }
  }

  /// Generar ID único para pago
  String _generatePaymentId() {
    return 'PAY_${DateTime.now().millisecondsSinceEpoch}_${(DateTime.now().microsecond % 10000)}';
  }

  /// Validar monto de pago
  bool isValidPaymentAmount(double amount) {
    return amount >= 1.0 && amount <= 999999.99;
  }

  /// Procesar webhook de Braintree (para confirmación asincrónica)
  Future<void> handleBraintreeWebhook(Map<String, dynamic> webhookData) async {
    try {
      final transactionId = webhookData['id'] as String?;
      final status = webhookData['status'] as String?;
      final metadata = webhookData['customFields'] as Map<String, dynamic>?;

      if (transactionId == null || metadata == null) return;

      final paymentId = metadata['payment_id'] as String?;
      if (paymentId == null) return;

      // Mapear estado de Braintree a nuestro PaymentStatus
      PaymentStatus newStatus;
      switch (status) {
        case 'settled':
        case 'submitted_for_settlement':
          newStatus = PaymentStatus.completed;
          break;
        case 'failed':
        case 'declined':
          newStatus = PaymentStatus.failed;
          break;
        case 'voided':
          newStatus = PaymentStatus.refunded;
          break;
        default:
          newStatus = PaymentStatus.processing;
      }

      await supabase.from('payments').update({
        'status': newStatus.toString().split('.').last,
        'braintree_transaction_id': transactionId,
        'completed_at': newStatus == PaymentStatus.completed
            ? DateTime.now().toIso8601String()
            : null,
      }).eq('id', paymentId);

      print('✅ Webhook de Braintree procesado: $paymentId -> $status');
    } catch (e) {
      print('❌ Error procesando webhook: $e');
    }
  }
}
