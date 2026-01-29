import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/work_and_chat_models.dart';
import '../../models/service_request_model.dart';
import '../../models/user_model.dart';
import '../../services/work_and_chat_service.dart';
import 'chat_tab.dart';
import 'payment_tab.dart';
import 'work_progress_tab.dart';

class WorkCoordinationScreen extends StatefulWidget {
  final AcceptedWork work;
  final ServiceRequest request;
  final UserModel currentUser;
  final bool isClient; // true si es cliente, false si es técnico

  const WorkCoordinationScreen({
    super.key,
    required this.work,
    required this.request,
    required this.currentUser,
    required this.isClient,
  });

  @override
  State<WorkCoordinationScreen> createState() => _WorkCoordinationScreenState();
}

class _WorkCoordinationScreenState extends State<WorkCoordinationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _workService = WorkService();
  AcceptedWork? _currentWork;

  @override
  void initState() {
    super.initState();
    _currentWork = widget.work;

    // Determinar número de tabs según estado
    final tabCount = _getTabCount();
    _tabController = TabController(length: tabCount, vsync: this);

    _loadWorkDetails();
  }

  int _getTabCount() {
    // Si está pendiente de pago, mostrar solo pago y chat
    if (_currentWork?.status == WorkStatus.pending_payment) {
      return 2; // Pago, Chat
    }
    // Si ya está pagado o en progreso, mostrar todas las tabs
    return 3; // Pago, Chat, Progreso
  }

  Future<void> _loadWorkDetails() async {
    if (!mounted) return;
    final work = await _workService.getWorkByQuotation(widget.work.quotationId);
    if (work != null && mounted) {
      setState(() {
        _currentWork = work;

        // Reconstruir tabs si el estado cambió
        final newTabCount = _getTabCount();
        if (newTabCount != _tabController.length) {
          _tabController.dispose();
          _tabController = TabController(length: newTabCount, vsync: this);
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
    if (_currentWork == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Coordinación')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final work = _currentWork!;
    final showProgressTab = work.status != WorkStatus.pending_payment;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Volver',
        ),
        title: Text(widget.request.title,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          // Botón para ir al home rápidamente
          if (widget.isClient)
            Tooltip(
              message: 'Ir al inicio',
              child: IconButton(
                icon: const Icon(Icons.home),
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              // Estado del trabajo
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(work.status).withOpacity(0.1),
                  border: Border(
                    bottom: BorderSide(
                      color: _getStatusColor(work.status),
                      width: 2,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          work.status.icon,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              work.status.displayName,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(work.status),
                              ),
                            ),
                            Text(
                              'Total: \$${work.paymentAmount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (work.paidAt != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Pagado',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            DateFormat('dd/MM/yyyy', 'es_ES')
                                .format(work.paidAt!),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // Tabs
              TabBar(
                controller: _tabController,
                labelColor: Colors.orange,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.orange,
                tabs: [
                  const Tab(
                    icon: Icon(Icons.payment),
                    text: 'Pago',
                  ),
                  const Tab(
                    icon: Icon(Icons.chat),
                    text: 'Chat',
                  ),
                  if (showProgressTab)
                    const Tab(
                      icon: Icon(Icons.trending_up),
                      text: 'Progreso',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab de Pago
          PaymentTab(
            work: work,
            isClient: widget.isClient,
            onPaymentCompleted: () {
              _loadWorkDetails();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Pago confirmado'),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),

          // Tab de Chat
          ChatTab(
            workId: work.id,
            otherUserName: widget.isClient
                ? 'Técnico' // Aquí podrías cargar el nombre real
                : widget.request.title,
            isClient: widget.isClient,
          ),

          // Tab de Progreso (solo si está pagado)
          if (showProgressTab)
            WorkProgressTab(
              work: work,
              request: widget.request,
              isClient: widget.isClient,
              onStatusChanged: _loadWorkDetails,
            ),
        ],
      ),
    );
  }
}
