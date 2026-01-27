import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/quotation_model.dart';

class QuotationDetailScreen extends StatelessWidget {
  final Quotation quotation;

  const QuotationDetailScreen({
    super.key,
    required this.quotation,
  });

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
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con estado
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _getStatusColor(quotation.status),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    quotation.quotationNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      quotation.status.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
                  // Título de solución
                  Text(
                    quotation.solutionTitle,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ENCABEZADO
                  _SectionCard(
                    title: 'Encabezado',
                    icon: Icons.article,
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: Icons.person,
                          label: 'Técnico',
                          value: quotation.technicianName,
                        ),
                        if (quotation.technicianRuc != null) ...[
                          const Divider(),
                          _InfoRow(
                            icon: Icons.badge,
                            label: 'RUC/Cédula',
                            value: quotation.technicianRuc!,
                          ),
                        ],
                        const Divider(),
                        _InfoRow(
                          icon: Icons.calendar_today,
                          label: 'Fecha de Emisión',
                          value: DateFormat('dd/MM/yyyy HH:mm').format(quotation.createdAt),
                        ),
                        const Divider(),
                        _InfoRow(
                          icon: Icons.numbers,
                          label: 'Número de Cotización',
                          value: quotation.quotationNumber,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // DETALLE DEL TRABAJO
                  _SectionCard(
                    title: 'Detalle del Trabajo',
                    icon: Icons.work,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Descripción del Servicio',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          quotation.workDescription,
                          style: const TextStyle(fontSize: 15, height: 1.5),
                        ),
                        if (quotation.includedMaterials != null) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Materiales Incluidos',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            quotation.includedMaterials!,
                            style: const TextStyle(fontSize: 15, height: 1.5),
                          ),
                        ],
                        const SizedBox(height: 16),
                        const Divider(),
                        _InfoRow(
                          icon: Icons.engineering,
                          label: 'Mano de Obra',
                          value: quotation.estimatedLabor,
                        ),
                        if (quotation.specialConditions != null) ...[
                          const Divider(),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.info, size: 18, color: Colors.orange),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Condiciones Especiales',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      quotation.specialConditions!,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // COSTOS
                  _SectionCard(
                    title: 'Costos',
                    icon: Icons.attach_money,
                    child: Column(
                      children: [
                        _CostRow(
                          label: 'Subtotal Materiales',
                          value: quotation.materialsSubtotal,
                        ),
                        const Divider(),
                        _CostRow(
                          label: 'Subtotal Mano de Obra',
                          value: quotation.laborSubtotal,
                        ),
                        if (quotation.taxAmount > 0) ...[
                          const Divider(),
                          _CostRow(
                            label: 'IVA (15%)',
                            value: quotation.taxAmount,
                          ),
                        ],
                        const Divider(thickness: 2),
                        const SizedBox(height: 8),
                        _CostRow(
                          label: 'TOTAL A PAGAR',
                          value: quotation.totalAmount,
                          isTotal: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // NOTAS
                  _SectionCard(
                    title: 'Notas',
                    icon: Icons.note,
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: Icons.timer,
                          label: 'Tiempo Estimado',
                          value: quotation.estimatedTime,
                        ),
                        if (quotation.warrantyOffered != null) ...[
                          const Divider(),
                          _InfoRow(
                            icon: Icons.verified_user,
                            label: 'Garantía',
                            value: quotation.warrantyOffered!,
                          ),
                        ],
                        const Divider(),
                        _InfoRow(
                          icon: Icons.event_available,
                          label: 'Vigencia',
                          value: quotation.status == QuotationStatus.pending
                              ? '${quotation.daysRemaining} días restantes'
                              : '${quotation.validityDays} días',
                        ),
                        if (quotation.additionalNotes != null) ...[
                          const Divider(),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.note_alt, size: 18, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Notas Adicionales',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      quotation.additionalNotes!,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Estado y fechas
                  _SectionCard(
                    title: 'Estado y Fechas',
                    icon: Icons.info_outline,
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: Icons.access_time,
                          label: 'Creada',
                          value: DateFormat('dd/MM/yyyy HH:mm').format(quotation.createdAt),
                        ),
                        const Divider(),
                        _InfoRow(
                          icon: Icons.update,
                          label: 'Última actualización',
                          value: DateFormat('dd/MM/yyyy HH:mm').format(quotation.updatedAt),
                        ),
                        if (quotation.expiresAt != null) ...[
                          const Divider(),
                          _InfoRow(
                            icon: Icons.event_busy,
                            label: 'Expira',
                            value: DateFormat('dd/MM/yyyy').format(quotation.expiresAt!),
                          ),
                        ],
                      ],
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
}

// ==================== SECTION CARD ====================
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 22, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

// ==================== INFO ROW ====================
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== COST ROW ====================
class _CostRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isTotal;

  const _CostRow({
    required this.label,
    required this.value,
    this.isTotal = false,
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
            ),
          ),
          Text(
            '\$${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 22 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? Colors.green[700] : null,
            ),
          ),
        ],
      ),
    );
  }
}