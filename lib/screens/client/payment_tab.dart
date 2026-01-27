import 'package:flutter/material.dart';
import '../../models/work_and_chat_models.dart';
import '../../services/work_and_chat_service.dart';

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
  final _workService = WorkService();
  String _selectedPaymentMethod = 'efectivo';
  bool _isProcessing = false;

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);

    // ════════════════════════════════════════════════════════════
    // 🔌 AQUÍ TU COMPAÑERO INTEGRARÁ LA API EXTERNA DE PAGOS
    // ════════════════════════════════════════════════════════════
    // 
    // Ejemplo de lo que haría:
    // 
    // final paymentResult = await ExternalPaymentAPI.processPayment(
    //   amount: widget.work.paymentAmount,
    //   method: _selectedPaymentMethod,
    //   workId: widget.work.id,
    //   description: 'Pago por servicio',
    // );
    // 
    // if (paymentResult.success) {
    //   final reference = paymentResult.transactionId;
    //   // Continuar con el registro en Supabase...
    // }
    // ════════════════════════════════════════════════════════════

    // Por ahora, simulamos el proceso
    await Future.delayed(const Duration(seconds: 2));

    final success = await _workService.registerPayment(
      workId: widget.work.id,
      paymentMethod: _selectedPaymentMethod,
      paymentReference: 'SIMULATED-${DateTime.now().millisecondsSinceEpoch}',
    );

    setState(() => _isProcessing = false);

    if (!mounted) return;

    if (success) {
      widget.onPaymentCompleted();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al procesar el pago'),
          backgroundColor: Colors.red,
        ),
      );
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
                            color: isPaid ? Colors.green[900] : Colors.orange[900],
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
              child: Column(
                children: [
                  RadioListTile<String>(
                    title: const Text('Efectivo'),
                    subtitle: const Text('Pago en efectivo al técnico'),
                    value: 'efectivo',
                    groupValue: _selectedPaymentMethod,
                    onChanged: (value) {
                      setState(() => _selectedPaymentMethod = value!);
                    },
                    secondary: const Icon(Icons.money, color: Colors.green),
                  ),
                  const Divider(height: 1),
                  RadioListTile<String>(
                    title: const Text('Transferencia'),
                    subtitle: const Text('Transferencia bancaria'),
                    value: 'transferencia',
                    groupValue: _selectedPaymentMethod,
                    onChanged: (value) {
                      setState(() => _selectedPaymentMethod = value!);
                    },
                    secondary: const Icon(Icons.account_balance, color: Colors.blue),
                  ),
                  const Divider(height: 1),
                  RadioListTile<String>(
                    title: const Text('Tarjeta de Crédito/Débito'),
                    subtitle: const Text('Pago con tarjeta'),
                    value: 'tarjeta',
                    groupValue: _selectedPaymentMethod,
                    onChanged: (value) {
                      setState(() => _selectedPaymentMethod = value!);
                    },
                    secondary: const Icon(Icons.credit_card, color: Colors.orange),
                  ),
                ],
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
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '🔌 Integración de Pasarela de Pago Externa',
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
                    'Este es el espacio donde se integrará la API externa de pagos. '
                    'Tu compañero puede reemplazar la función _processPayment() '
                    'con la llamada a la API real.',
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
                onPressed: _isProcessing ? null : _processPayment,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.payment),
                label: Text(
                  _isProcessing
                      ? 'Procesando...'
                      : 'Confirmar Pago (\$${widget.work.paymentAmount.toStringAsFixed(2)})',
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
