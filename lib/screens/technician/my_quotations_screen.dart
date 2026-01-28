import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user_model.dart';
import '../../models/quotation_model.dart';
import '../../models/service_request_model.dart';
import '../../models/work_and_chat_models.dart';
import '../../services/quotation_service.dart';
import '../../services/work_and_chat_service.dart';
import '../../services/notification_system_service.dart';
import 'quotation_detail_screen.dart';
import '../client/work_coordination_screen.dart';

class MyQuotationsScreen extends StatefulWidget {
  final UserModel user;

  const MyQuotationsScreen({super.key, required this.user});

  @override
  State<MyQuotationsScreen> createState() => _MyQuotationsScreenState();
}

class _MyQuotationsScreenState extends State<MyQuotationsScreen> {
  final _quotationService = QuotationService();
  final _workService = WorkService(); // Agregar
  final _notificationService = NotificationSystemService(); // Agregar
  final _supabase = Supabase.instance.client; // Agregar
  
  List<Quotation> _quotations = [];
  bool _isLoading = true;
  String _filterStatus = 'all';
  final Map<String, AcceptedWork?> _quotationWorks = {};
  RealtimeChannel? _quotationsSubscription;

  @override
  void initState() {
    super.initState();
    _loadQuotations();
    _setupRealtimeSubscription(); // Agregar
  }

  @override
  void dispose() {
    _quotationsSubscription?.unsubscribe(); // Limpiar subscription
    super.dispose();
  }

