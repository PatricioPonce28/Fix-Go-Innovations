import 'package:flutter/material.dart';
import '../../models/work_and_chat_models.dart';
import 'payment_screen.dart';

class PaymentTab extends StatefulWidget {
  final AcceptedWork work;
  final bool isClient;
  final VoidCallback onPaymentCompleted;

  const PaymentTab({
    super.key,
    required this.work,
    required this.isClient,
    required this.onPaymentCompleted,
  });

  @override
  State<PaymentTab> createState() => _PaymentTabState();
}

class _PaymentTabState extends State<PaymentTab> {
  String _selectedPaymentMethod = 'tarjeta';

  Future<void> _processPayment() async {
    // Navegar a la pantalla de pago con Braintree
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(work: widget.work),
      ),
    );

    // Si el pago fue exitoso, notificar al padre
    if (result == true && mounted) {
      widget.onPaymentCompleted();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPaid = widget.work.paymentStatus == PaymentStatus.completed;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Estado del pago
          Card(
            color: isPaid ? Colors.green[50] : Colors.orange[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    isPaid ? Icons.check_circle : Icons.payment,
                    size: 48,
                    color: isPaid ? Colors.green[700] : Colors.orange[700],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPaid ? '✅ Pago Confirmado' : '⏳ Pendiente de Pago',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color:
                                isPaid ? Colors.green[900] : Colors.orange[900],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isPaid
                              ? 'El técnico puede iniciar el trabajo'
                              : 'Completa el pago para continuar',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Desglose de costos
          const Text(
            '💰 Desglose de Pago',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _CostRow(
                    label: 'Monto del Servicio',
                    value: widget.work.technicianAmount ?? 0,
                  ),
                  const Divider(),
                  _CostRow(
                    label: 'Comisión de Plataforma (10%)',
                    value: widget.work.platformFee ?? 0,
                    isHighlight: true,
                  ),
                  const Divider(thickness: 2),
                  _CostRow(
                    label: 'TOTAL A PAGAR',
                    value: widget.work.paymentAmount,
                    isTotal: true,
                  ),
                ],
              ),
            ),
          ),

          // Si es cliente y no ha pagado
          if (widget.isClient && !isPaid) ...[
            const SizedBox(height: 24),
            const Text(
              '💳 Método de Pago',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Selector de método de pago
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(left: 16),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.credit_card,
                          color: Colors.orange[700], size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Braintree',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pago seguro con tarjeta',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(right: 16),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Recomendado',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ════════════════════════════════════════════════════════════
            // 🔌 PLACEHOLDER PARA API EXTERNA
            // ════════════════════════════════════════════════════════════
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                border: Border.all(color: Colors.blue[200]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '✅ Pago con Braintree',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Pago seguro con tarjeta de crédito, débito o PayPal. '
                    'Tu información está protegida con encriptación de Braintree.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Botón de pagar
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _processPayment,
                icon: const Icon(Icons.credit_card),
                label: Text(
                  'Pagar con Braintree (\$${widget.work.paymentAmount.toStringAsFixed(2)})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],

          // Si ya está pagado, mostrar información
          if (isPaid) ...[
            const SizedBox(height: 24),
            const Text(
              '📋 Información del Pago',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.payment,
                      label: 'Método de Pago',
                      value: _getPaymentMethodName(widget.work.paymentMethod),
                    ),
                    const Divider(),
                    _InfoRow(
                      icon: Icons.receipt,
                      label: 'Referencia',
                      value: widget.work.paymentReference ?? 'N/A',
                    ),
                    if (widget.work.paidAt != null) ...[
                      const Divider(),
                      _InfoRow(
                        icon: Icons.calendar_today,
                        label: 'Fecha de Pago',
                        value: widget.work.paidAt!
                            .toLocal()
                            .toString()
                            .substring(0, 16),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],

          // Información para el técnico
          if (!widget.isClient) ...[
            const SizedBox(height: 24),
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Información para el Técnico',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isPaid
                          ? '✅ El pago ha sido confirmado. Recibirás \$${widget.work.technicianAmount?.toStringAsFixed(2)} una vez completado el trabajo.'
                          : '⏳ Esperando confirmación de pago del cliente.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _getPaymentMethodName(String? method) {
    switch (method) {
      case 'efectivo':
        return 'Efectivo';
      case 'transferencia':
        return 'Transferencia Bancaria';
      case 'tarjeta':
        return 'Tarjeta de Crédito/Débito';
      default:
        return 'N/A';
    }
  }
}

// ==================== WIDGETS AUXILIARES ====================
class _CostRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isTotal;
  final bool isHighlight;

  const _CostRow({
    required this.label,
    required this.value,
    this.isTotal = false,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 15,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isHighlight ? Colors.orange[700] : null,
            ),
          ),
          Text(
            '\$${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 20 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal
                  ? Colors.green[700]
                  : (isHighlight ? Colors.orange[700] : null),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
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
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
