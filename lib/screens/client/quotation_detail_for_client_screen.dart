import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/quotation_model.dart';
import '../../models/service_request_model.dart';
import '../../models/user_model.dart'; // Agregar
import '../../models/work_and_chat_models.dart'; // Agregar
import '../../services/quotation_service.dart';
import '../../services/work_and_chat_service.dart'; // Agregar
import 'work_coordination_screen.dart'; // Agregar

class QuotationDetailForClientScreen extends StatefulWidget {
  final Quotation quotation;
  final ServiceRequest request;
  final UserModel user; // Agregar
  final VoidCallback onStatusChanged;

  const QuotationDetailForClientScreen({
    super.key,
    required this.quotation,
    required this.request,
    required this.user, // Agregar
    required this.onStatusChanged,
  });

  @override
  State<QuotationDetailForClientScreen> createState() =>
      _QuotationDetailForClientScreenState();
}

class _QuotationDetailForClientScreenState
    extends State<QuotationDetailForClientScreen> {
  final _quotationService = QuotationService();
  final _workService = WorkService(); // Agregar
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  bool get _isExpired => widget.quotation.isExpired;
  bool get _canDecide =>
      widget.quotation.status == QuotationStatus.pending && !_isExpired;

  Future<void> _acceptQuotation() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Aceptar Cotización?'),
        content: const Text(
          'Al aceptar esta cotización:\n\n'
          '• Se rechazarán automáticamente las demás cotizaciones\n'
          '• El técnico será notificado\n'
          '• Podrán coordinar los detalles del trabajo\n'
          '• Serás redirigido al chat y sistema de pago\n\n'
          '¿Deseas continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sí, Aceptar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      // Aceptar la cotización
      final result = await _quotationService.acceptQuotationWithNavigation(
        widget.quotation.id,
      );

      if (!mounted) return;

      if (result['success']) {
        // Mostrar diálogo de carga mientras se prepara
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('✅ ¡Cotización Aceptada!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text('Preparando coordinación...'),
                const SizedBox(height: 8),
                if (result['work'] != null)
                  Text(
                    'Total: \$${result['work']['payment_amount']?.toStringAsFixed(2) ?? '0.00'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
              ],
            ),
          ),
        );

        await Future.delayed(const Duration(seconds: 2));

        if (!mounted) return;
        Navigator.of(context).pop(); // Cerrar diálogo de carga

        // Convertir a modelo AcceptedWork
        final work = AcceptedWork.fromJson(result['work']);

        // Navegar directamente a WorkCoordinationScreen con RemoveUntil para limpiar stack
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => WorkCoordinationScreen(
              work: work,
              request: widget.request,
              currentUser: widget.user,
              isClient: true,
            ),
          ),
          (route) => false, // Limpiar todo el stack
        );
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${result['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al aceptar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectQuotation() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Rechazar Cotización?'),
        content: const Text(
          'Esta acción no se puede deshacer.\n\n'
          'El técnico será notificado del rechazo.\n\n'
          '¿Estás seguro?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sí, Rechazar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    final success = await _quotationService.rejectQuotation(
      widget.quotation.id,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cotización rechazada'),
          backgroundColor: Colors.orange,
        ),
      );
      Navigator.pop(context);
      widget.onStatusChanged();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al rechazar cotización'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 🔴 NUEVO: Botón para ver chat/pago si ya está aceptada
  void _goToChatAndPayment() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final work = await _workService.getWorkByQuotation(widget.quotation.id);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (work != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WorkCoordinationScreen(
            work: work,
            request: widget.request,
            currentUser: widget.user,
            isClient: true,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se encontró el trabajo. Intenta más tarde.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getStatusColor(QuotationStatus status) {
    switch (status) {
      case QuotationStatus.pending:
        return Colors.orange;
      case QuotationStatus.accepted:
        return Colors.green;
      case QuotationStatus.rejected:
        return Colors.red;
      case QuotationStatus.expired:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Cotización'),
        centerTitle: true,
        actions: [
          // 🔴 NUEVO: Botón para ir al chat si ya está aceptada
          if (widget.quotation.status == QuotationStatus.accepted)
            IconButton(
              icon: const Badge(
                child: Icon(Icons.chat),
              ),
              onPressed: _isLoading ? null : _goToChatAndPayment,
              tooltip: 'Ir al Chat y Pago',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Estado de la cotización
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _getStatusColor(widget.quotation.status)
                          .withOpacity(0.1),
                      border: Border(
                        bottom: BorderSide(
                          color: _getStatusColor(widget.quotation.status),
                          width: 3,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.quotation.status.displayName,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(widget.quotation.status),
                              ),
                            ),
                            if (_isExpired &&
                                widget.quotation.status ==
                                    QuotationStatus.pending)
                              const Text(
                                'Esta cotización ha vencido',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red,
                                ),
                              ),
                          ],
                        ),
                        Text(
                          widget.quotation.quotationNumber,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🔴 NUEVO: Mensaje especial si está aceptada
                        if (widget.quotation.status == QuotationStatus.accepted)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.celebration,
                                  size: 48,
                                  color: Colors.green[700],
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  '✅ ¡Cotización Aceptada!',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Ahora puedes coordinar el trabajo con el técnico',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton.icon(
                                    onPressed: _goToChatAndPayment,
                                    icon: const Icon(Icons.chat),
                                    label: const Text(
                                      '💬 Ir al Chat y 💳 Pago',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Información del Técnico
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '👨‍🔧 Técnico',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 30,
                                      backgroundColor: Colors.blue[700],
                                      child: const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            widget.quotation.technicianName,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'RUC: ${widget.quotation.technicianRuc ?? 'No especificado'}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Solución Propuesta
                        const Text(
                          '📋 Solución Propuesta',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.quotation.solutionTitle,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  widget.quotation.workDescription,
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Materiales
                        if (widget.quotation.includedMaterials != null) ...[
                          const Text(
                            '🔧 Materiales Incluidos',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                widget.quotation.includedMaterials!,
                                style: const TextStyle(fontSize: 15),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Mano de Obra
                        const Text(
                          '👨‍🔧 Mano de Obra',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              widget.quotation.estimatedLabor,
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Condiciones Especiales
                        if (widget.quotation.specialConditions != null) ...[
                          const Text(
                            'ℹ️ Condiciones Especiales',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Card(
                            color: Colors.amber[50],
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                widget.quotation.specialConditions!,
                                style: const TextStyle(fontSize: 15),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Desglose de Costos
                        const Text(
                          '💰 Desglose de Costos',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _CostRow(
                                  label: 'Materiales',
                                  value: widget.quotation.materialsSubtotal,
                                ),
                                const Divider(),
                                _CostRow(
                                  label: 'Mano de Obra',
                                  value: widget.quotation.laborSubtotal,
                                ),
                                const Divider(),
                                _CostRow(
                                  label: 'Subtotal',
                                  value: widget.quotation.materialsSubtotal +
                                      widget.quotation.laborSubtotal,
                                ),
                                if (widget.quotation.taxAmount > 0) ...[
                                  const Divider(),
                                  _CostRow(
                                    label: 'IVA (15%)',
                                    value: widget.quotation.taxAmount,
                                  ),
                                ],
                                const Divider(),
                                _CostRow(
                                  label: 'Comisión de Plataforma (10%)',
                                  value: (widget.quotation.totalAmount * 0.10),
                                  isSubtle: true,
                                ),
                                const Divider(thickness: 2),
                                _CostRow(
                                  label: 'TOTAL A PAGAR',
                                  value: widget.quotation.totalAmount +
                                      (widget.quotation.totalAmount * 0.10),
                                  isTotal: true,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Text(
                            'ℹ️ El 10% de comisión de plataforma es por el uso de nuestra app para conectarte con el técnico.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[800],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Información Adicional
                        const Text(
                          '📌 Información Adicional',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _InfoRow(
                                  icon: Icons.timer,
                                  label: 'Tiempo Estimado',
                                  value: widget.quotation.estimatedTime,
                                ),
                                const Divider(),
                                _InfoRow(
                                  icon: Icons.calendar_today,
                                  label: 'Fecha de Envío',
                                  value: DateFormat('dd/MM/yyyy', 'es_ES')
                                      .format(widget.quotation.createdAt),
                                ),
                                if (widget.quotation.expiresAt != null) ...[
                                  const Divider(),
                                  _InfoRow(
                                    icon: _isExpired
                                        ? Icons.warning
                                        : Icons.event_available,
                                    label: 'Válida Hasta',
                                    value: DateFormat('dd/MM/yyyy', 'es_ES')
                                        .format(widget.quotation.expiresAt!),
                                    valueColor:
                                        _isExpired ? Colors.red : Colors.green,
                                  ),
                                ],
                                if (widget.quotation.warrantyOffered !=
                                    null) ...[
                                  const Divider(),
                                  _InfoRow(
                                    icon: Icons.verified_user,
                                    label: 'Garantía',
                                    value: widget.quotation.warrantyOffered!,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        // Notas Adicionales
                        if (widget.quotation.additionalNotes != null) ...[
                          const SizedBox(height: 16),
                          const Text(
                            '📝 Notas Adicionales',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Card(
                            color: Colors.blue[50],
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                widget.quotation.additionalNotes!,
                                style: const TextStyle(fontSize: 15),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Botones de Acción
                        if (_canDecide) ...[
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed:
                                      _isLoading ? null : _rejectQuotation,
                                  icon: const Icon(Icons.close),
                                  label: const Text('Rechazar'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton.icon(
                                  onPressed:
                                      _isLoading ? null : _acceptQuotation,
                                  icon: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.check_circle),
                                  label: Text(
                                    _isLoading
                                        ? 'Procesando...'
                                        : '✅ Aceptar e Ir al Chat',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],

                        // 🔴 NUEVO: Acceso rápido desde cotizaciones aceptadas
                        if (widget.quotation.status ==
                            QuotationStatus.accepted) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  '📱 Acceso Rápido',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _goToChatAndPayment,
                                        icon: const Icon(Icons.chat),
                                        label: const Text('Chat'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.blue,
                                          side: BorderSide(
                                              color: Colors.blue.shade300),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _goToChatAndPayment,
                                        icon: const Icon(Icons.payment),
                                        label: const Text('Pago'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orange,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// ==================== WIDGETS AUXILIARES ====================
class _CostRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isTotal;
  final bool isSubtle;

  const _CostRow({
    required this.label,
    required this.value,
    this.isTotal = false,
    this.isSubtle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 15,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isSubtle ? Colors.grey[600] : null,
            ),
          ),
          Text(
            '\$${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 20 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal
                  ? Colors.green[700]
                  : (isSubtle ? Colors.grey[600] : null),
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
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
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
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: valueColor,
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
