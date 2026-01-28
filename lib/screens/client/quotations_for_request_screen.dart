import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/service_request_model.dart';
import '../../models/quotation_model.dart';
import '../../models/user_model.dart';
import '../../services/quotation_service.dart';
import 'quotation_detail_for_client_screen.dart';

class QuotationsForRequestScreen extends StatefulWidget {
  final ServiceRequest request;
  final UserModel user;

  const QuotationsForRequestScreen({
    super.key,
    required this.request,
    required this.user,
  });

  @override
  State<QuotationsForRequestScreen> createState() =>
      _QuotationsForRequestScreenState();
}

class _QuotationsForRequestScreenState
    extends State<QuotationsForRequestScreen> {
  final _quotationService = QuotationService();
  List<Quotation> _quotations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuotations();
  }

  Future<void> _loadQuotations() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final quotations =
        await _quotationService.getQuotationsForRequest(widget.request.id);
    if (!mounted) return;
    setState(() {
      _quotations = quotations;
      _isLoading = false;
    });
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
        title: const Text('Cotizaciones Recibidas'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadQuotations,
          ),
        ],
      ),
      body: Column(
        children: [
          // Información de la solicitud
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.work, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.request.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Sector: ${widget.request.sector}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Publicado: ${DateFormat('dd/MM/yyyy', 'es_ES').format(widget.request.createdAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Lista de cotizaciones
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _quotations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.description_outlined,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No hay cotizaciones aún',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Los técnicos podrán enviar sus propuestas',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadQuotations,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _quotations.length,
                          itemBuilder: (context, index) {
                            final quotation = _quotations[index];
                            final isExpired = quotation.isExpired;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              elevation: 3,
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          QuotationDetailForClientScreen(
                                        quotation: quotation,
                                        request: widget.request,
                                        user: widget.user,
                                        onStatusChanged: _loadQuotations,
                                      ),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Header con técnico y estado
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                CircleAvatar(
                                                  backgroundColor:
                                                      Colors.blue[700],
                                                  child: const Icon(
                                                    Icons.person,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        quotation
                                                            .technicianName,
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      Text(
                                                        quotation
                                                            .quotationNumber,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(
                                                      quotation.status)
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: _getStatusColor(
                                                    quotation.status),
                                              ),
                                            ),
                                            child: Text(
                                              quotation.status.displayName,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: _getStatusColor(
                                                    quotation.status),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),

                                      // Título de solución
                                      Text(
                                        quotation.solutionTitle,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 12),

                                      // Precio destacado
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.green[50],
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: Colors.green[200]!,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Precio Total:',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              '\$${quotation.totalAmount.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 12),

                                      // Tiempo estimado
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.timer,
                                            size: 16,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Tiempo: ${quotation.estimatedTime}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),

                                      // Fecha de envío y vencimiento
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.calendar_today,
                                                size: 14,
                                                color: Colors.grey[600],
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Enviado: ${DateFormat('dd/MM/yyyy', 'es_ES').format(quotation.createdAt)}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (quotation.expiresAt != null)
                                            Row(
                                              children: [
                                                Icon(
                                                  isExpired
                                                      ? Icons.warning
                                                      : Icons.event_available,
                                                  size: 14,
                                                  color: isExpired
                                                      ? Colors.red
                                                      : Colors.green,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  isExpired
                                                      ? 'Vencida'
                                                      : 'Válida hasta ${DateFormat('dd/MM', 'es_ES').format(quotation.expiresAt!)}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: isExpired
                                                        ? Colors.red
                                                        : Colors.green[700],
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),

                                      // Botón de acción
                                      if (quotation.status ==
                                              QuotationStatus.pending &&
                                          !isExpired) ...[
                                        const SizedBox(height: 12),
                                        const Divider(),
                                        const SizedBox(height: 8),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      QuotationDetailForClientScreen(
                                                    quotation: quotation,
                                                    request: widget.request,
                                                    user: widget.user,
                                                    onStatusChanged:
                                                        _loadQuotations,
                                                  ),
                                                ),
                                              );
                                            },
                                            icon: const Icon(Icons.visibility),
                                            label: const Text(
                                                'Ver Detalles y Decidir'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blue,
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
