import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/work_and_chat_models.dart';
import '../../models/service_request_model.dart';
import '../../services/work_and_chat_service.dart';
import '../../services/service_request_service.dart';
import '../client/work_coordination_screen.dart';

class MyActiveWorksScreen extends StatefulWidget {
  final UserModel user;

  const MyActiveWorksScreen({super.key, required this.user});

  @override
  State<MyActiveWorksScreen> createState() => _MyActiveWorksScreenState();
}

class _MyActiveWorksScreenState extends State<MyActiveWorksScreen> {
  final _workService = WorkService();
  final _requestService = ServiceRequestService();
  List<AcceptedWork> _works = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorks();
  }

  Future<void> _loadWorks() async {
    setState(() => _isLoading = true);
    final works = await _workService.getTechnicianActiveWorks();
    setState(() {
      _works = works;
      _isLoading = false;
    });
  }

  Future<void> _goToWork(AcceptedWork work) async {
    // Cargar la solicitud completa
    final requests = await _requestService.getClientRequests();
    
    // Intentar encontrar la solicitud, o crear una temporal
    ServiceRequest request;
    try {
      request = requests.firstWhere((r) => r.id == work.requestId);
    } catch (e) {
      // Si no se encuentra, crear una temporal
      request = ServiceRequest(
        id: work.requestId,
        clientId: work.clientId,
        title: 'Trabajo Aceptado',
        description: 'Coordinación de trabajo',
        serviceType: ServiceType.emergency,
        sector: '',
        exactLocation: '',
        status: RequestStatus.in_progress,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkCoordinationScreen(
          work: work,
          request: request,
          currentUser: widget.user,
          isClient: false,
        ),
      ),
    ).then((_) => _loadWorks());
  }

  Color _getStatusColor(WorkStatus status) {
    switch (status) {
      case WorkStatus.pending_payment:
        return Colors.orange;
      case WorkStatus.paid:
        return Colors.green;
      case WorkStatus.on_way:
        return Colors.blue;
      case WorkStatus.in_progress:
        return Colors.purple;
      case WorkStatus.completed:
        return Colors.teal;
      case WorkStatus.rated:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Trabajos Activos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWorks,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _works.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.work_off, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No tienes trabajos activos',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Busca solicitudes y envía cotizaciones',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadWorks,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _works.length,
                    itemBuilder: (context, index) {
                      final work = _works[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 3,
                        child: InkWell(
                          onTap: () => _goToWork(work),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(work.status),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              work.status.icon,
                                              style: const TextStyle(fontSize: 16),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              work.status.displayName,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Total',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        Text(
                                          '\$${work.paymentAmount.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Tu Pago',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        Text(
                                          '\$${work.technicianAmount?.toStringAsFixed(2) ?? '0.00'}',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _goToWork(work),
                                    icon: const Icon(Icons.chat),
                                    label: const Text('Ir al Chat y Trabajo'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                    ),
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