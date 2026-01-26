import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../models/service_request_model.dart';
import 'create_quotation_screen.dart';

class RequestDetailForTechnicianScreen extends StatelessWidget {
  final ServiceRequest request;
  final UserModel technician;
  final VoidCallback onQuotationSent;

  const RequestDetailForTechnicianScreen({
    super.key,
    required this.request,
    required this.technician,
    required this.onQuotationSent,
  });

  Color _getServiceTypeColor(ServiceType type) {
    return type == ServiceType.emergency ? Colors.red : Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Solicitud'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con tipo de servicio
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _getServiceTypeColor(request.serviceType),
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
                  Icon(
                    request.serviceType == ServiceType.emergency
                        ? Icons.warning_amber
                        : Icons.build,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    request.serviceType.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (request.serviceType == ServiceType.emergency)
                    const Text(
                      'Requiere atención urgente',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Text(
                    request.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Publicado ${DateFormat('dd/MM/yyyy HH:mm').format(request.createdAt)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Descripción
                  _SectionCard(
                    title: 'Descripción del Problema',
                    icon: Icons.description,
                    child: Text(
                      request.description,
                      style: const TextStyle(fontSize: 15, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Ubicación (SOLO SECTOR, NO EXACTA)
                  _SectionCard(
                    title: 'Ubicación',
                    icon: Icons.location_on,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.location_city, size: 18, color: Colors.orange),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Sector: ${request.sector}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.lock, size: 18, color: Colors.orange[700]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'La ubicación exacta se mostrará cuando el cliente acepte tu cotización',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.orange[900],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Disponibilidad
                  if (request.availabilityDate != null || request.availabilityTime != null)
                    _SectionCard(
                      title: 'Disponibilidad del Cliente',
                      icon: Icons.calendar_today,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (request.availabilityDate != null)
                            Row(
                              children: [
                                const Icon(Icons.event, size: 18, color: Colors.blue),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat('EEEE, dd MMMM yyyy', 'es')
                                      .format(request.availabilityDate!),
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ],
                            ),
                          if (request.availabilityTime != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.access_time, size: 18, color: Colors.blue),
                                const SizedBox(width: 8),
                                Text(
                                  request.availabilityTime!,
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Fotos
                  if (request.imageUrls.isNotEmpty) ...[
                    _SectionCard(
                      title: 'Fotos del Trabajo',
                      icon: Icons.photo_library,
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: request.imageUrls.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => Dialog(
                                  child: InteractiveViewer(
                                    child: Image.network(request.imageUrls[index]),
                                  ),
                                ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                request.imageUrls[index],
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Información adicional
                  _SectionCard(
                    title: 'Información Adicional',
                    icon: Icons.info_outline,
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: Icons.assignment,
                          label: 'ID de Solicitud',
                          value: request.id.substring(0, 8).toUpperCase(),
                        ),
                        const Divider(),
                        _InfoRow(
                          icon: Icons.pending_actions,
                          label: 'Estado',
                          value: request.status.displayName,
                        ),
                        const Divider(),
                        _InfoRow(
                          icon: Icons.description,
                          label: 'Cotizaciones enviadas',
                          value: '${request.quotationsCount ?? 0}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Botón enviar cotización
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CreateQuotationScreen(
                              request: request,
                              technician: technician,
                              onQuotationSent: () {
                                Navigator.pop(context);
                                onQuotationSent();
                              },
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.description, size: 24),
                      label: const Text(
                        'Enviar Cotización',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
            const SizedBox(height: 12),
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
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
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}