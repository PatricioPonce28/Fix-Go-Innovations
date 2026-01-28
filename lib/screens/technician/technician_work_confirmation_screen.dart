import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/quotation_model.dart';
import '../../models/service_request_model.dart';
import '../../models/accepted_work_model.dart';
import '../../services/quotation_service.dart';
import '../../services/service_request_service.dart';
import '../../services/work_and_chat_service.dart';
import '../chat/chat_confirmation_screen.dart';

class TechnicianWorkConfirmationScreen extends StatefulWidget {
  final String quotationId;
  final AcceptedWork work;

  const TechnicianWorkConfirmationScreen({
    super.key,
    required this.quotationId,
    required this.work,
  });

  @override
  State<TechnicianWorkConfirmationScreen> createState() =>
      _TechnicianWorkConfirmationScreenState();
}

class _TechnicianWorkConfirmationScreenState
    extends State<TechnicianWorkConfirmationScreen> {
  late QuotationService _quotationService;
  late ServiceRequestService _serviceRequestService;
  late WorkService _workService;

  Quotation? _quotation;
  ServiceRequest? _serviceRequest;
  bool _isLoading = true;
  String? _error;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _quotationService = QuotationService();
    _serviceRequestService = ServiceRequestService();
    _workService = WorkService();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      // Obtener cotización
      final quotations =
          await _quotationService.getQuotationsForRequest(widget.work.requestId);
      final quotation = quotations.firstWhere(
        (q) => q.id == widget.quotationId,
        orElse: () => quotations.first,
      );

      // Obtener solicitud de servicio (que tiene ubicación y fotos)
      final serviceRequest = await _serviceRequestService
          .getServiceRequestWithImages(widget.work.requestId);

      setState(() {
        _quotation = quotation;
        _serviceRequest = serviceRequest;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _proceedToChat() async {
    try {
      if (!mounted) return;

      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('✅ ¡Confirmando!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Preparando confirmación...'),
            ],
          ),
        ),
      );

      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;
      Navigator.of(context).pop(); // Cerrar diálogo

      // Obtener datos del cliente
      final clientName = await _getClientName(widget.work.clientId);

      // Navegar a pantalla de confirmación bilateral
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ChatConfirmationScreen(
            workId: widget.work.id,
            technicianName: 'Tú',
            clientName: clientName,
            isClient: false,
            sector: _serviceRequest?.sector ?? 'No especificado',
            exactLocation:
                _serviceRequest?.exactLocation ?? 'Por confirmar',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<String> _getClientName(String clientId) async {
    try {
      final response = await _workService.getTechnicianData(clientId);
      return response['full_name'] ?? 'Cliente';
    } catch (e) {
      return 'Cliente';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Confirmación de Trabajo')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Confirmación de Trabajo')),
        body: Center(
          child: Text('Error: $_error'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmación de Trabajo'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ======================== HEADER CON INFO GENERAL ========================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[600]!, Colors.blue[400]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Detalles del Trabajo',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _quotation?.quotationNumber ?? 'N/A',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '💰 \$${_quotation?.totalAmount.toStringAsFixed(2) ?? '0.00'}',
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

            // ======================== DESPLEGABLE DE PROBLEMAS/FOTOS ========================
            GestureDetector(
              onTap: () {
                setState(() => _isExpanded = !_isExpanded);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue[300]!),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.blue[50],
                ),
                child: Column(
                  children: [
                    // Header del desplegable
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Información del Problema',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Toca para ver detalles y fotos',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AnimatedRotation(
                            turns: _isExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 300),
                            child: Icon(
                              Icons.expand_more,
                              color: Colors.blue[600],
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Contenido expandido
                    if (_isExpanded)
                      Container(
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Colors.blue[200]!,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Título del problema
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '📋 Descripción del Problema',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey[200]!,
                                      ),
                                    ),
                                    child: Text(
                                      _serviceRequest?.title ?? 'No disponible',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Descripción detallada
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '📝 Detalles',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey[200]!,
                                      ),
                                    ),
                                    child: Text(
                                      _serviceRequest?.description ??
                                          'No disponible',
                                      style: const TextStyle(
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Fotos del problema
                            if (_serviceRequest?.imageUrls != null &&
                                _serviceRequest!.imageUrls.isNotEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 16, 16, 0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '📸 Fotos del Problema',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      height: 120,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount:
                                            _serviceRequest!.imageUrls.length,
                                        itemBuilder: (context, index) {
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              right: 12,
                                            ),
                                            child: GestureDetector(
                                              onTap: () {
                                                _showFullImage(
                                                  context,
                                                  _serviceRequest!
                                                      .imageUrls[index],
                                                );
                                              },
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: Colors.grey[300]!,
                                                  ),
                                              ),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  child: Image.network(
                                                    _serviceRequest!
                                                        .imageUrls[index],
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context,
                                                        error, stackTrace) {
                                                      return Container(
                                                        color: Colors.grey[300],
                                                        child: const Center(
                                                          child: Icon(
                                                            Icons.broken_image,
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Información de ubicación
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 16, 16, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '📍 Ubicación del Servicio',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.orange[50],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.orange[200]!,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.location_city,
                                              color: Colors.orange[600],
                                              size: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'Sector',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                  Text(
                                                    _serviceRequest?.sector ??
                                                        'No disponible',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.location_on,
                                              color: Colors.orange[600],
                                              size: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'Ubicación Exacta',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                  Text(
                                                    _serviceRequest
                                                            ?.exactLocation ??
                                                        'No disponible',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
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
                                ],
                              ),
                            ),

                            // Fecha disponible
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 16, 16, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '📅 Disponibilidad',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.green[50],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.green[200]!,
                                      ),
                                    ),
                                    child: Text(
                                      _serviceRequest?.availabilityDate != null
                                          ? DateFormat('dd/MM/yyyy - HH:mm')
                                              .format(_serviceRequest!
                                                  .availabilityDate!)
                                          : 'No disponible',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ======================== INFO DE COTIZACIÓN ========================
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '💼 Detalles de la Cotización',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    '📋 Solución Propuesta',
                    _quotation?.solutionTitle ?? 'N/A',
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    '⏱️ Tiempo Estimado',
                    _quotation?.estimatedTime ?? 'N/A',
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    '💰 Total',
                    '\$${_quotation?.totalAmount.toStringAsFixed(2) ?? '0.00'}',
                    isHighlight: true,
                  ),
                ],
              ),
            ),

            // ======================== BOTONES ========================
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _proceedToChat,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Ir al Chat para Confirmar Ubicación',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Volver Atrás'),
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

  Widget _buildInfoRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black87,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
            color: isHighlight ? Colors.green[700] : Colors.black87,
          ),
          textAlign: TextAlign.end,
        ),
      ],
    );
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Foto del Problema'),
              automaticallyImplyLeading: true,
            ),
            Expanded(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 48),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