  /// 🔴 NUEVO: Escuchar cambios en cotizaciones en tiempo real
  void _setupRealtimeSubscription() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _quotationsSubscription = _supabase.realtime.channel(
      'public:quotations:technician_id=eq.$userId',
    ).onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'quotations',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'technician_id',
        value: userId,
      ),
      callback: (payload) {
        if (!mounted) return;
        final newData = payload.newRecord;
        
        // Si una cotización fue aceptada
        if (newData['status'] == 'accepted') {
          final quotationId = newData['id'];
          final clientName = newData['client_name'] ?? 'Cliente';
          final amount = newData['total_amount'] ?? 0.0;
          
          // Mostrar notificación local
          _notificationService.showQuotationAcceptedNotification(
            clientName: clientName,
            amount: amount.toDouble(),
            quotationId: quotationId,
          );
          
          // Mostrar diálogo visual en la app si está abierta
          _showAcceptanceDialog(quotationId, clientName, amount.toDouble());
          
          // Recargar cotizaciones
          _loadQuotations();
        }
      },
    ).subscribe();
  }

  /// 🔴 NUEVO: Mostrar diálogo cuando se acepta una cotización
  void _showAcceptanceDialog(String quotationId, String clientName, double amount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 ¡Cotización Aceptada!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green[100],
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green[700],
                size: 50,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '$clientName aceptó tu cotización',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Monto: \$${amount.toStringAsFixed(2)}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Por favor, procede a confirmar los detalles del trabajo en el chat.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Más Tarde'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _goToWorkConfirmation(quotationId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ir a Confirmar'),
          ),
        ],
      ),
    );
  }

  /// 🔴 NUEVO: Navegar a la pantalla de confirmación del trabajo
  Future<void> _goToWorkConfirmation(String quotationId) async {
    try {
      // Obtener el trabajo asociado
      final work = await _workService.getWorkByQuotation(quotationId);
      
      if (!mounted) return;
      
      if (work != null) {
        // Crear solicitud básica para la navegación
        final request = ServiceRequest(
          id: work.requestId,
          clientId: work.clientId,
          title: 'Trabajo Aceptado',
          description: 'Coordinación de trabajo',
          serviceType: ServiceType.values.first,
          sector: '',
          exactLocation: '',
          status: RequestStatus.assigned,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          imageUrls: [],
        );
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkCoordinationScreen(
              work: work,
              request: request,
              currentUser: widget.user,
              isClient: false, // Es técnico
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aún no hay trabajo. Intenta más tarde.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadQuotations() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final quotations = await _quotationService.getTechnicianQuotations();
    
    // 🔴 NUEVO: Cargar trabajos para cotizaciones aceptadas
    for (var quotation in quotations) {
      if (quotation.status == QuotationStatus.accepted) {
        final work = await _workService.getWorkByQuotation(quotation.id);
        if (!mounted) return;
        _quotationWorks[quotation.id] = work;
      }
    }
    
    if (!mounted) return;
    setState(() {
      _quotations = quotations;
      _isLoading = false;
    });
  }

  List<Quotation> get _filteredQuotations {
    if (_filterStatus == 'all') return _quotations;
    return _quotations
        .where((q) => q.status.name == _filterStatus)
        .toList();
  }

  // 🔴 NUEVO: Navegar a coordinación
  Future<void> _goToWorkCoordination(Quotation quotation) async {
    final work = _quotationWorks[quotation.id];
    if (work != null) {
      // Necesitamos obtener la solicitud también
      final request = ServiceRequest(
        id: work.requestId,
        clientId: '',
        title: 'Trabajo Aceptado',
        description: 'Coordinación de trabajo',
        serviceType: ServiceType.values.first,
        sector: '',
        exactLocation: '',
        status: RequestStatus.assigned,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        imageUrls: [],
      );
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WorkCoordinationScreen(
            work: work,
            request: request,
            currentUser: widget.user,
            isClient: false, // Es técnico
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

  IconData _getStatusIcon(QuotationStatus status) {
    switch (status) {
      case QuotationStatus.pending:
        return Icons.hourglass_empty;
      case QuotationStatus.accepted:
        return Icons.check_circle;
      case QuotationStatus.rejected:
        return Icons.cancel;
      case QuotationStatus.expired:
        return Icons.access_time;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Cotizaciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadQuotations,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Todas',
                    isSelected: _filterStatus == 'all',
                    count: _quotations.length,
                    onTap: () => setState(() => _filterStatus = 'all'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Pendientes',
                    isSelected: _filterStatus == 'pending',
                    count: _quotations.where((q) => q.status == QuotationStatus.pending).length,
                    color: Colors.orange,
                    onTap: () => setState(() => _filterStatus = 'pending'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Aceptadas',
                    isSelected: _filterStatus == 'accepted',
                    count: _quotations.where((q) => q.status == QuotationStatus.accepted).length,
                    color: Colors.green,
                    onTap: () => setState(() => _filterStatus = 'accepted'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Rechazadas',
                    isSelected: _filterStatus == 'rejected',
                    count: _quotations.where((q) => q.status == QuotationStatus.rejected).length,
                    color: Colors.red,
                    onTap: () => setState(() => _filterStatus = 'rejected'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredQuotations.isEmpty
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
                        _filterStatus == 'all'
                            ? 'No has enviado cotizaciones aún'
                            : 'No hay cotizaciones ${_filterStatus}',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Busca solicitudes disponibles',
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
                    itemCount: _filteredQuotations.length,
                    itemBuilder: (context, index) {
                      final quotation = _filteredQuotations[index];
                      final hasAcceptedWork = _quotationWorks[quotation.id] != null;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 3,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => QuotationDetailScreen(
                                  quotation: quotation,
                                  user: widget.user, // 🔴 Agregar
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header con número y estado
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            quotation.quotationNumber,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            quotation.solutionTitle,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
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
                                        color: _getStatusColor(quotation.status),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _getStatusIcon(quotation.status),
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            quotation.status.displayName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Descripción
                                Text(
                                  quotation.workDescription,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Detalles
                                Row(
                                  children: [
                                    Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Total: \$${quotation.totalAmount.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                    const Spacer(),
                                    Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(
                                      quotation.estimatedTime,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Fecha y vigencia
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Enviado: ${DateFormat('dd/MM/yyyy').format(quotation.createdAt)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const Spacer(),
                                    if (quotation.status == QuotationStatus.pending) ...[
                                      Icon(
                                        quotation.daysRemaining > 2
                                            ? Icons.check_circle
                                            : Icons.warning,
                                        size: 14,
                                        color: quotation.daysRemaining > 2
                                            ? Colors.green
                                            : Colors.orange,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${quotation.daysRemaining} días restantes',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: quotation.daysRemaining > 2
                                              ? Colors.green
                                              : Colors.orange,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),

                                // 🔴 NUEVO: Sección para cotizaciones aceptadas
                                if (quotation.status == QuotationStatus.accepted) ...[
                                  const SizedBox(height: 12),
                                  Container(
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
                                            Icon(Icons.celebration, color: Colors.green[700], size: 20),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                '✅ Cotización Aceptada',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  color: Colors.green[900],
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'El cliente aceptó tu cotización. Ya puedes coordinar el trabajo.',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.green[800],
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        
                                        // Botones de acción rápida
                                        if (hasAcceptedWork) ...[
                                          Row(
                                            children: [
                                              Expanded(
                                                child: OutlinedButton.icon(
                                                  onPressed: () => _goToWorkCoordination(quotation),
                                                  icon: const Icon(Icons.chat, size: 16),
                                                  label: const Text('Ir al Chat'),
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
                                                  onPressed: () => _goToWorkCoordination(quotation),
                                                  icon: const Icon(Icons.work, size: 16),
                                                  label: const Text('Ver Trabajo'),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.orange,
                                                    foregroundColor: Colors.white,
                                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ] else ...[
                                          const Text(
                                            'El trabajo se está creando...',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.orange,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 12),
                                const Divider(),
                                const SizedBox(height: 8),

                                // Botón ver detalles
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      // 🔴 NUEVO: Botón extra para chat si está aceptada
                                      if (quotation.status == QuotationStatus.accepted && hasAcceptedWork)
                                        OutlinedButton.icon(
                                          onPressed: () => _goToWorkCoordination(quotation),
                                          icon: const Icon(Icons.chat, size: 16),
                                          label: const Text('Chat'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.blue,
                                            side: BorderSide(color: Colors.blue.shade300),
                                          ),
                                        ),
                                      if (quotation.status == QuotationStatus.accepted && hasAcceptedWork)
                                        const SizedBox(width: 8),
                                        
                                      TextButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => QuotationDetailScreen(
                                                quotation: quotation,
                                                user: widget.user,
                                              ),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.visibility, size: 18),
                                        label: const Text('Ver Detalles'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

// ==================== FILTER CHIP ====================
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final int count;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.count,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.grey[200],
      selectedColor: color ?? Colors.blue,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}