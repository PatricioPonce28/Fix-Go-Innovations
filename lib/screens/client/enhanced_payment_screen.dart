import 'package:flutter/material.dart';
import 'package:braintree_flutter_plus/braintree_flutter_plus.dart';
import '../../models/payment_method_model.dart';
import '../../models/accepted_work_model.dart';
import '../../services/payment_method_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EnhancedPaymentScreen extends StatefulWidget {
  final AcceptedWork work;

  const EnhancedPaymentScreen({
    super.key,
    required this.work,
  });

  @override
  State<EnhancedPaymentScreen> createState() => _EnhancedPaymentScreenState();
}

class _EnhancedPaymentScreenState extends State<EnhancedPaymentScreen> {
  late PaymentMethodService _paymentMethodService;
  PaymentMethodType _selectedPaymentMethod = PaymentMethodType.braintree;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _paymentMethodService = PaymentMethodService();
  }

  Future<void> _processBraintreePayment() async {
    setState(() => _isProcessing = true);

    try {
      // 🔑 Clave de tokenización de Braintree (Sandbox)
      const tokenizationKey = 'sandbox_pjypmnzx_54phx4kqg59jj2r8';

      var request = BraintreeDropInRequest(
        tokenizationKey: tokenizationKey,
        collectDeviceData: true,
        cardEnabled: true,
        paypalRequest: BraintreePayPalRequest(
          amount: widget.work.paymentAmount.toStringAsFixed(2),
          displayName: 'Fix&Go Innovations',
          billingAgreementDescription: 'Pago por servicio técnico',
        ),
        googlePaymentRequest: BraintreeGooglePaymentRequest(
          totalPrice: widget.work.paymentAmount.toStringAsFixed(2),
          currencyCode: 'USD',
        ),
        requestThreeDSecureVerification: true,
      );

      BraintreeDropInResult? result = await BraintreeDropIn.start(request);

      if (result != null) {
        await _completeBraintreePayment(result);
      } else {
        _showErrorDialog('Cancelado', 'El usuario canceló el pago');
      }
    } catch (e) {
      _showErrorDialog('Error', 'Error al procesar pago: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _completeBraintreePayment(BraintreeDropInResult result) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado');

      final nonce = result.paymentMethodNonce.nonce;
      final deviceData = result.deviceData;

      // Invocar Edge Function de Supabase
      final response = await Supabase.instance.client.functions.invoke(
        'procesar-pago',
        body: {
          'nonce': nonce,
          'amount': widget.work.paymentAmount.toStringAsFixed(2),
          'workId': widget.work.id,
          'platformFee': (widget.work.paymentAmount * 0.10).toStringAsFixed(2),
          if (deviceData != null) 'deviceData': deviceData,
        },
      );

      final responseData = response.data as Map<String, dynamic>;

      if (responseData['success'] == true) {
        // Crear registro de método de pago
        await _paymentMethodService.createPaymentMethod(
          workId: widget.work.id,
          type: PaymentMethodType.braintree,
          amount: widget.work.paymentAmount,
          paymentNonce: nonce,
          deviceData: deviceData,
        );

        _showSuccessDialog(
          'Pago Exitoso',
          'Pago de \$${widget.work.paymentAmount.toStringAsFixed(2)} procesado correctamente',
        );
      } else {
        throw Exception(responseData['message'] ?? 'Error desconocido');
      }
    } catch (e) {
      _showErrorDialog('Error', 'Error procesando pago: $e');
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('✅ $title'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Método de Pago'),
        elevation: 0,
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumen de pago
            _buildPaymentSummaryCard(),
            const SizedBox(height: 24),

            // Métodos de pago
            const Text(
              'Elige tu Método de Pago',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Opción única: Tarjeta de Crédito
            _buildPaymentOptionCard(
              title: '💳 Tarjeta de Crédito/Débito',
              subtitle: 'Visa, Mastercard, American Express, PayPal',
              icon: Icons.credit_card,
              isSelected: _selectedPaymentMethod == PaymentMethodType.braintree,
              onTap: () {
                setState(
                    () => _selectedPaymentMethod = PaymentMethodType.braintree);
              },
            ),

            const SizedBox(height: 32),

            // Botón de pagar
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _processPayment,
                icon: _isProcessing
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withOpacity(0.7),
                          ),
                        ),
                      )
                    : const Icon(Icons.payment),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  disabledBackgroundColor: Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                label: Text(
                  _isProcessing ? 'Procesando...' : 'Continuar',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Nota de seguridad
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tu información está segura y encriptada',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _processPayment() {
    // Solo procesar Braintree
    _processBraintreePayment();
  }

  Widget _buildPaymentSummaryCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen del Pago',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSummaryRow(
              'Monto del servicio',
              '\$${widget.work.paymentAmount.toStringAsFixed(2)}',
            ),
            const Divider(height: 16),
            _buildSummaryRow(
              'Comisión de plataforma',
              '- \$${(widget.work.paymentAmount * 0.10).toStringAsFixed(2)}',
              color: Colors.red,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: _buildSummaryRow(
                'Total a pagar',
                '\$${widget.work.paymentAmount.toStringAsFixed(2)}',
                isTotal: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String amount,
      {bool isTotal = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.blue[600]! : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? Colors.blue[50] : Colors.white,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? Colors.blue[600] : Colors.grey[600],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.blue[600] : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Radio<bool>(
              value: true,
              groupValue: isSelected,
              onChanged: (_) => onTap(),
              activeColor: Colors.blue[600],
            ),
          ],
        ),
      ),
    );
  }
}
