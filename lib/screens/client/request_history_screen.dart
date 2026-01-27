import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../models/service_request_model.dart';
import '../../models/work_and_chat_models.dart'; // Agregar
import '../../services/service_request_service.dart';
import '../../services/work_and_chat_service.dart'; // Agregar
import 'quotations_for_request_screen.dart';
import 'request_detail_screen.dart';
import 'work_coordination_screen.dart'; // Agregar

class RequestHistoryScreen extends StatefulWidget {
  final UserModel user;

  const RequestHistoryScreen({super.key, required this.user});

  @override
  State<RequestHistoryScreen> createState() => _RequestHistoryScreenState();
}

class _RequestHistoryScreenState extends State<RequestHistoryScreen> {
  final _requestService = ServiceRequestService();
  final _workService = WorkService(); // Agregar
  List<ServiceRequest> _requests = [];
  bool _isLoading = true;
  final Map<String, List<AcceptedWork>> _requestWorks = {}; // 🔴 NUEVO

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    final requests = await _requestService.getClientRequests();
    
    // 🔴 NUEVO: Cargar trabajos aceptados para cada solicitud
    for (var request in requests) {
      final works = await _getAcceptedWorksForRequest(request.id);
      _requestWorks[request.id] = works;
    }
    
    setState(() {
      _requests = requests;
      _isLoading = false;
    });
  }

  // 🔴 NUEVO: Obtener trabajos aceptados de una solicitud
  Future<List<AcceptedWork>> _getAcceptedWorksForRequest(String requestId) async {
    try {
      final response = await _workService.getClientActiveWorks();
      return response.where((work) => work.requestId == requestId).toList();
    } catch (e) {
      print('❌ Error cargando trabajos para request $requestId: $e');
      return [];
    }
  }

  Future<void> _deleteRequest(String requestId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text('¿Estás seguro de eliminar esta solicitud?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _requestService.deleteRequest(requestId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solicitud eliminada'),
            backgroundColor: Colors.green,
          ),
        );
        _loadRequests();
      }
    }
  }

  // 🔴 NUEVO: Navegar a coordinación
  Future<void> _goToWorkCoordination(AcceptedWork work, ServiceRequest request) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkCoordinationScreen(
          work: work,
          request: request,
          currentUser: widget.user,
          isClient: true,
        ),
      ),
    );
  }

  Color _getStatusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return Colors.orange;
      case RequestStatus.assigned:
        return Colors.blue;
      case RequestStatus.in_progress:
        return Colors.purple;
      case RequestStatus.completed:
        return Colors.green;
      case RequestStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getWorkStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Icons.check_circle;
      case 'in_progress':
        return Icons.hourglass_bottom;
      case 'completed':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  // 🔴 NUEVO: Widget para trabajos aceptados
  Widget _buildAcceptedWorkCard(AcceptedWork work, ServiceRequest request) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                _getWorkStatusIcon(work.status.displayName),
                color: Colors.green[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      work.status.displayName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    Text(
                      'Total: \$${work.paymentAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _goToWorkCoordination(work, request),
                  icon: const Icon(Icons.chat, size: 16),
                  label: const Text('Chat'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    side: BorderSide(color: Colors.blue.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _goToWorkCoordination(work, request),
                  icon: const Icon(Icons.payment, size: 16),
                  label: const Text('Pago'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Solicitudes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRequests,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No tienes solicitudes aún',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadRequests,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _requests.length,
                    itemBuilder: (context, index) {
                      final request = _requests[index];
                      final quotationsCount = request.quotationsCount ?? 0;
                      final acceptedWorks = _requestWorks[request.id] ?? [];
                      final hasAcceptedWork = acceptedWorks.isNotEmpty;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header - Click para ver detalles
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RequestDetailScreen(
                                      request: request,
                                      onUpdate: _loadRequests,
                                    ),
                                  ),
                                );
                              },
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Título y Estado
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            request.title,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(
                                                request.status),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            request.status.displayName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // 🔴 NUEVO: Indicador de trabajos aceptados
                                    if (hasAcceptedWork)
                                      Container(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.orange[50],
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: Colors.orange),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.work, size: 16, color: Colors.orange[700]),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Trabajo en progreso',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.orange[700],
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                    // Descripción
                                    Text(
                                      request.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: Colors.grey[700]),
                                    ),
                                    const SizedBox(height: 12),

                                    // Info: Fecha y Tipo
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today,
                                            size: 14, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Text(
                                          DateFormat('dd/MM/yyyy', 'es_ES')
                                              .format(request.createdAt),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Icon(
                                          request.serviceType ==
                                                  ServiceType.emergency
                                              ? Icons.warning_amber
                                              : Icons.build,
                                          size: 14,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          request.serviceType.displayName,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Badge de cotizaciones si hay
                                    if (quotationsCount > 0) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green[50],
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                            color: Colors.green,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.description,
                                              size: 16,
                                              color: Colors.green[700],
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '$quotationsCount cotización${quotationsCount > 1 ? 'es' : ''} recibida${quotationsCount > 1 ? 's' : ''}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],

                                    // 🔴 NUEVO: Mostrar trabajos aceptados
                                    if (hasAcceptedWork) ...[
                                      const SizedBox(height: 12),
                                      ...acceptedWorks.map((work) => 
                                        _buildAcceptedWorkCard(work, request)
                                      ).toList(),
                                    ],

                                    // Imágenes preview
                                    if (request.imageUrls.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        height: 60,
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: request.imageUrls.length
                                              .clamp(0, 3),
                                          itemBuilder: (context, imgIndex) {
                                            return Container(
                                              margin: const EdgeInsets.only(
                                                  right: 8),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Image.network(
                                                  request.imageUrls[imgIndex],
                                                  width: 60,
                                                  height: 60,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),

                            // Botones de acción
                            const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  // Botón Ver Detalles
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                RequestDetailScreen(
                                              request: request,
                                              onUpdate: _loadRequests,
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.visibility,
                                          size: 18),
                                      label: const Text(
                                        'Ver Detalles',
                                        style: TextStyle(fontSize: 13),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.blue,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Botón Ver Cotizaciones
                                  Expanded(
                                    flex: quotationsCount > 0 ? 2 : 1,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                QuotationsForRequestScreen(
                                              request: request,
                                            ),
                                          ),
                                        ).then((_) => _loadRequests());
                                      },
                                      icon: Icon(
                                        quotationsCount > 0
                                            ? Icons.description
                                            : Icons.description_outlined,
                                        size: 18,
                                      ),
                                      label: Text(
                                        quotationsCount > 0
                                            ? 'Cotizaciones ($quotationsCount)'
                                            : 'Cotizaciones',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: quotationsCount > 0
                                            ? Colors.orange
                                            : Colors.grey[400],
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                      ),
                                    ),
                                  ),

                                  // Botón Eliminar (solo si está pendiente)
                                  if (request.status == RequestStatus.pending) ...[
                                    const SizedBox(width: 8),
                                    IconButton(
                                      onPressed: () =>
                                          _deleteRequest(request.id),
                                      icon: const Icon(Icons.delete),
                                      color: Colors.red,
                                      tooltip: 'Eliminar',
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}